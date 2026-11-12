extends "res://tests/test_suite.gd"
## Fishing rules (GDD Sections 24-37, QA matrix 180.3). The controller and the
## reel simulation are driven by hand with fixed time steps, so every case is
## exact and independent of frame rate.

const STORAGE_DIR := "user://test_tmp/fishing"
const STEP := 0.02
const ROLLS := 100000

var _controller: FishingController
var _events: Array[String] = []


func get_suite_name() -> String:
	return "fishing"


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
	# Past the scripted first fish, so encounters follow the real tables.
	GameState.set_tutorial_seen(&"fishing_seen")
	GameState.set_tutorial_seen(&"reeling_seen")
	_events.clear()
	_controller = FishingController.new()
	_controller.auto_advance = false
	_controller.fishing_state_changed.connect(func(state: StringName) -> void: _events.append("state:%s" % state))
	_controller.float_released.connect(func() -> void: _events.append("float_released"))
	_controller.float_landed.connect(func() -> void: _events.append("float_landed"))
	_controller.nibbled.connect(func() -> void: _events.append("nibbled"))
	_controller.false_strike.connect(func() -> void: _events.append("false_strike"))
	_controller.fish_landed.connect(func(fish_id: StringName, _weight: float) -> void: _events.append("fish_landed:%s" % fish_id))
	_controller.trash_caught.connect(func(item_id: StringName) -> void: _events.append("trash_caught:%s" % item_id))
	_controller.fishing_failed.connect(func(reason: StringName) -> void: _events.append("failed:%s" % reason))
	_controller.catch_resolved.connect(func(outcome: Dictionary) -> void: _events.append("resolved:%s" % outcome["outcome"]))


func after_each() -> void:
	_controller.free()


# --- Helpers ----------------------------------------------------------------

## Steps the controller until it reaches `state`. Returns the simulated seconds
## it took, or -1.0 if the state never came.
func _run_until(state: StringName, limit_sec: float = 30.0) -> float:
	var elapsed := 0.0
	while _controller.get_state() != state:
		if elapsed > limit_sec:
			return -1.0
		_controller.advance(STEP)
		elapsed += STEP
	return elapsed


func _cast_forced(item_id: StringName) -> void:
	DebugService.set_forced_fish(item_id)
	_controller.start_cast()


func _count(event: String) -> int:
	return _events.count(event)


# --- Cast and waiting -------------------------------------------------------

func test_cast_timeline() -> bool:
	_cast_forced(&"catfish_bruiser")
	check_eq(_controller.get_state(), FishingController.STATE_CASTING, "cast starts")
	check_eq(GameState.get_stat(&"total_casts"), 1, "cast counted")

	var released_at := -1.0
	var landed_at := -1.0
	var elapsed := 0.0
	while _controller.get_state() == FishingController.STATE_CASTING and elapsed < 3.0:
		_controller.advance(0.01)
		elapsed += 0.01
		if released_at < 0.0 and _events.has("float_released"):
			released_at = elapsed
		if landed_at < 0.0 and _events.has("float_landed"):
			landed_at = elapsed
	# FISH-002: the float leaves the rod tip 0.48 s into the cast.
	check_near(released_at, 0.48, 0.011, "float release time")
	check_near(landed_at, 1.05, 0.011, "float landing time")
	check_near(elapsed, 1.35, 0.011, "cast duration")
	check_eq(_controller.get_state(), FishingController.STATE_WAITING, "cast ends in waiting")

	_controller.start_cast()
	check_eq(GameState.get_stat(&"total_casts"), 1, "casting again mid-cast does nothing")
	return true


# FISH-004, FISH-005
func test_wait_time_formula() -> bool:
	for roll: float in [0.0, 0.25, 0.5, 0.75, 0.999]:
		var base := EncounterRoller.wait_time(roll, 0)
		check(base >= 4.5 and base <= 9.5, "Lv0 wait %.2f is inside 4.5-9.5" % base)
	check_near(EncounterRoller.wait_time(0.0, 0), 4.5, 0.0001, "Lv0 shortest wait")
	check_near(EncounterRoller.wait_time(1.0, 0), 9.5, 0.0001, "Lv0 longest wait")
	check_near(EncounterRoller.wait_time(0.5, 1), 7.0 * 0.82, 0.0001, "Lv1 is 82%")
	check_near(EncounterRoller.wait_time(0.5, 2), 7.0 * 0.64, 0.0001, "Lv2 is 64%")
	check_near(EncounterRoller.wait_time(0.5, 3), 7.0 * 0.46, 0.0001, "Lv3 is 46%")
	check_near(EncounterRoller.wait_time(0.0, 3), 4.5 * 0.46, 0.0001, "Lv3 shortest wait")
	for level: int in 4:
		check(EncounterRoller.wait_time(0.0, level) >= 1.75, "Lv%d never drops under the 1.75 s floor" % level)
	check_eq(EncounterRoller.wait_time(0.5, 9), EncounterRoller.wait_time(0.5, 3), "bait level is clamped to 3")
	return true


func test_false_nibbles_stay_inside_the_wait() -> bool:
	for seed: int in 400:
		var encounter := EncounterRoller.roll(seed * 7919 + 13, 0)
		var nibbles: Array = encounter["nibble_times"]
		if not check(nibbles.size() <= 2, "at most two false nibbles (seed %d)" % seed):
			break
		for time: float in nibbles:
			if not check(time > 0.0 and time < float(encounter["wait_sec"]), "nibble falls inside the wait (seed %d)" % seed):
				break
	return true


# FISH-007
func test_false_strike_costs_only_a_short_delay() -> bool:
	_cast_forced(&"catfish_bruiser")
	_run_until(FishingController.STATE_WAITING)
	var wait := float(_controller.get_encounter()["wait_sec"])

	_controller.attempt_strike()
	check_eq(_count("false_strike"), 1, "false strike is signalled")
	check_eq(_controller.get_state(), FishingController.STATE_WAITING, "still waiting")
	check_eq(GameState.get_stat(&"failed_strikes"), 0, "a false strike is not a failed strike")
	check_eq(GameState.get_stat(&"successful_strikes"), 0, "nor a successful one")

	var until_bite := _run_until(FishingController.STATE_STRIKE_WINDOW)
	check_near(until_bite, wait + 0.8, STEP * 2.0, "the bite comes 0.8 s later than it would have")
	return true


func test_bite_warning_precedes_the_bite() -> bool:
	_cast_forced(&"gourami_shady")
	_run_until(FishingController.STATE_BITE_WARNING)
	check_eq(_controller.get_state(), FishingController.STATE_BITE_WARNING, "the shadow shows up first")
	var lead := _run_until(FishingController.STATE_STRIKE_WINDOW)
	check_near(lead, GameData.get_fishing_balance().bite_warning_sec, STEP * 2.0, "warning lead time")
	check_eq(_events.find("state:bite_warning") < _events.find("state:strike_window"), true, "warning comes before the strike window")
	return true


# --- Strike window ----------------------------------------------------------

# FISH-008
func test_strike_windows_match_the_table() -> bool:
	var expected: Dictionary = {
		&"catfish_bruiser": 0.79, &"tilapia_gym_rat": 0.74, &"gourami_shady": 0.70,
		&"carp_golden": 0.65, &"snakehead_sergeant": 0.60, &"arowana_don": 0.55,
		&"trash_sandal": 0.90, &"trash_can": 0.90, &"trash_tyre": 0.90,
	}
	for item_id: StringName in expected:
		var encounter := EncounterRoller.roll(4242, 0, item_id)
		check_eq(encounter["item_id"], item_id, "%s is forced" % item_id)
		check_near(float(encounter["strike_window_sec"]), expected[item_id], 0.0001, "%s strike window" % item_id)

	# The window that the controller actually enforces.
	_cast_forced(&"arowana_don")
	_run_until(FishingController.STATE_STRIKE_WINDOW)
	var open_for := _run_until(FishingController.STATE_ESCAPED)
	check_near(open_for, 0.55, STEP * 2.0, "arowana window stays open for 0.55 s")
	return true


# FISH-009
func test_late_strike_lets_the_fish_escape() -> bool:
	_cast_forced(&"carp_golden")
	_run_until(FishingController.STATE_STRIKE_WINDOW)
	_run_until(FishingController.STATE_ESCAPED)
	check_eq(_count("failed:missed_strike"), 1, "missed strike is reported once")
	check_eq(GameState.get_stat(&"failed_strikes"), 1, "failed strike counted")
	check_eq(GameState.get_bucket_total_count(), 0, "nothing enters the bucket")
	check_eq(GameState.get_cash(), 8430, "nothing is lost")

	_controller.attempt_strike()
	check_eq(_controller.get_state(), FishingController.STATE_ESCAPED, "a strike after the escape does nothing")
	_run_until(FishingController.STATE_IDLE)
	check_eq(_controller.get_state(), FishingController.STATE_IDLE, "back to idle, ready to cast again")
	check_eq(_count("resolved:duel") + _count("resolved:bucket") + _count("resolved:bucket_no_duel"), 0, "no catch was resolved")
	return true


func test_slow_frame_cannot_swallow_the_strike_window() -> bool:
	_cast_forced(&"arowana_don")
	_run_until(FishingController.STATE_STRIKE_WINDOW)
	# One five-second hitch must count as a single capped step, not five seconds.
	_controller.advance(5.0)
	check_eq(_controller.get_state(), FishingController.STATE_STRIKE_WINDOW, "window survives a long frame")
	check(_controller.get_strike_window_ratio() > 0.7, "only one capped step was consumed")
	return true


# --- Trash ------------------------------------------------------------------

# FISH-010
func test_trash_goes_straight_to_the_bucket() -> bool:
	_cast_forced(&"trash_tyre")
	_run_until(FishingController.STATE_STRIKE_WINDOW)
	_controller.attempt_strike()
	check_eq(_controller.get_state(), FishingController.STATE_LANDED, "trash skips the reel")
	check_eq(_count("trash_caught:trash_tyre"), 1, "trash catch signalled")
	check_eq(_count("state:reeling"), 0, "no reel minigame for trash")

	_run_until(FishingController.STATE_IDLE)
	check_eq(_count("resolved:bucket"), 1, "resolved into the bucket")
	check_eq(GameState.get_bucket_quantity(&"trash_tyre"), 1, "tyre is in the bucket")
	check_eq(GameState.get_stat(&"trash_caught"), 1, "trash stat")
	check_eq(GameState.get_stat(&"fish_landed"), 0, "trash is not a landed fish")
	check(not SceneRouter.is_transitioning(), "no Wheel, no duel, no scene change")
	check_eq(GameState.current_fish, &"", "no duel context was created")
	check_eq(read_json(SaveManager.get_save_path())["bucket"]["trash_tyre"], 1, "catch was autosaved")
	return true


# --- Encounter distribution -------------------------------------------------

# FISH-011 (tolerances from GDD 179.2)
func test_encounter_distribution_over_100k_rolls() -> bool:
	var expected: Dictionary = {
		&"catfish_bruiser": 0.2520, &"tilapia_gym_rat": 0.2016, &"gourami_shady": 0.1680,
		&"carp_golden": 0.1176, &"snakehead_sergeant": 0.0756, &"arowana_don": 0.0252,
	}
	var counts: Dictionary = {}
	var trash_total := 0
	var trash_probability := GameData.get_fishing_balance().trash_probability
	RNGService.initialize_session(1800000)
	for _index: int in ROLLS:
		var seed := RNGService.next_encounter_seed()
		var item: StringName
		if RNGService.roll_float(&"trash", seed) < trash_probability:
			trash_total += 1
			item = EncounterRoller.pick_trash(RNGService.roll_float(&"trash_type", seed))
		else:
			item = EncounterRoller.pick_fish(RNGService.roll_float(&"fish", seed))
		counts[item] = int(counts.get(item, 0)) + 1

	check_near(float(trash_total) / ROLLS, 0.16, 0.005, "trash share")
	for fish_id: StringName in expected:
		var tolerance := 0.002 if fish_id == &"arowana_don" else 0.005
		check_near(float(counts.get(fish_id, 0)) / ROLLS, expected[fish_id], tolerance, "%s share" % fish_id)
	var total := 0
	for item: StringName in counts:
		total += int(counts[item])
	check_eq(total, ROLLS, "every roll produced exactly one result")
	return true


func test_trash_subtype_distribution_over_100k_rolls() -> bool:
	var counts: Dictionary = {&"trash_sandal": 0, &"trash_can": 0, &"trash_tyre": 0}
	for index: int in ROLLS:
		var item := EncounterRoller.pick_trash(RNGService.roll_float(&"trash_type", index * 31 + 7))
		counts[item] = int(counts[item]) + 1
	check_near(float(counts[&"trash_sandal"]) / ROLLS, 0.45, 0.0075, "sandal share")
	check_near(float(counts[&"trash_can"]) / ROLLS, 0.40, 0.0075, "can share")
	check_near(float(counts[&"trash_tyre"]) / ROLLS, 0.15, 0.0075, "tyre share")
	return true


func test_encounter_is_reproducible_from_its_seed() -> bool:
	var first := EncounterRoller.roll(918221, 1)
	var second := EncounterRoller.roll(918221, 1)
	check_eq(JSON.stringify(first), JSON.stringify(second), "same seed, same encounter")
	check(JSON.stringify(EncounterRoller.roll(918222, 1)) != JSON.stringify(first), "another seed differs")
	check_eq(EncounterRoller.pick_fish(0.0), &"catfish_bruiser", "lowest roll is the most common fish")
	check_eq(EncounterRoller.pick_fish(0.9999), &"arowana_don", "highest roll is the rarest fish")
	return true


func test_weights_stay_in_the_species_range() -> bool:
	var fish := GameData.get_fish(&"arowana_don")
	var threshold := lerpf(fish.weight_min_kg, fish.weight_max_kg, 0.9)
	for index: int in 200:
		var roll := float(index) / 200.0
		var normal := EncounterRoller.weight(fish, roll, false)
		var big := EncounterRoller.weight(fish, roll, true)
		if not check(normal >= fish.weight_min_kg and normal <= threshold + 0.01, "normal weight %.2f is below the top 10%%" % normal):
			break
		if not check(big >= threshold - 0.01 and big <= fish.weight_max_kg, "BIG ONE weight %.2f is in the top 10%%" % big):
			break
	return true


func test_first_catch_is_always_bruiser_catfish() -> bool:
	GameState.clear_game()
	GameState.new_game()
	for _attempt: int in 6:
		_controller.start_cast()
		check_eq(_controller.get_encounter().get("item_id"), &"catfish_bruiser", "first fish is scripted")
		_controller.cancel_to_idle()
	# Once a fish has been landed, the lake plays by its normal odds.
	GameState.set_tutorial_seen(&"reeling_seen")
	var others := 0
	for _attempt: int in 40:
		_controller.start_cast()
		if _controller.get_encounter().get("item_id") != &"catfish_bruiser":
			others += 1
		_controller.cancel_to_idle()
	check(others > 0, "later casts roll other results")
	return true


# --- Reel -------------------------------------------------------------------

func _reel_for(fish_id: StringName, rod_level: int = 0) -> ReelSimulation:
	var reel := ReelSimulation.new()
	reel.setup(GameData.get_fish(fish_id), rod_level, 777)
	return reel


func test_marker_speeds() -> bool:
	var reel := _reel_for(&"catfish_bruiser")
	reel.marker = 0.5
	# After the 0.12 s ease-in the marker moves at its full speed.
	for _index: int in 20:
		reel.step(0.01, true)
	check_near(reel.marker_velocity, 0.72, 0.0001, "hold speed")
	for _index: int in 20:
		reel.step(0.01, false)
	check_near(reel.marker_velocity, -0.58, 0.0001, "release speed")

	reel.marker = 0.999
	reel.marker_velocity = 0.72
	for _index: int in 30:
		reel.step(0.01, true)
	check_eq(reel.marker, 1.0, "marker stops at the top")
	return true


func test_landing_and_stress_rates() -> bool:
	var reel := _reel_for(&"tilapia_gym_rat")

	# Inside the zone and holding: landing +18/s, stress recovers 30/s.
	reel.marker = reel.zone_center
	reel.marker_velocity = 0.0
	reel.stress = 50.0
	reel.landing = 10.0
	reel.step(0.1, true)
	check_near(reel.landing, 11.8, 0.001, "landing gain inside the zone")
	check_near(reel.stress, 47.0, 0.001, "stress recovery inside the zone")

	# Outside the zone and holding: landing -3/s, stress +35/s for Tilapia.
	reel = _reel_for(&"tilapia_gym_rat")
	reel.zone_center = 0.2
	reel.marker = 0.95
	reel.stress = 50.0
	reel.landing = 10.0
	reel.step(0.1, true)
	check_near(reel.landing, 9.7, 0.001, "landing loss outside the zone")
	check_near(reel.stress, 53.5, 0.001, "stress gain outside the zone")

	# Outside the zone and released: landing holds, stress recovers 16/s.
	reel = _reel_for(&"tilapia_gym_rat")
	reel.zone_center = 0.8
	reel.marker = 0.05
	reel.stress = 50.0
	reel.landing = 10.0
	reel.step(0.1, false)
	check_near(reel.landing, 10.0, 0.001, "landing unchanged while released")
	check_near(reel.stress, 48.4, 0.001, "stress recovery while released")

	reel.landing = 0.0
	reel.zone_center = 0.2
	reel.marker = 0.95
	reel.step(0.1, true)
	check_eq(reel.landing, 0.0, "landing never goes below zero")
	return true


# FISH-016
func test_carbon_rod_widens_the_zone_up_to_the_clamp() -> bool:
	var catfish := GameData.get_fish(&"catfish_bruiser")
	var arowana := GameData.get_fish(&"arowana_don")
	check_near(ReelSimulation.half_width_for(catfish, 0), 0.175, 0.0001, "catfish Lv0")
	check_near(ReelSimulation.half_width_for(catfish, 1), 0.210, 0.0001, "catfish Lv1")
	check_near(ReelSimulation.half_width_for(catfish, 2), 0.245, 0.0001, "catfish Lv2 reaches the clamp")
	check_near(ReelSimulation.half_width_for(catfish, 3), 0.245, 0.0001, "catfish Lv3 stays clamped")
	check_near(ReelSimulation.half_width_for(arowana, 0), 0.110, 0.0001, "arowana Lv0")
	check_near(ReelSimulation.half_width_for(arowana, 3), 0.215, 0.0001, "arowana Lv3")
	for fish: FishData in GameData.get_all_fish():
		for level: int in 4:
			check(ReelSimulation.half_width_for(fish, level) <= 0.245, "%s Lv%d is within the clamp" % [fish.id, level])
	return true


func test_zone_glides_within_the_fish_speed() -> bool:
	for fish: FishData in GameData.get_all_fish():
		var reel := _reel_for(fish.id)
		var fastest := 0.0
		var in_bounds := true
		var previous := reel.zone_center
		for _index: int in 2000:
			reel.step(0.01, false)
			fastest = maxf(fastest, absf(reel.zone_center - previous) / 0.01)
			previous = reel.zone_center
			in_bounds = in_bounds and reel.zone_center >= reel.zone_half_width - 0.0001 and reel.zone_center <= 1.0 - reel.zone_half_width + 0.0001
		check(fastest <= fish.reel_move_speed + 0.0001, "%s zone never exceeds %.2f/s (peak %.3f)" % [fish.id, fish.reel_move_speed, fastest])
		check(fastest > fish.reel_move_speed * 0.5, "%s zone really moves" % fish.id)
		check(in_bounds, "%s zone stays on the track" % fish.id)
	return true


func test_reel_is_deterministic() -> bool:
	var a := _reel_for(&"snakehead_sergeant")
	var b := _reel_for(&"snakehead_sergeant")
	for index: int in 600:
		var held := index % 40 < 22
		a.step(0.016, held)
		b.step(0.016, held)
	check_eq(a.zone_center, b.zone_center, "same seed and input give the same zone path")
	check_eq(a.landing, b.landing, "and the same landing progress")
	check_eq(a.stress, b.stress, "and the same stress")
	return true


func test_stress_bands() -> bool:
	var reel := _reel_for(&"catfish_bruiser")
	for case: Array in [[0.0, 0], [39.9, 0], [40.0, 1], [69.9, 1], [70.0, 2], [89.9, 2], [90.0, 3], [100.0, 3]]:
		reel.stress = case[0]
		check_eq(reel.get_stress_band(), case[1], "stress %.1f is band %d" % [case[0], case[1]])
	return true


# FISH-012
func test_line_breaks_at_full_stress() -> bool:
	_cast_forced(&"snakehead_sergeant")
	_run_until(FishingController.STATE_STRIKE_WINDOW)
	_controller.attempt_strike()
	check_eq(_controller.get_state(), FishingController.STATE_REELING, "a successful strike starts the reel")
	check_eq(GameState.get_stat(&"successful_strikes"), 1, "successful strike counted")

	var reel := _controller.get_reel()
	reel.zone_center = 0.2
	reel.marker = 0.95
	reel.stress = 99.5
	_controller.set_reel_held(true)
	_controller.advance(STEP)
	check_eq(_controller.get_state(), FishingController.STATE_ESCAPED, "line break ends the reel")
	check_eq(_count("failed:line_break"), 1, "line break reported once")
	check_eq(GameState.get_stat(&"lines_broken"), 1, "line break counted")
	check_eq(GameState.get_stat(&"fish_landed"), 0, "no fish landed")
	check_eq(GameState.get_bucket_total_count(), 0, "bucket untouched")

	_run_until(FishingController.STATE_IDLE)
	check_eq(_controller.get_state(), FishingController.STATE_IDLE, "player returns to fishing")
	return true


# FISH-013
func test_fish_lands_exactly_once() -> bool:
	_cast_forced(&"gourami_shady")
	_run_until(FishingController.STATE_STRIKE_WINDOW)
	_controller.attempt_strike()
	var reel := _controller.get_reel()
	reel.marker = reel.zone_center
	reel.marker_velocity = 0.0
	reel.landing = 99.9
	_controller.set_reel_held(true)
	_controller.advance(STEP)
	check_eq(_controller.get_state(), FishingController.STATE_LANDED, "landing reaches 100")
	check_eq(_count("fish_landed:gourami_shady"), 1, "fish_landed emitted once")
	check_eq(GameState.get_stat(&"fish_landed"), 1, "landed stat")
	check_eq(GameState.get_fish_book_entry(&"gourami_shady")["encounters"], 1, "encounter recorded")
	check(not GameState.is_fish_discovered(&"gourami_shady"), "landing alone does not discover the fish")

	_run_until(FishingController.STATE_IDLE, 10.0)
	_controller.advance(1.0)
	check_eq(_count("fish_landed:gourami_shady"), 1, "still emitted only once")
	check_eq(GameState.get_stat(&"fish_landed"), 1, "still counted only once")
	if SceneRouter.has_scene(SceneRouter.SCENE_WHEEL) or _has_any_duel():
		check_eq(_count("resolved:duel"), 1, "the fish is routed to its duel")
	else:
		check_eq(_count("resolved:bucket_no_duel"), 1, "without duel scenes the fish goes to the bucket")
		check_eq(GameState.get_bucket_quantity(&"gourami_shady"), 1, "exactly one fish in the bucket")
	return true


func _has_any_duel() -> bool:
	for duel_id: StringName in ContentIds.DUEL_IDS:
		if SceneRouter.has_scene(duel_id):
			return true
	return false


# --- Whole flow -------------------------------------------------------------

func test_cancel_returns_to_idle_without_penalty() -> bool:
	_cast_forced(&"carp_golden")
	_run_until(FishingController.STATE_WAITING)
	_controller.cancel_to_idle()
	check_eq(_controller.get_state(), FishingController.STATE_IDLE, "cancelled to idle")
	check(_controller.get_encounter().is_empty(), "encounter dropped")
	check_eq(GameState.get_stat(&"failed_strikes"), 0, "no failure recorded")
	_controller.attempt_strike()
	_controller.set_reel_held(true)
	_controller.advance(1.0)
	check_eq(_controller.get_state(), FishingController.STATE_IDLE, "idle ignores strike and reel input")
	return true


func test_play_time_accumulates_at_the_lake() -> bool:
	for _index: int in 50:
		_controller.advance(STEP)
	check_near(float(GameState.get_stat(&"play_time_sec")), 1.0, 0.001, "idle time at the lake counts")
	_cast_forced(&"catfish_bruiser")
	for _index: int in 50:
		_controller.advance(STEP)
	check_near(float(GameState.get_stat(&"play_time_sec")), 2.0, 0.001, "so does time spent fishing")
	# A long hitch is still one capped step.
	_controller.advance(60.0)
	check_near(float(GameState.get_stat(&"play_time_sec")), 2.1, 0.001, "a slow frame adds at most one step")
	return true


func test_full_loop_with_a_simple_player() -> bool:
	# A player who holds while the marker is below the zone centre lands a
	# Bruiser Catfish, which is the intended early-game experience.
	_cast_forced(&"catfish_bruiser")
	_run_until(FishingController.STATE_STRIKE_WINDOW)
	_controller.attempt_strike()
	var elapsed := 0.0
	while _controller.get_state() == FishingController.STATE_REELING and elapsed < 40.0:
		var reel := _controller.get_reel()
		_controller.set_reel_held(reel.marker < reel.zone_center)
		_controller.advance(STEP)
		elapsed += STEP
	check_eq(_controller.get_state(), FishingController.STATE_LANDED, "the catfish is landed")
	check(elapsed > 5.5 and elapsed < 20.0, "landing took %.1f s (at least 100/18 s of reeling)" % elapsed)
	check_eq(_events.find("state:casting") < _events.find("state:waiting"), true, "casting before waiting")
	check_eq(_events.find("state:strike_window") < _events.find("state:reeling"), true, "strike before reeling")
	check_eq(_events.find("state:reeling") < _events.find("state:landed"), true, "reeling before landing")
	return true
