extends "res://tests/test_suite.gd"
## Panco Maut rules (GDD 50-56, 139, 169.13, 176.13; QA matrix ARM-001..011).

const STORAGE_DIR := "user://test_tmp/arm_wrestle"
const TICK := ArmWrestleController.TICK_SEC
const SEED := 2024

var _arm: ArmWrestleController
var _events: Array[String] = []


func get_suite_name() -> String:
	return "arm_wrestle"


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
	_arm = ArmWrestleController.new()
	_arm.auto_advance = false
	_arm.burst_warning_started.connect(func(_sec: float) -> void: _events.append("warning@%.3f" % _snap("elapsed")))
	_arm.burst_started.connect(func(_sec: float) -> void: _events.append("burst@%.3f" % _snap("elapsed")))
	_arm.burst_ended.connect(func() -> void: _events.append("burst_end@%.3f" % _snap("elapsed")))
	_arm.sudden_grip_started.connect(func() -> void: _events.append("sudden_grip"))
	_arm.rematch_started.connect(func() -> void: _events.append("rematch"))
	_arm.duel_finished.connect(func(_result: Dictionary) -> void: _events.append("finished"))


func after_each() -> void:
	_arm.free()


func _snap(key: String) -> Variant:
	return _arm.get_snapshot()[key]


func _run(seconds: float) -> void:
	for _tick: int in roundi(seconds / TICK):
		_arm.advance(TICK)


func _start(fish_id: StringName, seed: int = SEED) -> void:
	_arm.start_duel(fish_id, seed)
	_run(ArmWrestleController.INTRO_SEC + TICK)


## Plays to the end with the bot at `rate` taps a second (0 = never taps).
func _play_out(rate: float, rests: bool = false) -> Dictionary:
	var bot := ArmWrestleBot.new()
	bot.taps_per_sec = maxf(rate, 0.1)
	bot.rests = rests
	for _tick: int in roundi(120.0 / TICK):
		if _arm.get_state() == ArmWrestleController.STATE_FINISHED:
			break
		if rate > 0.0:
			bot.play(_arm)
		_arm.advance(TICK)
	return _arm.get_result()


## Keeps the hands at `value` for `seconds`, as if both sides were equal.
func _hold(value: float, seconds: float) -> void:
	for _tick: int in roundi(seconds / TICK):
		if _arm.get_state() == ArmWrestleController.STATE_FINISHED:
			return
		_arm.debug_set_position(value)
		_arm.advance(TICK)


func _times(prefix: String) -> Array[float]:
	var times: Array[float] = []
	for event: String in _events:
		if event.begins_with(prefix + "@"):
			times.append(event.get_slice("@", 1).to_float())
	return times


# --- Tests ------------------------------------------------------------------

# ARM-001
func test_match_starts_level_with_full_stamina() -> bool:
	_arm.start_duel(&"catfish_bruiser", SEED)
	check_eq(_snap("position"), 0.0, "position starts at 0")
	check_eq(_snap("stamina"), 100.0, "stamina starts full")
	check_eq(_snap("time_left"), 32.0, "a 32 second round")
	check(not _arm.request_mash(), "no press counts during the intro")
	_run(ArmWrestleController.INTRO_SEC + TICK)
	check_eq(_arm.get_state(), ArmWrestleController.STATE_PULLING, "the pull starts after the intro")
	return true


# ARM-002
func test_accepted_press_pushes_and_costs_stamina() -> bool:
	_start(&"catfish_bruiser")
	var before: float = _snap("position")
	check(_arm.request_mash(), "the first press is accepted")
	check_near(_snap("position"), before + 4.8, 0.0001, "+4.8 at full power")
	check_eq(_snap("stamina"), 93.0, "-7 stamina")
	return true


# ARM-003
func test_presses_above_ten_a_second_are_ignored() -> bool:
	_start(&"catfish_bruiser")
	# Twenty presses in the same instant: only the saved-up ones count.
	var accepted := 0
	for _press: int in 20:
		if _arm.request_mash():
			accepted += 1
	check_eq(accepted, int(ArmWrestleController.PRESS_BURST), "only the small saved-up allowance is taken at once")
	check_eq(_snap("stamina"), 100.0 - 7.0 * accepted, "ignored presses cost nothing")

	# Over two seconds of tapping 30 times a second, about 20 are accepted.
	_start(&"catfish_bruiser")
	accepted = 0
	var taps := 0
	for step: int in 240:
		if step % 4 == 0:
			taps += 1
			if _arm.request_mash():
				accepted += 1
		_arm.advance(TICK)
	check_eq(taps, 60, "sixty taps in two seconds")
	check(accepted >= 20 and accepted <= 22, "accepted presses stay at 10 a second (%d)" % accepted)

	# Exactly ten a second: every tap counts.
	_start(&"catfish_bruiser")
	accepted = 0
	for step: int in 240:
		if step % 12 == 0 and _arm.request_mash():
			accepted += 1
		_arm.advance(TICK)
	check_eq(accepted, 20, "at the cap, nothing is lost")

	# Tapping at 14 a second still gets the full rate, not every other tap.
	_start(&"catfish_bruiser")
	accepted = 0
	var next := 0.0
	for step: int in 240:
		if float(step) * TICK >= next:
			next += 1.0 / 14.0
			if _arm.request_mash():
				accepted += 1
		_arm.advance(TICK)
	check(accepted >= 19, "tapping faster than the cap is not punished (%d accepted)" % accepted)
	return true


# ARM-004, ARM-005
func test_stamina_returns_after_a_short_rest() -> bool:
	_start(&"catfish_bruiser")
	for _press: int in 2:
		_arm.request_mash()
	check_eq(_snap("stamina"), 86.0, "two presses cost 14")
	_run(0.34)
	check_eq(_snap("stamina"), 86.0, "nothing comes back for 0.35 s")
	_run(0.02)
	check(float(_snap("stamina")) > 86.0, "then stamina returns")
	_run(0.25)
	var start: float = _snap("stamina")
	_run(0.25)
	check_near(float(_snap("stamina")) - start, 26.0 * 0.25, 0.05, "at 26 per second")
	check(_snap("resting"), "the snapshot says Darto is resting")
	_run(5.0)
	check_eq(_snap("stamina"), 100.0, "never above the maximum")
	return true


# ARM-006
func test_herbal_tonic_raises_maximum_stamina() -> bool:
	var expected: Array[float] = [100.0, 120.0, 140.0, 160.0]
	for level: int in expected.size():
		GameState.debug_set_upgrade_level(&"tonic", level)
		_arm.start_duel(&"catfish_bruiser", SEED)
		check_near(_snap("max_stamina"), expected[level], 0.0001, "Tonic Lv%d stamina" % level)
		check_near(_snap("stamina"), expected[level], 0.0001, "starts full at Lv%d" % level)
	return true


# ARM-007
func test_power_bands_follow_stamina() -> bool:
	check_eq(ArmWrestleController.power_for(1.0), 1.0, "full stamina: 100%")
	check_eq(ArmWrestleController.power_for(0.61), 1.0, "above 60%: 100%")
	check_eq(ArmWrestleController.power_for(0.6), 0.85, "60%: 85%")
	check_eq(ArmWrestleController.power_for(0.3), 0.85, "30%: 85%")
	check_eq(ArmWrestleController.power_for(0.29), 0.65, "below 30%: 65%")
	check_eq(ArmWrestleController.power_for(0.1), 0.65, "10%: 65%")
	check_eq(ArmWrestleController.power_for(0.09), 0.42, "below 10%: 42%")
	check_eq(ArmWrestleController.power_for(0.0), 0.42, "empty: 42%, never zero")

	# Through the real presses: the push follows the band of the stamina before it.
	_start(&"catfish_bruiser")
	var pushes: Array[float] = []
	for _press: int in 16:
		_arm.debug_set_position(0.0)
		_arm.request_mash()
		pushes.append(_snap("position"))
		_run(0.1)
	check_near(pushes[0], 4.8, 0.0001, "first press at 100%")
	check_near(pushes[6], 4.08, 0.0001, "press at 58 stamina: 85%")
	check_near(pushes[10], 4.08, 0.0001, "press at exactly 30 stamina: still 85%")
	check_near(pushes[11], 3.12, 0.0001, "press at 23 stamina: 65%")
	check_near(pushes[15], 2.016, 0.0001, "an empty Darto still pushes at 42%")
	return true


func test_the_fish_pushes_and_bursts_after_a_warning() -> bool:
	_start(&"snakehead_sergeant")
	var config := GameData.get_arm_wrestle_config()
	var fish := GameData.get_fish(&"snakehead_sergeant")
	var steady := fish.arm_strength * config.fish_pressure_per_strength
	_run(1.0)
	check_near(_snap("position"), -steady * 1.0, 0.05, "the fish pushes steadily")
	_hold(0.0, 29.0)
	var warnings := _times("warning")
	var bursts := _times("burst")
	check(bursts.size() >= 4, "the fish bursts several times in a round (%d)" % bursts.size())
	check_eq(warnings.size(), bursts.size(), "every burst has a warning")
	for index: int in bursts.size():
		check_near(bursts[index] - warnings[index], config.burst_warning_sec, 0.01, "burst %d comes %.2f s after its warning" % [index, config.burst_warning_sec])
	var ends := _times("burst_end")
	for index: int in ends.size():
		var length := ends[index] - bursts[index]
		check(length >= config.burst_min_sec - 0.01 and length <= config.burst_max_sec + 0.01, "burst %d lasts %.2f s" % [index, length])
		if index + 1 < warnings.size():
			var rest := warnings[index + 1] - ends[index]
			check(rest >= config.burst_cooldown_min_sec - 0.01 and rest <= config.burst_cooldown_max_sec + 0.01, "cooldown %d is %.2f s" % [index, rest])
	return true


func test_higher_tiers_burst_harder() -> bool:
	var config := GameData.get_arm_wrestle_config()
	var previous := 0.0
	# The tier ladder of Cempaka Lake (each spot has its own ladder, and its
	# fish still burst: test_every_fish_falls_to_a_comfortable_rate).
	for fish: FishData in GameData.get_location_fish(ContentIds.START_LOCATION):
		_start(fish.id)
		check(await_burst(), "%s bursts" % fish.id)
		var steady := fish.arm_strength * config.fish_pressure_per_strength
		var extra: float = float(_snap("fish_force")) - steady
		check(extra > previous, "%s bursts harder than the tier below (%.1f)" % [fish.id, extra])
		previous = extra
	return true


func await_burst() -> bool:
	for _tick: int in roundi(10.0 / TICK):
		if _snap("bursting"):
			return true
		_arm.advance(TICK)
	return false


# ARM-009
func test_timeout_follows_the_position() -> bool:
	_start(&"catfish_bruiser")
	var won := _play_out(5.0)
	check(bool(won["metrics"]["timed_out"]) or won["player_won"], "a steady 5 taps a second reaches time or wins")
	if bool(won["metrics"]["timed_out"]):
		check(float(won["metrics"]["position"]) > 0.0 and won["player_won"], "ahead at time: the player wins")
		check_near(won["duration_sec"], 32.0, 0.05, "the round is 32 s")

	_start(&"tilapia_gym_rat")
	_hold(-10.0, 31.9)
	var lost := _play_out(0.0)
	check(bool(lost["metrics"]["timed_out"]), "the clock runs out")
	check(float(lost["metrics"]["position"]) < -2.0 and not lost["player_won"], "behind at time: the fish wins")
	_start(&"tilapia_gym_rat")
	_hold(10.0, 31.95)
	var ahead := _play_out(0.0)
	check(bool(ahead["metrics"]["timed_out"]) and ahead["player_won"], "ahead at time: the player wins")
	return true


func test_reaching_either_end_wins_at_once() -> bool:
	_start(&"catfish_bruiser")
	var result := _play_out(10.0)
	check(result["player_won"] and not bool(result["metrics"]["timed_out"]), "pinning the fish wins before time")
	check_eq(result["metrics"]["position"], 100.0, "at +100")
	_start(&"catfish_bruiser")
	result = _play_out(0.0)
	check(not result["player_won"], "never pressing loses")
	check_eq(result["metrics"]["position"], -100.0, "at -100")
	return true


# ARM-010
func test_near_zero_at_time_is_sudden_grip() -> bool:
	_start(&"gourami_shady")
	_hold(1.5, 32.04)
	check(_events.has("sudden_grip"), "within 2 of zero at time: Sudden Grip")
	check_eq(_arm.get_state(), ArmWrestleController.STATE_SUDDEN_GRIP, "the match goes on")
	check_near(_snap("time_left"), 5.0 - 0.04, 0.02, "for at most 5 more seconds")
	# Pressing hard reaches +5 first.
	var result := _play_out(10.0)
	check(result["player_won"], "first to magnitude 5 wins")
	check(bool(result["metrics"]["sudden_grip"]), "the result records the Sudden Grip")
	check(float(result["duration_sec"]) < 37.0, "inside the extra 5 s")

	# Nobody gets there: the exact position decides.
	_events.clear()
	_start(&"gourami_shady")
	_hold(-1.0, 32.04)
	for _tick: int in roundi(5.2 / TICK):
		if _arm.get_state() == ArmWrestleController.STATE_FINISHED:
			break
		_arm.debug_set_position(-0.25)
		_arm.advance(TICK)
	check(not _arm.get_result()["player_won"], "still slightly behind after 5 s: the fish wins")
	return true


# ARM-011 and the non-boss tiebreak.
func test_dead_level_is_settled_without_luck() -> bool:
	for fish_id: StringName in [&"carp_golden", &"arowana_don"]:
		_events.clear()
		_start(fish_id)
		_hold(0.0, 31.99)
		for _tick: int in roundi(5.2 / TICK):
			if _arm.get_state() != ArmWrestleController.STATE_PULLING and _arm.get_state() != ArmWrestleController.STATE_SUDDEN_GRIP:
				break
			# Offset the fish's push of this tick so the hands end it dead level.
			_arm.debug_set_position(_arm.fish_force() * TICK)
			_arm.advance(TICK)
		if fish_id == &"carp_golden":
			check_eq(_arm.get_state(), ArmWrestleController.STATE_FINISHED, "a non-boss dead heat ends")
			check(_arm.get_result()["player_won"], "and the player wins it (GDD Section 56)")
		else:
			check(_events.has("rematch"), "Don Arowana demands a rematch")
			check_eq(_arm.get_state(), ArmWrestleController.STATE_REMATCH, "the rematch is on")
			check_eq(_snap("position"), 0.0, "from the middle")
			check_near(_snap("time_left"), 10.0, 0.02, "for 10 seconds")
			check_eq(_snap("stamina"), 100.0, "with fresh stamina")
			var result := _play_out(10.0)
			check(result["player_won"], "a strong rematch wins")
			check(bool(result["metrics"]["rematch"]), "the result records the rematch")
	return true


func test_every_fish_falls_to_a_comfortable_rate() -> bool:
	for fish: FishData in GameData.get_all_fish():
		_start(fish.id, SEED + fish.tier)
		var comfortable := _play_out(7.0)
		check(comfortable["player_won"], "%s: 7 taps a second wins (GDD 176.13)" % fish.id)
		_start(fish.id, SEED + fish.tier)
		check(not _play_out(0.0)["player_won"], "%s beats a player who does nothing" % fish.id)
	_start(&"catfish_bruiser")
	check(_play_out(4.0)["player_won"], "the first fish is beaten even at 4 taps a second")
	return true


func test_same_seed_same_match() -> bool:
	var runs: Array[Dictionary] = []
	for _run_index: int in 2:
		_events.clear()
		_start(&"carp_golden", 99)
		var result := _play_out(6.0)
		runs.append({"events": _events.duplicate(), "position": result["metrics"]["position"], "won": result["player_won"]})
	check_eq(runs[0], runs[1], "the same seed and taps give the same match")
	_events.clear()
	_start(&"carp_golden", 100)
	_play_out(6.0)
	check(_events != runs[0]["events"], "another seed bursts at other times")
	return true


func test_result_contract_and_debug_override() -> bool:
	_start(&"tilapia_gym_rat", 31)
	var result := _play_out(8.0)
	for key: String in ["duel_id", "fish_id", "player_won", "duration_sec", "seed", "metrics"]:
		check(result.has(key), "result has %s (GDD 169.14)" % key)
	check_eq(result["duel_id"], &"arm_wrestle", "duel id")
	check_eq(result["seed"], 31, "seed")
	check_eq(_events.count("finished"), 1, "duel_finished fires once")
	check(not _arm.request_mash(), "a finished match takes no presses")

	var before := GameState.export_save_state()
	DebugService.set_forced_result(&"win")
	_start(&"arowana_don")
	check_eq(_arm.get_state(), ArmWrestleController.STATE_FINISHED, "a forced result ends the match after the intro")
	check(_arm.get_result()["player_won"], "forced win")
	var after := GameState.export_save_state()
	for key: String in ["cash", "bucket", "fish_book", "stats"]:
		check_eq(after[key], before[key], "%s is unchanged by the match itself" % key)

	DebugService.clear_forces()
	GameState.record_encounter(&"tilapia_gym_rat")
	check(DuelOutcome.commit(result), "the shared commit takes an arm wrestling result")
	check_eq(GameState.get_stat(&"arm_wrestle_wins"), 1 if result["player_won"] else 0, "arm wrestling wins are counted")
	return true
