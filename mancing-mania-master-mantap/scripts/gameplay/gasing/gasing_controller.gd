class_name GasingController
extends DuelControllerBase
## Spinning Tops (revision 6.7, Anggrek Estuary): a throw, then timed clashes.
##
## The throw: an aim needle swings left and right; one tap locks it. Then a
## power bar fills and empties; a second tap locks it. A straight, strong
## throw gives the most spin. The fish throws by its skill.
##
## The clashes: both tops slowly lose spin. Every so often they collide; a
## ring closes in on the player's top and a tap as it closes lands a hit on
## the fish's top. A perfect tap hits hardest. A tap too early or no tap at
## all lets the fish's top hit instead. The last top spinning wins.

signal thrown(player_spin: float, fish_spin: float)
signal ring_started()
signal clash_resolved(outcome: Dictionary)

const DUEL_ID := &"gasing"

const STATE_AIM := &"aim"
const STATE_POWER := &"power"
const STATE_LAUNCH := &"launch"
const STATE_SPIN := &"spin"

const HIT_PERFECT := &"perfect"
const HIT_GOOD := &"good"
const HIT_MISS := &"miss"
const HIT_EARLY := &"early"

## Radians per second of the aim needle (it moves as sin(phase)).
const AIM_RATE := 4.2
## Bar lengths per second of the power bar.
const POWER_RATE := 1.4
## A throw is locked by itself after this long, so the duel never stalls.
const AUTO_LOCK_SEC := 3.5
const LAUNCH_SEC := 1.2
const SPIN_MIN := 55.0
const SPIN_RANGE := 45.0
const DECAY_PER_SEC := 2.5
const RING_GAP_SEC := 0.8
const GOOD_WINDOW := 0.22
const PERFECT_WINDOW := 0.09
const PERFECT_DAMAGE := 14.0
const GOOD_DAMAGE := 8.0
const GOOD_RECOIL := 4.0
const PERFECT_RECOIL := 1.0
const MISS_RECOIL := 2.0
const TIME_LIMIT_SEC := 60.0

var _aim_phase: float = 0.0
var _power_travel: float = 0.0
var _aim: float = 0.0
var _power: float = 0.0
var _player_spin: float = 0.0
var _fish_spin: float = 0.0
var _ring_sec: float = 1.0
## Seconds until the tops collide; negative while the late window runs.
var _impact_in: float = 0.0
var _ring_active: bool = false
var _gap: float = 0.0
var _spin_time: float = 0.0
var _clashes: int = 0
var _perfects: int = 0
var _goods: int = 0
var _misses: int = 0
var _last: Dictionary = {}


func get_duel_id() -> StringName:
	return DUEL_ID


## How long the ring takes to close: 1.1 s for the weakest fish, 0.75 s for
## the strongest.
func ring_sec() -> float:
	return lerpf(1.1, 0.75, skill())


## Spin the fish's top loses when it lands a hit.
func fish_hit() -> float:
	return lerpf(7.0, 13.0, skill())


## The aim needle, -1 (far left) to 1 (far right); 0 is straight.
func get_aim() -> float:
	return sin(_aim_phase) if _state == STATE_AIM else _aim


func get_power() -> float:
	return ping_pong01(_power_travel) if _state == STATE_POWER else _power


## Spin from a throw: half from a straight aim, half from power.
static func throw_spin(aim: float, power: float) -> float:
	var quality := 0.5 * (1.0 - clampf(absf(aim), 0.0, 1.0)) + 0.5 * clampf(power, 0.0, 1.0)
	return SPIN_MIN + SPIN_RANGE * quality


## The one button: locks the aim, then the power, then hits in the clashes.
func tap() -> void:
	match _state:
		STATE_AIM:
			_lock_aim()
		STATE_POWER:
			_lock_power()
		STATE_SPIN:
			if _ring_active:
				var error := absf(_impact_in)
				if error <= PERFECT_WINDOW:
					_resolve_clash(HIT_PERFECT)
				elif error <= GOOD_WINDOW:
					_resolve_clash(HIT_GOOD)
				else:
					_resolve_clash(HIT_EARLY)


## Seconds until impact while a ring closes, else a large number.
func get_impact_in() -> float:
	return _impact_in if _ring_active else INF


# --- Rules ----------------------------------------------------------------------

func _begin() -> void:
	_aim_phase = _rng.randf_range(0.0, TAU)
	_power_travel = 0.0
	_aim = 0.0
	_power = 0.0
	_player_spin = 0.0
	_fish_spin = 0.0
	_ring_sec = ring_sec()
	_ring_active = false
	_spin_time = 0.0
	_clashes = 0
	_perfects = 0
	_goods = 0
	_misses = 0
	_last = {}


func _after_intro() -> void:
	_state = STATE_AIM
	_timer = AUTO_LOCK_SEC


func _tick_rules(dt: float) -> void:
	match _state:
		STATE_AIM:
			_aim_phase += AIM_RATE * dt
			_timer -= dt
			if _timer <= 0.0:
				_lock_aim()
		STATE_POWER:
			_power_travel += POWER_RATE * dt
			_timer -= dt
			if _timer <= 0.0:
				_lock_power()
		STATE_LAUNCH:
			_timer -= dt
			if _timer <= 0.0:
				_state = STATE_SPIN
				_gap = RING_GAP_SEC
		STATE_SPIN:
			_tick_spin(dt)


func _lock_aim() -> void:
	_aim = sin(_aim_phase)
	_state = STATE_POWER
	_timer = AUTO_LOCK_SEC


func _lock_power() -> void:
	_power = ping_pong01(_power_travel)
	_player_spin = throw_spin(_aim, _power)
	var fish_quality := clampf(lerpf(0.5, 0.9, skill()) + _rng.randf_range(-0.06, 0.06), 0.0, 1.0)
	_fish_spin = SPIN_MIN + SPIN_RANGE * fish_quality
	_state = STATE_LAUNCH
	_timer = LAUNCH_SEC
	thrown.emit(_player_spin, _fish_spin)


func _tick_spin(dt: float) -> void:
	_spin_time += dt
	_player_spin -= DECAY_PER_SEC * dt
	_fish_spin -= DECAY_PER_SEC * dt
	if _ring_active:
		_impact_in -= dt
		if _impact_in < -GOOD_WINDOW:
			_resolve_clash(HIT_MISS)
	else:
		_gap -= dt
		if _gap <= 0.0:
			_ring_active = true
			_impact_in = _ring_sec
			ring_started.emit()
	_check_end()
	if _state == STATE_SPIN and _spin_time >= TIME_LIMIT_SEC:
		_end(_player_spin > _fish_spin)


func _resolve_clash(hit: StringName) -> void:
	_ring_active = false
	_gap = RING_GAP_SEC
	_clashes += 1
	match hit:
		HIT_PERFECT:
			_fish_spin -= PERFECT_DAMAGE
			_player_spin -= PERFECT_RECOIL
			_perfects += 1
		HIT_GOOD:
			_fish_spin -= GOOD_DAMAGE
			_player_spin -= GOOD_RECOIL
			_goods += 1
		_:
			_player_spin -= fish_hit()
			_fish_spin -= MISS_RECOIL
			_misses += 1
	_last = {"clash": _clashes, "hit": hit, "player_spin": _player_spin, "fish_spin": _fish_spin}
	clash_resolved.emit(_last.duplicate())
	_check_end()


func _check_end() -> void:
	if _state != STATE_SPIN:
		return
	if _player_spin <= 0.0 or _fish_spin <= 0.0:
		_end(_player_spin > _fish_spin)


func _end(player_won: bool) -> void:
	_ring_active = false
	_finish(player_won, {
		"aim": snappedf(_aim, 0.001), "power": snappedf(_power, 0.001), "clashes": _clashes,
		"perfect_hits": _perfects, "good_hits": _goods, "misses": _misses,
		"player_spin": snappedf(maxf(_player_spin, 0.0), 0.01), "fish_spin": snappedf(maxf(_fish_spin, 0.0), 0.01),
	})


func _snapshot_rules() -> Dictionary:
	return {
		"aim": get_aim(),
		"power": get_power(),
		"lock_left": maxf(_timer, 0.0) if _state == STATE_AIM or _state == STATE_POWER else 0.0,
		"player_spin": maxf(_player_spin, 0.0),
		"fish_spin": maxf(_fish_spin, 0.0),
		"spin_max": SPIN_MIN + SPIN_RANGE,
		"ring_active": _ring_active,
		"ring": clampf(_impact_in / _ring_sec, 0.0, 1.0) if _ring_active else 0.0,
		"impact_in": _impact_in if _ring_active else 0.0,
		"last_clash": _last.duplicate(),
	}
