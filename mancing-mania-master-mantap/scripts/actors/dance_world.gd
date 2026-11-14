class_name DanceWorld
extends Node3D
## The stage (GDD 57, 168.9, 172.4, 172.6, 185.18): Darto and the fish dance
## side by side. Animation follows the judgments; it is never the timing
## source (GDD 172.4).

## HUD bars (top, bottom) in reference pixels, landscape then portrait. The
## note lanes take the bottom of the screen.
## HUD bars of the portrait screen: top in canvas points, bottom as a share
## of the screen height (the bottom sheet scales with it).
const HUD_INSETS := Vector2(64.0, 0.56)
const BLEND_SEC := 0.06
const IDLE_BPM := 120.0
const HIGH_COMBO := 20

@onready var _set: Node3D = $DanceSet
@onready var _darto: Node3D = $DartoDancer
@onready var _fish_anchor: Node3D = $FishDancer
@onready var _camera: DioramaCamera = $DanceCamera

var _darto_player: AnimationPlayer
var _fish_player: AnimationPlayer
var _fish: Node3D
var _tempo: float = 1.0
var _finished: bool = false
var _high_combo: bool = false


func _ready() -> void:
	var markers := _set.get_node("Markers")
	_darto.transform = (markers.get_node("DartoSpot") as Node3D).transform
	_fish_anchor.transform = (markers.get_node("FishSpot") as Node3D).transform
	_darto_player = _darto.get_node("Rig/AnimationPlayer")
	_darto_player.animation_finished.connect(_on_darto_finished)
	_darto_player.play(&"dance_idle_bounce")
	_camera.set_hud_insets(HUD_INSETS)
	_camera.frame_marker(markers.get_node("CameraFocus") as Node3D)


func setup(fish_id: StringName, bpm: float) -> void:
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
	_fish_player.animation_finished.connect(_on_fish_finished)
	# The idle loops are two beats at 120 BPM; play them in time with the song.
	_tempo = bpm / IDLE_BPM
	reset()


func reset() -> void:
	_finished = false
	_high_combo = false
	_darto_player.play(&"dance_idle_bounce", BLEND_SEC, _tempo)
	if _fish_player != null:
		_fish_player.play(&"dance_idle", BLEND_SEC, _tempo)


func show_player_note(judgment: StringName, lane: int, combo: int) -> void:
	if _finished:
		return
	_high_combo = combo >= HIGH_COMBO
	if judgment == DanceController.MISS:
		_darto_player.play(&"dance_miss", BLEND_SEC)
	else:
		_darto_player.play(StringName("dance_hit_lane_%d" % (lane + 1)), BLEND_SEC)


func show_fish_note(judgment: StringName) -> void:
	if _finished or _fish_player == null:
		return
	_fish_player.play(StringName("dance_%s" % judgment), BLEND_SEC)


func show_finish(player_won: bool) -> void:
	_finished = true
	_darto_player.play(&"dance_win" if player_won else &"dance_lose", BLEND_SEC * 2.0)
	_fish_player.play(&"dance_lose" if player_won else &"dance_win", BLEND_SEC * 2.0)
	DioramaMotion.stretch((_darto.get_node("Rig") as Node3D) if player_won else _fish, 0.12)


func get_darto_clip() -> StringName:
	return StringName(_darto_player.current_animation)


func get_fish_clip() -> StringName:
	return StringName(_fish_player.current_animation) if _fish_player != null else &""


func _on_darto_finished(_clip: StringName) -> void:
	if not _finished:
		_darto_player.play(&"dance_combo_high" if _high_combo else &"dance_idle_bounce", BLEND_SEC, _tempo)


func _on_fish_finished(_clip: StringName) -> void:
	if not _finished:
		_fish_player.play(&"dance_idle", BLEND_SEC, _tempo)

