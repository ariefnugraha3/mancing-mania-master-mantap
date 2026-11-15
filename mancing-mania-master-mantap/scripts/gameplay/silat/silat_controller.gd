class_name SilatController
extends DuelControllerBase
## Silat (revision 6.7, Kenanga River): a memory duel.
##
## Each round the fish shows a sequence of moves, one at a time. Then the
## player repeats it with the four arrows. The whole sequence right is a
## counter (a point for Darto); a wrong move or running out of time is a hit
## (a point for the fish). Three points win. The sequence grows by one every
## round. Stronger fish show their moves faster and give less time to answer.

signal show_step(move: StringName)
signal input_checked(move: StringName, correct: bool)
signal round_resolved(outcome: Dictionary)

const DUEL_ID := &"silat"

const LEFT := &"left"
const DOWN := &"down"
const UP := &"up"
const RIGHT := &"right"
## In lane order: the four arrows sit on S D J K like the Dance lanes.
const MOVES: Array[StringName] = [LEFT, DOWN, UP, RIGHT]

const STATE_SHOW := &"show"
const STATE_INPUT := &"input"
const STATE_REVEAL := &"reveal"

const OUTCOME_COUNTER := &"counter"
const OUTCOME_WRONG := &"wrong"
const OUTCOME_SLOW := &"slow"

const POINTS_REQUIRED := 3
const BASE_LENGTH := 3
const MAX_LENGTH := 8
const REVEAL_SEC := 1.3
## A short pause before the first move of a sequence is shown.
const LEAD_IN_SEC := 0.5
## Each shown move is followed by a blank gap, so a move shown twice in a
## row would still read as two. (Sequences never repeat a move back to back.)
const GAP_FRACTION := 0.3

var _round: int = 0
var _player_points: int = 0
var _fish_points: int = 0
var _sequence: Array[StringName] = []
var _show_index: int = -1
var _input_index: int = 0
var _step_sec: float = 0.6
var _window_sec: float = 1.5
var _last: Dictionary = {}
var _history: Array[Dictionary] = []
var _wrong_presses: int = 0


func get_duel_id() -> StringName:
	return DUEL_ID


## Seconds each move is shown for: 0.62 s for the weakest fish, 0.40 s for
## the strongest.
func step_sec() -> float:
	return lerpf(0.62, 0.40, skill())


## Seconds allowed for each answer: 1.6 s down to 1.05 s.
func window_sec() -> float:
	return lerpf(1.6, 1.05, skill())


## Sequence length of round `index` (0-based).
func length_for_round(index: int) -> int:
	var base := BASE_LENGTH + (1 if _fish != null and _fish.duel_skill >= 70.0 else 0)
	return mini(base + index, MAX_LENGTH)


## Plays one of the four moves. Only counts while it is the player's turn.
func press(move: StringName) -> void:
	if _state != STATE_INPUT or not MOVES.has(move):
		return
	var expected := _sequence[_input_index]
	var correct := move == expected
	input_checked.emit(move, correct)
	if not correct:
		_wrong_presses += 1
		_resolve(OUTCOME_WRONG)
		return
	_input_index += 1
	_timer = _window_sec
	if _input_index >= _sequence.size():
		_resolve(OUTCOME_COUNTER)


## The full sequence of this round. The HUD only shows it move by move while
## the fish demonstrates; tests and the QA bot read it here.
func debug_get_sequence() -> Array[StringName]:
	return _sequence.duplicate()


func get_history() -> Array[Dictionary]:
	return _history.duplicate(true)


# --- Rules ----------------------------------------------------------------------

func _begin() -> void:
	_round = 0
	_player_points = 0
	_fish_points = 0
	_sequence.clear()
	_history.clear()
	_last = {}
	_wrong_presses = 0
	_step_sec = step_sec()
	_window_sec = window_sec()


func _after_intro() -> void:
	_start_round()


func _tick_rules(dt: float) -> void:
	_timer -= dt
	match _state:
		STATE_SHOW:
			_tick_show()
		STATE_INPUT:
			if _timer <= 0.0:
				_resolve(OUTCOME_SLOW)
		STATE_REVEAL:
			if _timer <= 0.0:
				_start_round()


func _start_round() -> void:
	_round += 1
	_sequence.clear()
	var previous: StringName = &""
	for index: int in length_for_round(_round - 1):
		var options: Array[StringName] = MOVES.filter(func(move: StringName) -> bool: return move != previous)
		var move: StringName = options[_rng.randi() % options.size()]
		_sequence.append(move)
		previous = move
	_show_index = -1
	_input_index = 0
	_state = STATE_SHOW
	# The show runs on a single clock: lead-in, then one step per move.
	_timer = LEAD_IN_SEC + _step_sec * float(_sequence.size())


func _tick_show() -> void:
	var shown_for := LEAD_IN_SEC + _step_sec * float(_sequence.size()) - _timer
	if shown_for < LEAD_IN_SEC:
		return
	var step := int((shown_for - LEAD_IN_SEC) / _step_sec)
	if _timer <= 0.0 or step >= _sequence.size():
		_show_index = -1
		_state = STATE_INPUT
		_input_index = 0
		_timer = _window_sec
		return
	var into_step := fmod(shown_for - LEAD_IN_SEC, _step_sec)
	var visible := into_step < _step_sec * (1.0 - GAP_FRACTION)
	var index := step if visible else -1
	if index != _show_index:
		_show_index = index
		if index >= 0:
			show_step.emit(_sequence[index])


func _resolve(outcome: StringName) -> void:
	if outcome == OUTCOME_COUNTER:
		_player_points += 1
	else:
		_fish_points += 1
	_last = {
		"round": _round, "outcome": outcome, "length": _sequence.size(),
		"answered": _input_index, "player_points": _player_points, "fish_points": _fish_points,
	}
	_history.append(_last.duplicate())
	_state = STATE_REVEAL
	_timer = REVEAL_SEC
	round_resolved.emit(_last.duplicate())
	if _player_points >= POINTS_REQUIRED or _fish_points >= POINTS_REQUIRED:
		var counters := 0
		var longest := 0
		for entry: Dictionary in _history:
			if entry["outcome"] == OUTCOME_COUNTER:
				counters += 1
				longest = maxi(longest, int(entry["length"]))
		_finish(_player_points >= POINTS_REQUIRED, {
			"rounds": _history.size(), "player_points": _player_points, "fish_points": _fish_points,
			"counters": counters, "longest_sequence": longest, "wrong_presses": _wrong_presses,
		})


func _snapshot_rules() -> Dictionary:
	return {
		"round": _round,
		"player_points": _player_points,
		"fish_points": _fish_points,
		"points_required": POINTS_REQUIRED,
		"sequence_length": _sequence.size(),
		"show_move": _sequence[_show_index] if _state == STATE_SHOW and _show_index >= 0 else &"",
		"show_index": _show_index if _state == STATE_SHOW else -1,
		"input_index": _input_index,
		"time_left": maxf(_timer, 0.0) if _state == STATE_INPUT else 0.0,
		"window_sec": _window_sec,
		"last_round": _last.duplicate(),
	}
