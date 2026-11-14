@tool
extends RefCounted
## Generates the human characters as rigid-part low-poly rigs (GDD 184.6, 185.2).
##
## Every body part is bound to exactly one bone, so joints stay crisp and the
## whole character is one draw call for the body and one for the accessories.
## Characters face -Z; their right hand is on +X.
##
## Milestone 2 builds Darto with his fishing clips. Rini, Nisa and Bu Yati and
## the home, market and duel clips are added by the milestones that need them.

const MeshBuilder := preload("res://tools/generators/mesh_builder.gd")
const RigBuilder := preload("res://tools/generators/rig_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")

const GENERATOR_ID := "character_builder"
const GENERATOR_VERSION := 1
const DARTO_PATH := "res://generated/scenes/characters/chr_darto.tscn"

const SEGMENTS := 10

# Darto palette (GDD 185.2).
const SKIN := Color("b98a62")
const SKIN_SHADE := Color("a37650")
const SHIRT := Color("a78d68")
const TROUSERS := Color("4f554e")
const CAP := Color("6a6655")
const HAIR := Color("2a2622")
const SANDAL := Color("6b5b4b")
const BAG := Color("59614f")
const FACE_DARK := Color("2e2620")

## [bone, parent, joint position]. Height 1.72 m.
const DARTO_BONES: Array = [
	["root", "", Vector3(0, 0, 0)],
	["pelvis", "root", Vector3(0, 0.93, 0)],
	["spine_lower", "pelvis", Vector3(0, 1.02, 0)],
	["spine_upper", "spine_lower", Vector3(0, 1.22, 0)],
	["neck", "spine_upper", Vector3(0, 1.43, 0)],
	["head", "neck", Vector3(0, 1.50, 0)],
	["upper_arm_l", "spine_upper", Vector3(-0.205, 1.385, 0)],
	["forearm_l", "upper_arm_l", Vector3(-0.215, 1.115, 0)],
	["hand_l", "forearm_l", Vector3(-0.22, 0.875, 0)],
	["upper_arm_r", "spine_upper", Vector3(0.205, 1.385, 0)],
	["forearm_r", "upper_arm_r", Vector3(0.215, 1.115, 0)],
	["hand_r", "forearm_r", Vector3(0.22, 0.875, 0)],
	["thigh_l", "pelvis", Vector3(-0.09, 0.90, 0)],
	["shin_l", "thigh_l", Vector3(-0.095, 0.50, 0)],
	["foot_l", "shin_l", Vector3(-0.095, 0.09, 0)],
	["thigh_r", "pelvis", Vector3(0.09, 0.90, 0)],
	["shin_r", "thigh_r", Vector3(0.095, 0.50, 0)],
	["foot_r", "shin_r", Vector3(0.095, 0.09, 0)],
]

## Relaxed fishing stance: rod held forward and up in the right hand, left hand
## resting near the reel, a slight forward slouch. Degrees: X pitch (positive
## swings a hanging limb forward), Y yaw, Z roll.
const FISHING_POSE: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-4, 0, 0),
	"spine_upper": Vector3(-3, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(-4, 0, 0),
	"upper_arm_r": Vector3(38, 0, 6),
	"forearm_r": Vector3(52, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(30, 0, 16),
	"forearm_l": Vector3(62, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(6, 0, -3),
	"shin_l": Vector3(-6, 0, 0),
	"foot_l": Vector3(0, 0, 0),
	"thigh_r": Vector3(-4, 0, 3),
	"shin_r": Vector3(-3, 0, 0),
	"foot_r": Vector3(7, 0, 0),
}


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var root := build_darto()
	var save_error := GeneratorIo.save_scene(root, DARTO_PATH)
	root.free()
	if save_error != OK:
		errors.append("chr_darto: could not save (%s)" % error_string(save_error))
	else:
		manifest.register("chr_darto", GENERATOR_ID, GENERATOR_VERSION, 0, DARTO_PATH)
	return errors


func build_darto() -> Node3D:
	var root := Node3D.new()
	root.name = "ChrDarto"
	var skeleton := RigBuilder.make_skeleton(DARTO_BONES)
	root.add_child(skeleton)

	var material: Material = load(MaterialBuilder.VERTEX_COLOR)
	var body_meshes := Node3D.new()
	body_meshes.name = "BodyMeshes"
	root.add_child(body_meshes)
	body_meshes.add_child(_mesh_instance("Body", _build_darto_body(skeleton), material))

	var accessories := Node3D.new()
	accessories.name = "AccessoryMeshes"
	root.add_child(accessories)
	accessories.add_child(_mesh_instance("Accessories", _build_darto_accessories(skeleton), material))

	# Anchors that follow the head, for dialogue and look-at targets.
	var face := BoneAttachment3D.new()
	face.name = "FaceMarkers"
	root.add_child(face)
	face.set_use_external_skeleton(true)
	face.set_external_skeleton(NodePath("../Skeleton3D"))
	face.bone_name = "head"
	for marker: Array in [["EyeLine", Vector3(0, 0.088, -0.115)], ["Mouth", Vector3(0, 0.027, -0.11)], ["HeadTop", Vector3(0, 0.29, 0)]]:
		var node := Marker3D.new()
		node.name = marker[0]
		node.position = marker[1]
		face.add_child(node)

	root.add_child(RigBuilder.make_player(_build_darto_clips(skeleton)))
	return root


func _mesh_instance(node_name: String, mesh: ArrayMesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.skeleton = NodePath("../../Skeleton3D")
	return instance


# --- Darto: body ------------------------------------------------------------

func _build_darto_body(skeleton: Skeleton3D) -> ArrayMesh:
	var builder := MeshBuilder.new()
	builder.enable_skinning()

	# Hips in trousers.
	builder.set_bone(skeleton.find_bone("pelvis"))
	builder.color = TROUSERS
	builder.loft([_ring(builder, 0.84, 0.150, 0.105), _ring(builder, 0.90, 0.168, 0.118), _ring(builder, 0.98, 0.166, 0.118)])

	# A loose T-shirt: the hem hangs over the waistband, with a small belly.
	builder.set_bone(skeleton.find_bone("spine_lower"))
	builder.color = SHIRT
	builder.loft([
		_ring(builder, 0.935, 0.176, 0.126), _ring(builder, 0.97, 0.174, 0.128, -0.006),
		_ring(builder, 1.05, 0.177, 0.136, -0.014), _ring(builder, 1.14, 0.177, 0.130, -0.008),
		_ring(builder, 1.225, 0.179, 0.122)])
	builder.set_bone(skeleton.find_bone("spine_upper"))
	builder.loft([
		_ring(builder, 1.205, 0.179, 0.122), _ring(builder, 1.32, 0.197, 0.116),
		_ring(builder, 1.39, 0.187, 0.102), _ring(builder, 1.436, 0.086, 0.072)])

	builder.set_bone(skeleton.find_bone("neck"))
	builder.color = SKIN_SHADE
	builder.tube(Vector3(0, 1.415, 0), Vector3(0, 1.51, 0), 0.051, 0.048, 8)

	_add_darto_head(builder, skeleton)

	for side: float in [-1.0, 1.0]:
		var suffix := "_l" if side < 0.0 else "_r"
		var shoulder := Vector3(0.205 * side, 1.392, 0)
		var elbow := Vector3(0.215 * side, 1.115, 0)
		var wrist := Vector3(0.22 * side, 0.882, 0)
		builder.set_bone(skeleton.find_bone("upper_arm" + suffix))
		builder.color = SHIRT
		builder.blob(shoulder - Vector3(0.014 * side, 0.03, 0), Vector3(0.062, 0.044, 0.064), 8, 4)
		builder.tube(shoulder - Vector3(0, 0.02, 0), shoulder.lerp(elbow, 0.55), 0.060, 0.057, 8, false)
		builder.tube(shoulder.lerp(elbow, 0.5), shoulder.lerp(elbow, 0.55), 0.057, 0.044, 8, false)
		builder.color = SKIN
		builder.tube(shoulder.lerp(elbow, 0.5), elbow, 0.044, 0.040, 8)
		builder.set_bone(skeleton.find_bone("forearm" + suffix))
		builder.tube(elbow + Vector3(0, 0.01, 0), wrist, 0.041, 0.033, 8)
		builder.set_bone(skeleton.find_bone("hand" + suffix))
		builder.box(Vector3(0.062, 0.098, 0.04), Vector3(0.22 * side, 0.832, 0))
		builder.box(Vector3(0.022, 0.05, 0.026), Vector3(0.22 * side - 0.03 * side, 0.845, -0.026))

		var hip := Vector3(0.09 * side, 0.925, 0)
		var knee := Vector3(0.095 * side, 0.50, 0)
		var ankle := Vector3(0.095 * side, 0.09, 0)
		builder.set_bone(skeleton.find_bone("thigh" + suffix))
		builder.color = TROUSERS
		builder.tube(hip, hip.lerp(knee, 0.88), 0.088, 0.075, 8)
		builder.color = SKIN
		builder.tube(hip.lerp(knee, 0.85), knee, 0.056, 0.052, 8)
		builder.set_bone(skeleton.find_bone("shin" + suffix))
		builder.tube(knee + Vector3(0, 0.01, 0), ankle, 0.053, 0.038, 8)
		builder.set_bone(skeleton.find_bone("foot" + suffix))
		builder.box(Vector3(0.084, 0.05, 0.205), Vector3(0.095 * side, 0.052, -0.045))
	return builder.commit()


func _add_darto_head(builder: RefCounted, skeleton: Skeleton3D) -> void:
	builder.set_bone(skeleton.find_bone("head"))
	# Rounded rectangular head, narrower at the jaw.
	builder.color = SKIN
	builder.loft([
		_ring(builder, 1.485, 0.070, 0.078, 0.0, 3.2), _ring(builder, 1.525, 0.094, 0.102, 0.0, 3.2),
		_ring(builder, 1.60, 0.103, 0.112, 0.0, 3.2), _ring(builder, 1.68, 0.100, 0.108, 0.0, 3.2),
		_ring(builder, 1.725, 0.075, 0.080, 0.0, 3.2)])
	builder.color = SKIN_SHADE
	for side: float in [-1.0, 1.0]:
		builder.box(Vector3(0.022, 0.052, 0.03), Vector3(0.108 * side, 1.575, 0.004))

	# Short messy hair showing under the cap, a little longer at the back.
	builder.color = HAIR
	# The hair shape sits toward the back of the skull, so it shows at the
	# sides and nape while the forehead stays clear.
	builder.loft([_ring(builder, 1.60, 0.108, 0.074, 0.052, 3.2), _ring(builder, 1.70, 0.106, 0.074, 0.050, 3.2)])
	builder.box(Vector3(0.16, 0.05, 0.03), Vector3(0, 1.578, 0.106))

	# Small tired eyes under soft brows, a wedge nose and a flat mouth.
	builder.color = FACE_DARK
	for side: float in [-1.0, 1.0]:
		builder.box(Vector3(0.03, 0.011, 0.012), Vector3(0.042 * side, 1.586, -0.109))
		builder.transform = Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(-9.0 * side)), Vector3(0.044 * side, 1.607, -0.111))
		builder.box(Vector3(0.044, 0.009, 0.012))
		builder.transform = Transform3D.IDENTITY
	builder.color = SKIN_SHADE
	builder.tube(Vector3(0, 1.592, -0.106), Vector3(0, 1.553, -0.132), 0.008, 0.017, 4)
	builder.color = Color("6e4a3a")
	builder.box(Vector3(0.046, 0.006, 0.01), Vector3(0, 1.526, -0.102))


# --- Darto: cap, waist bag, sandals -----------------------------------------

func _build_darto_accessories(skeleton: Skeleton3D) -> ArrayMesh:
	var builder := MeshBuilder.new()
	builder.enable_skinning()

	# Old faded cap with the brim tipped slightly down.
	builder.set_bone(skeleton.find_bone("head"))
	builder.color = CAP
	builder.loft([
		_ring(builder, 1.655, 0.111, 0.120, 0.002, 2.6), _ring(builder, 1.70, 0.108, 0.116, 0.002, 2.6),
		_ring(builder, 1.745, 0.090, 0.098, 0.002, 2.6), _ring(builder, 1.775, 0.050, 0.055, 0.002, 2.6)])
	builder.blob(Vector3(0, 1.782, 0.002), Vector3(0.016, 0.008, 0.016), 6, 3)
	builder.color = CAP.darkened(0.12)
	# The outline is drawn upright, then laid flat with its front edge dipped.
	builder.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(81.0)), Vector3(0, 1.664, -0.168))
	builder.slab(PackedVector2Array([
		Vector2(-0.098, 0.062), Vector2(0.098, 0.062), Vector2(0.088, -0.03),
		Vector2(0.05, -0.066), Vector2(-0.05, -0.066), Vector2(-0.088, -0.03)]), 0.012)
	builder.transform = Transform3D.IDENTITY

	# Waist bag worn at the front, slightly to his right.
	builder.set_bone(skeleton.find_bone("pelvis"))
	builder.color = BAG.darkened(0.2)
	builder.loft([_ring(builder, 0.975, 0.181, 0.131), _ring(builder, 1.0, 0.181, 0.131)], false, false)
	builder.color = BAG
	builder.box(Vector3(0.15, 0.085, 0.06), Vector3(0.05, 0.982, -0.148))
	builder.color = BAG.lightened(0.12)
	builder.box(Vector3(0.152, 0.03, 0.064), Vector3(0.05, 1.012, -0.148))

	# Plain sandals: sole, instep strap and toe post.
	for side: float in [-1.0, 1.0]:
		builder.set_bone(skeleton.find_bone("foot_l" if side < 0.0 else "foot_r"))
		builder.color = SANDAL
		builder.box(Vector3(0.1, 0.024, 0.25), Vector3(0.095 * side, 0.012, -0.045))
		builder.color = SANDAL.darkened(0.25)
		builder.box(Vector3(0.094, 0.012, 0.032), Vector3(0.095 * side, 0.082, -0.07))
		builder.box(Vector3(0.012, 0.03, 0.012), Vector3(0.095 * side, 0.066, -0.115))
	return builder.commit()


func _ring(builder: RefCounted, height: float, half_x: float, half_z: float, z_offset: float = 0.0, squareness: float = 2.4) -> PackedVector3Array:
	return builder.ring(Vector3(0, height, z_offset), Vector3(half_x, 0, 0), Vector3(0, 0, half_z), SEGMENTS, squareness)


# --- Darto: fishing clips (GDD 172.1) ---------------------------------------

func _build_darto_clips(skeleton: Skeleton3D) -> Array:
	var clips: Array = []
	var back_swing := {
		"upper_arm_r": Vector3(126, 0, 8), "forearm_r": Vector3(55, 0, 0),
		"spine_lower": Vector3(3, 0, 0), "spine_upper": Vector3(6, -14, 0),
		"upper_arm_l": Vector3(12, 0, -4), "forearm_l": Vector3(22, 0, 0), "head": Vector3(-2, 0, 0),
	}
	var forward_swing := {
		"upper_arm_r": Vector3(58, 0, 0), "forearm_r": Vector3(10, 0, 0),
		"spine_lower": Vector3(-8, 0, 0), "spine_upper": Vector3(-12, 8, 0),
		"upper_arm_l": Vector3(14, 0, -4), "forearm_l": Vector3(26, 0, 0),
	}
	var reel := {
		"upper_arm_r": Vector3(46, 0, 6), "forearm_r": Vector3(66, 0, 0),
		"spine_lower": Vector3(4, 0, 0), "spine_upper": Vector3(3, 0, 0),
		"upper_arm_l": Vector3(36, 0, 16), "forearm_l": Vector3(72, 0, 0), "head": Vector3(-8, 0, 0),
	}

	var idle := RigBuilder.Clip.new(skeleton, &"idle_fishing", 5.0, true)
	_pose(idle, 0.0)
	_pose(idle, 2.5, {"spine_upper": Vector3(-5, 0, 0), "upper_arm_r": Vector3(36, 0, 6), "forearm_r": Vector3(51, 0, 0), "head": Vector3(-6, 3, 0)})
	_pose(idle, 5.0)
	clips.append(idle)

	var prepare := RigBuilder.Clip.new(skeleton, &"cast_prepare", 0.30)
	_pose(prepare, 0.0)
	_pose(prepare, 0.30, back_swing)
	clips.append(prepare)

	# The float leaves the rod tip at 0.18 s here, which is 0.48 s into the cast.
	var forward := RigBuilder.Clip.new(skeleton, &"cast_forward", 0.42)
	_pose(forward, 0.0, back_swing)
	_pose(forward, 0.18, {
		"upper_arm_r": Vector3(86, 0, 4), "forearm_r": Vector3(30, 0, 0),
		"spine_lower": Vector3(-3, 0, 0), "spine_upper": Vector3(-4, -2, 0)})
	_pose(forward, 0.42, forward_swing)
	forward.mark(&"release_float", 0.18)
	clips.append(forward)

	var settle := RigBuilder.Clip.new(skeleton, &"cast_settle", 0.63)
	_pose(settle, 0.0, forward_swing)
	_pose(settle, 0.33, {"upper_arm_r": Vector3(47, 0, 3), "forearm_r": Vector3(40, 0, 0), "spine_upper": Vector3(-6, 2, 0)})
	_pose(settle, 0.63)
	settle.mark(&"cast_complete", 0.63)
	clips.append(settle)

	var reel_hold := RigBuilder.Clip.new(skeleton, &"reel_hold", 1.0, true)
	_pose(reel_hold, 0.0, reel)
	_pose(reel_hold, 0.5, reel.merged({"forearm_l": Vector3(84, 0, 0), "upper_arm_l": Vector3(40, 0, 18), "upper_arm_r": Vector3(48, 0, 6)}, true))
	_pose(reel_hold, 1.0, reel)
	clips.append(reel_hold)

	var relax := RigBuilder.Clip.new(skeleton, &"reel_release_relax", 0.35)
	_pose(relax, 0.0, reel)
	_pose(relax, 0.35, {"upper_arm_r": Vector3(40, 0, 6), "forearm_r": Vector3(56, 0, 0)})
	clips.append(relax)

	var jerk := RigBuilder.Clip.new(skeleton, &"line_stress_jerk", 0.30)
	_pose(jerk, 0.0, reel)
	_pose(jerk, 0.10, reel.merged({"upper_arm_r": Vector3(32, 0, 6), "forearm_r": Vector3(50, 0, 0), "spine_upper": Vector3(-10, 0, 0)}, true))
	_pose(jerk, 0.30, reel)
	clips.append(jerk)

	var land := RigBuilder.Clip.new(skeleton, &"land_fish", 1.10)
	_pose(land, 0.0, reel)
	_pose(land, 0.30, {
		"upper_arm_r": Vector3(96, 0, 10), "forearm_r": Vector3(76, 0, 0), "spine_lower": Vector3(10, 0, 0),
		"spine_upper": Vector3(10, 0, 0), "upper_arm_l": Vector3(70, 0, 14), "forearm_l": Vector3(80, 0, 0)})
	_pose(land, 0.55, {
		"upper_arm_r": Vector3(112, 0, 10), "forearm_r": Vector3(60, 0, 0), "spine_lower": Vector3(8, 0, 0),
		"spine_upper": Vector3(8, 0, 0), "upper_arm_l": Vector3(60, 0, 12), "forearm_l": Vector3(70, 0, 0), "head": Vector3(8, 0, 0)})
	_pose(land, 0.80, {"upper_arm_r": Vector3(72, 0, 8), "forearm_r": Vector3(70, 0, 0), "spine_upper": Vector3(2, 0, 0)})
	_pose(land, 1.10, {"upper_arm_r": Vector3(56, 0, 6), "forearm_r": Vector3(64, 0, 0)})
	land.mark(&"fish_reveal", 0.55)
	clips.append(land)

	var empty := RigBuilder.Clip.new(skeleton, &"empty_pull", 0.80)
	_pose(empty, 0.0)
	_pose(empty, 0.20, {"upper_arm_r": Vector3(80, 0, 8), "forearm_r": Vector3(70, 0, 0), "spine_upper": Vector3(4, 0, 0)})
	_pose(empty, 0.50, {"upper_arm_r": Vector3(60, 0, 6), "forearm_r": Vector3(62, 0, 0)})
	_pose(empty, 0.80)
	clips.append(empty)

	var react := RigBuilder.Clip.new(skeleton, &"fish_escape_react", 1.00)
	_pose(react, 0.0)
	_pose(react, 0.30, {"spine_upper": Vector3(-10, 0, 0), "head": Vector3(-18, 0, 0), "upper_arm_r": Vector3(22, 0, 6), "forearm_r": Vector3(42, 0, 0)})
	_pose(react, 0.55, {"spine_upper": Vector3(-10, 0, 0), "head": Vector3(-14, 13, 0), "upper_arm_r": Vector3(22, 0, 6), "forearm_r": Vector3(42, 0, 0)})
	_pose(react, 0.75, {"spine_upper": Vector3(-9, 0, 0), "head": Vector3(-14, -13, 0), "upper_arm_r": Vector3(24, 0, 6), "forearm_r": Vector3(44, 0, 0)})
	_pose(react, 1.00)
	clips.append(react)

	var bucket := RigBuilder.Clip.new(skeleton, &"bucket_add", 0.75)
	_pose(bucket, 0.0)
	_pose(bucket, 0.30, {
		"spine_lower": Vector3(-26, 0, 0), "spine_upper": Vector3(-22, -22, 0), "head": Vector3(-10, -10, 0),
		"upper_arm_l": Vector3(58, 0, 4), "forearm_l": Vector3(18, 0, 0), "upper_arm_r": Vector3(30, 0, 8)})
	_pose(bucket, 0.45, {
		"spine_lower": Vector3(-28, 0, 0), "spine_upper": Vector3(-24, -22, 0), "head": Vector3(-10, -10, 0),
		"upper_arm_l": Vector3(64, 0, 4), "forearm_l": Vector3(10, 0, 0), "upper_arm_r": Vector3(30, 0, 8)})
	_pose(bucket, 0.75)
	bucket.mark(&"bucket_commit", 0.45)
	clips.append(bucket)
	return clips


## Keys the whole body at `time`: the fishing stance with `changes` on top.
## Keying every joint in every clip keeps blends between clips clean.
func _pose(clip: RefCounted, time: float, changes: Dictionary = {}) -> void:
	for bone: String in FISHING_POSE:
		clip.rot(bone, time, changes.get(bone, FISHING_POSE[bone]))
