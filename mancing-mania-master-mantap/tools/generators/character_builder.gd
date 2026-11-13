@tool
extends RefCounted
## Generates the human characters as rigid-part low-poly rigs (GDD 184.6, 185.2).
##
## Every body part is bound to exactly one bone, so joints stay crisp and the
## whole character is one draw call for the body and one for the accessories.
## Characters face -Z; their right hand is on +X.
##
## Darto has his fishing and market clips and Bu Yati her market clips. Rini,
## Nisa and the home and duel clips are added by the milestones that need them.

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
	var characters: Dictionary[String, Array] = {
		"chr_darto": [build_darto, DARTO_PATH],
		"chr_bu_yati": [build_bu_yati, BU_YATI_PATH],
	}
	for character_id: String in characters:
		var root: Node3D = characters[character_id][0].call()
		var path: String = characters[character_id][1]
		var save_error := GeneratorIo.save_scene(root, path)
		root.free()
		if save_error != OK:
			errors.append("%s: could not save (%s)" % [character_id, error_string(save_error)])
		else:
			manifest.register(character_id, GENERATOR_ID, GENERATOR_VERSION, 0, path)
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
	var gloves := _mesh_instance("BoxingGloves", _build_darto_gloves(skeleton), material)
	gloves.visible = false
	accessories.add_child(gloves)

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

	var clips := _build_darto_clips(skeleton)
	clips.append_array(_build_darto_boxing_clips(skeleton))
	clips.append_array(_build_darto_arm_clips(skeleton))
	root.add_child(RigBuilder.make_player(clips))
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

	# At the warung: arms down, weight on one leg, a slow sway.
	var standing := {
		"upper_arm_r": Vector3(6, 0, 7), "forearm_r": Vector3(14, 0, 0),
		"upper_arm_l": Vector3(8, 0, -7), "forearm_l": Vector3(18, 0, 0),
		"spine_lower": Vector3(-2, 0, 0), "spine_upper": Vector3(-3, 0, 0), "head": Vector3(-3, 0, 0),
	}
	var market := RigBuilder.Clip.new(skeleton, &"market_idle", 5.0, true)
	_pose(market, 0.0, standing)
	_pose(market, 2.5, standing.merged({"spine_upper": Vector3(-4, 3, 0), "head": Vector3(-5, 5, 0)}, true))
	_pose(market, 5.0, standing)
	clips.append(market)
	return clips


## Keys the whole body at `time`: the fishing stance with `changes` on top.
## Keying every joint in every clip keeps blends between clips clean.
func _pose(clip: RefCounted, time: float, changes: Dictionary = {}) -> void:
	for bone: String in FISHING_POSE:
		clip.rot(bone, time, changes.get(bone, FISHING_POSE[bone]))


# --- Bu Yati (GDD 185.5) ----------------------------------------------------
# A compact, sturdy older woman: maroon blouse, cream apron, olive skirt, grey
# hair tied in a bun. She moves as little as possible.

const BU_YATI_PATH := "res://generated/scenes/characters/chr_bu_yati.tscn"
const YATI_SKIN := Color("b08260")
const YATI_SKIN_SHADE := Color("996e4e")
const YATI_BLOUSE := Color("7c4a44")
const YATI_SKIRT := Color("6b6a4b")
const YATI_APRON := Color("d6c4a0")
const YATI_HAIR := Color("5a554f")
const YATI_SLIPPER := Color("8a5a4a")

## Height 1.56 m.
const BU_YATI_BONES: Array = [
	["root", "", Vector3(0, 0, 0)],
	["pelvis", "root", Vector3(0, 0.84, 0)],
	["spine_lower", "pelvis", Vector3(0, 0.925, 0)],
	["spine_upper", "spine_lower", Vector3(0, 1.105, 0)],
	["neck", "spine_upper", Vector3(0, 1.295, 0)],
	["head", "neck", Vector3(0, 1.36, 0)],
	["upper_arm_l", "spine_upper", Vector3(-0.205, 1.255, 0)],
	["forearm_l", "upper_arm_l", Vector3(-0.215, 1.01, 0)],
	["hand_l", "forearm_l", Vector3(-0.22, 0.795, 0)],
	["upper_arm_r", "spine_upper", Vector3(0.205, 1.255, 0)],
	["forearm_r", "upper_arm_r", Vector3(0.215, 1.01, 0)],
	["hand_r", "forearm_r", Vector3(0.22, 0.795, 0)],
	["thigh_l", "pelvis", Vector3(-0.09, 0.815, 0)],
	["shin_l", "thigh_l", Vector3(-0.095, 0.455, 0)],
	["foot_l", "shin_l", Vector3(-0.095, 0.085, 0)],
	["thigh_r", "pelvis", Vector3(0.09, 0.815, 0)],
	["shin_r", "thigh_r", Vector3(0.095, 0.455, 0)],
	["foot_r", "shin_r", Vector3(0.095, 0.085, 0)],
]

## Standing behind the counter with both hands resting near it.
const COUNTER_POSE: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-2, 0, 0),
	"spine_upper": Vector3(-2, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(-2, 0, 0),
	"upper_arm_r": Vector3(24, 0, 8),
	"forearm_r": Vector3(46, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(22, 0, -8),
	"forearm_l": Vector3(50, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(0, 0, -2),
	"shin_l": Vector3(0, 0, 0),
	"foot_l": Vector3(0, 0, 0),
	"thigh_r": Vector3(0, 0, 2),
	"shin_r": Vector3(0, 0, 0),
	"foot_r": Vector3(0, 0, 0),
}


func build_bu_yati() -> Node3D:
	var root := Node3D.new()
	root.name = "ChrBuYati"
	var skeleton := RigBuilder.make_skeleton(BU_YATI_BONES)
	root.add_child(skeleton)

	var material: Material = load(MaterialBuilder.VERTEX_COLOR)
	var body_meshes := Node3D.new()
	body_meshes.name = "BodyMeshes"
	root.add_child(body_meshes)
	body_meshes.add_child(_mesh_instance("Body", _build_bu_yati_body(skeleton), material))
	var accessories := Node3D.new()
	accessories.name = "AccessoryMeshes"
	root.add_child(accessories)
	accessories.add_child(_mesh_instance("Accessories", _build_bu_yati_accessories(skeleton), material))

	var face := BoneAttachment3D.new()
	face.name = "FaceMarkers"
	root.add_child(face)
	face.set_use_external_skeleton(true)
	face.set_external_skeleton(NodePath("../Skeleton3D"))
	face.bone_name = "head"
	for marker: Array in [["EyeLine", Vector3(0, 0.082, -0.112)], ["Mouth", Vector3(0, 0.026, -0.108)], ["HeadTop", Vector3(0, 0.23, 0)]]:
		var node := Marker3D.new()
		node.name = marker[0]
		node.position = marker[1]
		face.add_child(node)

	root.add_child(RigBuilder.make_player(_build_bu_yati_clips(skeleton)))
	return root


func _build_bu_yati_body(skeleton: Skeleton3D) -> ArrayMesh:
	var builder := MeshBuilder.new()
	builder.enable_skinning()

	# A practical skirt to mid-shin hides the upper legs entirely.
	builder.set_bone(skeleton.find_bone("pelvis"))
	builder.color = YATI_SKIRT
	builder.loft([
		_ring(builder, 0.30, 0.185, 0.150), _ring(builder, 0.55, 0.195, 0.158),
		_ring(builder, 0.80, 0.190, 0.150), _ring(builder, 0.90, 0.185, 0.140)])

	builder.set_bone(skeleton.find_bone("spine_lower"))
	builder.color = YATI_BLOUSE
	builder.loft([
		_ring(builder, 0.86, 0.196, 0.150), _ring(builder, 0.95, 0.200, 0.158, -0.008),
		_ring(builder, 1.04, 0.200, 0.152, -0.006), _ring(builder, 1.11, 0.198, 0.140)])
	builder.set_bone(skeleton.find_bone("spine_upper"))
	builder.loft([
		_ring(builder, 1.095, 0.198, 0.140), _ring(builder, 1.19, 0.208, 0.130),
		_ring(builder, 1.255, 0.196, 0.112), _ring(builder, 1.30, 0.088, 0.074)])

	builder.set_bone(skeleton.find_bone("neck"))
	builder.color = YATI_SKIN_SHADE
	builder.tube(Vector3(0, 1.285, 0), Vector3(0, 1.37, 0), 0.052, 0.049, 8)

	# Rounder head than Darto's, with a flat, unimpressed face.
	builder.set_bone(skeleton.find_bone("head"))
	builder.color = YATI_SKIN
	builder.loft([
		_ring(builder, 1.345, 0.072, 0.078, 0.0, 2.8), _ring(builder, 1.385, 0.096, 0.102, 0.0, 2.8),
		_ring(builder, 1.455, 0.105, 0.112, 0.0, 2.8), _ring(builder, 1.525, 0.100, 0.106, 0.0, 2.8),
		_ring(builder, 1.57, 0.070, 0.076, 0.0, 2.8)])
	builder.color = YATI_SKIN_SHADE
	for side: float in [-1.0, 1.0]:
		builder.box(Vector3(0.02, 0.048, 0.028), Vector3(0.108 * side, 1.43, 0.004))
	builder.color = FACE_DARK
	for side: float in [-1.0, 1.0]:
		builder.box(Vector3(0.028, 0.010, 0.012), Vector3(0.042 * side, 1.442, -0.109))
		builder.box(Vector3(0.042, 0.008, 0.012), Vector3(0.043 * side, 1.463, -0.111))
	builder.color = YATI_SKIN_SHADE
	builder.tube(Vector3(0, 1.448, -0.106), Vector3(0, 1.412, -0.13), 0.008, 0.017, 4)
	builder.color = Color("6e4a3a")
	builder.box(Vector3(0.05, 0.006, 0.01), Vector3(0, 1.386, -0.102))

	for side: float in [-1.0, 1.0]:
		var suffix := "_l" if side < 0.0 else "_r"
		var shoulder := Vector3(0.205 * side, 1.262, 0)
		var elbow := Vector3(0.215 * side, 1.01, 0)
		var wrist := Vector3(0.22 * side, 0.80, 0)
		builder.set_bone(skeleton.find_bone("upper_arm" + suffix))
		builder.color = YATI_BLOUSE
		builder.blob(shoulder - Vector3(0.014 * side, 0.028, 0), Vector3(0.064, 0.046, 0.066), 8, 4)
		builder.tube(shoulder - Vector3(0, 0.02, 0), elbow + Vector3(0, 0.03, 0), 0.062, 0.054, 8, true)
		builder.set_bone(skeleton.find_bone("forearm" + suffix))
		builder.color = YATI_SKIN
		builder.tube(elbow + Vector3(0, 0.02, 0), wrist, 0.044, 0.035, 8)
		builder.set_bone(skeleton.find_bone("hand" + suffix))
		builder.box(Vector3(0.062, 0.09, 0.04), Vector3(0.22 * side, 0.755, 0))

		var knee := Vector3(0.095 * side, 0.455, 0)
		var ankle := Vector3(0.095 * side, 0.085, 0)
		builder.set_bone(skeleton.find_bone("shin" + suffix))
		builder.color = YATI_SKIN
		builder.tube(knee - Vector3(0, 0.1, 0), ankle, 0.05, 0.038, 8)
		builder.set_bone(skeleton.find_bone("foot" + suffix))
		builder.box(Vector3(0.082, 0.05, 0.2), Vector3(0.095 * side, 0.05, -0.04))
	return builder.commit()


func _build_bu_yati_accessories(skeleton: Skeleton3D) -> ArrayMesh:
	var builder := MeshBuilder.new()
	builder.enable_skinning()

	# Grey hair pulled back into a bun.
	builder.set_bone(skeleton.find_bone("head"))
	builder.color = YATI_HAIR
	builder.loft([
		_ring(builder, 1.475, 0.110, 0.098, 0.028, 2.8), _ring(builder, 1.535, 0.106, 0.108, 0.012, 2.8),
		_ring(builder, 1.578, 0.076, 0.084, 0.006, 2.8), _ring(builder, 1.592, 0.03, 0.034, 0.004, 2.8)])
	builder.blob(Vector3(0, 1.50, 0.128), Vector3(0.052, 0.05, 0.046), 7, 4)

	# Cream apron over the blouse and skirt, tied at the waist.
	builder.set_bone(skeleton.find_bone("spine_lower"))
	builder.color = YATI_APRON
	builder.box(Vector3(0.25, 0.2, 0.014), Vector3(0, 1.0, -0.158))
	builder.color = YATI_APRON.darkened(0.12)
	builder.loft([_ring(builder, 0.895, 0.203, 0.163), _ring(builder, 0.92, 0.203, 0.163)], false, false)
	builder.set_bone(skeleton.find_bone("pelvis"))
	builder.color = YATI_APRON
	builder.box(Vector3(0.27, 0.42, 0.014), Vector3(0, 0.69, -0.162))
	builder.color = YATI_APRON.darkened(0.1)
	builder.box(Vector3(0.11, 0.1, 0.018), Vector3(0.05, 0.74, -0.168))

	for side: float in [-1.0, 1.0]:
		builder.set_bone(skeleton.find_bone("foot_l" if side < 0.0 else "foot_r"))
		builder.color = YATI_SLIPPER
		builder.box(Vector3(0.098, 0.022, 0.24), Vector3(0.095 * side, 0.011, -0.04))
		builder.color = YATI_SLIPPER.darkened(0.2)
		builder.box(Vector3(0.098, 0.03, 0.09), Vector3(0.095 * side, 0.062, -0.1))
	return builder.commit()


## Bu Yati's clips (GDD 172.8). Small, economical movements only.
func _build_bu_yati_clips(skeleton: Skeleton3D) -> Array:
	var clips: Array = []

	var idle := RigBuilder.Clip.new(skeleton, &"market_idle", 5.0, true)
	_pose_from(idle, COUNTER_POSE, 0.0)
	_pose_from(idle, COUNTER_POSE, 2.5, {"spine_upper": Vector3(-3, 0, 0), "head": Vector3(-3, -4, 0)})
	_pose_from(idle, COUNTER_POSE, 5.0)
	clips.append(idle)

	var look := RigBuilder.Clip.new(skeleton, &"look_darto", 1.2)
	_pose_from(look, COUNTER_POSE, 0.0)
	_pose_from(look, COUNTER_POSE, 0.35, {"head": Vector3(-4, 14, 0), "neck": Vector3(0, 6, 0)})
	_pose_from(look, COUNTER_POSE, 0.9, {"head": Vector3(-4, 14, 0), "neck": Vector3(0, 6, 0)})
	_pose_from(look, COUNTER_POSE, 1.2)
	clips.append(look)

	# One hand to the scale, a glance down, then back.
	var weigh := RigBuilder.Clip.new(skeleton, &"weigh_fish", 1.6)
	_pose_from(weigh, COUNTER_POSE, 0.0)
	_pose_from(weigh, COUNTER_POSE, 0.5, {
		"upper_arm_r": Vector3(46, 0, -4), "forearm_r": Vector3(40, 0, 0), "head": Vector3(-14, -6, 0), "spine_upper": Vector3(-6, 0, 0)})
	_pose_from(weigh, COUNTER_POSE, 1.1, {
		"upper_arm_r": Vector3(46, 0, -4), "forearm_r": Vector3(40, 0, 0), "head": Vector3(-14, -6, 0), "spine_upper": Vector3(-6, 0, 0)})
	_pose_from(weigh, COUNTER_POSE, 1.6)
	clips.append(weigh)

	var count := RigBuilder.Clip.new(skeleton, &"cash_count", 1.4)
	_pose_from(count, COUNTER_POSE, 0.0)
	for step: int in 4:
		var time := 0.25 + 0.25 * float(step)
		var flick := 62.0 if step % 2 == 0 else 50.0
		_pose_from(count, COUNTER_POSE, time, {
			"upper_arm_r": Vector3(34, 0, -2), "forearm_r": Vector3(flick, 0, 0),
			"upper_arm_l": Vector3(34, 0, 2), "forearm_l": Vector3(58, 0, 0), "head": Vector3(-12, 0, 0)})
	_pose_from(count, COUNTER_POSE, 1.4)
	clips.append(count)

	# She has no eyelids to blink with; the deadpan beat is a tiny head settle.
	var blink := RigBuilder.Clip.new(skeleton, &"deadpan_blink", 0.6)
	_pose_from(blink, COUNTER_POSE, 0.0)
	_pose_from(blink, COUNTER_POSE, 0.3, {"head": Vector3(-5, 0, 0)})
	_pose_from(blink, COUNTER_POSE, 0.6)
	clips.append(blink)
	return clips


## Keys a whole body at `time`: a base stance with `changes` on top.
func _pose_from(clip: RefCounted, base: Dictionary, time: float, changes: Dictionary = {}) -> void:
	for bone: String in base:
		clip.rot(bone, time, changes.get(bone, base[bone]))


# --- Darto: boxing (GDD 172.2) ----------------------------------------------

const GLOVE_RED := Color("a4483f")
const GLOVE_CUFF := Color("e9dcc0")
## Guarded but slightly awkward: fists up, knees soft, chin down.
const BOX_GUARD: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-6, 0, 0),
	"spine_upper": Vector3(-8, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(4, 0, 0),
	"upper_arm_r": Vector3(46, 0, 14),
	"forearm_r": Vector3(112, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(54, 0, -12),
	"forearm_l": Vector3(104, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(22, 0, -4),
	"shin_l": Vector3(-30, 0, 0),
	"foot_l": Vector3(8, 0, 0),
	"thigh_r": Vector3(-6, 0, 5),
	"shin_r": Vector3(-22, 0, 0),
	"foot_r": Vector3(22, 0, 0),
}
## Soft knees drop the hips; the root offset keeps the feet on the ground.
const BOX_CROUCH := Vector3(0, -0.045, 0)


## Worn red gloves over both hands. Hidden in the scene file; only the boxing
## scene shows them.
func _build_darto_gloves(skeleton: Skeleton3D) -> ArrayMesh:
	var builder := MeshBuilder.new()
	builder.enable_skinning()
	for side: float in [-1.0, 1.0]:
		builder.set_bone(skeleton.find_bone("hand_l" if side < 0.0 else "hand_r"))
		var x := 0.22 * side
		builder.color = GLOVE_CUFF
		builder.tube(Vector3(x, 0.915, 0), Vector3(x, 0.865, 0), 0.05, 0.056, 8, true)
		builder.color = GLOVE_RED
		builder.blob(Vector3(x, 0.805, -0.008), Vector3(0.072, 0.082, 0.078), 8, 5, 0.04, 23)
		builder.blob(Vector3(x - 0.05 * side, 0.83, -0.035), Vector3(0.034, 0.042, 0.034), 6, 4)
		builder.color = GLOVE_RED.lightened(0.2)
		builder.blob(Vector3(x, 0.765, -0.03), Vector3(0.05, 0.03, 0.045), 6, 3)
	return builder.commit()


func _build_darto_boxing_clips(skeleton: Skeleton3D) -> Array:
	var clips: Array = []

	var idle := RigBuilder.Clip.new(skeleton, &"box_idle", 1.2, true)
	for step: int in 5:
		var down := step % 2 == 1
		_box_pose(idle, 0.3 * float(step), {
			"spine_upper": Vector3(-10 if down else -8, 0, 0),
			"upper_arm_l": Vector3(57 if down else 54, 0, -12), "upper_arm_r": Vector3(49 if down else 46, 0, 14),
		}, Vector3(0, -0.018 if down else 0.0, 0))
	clips.append(idle)

	# A lean from the hips with the head kept level. The lean is reached at
	# `lean_peak`, where the scene can hold it until the punch has passed.
	for side: float in [-1.0, 1.0]:
		var dodge := RigBuilder.Clip.new(skeleton, &"box_dodge_left" if side < 0.0 else &"box_dodge_right", 0.32)
		var lean := {
			"spine_lower": Vector3(-6, 0, -17 * side), "spine_upper": Vector3(-8, 0, -13 * side),
			"head": Vector3(4, 0, 16 * side), "pelvis": Vector3(0, 0, -6 * side),
			"thigh_l": Vector3(22, 0, -4 + 9 * side), "thigh_r": Vector3(-6, 0, 5 + 9 * side),
		}
		_box_pose(dodge, 0.0)
		_box_pose(dodge, 0.10, lean, Vector3(0.24 * side, -0.05, 0))
		_box_pose(dodge, 0.20, lean, Vector3(0.24 * side, -0.05, 0))
		_box_pose(dodge, 0.32)
		dodge.mark(&"lean_peak", 0.10)
		clips.append(dodge)

	# Jab: the lead (left) hand snaps out. Lands at 0.11 s, back by 0.36 s.
	var jab := RigBuilder.Clip.new(skeleton, &"box_jab", 0.36)
	var jab_out := {
		"upper_arm_l": Vector3(92, 0, -4), "forearm_l": Vector3(6, 0, 0),
		"spine_upper": Vector3(-10, -14, 0), "spine_lower": Vector3(-7, -6, 0)}
	_box_pose(jab, 0.0)
	_box_pose(jab, 0.11, jab_out, Vector3(0, 0, -0.05))
	_box_pose(jab, 0.17, jab_out, Vector3(0, 0, -0.05))
	_box_pose(jab, 0.36)
	jab.mark(&"hit_frame", 0.11)
	clips.append(jab)

	# Cross: the rear (right) hand with the whole body behind it. Lands at
	# 0.20 s, back by 0.64 s.
	var cross := RigBuilder.Clip.new(skeleton, &"box_cross", 0.64)
	var cross_load := {
		"upper_arm_r": Vector3(30, 0, 22), "forearm_r": Vector3(124, 0, 0),
		"spine_upper": Vector3(-6, -16, 0)}
	var cross_out := {
		"upper_arm_r": Vector3(94, 0, 2), "forearm_r": Vector3(4, 0, 0),
		"upper_arm_l": Vector3(40, 0, -16), "spine_upper": Vector3(-14, 28, 0),
		"spine_lower": Vector3(-9, 12, 0), "thigh_r": Vector3(4, 0, 5), "shin_r": Vector3(-30, 0, 0)}
	_box_pose(cross, 0.0)
	_box_pose(cross, 0.08, cross_load)
	_box_pose(cross, 0.20, cross_out, Vector3(0, -0.01, -0.12))
	_box_pose(cross, 0.30, cross_out, Vector3(0, -0.01, -0.12))
	_box_pose(cross, 0.64)
	cross.mark(&"hit_frame", 0.20)
	clips.append(cross)

	# Knocked toward his left (a punch from the right) and the mirror of it.
	for side: float in [-1.0, 1.0]:
		var hit := RigBuilder.Clip.new(skeleton, &"box_hit_left" if side < 0.0 else &"box_hit_right", 0.45)
		var rocked := {
			"spine_lower": Vector3(8, 10 * side, -10 * side), "spine_upper": Vector3(10, 16 * side, -8 * side),
			"head": Vector3(-12, 22 * side, -10 * side),
			"upper_arm_l": Vector3(34, 0, -30), "upper_arm_r": Vector3(30, 0, 30),
			"forearm_l": Vector3(70, 0, 0), "forearm_r": Vector3(74, 0, 0)}
		_box_pose(hit, 0.0)
		_box_pose(hit, 0.08, rocked, Vector3(0.10 * side, -0.02, 0.10))
		_box_pose(hit, 0.24, rocked, Vector3(0.12 * side, -0.02, 0.12))
		_box_pose(hit, 0.45)
		clips.append(hit)

	# Down on his back, arms out. The last pose is held.
	var ko := RigBuilder.Clip.new(skeleton, &"box_ko", 1.2)
	var stagger := {
		"spine_lower": Vector3(10, 0, 0), "spine_upper": Vector3(14, 0, 0), "head": Vector3(-16, 0, 0),
		"upper_arm_l": Vector3(20, 0, -34), "upper_arm_r": Vector3(18, 0, 34),
		"forearm_l": Vector3(40, 0, 0), "forearm_r": Vector3(44, 0, 0)}
	var flat := {
		"spine_lower": Vector3(0, 0, 0), "spine_upper": Vector3(0, 0, 0), "head": Vector3(-8, 0, 0),
		"upper_arm_l": Vector3(0, 0, -62), "upper_arm_r": Vector3(0, 0, 62),
		"forearm_l": Vector3(12, 0, 0), "forearm_r": Vector3(12, 0, 0),
		"thigh_l": Vector3(4, 0, -8), "thigh_r": Vector3(-2, 0, 8),
		"shin_l": Vector3(-6, 0, 0), "shin_r": Vector3(-4, 0, 0), "foot_l": Vector3(0, 0, 0), "foot_r": Vector3(0, 0, 0)}
	_box_pose(ko, 0.0)
	_box_pose(ko, 0.3, stagger, Vector3(0, -0.02, 0.14), 14.0)
	_box_pose(ko, 0.75, flat, Vector3(0, 0.13, 0.3), 86.0)
	_box_pose(ko, 0.88, flat, Vector3(0, 0.17, 0.3), 82.0)
	_box_pose(ko, 1.2, flat, Vector3(0, 0.13, 0.3), 86.0)
	clips.append(ko)

	# Understated: the guard comes down and one fist goes up, barely.
	var win := RigBuilder.Clip.new(skeleton, &"box_win", 1.1)
	var relief := {
		"spine_lower": Vector3(-2, 0, 0), "spine_upper": Vector3(-2, 0, 0), "head": Vector3(-6, 0, 0),
		"upper_arm_l": Vector3(8, 0, -8), "forearm_l": Vector3(20, 0, 0),
		"upper_arm_r": Vector3(64, 0, 10), "forearm_r": Vector3(96, 0, 0),
		"thigh_l": Vector3(6, 0, -4), "shin_l": Vector3(-8, 0, 0), "foot_l": Vector3(2, 0, 0),
		"thigh_r": Vector3(-2, 0, 5), "shin_r": Vector3(-6, 0, 0), "foot_r": Vector3(8, 0, 0)}
	_box_pose(win, 0.0)
	_box_pose(win, 0.45, relief, -BOX_CROUCH)
	_box_pose(win, 0.7, relief.merged({"upper_arm_r": Vector3(70, 0, 10), "head": Vector3(-9, 0, 0)}, true), -BOX_CROUCH)
	_box_pose(win, 1.1, relief, -BOX_CROUCH)
	clips.append(win)
	return clips


## Keys the whole body at `time`: the boxing guard with `changes` on top.
## `offset` moves the whole body from the guard position and `tip` pitches it
## backward around the feet (used when he goes down).
func _box_pose(clip: RefCounted, time: float, changes: Dictionary = {}, offset: Vector3 = Vector3.ZERO, tip: float = 0.0) -> void:
	clip.rot("root", time, Vector3(tip, 0, 0))
	clip.move("root", time, BOX_CROUCH + offset)
	for bone: String in BOX_GUARD:
		clip.rot(bone, time, changes.get(bone, BOX_GUARD[bone]))


# --- Darto: arm wrestling (GDD 172.3) ---------------------------------------
# Leaning over the table with his right elbow on the pad. The forearm's lean
# left or right is set by the scene from the match position; these clips are
# the effort in the rest of his body.

const ARM_POSE: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-14, 0, 0),
	"spine_upper": Vector3(-16, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(18, 0, 0),
	"upper_arm_r": Vector3(74, 0, 10),
	"forearm_r": Vector3(150, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(58, 0, -18),
	"forearm_l": Vector3(54, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(18, 0, -4),
	"shin_l": Vector3(-14, 0, 0),
	"foot_l": Vector3(-4, 0, 0),
	"thigh_r": Vector3(-10, 0, 6),
	"shin_r": Vector3(-6, 0, 0),
	"foot_r": Vector3(16, 0, 0),
}
const ARM_DROP := Vector3(0, -0.04, 0)


func _build_darto_arm_clips(skeleton: Skeleton3D) -> Array:
	var clips: Array = []

	var grip := RigBuilder.Clip.new(skeleton, &"arm_idle_grip", 2.0, true)
	_arm_pose(grip, 0.0)
	_arm_pose(grip, 1.0, {"spine_upper": Vector3(-24, 0, 0), "head": Vector3(24, 0, 0)})
	_arm_pose(grip, 2.0)
	clips.append(grip)

	var light := RigBuilder.Clip.new(skeleton, &"arm_push_light", 0.5, true)
	var leaning := {"spine_upper": Vector3(-26, 0, -4), "spine_lower": Vector3(-20, 0, -3), "head": Vector3(18, 0, 4)}
	_arm_pose(light, 0.0, leaning)
	_arm_pose(light, 0.25, leaning.merged({"spine_upper": Vector3(-28, 0, -5)}, true))
	_arm_pose(light, 0.5, leaning)
	clips.append(light)

	# Everything into it: shoulder over the grip, free hand clamped on the table.
	var hard := RigBuilder.Clip.new(skeleton, &"arm_push_hard", 0.2, true)
	var straining := {
		"spine_upper": Vector3(-32, 0, -9), "spine_lower": Vector3(-22, 0, -6), "head": Vector3(10, 0, 8),
		"upper_arm_l": Vector3(54, 0, -8), "forearm_l": Vector3(28, 0, 0),
		"thigh_l": Vector3(24, 0, -4), "shin_l": Vector3(-20, 0, 0)}
	_arm_pose(hard, 0.0, straining)
	_arm_pose(hard, 0.1, straining.merged({"spine_upper": Vector3(-33, 0, -10), "head": Vector3(9, 0, 9)}, true))
	_arm_pose(hard, 0.2, straining)
	clips.append(hard)

	# Out of breath: the body sags while the arm holds on.
	var recover := RigBuilder.Clip.new(skeleton, &"arm_recover", 1.2, true)
	var tired := {"spine_upper": Vector3(-14, 0, 0), "spine_lower": Vector3(-14, 0, 0), "head": Vector3(30, 0, 0),
		"upper_arm_l": Vector3(20, 0, -10), "forearm_l": Vector3(26, 0, 0)}
	_arm_pose(recover, 0.0, tired)
	_arm_pose(recover, 0.6, tired.merged({"spine_upper": Vector3(-12, 0, 0), "head": Vector3(32, 0, 0)}, true))
	_arm_pose(recover, 1.2, tired)
	clips.append(recover)

	var win := RigBuilder.Clip.new(skeleton, &"arm_win", 1.0)
	_arm_pose(win, 0.0)
	var upright := {"spine_upper": Vector3(-6, 0, 0), "spine_lower": Vector3(-6, 0, 0), "head": Vector3(-4, 0, 0),
		"upper_arm_l": Vector3(150, 0, -10), "forearm_l": Vector3(20, 0, 0)}
	_arm_pose(win, 0.5, upright, Vector3(0, 0.03, 0))
	_arm_pose(win, 1.0, upright, Vector3(0, 0.03, 0))
	clips.append(win)

	var lose := RigBuilder.Clip.new(skeleton, &"arm_lose", 1.0)
	_arm_pose(lose, 0.0)
	var slumped := {"spine_upper": Vector3(-34, 0, 0), "spine_lower": Vector3(-26, 0, 0), "head": Vector3(-10, 0, 0),
		"upper_arm_l": Vector3(20, 0, -6), "forearm_l": Vector3(10, 0, 0)}
	_arm_pose(lose, 0.5, slumped, Vector3(0, -0.04, 0))
	_arm_pose(lose, 1.0, slumped, Vector3(0, -0.05, 0))
	clips.append(lose)
	return clips


func _arm_pose(clip: RefCounted, time: float, changes: Dictionary = {}, offset: Vector3 = Vector3.ZERO) -> void:
	clip.rot("root", time, Vector3.ZERO)
	clip.move("root", time, ARM_DROP + offset)
	for bone: String in ARM_POSE:
		clip.rot(bone, time, changes.get(bone, ARM_POSE[bone]))
