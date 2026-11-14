extends "res://tests/test_suite.gd"
## Tinju Empang rules (GDD 41-49, 138, 169.13, 169.14; QA matrix BOX-001..012)
## and the duel result commit.

const STORAGE_DIR := "user://test_tmp/boxing"
const TICK := BoxingController.TICK_SEC
const SEED := 4242

var _box: BoxingController
var _events: Array[String] = []
var _telegraphs: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _landed: Array[Dictionary] = []


func get_suite_name() -> String:
	return "boxing"


func before_all() -> void:
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)


func after_all() -> void:
	DebugService.clear_forces()
	DebugService.clear_dev_dirty()
	GameState.clear_game()
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


func before_each() -> void:
	SaveManager.delete_save()
	DebugService.clear_forces()
	DebugService.clear_dev_dirty()
	GameState.clear_game()
	GameState.new_game()
	_events.clear()
	_telegraphs.clear()
	_impacts.clear()
	_landed.clear()
	_box = BoxingController.new()
	_box.auto_advance = false
	_box.telegraph_started.connect(func(direction: StringName, variant: int, seconds: float) -> void:
		_telegraphs.append({"direction": direction, "variant": variant, "seconds": seconds, "at": _elapsed()})
		_events.append("telegraph"))
	_box.attack_resolved.connect(func(outcome: StringName, direction: StringName) -> void:
		_impacts.append({"outcome": outcome, "direction": direction, "at": _elapsed()})
		_events.append("impact:%s" % outcome))
	_box.player_attack_landed.connect(func(attack_id: StringName, damage: float, blocked: bool) -> void:
		_landed.append({"attack": attack_id, "damage": damage, "blocked": blocked, "at": _elapsed()}))
	_box.sudden_death_started.connect(func() -> void: _events.append("sudden_death"))
	_box.duel_finished.connect(func(_result: Dictionary) -> void: _events.append("finished"))


func after_each() -> void:
	_box.free()


# --- Helpers ----------------------------------------------------------------

func _elapsed() -> float:
	return float(_box.get_snapshot()["elapsed"])


func _snap(key: String) -> Variant:
	return _box.get_snapshot()[key]


func _run(seconds: float) -> void:
	for _tick: int in roundi(seconds / TICK):
		_box.advance(TICK)


## Steps the fight until `condition` holds. False when it never does.
func _until(condition: Callable, max_sec: float = 90.0) -> bool:
	for _tick: int in roundi(max_sec / TICK):
		if condition.call():
			return true
		_box.advance(TICK)
	return condition.call()


func _until_telegraph() -> bool:
	return _until(func() -> bool: return _snap("attack_direction") != &"")


func _other(direction: StringName) -> StringName:
	return BoxingController.DIRECTION_RIGHT if direction == BoxingController.DIRECTION_LEFT else BoxingController.DIRECTION_LEFT


## Dodges the current telegraph when `lead_sec` is left before the impact and
## runs on to the impact.
func _dodge_at(lead_sec: float, wrong: bool = false) -> void:
	_until(func() -> bool: return float(_snap("time_to_impact")) <= lead_sec + TICK * 0.5)
	var direction: StringName = _snap("attack_direction")
	_box.request_dodge(_other(direction) if wrong else direction)
	var impacts := _impacts.size()
	_until(func() -> bool: return _impacts.size() > impacts)


## Plays with the bot until the duel ends. `attack` off means dodge only.
func _play_out(perfect: bool, attack: bool = true, max_sec: float = 200.0) -> Dictionary:
	for _tick: int in roundi(max_sec / TICK):
		if _box.get_state() == BoxingController.STATE_FINISHED:
			break
		if attack or _snap("attack_direction") != &"":
			BoxingBot.play(_box, perfect)
		_box.advance(TICK)
	return _box.get_result()


## Dodges every attack, throws nothing, until `condition` holds.
func _dodge_until(condition: Callable, max_sec: float = 90.0) -> bool:
	for _tick: int in roundi(max_sec / TICK):
		if condition.call():
			return true
		if _snap("attack_direction") != &"":
			BoxingBot.play(_box, true)
		_box.advance(TICK)
	return condition.call()


# --- Tests ------------------------------------------------------------------

# BOX-001, BOX-002
func test_player_hp_follows_herbal_tonic() -> bool:
	var expected: Array[float] = [100.0, 125.0, 150.0, 175.0]
	for level: int in expected.size():
		GameState.debug_set_upgrade_level(&"tonic", level)
		_box.start_duel(&"catfish_bruiser", SEED)
		check_eq(_snap("player_max_hp"), expected[level], "max HP at Tonic Lv%d" % level)
		check_eq(_snap("player_hp"), expected[level], "the fight starts at full HP")
	check_eq(_snap("fish_max_hp"), 70.0, "Bruiser Catfish has 70 HP")
	return true


# BOX-003
func test_jab_and_cross_values_and_timing() -> bool:
	var config := GameData.get_boxing_config()
	check_eq(config.jab_damage, 11.0, "jab damage")
	check_eq(config.jab_startup_sec, 0.11, "jab startup")
	check_eq(config.jab_recovery_sec, 0.25, "jab recovery")
	check_eq(config.cross_damage, 18.0, "cross damage")
	check_eq(config.cross_startup_sec, 0.20, "cross startup")
	check_eq(config.cross_recovery_sec, 0.44, "cross recovery")

	for attack: Array in [[BoxingController.ATTACK_JAB, 0.11, 0.25], [BoxingController.ATTACK_CROSS, 0.20, 0.44]]:
		_landed.clear()
		_box.start_duel(&"arowana_don", SEED)
		_run(BoxingController.INTRO_SEC + 0.1)
		var started := _elapsed()
		_box.request_attack(attack[0])
		check_eq(_snap("player_phase"), BoxingController.PLAYER_ATTACKING, "%s starts at once" % attack[0])
		_run(float(attack[1]) - 0.03)
		check_eq(_landed.size(), 0, "%s has not landed before its startup ends" % attack[0])
		_run(0.05)
		if check_eq(_landed.size(), 1, "%s lands once" % attack[0]):
			check_near(float(_landed[0]["at"]) - started, attack[1], 0.012, "%s lands when its startup ends" % attack[0])
		_box.request_attack(attack[0])
		check_eq(_landed.size(), 1, "no second punch during recovery")
		check(await_ready_after(started, float(attack[1]) + float(attack[2])), "%s is ready again after startup + recovery" % attack[0])
	return true


func await_ready_after(started: float, total: float) -> bool:
	_until(func() -> bool: return _snap("player_phase") == BoxingController.PLAYER_READY, 2.0)
	return absf((_elapsed() - started) - total) <= 0.012


# BOX-004
func test_every_attack_is_telegraphed_for_its_full_time() -> bool:
	for fish: FishData in GameData.get_all_fish():
		_telegraphs.clear()
		_impacts.clear()
		GameState.debug_set_upgrade_level(&"tonic", 3)
		_box.start_duel(fish.id, SEED + fish.tier)
		_until(func() -> bool: return _box.get_state() == BoxingController.STATE_FINISHED)
		check(_impacts.size() >= 3, "%s attacked several times (%d)" % [fish.id, _impacts.size()])
		check_eq(_telegraphs.size(), _impacts.size(), "%s: one telegraph for every impact" % fish.id)
		var short := 0
		for index: int in mini(_telegraphs.size(), _impacts.size()):
			var warned := float(_impacts[index]["at"]) - float(_telegraphs[index]["at"])
			if warned < fish.boxing_telegraph_sec - 0.012 or _telegraphs[index]["direction"] != _impacts[index]["direction"]:
				short += 1
		check_eq(short, 0, "%s: every attack shows its direction for the full %.2f s" % [fish.id, fish.boxing_telegraph_sec])
		check_eq(_telegraphs[0]["seconds"], fish.boxing_telegraph_sec, "%s telegraph comes from FishData" % fish.id)
	return true


# BOX-005, BOX-009
func test_correct_dodge_opens_a_counter_window() -> bool:
	_box.start_duel(&"catfish_bruiser", SEED)
	_until_telegraph()
	_dodge_at(0.5)
	check_eq(_impacts[0]["outcome"], BoxingController.OUTCOME_DODGED, "an early correct dodge is a normal dodge")
	check_eq(_snap("player_hp"), 100.0, "no damage taken")
	check(_snap("counter_open"), "the counter window is open")
	check_near(_snap("counter_left"), 0.62, 0.012, "normal counter window is 0.62 s")
	check_eq(_snap("player_phase"), BoxingController.PLAYER_READY, "Darto can counter at once")

	_box.request_attack(BoxingController.ATTACK_CROSS)
	_until(func() -> bool: return _landed.size() == 1, 1.0)
	check(not _landed[0]["blocked"], "the counter is not blocked")
	check_near(_landed[0]["damage"], 36.0, 0.0001, "cross x 2.0 = 36")
	check_near(_snap("fish_hp"), 34.0, 0.0001, "the catfish lost 36 HP")

	_until(func() -> bool: return not _snap("counter_open"), 2.0)
	check(not _snap("counter_open"), "the window closes again")
	return true


# BOX-006
func test_wrong_or_missing_dodge_takes_the_hit() -> bool:
	_box.start_duel(&"catfish_bruiser", SEED)
	_until_telegraph()
	_dodge_at(0.5, true)
	check_eq(_impacts[0]["outcome"], BoxingController.OUTCOME_HIT, "the wrong direction is a hit")
	check_eq(_snap("player_hp"), 88.0, "the catfish hits for 12")
	check(not _snap("counter_open"), "no counter window after a hit")
	check_eq(_snap("player_phase"), BoxingController.PLAYER_STUNNED, "Darto reels from the hit")
	_box.request_attack(BoxingController.ATTACK_JAB)
	check_eq(_snap("player_phase"), BoxingController.PLAYER_STUNNED, "no input is accepted while reeling")

	_until_telegraph()
	_until(func() -> bool: return _impacts.size() == 2)
	check_eq(_impacts[1]["outcome"], BoxingController.OUTCOME_HIT, "no dodge at all is a hit")
	check_eq(_snap("player_hp"), 76.0, "second hit applied")
	return true


func test_first_dodge_is_the_answer() -> bool:
	_box.start_duel(&"catfish_bruiser", SEED)
	_until_telegraph()
	var direction: StringName = _snap("attack_direction")
	_box.request_dodge(_other(direction))
	_run(0.1)
	_box.request_dodge(direction)
	_until(func() -> bool: return _impacts.size() == 1)
	check_eq(_impacts[0]["outcome"], BoxingController.OUTCOME_HIT, "changing your mind after a wrong dodge does not save you")

	# A dodge thrown before the telegraph is only a step; it answers nothing.
	_until(func() -> bool: return _snap("fish_phase") == BoxingController.FISH_COOLDOWN and _snap("player_phase") == BoxingController.PLAYER_READY)
	_box.request_dodge(BoxingController.DIRECTION_LEFT)
	_run(BoxingController.DODGE_SEC + 0.02)
	check_eq(_snap("player_phase"), BoxingController.PLAYER_READY, "an idle dodge lasts 0.32 s")
	return true


# BOX-007, BOX-008
func test_perfect_dodge_is_the_last_180_ms() -> bool:
	_box.start_duel(&"catfish_bruiser", SEED)
	_until_telegraph()
	_dodge_at(0.20)
	check_eq(_impacts[0]["outcome"], BoxingController.OUTCOME_DODGED, "0.20 s before impact is still a normal dodge")

	_until(func() -> bool: return not _snap("counter_open"))
	_until_telegraph()
	check(not _snap("in_perfect_window"), "the perfect window is not open at the start of a telegraph")
	_dodge_at(0.17)
	check_eq(_impacts[1]["outcome"], BoxingController.OUTCOME_PERFECT, "0.17 s before impact is a Perfect Dodge")
	check(_snap("counter_perfect"), "the window is a perfect one")
	check_near(_snap("counter_left"), 0.85, 0.012, "perfect counter window is 0.85 s")

	# The 70 ms freeze: the window does not run down while the fight holds.
	var before: float = _snap("counter_left")
	_run(0.05)
	check_eq(_snap("counter_left"), before, "the fight is frozen right after a Perfect Dodge")
	_run(0.05)
	check(float(_snap("counter_left")) < before, "and moves again after 70 ms")

	_box.request_attack(BoxingController.ATTACK_CROSS)
	_until(func() -> bool: return _landed.size() == 1, 1.0)
	check_near(_landed[0]["damage"], 43.2, 0.0001, "cross x 2.4 = 43.2")
	_until(func() -> bool: return _snap("player_phase") == BoxingController.PLAYER_READY, 1.0)
	_box.request_attack(BoxingController.ATTACK_JAB)
	_until(func() -> bool: return _landed.size() == 2, 1.0)
	check_near(_landed[1]["damage"], 26.4, 0.0001, "a jab inside the same window: x 2.4 = 26.4")
	return true


# BOX-010
func test_attack_without_an_opening_is_blocked() -> bool:
	_box.start_duel(&"arowana_don", SEED)
	_run(BoxingController.INTRO_SEC + 0.05)
	_box.request_attack(BoxingController.ATTACK_JAB)
	_until(func() -> bool: return _landed.size() == 1, 1.0)
	check(_landed[0]["blocked"], "a jab with no opening is blocked")
	check_near(_landed[0]["damage"], 4.4, 0.0001, "blocked jab does 40%: 4.4")
	_until(func() -> bool: return _snap("player_phase") == BoxingController.PLAYER_READY, 1.0)
	_box.request_attack(BoxingController.ATTACK_CROSS)
	_until(func() -> bool: return _landed.size() == 2, 1.0)
	check_near(_landed[1]["damage"], 7.2, 0.0001, "blocked cross does 40%: 7.2")
	check_near(_snap("fish_hp"), 190.0 - 11.6, 0.0001, "Don Arowana lost exactly 11.6 HP")
	return true


func test_punching_through_a_telegraph_gets_you_hit() -> bool:
	_box.start_duel(&"snakehead_sergeant", SEED)
	_until_telegraph()
	_until(func() -> bool: return float(_snap("time_to_impact")) <= 0.1)
	_box.request_attack(BoxingController.ATTACK_CROSS)
	_until(func() -> bool: return _impacts.size() == 1)
	check_eq(_impacts[0]["outcome"], BoxingController.OUTCOME_HIT, "the fish's attack is not interrupted")
	check_eq(_landed.size(), 0, "the cross that had not landed yet is cancelled")
	check_eq(_snap("player_hp"), 100.0 - 22.0, "Snakehead Sergeant hits for 22")
	return true


# BOX-011
func test_timeout_compares_hp_share() -> bool:
	# Dodge everything and land one blocked jab: 100% against less than 100%.
	_box.start_duel(&"arowana_don", SEED)
	_run(BoxingController.INTRO_SEC + 0.05)
	_box.request_attack(BoxingController.ATTACK_JAB)
	var won := _play_out(true, false)
	check(bool(won["metrics"]["timed_out"]), "the round ran the full 60 s")
	check_near(won["duration_sec"], 60.0, 0.05, "duration is the round time")
	check(won["player_won"], "the higher share of HP wins on time")
	check_eq(won["metrics"]["hits_taken"], 0, "the player was never hit")

	# Take hits and never fight back: the fish has the higher share.
	GameState.debug_set_upgrade_level(&"tonic", 3)
	_impacts.clear()
	_box.start_duel(&"catfish_bruiser", SEED)
	_until(func() -> bool: return _impacts.size() == 2)
	var lost := _play_out(true, false)
	check(bool(lost["metrics"]["timed_out"]), "this round also went to time")
	check(not lost["player_won"], "151/175 against 70/70: the fish wins on time")
	return true


# BOX-012
func test_exact_tie_goes_to_sudden_death() -> bool:
	_box.start_duel(&"catfish_bruiser", SEED)
	_dodge_until(func() -> bool: return _events.has("sudden_death") or _events.has("finished"))
	check(_events.has("sudden_death"), "100% against 100% at time starts sudden death")
	check_eq(_box.get_state(), BoxingController.STATE_SUDDEN_DEATH, "the fight goes on")
	check(_snap("sudden_death"), "the snapshot says so")

	# A blocked punch decides nothing.
	_until(func() -> bool: return _snap("fish_phase") == BoxingController.FISH_COOLDOWN and _snap("player_phase") == BoxingController.PLAYER_READY)
	_box.request_attack(BoxingController.ATTACK_JAB)
	_until(func() -> bool: return _landed.size() == 1, 1.0)
	check(_landed[0]["blocked"] and _box.get_state() == BoxingController.STATE_SUDDEN_DEATH, "a blocked hit does not end sudden death")
	check_eq(_snap("fish_hp"), 70.0, "and does no damage")

	var result := _play_out(true, true)
	check(result["player_won"], "the first clean hit wins")
	check(bool(result["metrics"]["sudden_death"]), "the result records the sudden death")

	# The other way round: the fish lands the first hit.
	_events.clear()
	_box.start_duel(&"catfish_bruiser", SEED)
	_dodge_until(func() -> bool: return _events.has("sudden_death") or _events.has("finished"))
	check(_events.has("sudden_death"), "second fight reaches sudden death too")
	_until(func() -> bool: return _box.get_state() == BoxingController.STATE_FINISHED)
	check(not _box.get_result()["player_won"], "one hit from the fish ends it")
	check_eq(_box.get_result()["metrics"]["hits_taken"], 1, "exactly one hit was needed")
	return true


func test_hp_reaching_zero_ends_the_fight_at_once() -> bool:
	_box.start_duel(&"arowana_don", SEED)
	_until(func() -> bool: return _box.get_state() == BoxingController.STATE_FINISHED)
	var result := _box.get_result()
	check(not result["player_won"], "a player who never dodges loses")
	check_eq(result["metrics"]["hits_taken"], 4, "Don Arowana needs four hits of 26 against 100 HP")
	check(not bool(result["metrics"]["timed_out"]), "the fight ended before the clock")
	check_eq(_snap("player_hp"), 0.0, "HP never goes below zero")
	return true


func test_cooldowns_stay_in_range_and_follow_the_seed() -> bool:
	var ranges: Dictionary = {&"gourami_shady": Vector2(1.2, 2.1), &"arowana_don": Vector2(0.95, 1.65)}
	for fish_id: StringName in ranges:
		_telegraphs.clear()
		_impacts.clear()
		_box.start_duel(fish_id, SEED)
		_play_out(true, false, 62.0)
		var range: Vector2 = ranges[fish_id]
		var outside := 0
		var gaps := PackedFloat32Array()
		# After a dodge the fish is open for 0.85 s, then waits its cooldown.
		for index: int in range(1, _telegraphs.size()):
			var gap := float(_telegraphs[index]["at"]) - float(_impacts[index - 1]["at"]) - 0.85
			gaps.append(gap)
			if gap < range.x - 0.02 or gap > range.y + 0.02:
				outside += 1
		check(gaps.size() >= 12, "%s attacked many times (%d)" % [fish_id, gaps.size()])
		check_eq(outside, 0, "%s cooldowns stay within %.2f-%.2f s" % [fish_id, range.x, range.y])
		var spread := 0.0
		for gap: float in gaps:
			spread = maxf(spread, absf(gap - gaps[0]))
		check(spread > 0.2, "%s does not attack on a fixed rhythm" % fish_id)

	var first := _attack_script(SEED)
	check_eq(_attack_script(SEED), first, "the same seed gives the same fight")
	check(_attack_script(SEED + 1) != first, "another seed gives another fight")
	var lefts := first.count("left")
	check(lefts > 3 and lefts < first.size() - 3, "both directions are used (%d of %d left)" % [lefts, first.size()])
	return true


func _attack_script(seed: int) -> Array[String]:
	_telegraphs.clear()
	_box.start_duel(&"tilapia_gym_rat", seed)
	_play_out(true, false, 62.0)
	var script: Array[String] = []
	for telegraph: Dictionary in _telegraphs:
		script.append(String(telegraph["direction"]))
	return script


# Exit gate: Catfish through Arowana can complete Boxing.
func test_every_fish_can_be_beaten_and_can_win() -> bool:
	for fish: FishData in GameData.get_all_fish():
		_box.start_duel(fish.id, SEED + fish.tier * 11)
		var win := _play_out(true)
		check(win["player_won"], "%s: a careful player wins" % fish.id)
		check_eq(win["metrics"]["hits_taken"], 0, "%s: reading every telegraph means never being hit" % fish.id)
		check(float(win["duration_sec"]) < 60.0, "%s goes down before the clock (%.1f s)" % [fish.id, float(win["duration_sec"])])

		_box.start_duel(fish.id, SEED + fish.tier * 11)
		var normal := _play_out(false)
		check(normal["player_won"], "%s: normal dodges are enough to win" % fish.id)
		check_eq(normal["metrics"]["perfect_dodges"], 0, "%s: that fight used no Perfect Dodge" % fish.id)

		_box.start_duel(fish.id, SEED + fish.tier * 11)
		_until(func() -> bool: return _box.get_state() == BoxingController.STATE_FINISHED)
		check(not _box.get_result()["player_won"], "%s beats a player who does nothing" % fish.id)
	return true


func test_result_follows_the_contract() -> bool:
	_box.start_duel(&"carp_golden", 777)
	check_eq(_box.get_result(), {}, "no result before the fight ends")
	var result := _play_out(true)
	for key: String in ["duel_id", "fish_id", "player_won", "duration_sec", "seed", "metrics"]:
		check(result.has(key), "result has %s (GDD 169.14)" % key)
	check_eq(result["duel_id"], &"boxing", "duel id")
	check_eq(result["fish_id"], &"carp_golden", "fish id")
	check_eq(result["seed"], 777, "seed")
	check_eq(typeof(result["metrics"]), TYPE_DICTIONARY, "metrics is a dictionary")
	check_eq(_events.count("finished"), 1, "duel_finished fires once")
	_box.request_attack(BoxingController.ATTACK_JAB)
	_run(1.0)
	check_eq(_events.count("finished"), 1, "a finished fight takes no more input")
	return true


func test_the_controller_never_touches_the_economy() -> bool:
	var before := GameState.export_save_state()
	_box.start_duel(&"catfish_bruiser", SEED)
	_play_out(true)
	var after := GameState.export_save_state()
	for key: String in ["cash", "debt", "bucket", "upgrades", "fish_book", "stats"]:
		check_eq(after[key], before[key], "%s is unchanged by the fight itself" % key)
	return true


func test_debug_overrides() -> bool:
	DebugService.set_forced_attack_direction(&"right")
	_box.start_duel(&"catfish_bruiser", SEED)
	_play_out(true, false, 20.0)
	var rights := 0
	for telegraph: Dictionary in _telegraphs:
		if telegraph["direction"] == &"right":
			rights += 1
	check(rights == _telegraphs.size() and rights > 3, "every attack comes from the forced side")

	DebugService.clear_forces()
	DebugService.set_forced_result(&"loss")
	_box.start_duel(&"catfish_bruiser", SEED)
	_run(BoxingController.INTRO_SEC + 0.05)
	check_eq(_box.get_state(), BoxingController.STATE_FINISHED, "a forced result ends the duel after the intro")
	check(not _box.get_result()["player_won"], "forced loss")
	DebugService.simulate_release_build = true
	check_eq(DebugService.get_forced_result(), &"", "release builds ignore the override")
	DebugService.simulate_release_build = false
	return true


# The result commit (GDD 169.13, 169.14, 176.11).
func test_winning_puts_the_fish_in_the_bucket() -> bool:
	GameState.current_fish = &"gourami_shady"
	GameState.current_duel = &"boxing"
	GameState.current_catch = {"fish_id": &"gourami_shady", "weight_kg": 1.37, "is_big_one": false, "seed": 5}
	GameState.record_encounter(&"gourami_shady")
	_box.start_duel(&"gourami_shady", SEED)
	var result := _play_out(true)
	check_eq(GameState.get_bucket_quantity(&"gourami_shady"), 0, "the fish is not in the Bucket before the commit")
	check(DuelOutcome.commit(result), "commit saves")

	check_eq(GameState.get_bucket_quantity(&"gourami_shady"), 1, "a won fish goes into the Bucket")
	var entry := GameState.get_fish_book_entry(&"gourami_shady")
	check(entry["discovered"], "the Fish Book entry opens")
	check_eq(entry["wins"], 1, "one win")
	check_eq(entry["best_weight_kg"], 1.37, "best weight is the hooked weight")
	check_eq(entry["favourite_duel"], "boxing", "favourite duel")
	check_eq(GameState.get_stat(&"duel_wins"), 1, "duel wins")
	check_eq(GameState.get_stat(&"boxing_wins"), 1, "boxing wins")
	check_eq(GameState.get_stat(&"duel_losses"), 0, "no loss recorded")
	check_eq(GameState.get_stat(&"don_arowana_defeated"), 0, "not the boss")
	check_eq(GameState.current_catch, {}, "the pending catch is cleared")
	check_eq(GameState.current_fish, &"", "no current fish")
	check_eq(GameState.get_cash(), ContentIds.STARTING_CASH, "winning pays nothing until the fish is sold")
	var saved: Dictionary = read_json(SaveManager.get_save_path())
	check_eq(saved["bucket"]["gourami_shady"], 1, "the Bucket is in the save")
	check_eq(saved["stats"]["boxing_wins"], 1, "the win is in the save")
	return true


func test_losing_costs_only_the_fish() -> bool:
	GameState.add_bucket_item(&"catfish_bruiser", 2)
	GameState.debug_set_cash(50000)
	GameState.debug_set_upgrade_level(&"rod", 2)
	GameState.record_encounter(&"snakehead_sergeant")
	var debt_before := GameState.get_debt_remaining()
	_box.start_duel(&"snakehead_sergeant", SEED)
	_until(func() -> bool: return _box.get_state() == BoxingController.STATE_FINISHED)
	check(DuelOutcome.commit(_box.get_result()), "commit saves")

	check_eq(GameState.get_bucket_quantity(&"snakehead_sergeant"), 0, "the fish got away")
	check_eq(GameState.get_bucket_quantity(&"catfish_bruiser"), 2, "the Bucket is untouched")
	check_eq(GameState.get_cash(), 50000, "no cash lost")
	check_eq(GameState.get_upgrade_level(&"rod"), 2, "no upgrade lost")
	check_eq(GameState.get_debt_remaining(), debt_before, "no debt change")
	check_eq(GameState.get_stat(&"duel_losses"), 1, "the loss is recorded")
	check_eq(GameState.get_stat(&"duel_wins"), 0, "no win recorded")
	var entry := GameState.get_fish_book_entry(&"snakehead_sergeant")
	check_eq(entry["losses"], 1, "Fish Book loss")
	check(not entry["discovered"], "a loss does not open the entry")
	return true


func test_beating_don_arowana_is_recorded() -> bool:
	GameState.record_encounter(&"arowana_don")
	_box.start_duel(&"arowana_don", SEED)
	check(DuelOutcome.commit(_play_out(true)), "commit saves")
	check_eq(GameState.get_stat(&"don_arowana_defeated"), 1, "Don Arowana Defeated")
	check_eq(GameState.get_bucket_quantity(&"arowana_don"), 1, "the Don is in the Bucket")
	StoryDirector.evaluate_story_triggers()
	check(StoryDirector.get_pending_events().has(&"story_arowana_first_win"), "the first win queues its story event")
	check(not DuelOutcome.commit({"duel_id": &"boxing", "fish_id": &"not_a_fish", "player_won": true}), "an unknown fish is rejected")
	return true
