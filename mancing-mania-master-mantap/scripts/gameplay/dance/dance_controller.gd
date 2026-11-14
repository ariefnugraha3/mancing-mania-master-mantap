class_name DanceController
extends Node
## Joget Koplo rules (GDD 57-63, 169.13, 170.6).
##
## Both dancers play the same chart. The player's hits are judged against the
## RhythmClock, which follows the audio, with the calibration offset applied.
## The fish's judgments come note by note from its Rhythm Skill and the duel
## seed, so its dance can be shown move by move and replayed exactly.
##
## After the last note: higher score wins; then more PERFECTs; then the higher
## max combo; then a four-note encore (GDD Section 63).

signal duel_started(snapshot: Dictionary)
## A note was settled for the player: &"perfect", &"great", &"good" or &"miss".
signal note_judged(index: int, judgment: StringName, lane: int, delta_ms: float)
signal fish_note_judged(index: int, judgment: StringName, lane: int)
signal encore_started()
signal duel_finished(result: Dictionary)

const DUEL_ID := &"dance"

const STATE_IDLE := &"idle"
const STATE_PLAYING := &"playing"
const STATE_ENCORE := &"encore"
const STATE_FINISHED := &"finished"

const PERFECT := &"perfect"
const GREAT := &"great"
const GOOD := &"good"
const MISS := &"miss"
const JUDGMENTS: Array[StringName] = [PERFECT, GREAT, GOOD, MISS]

## Visual travel time of a note at Coffee Lv0, from spawn to the hit line.
const BASE_APPROACH_SEC := 1.25

@export var clock: RhythmClock

var _config: DanceConfig
var _fish: FishData
var _seed: int = 0
var _chart: Dictionary = {}
var _notes: Array = []
var _state: StringName = STATE_IDLE
var _player: Dictionary = {}
var _fish_side: Dictionary = {}
var _player_results: Array[StringName] = []
var _fish_plan: Array[StringName] = []
var _fish_shown: int = 0
var _encore_from: int = -1
var _input_offset_sec: float = 0.0
var _last_judgment: StringName = &""
var _result: Dictionary = {}


# --- Public API (GDD 169.13) ------------------------------------------------

## Builds the chart for this fish and duel seed and resets both scores. The
## clock is not touched: the scene starts the song, and with it the clock.
func start_duel(fish_id: StringName, seed: int) -> void:
	_config = GameData.get_dance_config()
	_fish = GameData.get_fish(fish_id)
	if _fish == null:
		GameLog.error(&"DANCE", "unknown fish", {"fish": fish_id})
		return
	_seed = seed
	_chart = ChartGenerator.generate(fish_id, seed)
	_notes = (_chart["notes"] as Array).duplicate(true)
	_player_results.clear()
	_player_results.resize(_notes.size())
	_player_results.fill(&"")
	_fish_plan = plan_fish(_fish, _chart["seed"], _notes.size() + ChartGenerator.ENCORE_NOTES)
	_fish_shown = 0
	_encore_from = -1
	_player = _new_side()
	_fish_side = _new_side()
	_last_judgment = &""
	_result = {}
	_input_offset_sec = float(GameState.get_setting(&"rhythm_input_offset_ms")) / 1000.0
	_state = STATE_PLAYING
	GameLog.info(&"DANCE", "duel", {"fish": fish_id, "seed": _chart["seed"], "bpm": _chart["bpm"], "notes": _notes.size()})
	duel_started.emit(get_snapshot())


## A lane was pressed at `event_time_sec` on the song clock. The calibration
## offset is applied, then the nearest open note in that lane within the GOOD
## window is judged. A press with no note near it costs nothing.
func submit_lane(lane_index: int, event_time_sec: float) -> void:
	if not _is_live() or lane_index < 0 or lane_index >= ChartGenerator.LANES:
		return
	var time := event_time_sec - _input_offset_sec
	var good := float(_config.good_window_ms) / 1000.0
	# Notes this press is already too late for are missed first, so a combo
	# breaks in the right order even within one frame.
	_expire_until(time)
	var best := -1
	var best_delta := INF
	for index: int in _notes.size():
		if _player_results[index] != &"" or int(_notes[index]["lane"]) != lane_index:
			continue
		var delta := time - float(_notes[index]["time"])
		if absf(delta) <= good + 0.000001 and absf(delta) < absf(best_delta):
			best = index
			best_delta = delta
	if best < 0:
		return
	_settle(best, judge(best_delta), best_delta * 1000.0)


func get_song_time_sec() -> float:
	return clock.get_time() if clock != null else 0.0


func get_snapshot() -> Dictionary:
	return {
		"state": _state,
		"fish_id": _fish.id if _fish != null else &"",
		"song_time": get_song_time_sec(),
		"bpm": _chart.get("bpm", 0.0),
		"beat_sec": _chart.get("beat_sec", 0.5),
		"duration_sec": _chart.get("duration_sec", 0.0),
		"note_count": _notes.size(),
		"player_score": int(_player.get("score", 0)),
		"player_combo": int(_player.get("combo", 0)),
		"player_max_combo": int(_player.get("max_combo", 0)),
		"player_counts": (_player.get("counts", {}) as Dictionary).duplicate(),
		"fish_score": int(_fish_side.get("score", 0)),
		"fish_combo": int(_fish_side.get("combo", 0)),
		"fish_max_combo": int(_fish_side.get("max_combo", 0)),
		"fish_counts": (_fish_side.get("counts", {}) as Dictionary).duplicate(),
		"last_judgment": _last_judgment,
		"approach_sec": approach_sec(),
		"encore": _state == STATE_ENCORE,
	}


# --- Extras -----------------------------------------------------------------

func get_state() -> StringName:
	return _state


func get_chart() -> Dictionary:
	return _chart


## The notes, with the encore notes appended once it starts.
func get_notes() -> Array:
	return _notes


## The player's judgment of a note, or &"" while it is still open.
func get_player_judgment(index: int) -> StringName:
	return _player_results[index] if index >= 0 and index < _player_results.size() else &""


func get_result() -> Dictionary:
	return _result.duplicate(true)


## How long a note is on screen before it reaches the hit line. Black Coffee
## slows the notes down, so they appear earlier; the beat never moves (GDD 62).
static func approach_sec() -> float:
	return BASE_APPROACH_SEC / UpgradeEffects.coffee_speed_multiplier(GameState.get_upgrade_level(&"coffee"))


## Which judgment a timing error gets (GDD Section 59).
static func judge(delta_sec: float) -> StringName:
	var config := GameData.get_dance_config()
	var error := absf(delta_sec) * 1000.0
	if error <= float(config.perfect_window_ms) + 0.0001:
		return PERFECT
	if error <= float(config.great_window_ms) + 0.0001:
		return GREAT
	if error <= float(config.good_window_ms) + 0.0001:
		return GOOD
	return MISS


## Points for a judgment at a combo: base x (1 + min(floor(combo / 10) x 0.1, 0.5)).
static func points(judgment: StringName, combo: int) -> int:
	var config := GameData.get_dance_config()
	var base := 0
	match judgment:
		PERFECT:
			base = config.perfect_score
		GREAT:
			base = config.great_score
		GOOD:
			base = config.good_score
	var bonus := minf(float(combo / config.combo_step) * config.combo_bonus_step, config.combo_bonus_max)
	return roundi(float(base) * (1.0 + bonus))


## The chance of each judgment for a fish, from its Rhythm Skill (GDD 61):
## low tiers lean to GOOD and MISS, high tiers to PERFECT and GREAT.
static func fish_odds(fish: FishData) -> Dictionary:
	var skill := clampf((fish.rhythm_skill - 50.0) / 45.0, 0.0, 1.0)
	var perfect := 0.18 + 0.42 * skill
	var great := 0.32
	var miss := 0.2 - 0.16 * skill
	return {PERFECT: perfect, GREAT: great, GOOD: 1.0 - perfect - great - miss, MISS: miss}


## The fish's judgment for every note, decided up front from the seed.
static func plan_fish(fish: FishData, seed: int, count: int) -> Array[StringName]:
	var odds := fish_odds(fish)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed ^ 0x5F3759DF
	var plan: Array[StringName] = []
	for _note: int in count:
		var roll := rng.randf()
		var picked := MISS
		for judgment: StringName in [PERFECT, GREAT, GOOD]:
			roll -= float(odds[judgment])
			if roll < 0.0:
				picked = judgment
				break
		plan.append(picked)
	return plan


## Settles everything the clock has passed: notes nobody hit become MISS, the
## fish dances each note as it arrives, and the duel ends after the last one.
func advance(_delta: float = 0.0) -> void:
	if not _is_live():
		return
	var forced := DebugService.get_forced_result()
	if forced != &"" and get_song_time_sec() > 0.5:
		_finish(forced == &"win")
		return
	_expire_until(get_song_time_sec() - _input_offset_sec)
	var song_now := get_song_time_sec()
	while _fish_shown < _notes.size() and song_now >= float(_notes[_fish_shown]["time"]):
		var judgment := _fish_plan[_fish_shown]
		_score(_fish_side, judgment)
		fish_note_judged.emit(_fish_shown, judgment, int(_notes[_fish_shown]["lane"]))
		_fish_shown += 1
	if not _player_results.has(&"") and _fish_shown >= _notes.size():
		_resolve()


func _process(delta: float) -> void:
	advance(delta)


# --- Internals --------------------------------------------------------------

func _is_live() -> bool:
	return _state == STATE_PLAYING or _state == STATE_ENCORE


func _new_side() -> Dictionary:
	return {"score": 0, "combo": 0, "max_combo": 0, "counts": {PERFECT: 0, GREAT: 0, GOOD: 0, MISS: 0}}


## Every open note whose GOOD window closed before `time` becomes a MISS.
func _expire_until(time: float) -> void:
	var good := float(_config.good_window_ms) / 1000.0
	for index: int in _notes.size():
		if _player_results[index] == &"" and time > float(_notes[index]["time"]) + good:
			_settle(index, MISS, good * 1000.0)


func _settle(index: int, judgment: StringName, delta_ms: float) -> void:
	_player_results[index] = judgment
	_last_judgment = judgment
	_score(_player, judgment)
	note_judged.emit(index, judgment, int(_notes[index]["lane"]), delta_ms)


## A hit extends the combo and scores with the combo bonus it has reached;
## a miss breaks the combo (GDD Section 60).
func _score(side: Dictionary, judgment: StringName) -> void:
	var counts: Dictionary = side["counts"]
	counts[judgment] = int(counts[judgment]) + 1
	if judgment == MISS:
		side["combo"] = 0
		return
	side["combo"] = int(side["combo"]) + 1
	side["max_combo"] = maxi(int(side["max_combo"]), int(side["combo"]))
	side["score"] = int(side["score"]) + points(judgment, int(side["combo"]))


func _resolve() -> void:
	var winner := _compare()
	if winner == 0 and _state == STATE_PLAYING:
		_start_encore()
		return
	# A level encore goes to the player: nothing is left to compare.
	_finish(winner >= 0)


## +1 player ahead, -1 fish ahead, 0 level after every tiebreak (GDD 63).
func _compare() -> int:
	var keys: Array = [
		[int(_player["score"]), int(_fish_side["score"])],
		[int(_player["counts"][PERFECT]), int(_fish_side["counts"][PERFECT])],
		[int(_player["max_combo"]), int(_fish_side["max_combo"])],
	]
	for pair: Array in keys:
		if pair[0] != pair[1]:
			return 1 if pair[0] > pair[1] else -1
	return 0


## Four more notes in the spare bar; both sides keep their totals.
func _start_encore() -> void:
	_state = STATE_ENCORE
	_encore_from = _notes.size()
	for note: Dictionary in _chart["encore"]:
		_notes.append(note.duplicate())
		_player_results.append(&"")
	encore_started.emit()


func _finish(player_won: bool) -> void:
	_state = STATE_FINISHED
	_result = {
		"duel_id": DUEL_ID,
		"fish_id": _fish.id,
		"player_won": player_won,
		"duration_sec": get_song_time_sec(),
		"seed": _seed,
		"metrics": {
			"chart_seed": _chart["seed"], "bpm": _chart["bpm"], "notes": _notes.size(),
			"player_score": _player["score"], "fish_score": _fish_side["score"],
			"player_counts": (_player["counts"] as Dictionary).duplicate(),
			"fish_counts": (_fish_side["counts"] as Dictionary).duplicate(),
			"player_max_combo": _player["max_combo"], "fish_max_combo": _fish_side["max_combo"],
			"encore": _encore_from >= 0,
		},
	}
	GameLog.info(&"DANCE", "finished", {"won": player_won, "player": _player["score"], "fish": _fish_side["score"]})
	duel_finished.emit(get_result())


# --- Test hooks -------------------------------------------------------------

## Replaces the fish's planned judgments, for the tiebreak tests.
func debug_set_fish_plan(plan: Array[StringName]) -> void:
	_fish_plan = plan
