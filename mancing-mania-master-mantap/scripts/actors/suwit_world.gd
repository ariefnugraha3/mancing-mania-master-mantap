class_name SuwitWorld
extends Node3D
## The Suwit table (GDD 64, 168.10, 172.5, 185.19): Darto and the fish face
## each other across a small round table on a little deck under one warm lamp.

## HUD bars (top, bottom) in reference pixels, landscape then portrait.
## HUD bars of the portrait screen (top, bottom) in canvas points.
const HUD_INSETS := Vector2(110.0, 190.0)
const BLEND_SEC := 0.08

@onready var _set: Node3D = $SuwitSet
@onready var _darto: Node3D = $DartoSuwitPose
@onready var _fish_anchor: Node3D = $FishSuwitPose
@onready var _camera: DioramaCamera = $SuwitCamera

var _darto_player: AnimationPlayer
var _fish_player: AnimationPlayer
var _fish: Node3D


func _ready() -> void:
	var markers := _set.get_node("Markers")
	_darto.transform = (markers.get_node("DartoSpot") as Node3D).transform
	_fish_anchor.transform = (markers.get_node("FishSpot") as Node3D).transform
	_darto_player = _darto.get_node("Rig/AnimationPlayer")
	_darto_player.play(&"suwit_ready")
	_camera.set_hud_insets(HUD_INSETS)
	_camera.frame_marker(markers.get_node("CameraFocus") as Node3D)


func setup(fish_id: StringName) -> void:
	_fish = GameData.get_fish(fish_id).model_scene.instantiate()
	_fish.name = "Rig"
	_fish_anchor.add_child(_fish)
	var gloves := _fish.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = false
	_fish_player = _fish.get_node("AnimationPlayer")
	_fish_player.play(&"suwit_ready")


func show_round_start() -> void:
	_darto_player.play(&"suwit_ready", BLEND_SEC)
	_fish_player.play(&"suwit_ready", BLEND_SEC)


func show_tell(truthful: bool) -> void:
	_fish_player.play(&"suwit_tell_true" if truthful else &"suwit_tell_fake", BLEND_SEC)


func show_reveal(outcome: Dictionary) -> void:
	_darto_player.play(StringName("suwit_%s" % outcome["player"]), BLEND_SEC)
	_fish_player.play(&"suwit_reveal", BLEND_SEC)
	await get_tree().create_timer(0.5).timeout
	if not is_inside_tree():
		return
	match outcome["outcome"]:
		SuwitController.OUTCOME_WIN:
			_darto_player.play(&"suwit_win", BLEND_SEC)
			_fish_player.play(&"suwit_lose", BLEND_SEC)
			DioramaMotion.stretch(_darto.get_node("Rig") as Node3D, 0.1)
		SuwitController.OUTCOME_LOSS:
			_darto_player.play(&"suwit_lose", BLEND_SEC)
			_fish_player.play(&"suwit_win", BLEND_SEC)
			DioramaMotion.stretch(_fish, 0.1)
		_:
			_darto_player.play(&"suwit_draw", BLEND_SEC)
			_fish_player.play(&"suwit_draw", BLEND_SEC)


func get_fish_clip() -> StringName:
	return StringName(_fish_player.current_animation) if _fish_player != null else &""

