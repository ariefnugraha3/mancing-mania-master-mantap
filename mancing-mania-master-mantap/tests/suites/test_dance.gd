extends "res://tests/test_suite.gd"
## Joget Koplo rules and the procedural music they run on (GDD 57-63, 175.10;
## QA matrix DANCE-001..011, AUD-011).

const STORAGE_DIR := "user://test_tmp/dance"
const SEED := 777

var _dance: DanceController
var _clock: RhythmClock
var _judged: Array[Dictionary] = []
var _events: Array[String] = []


func get_suite_name() -> String:
	return "dance"


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
	_judged.clear()
	_events.clear()
	_clock = RhythmClock.new()
	_clock.source = RhythmClock.SOURCE_MANUAL
	_dance = DanceController.new()
	_dance.clock = _clock
	_dance.note_judged.connect(func(index: int, judgment: StringName, lane: int, delta_ms: float) -> void:
		_judged.append({"index": index, "judgment": judgment, "lane": lane, "delta": delta_ms}))
	_dance.encore_started.connect(func() -> void: _events.append("encore"))
	_dance.duel_finished.connect(func(_result: Dictionary) -> void: _events.append("finished"))


func after_each() -> void:
	_dance.free()
	_clock.free()


## Runs the song to its end with the clock in `step` second frames, pressing
## each note `offset_sec` late (null = never pressing).
func _play(offset_sec: Variant, step: float = 1.0 / 60.0) -> Dictionary:
	var notes := _dance.get_notes()
	var next := 0
	for _frame: int in roundi(60.0 / step):
		if _dance.get_state() == DanceController.STATE_FINISHED:
			break
		_clock.advance(step)
		var now := _clock.get_time()
		while offset_sec != null and next < notes.size() and float(notes[next]["time"]) + float(offset_sec) <= now:
			_dance.submit_lane(int(notes[next]["lane"]), float(notes[next]["time"]) + float(offset_sec))
			next += 1
		_dance.advance(step)
		notes = _dance.get_notes()
	return _dance.get_result()


# --- Tests ------------------------------------------------------------------

# DANCE-001, DANCE-002
func test_tempo_and_length_stay_in_range() -> bool:
	var config := GameData.get_dance_config()
	var tempos := {}
	for seed: int in 200:
		var chart := ChartGenerator.generate(&"carp_golden", seed * 7919)
		var bpm: float = chart["bpm"]
		var duration: float = chart["duration_sec"]
		check(bpm >= config.bpm_min and bpm <= config.bpm_max, "seed %d: %d BPM is in 132-156" % [seed, bpm])
		check(duration >= config.duration_min_sec - 0.001 and duration <= config.duration_max_sec + 0.001, "seed %d: %.2f s is in 36-44" % [seed, duration])
		tempos[bpm] = true
		var notes: Array = chart["notes"]
		check(notes.size() >= 40, "seed %d has a real chart (%d notes)" % [seed, notes.size()])
		check(float(notes[0]["time"]) >= float(chart["beat_sec"]) * 4.0 - 0.001, "seed %d: no note during the count-in" % seed)
	check(tempos.size() >= 15, "tempos vary across seeds (%d different)" % tempos.size())
	return true


# DANCE-003, AUD-011
func test_same_seed_same_track_and_chart() -> bool:
	var first := ChartGenerator.generate(&"tilapia_gym_rat", SEED)
	var second := ChartGenerator.generate(&"tilapia_gym_rat", SEED)
	check_eq(second["notes"], first["notes"], "the same seed gives the same chart")
	check_eq(second["schedule"]["events"], first["schedule"]["events"], "and the same music schedule")
	check(ChartGenerator.generate(&"tilapia_gym_rat", SEED + 1)["notes"] != first["notes"], "another duel gives another chart")
	check(ChartGenerator.generate(&"carp_golden", SEED)["notes"] != first["notes"], "another fish gives another chart")

	var notes: Array = first["notes"]
	var beat: float = first["beat_sec"]
	var gaps_ok := true
	var on_grid := true
	var lanes := {}
	for index: int in notes.size():
		lanes[notes[index]["lane"]] = true
		var steps := float(notes[index]["time"]) / (beat / 4.0)
		on_grid = on_grid and absf(steps - roundf(steps)) < 0.001
		if index > 0:
			gaps_ok = gaps_ok and float(notes[index]["time"]) - float(notes[index - 1]["time"]) >= beat * 0.5 - 0.001
	check(on_grid, "every note sits on the music's sixteenth-note grid")
	check(gaps_ok, "no two notes are closer than an eighth note")
	check_eq(lanes.size(), 4, "all four lanes are used")
	# Every note is something in the track: a drum or melody hit at that time.
	var hits := {}
	for event: Dictionary in first["schedule"]["events"]:
		if int(event["lane_hint"]) >= 0:
			hits[snappedf(event["t"], 0.0001)] = true
	var heard := 0
	for note: Dictionary in notes:
		if hits.has(snappedf(note["time"], 0.0001)):
			heard += 1
	check_eq(heard, notes.size(), "every note lands on a hit you can hear")

	# The rendered audio is the same too.
	var short := MusicSequencer.build_koplo(SEED, 140.0, 3)
	var audio_a := MusicRenderer.new()
	audio_a.start(short)
	audio_a.render_all()
	var audio_b := MusicRenderer.new()
	audio_b.start(short)
	audio_b.render_all()
	check_eq(audio_a.get_samples(), audio_b.get_samples(), "the same schedule renders the same samples")
	check(not SynthDsp.has_invalid_samples(audio_a.get_samples()), "the track has no NaN or Inf")
	check(SynthDsp.peak(audio_a.get_samples()) <= 1.0, "and never clips")
	return true


# DANCE-004..006
func test_judgment_windows() -> bool:
	check_eq(DanceController.judge(0.0), DanceController.PERFECT, "on time: PERFECT")
	check_eq(DanceController.judge(0.055), DanceController.PERFECT, "55 ms: PERFECT")
	check_eq(DanceController.judge(-0.055), DanceController.PERFECT, "55 ms early: PERFECT")
	check_eq(DanceController.judge(0.056), DanceController.GREAT, "56 ms: GREAT")
	check_eq(DanceController.judge(-0.1), DanceController.GREAT, "100 ms early: GREAT")
	check_eq(DanceController.judge(0.101), DanceController.GOOD, "101 ms: GOOD")
	check_eq(DanceController.judge(0.175), DanceController.GOOD, "175 ms: GOOD")
	check_eq(DanceController.judge(0.176), DanceController.MISS, "176 ms: MISS")

	_dance.start_duel(&"catfish_bruiser", SEED)
	var notes := _dance.get_notes()
	var note: Dictionary = notes[0]
	_clock.set_time(float(note["time"]) + 0.08)
	_dance.submit_lane(int(note["lane"]), float(note["time"]) + 0.08)
	check_eq(_judged[0]["judgment"], DanceController.GREAT, "a press 80 ms late is GREAT")
	_dance.submit_lane(int(note["lane"]), float(note["time"]) + 0.08)
	check_eq(_judged.size(), 1, "a note is judged once")
	var wrong_lane := (int(notes[1]["lane"]) + 1) % 4
	_dance.submit_lane(wrong_lane, float(notes[1]["time"]))
	check_eq(_judged.size(), 1, "a press in another lane does not take the note")
	_clock.set_time(float(notes[1]["time"]) + 0.2)
	_dance.advance()
	check_eq(_judged[1]["judgment"], DanceController.MISS, "a note nobody hit becomes MISS after the GOOD window")
	return true


# DANCE-007
func test_score_and_combo_bonus() -> bool:
	check_eq(DanceController.points(DanceController.PERFECT, 1), 1000, "PERFECT 1000")
	check_eq(DanceController.points(DanceController.GREAT, 1), 700, "GREAT 700")
	check_eq(DanceController.points(DanceController.GOOD, 1), 350, "GOOD 350")
	check_eq(DanceController.points(DanceController.MISS, 1), 0, "MISS 0")
	check_eq(DanceController.points(DanceController.PERFECT, 9), 1000, "combo 9: no bonus yet")
	check_eq(DanceController.points(DanceController.PERFECT, 10), 1100, "combo 10: +10%")
	check_eq(DanceController.points(DanceController.GREAT, 29), 840, "combo 29: +20%")
	check_eq(DanceController.points(DanceController.PERFECT, 50), 1500, "combo 50: +50%")
	check_eq(DanceController.points(DanceController.PERFECT, 120), 1500, "the bonus stops at +50%")

	_dance.start_duel(&"catfish_bruiser", SEED)
	var result := _play(0.0)
	var count: int = result["metrics"]["notes"]
	var expected := 0
	for combo: int in range(1, count + 1):
		expected += DanceController.points(DanceController.PERFECT, combo)
	check_eq(result["metrics"]["player_score"], expected, "a perfect run scores exactly the formula")
	check_eq(result["metrics"]["player_max_combo"], count, "full combo")

	# A miss resets the combo.
	_dance.start_duel(&"catfish_bruiser", SEED)
	_clock.reset()
	var notes := _dance.get_notes()
	for index: int in 12:
		if index == 10:
			continue
		_clock.set_time(float(notes[index]["time"]))
		_dance.submit_lane(int(notes[index]["lane"]), float(notes[index]["time"]))
		_dance.advance()
	_clock.set_time(float(notes[12]["time"]) - 0.3)
	_dance.advance()
	check_eq(_dance.get_snapshot()["player_combo"], 1, "the combo restarts after the missed note")
	check_eq(_dance.get_snapshot()["player_max_combo"], 10, "max combo remembers the run")
	return true


# DANCE-008
func test_coffee_changes_only_the_visual_speed() -> bool:
	var times: Array[float] = []
	var expected: Array[float] = [1.25, 1.25 / 0.88, 1.25 / 0.76, 1.25 / 0.64]
	var charts: Array = []
	for level: int in 4:
		GameState.debug_set_upgrade_level(&"coffee", level)
		check_near(DanceController.approach_sec(), expected[level], 0.0001, "Coffee Lv%d note travel time" % level)
		times.append(DanceController.approach_sec())
		_dance.start_duel(&"gourami_shady", SEED)
		charts.append(_dance.get_notes().duplicate(true))
		check_eq(_dance.get_chart()["bpm"], ChartGenerator.generate(&"gourami_shady", SEED)["bpm"], "Coffee Lv%d does not change the tempo" % level)
	for level: int in range(1, 4):
		check_eq(charts[level], charts[0], "Coffee Lv%d does not move a single note" % level)
		check(times[level] > times[level - 1], "slower notes appear earlier at Lv%d" % level)
	return true


# DANCE-009
func test_judgment_does_not_depend_on_frame_rate() -> bool:
	var outcomes: Array = []
	for step: float in [1.0 / 30.0, 1.0 / 60.0, 1.0 / 144.0]:
		_dance.start_duel(&"snakehead_sergeant", SEED)
		_clock.reset()
		_judged.clear()
		var result := _play(0.03, step)
		var judgments: Array = []
		for entry: Dictionary in _judged:
			judgments.append(entry["judgment"])
		outcomes.append({"judgments": judgments, "score": result["metrics"]["player_score"], "fish": result["metrics"]["fish_score"]})
	check_eq(outcomes[1], outcomes[0], "30 FPS and 60 FPS judge the same presses the same")
	check_eq(outcomes[2], outcomes[0], "and so does 144 FPS")
	check(not (outcomes[0]["judgments"] as Array).has(DanceController.MISS), "30 ms late is never a miss, even at 30 FPS")
	return true


func test_calibration_offset_shifts_the_reference() -> bool:
	GameState.set_setting(&"rhythm_input_offset_ms", 80)
	_dance.start_duel(&"catfish_bruiser", SEED)
	var result := _play(0.08)
	check_eq(int(result["metrics"]["player_counts"][DanceController.PERFECT]), int(result["metrics"]["notes"]), "with an 80 ms offset, presses 80 ms late are all PERFECT")
	GameState.set_setting(&"rhythm_input_offset_ms", 0)
	return true


# DANCE-010
func test_fish_dances_note_by_note_from_the_seed() -> bool:
	var fish := GameData.get_fish(&"carp_golden")
	var plan_a := DanceController.plan_fish(fish, 99, 300)
	check_eq(DanceController.plan_fish(fish, 99, 300), plan_a, "the same seed gives the same note-by-note dance")
	check(DanceController.plan_fish(fish, 100, 300) != plan_a, "another seed gives another dance")

	var shown: Array[StringName] = []
	_dance.fish_note_judged.connect(func(_index: int, judgment: StringName, _lane: int) -> void: shown.append(judgment))
	_dance.start_duel(&"carp_golden", SEED)
	var notes := _dance.get_notes()
	_clock.set_time(float(notes[4]["time"]))
	_dance.advance()
	check_eq(shown.size(), 5, "the fish dances each note as the song reaches it, not all at once")

	# Higher tiers dance better.
	var previous := -1.0
	# Cempaka Lake's tier ladder; the spot fish are checked for their odds too.
	for fish_data: FishData in GameData.get_location_fish(ContentIds.START_LOCATION):
		var plan := DanceController.plan_fish(fish_data, 5, 4000)
		var perfect := float(plan.count(DanceController.PERFECT)) / 4000.0
		var odds := DanceController.fish_odds(fish_data)
		check_near(perfect, odds[DanceController.PERFECT], 0.025, "%s PERFECT share follows its odds" % fish_data.id)
		check(perfect >= previous - 0.02, "%s dances at least as well as the tier below" % fish_data.id)
		previous = perfect
	for fish_data: FishData in GameData.get_all_fish():
		var plan := DanceController.plan_fish(fish_data, 5, 4000)
		var odds := DanceController.fish_odds(fish_data)
		check_near(float(plan.count(DanceController.PERFECT)) / 4000.0, odds[DanceController.PERFECT], 0.025, "%s PERFECT share follows its odds" % fish_data.id)
	return true


# DANCE-011
func test_level_scores_go_to_the_tiebreaks() -> bool:
	# The fish copies the player exactly: level on every count, so an encore.
	_dance.start_duel(&"catfish_bruiser", SEED)
	var all_perfect: Array[StringName] = []
	for _note: int in _dance.get_notes().size() + ChartGenerator.ENCORE_NOTES:
		all_perfect.append(DanceController.PERFECT)
	_dance.debug_set_fish_plan(all_perfect)
	var result := _play(0.0)
	check(_events.has("encore"), "a dead level dance plays the four-note encore")
	check_eq(int(result["metrics"]["notes"]), int(_dance.get_chart()["notes"].size()) + 4, "four extra notes")
	check(result["player_won"], "a level encore goes to the player")

	# Same score, more PERFECTs wins. GREAT at combo 1 is 700: 7 x 1000 = 10 x 700.
	_events.clear()
	_dance.start_duel(&"catfish_bruiser", SEED)
	_clock.reset()
	var notes := _dance.get_notes()
	var plan: Array[StringName] = []
	for index: int in notes.size() + 4:
		plan.append(DanceController.MISS)
	_dance.debug_set_fish_plan(plan)
	# Player: GREAT, MISS alternating for 20 notes (10 x 700); fish below is set to
	# PERFECT, MISS for 14 notes (7 x 1000). Everything else misses for both.
	for index: int in 20:
		plan[index] = DanceController.MISS
	for index: int in 7:
		plan[index * 2] = DanceController.PERFECT
	_dance.debug_set_fish_plan(plan)
	for index: int in 20:
		_clock.set_time(float(notes[index]["time"]) + 0.08)
		if index % 2 == 0:
			_dance.submit_lane(int(notes[index]["lane"]), float(notes[index]["time"]) + 0.08)
		_dance.advance()
	var rest := _play(null)
	check_eq(rest["metrics"]["player_score"], rest["metrics"]["fish_score"], "both scored 7000")
	check(not rest["player_won"], "the fish has more PERFECTs, so the fish wins")
	check(not _events.has("encore"), "no encore was needed")
	return true


func test_every_fish_can_be_out_danced() -> bool:
	for fish: FishData in GameData.get_all_fish():
		_dance.start_duel(fish.id, SEED + fish.tier)
		_clock.reset()
		var great := _play(0.07)
		check(great["player_won"], "%s: an all-GREAT dance wins" % fish.id)
		_dance.start_duel(fish.id, SEED + fish.tier)
		_clock.reset()
		check(not _play(null)["player_won"], "%s beats a player who never presses" % fish.id)
	return true


func test_result_contract_and_shared_commit() -> bool:
	_dance.start_duel(&"tilapia_gym_rat", 55)
	var result := _play(0.0)
	for key: String in ["duel_id", "fish_id", "player_won", "duration_sec", "seed", "metrics"]:
		check(result.has(key), "result has %s (GDD 169.14)" % key)
	check_eq(result["duel_id"], &"dance", "duel id")
	check_eq(_events.count("finished"), 1, "duel_finished fires once")
	GameState.record_encounter(&"tilapia_gym_rat")
	DuelOutcome.commit(result)
	check_eq(GameState.get_stat(&"dance_wins"), 1, "dance wins are counted")

	DebugService.set_forced_result(&"loss")
	_dance.start_duel(&"tilapia_gym_rat", 55)
	_clock.reset()
	_clock.advance(0.6)
	_dance.advance()
	check(not _dance.get_result()["player_won"], "a forced loss ends the duel")
	return true


# The other music states (GDD 175.11, Section 115 tones).
func test_music_loops_render_cleanly() -> bool:
	for style: StringName in [MusicSequencer.STYLE_FISHING, MusicSequencer.STYLE_BOXING, MusicSequencer.STYLE_ARM]:
		var schedule := MusicSequencer.build_loop(style, 12)
		check(schedule["loop"], "%s loops" % style)
		var renderer := MusicRenderer.new()
		renderer.start(schedule)
		var stream := renderer.render_all()
		var samples := renderer.get_samples()
		check_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s stream loops" % style)
		check_near(float(samples.size()) / MusicRenderer.RATE, float(schedule["length_sec"]), 0.01, "%s loop length" % style)
		check(not SynthDsp.has_invalid_samples(samples) and SynthDsp.peak(samples) <= 1.0, "%s renders without NaN or clipping" % style)
		check(SynthDsp.peak(samples) > 0.05, "%s is audible" % style)
	# Fishing music leaves long silences (GDD 175.11).
	var fishing := MusicRenderer.new()
	fishing.start(MusicSequencer.build_loop(MusicSequencer.STYLE_FISHING, 31337))
	fishing.render_all()
	var quiet := 0
	var samples := fishing.get_samples()
	for index: int in range(0, samples.size(), 2205):
		if absf(samples[index]) < 0.005:
			quiet += 1
	check(float(quiet) / float(samples.size() / 2205) > 0.4, "fishing music is mostly quiet (%d%% silent)" % roundi(100.0 * float(quiet) / float(samples.size() / 2205)))
	var clicks := MusicSequencer.build_click_track(100.0, 12)
	check_eq((clicks["events"] as Array).size(), 12, "the calibration click track has one click per beat")
	return true
