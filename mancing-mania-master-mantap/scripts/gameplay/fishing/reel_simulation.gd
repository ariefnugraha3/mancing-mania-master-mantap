class_name ReelSimulation
extends RefCounted
## The tension minigame as plain numbers (GDD Sections 31-35).
##
## The player marker rises while the reel is held and falls when released.
## Holding inside the green zone lands the catch; holding outside it strains
## the line. Nothing here touches nodes, so the rules run identically in the
## game and in headless tests.

const RESULT_NONE := &""
const RESULT_LANDED := &"landed"
const RESULT_LINE_BREAK := &"line_break"
const LANDING_GOAL := 100.0
## How hard the zone steers toward its target, and how quickly it can change speed.
const ZONE_STEERING := 4.0
const ZONE_ACCELERATION := 6.0
## Stress bands for HUD feedback (GDD Section 36).
const STRESS_BANDS: Array[float] = [40.0, 70.0, 90.0]

var marker: float = 0.4
var marker_velocity: float = 0.0
var zone_center: float = 0.4
var zone_velocity: float = 0.0
var zone_half_width: float = 0.175
var landing: float = 0.0
var stress: float = 0.0

var _balance: FishingBalance
var _move_speed: float = 0.36
var _stress_rate: float = 32.0
var _is_boss: bool = false
var _rng := RandomNumberGenerator.new()
var _zone_target: float = 0.4
var _retarget_left: float = 0.0
var _feint_left: float = 0.0
var _feint_target: float = 0.4
## The spot's water (revision 6.7): a current that pushes the marker and waves
## that strain the line. Calm water leaves both at zero.
var _drift: float = 0.0
var _location: LocationData
var _clock: float = 0.0


func setup(fish: FishData, rod_level: int, seed: int) -> void:
	_balance = GameData.get_fishing_balance()
	_move_speed = fish.reel_move_speed
	_stress_rate = fish.line_stress_per_sec
	_is_boss = fish.tier >= 5
	zone_half_width = half_width_for(fish, rod_level)
	_rng.seed = seed
	marker = 0.4
	marker_velocity = 0.0
	zone_center = clampf(0.4, zone_half_width, 1.0 - zone_half_width)
	zone_velocity = 0.0
	_zone_target = zone_center
	_retarget_left = _next_retarget_delay()
	_feint_left = 0.0
	landing = 0.0
	stress = 0.0
	_clock = 0.0


## Applies the water of `location` (call after setup). Null means calm water.
func setup_water(location: LocationData) -> void:
	_location = location
	_drift = location.reel_drift if location != null else 0.0
	_clock = 0.0


## Extra line stress per second the waves add right now.
func get_wave_stress() -> float:
	return _location.wave_stress(_clock) if _location != null else 0.0


## Carbon Rod widens the zone additively, up to the clamp (GDD Section 32).
static func half_width_for(fish: FishData, rod_level: int) -> float:
	var balance := GameData.get_fishing_balance()
	var level := clampi(rod_level, 0, ContentIds.UPGRADE_MAX_LEVEL)
	return minf(fish.reel_half_width + balance.rod_half_width_per_level * float(level), balance.rod_half_width_max)


## Advances the minigame and reports whether it just ended.
func step(delta: float, held: bool) -> StringName:
	_clock += delta
	_step_marker(delta, held)
	_step_zone(delta)

	var inside := is_marker_in_zone()
	if inside:
		stress -= _balance.stress_recover_inside_per_sec * delta
		if held:
			landing += _balance.landing_gain_per_sec * delta
	elif held:
		stress += _stress_rate * delta
		landing -= _balance.landing_loss_outside_per_sec * delta
	else:
		stress -= _balance.stress_recover_release_per_sec * delta
	# Waves strain the line while it is held, whatever the zone says.
	if held:
		stress += get_wave_stress() * delta
	stress = maxf(stress, 0.0)
	landing = clampf(landing, 0.0, LANDING_GOAL)

	if stress >= _balance.stress_break_value:
		stress = _balance.stress_break_value
		return RESULT_LINE_BREAK
	if landing >= LANDING_GOAL:
		return RESULT_LANDED
	return RESULT_NONE


func is_marker_in_zone() -> bool:
	return absf(marker - zone_center) <= zone_half_width


## 0 calm, 1 light, 2 medium, 3 strong (GDD Section 36).
func get_stress_band() -> int:
	var band := 0
	for threshold: float in STRESS_BANDS:
		if stress >= threshold:
			band += 1
	return band


func get_landing_ratio() -> float:
	return landing / LANDING_GOAL


func get_stress_ratio() -> float:
	return stress / _balance.stress_break_value


func _step_marker(delta: float, held: bool) -> void:
	# The marker eases into its speed so control never feels twitchy.
	var target := _balance.marker_hold_velocity if held else _balance.marker_release_velocity
	var swing := _balance.marker_hold_velocity - _balance.marker_release_velocity
	marker_velocity = move_toward(marker_velocity, target, swing / maxf(_balance.input_ease_sec, 0.001) * delta)
	marker += (marker_velocity + _drift) * delta
	if marker <= 0.0 or marker >= 1.0:
		marker = clampf(marker, 0.0, 1.0)
		marker_velocity = 0.0


func _step_zone(delta: float) -> void:
	_retarget_left -= delta
	if _retarget_left <= 0.0:
		_retarget_left = _next_retarget_delay()
		_zone_target = _rng.randf_range(zone_half_width, 1.0 - zone_half_width)
		# Don Arowana sometimes starts the wrong way before committing.
		if _is_boss and _rng.randf() < _balance.boss_feint_probability:
			_feint_left = _balance.boss_feint_sec
			var away := -signf(_zone_target - zone_center)
			_feint_target = clampf(zone_center + away * 0.25, zone_half_width, 1.0 - zone_half_width)

	var target := _zone_target
	if _feint_left > 0.0:
		_feint_left -= delta
		target = _feint_target

	# Steer toward the target without ever exceeding the fish's speed: the zone
	# glides and never teleports.
	var wanted := clampf((target - zone_center) * ZONE_STEERING, -_move_speed, _move_speed)
	zone_velocity = move_toward(zone_velocity, wanted, _move_speed * ZONE_ACCELERATION * delta)
	zone_center = clampf(zone_center + zone_velocity * delta, zone_half_width, 1.0 - zone_half_width)


func _next_retarget_delay() -> float:
	return _rng.randf_range(_balance.zone_retarget_min_sec, _balance.zone_retarget_max_sec)
