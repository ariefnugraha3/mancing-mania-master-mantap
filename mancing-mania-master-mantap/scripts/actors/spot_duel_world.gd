class_name SpotDuelWorld
extends Node3D
## Shared staging of the four spot duels (revision 6.7): the arena set, Darto
## and the fish on their marks, and the fixed diorama camera. Each duel's
## world adds its own moving pieces (the rope, the tops, the climbers).
##
## The world only shows what the duel's controller decided; it has no rules.

const BLEND_SEC := 0.08

@onready var _set: Node3D = $ArenaSet
@onready var _darto: Node3D = $DartoPose
@onready var _fish_anchor: Node3D = $FishPose
@onready var _camera: DioramaCamera = $DuelCamera

var _markers: Node3D
var _darto_rig: Node3D
var _darto_player: AnimationPlayer
var _fish: Node3D
var _fish_player: AnimationPlayer
var _darto_base: Transform3D
var _fish_base: Transform3D


func _ready() -> void:
	_markers = _set.get_node("Markers")
	_darto.transform = marker("DartoSpot").transform
	_fish_anchor.transform = marker("FishSpot").transform
	_darto_base = _darto.transform
	_fish_base = _fish_anchor.transform
	_darto_rig = _darto.get_node("Rig")
	_darto_player = _darto_rig.get_node("AnimationPlayer")
	_darto_player.play(_darto_idle())
	_camera.set_hud_insets(_hud_insets())
	_camera.frame_marker(marker("CameraFocus"))
	_build()


func setup(fish_id: StringName) -> void:
	if _fish != null:
		_fish_anchor.remove_child(_fish)
		_fish.queue_free()
	_fish = GameData.get_fish(fish_id).model_scene.instantiate()
	_fish.name = "Rig"
	_fish_anchor.add_child(_fish)
	var gloves := _fish.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = false
	_fish_player = _fish.get_node("AnimationPlayer")
	_fish_player.play(_fish_idle())
	_after_setup()


func marker(marker_name: String) -> Node3D:
	return _markers.get_node(marker_name) as Node3D


func has_marker(marker_name: String) -> bool:
	return _markers.has_node(marker_name)


func play_darto(clip: StringName, blend: float = BLEND_SEC) -> void:
	if _darto_player.has_animation(clip):
		_darto_player.play(clip, blend)


func play_fish(clip: StringName, blend: float = BLEND_SEC) -> void:
	if _fish_player != null and _fish_player.has_animation(clip):
		_fish_player.play(clip, blend)


## After a clip ends, go back to the idle loop.
func queue_idle() -> void:
	if _darto_player.has_animation(_darto_idle()):
		_darto_player.queue(_darto_idle())
	if _fish_player != null and _fish_player.has_animation(_fish_idle()):
		_fish_player.queue(_fish_idle())


func show_end(player_won: bool) -> void:
	if player_won:
		play_darto(&"dance_win")
		play_fish(_fish_lose())
		DioramaMotion.stretch(_darto_rig, 0.1)
	else:
		play_darto(&"dance_lose")
		play_fish(_fish_win())
		if _fish != null:
			DioramaMotion.stretch(_fish, 0.1)


func get_darto_clip() -> StringName:
	return StringName(_darto_player.current_animation)


func get_fish_clip() -> StringName:
	return StringName(_fish_player.current_animation) if _fish_player != null else &""


# --- For subclasses -----------------------------------------------------------

func _hud_insets() -> Vector2:
	return Vector2(110.0, 0.42)


func _darto_idle() -> StringName:
	return &"box_idle"


func _fish_idle() -> StringName:
	return &"box_idle"


func _fish_win() -> StringName:
	return &"dance_win"


func _fish_lose() -> StringName:
	return &"dance_lose"


func _build() -> void:
	pass


func _after_setup() -> void:
	pass


## A flat-coloured part for the moving props, in the diorama's material.
static func part(mesh: Mesh, tint: Color, node_name: String = "Part") -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = DioramaStyle.material(tint)
	return instance
