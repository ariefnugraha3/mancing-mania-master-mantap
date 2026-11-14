class_name BoxingWorld
extends Node3D
## Everything you see in the ring (GDD 41-49, 168.7, 172.2, 172.6, 185.16):
## Darto in the near half with his back to the diorama camera, the fish on its
## low stool in the far half facing him, and the hits between them.
##
## The world only shows what BoxingController decided. The fish's wind-up is
## its attack clip played at exactly the speed that fills the telegraph time,
## so what the player sees is what the rules are counting down. An attack
## animation is never interrupted before its impact: an unreadable attack
## would break the one promise this duel makes (GDD 176.14).

## HUD bars (top, bottom) in reference pixels, landscape then portrait.
## HUD bars of the portrait screen (top, bottom) in canvas points.
const HUD_INSETS := Vector2(170.0, 230.0)
const BLEND_SEC := 0.06
const IDLE_CLIP := &"box_idle"
const MIRROR_SUFFIX := "_mirror"
const ATTACK_VARIANTS: Array[String] = ["a", "b", "c"]
## Normalized time of the impact inside every fish attack clip.
const ATTACK_IMPACT_TIME := 1.0
const SPARK_SEC := 0.16
## Head and chest heights of the chibi fighters, for the hit sparks.
const DARTO_HEAD_Y := 0.7
const FISH_CHEST_Y := 0.42

@onready var _set: Node3D = $BoxingSet
@onready var _darto: Node3D = $DartoFighter
@onready var _fish_anchor: Node3D = $FishFighter
@onready var _camera: DioramaCamera = $BoxingCamera

var _darto_player: AnimationPlayer
var _fish_player: AnimationPlayer
var _fish: Node3D
var _telegraphing: bool = false
var _holding_dodge: bool = false
var _finished: bool = false
var _freeze_left: float = 0.0
var _sparks: Array[MeshInstance3D] = []
var _spark_ages: Array[float] = []


func _ready() -> void:
	var markers := _set.get_node("Markers")
	_darto.transform = (markers.get_node("DartoSpot") as Node3D).transform
	_fish_anchor.transform = (markers.get_node("FishSpot") as Node3D).transform

	var gloves := _darto.get_node_or_null("Rig/AccessoryMeshes/BoxingGloves") as Node3D
	if gloves != null:
		gloves.visible = true
	_darto_player = _darto.get_node("Rig/AnimationPlayer")
	_darto_player.animation_finished.connect(_on_darto_clip_finished)
	_darto_player.play(IDLE_CLIP)

	for index: int in 3:
		_sparks.append(_make_spark())
		_spark_ages.append(SPARK_SEC)
	_camera.set_hud_insets(HUD_INSETS)
	_camera.frame_marker(markers.get_node("CameraFocus") as Node3D)


func _process(delta: float) -> void:
	if _freeze_left > 0.0:
		_freeze_left -= delta
		if _freeze_left <= 0.0:
			_set_speed(1.0)
	# A dodge that answers a telegraph leans out and waits there for the punch.
	if _holding_dodge and _darto_player.is_playing() and _darto_player.current_animation_position >= _lean_peak():
		_darto_player.pause()
	for index: int in _sparks.size():
		if _spark_ages[index] >= SPARK_SEC:
			continue
		_spark_ages[index] += delta
		var progress := clampf(_spark_ages[index] / SPARK_SEC, 0.0, 1.0)
		_sparks[index].scale = Vector3.ONE * lerpf(0.5, 1.5, progress)
		var material := _sparks[index].material_override as StandardMaterial3D
		material.albedo_color.a = 1.0 - progress
		_sparks[index].visible = progress < 1.0


# --- Set up -----------------------------------------------------------------

## Puts `fish_id` on the stool, gloves on, in its guard.
func setup(fish_id: StringName) -> void:
	if _fish != null:
		_fish_anchor.remove_child(_fish)
		_fish.queue_free()
	_fish = GameData.get_fish(fish_id).model_scene.instantiate()
	_fish.name = "Rig"
	_fish_anchor.add_child(_fish)
	var gloves := _fish.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = true
	_fish_player = _fish.get_node("AnimationPlayer")
	_fish_player.animation_finished.connect(_on_fish_clip_finished)
	reset()


## Both fighters back in their guard, e.g. before a tutorial retry.
func reset() -> void:
	_finished = false
	_telegraphing = false
	_holding_dodge = false
	_freeze_left = 0.0
	_set_speed(1.0)
	_darto_player.play(IDLE_CLIP)
	if _fish_player != null:
		_fish_player.play(IDLE_CLIP)


# --- Called by the boxing scene ---------------------------------------------

## The fish winds up. The clip's telegraph part lasts exactly `telegraph_sec`.
func show_telegraph(direction: StringName, variant: int, telegraph_sec: float) -> void:
	_telegraphing = true
	_fish_player.play(get_attack_clip(direction, variant), BLEND_SEC, ATTACK_IMPACT_TIME / maxf(telegraph_sec, 0.05))


## The punch arrives: it either lands on Darto or sails past him.
func show_impact(outcome: StringName, direction: StringName) -> void:
	_telegraphing = false
	_holding_dodge = false
	# From the impact on the clip runs at normal speed, from the exact pose.
	if _fish_player.current_animation.begins_with("box_attack"):
		_fish_player.play(_fish_player.current_animation, -1.0, 1.0)
		_fish_player.seek(ATTACK_IMPACT_TIME, true)
	if outcome == BoxingController.OUTCOME_HIT:
		_darto_player.play(&"box_hit_left" if direction == BoxingController.DIRECTION_LEFT else &"box_hit_right", BLEND_SEC)
		_spark(_darto.global_position + Vector3(0, DARTO_HEAD_Y, 0), UiTokens.RED_500)
		DioramaMotion.squash(_darto.get_node("Rig") as Node3D, 0.1)
		return
	# Dodged: Darto finishes the lean he was holding.
	if _darto_player.current_animation.begins_with("box_dodge"):
		_darto_player.play()
	if outcome == BoxingController.OUTCOME_PERFECT:
		_freeze(GameData.get_boxing_config().perfect_freeze_sec)
		_spark(_darto.global_position + Vector3(0, DARTO_HEAD_Y + 0.08, 0), UiTokens.SUN_500)


func show_dodge(direction: StringName, answering: bool) -> void:
	_holding_dodge = answering
	_darto_player.play(&"box_dodge_left" if direction == BoxingController.DIRECTION_LEFT else &"box_dodge_right", BLEND_SEC)


func show_player_attack(attack_id: StringName) -> void:
	_darto_player.play(&"box_jab" if attack_id == BoxingController.ATTACK_JAB else &"box_cross", BLEND_SEC)


## Darto's punch arrived. A blocked punch never interrupts a wind-up.
func show_player_hit(blocked: bool) -> void:
	_spark(_fish_anchor.global_position + Vector3(0, FISH_CHEST_Y, 0), UiTokens.CREAM_50 if blocked else UiTokens.SUN_500)
	if _telegraphing or _finished:
		return
	_fish_player.play(&"box_block" if blocked else &"box_hit", BLEND_SEC)
	if not blocked:
		DioramaMotion.squash(_fish, 0.12)


## The fight is over: the loser goes down, the winner barely celebrates.
func show_finish(player_won: bool) -> void:
	_finished = true
	_telegraphing = false
	_holding_dodge = false
	_freeze_left = 0.0
	_set_speed(1.0)
	if player_won:
		_fish_player.play(&"box_ko", BLEND_SEC)
		_darto_player.play(&"box_win", BLEND_SEC * 2.0)
		DioramaMotion.stretch(_darto.get_node("Rig") as Node3D, 0.1)
	else:
		_darto_player.play(&"box_ko", BLEND_SEC)
		_fish_player.play(IDLE_CLIP, BLEND_SEC * 2.0)


# --- Read by tests and the debug overlay ------------------------------------

func get_fish_clip() -> StringName:
	return StringName(_fish_player.current_animation) if _fish_player != null else &""


func get_darto_clip() -> StringName:
	return StringName(_darto_player.current_animation)


func get_fish_rig() -> Node3D:
	return _fish


## The clip for an attack. The plain clip is the "dodge left" attack and the
## mirrored one is "dodge right".
static func get_attack_clip(direction: StringName, variant: int) -> StringName:
	var letter := ATTACK_VARIANTS[clampi(variant, 0, ATTACK_VARIANTS.size() - 1)]
	var suffix := "" if direction == BoxingController.DIRECTION_LEFT else MIRROR_SUFFIX
	return StringName("box_attack_%s%s" % [letter, suffix])


## A flat fan facing +Z, opaque in the middle and clear at the rim.
static func burst_disc(radius: float, segments: int) -> ArrayMesh:
	var vertices := PackedVector3Array([Vector3.ZERO])
	var colors := PackedColorArray([Color(1, 1, 1, 1)])
	var indices := PackedInt32Array()
	for index: int in segments:
		var angle := TAU * float(index) / float(segments)
		vertices.append(Vector3(cos(angle), sin(angle), 0.0) * radius)
		colors.append(Color(1, 1, 1, 0))
		indices.append_array(PackedInt32Array([0, index + 1, (index + 1) % segments + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# --- Internals --------------------------------------------------------------

func _on_darto_clip_finished(clip: StringName) -> void:
	if not _finished and clip != IDLE_CLIP:
		_darto_player.play(IDLE_CLIP, BLEND_SEC * 2.0)


func _on_fish_clip_finished(clip: StringName) -> void:
	if not _finished and clip != IDLE_CLIP:
		_fish_player.play(IDLE_CLIP, BLEND_SEC * 2.0, 1.0)


func _lean_peak() -> float:
	var animation := _darto_player.get_animation(_darto_player.current_animation)
	return animation.get_marker_time(&"lean_peak") if animation != null and animation.has_marker(&"lean_peak") else 0.1


## The short hold after a Perfect Dodge (GDD Section 47): both fighters stop.
func _freeze(seconds: float) -> void:
	_freeze_left = seconds
	_set_speed(0.0)


func _set_speed(speed: float) -> void:
	_darto_player.speed_scale = speed
	if _fish_player != null:
		_fish_player.speed_scale = speed


## A small flat burst where a punch landed. It is a shape and a size change,
## not a screen flash, and it is skipped when Reduce Flash is on.
func _spark(at: Vector3, color: Color) -> void:
	if GameState.get_setting(&"reduced_flash"):
		return
	var index := 0
	for candidate: int in _sparks.size():
		if _spark_ages[candidate] > _spark_ages[index]:
			index = candidate
	_spark_ages[index] = 0.0
	_sparks[index].global_position = at
	(_sparks[index].material_override as StandardMaterial3D).albedo_color = color
	_sparks[index].visible = true


func _make_spark() -> MeshInstance3D:
	# A soft round burst: a disc whose vertex alpha fades to the rim. No
	# texture is involved (VISUAL_STYLE_GUIDE 5.1).
	var material := DioramaStyle.unshaded_transparent(Color.WHITE, true)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.no_depth_test = true
	var spark := MeshInstance3D.new()
	spark.mesh = burst_disc(0.11, 16)
	spark.material_override = material
	spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spark.visible = false
	add_child(spark)
	return spark

