class_name WheelController
extends Node
## The Wheel of Fate (GDD Section 38, 168.6, 169.13): eight painted segments,
## two of each duel, so every duel has the same 25% chance.
##
## The outcome is chosen from the game RNG before the wheel moves; the spin
## animation is then fitted to land on it. Frame rate can only change how
## smooth the spin looks, never where it stops (WHEEL-002).

signal wheel_resolved(duel_id: StringName)

## Segment order around the Cempaka Lake wheel, clockwise from the top.
## Every spot has its own eight segments (LocationData.wheel_segments,
## revision 6.7); a duel's share of them is its chance.
const SEGMENTS: Array[StringName] = [&"boxing", &"arm_wrestle", &"dance", &"suwit", &"boxing", &"arm_wrestle", &"dance", &"suwit"]
const MIN_SPIN_SEC := 3.1
const MAX_SPIN_SEC := 4.0
const MIN_TURNS := 3
## How long the landed segment is shown before the duel starts.
const REVEAL_SEC := 1.2
## Holding skip this long jumps to the reveal (GDD Section 38).
const SKIP_HOLD_SEC := 0.6
## A skip still shows a short reveal.
const SKIP_REVEAL_SEC := 0.8

const STATE_IDLE := &"idle"
const STATE_SPINNING := &"spinning"
const STATE_REVEAL := &"reveal"
const STATE_DONE := &"done"

var auto_advance: bool = true
## The segments of the wheel being spun: the fish's spot's wheel.
var segments: Array[StringName] = SEGMENTS

var _state: StringName = STATE_IDLE
var _duel: StringName = &""
var _segment: int = 0
var _spin_sec: float = 0.0
var _elapsed: float = 0.0
var _total_turn: float = 0.0
var _allow_skip: bool = false
var _reveal_left: float = 0.0
var _skipped: bool = false


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


# --- Public API (GDD 169.13) ------------------------------------------------

## Picks the duel, then sets up a spin that lands on it. The first Wheel of a
## save is the tutorial and always lands on Boxing (GDD 176.10, WHEEL-005).
func start_wheel(fish_id: StringName, seed: int, allow_skip: bool) -> void:
	segments = segments_for(fish_id)
	_duel = pick_duel(fish_id, seed)
	var choices: Array[int] = []
	for index: int in segments.size():
		if segments[index] == _duel:
			choices.append(index)
	_segment = choices[RNGService.choose_index(&"wheel_segment", seed, choices.size())]
	_spin_sec = lerpf(MIN_SPIN_SEC, MAX_SPIN_SEC, RNGService.roll_float(&"wheel_time", seed))
	var turns := MIN_TURNS + RNGService.choose_index(&"wheel_turns", seed, 2)
	_total_turn = float(turns) + segment_angle(_segment) / TAU
	_elapsed = 0.0
	_allow_skip = allow_skip
	_skipped = false
	_state = STATE_SPINNING
	GameLog.info(&"WHEEL", "spin", {"fish": fish_id, "duel": _duel, "segment": _segment})


## Jumps to the reveal. Only allowed after the first Wheel has been seen.
func request_skip() -> void:
	if not _allow_skip or _state != STATE_SPINNING:
		return
	_skipped = true
	_elapsed = _spin_sec
	_begin_reveal(SKIP_REVEAL_SEC)


func get_preselected_duel_id() -> StringName:
	return _duel


# --- Extras -----------------------------------------------------------------

func get_state() -> StringName:
	return _state


func get_segment() -> int:
	return _segment


func was_skipped() -> bool:
	return _skipped


func get_spin_sec() -> float:
	return _spin_sec


## Wheel rotation in turns (1.0 = a full turn). It eases out and ends exactly
## with the chosen segment under the pointer.
func get_rotation_turns() -> float:
	var progress := clampf(_elapsed / maxf(_spin_sec, 0.001), 0.0, 1.0)
	return _total_turn * (1.0 - pow(1.0 - progress, 3.0))


## Which segment is under the pointer right now.
func get_segment_under_pointer() -> int:
	var turn := fposmod(get_rotation_turns(), 1.0)
	return roundi(turn * float(segments.size())) % segments.size()


## Rotation that puts `segment` under the pointer at the top.
static func segment_angle(segment: int) -> float:
	return TAU * float(segment) / float(SEGMENTS.size())


## The eight segments of the wheel for a fish: its spot's wheel.
static func segments_for(fish_id: StringName) -> Array[StringName]:
	var location := GameData.get_location(ContentIds.location_of_fish(fish_id))
	if location == null or location.wheel_segments.size() != SEGMENTS.size():
		return SEGMENTS
	return location.wheel_segments


## The duel for this fish and seed: Boxing for the tutorial, otherwise one of
## the spot's duels by its share of the wheel, from the game RNG. On an even
## wheel (Cempaka Lake: four duels, two segments each) every duel has the same
## chance, rolled exactly as before revision 6.7.
static func pick_duel(fish_id: StringName, seed: int) -> StringName:
	var forced := DebugService.get_forced_duel()
	if forced != &"":
		return forced
	if not GameState.is_tutorial_seen(&"wheel_seen"):
		return &"boxing"
	var wheel := segments_for(fish_id)
	var duels: Array[StringName] = []
	for duel_id: StringName in wheel:
		if not duels.has(duel_id):
			duels.append(duel_id)
	if wheel.size() % duels.size() == 0 and duels.all(func(duel_id: StringName) -> bool: return wheel.count(duel_id) == wheel.size() / duels.size()):
		return duels[RNGService.choose_index(&"wheel_duel", seed, duels.size())]
	return wheel[RNGService.choose_index(&"wheel_duel", seed, wheel.size())]


func advance(delta: float) -> void:
	match _state:
		STATE_SPINNING:
			_elapsed += minf(maxf(delta, 0.0), 0.1)
			if _elapsed >= _spin_sec:
				_elapsed = _spin_sec
				_begin_reveal(REVEAL_SEC)
		STATE_REVEAL:
			_reveal_left -= minf(maxf(delta, 0.0), 0.1)
			if _reveal_left <= 0.0:
				_state = STATE_DONE
				wheel_resolved.emit(_duel)


func _begin_reveal(seconds: float) -> void:
	_state = STATE_REVEAL
	_reveal_left = seconds
