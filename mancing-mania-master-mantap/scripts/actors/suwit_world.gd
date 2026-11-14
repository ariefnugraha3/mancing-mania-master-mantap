class_name SuwitWorld
extends Node3D
## The Suwit table (GDD 64, 168.10, 172.5, 185.19): Darto and the fish face
## each other across a small round table under one warm lamp.

const FOV_LANDSCAPE := 45.0
const FOV_PORTRAIT := 58.0
const BLEND_SEC := 0.08
const FISH_SCALE := 1.3

@onready var _set: Node3D = $SuwitSet
@onready var _darto: Node3D = $DartoSuwitPose
@onready var _fish_anchor: Node3D = $FishSuwitPose
@onready var _camera: Camera3D = $SuwitCamera

var _darto_player: AnimationPlayer
var _fish_player: AnimationPlayer
var _fish: Node3D


func _ready() -> void:
	var markers := _set.get_node("Markers")
	_darto.transform = (markers.get_node("DartoSpot") as Node3D).transform
	_fish_anchor.transform = (markers.get_node("FishSpot") as Node3D).transform.scaled_local(Vector3.ONE * FISH_SCALE)
	_darto_player = _darto.get_node("Rig/AnimationPlayer")
	_darto_player.play(&"suwit_ready")
	PlatformService.viewport_class_changed.connect(_apply_camera)
	_apply_camera(PlatformService.get_viewport_class())


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
		SuwitController.OUTCOME_LOSS:
			_darto_player.play(&"suwit_lose", BLEND_SEC)
			_fish_player.play(&"suwit_win", BLEND_SEC)
		_:
			_darto_player.play(&"suwit_draw", BLEND_SEC)
			_fish_player.play(&"suwit_draw", BLEND_SEC)


func get_fish_clip() -> StringName:
	return StringName(_fish_player.current_animation) if _fish_player != null else &""


func _apply_camera(viewport_class: StringName) -> void:
	var portrait := viewport_class == PlatformService.PORTRAIT
	_camera.transform = (_set.get_node("Markers/%s" % ("CameraPortrait" if portrait else "CameraLandscape")) as Node3D).transform
	_camera.fov = FOV_PORTRAIT if portrait else FOV_LANDSCAPE
