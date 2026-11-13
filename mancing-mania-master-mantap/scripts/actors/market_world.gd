class_name MarketWorld
extends Node3D
## Everything you see at Bu Yati's warung (GDD 72, 168.5, 185.15): the set,
## Bu Yati behind her counter and Darto in front of it.
##
## The world has no rules. It stands the cast on the set's markers, picks the
## camera for the screen shape and lets Bu Yati react to what the player did.
## The camera is fixed: the Market is a place to do business, not to explore.

const CAMERA_FOV := 50.0
const BLEND_SEC := 0.18
const IDLE_CLIP := &"market_idle"
## The little counter fan turns the whole time (GDD 172.9).
const FAN_SPEED := 15.0
## Seconds between Bu Yati's small deadpan beats while nothing else happens.
const BEAT_GAP_SEC := Vector2(4.0, 9.0)

@onready var _set: Node3D = $MarketSet
@onready var _bu_yati: Node3D = $BuYati
@onready var _darto: Node3D = $DartoMarketPose
@onready var _camera: Camera3D = $MarketCamera

var _yati_player: AnimationPlayer
var _darto_player: AnimationPlayer
var _fan_blades: Node3D
var _queue: Array[StringName] = []
var _beat_left: float = 0.0


func _ready() -> void:
	var markers := _set.get_node("Markers")
	_bu_yati.transform = (markers.get_node("BuYatiSpot") as Node3D).transform
	_darto.transform = (markers.get_node("DartoSpot") as Node3D).transform

	_yati_player = _bu_yati.get_node("Rig/AnimationPlayer")
	_darto_player = _darto.get_node("Rig/AnimationPlayer")
	_yati_player.animation_finished.connect(_on_yati_clip_finished)
	_yati_player.play(IDLE_CLIP)
	_darto_player.play(IDLE_CLIP)
	_beat_left = RNGService.cosmetic.randf_range(BEAT_GAP_SEC.x, BEAT_GAP_SEC.y)
	_fan_blades = _set.get_node_or_null("Props/Fan/Blades")

	PlatformService.viewport_class_changed.connect(_apply_camera)
	_apply_camera(PlatformService.get_viewport_class())


func _process(delta: float) -> void:
	if _fan_blades != null:
		_fan_blades.rotate_object_local(Vector3.BACK, FAN_SPEED * delta)
	if _yati_player.current_animation != IDLE_CLIP:
		return
	_beat_left -= delta
	if _beat_left <= 0.0:
		_beat_left = RNGService.cosmetic.randf_range(BEAT_GAP_SEC.x, BEAT_GAP_SEC.y)
		_play_sequence([&"deadpan_blink"])


# --- Reactions --------------------------------------------------------------

## A sale: she weighs the catch, then counts out the money.
func react_sale() -> void:
	_play_sequence([&"weigh_fish", &"cash_count"])


## An upgrade bought: she counts what Darto handed over.
func react_purchase() -> void:
	_play_sequence([&"cash_count"])


## A debt payment: one look at Darto. That is the whole celebration.
func react_payment() -> void:
	_play_sequence([&"look_darto"])


## The clip Bu Yati is playing right now.
func get_bu_yati_clip() -> StringName:
	return StringName(_yati_player.current_animation)


# --- Internals --------------------------------------------------------------

func _play_sequence(clips: Array[StringName]) -> void:
	_queue = clips.duplicate()
	_play_next()


func _play_next() -> void:
	var clip: StringName = _queue.pop_front() if not _queue.is_empty() else IDLE_CLIP
	if not _yati_player.has_animation(clip):
		clip = IDLE_CLIP
	_yati_player.play(clip, BLEND_SEC)


func _on_yati_clip_finished(_clip: StringName) -> void:
	_play_next()


## The set carries one camera position per screen shape.
func _apply_camera(viewport_class: StringName) -> void:
	var marker_name := "CameraPortrait" if viewport_class == PlatformService.PORTRAIT else "CameraLandscape"
	_camera.transform = (_set.get_node("Markers/%s" % marker_name) as Node3D).transform
	_camera.fov = CAMERA_FOV
