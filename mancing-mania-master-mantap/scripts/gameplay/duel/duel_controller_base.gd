class_name DuelControllerBase
extends Node
## Shared plumbing of the four spot duels (revision 6.7): Silat, Tug of War,
## Spinning Tops and Greased Pole.
##
## Like the first four duels, a match is a deterministic simulation stepped
## at a fixed 120 Hz: the same seed and the same inputs at the same ticks
## always give the same result (GDD 169.13). Subclasses only implement the
## rules (`_begin`, `_tick_rules`, `_snapshot_rules`) and call `_finish`.
## The fish's strength in these duels is its `duel_skill` (0-100).

signal duel_started(snapshot: Dictionary)
signal duel_finished(result: Dictionary)

const STATE_IDLE := &"idle"
const STATE_INTRO := &"intro"
const STATE_FINISHED := &"finished"

const TICK_SEC := 1.0 / 120.0
const MAX_STEP_SEC := 0.1
const INTRO_SEC := 1.2

var auto_advance: bool = true

var _fish: FishData
var _seed: int = 0
var _rng := RandomNumberGenerator.new()
var _state: StringName = STATE_IDLE
var _accumulator: float = 0.0
var _elapsed: float = 0.0
var _timer: float = 0.0
var _result: Dictionary = {}


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


# --- Public API ---------------------------------------------------------------

## The duel's ID in ContentIds.DUEL_IDS.
func get_duel_id() -> StringName:
	return &""


func start_duel(fish_id: StringName, seed: int) -> void:
	_fish = GameData.get_fish(fish_id)
	if _fish == null:
		GameLog.error(&"DUEL", "unknown fish", {"fish": fish_id, "duel": get_duel_id()})
		return
	_seed = seed
	_rng.seed = seed
	_accumulator = 0.0
	_elapsed = 0.0
	_result = {}
	_state = STATE_INTRO
	_timer = INTRO_SEC
	_begin()
	GameLog.info(&"DUEL", "start", {"duel": get_duel_id(), "fish": fish_id, "seed": seed})
	duel_started.emit(get_snapshot())


func advance(delta: float) -> void:
	if _state == STATE_IDLE or _state == STATE_FINISHED:
		return
	_accumulator += minf(maxf(delta, 0.0), MAX_STEP_SEC)
	while _accumulator >= TICK_SEC and _state != STATE_FINISHED:
		_accumulator -= TICK_SEC
		_elapsed += TICK_SEC
		if _state == STATE_INTRO:
			_timer -= TICK_SEC
			if _timer <= 0.0:
				var forced := DebugService.get_forced_result()
				if forced != &"":
					_finish(forced == &"win", {"forced": true})
					return
				_after_intro()
		else:
			_tick_rules(TICK_SEC)


func get_snapshot() -> Dictionary:
	var snapshot := {
		"state": _state,
		"fish_id": _fish.id if _fish != null else &"",
		"elapsed": _elapsed,
	}
	if _fish != null:
		snapshot.merge(_snapshot_rules(), true)
	return snapshot


func get_state() -> StringName:
	return _state


func get_result() -> Dictionary:
	return _result.duplicate(true)


func is_running() -> bool:
	return _state != STATE_IDLE and _state != STATE_INTRO and _state != STATE_FINISHED


## The fish's skill as 0..1.
func skill() -> float:
	return clampf(_fish.duel_skill / 100.0, 0.0, 1.0) if _fish != null else 0.5


# --- For subclasses -----------------------------------------------------------

func _begin() -> void:
	pass


func _after_intro() -> void:
	pass


func _tick_rules(_dt: float) -> void:
	pass


func _snapshot_rules() -> Dictionary:
	return {}


func _finish(player_won: bool, metrics: Dictionary) -> void:
	_state = STATE_FINISHED
	_result = {
		"duel_id": get_duel_id(),
		"fish_id": _fish.id,
		"player_won": player_won,
		"duration_sec": _elapsed,
		"seed": _seed,
		"metrics": metrics,
	}
	GameLog.info(&"DUEL", "finished", {"duel": get_duel_id(), "won": player_won})
	duel_finished.emit(get_result())


## A value that bounces between 0 and 1: `t` is distance travelled.
static func ping_pong01(t: float) -> float:
	var cycle := fposmod(t, 2.0)
	return cycle if cycle <= 1.0 else 2.0 - cycle
