extends "res://tests/test_suite.gd"
## Revision 6.7 (GDD Section 198): the four new fishing spots, their fish,
## their water, their Wheels, their duels, travel and the Market's gear.

const STORAGE_DIR := "user://test_tmp/spots"
const TICK := DuelControllerBase.TICK_SEC
const NEW_SPOTS: Array[StringName] = [&"kenanga", &"melati", &"anggrek", &"mawar"]
const SIGNATURE: Dictionary[StringName, StringName] = {
	&"kenanga": &"silat", &"melati": &"tambang", &"anggrek": &"gasing", &"mawar": &"pinang",
}


func get_suite_name() -> String:
	return "spots"


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
	GameState.set_tutorial_seen(&"wheel_seen")


func _set_cash(amount: int) -> void:
	var change := amount - GameState.get_cash()
	if change > 0:
		GameState.add_cash(change)
	elif change < 0:
		GameState.spend_cash(-change)


# --- Data -------------------------------------------------------------------------

func test_every_spot_has_its_own_five_fish() -> bool:
	check_empty(DataValidator.validate_location_set(GameData.get_all_locations()), "spot data validation")
	var seen: Array[StringName] = []
	for location_id: StringName in ContentIds.LOCATION_IDS:
		var location := GameData.get_location(location_id)
		if not check(location != null, "%s resource exists" % location_id):
			continue
		var fish_ids := ContentIds.fish_of_location(location_id)
		check_eq(GameData.get_location_fish(location_id).size(), fish_ids.size(), "%s fish resources" % location_id)
		var total := 0.0
		for fish_id: StringName in fish_ids:
			check(not seen.has(fish_id), "%s lives in one spot only" % fish_id)
			seen.append(fish_id)
			var fish := GameData.get_fish(fish_id)
			check_eq(fish.get_location(), location_id, "%s knows its spot" % fish_id)
			total += fish.conditional_chance
		check_near(total, 1.0, 0.0001, "%s chances add up to 1" % location_id)
		check_eq(location.wheel_segments.size(), 8, "%s wheel has eight segments" % location_id)
		if location_id != ContentIds.START_LOCATION:
			check_eq(fish_ids.size(), 5, "%s has five fish" % location_id)
			var legend := GameData.get_fish(fish_ids[4])
			check(legend.is_legend() and legend.tier == 5, "%s ends with its legend" % location_id)
			check_eq(legend.sale_multiplier, 1.25, "%s legend sells for 1.25x" % location_id)
			check_eq(location.wheel_segments.count(SIGNATURE[location_id]), 4, "%s signature duel has half the wheel" % location_id)
			check(location.access_price > 0, "%s gear has a price" % location_id)
			check(StoryDirector.get_event(location.unlock_event) != null, "%s opening event exists" % location_id)
	check_eq(seen.size(), ContentIds.FISH_IDS.size(), "every fish belongs to a spot")
	return true


func test_new_fish_stay_inside_the_balance_limits() -> bool:
	for location_id: StringName in NEW_SPOTS:
		for fish: FishData in GameData.get_location_fish(location_id):
			check(fish.arm_strength <= 84.0, "%s arm strength in range" % fish.id)
			check(fish.boxing_hp <= 190.0, "%s boxing HP in range" % fish.id)
			check(fish.rhythm_skill <= 90.0, "%s rhythm in range" % fish.id)
			check(fish.tell_truth_probability >= 0.30, "%s tells the truth sometimes" % fish.id)
			check(fish.duel_skill > 0.0 and fish.duel_skill <= 90.0, "%s duel skill in range" % fish.id)
			check(fish.model_scene != null and fish.portrait_texture != null, "%s has a model and a portrait" % fish.id)
			check(TextDb.has_key(StringName("fish.%s.description" % fish.id)), "%s has a Fish Book description" % fish.id)
	return true


# --- Cempaka Lake is unchanged -------------------------------------------------------

func test_cempaka_lake_rolls_exactly_as_before() -> bool:
	for seed: int in range(1, 400):
		var before := EncounterRoller.roll(seed * 7919, 2)
		var now := EncounterRoller.roll(seed * 7919, 2, &"", -1.0, ContentIds.START_LOCATION, seed)
		check_eq(now["item_id"], before["item_id"], "seed %d catch" % seed)
		check_eq(now["weight_kg"], before["weight_kg"], "seed %d weight" % seed)
		check_eq(now["wait_sec"], before["wait_sec"], "seed %d wait" % seed)
		if not ContentIds.fish_of_location(ContentIds.START_LOCATION).has(now["item_id"]) and now["kind"] == EncounterRoller.KIND_FISH:
			check(false, "seed %d caught a spot fish at the lake" % seed)
	return true


func test_spot_fish_odds() -> bool:
	for location_id: StringName in NEW_SPOTS:
		var counts := {}
		var fish_rolls := 0
		for seed: int in 20000:
			var encounter := EncounterRoller.roll(seed * 2654435761 % 2147483647, 0, &"", -1.0, location_id, 0)
			if encounter["kind"] != EncounterRoller.KIND_FISH:
				continue
			fish_rolls += 1
			counts[encounter["item_id"]] = int(counts.get(encounter["item_id"], 0)) + 1
		for fish: FishData in GameData.get_location_fish(location_id):
			check_near(float(counts.get(fish.id, 0)) / float(fish_rolls), fish.conditional_chance, 0.015, "%s about %d%%" % [fish.id, roundi(fish.conditional_chance * 100.0)])
		check_eq(counts.size(), 5, "%s only gives its own fish" % location_id)
	return true


# --- Water ---------------------------------------------------------------------------

func test_each_spot_changes_the_water() -> bool:
	var river := GameData.get_location(&"kenanga")
	var deep := GameData.get_location(&"melati")
	var estuary := GameData.get_location(&"anggrek")
	var sea := GameData.get_location(&"mawar")
	# River: shorter waits, a tighter strike window, and a sinking reel marker.
	var lake_wait := EncounterRoller.wait_time(0.5, 0)
	check(EncounterRoller.wait_time(0.5, 0, river) < lake_wait, "the river bites sooner")
	check(EncounterRoller.wait_time(0.5, 0, deep) > lake_wait, "the reservoir bites later")
	var fish := GameData.get_fish(&"baung_satpam")
	var calm := ReelSimulation.new()
	calm.setup(fish, 0, 11)
	var current := ReelSimulation.new()
	current.setup(fish, 0, 11)
	current.setup_water(river)
	for _step: int in 60:
		calm.step(1.0 / 60.0, false)
		current.step(1.0 / 60.0, false)
	check(current.marker < calm.marker or current.marker <= 0.0, "the current pulls the marker down")
	# Reservoir: heavier fish and more big ones.
	var light := 0.0
	var heavy := 0.0
	var big := 0
	for seed: int in 2000:
		var at_lake := EncounterRoller.roll(seed, 0, &"patin_stempel", -1.0, ContentIds.START_LOCATION, 0)
		var at_reservoir := EncounterRoller.roll(seed, 0, &"patin_stempel", -1.0, &"melati", 0)
		light += float(at_lake["weight_kg"])
		heavy += float(at_reservoir["weight_kg"])
		big += 1 if at_reservoir["is_big_one"] else 0
	check(heavy > light * 1.1, "reservoir fish weigh more")
	check(big > 0, "big ones turn up")
	# Estuary: the tide turns every four casts, and low water brings trash.
	check(estuary.is_high_tide(0) and estuary.is_high_tide(3), "high tide for the first four casts")
	check(not estuary.is_high_tide(4) and not estuary.is_high_tide(7), "then low tide")
	check(estuary.is_high_tide(8), "then high again")
	check(estuary.trash_probability(0.2, 4) > estuary.trash_probability(0.2, 0), "low water brings more trash")
	# Pier: waves add line stress in pulses.
	var peak := 0.0
	for step: int in 400:
		peak = maxf(peak, sea.wave_stress(float(step) * 0.01))
	check_near(peak, sea.wave_stress_per_sec, 0.5, "a wave adds its full stress at the crest")
	check_eq(river.wave_stress(1.0), 0.0, "no waves on the river")
	return true


# --- Opening, gear and travel ------------------------------------------------------------

func test_spots_open_with_the_story_and_need_their_gear() -> bool:
	check_eq(GameState.get_current_location(), ContentIds.START_LOCATION, "a new game starts at the lake")
	check(not GameState.can_fish_at(&"kenanga"), "the river is closed at first")
	check(not GameState.can_buy_location_gear(&"kenanga"), "and its gear is not for sale")
	check(not GameState.set_current_location(&"kenanga"), "Darto cannot go there")
	StoryDirector.complete_event(&"story_unlock_kenanga", true)
	check(GameState.is_location_unlocked(&"kenanga"), "the opening event opens the river, even skipped")
	check(not GameState.can_fish_at(&"kenanga"), "but without the gear Darto still cannot fish there")
	_set_cash(10000)
	check(not GameState.can_buy_location_gear(&"kenanga"), "the gear costs Rp 25,000")
	_set_cash(30000)
	check(GameState.buy_location_gear(&"kenanga"), "bought")
	check_eq(GameState.get_cash(), 5000, "the price is paid")
	check(not GameState.buy_location_gear(&"kenanga"), "gear is bought once")
	check(GameState.set_current_location(&"kenanga"), "now Darto can go")
	check(GameState.mark_location_visited(&"kenanga"), "first arrival")
	check(not GameState.mark_location_visited(&"kenanga"), "only once")
	check_eq(GameState.get_visited_location_count(), 2, "two spots visited")
	check(not GameState.can_fish_at(&"mawar"), "the pier is still closed")
	return true


func test_a_spot_without_its_gear_is_normalized_away() -> bool:
	var data := SaveSchema.make_default(77)
	data["locations"] = {"current": "mawar", "unlocked": ["cempaka", "mawar", "nowhere"], "gear": [], "visited": ["cempaka"]}
	var clean := SaveSchema.normalize(data)
	check_eq(clean["locations"]["current"], "cempaka", "Darto goes back to the lake")
	check_eq(clean["locations"]["unlocked"], ["cempaka", "mawar"], "unknown spots are dropped")
	data["locations"] = {"current": "mawar", "unlocked": ["mawar"], "gear": ["mawar"], "visited": []}
	clean = SaveSchema.normalize(data)
	check_eq(clean["locations"]["current"], "mawar", "an open spot with its gear is kept")
	check(clean["locations"]["unlocked"].has("cempaka"), "the lake is always open")
	return true


func test_spot_openings_wait_for_their_debt_milestone() -> bool:
	var milestones: Dictionary[StringName, int] = {&"kenanga": 300000, &"melati": 600000, &"anggrek": 1000000, &"mawar": 1400000}
	for location_id: StringName in milestones:
		var event := StoryDirector.get_event(GameData.get_location(location_id).unlock_event)
		check_eq(event.trigger_type, StoryDirector.TRIGGER_DEBT_PAID, "%s opens on debt paid" % location_id)
		check_eq(int(event.trigger_value), milestones[location_id], "%s opens at its milestone" % location_id)
		check_eq(event.priority, 300, "%s ranks below the debt events" % location_id)
		check(not event.requires_seen.is_empty(), "%s waits for its debt event" % location_id)
	return true


func test_travel_overlay_lists_every_spot() -> bool:
	var overlay := TravelOverlay.new()
	tree.root.add_child(overlay)
	await wait_frames(2)
	overlay.open()
	await wait_frames(2)
	for location_id: StringName in NEW_SPOTS:
		check(overlay.get_go_button(location_id) == null, "%s has no GO before it opens" % location_id)
	check_contains(PackedStringArray([TravelOverlay.status_text(&"kenanga")]), Money.format_rp(300000), "a closed spot says what opens it")
	GameState.debug_open_location(&"kenanga")
	GameState.set_current_location(ContentIds.START_LOCATION)
	overlay.open()
	await wait_frames(2)
	check(overlay.get_go_button(&"kenanga") != null, "an open spot with gear has GO")
	check_eq(TravelOverlay.fish_count_text(&"kenanga"), TextDb.tf(&"travel.fish_count", {"count": 0, "total": 5}), "fish count starts at zero")
	GameState.record_encounter(&"baung_satpam")
	GameState.record_fish_win(&"baung_satpam", 2.0, &"silat")
	check_eq(TravelOverlay.fish_count_text(&"kenanga"), TextDb.tf(&"travel.fish_count", {"count": 1, "total": 5}), "a beaten fish counts")
	overlay.hide_overlay()
	overlay.queue_free()
	await wait_frames(1)
	return true


func test_market_sells_travel_gear() -> bool:
	var controller := MarketController.new()
	tree.root.add_child(controller)
	_set_cash(500000)
	check(not controller.purchase_gear(&"melati"), "closed spots sell no gear")
	StoryDirector.complete_event(&"story_unlock_melati", true)
	await wait_seconds(0.3)
	check(controller.purchase_gear(&"melati"), "open spot: the gear is sold")
	check(GameState.has_location_gear(&"melati"), "and owned")
	check_eq(GameState.get_cash(), 500000 - GameData.get_location(&"melati").access_price, "for its price")
	await wait_seconds(0.3)
	check(not controller.purchase_gear(&"melati"), "never twice")
	controller.queue_free()
	await wait_frames(1)
	return true


# --- Wheels ------------------------------------------------------------------------------

func test_each_spot_spins_its_own_wheel() -> bool:
	for location_id: StringName in NEW_SPOTS:
		var fish_id: StringName = ContentIds.fish_of_location(location_id)[0]
		var counts := {}
		for seed: int in 40000:
			var duel := WheelController.pick_duel(fish_id, seed * 2654435761 % 2147483647)
			counts[duel] = int(counts.get(duel, 0)) + 1
		var location := GameData.get_location(location_id)
		check_eq(counts.size(), 3, "%s wheel has three duels" % location_id)
		for duel_id: StringName in location.get_duel_ids():
			var share := float(location.wheel_segments.count(duel_id)) / 8.0
			check_near(float(counts.get(duel_id, 0)) / 40000.0, share, 0.015, "%s %s about %d%%" % [location_id, duel_id, roundi(share * 100.0)])
		check_eq(WheelController.segments_for(fish_id), location.wheel_segments, "%s fish use their spot's wheel" % location_id)
	return true


# --- Duels -------------------------------------------------------------------------------

func _make(duel_id: StringName) -> DuelControllerBase:
	var controller: DuelControllerBase
	match duel_id:
		&"silat":
			controller = SilatController.new()
		&"tambang":
			controller = TambangController.new()
		&"gasing":
			controller = GasingController.new()
		_:
			controller = PinangController.new()
	controller.auto_advance = false
	return controller


## Plays a whole duel with the QA bot's strategy (`skilled`) or with no input
## at all, ticking at 120 Hz. Returns the result.
func _play(duel_id: StringName, fish_id: StringName, seed: int, skilled: bool) -> Dictionary:
	var controller := _make(duel_id)
	controller.start_duel(fish_id, seed)
	var bot_clock := 0.0
	var side := PinangController.LEFT
	for _tick: int in roundi(120.0 / TICK):
		if controller.get_state() == DuelControllerBase.STATE_FINISHED:
			break
		bot_clock += TICK
		if skilled:
			var snapshot := controller.get_snapshot()
			match duel_id:
				&"silat":
					var silat := controller as SilatController
					if snapshot["state"] == SilatController.STATE_INPUT and bot_clock >= 0.25:
						bot_clock = 0.0
						silat.press(silat.debug_get_sequence()[int(snapshot["input_index"])])
				&"tambang":
					if snapshot["state"] == TambangController.STATE_PULL and not snapshot["zone_spent"] and not snapshot["stunned"] \
							and absf(float(snapshot["marker"]) - TambangController.ZONE_CENTRE) <= float(snapshot["zone_half"]) * 0.3:
						(controller as TambangController).pull()
				&"gasing":
					var gasing := controller as GasingController
					match snapshot["state"]:
						GasingController.STATE_AIM:
							if absf(float(snapshot["aim"])) < 0.08:
								gasing.tap()
						GasingController.STATE_POWER:
							if float(snapshot["power"]) > 0.93:
								gasing.tap()
						GasingController.STATE_SPIN:
							if snapshot["ring_active"] and absf(float(snapshot["impact_in"])) <= 0.03:
								gasing.tap()
				&"pinang":
					var pinang := controller as PinangController
					if snapshot["state"] == PinangController.STATE_CLIMB and bot_clock >= 0.2:
						bot_clock = 0.0
						var expected := pinang.get_expected_side()
						side = expected if expected != &"" else side
						pinang.press(side)
		controller.advance(TICK)
	var result := controller.get_result()
	controller.free()
	return result


func test_the_bot_beats_every_fish_of_each_spot() -> bool:
	for location_id: StringName in NEW_SPOTS:
		var duel_id: StringName = SIGNATURE[location_id]
		for fish_id: StringName in ContentIds.fish_of_location(location_id):
			for seed: int in [5, 77, 4242]:
				var result := _play(duel_id, fish_id, seed, true)
				check_eq(result.get("duel_id"), duel_id, "%s result names its duel" % duel_id)
				check(bool(result.get("player_won", false)), "%s: the bot beats %s (seed %d)" % [duel_id, fish_id, seed])
	return true


func test_doing_nothing_never_wins() -> bool:
	for location_id: StringName in NEW_SPOTS:
		var duel_id: StringName = SIGNATURE[location_id]
		var legend: StringName = ContentIds.fish_of_location(location_id)[4]
		var result := _play(duel_id, legend, 9, false)
		check(not result.is_empty(), "%s ends without input" % duel_id)
		check(not bool(result.get("player_won", true)), "%s is lost without input" % duel_id)
		check(float(result.get("duration_sec", 0.0)) <= 61.5, "%s ends in time" % duel_id)
	return true


func test_duels_are_deterministic() -> bool:
	for duel_id: StringName in SIGNATURE.values():
		var fish_id: StringName = ContentIds.fish_of_location(SIGNATURE.find_key(duel_id))[2]
		var first := _play(duel_id, fish_id, 1234, true)
		var again := _play(duel_id, fish_id, 1234, true)
		check_eq(JSON.stringify(again), JSON.stringify(first), "%s: same seed and inputs, same result" % duel_id)
	return true


func test_forced_results_and_commit() -> bool:
	for duel_id: StringName in SIGNATURE.values():
		var location_id: StringName = SIGNATURE.find_key(duel_id)
		var legend: StringName = ContentIds.fish_of_location(location_id)[4]
		DebugService.set_forced_result(&"loss")
		check(not bool(_play(duel_id, legend, 3, true).get("player_won", true)), "%s obeys a forced loss" % duel_id)
		DebugService.set_forced_result(&"win")
		var result := _play(duel_id, legend, 3, false)
		check(bool(result.get("player_won", false)), "%s obeys a forced win" % duel_id)
		DebugService.clear_forces()
		var legends_before := int(GameState.get_stat(&"legends_defeated"))
		var cash := GameState.get_cash()
		check(DuelOutcome.commit(result), "%s result commits" % duel_id)
		check_eq(int(GameState.get_stat(StringName("%s_wins" % duel_id))), 1, "%s win recorded" % duel_id)
		check_eq(int(GameState.get_stat(&"legends_defeated")), legends_before + 1, "beating %s counts as a legend" % legend)
		check_eq(GameState.get_bucket_quantity(legend), 1, "%s goes into the bucket" % legend)
		check_eq(GameState.get_cash(), cash, "winning costs nothing")
	return true


func test_duel_rules() -> bool:
	# Silat: sequences grow by one and never repeat a move back to back.
	var silat := _make(&"silat") as SilatController
	silat.start_duel(&"baung_satpam", 8)
	check_eq(silat.length_for_round(0), 3, "a weak fish starts with three moves")
	check_eq(silat.length_for_round(2), 5, "and adds one each round")
	check_eq(silat.length_for_round(20), SilatController.MAX_LENGTH, "up to eight")
	silat.free()
	silat = _make(&"silat") as SilatController
	silat.start_duel(&"belida_pendekar", 8)
	check_eq(silat.length_for_round(0), 4, "the legend starts with four")
	check(silat.step_sec() < 0.5, "and shows its moves faster")
	silat.free()
	# Tug of War: a pull outside the zone slips; one pull per pass.
	var tambang := _make(&"tambang") as TambangController
	tambang.start_duel(&"patin_stempel", 2)
	while tambang.get_state() != TambangController.STATE_PULL:
		tambang.advance(TICK)
	while tambang.is_marker_in_zone():
		tambang.advance(TICK)
	check_eq(tambang.pull(), &"slip", "pulling outside the zone slips")
	check_eq(tambang.pull(), &"", "and Darto needs a moment")
	while not tambang.is_marker_in_zone() or tambang.get_snapshot()["stunned"]:
		tambang.advance(TICK)
	check(tambang.pull() in [TambangController.QUALITY_GOOD, TambangController.QUALITY_PERFECT], "a pull in the zone counts")
	check_eq(tambang.pull(), &"", "a second pull in the same pass does nothing")
	tambang.free()
	# Spinning Tops: a straight, strong throw spins longest.
	check(GasingController.throw_spin(0.0, 1.0) > GasingController.throw_spin(0.8, 1.0), "a crooked throw spins less")
	check(GasingController.throw_spin(0.0, 1.0) > GasingController.throw_spin(0.0, 0.3), "a weak throw spins less")
	check_eq(GasingController.throw_spin(0.0, 1.0), GasingController.SPIN_MIN + GasingController.SPIN_RANGE, "a perfect throw is full spin")
	# Greased Pole: the same side twice slips; rushing smears the grease.
	var pinang := _make(&"pinang") as PinangController
	pinang.start_duel(&"tongkol_ojol", 4)
	while pinang.get_state() != PinangController.STATE_CLIMB:
		pinang.advance(TICK)
	pinang.press(PinangController.LEFT)
	var after_left := float(pinang.get_snapshot()["height"])
	check_near(after_left, PinangController.STEP, 0.0001, "one good grab climbs one step")
	for _tick: int in 30:
		pinang.advance(TICK)
	pinang.press(PinangController.LEFT)
	check(float(pinang.get_snapshot()["height"]) < after_left, "the same side twice slides down")
	check(pinang.get_snapshot()["stunned"], "and Darto needs a moment")
	for _tick: int in 120:
		pinang.advance(TICK)
	# Lambdas capture locals by value, so the slips are collected in an array.
	var slips: Array[StringName] = []
	pinang.player_slipped.connect(func(reason: StringName) -> void: slips.append(reason))
	var side := PinangController.LEFT
	for _grab: int in 6:
		pinang.press(side)
		side = PinangController.RIGHT if side == PinangController.LEFT else PinangController.LEFT
		pinang.advance(TICK * 6.0)
	check(slips.has(PinangController.SLIP_GREASE), "tapping too fast greases the pole")
	pinang.free()
	return true
