class_name PinangController
extends DuelControllerBase
## Greased Pole (revision 6.7, Mawar Pier): a rhythm race up two poles.
##
## Darto climbs by tapping LEFT and RIGHT in turn. The same side twice is a
## slip: he slides down a little and needs a moment. Tapping faster than a
## steady rhythm smears the grease: the grease meter fills, and when it is
## full he slides down further. The fish climbs at its own pace and slips now
## and then. First to the top wins; when time runs out, the higher one wins.

signal climbed(height: float)
signal player_slipped(reason: StringName)
signal fish_climbed(height: float)
signal fish_slipped()

const DUEL_ID := &"pinang"

const STATE_CLIMB := &"climb"

const LEFT := &"left"
const RIGHT := &"right"

const SLIP_SAME_SIDE := &"same_side"
const SLIP_GREASE := &"grease"

const STEP := 0.034
const SAME_SIDE_SLIDE := 0.05
const SAME_SIDE_STUN_SEC := 0.45
## Taps closer together than this smear the grease.
const STEADY_INTERVAL_SEC := 0.17
const GREASE_PER_RUSHED_TAP := 0.45
const GREASE_DECAY_PER_SEC := 0.9
const GREASE_SLIDE := 0.08
const GREASE_STUN_SEC := 0.6
const FISH_SLIDE := 0.05
const FISH_SLIP_PAUSE_SEC := 0.45
const TIME_LIMIT_SEC := 40.0

var _height: float = 0.0
var _fish_height: float = 0.0
var _last_side: StringName = &""
var _since_tap: float = 99.0
var _grease: float = 0.0
var _stun: float = 0.0
var _fish_wait: float = 0.0
var _taps: int = 0
var _same_side_slips: int = 0
var _grease_slips: int = 0
var _fish_slips: int = 0


func get_duel_id() -> StringName:
	return DUEL_ID


## Average seconds between the fish's grabs: 0.40 s for the weakest fish,
## 0.22 s for the strongest.
func fish_interval() -> float:
	return lerpf(0.40, 0.22, skill())


## Chance that a grab of the fish slips: 10 % down to 4 %.
func fish_slip_chance() -> float:
	return lerpf(0.10, 0.04, skill())


## One tap of LEFT or RIGHT.
func press(side: StringName) -> void:
	if _state != STATE_CLIMB or _stun > 0.0 or (side != LEFT and side != RIGHT):
		return
	_taps += 1
	if side == _last_side:
		_last_side = &""
		_height = maxf(_height - SAME_SIDE_SLIDE, 0.0)
		_stun = SAME_SIDE_STUN_SEC
		_same_side_slips += 1
		player_slipped.emit(SLIP_SAME_SIDE)
		return
	if _since_tap < STEADY_INTERVAL_SEC:
		_grease += GREASE_PER_RUSHED_TAP
	_since_tap = 0.0
	_last_side = side
	if _grease >= 1.0:
		_grease = 0.0
		_last_side = &""
		_height = maxf(_height - GREASE_SLIDE, 0.0)
		_stun = GREASE_STUN_SEC
		_grease_slips += 1
		player_slipped.emit(SLIP_GREASE)
		return
	_height = minf(_height + STEP, 1.0)
	climbed.emit(_height)
	_check_end()


## The side the next tap should be, or &"" when either side is fine.
func get_expected_side() -> StringName:
	if _last_side == LEFT:
		return RIGHT
	if _last_side == RIGHT:
		return LEFT
	return &""


# --- Rules ----------------------------------------------------------------------

func _begin() -> void:
	_height = 0.0
	_fish_height = 0.0
	_last_side = &""
	_since_tap = 99.0
	_grease = 0.0
	_stun = 0.0
	_taps = 0
	_same_side_slips = 0
	_grease_slips = 0
	_fish_slips = 0
	_fish_wait = _next_fish_wait()


func _after_intro() -> void:
	_state = STATE_CLIMB
	_timer = TIME_LIMIT_SEC


func _tick_rules(dt: float) -> void:
	_timer -= dt
	_since_tap += dt
	_stun = maxf(_stun - dt, 0.0)
	_grease = maxf(_grease - GREASE_DECAY_PER_SEC * dt, 0.0)
	_fish_wait -= dt
	if _fish_wait <= 0.0:
		if _rng.randf() < fish_slip_chance():
			_fish_height = maxf(_fish_height - FISH_SLIDE, 0.0)
			_fish_slips += 1
			_fish_wait = FISH_SLIP_PAUSE_SEC + _next_fish_wait()
			fish_slipped.emit()
		else:
			_fish_height = minf(_fish_height + STEP, 1.0)
			_fish_wait = _next_fish_wait()
			fish_climbed.emit(_fish_height)
	_check_end()
	if _state == STATE_CLIMB and _timer <= 0.0:
		_end(_height > _fish_height)


func _next_fish_wait() -> float:
	return fish_interval() * _rng.randf_range(0.85, 1.15)


func _check_end() -> void:
	if _state != STATE_CLIMB:
		return
	# Darto's grab is checked first: if both reach the top on the same tick,
	# the tap that got him there came first.
	if _height >= 1.0:
		_end(true)
	elif _fish_height >= 1.0:
		_end(false)


func _end(player_won: bool) -> void:
	_finish(player_won, {
		"taps": _taps, "same_side_slips": _same_side_slips, "grease_slips": _grease_slips,
		"fish_slips": _fish_slips, "height": snappedf(_height, 0.001), "fish_height": snappedf(_fish_height, 0.001),
	})


func _snapshot_rules() -> Dictionary:
	return {
		"height": _height,
		"fish_height": _fish_height,
		"grease": _grease,
		"stunned": _stun > 0.0,
		"expected_side": get_expected_side(),
		"time_left": maxf(_timer, 0.0) if _state == STATE_CLIMB else 0.0,
	}
