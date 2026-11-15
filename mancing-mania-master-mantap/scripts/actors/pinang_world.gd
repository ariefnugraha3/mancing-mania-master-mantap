class_name PinangWorld
extends SpotDuelWorld
## The Greased Pole (revision 6.7): two tall greased poles on the pier with
## prizes hanging from a ring at the top. Darto climbs the left one and the
## fish the right one; each rises with its height in the race and slides
## when it slips.

const DEFAULT_CLIMB := 1.35
const FOLLOW := 12.0

var _climb: float = DEFAULT_CLIMB
var _shown: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _grab_toggle: bool = false


func _hud_insets() -> Vector2:
	return Vector2(110.0, 0.30)


func _darto_idle() -> StringName:
	return &"arm_idle_grip"


func _fish_idle() -> StringName:
	return &"arm_idle"


func _build() -> void:
	if has_marker("DartoSpot") and marker("DartoSpot").has_meta(&"climb_height"):
		_climb = float(marker("DartoSpot").get_meta(&"climb_height"))


func _process(delta: float) -> void:
	_shown = _shown.lerp(_target, minf(delta * FOLLOW, 1.0))
	_darto.position = _darto_base.origin + Vector3.UP * _shown.x * _climb
	_fish_anchor.position = _fish_base.origin + Vector3.UP * _shown.y * _climb


func set_heights(player_height: float, fish_height: float) -> void:
	_target = Vector2(clampf(player_height, 0.0, 1.0), clampf(fish_height, 0.0, 1.0))


func show_climb() -> void:
	_grab_toggle = not _grab_toggle
	play_darto(&"arm_push_light" if _grab_toggle else &"arm_recover", 0.03)


func show_slip() -> void:
	play_darto(&"line_stress_jerk", 0.04)
	_darto_player.queue(_darto_idle())
	DioramaMotion.squash(_darto_rig, 0.14)


func show_fish_climb() -> void:
	if _fish != null and get_fish_clip() != _fish_idle():
		play_fish(_fish_idle(), 0.05)


func show_fish_slip() -> void:
	play_fish(&"dance_miss", 0.04)
	if _fish != null:
		_fish_player.queue(_fish_idle())
		DioramaMotion.squash(_fish, 0.14)


func get_shown_heights() -> Vector2:
	return _shown
