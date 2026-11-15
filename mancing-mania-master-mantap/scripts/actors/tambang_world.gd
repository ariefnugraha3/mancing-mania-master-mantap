class_name TambangWorld
extends SpotDuelWorld
## The Tug of War field (revision 6.7): a grassy bank by the reservoir with
## a chalk line on each side. Darto and the fish hold the two ends of a thick
## rope with a red flag tied in the middle. The whole tug slides toward
## whoever is winning, so the flag shows the match at a glance.

## How far the tug slides at the ends of the rope range, in metres.
const SLIDE := 0.42
const FOLLOW := 10.0
const ROPE_RADIUS := 0.022
const HAND_HEIGHT := 0.42

var _across: Vector3 = Vector3.RIGHT
var _rope: MeshInstance3D
var _flag: Node3D
var _shown: float = 0.0
var _target: float = 0.0


func _hud_insets() -> Vector2:
	return Vector2(110.0, 0.46)


func _darto_idle() -> StringName:
	return &"arm_idle_grip"


func _fish_idle() -> StringName:
	return &"arm_idle"


func _fish_win() -> StringName:
	return &"arm_win"


func _fish_lose() -> StringName:
	return &"arm_lose"


func _build() -> void:
	_across = (_fish_base.origin - _darto_base.origin).slide(Vector3.UP).normalized()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = ROPE_RADIUS
	cylinder.bottom_radius = ROPE_RADIUS
	cylinder.height = 1.0
	cylinder.radial_segments = 10
	cylinder.rings = 1
	_rope = part(cylinder, DioramaStyle.CARAMEL, "Rope")
	add_child(_rope)
	_flag = Node3D.new()
	_flag.name = "Flag"
	add_child(_flag)
	var cloth := BoxMesh.new()
	cloth.size = Vector3(0.012, 0.11, 0.13)
	var cloth_part := part(cloth, UiTokens.RED_500, "Cloth")
	cloth_part.position = Vector3(0.0, -0.07, 0.0)
	_flag.add_child(cloth_part)
	var knot := SphereMesh.new()
	knot.radius = 0.04
	knot.height = 0.07
	_flag.add_child(part(knot, UiTokens.RED_500.darkened(0.15), "Knot"))
	_place_rope()


func _process(delta: float) -> void:
	_shown = lerpf(_shown, _target, minf(delta * FOLLOW, 1.0))
	var offset := -_across * _shown * SLIDE
	_darto.position = _darto_base.origin + offset
	_fish_anchor.position = _fish_base.origin + offset
	_place_rope()


## `rope` is the match, -1 (fish's line) to 1 (Darto's line).
func set_rope(rope: float) -> void:
	_target = clampf(rope, -1.0, 1.0)


func show_pull(perfect: bool) -> void:
	play_darto(&"arm_push_hard" if perfect else &"arm_push_light", 0.04)
	_darto_player.queue(_darto_idle())
	play_fish(&"arm_idle", 0.1)
	if _fish != null:
		DioramaMotion.squash(_fish, 0.05)


func show_slip() -> void:
	play_darto(&"arm_recover", 0.04)
	_darto_player.queue(_darto_idle())
	DioramaMotion.squash(_darto_rig, 0.1)


func show_heave() -> void:
	play_fish(&"arm_burst", 0.05)
	if _fish != null:
		_fish_player.queue(_fish_idle())
		DioramaMotion.stretch(_fish, 0.08)


func show_end(player_won: bool) -> void:
	_target = 1.0 if player_won else -1.0
	play_darto(&"arm_win" if player_won else &"arm_lose")
	play_fish(_fish_lose() if player_won else _fish_win())


func get_shown_rope() -> float:
	return _shown


func _place_rope() -> void:
	if _rope == null:
		return
	var from := _darto.position + Vector3.UP * HAND_HEIGHT + _across * 0.18
	var to := _fish_anchor.position + Vector3.UP * HAND_HEIGHT - _across * 0.12
	var length := from.distance_to(to)
	var middle := (from + to) * 0.5
	var direction := (to - from).normalized()
	var basis := Basis(Quaternion(Vector3.UP, direction))
	_rope.transform = Transform3D(basis * Basis.from_scale(Vector3(1.0, length, 1.0)), middle)
	_flag.position = middle
	_flag.rotation.y = atan2(-direction.z, direction.x)
