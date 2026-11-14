class_name FishingController
extends Node
## The fishing phase state machine (GDD Sections 23-37, 169.11).
##
##   idle -> casting -> waiting -> bite_warning -> strike_window -> reeling
##                                                               -> landed | escaped -> idle
##
## The controller owns the rules and the clock. It knows nothing about meshes
## or HUD nodes: the world and the HUD listen to its signals. Time advances
## only through advance(), with each frame's step capped, so one slow frame can
## never swallow a reaction window.

signal fishing_state_changed(state: StringName)
signal encounter_rolled(encounter: Dictionary)
signal fish_landed(fish_id: StringName, weight_kg: float)
signal fishing_failed(reason: StringName)

# Moments the world and the audio react to.
signal float_released()
signal float_landed()
signal nibbled()
signal bite_started(strike_window_sec: float)
signal false_strike()
signal strike_succeeded(encounter: Dictionary)
signal trash_caught(item_id: StringName)
## The catch left the fishing phase: {outcome, item_id}. Outcomes are
## &"bucket" (trash), &"duel" (routed onward) and &"bucket_no_duel".
signal catch_resolved(outcome: Dictionary)

const STATE_IDLE := &"idle"
const STATE_CASTING := &"casting"
const STATE_WAITING := &"waiting"
const STATE_BITE_WARNING := &"bite_warning"
const STATE_STRIKE_WINDOW := &"strike_window"
const STATE_REELING := &"reeling"
const STATE_LANDED := &"landed"
const STATE_ESCAPED := &"escaped"

const REASON_MISSED_STRIKE := &"missed_strike"
const REASON_LINE_BREAK := &"line_break"

const OUTCOME_BUCKET := &"bucket"
const OUTCOME_DUEL := &"duel"
const OUTCOME_BUCKET_NO_DUEL := &"bucket_no_duel"

# Cast timing (GDD Section 24).
const CAST_DURATION_SEC := 1.35
const FLOAT_RELEASE_SEC := 0.48
const FLOAT_LAND_SEC := 1.05
## Time on screen for the catch reveal before the game moves on.
const FISH_REVEAL_SEC := 3.2
const TRASH_REVEAL_SEC := 1.5
const ESCAPE_HOLD_SEC := 1.3
## Largest time step taken in one frame.
const MAX_STEP_SEC := 0.1
## Debug override for the waiting time (GDD 178.2).
const DEBUG_FAST_WAIT_SEC := 0.5

## Set false to drive the controller by hand (tests).
var auto_advance: bool = true

var _state: StringName = STATE_IDLE
var _encounter: Dictionary = {}
var _reel := ReelSimulation.new()
var _reel_held: bool = false
var _timer: float = 0.0
var _wait_left: float = 0.0
var _window_left: float = 0.0
var _next_nibble: int = 0
var _waited: float = 0.0
var _float_released: bool = false
var _float_landed: bool = false
var _resolved: bool = false


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


# --- Public API (GDD 169.11) ------------------------------------------------

func start_cast() -> void:
	if _state != STATE_IDLE:
		return
	var forced := DebugService.get_forced_fish()
	if forced == &"" and _is_first_catch():
		# The very first fish is always Bruiser Catfish (GDD Section 13).
		forced = &"catfish_bruiser"
	var wait_override := DEBUG_FAST_WAIT_SEC if DebugService.is_fast_wait_enabled() else -1.0
	_encounter = EncounterRoller.roll(
		RNGService.next_encounter_seed(), GameState.get_upgrade_level(&"bait"), forced, wait_override)
	GameState.increment_stat(&"total_casts")
	_timer = 0.0
	_float_released = false
	_float_landed = false
	_resolved = false
	_reel_held = false
	GameLog.info(&"FISHING", "encounter", {
		"item": _encounter["item_id"], "seed": _encounter["seed"], "wait": "%.2f" % _encounter["wait_sec"]})
	encounter_rolled.emit(_encounter.duplicate(true))
	_set_state(STATE_CASTING)


## The single reaction input. In the strike window it hooks the catch; while
## waiting it is a harmless empty pull that delays the bite a little.
func attempt_strike() -> void:
	match _state:
		STATE_STRIKE_WINDOW:
			GameState.increment_stat(&"successful_strikes")
			GameState.set_tutorial_seen(&"fishing_seen")
			strike_succeeded.emit(_encounter.duplicate(true))
			if _encounter["kind"] == EncounterRoller.KIND_TRASH:
				_land_trash()
			else:
				_reel.setup(GameData.get_fish(_encounter["item_id"]), GameState.get_upgrade_level(&"rod"), int(_encounter["seed"]))
				_set_state(STATE_REELING)
		STATE_WAITING, STATE_BITE_WARNING:
			_wait_left = maxf(_wait_left, 0.0) + GameData.get_fishing_balance().false_strike_delay_sec
			false_strike.emit()
			if _state == STATE_BITE_WARNING:
				_set_state(STATE_WAITING)


func set_reel_held(held: bool) -> void:
	_reel_held = held


## Drops whatever is happening and returns to idle without any penalty or stat.
func cancel_to_idle() -> void:
	_reel_held = false
	_encounter = {}
	_set_state(STATE_IDLE)


func get_state() -> StringName:
	return _state


# --- Extras for the world, the HUD and tests --------------------------------

## Advances the clock. Called every frame; tests call it directly.
func advance(delta: float) -> void:
	var step := clampf(delta, 0.0, MAX_STEP_SEC)
	if step <= 0.0:
		return
	GameState.add_play_time(step)
	match _state:
		STATE_CASTING:
			_advance_cast(step)
		STATE_WAITING, STATE_BITE_WARNING:
			_advance_wait(step)
		STATE_STRIKE_WINDOW:
			_window_left -= step
			if _window_left <= 0.0:
				_fail(REASON_MISSED_STRIKE)
		STATE_REELING:
			_advance_reel(step)
		STATE_LANDED:
			_timer += step
			if not _resolved and _timer >= _reveal_duration():
				_resolve_catch()
		STATE_ESCAPED:
			_timer += step
			if _timer >= ESCAPE_HOLD_SEC:
				_encounter = {}
				_set_state(STATE_IDLE)


func get_encounter() -> Dictionary:
	return _encounter.duplicate(true)


func get_reel() -> ReelSimulation:
	return _reel


func is_reel_held() -> bool:
	return _reel_held


## Share of the strike window still open, 1.0 down to 0.0.
func get_strike_window_ratio() -> float:
	if _state != STATE_STRIKE_WINDOW or _encounter.is_empty():
		return 0.0
	return clampf(_window_left / float(_encounter["strike_window_sec"]), 0.0, 1.0)


## Seconds spent in the current cast or reveal; the world times its motion on this.
func get_state_time() -> float:
	return _timer


# --- State steps ------------------------------------------------------------

func _advance_cast(step: float) -> void:
	_timer += step
	if not _float_released and _timer >= FLOAT_RELEASE_SEC:
		_float_released = true
		float_released.emit()
	if not _float_landed and _timer >= FLOAT_LAND_SEC:
		_float_landed = true
		float_landed.emit()
	if _timer >= CAST_DURATION_SEC:
		_wait_left = float(_encounter["wait_sec"])
		_waited = 0.0
		_next_nibble = 0
		_set_state(STATE_WAITING)


func _advance_wait(step: float) -> void:
	_wait_left -= step
	_waited += step
	var nibbles: Array = _encounter["nibble_times"]
	if _state == STATE_WAITING and _next_nibble < nibbles.size() and _waited >= float(nibbles[_next_nibble]):
		_next_nibble += 1
		nibbled.emit()

	var warning := GameData.get_fishing_balance().bite_warning_sec
	if _state == STATE_WAITING and _wait_left <= warning:
		_set_state(STATE_BITE_WARNING)
	if _wait_left <= 0.0:
		_window_left = float(_encounter["strike_window_sec"])
		_set_state(STATE_STRIKE_WINDOW)
		bite_started.emit(_window_left)


func _advance_reel(step: float) -> void:
	match _reel.step(step, _reel_held):
		ReelSimulation.RESULT_LANDED:
			_land_fish()
		ReelSimulation.RESULT_LINE_BREAK:
			_fail(REASON_LINE_BREAK)


func _land_fish() -> void:
	var fish_id: StringName = _encounter["item_id"]
	_reel_held = false
	_timer = 0.0
	GameState.increment_stat(&"fish_landed")
	GameState.record_encounter(fish_id)
	GameState.set_tutorial_seen(&"reeling_seen")
	_set_state(STATE_LANDED)
	fish_landed.emit(fish_id, float(_encounter["weight_kg"]))


func _land_trash() -> void:
	var item_id: StringName = _encounter["item_id"]
	_timer = 0.0
	GameState.increment_stat(&"trash_caught")
	_set_state(STATE_LANDED)
	trash_caught.emit(item_id)


func _fail(reason: StringName) -> void:
	_reel_held = false
	_timer = 0.0
	GameState.increment_stat(&"lines_broken" if reason == REASON_LINE_BREAK else &"failed_strikes")
	GameLog.info(&"FISHING", "escaped", {"reason": reason, "item": _encounter.get("item_id", "")})
	_set_state(STATE_ESCAPED)
	fishing_failed.emit(reason)


## Hands the catch on. Trash goes straight into the Bucket; a fish goes to the
## Wheel, or directly to a duel while the Wheel scene is not in the build.
func _resolve_catch() -> void:
	_resolved = true
	var item_id: StringName = _encounter["item_id"]
	if _encounter["kind"] == EncounterRoller.KIND_TRASH:
		GameState.add_bucket_item(item_id)
		SaveManager.save_game(&"catch")
		_finish(OUTCOME_BUCKET, item_id)
		return

	GameState.current_fish = item_id
	GameState.current_catch = {
		"fish_id": item_id,
		"weight_kg": _encounter["weight_kg"],
		"is_big_one": _encounter["is_big_one"],
		"seed": _encounter["seed"],
	}
	if SceneRouter.has_scene(SceneRouter.SCENE_WHEEL):
		catch_resolved.emit({"outcome": OUTCOME_DUEL, "item_id": item_id})
		SceneRouter.goto_wheel(item_id)
		return
	var duel := pick_duel(int(_encounter["seed"]))
	if duel != &"":
		GameState.current_duel = duel
		catch_resolved.emit({"outcome": OUTCOME_DUEL, "item_id": item_id})
		SceneRouter.goto_duel(duel, item_id)
		return

	# No duel scene exists in this build yet, so there is nothing to lose to:
	# the fish goes into the Bucket and the HUD says why.
	GameState.add_bucket_item(item_id)
	GameState.current_fish = &""
	GameState.current_catch = {}
	SaveManager.save_game(&"catch")
	_finish(OUTCOME_BUCKET_NO_DUEL, item_id)


func _finish(outcome: StringName, item_id: StringName) -> void:
	_encounter = {}
	_set_state(STATE_IDLE)
	catch_resolved.emit({"outcome": outcome, "item_id": item_id})


## Which duel settles this catch while the Wheel is not in the build. The very
## first duel is always Boxing (GDD 176.10); after that every duel in the
## build is equally likely, chosen from the encounter seed, so the choice is
## fixed before anything is shown (GDD Section 38).
static func pick_duel(seed: int) -> StringName:
	var forced := DebugService.get_forced_duel()
	if forced != &"" and SceneRouter.has_scene(forced):
		return forced
	var available: Array[StringName] = []
	for duel_id: StringName in ContentIds.DUEL_IDS:
		if SceneRouter.has_scene(duel_id):
			available.append(duel_id)
	if available.is_empty():
		return &""
	if not GameState.is_tutorial_seen(&"boxing_seen") and available.has(&"boxing"):
		return &"boxing"
	return available[RNGService.choose_index(&"duel_pick", seed, available.size())]


func _reveal_duration() -> float:
	return TRASH_REVEAL_SEC if _encounter.get("kind") == EncounterRoller.KIND_TRASH else FISH_REVEAL_SEC


func _is_first_catch() -> bool:
	return int(GameState.get_stat(&"fish_landed")) == 0 and not GameState.is_tutorial_seen(&"reeling_seen")


func _set_state(state: StringName) -> void:
	if _state == state:
		return
	_state = state
	fishing_state_changed.emit(_state)
