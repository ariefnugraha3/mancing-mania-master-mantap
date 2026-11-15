extends "res://tests/test_suite.gd"
## Suwit, the Wheel of Fate and the fish dialogue (GDD 38, 64-69, 166;
## QA matrix SUWIT-001..008, WHEEL-001, 002, 005).

const STORAGE_DIR := "user://test_tmp/suwit_wheel"
const TICK := SuwitController.TICK_SEC

var _suwit: SuwitController
var _rounds: Array[Dictionary] = []
var _tells: Array[float] = []
var _starts: Array[float] = []


func get_suite_name() -> String:
	return "suwit_wheel"


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
	DebugService.clear_forces()
	GameState.clear_game()
	GameState.new_game()
	_rounds.clear()
	_tells.clear()
	_starts.clear()
	_suwit = SuwitController.new()
	_suwit.auto_advance = false
	_suwit.round_resolved.connect(func(outcome: Dictionary) -> void: _rounds.append(outcome))
	_suwit.tell_shown.connect(func(_move: StringName) -> void: _tells.append(_suwit.get_snapshot()["elapsed"]))
	_suwit.round_started.connect(func(_index: int) -> void: _starts.append(_suwit.get_snapshot()["elapsed"]))


func after_each() -> void:
	_suwit.free()


func _run(seconds: float) -> void:
	for _tick: int in roundi(seconds / TICK):
		_suwit.advance(TICK)


## Plays to the end. `pick` decides the move each round from the snapshot.
func _play(pick: Callable) -> Dictionary:
	for _tick: int in roundi(120.0 / TICK):
		if _suwit.get_state() == SuwitController.STATE_FINISHED:
			break
		var snapshot := _suwit.get_snapshot()
		if snapshot["state"] == SuwitController.STATE_COUNTDOWN and snapshot["player_move"] == &"":
			var move: StringName = pick.call(snapshot)
			if move != &"":
				_suwit.choose_move(move)
		_suwit.advance(TICK)
	return _suwit.get_result()


static func _beater(move: StringName) -> StringName:
	for candidate: StringName in SuwitController.MOVES:
		if SuwitController.BEATS[candidate] == move:
			return candidate
	return &""


# --- Suwit ------------------------------------------------------------------

# SUWIT-001, SUWIT-002
func test_first_to_two_and_draws_replay() -> bool:
	check_eq(SuwitController.outcome_of(&"rock", &"scissors"), SuwitController.OUTCOME_WIN, "rock beats scissors")
	check_eq(SuwitController.outcome_of(&"scissors", &"paper"), SuwitController.OUTCOME_WIN, "scissors beats paper")
	check_eq(SuwitController.outcome_of(&"paper", &"rock"), SuwitController.OUTCOME_WIN, "paper beats rock")
	check_eq(SuwitController.outcome_of(&"rock", &"paper"), SuwitController.OUTCOME_LOSS, "rock loses to paper")
	check_eq(SuwitController.outcome_of(&"paper", &"paper"), SuwitController.OUTCOME_DRAW, "same move draws")

	for seed: int in 40:
		_rounds.clear()
		_suwit.start_duel(&"carp_golden", 900 + seed)
		var result := _play(func(_s: Dictionary) -> StringName: return SuwitController.MOVES[seed % 3])
		var wins := 0
		var losses := 0
		var draws := 0
		for outcome: Dictionary in _rounds:
			wins += 1 if outcome["outcome"] == SuwitController.OUTCOME_WIN else 0
			losses += 1 if outcome["outcome"] == SuwitController.OUTCOME_LOSS else 0
			draws += 1 if outcome["outcome"] == SuwitController.OUTCOME_DRAW else 0
		check(maxi(wins, losses) == 2 and mini(wins, losses) <= 1, "seed %d: the match stops at two wins (%d-%d)" % [seed, wins, losses])
		check_eq(result["player_won"], wins == 2, "seed %d: the side with two wins takes it" % seed)
		check_eq(int(result["metrics"]["rounds"]), wins + losses + draws, "seed %d: draws were replayed, not counted" % seed)
		check_eq(int(result["metrics"]["player_wins"]) + int(result["metrics"]["fish_wins"]), wins + losses, "seed %d: a draw adds no dot" % seed)
	return true


# SUWIT-003
func test_the_fish_decides_before_the_tell() -> bool:
	_suwit.start_duel(&"gourami_shady", 5)
	_run(SuwitController.INTRO_SEC + TICK * 2.0)
	check_eq(_suwit.get_state(), SuwitController.STATE_COUNTDOWN, "the countdown is running")
	var hidden := _suwit.debug_get_hidden_move()
	check(hidden != &"", "the hidden move exists from the first moment of the countdown")
	check_eq(_suwit.get_snapshot()["tell"], &"", "no tell yet")
	_run(1.0)
	check_eq(_suwit.get_snapshot()["tell"], &"", "no tell at 1.0 s")
	_run(0.12)
	check(_suwit.get_snapshot()["tell"] != &"", "the tell appears 1.1 s in")
	check_eq(_suwit.debug_get_hidden_move(), hidden, "showing the tell does not change the move")
	check_near(_tells[0] - _starts[0], 1.1, 0.01, "tell at exactly 1.1 s after the round start")
	return true


# SUWIT-004
func test_tells_are_true_at_the_fish_rate() -> bool:
	for fish: FishData in GameData.get_all_fish():
		var truthful := 0
		var total := 0
		for seed: int in 120:
			_rounds.clear()
			_suwit.start_duel(fish.id, 3000 + seed)
			_play(func(s: Dictionary) -> StringName: return &"rock" if s["tell"] != &"" else &"")
			for outcome: Dictionary in _rounds:
				total += 1
				truthful += 1 if outcome["tell"] == outcome["fish"] else 0
				if not outcome["tell_truthful"]:
					check(outcome["tell"] != outcome["fish"], "%s: a lie never shows the real move" % fish.id)
		var rate := float(truthful) / float(total)
		check_near(rate, fish.tell_truth_probability, 0.06, "%s tells the truth about %d%% of the time (%d rounds)" % [fish.id, roundi(fish.tell_truth_probability * 100.0), total])
	return true


# SUWIT-005
func test_no_input_is_a_panic_pick() -> bool:
	_suwit.start_duel(&"catfish_bruiser", 77)
	var result := _play(func(_s: Dictionary) -> StringName: return &"")
	check(not _rounds.is_empty(), "rounds were played")
	for outcome: Dictionary in _rounds:
		check(outcome["panic"], "round %d with no pick is a PANIC PICK" % outcome["round"])
		check(SuwitController.MOVES.has(outcome["player"]), "the panic pick is a real move")
	var moves := {}
	for seed: int in 30:
		_rounds.clear()
		_suwit.start_duel(&"catfish_bruiser", 500 + seed)
		_play(func(_s: Dictionary) -> StringName: return &"")
		for outcome: Dictionary in _rounds:
			moves[outcome["player"]] = true
	check_eq(moves.size(), 3, "panic picks use all three moves")
	check(result.has("player_won"), "a match of panic picks still ends normally")
	return true


# SUWIT-006, SUWIT-007, SUWIT-008
func test_charm_charges_and_reveal() -> bool:
	for level: int in 4:
		GameState.debug_set_upgrade_level(&"charm", level)
		_suwit.start_duel(&"carp_golden", 11)
		check_eq(_suwit.get_snapshot()["charm_charges"], level, "Charm Lv%d gives %d charges" % [level, level])
	GameState.debug_set_upgrade_level(&"charm", 2)
	_suwit.start_duel(&"gourami_shady", 12)
	check(not _suwit.use_charm(), "no charm before a round starts")
	_run(SuwitController.INTRO_SEC + TICK * 2.0)
	var hidden := _suwit.debug_get_hidden_move()
	check(_suwit.use_charm(), "the charm is used")
	check_eq(_suwit.get_snapshot()["charm_move"], hidden, "it shows the real move")
	check_eq(_suwit.get_snapshot()["charm_charges"], 1, "one charge spent")
	check(not _suwit.use_charm(), "one charm at a time")
	_run(0.79)
	check_eq(_suwit.get_snapshot()["charm_move"], hidden, "still showing at 0.79 s")
	_run(0.03)
	check_eq(_suwit.get_snapshot()["charm_move"], &"", "gone after 0.8 s")
	check_eq(_suwit.debug_get_hidden_move(), hidden, "the charm never changed the fish's move")
	_suwit.choose_move(_beater(hidden))
	_run(2.5)
	check_eq(_rounds[0]["outcome"], SuwitController.OUTCOME_WIN, "knowing the real move wins the round")

	_suwit.start_duel(&"gourami_shady", 13)
	check_eq(_suwit.get_snapshot()["charm_charges"], 2, "the next duel starts with full charges again")
	return true


func test_reading_the_charm_beats_every_fish() -> bool:
	GameState.debug_set_upgrade_level(&"charm", 3)
	for fish: FishData in GameData.get_all_fish():
		_suwit.start_duel(fish.id, 41 + fish.tier)
		var result := _play(_charm_reader)
		check(result["player_won"] or int(result["metrics"]["charges_left"]) == 0, "%s: the charm wins rounds while it lasts" % fish.id)
	return true


func test_same_seed_same_match_and_result_contract() -> bool:
	_suwit.start_duel(&"snakehead_sergeant", 99)
	_play(func(_s: Dictionary) -> StringName: return &"paper")
	var first := _suwit.get_history()
	_suwit.start_duel(&"snakehead_sergeant", 99)
	var result := _play(func(_s: Dictionary) -> StringName: return &"paper")
	check_eq(_suwit.get_history(), first, "the same seed and picks give the same match")
	for key: String in ["duel_id", "fish_id", "player_won", "duration_sec", "seed", "metrics"]:
		check(result.has(key), "result has %s (GDD 169.14)" % key)
	check_eq(result["duel_id"], &"suwit", "duel id")
	GameState.record_encounter(&"snakehead_sergeant")
	DuelOutcome.commit(result)
	check_eq(GameState.get_stat(&"suwit_wins"), 1 if result["player_won"] else 0, "suwit wins are counted")
	return true


## Uses the charm while it lasts and answers the real move; otherwise trusts the tell.
func _charm_reader(s: Dictionary) -> StringName:
	if s["charm_move"] != &"":
		return _beater(s["charm_move"])
	if s["charm_charges"] > 0:
		_suwit.use_charm()
		return &""
	return &"" if s["tell"] == &"" else _beater(s["tell"])


# --- Wheel ------------------------------------------------------------------

# WHEEL-001
func test_wheel_odds_are_even() -> bool:
	GameState.set_tutorial_seen(&"wheel_seen")
	var counts := {}
	for seed: int in 100000:
		var duel := WheelController.pick_duel(&"carp_golden", seed * 2654435761 % 2147483647)
		counts[duel] = int(counts.get(duel, 0)) + 1
	# Cempaka Lake's Wheel: the four original duels (spot Wheels: suite spots).
	var lake_duels: Array[StringName] = [&"boxing", &"arm_wrestle", &"dance", &"suwit"]
	check_eq(counts.size(), 4, "all four duels come up")
	for duel: StringName in lake_duels:
		check_near(float(counts.get(duel, 0)) / 100000.0, 0.25, 0.01, "%s about 25%%" % duel)
	var segments := {}
	for duel: StringName in WheelController.SEGMENTS:
		segments[duel] = int(segments.get(duel, 0)) + 1
	check_eq(WheelController.SEGMENTS.size(), 8, "eight segments")
	for duel: StringName in lake_duels:
		check_eq(segments[duel], 2, "%s has two segments" % duel)
	return true


# WHEEL-002
func test_wheel_lands_on_its_choice_at_any_frame_rate() -> bool:
	GameState.set_tutorial_seen(&"wheel_seen")
	for seed: int in [3, 17, 123, 9999]:
		var outcomes: Array = []
		for step: float in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0, 0.25]:
			var wheel := WheelController.new()
			wheel.auto_advance = false
			wheel.start_wheel(&"tilapia_gym_rat", seed, false)
			var chosen := wheel.get_preselected_duel_id()
			var resolved: Array[StringName] = []
			wheel.wheel_resolved.connect(func(duel: StringName) -> void: resolved.append(duel))
			var spin := wheel.get_spin_sec()
			check(spin >= 3.1 and spin <= 4.0, "seed %d: spin lasts %.2f s" % [seed, spin])
			# The wheel caps one step at 0.1 s, so long frames take more of them.
			for _frame: int in ceili(6.0 / minf(step, 0.1)):
				wheel.advance(step)
			check_eq(resolved, [chosen] as Array[StringName], "seed %d: resolves once to the preselected duel" % seed)
			check_eq(WheelController.SEGMENTS[wheel.get_segment_under_pointer()], chosen, "seed %d at %.3f s frames: the pointer shows it" % [seed, step])
			outcomes.append(chosen)
			wheel.free()
		check(outcomes.count(outcomes[0]) == outcomes.size(), "seed %d: frame rate never changes the outcome" % seed)
	return true


# WHEEL-005 and skipping
func test_first_wheel_is_boxing_and_cannot_be_skipped() -> bool:
	for seed: int in 50:
		check_eq(WheelController.pick_duel(&"catfish_bruiser", seed), &"boxing", "the tutorial Wheel lands on Boxing (seed %d)" % seed)
	var wheel := WheelController.new()
	wheel.auto_advance = false
	wheel.start_wheel(&"catfish_bruiser", 5, false)
	wheel.request_skip()
	check_eq(wheel.get_state(), WheelController.STATE_SPINNING, "the first Wheel cannot be skipped")
	wheel.free()
	GameState.set_tutorial_seen(&"wheel_seen")
	wheel = WheelController.new()
	wheel.auto_advance = false
	wheel.start_wheel(&"catfish_bruiser", 5, true)
	wheel.request_skip()
	check_eq(wheel.get_state(), WheelController.STATE_REVEAL, "later Wheels skip to the reveal")
	check(wheel.was_skipped(), "and say so")
	check_eq(WheelController.SEGMENTS[wheel.get_segment_under_pointer()], wheel.get_preselected_duel_id(), "a skip still lands on the chosen duel")
	wheel.free()
	return true


# --- Dialogue ---------------------------------------------------------------

func test_every_fish_line_exists() -> bool:
	var missing := PackedStringArray()
	for key: String in FishDialogue.required_keys():
		if not TextDb.has_key(StringName(key)):
			missing.append(key)
	check_empty(missing, "missing dialogue keys")
	for fish: FishData in GameData.get_all_fish():
		var first := FishDialogue.first_meeting(fish.id)
		check(first.size() >= 5, "%s has its first-meeting conversation (%d lines)" % [fish.id, first.size()])
		check_eq(first[0]["speaker"], fish.display_name.to_upper(), "%s speaks first" % fish.id)
		var darto_lines := 0
		for line: Dictionary in first:
			darto_lines += 1 if line["speaker"] == "DARTO" else 0
			check(str(line["text"]).length() > 1, "%s: no empty line" % fish.id)
		check(darto_lines >= 1, "%s: Darto answers" % fish.id)
	check_eq(FishDialogue.first_meeting(&"catfish_bruiser")[-1]["text"], "Square up.", "the catfish ends with Square up.")
	var boss := FishDialogue.after_duel(&"arowana_don", true, 1, true)
	check_eq(boss[-2]["text"], "You disgust me.", "Don Arowana's first defeat has its own exchange")
	check_eq(boss[-1]["text"], "That's not a no.", "and Darto has the last word")
	return true


func test_dialogue_picks_are_seeded_and_separate() -> bool:
	var line := FishDialogue.pick(&"carp_golden", FishDialogue.POOL_LAND, 42)
	check_eq(FishDialogue.pick(&"carp_golden", FishDialogue.POOL_LAND, 42), line, "the same seed gives the same line")
	var seen := {}
	for seed: int in 200:
		seen[FishDialogue.pick(&"carp_golden", FishDialogue.POOL_LAND, seed)["text"]] = true
	check_eq(seen.size(), 4, "every LAND line comes up")
	# Picking dialogue does not touch the game RNG.
	var before := RNGService.get_persist_state()
	for seed: int in 50:
		FishDialogue.after_duel(&"gourami_shady", seed % 2 == 0, seed)
	check_eq(RNGService.get_persist_state(), before, "dialogue never advances the gameplay RNG")
	var after_win := FishDialogue.after_duel(&"tilapia_gym_rat", true, 7)
	check_eq(after_win.size(), 2, "after a duel: the fish, then Darto")
	check_eq(after_win[1]["speaker"], "DARTO", "Darto reacts last")
	return true
