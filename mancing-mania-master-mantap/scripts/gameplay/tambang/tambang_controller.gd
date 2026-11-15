class_name TambangController
extends DuelControllerBase
## Tug of War (revision 6.7, Melati Reservoir): a timing duel.
##
## The rope's flag sits between Darto's line (+1) and the fish's line (-1).
## The fish pulls all the time and now and then heaves, with a warning first.
## A marker swings across a bar; PULL inside the green zone drags the rope
## toward Darto, a pull in the zone's centre drags it further. Pulling outside
## the zone is a slip: the rope gives a little and Darto needs a moment to get
## his grip back. One pull counts per pass of the marker through the zone, so
## mashing does not help. Whoever drags the flag over their line wins; when
## time runs out, the side the flag is on wins.

signal pulled(quality: StringName)
signal slipped()
signal heave_warned()
signal heave_started()

const DUEL_ID := &"tambang"

const STATE_PULL := &"pull"

const QUALITY_PERFECT := &"perfect"
const QUALITY_GOOD := &"good"

const ZONE_CENTRE := 0.5
const GOOD_PULL := 0.13
const PERFECT_PULL := 0.19
## The share of the zone's half width that counts as its centre.
const PERFECT_SHARE := 0.35
const SLIP_GIVE := 0.04
const SLIP_STUN_SEC := 0.4
const HEAVE_WARNING_SEC := 0.7
const HEAVE_SEC := 0.5
const HEAVE_PULL := 0.16
const TIME_LIMIT_SEC := 45.0

var _rope: float = 0.0
var _marker_travel: float = 0.0
var _marker_speed: float = 1.6
var _zone_half: float = 0.12
var _fish_pull: float = 0.08
var _stun: float = 0.0
var _zone_spent: bool = false
var _heave_in: float = 0.0
var _heave_left: float = 0.0
var _warned: bool = false
var _pulls: int = 0
var _perfects: int = 0
var _slips: int = 0
var _heaves: int = 0


func get_duel_id() -> StringName:
	return DUEL_ID


## Bar widths per second the marker travels: 1.3 for the weakest fish, 2.3
## for the strongest.
func marker_speed() -> float:
	return lerpf(1.3, 2.3, skill())


## Half the green zone's width on the 0..1 bar.
func zone_half_width() -> float:
	return lerpf(0.15, 0.09, skill())


## How far the fish drags the rope per second without heaving.
func fish_pull_per_sec() -> float:
	return lerpf(0.04, 0.12, skill())


func get_marker() -> float:
	return ping_pong01(_marker_travel)


func is_marker_in_zone() -> bool:
	return absf(get_marker() - ZONE_CENTRE) <= _zone_half


## PULL. Returns the quality (&"perfect", &"good"), &"slip" or &"" when the
## press did nothing (not running, still recovering, or the pass was used).
func pull() -> StringName:
	if _state != STATE_PULL or _stun > 0.0:
		return &""
	var offset := absf(get_marker() - ZONE_CENTRE)
	if offset <= _zone_half:
		if _zone_spent:
			return &""
		_zone_spent = true
		var perfect := offset <= _zone_half * PERFECT_SHARE
		_rope += PERFECT_PULL if perfect else GOOD_PULL
		_pulls += 1
		_perfects += 1 if perfect else 0
		var quality := QUALITY_PERFECT if perfect else QUALITY_GOOD
		pulled.emit(quality)
		_check_end()
		return quality
	_rope -= SLIP_GIVE
	_stun = SLIP_STUN_SEC
	_slips += 1
	slipped.emit()
	_check_end()
	return &"slip"


# --- Rules ----------------------------------------------------------------------

func _begin() -> void:
	_rope = 0.0
	_marker_travel = 0.0
	_marker_speed = marker_speed()
	_zone_half = zone_half_width()
	_fish_pull = fish_pull_per_sec()
	_stun = 0.0
	_zone_spent = false
	_heave_left = 0.0
	_warned = false
	_heave_in = _next_heave_gap()
	_pulls = 0
	_perfects = 0
	_slips = 0
	_heaves = 0


func _after_intro() -> void:
	_state = STATE_PULL
	_timer = TIME_LIMIT_SEC


func _tick_rules(dt: float) -> void:
	_timer -= dt
	_stun = maxf(_stun - dt, 0.0)
	_marker_travel += _marker_speed * dt
	if not is_marker_in_zone():
		_zone_spent = false
	var pull := _fish_pull
	if _heave_left > 0.0:
		_heave_left -= dt
		pull += HEAVE_PULL / HEAVE_SEC
	else:
		_heave_in -= dt
		if not _warned and _heave_in <= HEAVE_WARNING_SEC:
			_warned = true
			heave_warned.emit()
		if _heave_in <= 0.0:
			_heave_left = HEAVE_SEC
			_heaves += 1
			_warned = false
			_heave_in = _next_heave_gap()
			heave_started.emit()
	_rope -= pull * dt
	_check_end()
	if _state == STATE_PULL and _timer <= 0.0:
		_end(_rope > 0.0)


func _next_heave_gap() -> float:
	return _rng.randf_range(2.6, 4.2) - skill() * 0.6


func _check_end() -> void:
	if _state != STATE_PULL:
		return
	if _rope >= 1.0:
		_end(true)
	elif _rope <= -1.0:
		_end(false)


func _end(player_won: bool) -> void:
	_rope = clampf(_rope, -1.0, 1.0)
	_finish(player_won, {
		"pulls": _pulls, "perfect_pulls": _perfects, "slips": _slips, "heaves": _heaves,
		"rope": snappedf(_rope, 0.001), "timed_out": _timer <= 0.0,
	})


func _snapshot_rules() -> Dictionary:
	return {
		"rope": _rope,
		"marker": get_marker(),
		"zone_centre": ZONE_CENTRE,
		"zone_half": _zone_half,
		"in_zone": is_marker_in_zone(),
		"zone_spent": _zone_spent,
		"stunned": _stun > 0.0,
		"heave_warning": _warned and _heave_left <= 0.0,
		"heaving": _heave_left > 0.0,
		"time_left": maxf(_timer, 0.0) if _state == STATE_PULL else 0.0,
	}
