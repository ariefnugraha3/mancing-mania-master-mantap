class_name ArmWrestleWorld
extends Node3D
## Everything you see at the arm wrestling table (GDD 50-56, 168.8, 172.3,
## 185.17): Darto leaning over the table, the fish on it, and the two hands
## locked over the middle.
##
## The match position is shown by the locked hands: they lean toward Darto's
## left as he wins and toward his right as the fish wins, the same way the
## position bar moves. The lean is applied on top of the body clips, so the
## arm always shows the real position while the body shows the effort.

const FOV_LANDSCAPE := 45.0
const FOV_PORTRAIT := 52.0
const BLEND_SEC := 0.15
## Lean of the locked forearms at the ends of the position range, in degrees.
const MAX_LEAN_DEG := 62.0
## How quickly the shown lean follows the match, per second.
const LEAN_FOLLOW := 14.0
const GRIP_SKIN := Color("b98a62")

@onready var _set: Node3D = $ArmWrestleSet
@onready var _darto: Node3D = $DartoArmRig
@onready var _fish_anchor: Node3D = $FishArmRig
@onready var _camera: Camera3D = $ArmCamera

var _darto_player: AnimationPlayer
var _darto_skeleton: Skeleton3D
var _forearm: int = -1
var _fish: Node3D
var _fish_player: AnimationPlayer
var _fish_base: Transform3D
var _grip: Node3D
var _fist: MeshInstance3D
var _fin_arm: MeshInstance3D
var _fish_skeleton: Skeleton3D
var _fish_fin: int = -1
var _shown_lean: float = 0.0
var _target_lean: float = 0.0
var _finished: bool = false


func _ready() -> void:
	var markers := _set.get_node("Markers")
	_darto.transform = (markers.get_node("DartoSpot") as Node3D).transform
	_fish_anchor.transform = (markers.get_node("FishSpot") as Node3D).transform
	_fish_base = _fish_anchor.transform

	var rig := _darto.get_node("Rig")
	_darto_player = rig.get_node("AnimationPlayer")
	# The lean is written after each animation step, so the player is stepped here.
	_darto_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_darto_skeleton = rig.get_node("Skeleton3D")
	_forearm = _darto_skeleton.find_bone("forearm_r")
	_darto_player.play(&"arm_idle_grip")
	_build_grip()

	PlatformService.viewport_class_changed.connect(_apply_camera)
	_apply_camera(PlatformService.get_viewport_class())


func _process(delta: float) -> void:
	_shown_lean = lerpf(_shown_lean, _target_lean, minf(delta * LEAN_FOLLOW, 1.0))
	_darto_player.advance(delta)
	_apply_lean()
	_stretch_fin_arm()


# --- Called by the arm wrestling scene --------------------------------------

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
	_fish_skeleton = _fish.get_node("Skeleton3D")
	_fish_fin = _fish_skeleton.find_bone("fin_left")
	(_fin_arm.material_override as StandardMaterial3D).albedo_color = _fin_color(fish_id)
	reset()


func reset() -> void:
	_finished = false
	_shown_lean = 0.0
	_target_lean = 0.0
	_darto_player.play(&"arm_idle_grip", BLEND_SEC)
	if _fish_player != null:
		_fish_player.play(&"arm_idle", BLEND_SEC)


## Shows the match: where the hands are, and how hard each side is working.
func show_state(snapshot: Dictionary, pressing: bool) -> void:
	if _finished:
		return
	var config := GameData.get_arm_wrestle_config()
	_target_lean = clampf(float(snapshot["position"]) / config.position_max, -1.0, 1.0)
	var clip := &"arm_idle_grip"
	if float(snapshot["stamina_ratio"]) < 0.1 and not pressing:
		clip = &"arm_recover"
	elif pressing:
		clip = &"arm_push_hard" if float(snapshot["power"]) >= 0.85 else &"arm_push_light"
	if _darto_player.current_animation != clip:
		_darto_player.play(clip, BLEND_SEC)
	var fish_clip := &"arm_burst" if snapshot["bursting"] or snapshot["burst_warning"] else &"arm_idle"
	if _fish_player.current_animation != fish_clip:
		_fish_player.play(fish_clip, BLEND_SEC)


func show_finish(player_won: bool) -> void:
	_finished = true
	_target_lean = 1.0 if player_won else -1.0
	_darto_player.play(&"arm_win" if player_won else &"arm_lose", BLEND_SEC)
	_fish_player.play(&"arm_lose" if player_won else &"arm_win", BLEND_SEC)


func get_darto_clip() -> StringName:
	return StringName(_darto_player.current_animation)


func get_fish_clip() -> StringName:
	return StringName(_fish_player.current_animation) if _fish_player != null else &""


func get_fish_rig_node() -> Node3D:
	return _fish


## The lean shown right now, -1 (fish's side) to +1 (Darto's side).
func get_shown_lean() -> float:
	return _shown_lean


# --- Internals --------------------------------------------------------------

## Darto's forearm rolls toward his left for a positive position; the fish's
## whole body leans the same way, pivoting on the table.
func _apply_lean() -> void:
	var angle := deg_to_rad(MAX_LEAN_DEG) * _shown_lean
	if _forearm >= 0:
		var pose := _darto_skeleton.get_bone_pose_rotation(_forearm)
		_darto_skeleton.set_bone_pose_rotation(_forearm, pose * Quaternion(Vector3.FORWARD, -angle))
	# Darto faces +X: a lean toward his left is a tilt toward -Z.
	var tilt := Basis(Vector3.RIGHT, -angle * 0.35)
	_fish_anchor.transform = Transform3D(tilt * _fish_base.basis, _fish_base.origin)


## The locked hands: a fist wrapped by a fin, riding on Darto's right hand.
func _build_grip() -> void:
	var attachment := BoneAttachment3D.new()
	attachment.name = "Grip"
	_darto.get_node("Rig").add_child(attachment)
	attachment.set_use_external_skeleton(true)
	attachment.set_external_skeleton(NodePath("../Skeleton3D"))
	attachment.bone_name = "hand_r"
	var fist := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	sphere.height = 0.11
	sphere.radial_segments = 8
	sphere.rings = 4
	fist.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = GRIP_SKIN
	fist.material_override = material
	# The bone frame starts at the wrist; the fist hangs just past it.
	fist.position = Vector3(0.0, -0.055, -0.01)
	attachment.add_child(fist)
	_grip = attachment
	_fist = fist

	# The fish's arm: a fin stretched from its shoulder to Darto's fist. It is
	# rebuilt from the two end points every frame, so the hands always meet.
	_fin_arm = MeshInstance3D.new()
	_fin_arm.name = "FinArm"
	var tube := CylinderMesh.new()
	tube.top_radius = 0.035
	tube.bottom_radius = 0.06
	tube.height = 1.0
	tube.radial_segments = 6
	tube.rings = 1
	_fin_arm.mesh = tube
	var fin_material := StandardMaterial3D.new()
	_fin_arm.material_override = fin_material
	add_child(_fin_arm)


func _stretch_fin_arm() -> void:
	if _fish_skeleton == null or _fish_fin < 0:
		_fin_arm.visible = false
		return
	var from := (_fish_skeleton.global_transform * _fish_skeleton.get_bone_global_pose(_fish_fin)).origin
	var to := _fist.global_position
	var span := to - from
	if span.length() < 0.01:
		return
	_fin_arm.visible = true
	var up := span.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var basis := Basis(side, up, side.cross(up)).scaled(Vector3(1.0, span.length(), 1.0))
	_fin_arm.global_transform = Transform3D(basis, from + span * 0.5)


## The fin colour of each species, the same as in fish_builder.gd's profiles.
func _fin_color(fish_id: StringName) -> Color:
	var colors := {
		&"catfish_bruiser": Color("2c3129"), &"tilapia_gym_rat": Color("55666d"),
		&"gourami_shady": Color("665840"), &"carp_golden": Color("d47a2c"),
		&"snakehead_sergeant": Color("2d382b"), &"arowana_don": Color("73291f"),
	}
	return colors.get(fish_id, Color("5a5046"))


func _apply_camera(viewport_class: StringName) -> void:
	var portrait := viewport_class == PlatformService.PORTRAIT
	var marker_name := "CameraPortrait" if portrait else "CameraLandscape"
	_camera.transform = (_set.get_node("Markers/%s" % marker_name) as Node3D).transform
	_camera.fov = FOV_PORTRAIT if portrait else FOV_LANDSCAPE
