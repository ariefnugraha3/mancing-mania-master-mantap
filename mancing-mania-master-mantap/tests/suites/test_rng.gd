extends "res://tests/test_suite.gd"
## RNGService determinism and distribution (GDD 129, 136, 169.8).

const SAMPLE_COUNT := 100000


func get_suite_name() -> String:
	return "rng"


func after_all() -> void:
	GameState.clear_game()


func test_rolls_depend_only_on_channel_and_seed() -> bool:
	var first := RNGService.roll_float(&"fish", 918221)
	check_eq(RNGService.roll_float(&"fish", 918221), first, "same channel and seed repeat exactly")
	check(RNGService.roll_float(&"wheel", 918221) != first, "another channel gives another roll")
	check(RNGService.roll_float(&"fish", 918222) != first, "another seed gives another roll")
	return true


func test_roll_range_and_index_bounds() -> bool:
	var in_range := true
	var index_ok := true
	for seed: int in 5000:
		var roll := RNGService.roll_float(&"range", seed)
		in_range = in_range and roll >= 0.0 and roll < 1.0
		var index := RNGService.choose_index(&"index", seed, 8)
		index_ok = index_ok and index >= 0 and index < 8
	check(in_range, "rolls stay inside [0, 1)")
	check(index_ok, "indices stay inside [0, count)")
	check_eq(RNGService.choose_index(&"index", 1, 0), -1, "empty choice returns -1")
	check_eq(RNGService.choose_index(&"index", 1, 1), 0, "single choice returns 0")
	return true


func test_encounter_seed_sequence_is_reproducible() -> bool:
	RNGService.initialize_session(123456789)
	var first_run: Array[int] = []
	for _index: int in 5:
		first_run.append(RNGService.next_encounter_seed())

	RNGService.initialize_session(123456789)
	var second_run: Array[int] = []
	for _index: int in 5:
		second_run.append(RNGService.next_encounter_seed())
	check_eq(second_run, first_run, "same save seed replays the same encounter seeds")

	# Resuming from saved counters continues the sequence instead of restarting it.
	RNGService.initialize_session(123456789)
	RNGService.restore_counters(3, 0)
	check_eq(RNGService.next_encounter_seed(), first_run[3], "sequence resumes from the saved counter")

	RNGService.initialize_session(987654321)
	check(RNGService.next_encounter_seed() != first_run[0], "another save seed gives another sequence")
	check(RNGService.next_duel_seed() != RNGService.next_encounter_seed(), "duel and encounter seeds differ")
	return true


func test_distribution_over_100k_encounters() -> bool:
	RNGService.initialize_session(20261111)
	var trash_probability := GameData.get_fishing_balance().trash_probability
	var trash_hits := 0
	var buckets: Array[int] = []
	buckets.resize(10)
	buckets.fill(0)
	var total := 0.0

	for _index: int in SAMPLE_COUNT:
		var encounter_seed := RNGService.next_encounter_seed()
		var roll := RNGService.roll_float(&"trash", encounter_seed)
		if roll < trash_probability:
			trash_hits += 1
		buckets[mini(int(roll * 10.0), 9)] += 1
		total += roll

	check_near(float(trash_hits) / SAMPLE_COUNT, trash_probability, 0.006, "trash rate over 100k encounters")
	check_near(total / SAMPLE_COUNT, 0.5, 0.005, "mean roll")
	for index: int in 10:
		check_near(float(buckets[index]) / SAMPLE_COUNT, 0.1, 0.005, "decile %d share" % index)
	return true


func test_channels_are_independent() -> bool:
	# Two channels read from the same encounter seed must not move together.
	var both_low := 0
	var samples := 20000
	for seed: int in samples:
		if RNGService.roll_float(&"trash", seed) < 0.5 and RNGService.roll_float(&"fish", seed) < 0.5:
			both_low += 1
	check_near(float(both_low) / samples, 0.25, 0.015, "joint rate of two independent halves")
	return true


func test_make_rng_and_snapshot() -> bool:
	var a := RNGService.make_rng(42)
	var b := RNGService.make_rng(42)
	check_eq(a.randi(), b.randi(), "generators with the same seed agree")

	RNGService.initialize_session(555)
	RNGService.next_encounter_seed()
	var snapshot := RNGService.get_debug_snapshot()
	check_eq(snapshot["save_seed"], 555, "snapshot save seed")
	check_eq(snapshot["encounter_counter"], 1, "snapshot encounter counter")
	check(snapshot.has("session_seed") and snapshot.has("last_encounter_seed"), "snapshot lists the debug seeds")
	check_eq(RNGService.get_persist_state(), {"save_seed": 555, "encounter_counter": 1, "duel_counter": 0}, "persist state")
	return true
