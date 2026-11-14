@tool
extends RefCounted
## Generates the six fish as chubby, toy-like diorama fish (VISUAL_STYLE_GUIDE
## 1, 4; GDD 184.7, 185.6-185.11).
##
## Each species keeps its own body profile, fins and colours, so silhouettes
## differ by shape and not just by tint, but every body is plump and smooth,
## with big bead eyes, soft pillowy fins and a hint of pink cheek. The mesh is
## skinned along a spine, so the body bends when the fish swims, flops or
## boxes. Every fish owns boxing gloves and the clips of the universal
## contract (GDD 172.6); clip distances are in body lengths.

const SoftMesh := preload("res://tools/generators/soft_mesh.gd")
const RigBuilder := preload("res://tools/generators/rig_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")
const Kit := preload("res://tools/generators/diorama_kit.gd")
const Style := preload("res://scripts/visual/diorama_style.gd")

const GENERATOR_ID := "fish_builder"
const GENERATOR_VERSION := 2
const SCENE_PATH := "res://generated/scenes/fish/fish_%s.tscn"

const BODY_SEGMENTS := 12
const EYE_WHITE := Style.FLOUR
const EYE_DARK := Style.INK
const MOUTH := Color("7a3b2a")
const GLOVE_RED := Color("c8574a")
const GLOVE_CUFF := Style.FLOUR

## Spine joints along the body, from tail to head, as fractions of body length.
const SPINE: Array = [
	["tail_tip", -0.46], ["tail_base", -0.36], ["body_back", -0.22],
	["body_mid", -0.05], ["body_front", 0.12], ["jaw_or_head", 0.30],
]

## Cross-sections are [x, half_width, half_height, y] in body lengths, listed
## from the snout (+x) to the tail (-x). Fin outlines are in the side plane.
## "eye" is [x, y, radius]: the eye sits on the body surface at (x, y).
const PROFILES: Dictionary = {
	&"catfish_bruiser": {
		"length": 0.72, "squareness": 2.3,
		"top": Color("6b7360"), "belly": Color("e6dcbf"), "fin": Color("545b4a"),
		"sections": [
			[0.52, 0.06, 0.04, -0.005], [0.47, 0.135, 0.075, 0.0], [0.38, 0.175, 0.105, 0.0],
			[0.26, 0.18, 0.12, 0.005], [0.10, 0.155, 0.125, 0.01], [-0.08, 0.125, 0.115, 0.01],
			[-0.25, 0.088, 0.095, 0.008], [-0.38, 0.05, 0.068, 0.005], [-0.46, 0.026, 0.046, 0.0]],
		"tail": [[-0.43, 0.035], [-0.56, 0.11], [-0.62, 0.07], [-0.6, 0.0], [-0.62, -0.07], [-0.56, -0.11], [-0.43, -0.035]],
		"dorsal": [[0.16, 0.11], [0.10, 0.17], [-0.08, 0.16], [-0.30, 0.11], [-0.33, 0.07], [-0.08, 0.1]],
		"anal": [[-0.06, -0.09], [-0.12, -0.14], [-0.32, -0.1], [-0.34, -0.06]],
		"pectoral": [0.20, -0.04, 0.16],
		"eye": [0.40, 0.055, 0.07],
		"whiskers": true, "gloves": true, "brow": true,
	},
	&"tilapia_gym_rat": {
		"length": 0.56, "squareness": 2.0,
		"top": Color("8a9da5"), "belly": Color("efe8da"), "fin": Color("6f838b"),
		"sections": [
			[0.51, 0.03, 0.045, 0.0], [0.45, 0.075, 0.115, 0.0], [0.32, 0.105, 0.195, 0.01],
			[0.12, 0.12, 0.235, 0.01], [-0.08, 0.105, 0.22, 0.01], [-0.26, 0.072, 0.155, 0.0],
			[-0.38, 0.04, 0.085, 0.0], [-0.45, 0.022, 0.058, 0.0]],
		"tail": [[-0.42, 0.05], [-0.58, 0.16], [-0.61, 0.0], [-0.58, -0.16], [-0.42, -0.05]],
		"dorsal": [[0.22, 0.2], [0.14, 0.3], [-0.06, 0.3], [-0.28, 0.23], [-0.32, 0.13], [-0.06, 0.21]],
		"anal": [[-0.10, -0.19], [-0.16, -0.26], [-0.30, -0.18], [-0.32, -0.11]],
		"pectoral": [0.22, -0.06, 0.22],
		"eye": [0.39, 0.06, 0.072],
	},
	&"gourami_shady": {
		"length": 0.58, "squareness": 2.0,
		"top": Color("a5977b"), "belly": Color("f0e3c8"), "fin": Color("8b6f69"),
		"sections": [
			[0.51, 0.03, 0.045, 0.0], [0.44, 0.068, 0.125, 0.0], [0.30, 0.095, 0.225, 0.0],
			[0.10, 0.11, 0.275, 0.0], [-0.12, 0.1, 0.26, 0.0], [-0.30, 0.064, 0.175, 0.0],
			[-0.42, 0.032, 0.08, 0.0], [-0.47, 0.018, 0.052, 0.0]],
		"tail": [[-0.44, 0.05], [-0.56, 0.13], [-0.61, 0.07], [-0.61, -0.07], [-0.56, -0.13], [-0.44, -0.05]],
		"dorsal": [[0.04, 0.26], [-0.06, 0.34], [-0.30, 0.27], [-0.36, 0.15], [-0.10, 0.23]],
		"anal": [[0.10, -0.25], [0.0, -0.34], [-0.32, -0.25], [-0.38, -0.12], [-0.10, -0.23]],
		"pectoral": [0.24, -0.05, 0.2],
		"eye": [0.39, 0.06, 0.068],
	},
	&"carp_golden": {
		"length": 0.62, "squareness": 2.1,
		"top": Color("efae45"), "belly": Color("fbe8b4"), "fin": Color("e07f3c"),
		"sections": [
			[0.51, 0.045, 0.048, -0.01], [0.44, 0.095, 0.105, 0.0], [0.32, 0.135, 0.165, 0.015],
			[0.12, 0.155, 0.205, 0.03], [-0.08, 0.14, 0.19, 0.025], [-0.26, 0.094, 0.135, 0.01],
			[-0.39, 0.047, 0.072, 0.0], [-0.46, 0.025, 0.052, 0.0]],
		"tail": [[-0.43, 0.05], [-0.60, 0.18], [-0.56, 0.0], [-0.60, -0.18], [-0.43, -0.05]],
		"dorsal": [[0.16, 0.22], [0.08, 0.33], [-0.24, 0.23], [-0.28, 0.14], [-0.05, 0.2]],
		"anal": [[-0.14, -0.17], [-0.20, -0.25], [-0.30, -0.16], [-0.30, -0.11]],
		"pectoral": [0.24, -0.08, 0.2],
		"eye": [0.39, 0.05, 0.072],
	},
	&"snakehead_sergeant": {
		"length": 0.76, "squareness": 2.4,
		"top": Color("66704f"), "belly": Color("dcd2b0"), "fin": Color("4f5741"),
		"bands": true,
		"sections": [
			[0.52, 0.05, 0.034, 0.0], [0.46, 0.105, 0.065, 0.0], [0.36, 0.125, 0.085, 0.0],
			[0.18, 0.125, 0.095, 0.0], [-0.05, 0.115, 0.095, 0.0], [-0.25, 0.092, 0.085, 0.0],
			[-0.40, 0.052, 0.062, 0.0], [-0.47, 0.025, 0.042, 0.0]],
		"tail": [[-0.44, 0.035], [-0.57, 0.1], [-0.62, 0.0], [-0.57, -0.1], [-0.44, -0.035]],
		"dorsal": [[0.14, 0.09], [0.10, 0.15], [-0.38, 0.13], [-0.42, 0.06], [-0.10, 0.09]],
		"anal": [[-0.02, -0.09], [-0.06, -0.14], [-0.38, -0.12], [-0.42, -0.06], [-0.10, -0.085]],
		"pectoral": [0.26, -0.035, 0.14],
		"eye": [0.42, 0.04, 0.062],
	},
	&"arowana_don": {
		"length": 0.90, "squareness": 2.0,
		"top": Color("c66a4b"), "belly": Color("f2c584"), "fin": Color("7d332e"),
		"scales": true,
		"sections": [
			[0.51, 0.03, 0.04, 0.035], [0.45, 0.066, 0.088, 0.02], [0.34, 0.088, 0.128, 0.0],
			[0.12, 0.095, 0.142, -0.005], [-0.12, 0.088, 0.137, -0.005], [-0.30, 0.068, 0.112, 0.0],
			[-0.42, 0.042, 0.082, 0.0], [-0.48, 0.021, 0.052, 0.0]],
		"tail": [[-0.45, 0.05], [-0.56, 0.11], [-0.63, 0.0], [-0.56, -0.11], [-0.45, -0.05]],
		"dorsal": [[-0.18, 0.13], [-0.25, 0.2], [-0.45, 0.12], [-0.45, 0.06], [-0.30, 0.11]],
		"anal": [[-0.10, -0.135], [-0.18, -0.21], [-0.45, -0.12], [-0.45, -0.06], [-0.20, -0.12]],
		"pectoral": [0.26, -0.08, 0.16],
		"eye": [0.42, 0.055, 0.056],
	},
}


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	for fish_id: StringName in PROFILES:
		var path := SCENE_PATH % fish_id
		var root := build_fish(fish_id)
		var save_error := GeneratorIo.save_scene(root, path)
		root.free()
		if save_error != OK:
			errors.append("fish_%s: could not save (%s)" % [fish_id, error_string(save_error)])
		else:
			manifest.register("fish_%s" % fish_id, GENERATOR_ID, GENERATOR_VERSION, 0, path)
	return errors


func build_fish(fish_id: StringName) -> Node3D:
	var profile: Dictionary = PROFILES[fish_id]
	var length: float = profile["length"]

	var root := Node3D.new()
	root.name = ("fish_%s" % fish_id).to_pascal_case()

	var skeleton := RigBuilder.make_skeleton(_bone_rows(profile))
	root.add_child(skeleton)

	var body_meshes := Node3D.new()
	body_meshes.name = "BodyMeshes"
	root.add_child(body_meshes)
	body_meshes.add_child(_mesh_instance("Body", _build_body(profile, skeleton)))

	var accessories := Node3D.new()
	accessories.name = "AccessoryMeshes"
	root.add_child(accessories)
	var signature := _build_signature(fish_id, profile, skeleton)
	if signature != null:
		accessories.add_child(_mesh_instance("Signature", signature))
	# Every fish boxes, so every fish has gloves. Scenes hide them until needed.
	accessories.add_child(_mesh_instance("Gloves", _build_gloves(profile, skeleton)))
	root.add_child(Kit.character_shadow(0.3 * length))

	var clips := _build_clips(skeleton, length)
	clips.append_array(_build_boxing_clips(skeleton, fish_id, length))
	clips.append_array(_build_arm_clips(skeleton, fish_id, length))
	clips.append_array(_build_dance_clips(skeleton, fish_id, length))
	clips.append_array(_build_suwit_clips(skeleton, fish_id, length))
	root.add_child(RigBuilder.make_player(clips))
	return root


# --- Rig --------------------------------------------------------------------

func _bone_rows(profile: Dictionary) -> Array:
	var length: float = profile["length"]
	var pectoral: Array = profile["pectoral"]
	var fin_x: float = pectoral[0] * length
	var fin_y: float = pectoral[1] * length
	var fin_z: float = _surface_z(profile, pectoral[0], pectoral[1]) * length
	return [
		["root", "", Vector3.ZERO],
		["body_mid", "root", Vector3(-0.05 * length, 0.0, 0.0)],
		["body_front", "body_mid", Vector3(0.12 * length, 0.0, 0.0)],
		["jaw_or_head", "body_front", Vector3(0.30 * length, 0.0, 0.0)],
		["fin_left", "body_front", Vector3(fin_x, fin_y, -fin_z)],
		["fin_right", "body_front", Vector3(fin_x, fin_y, fin_z)],
		["body_back", "body_mid", Vector3(-0.22 * length, 0.0, 0.0)],
		["tail_base", "body_back", Vector3(-0.36 * length, 0.0, 0.0)],
		["tail_tip", "tail_base", Vector3(-0.46 * length, 0.0, 0.0)],
	]


func _mesh_instance(node_name: String, mesh: ArrayMesh) -> MeshInstance3D:
	var instance := Kit.mesh_instance(node_name, mesh)
	instance.skeleton = NodePath("../../Skeleton3D")
	return instance


# --- Body -------------------------------------------------------------------

func _build_body(profile: Dictionary, skeleton: Skeleton3D) -> ArrayMesh:
	var length: float = profile["length"]
	var top: Color = profile["top"]
	var belly: Color = profile["belly"]
	var fin: Color = profile["fin"]
	var builder := SoftMesh.new()
	builder.enable_skinning()
	builder.select_surface(MaterialBuilder.SURFACE_ROUND)

	var spine_bones := PackedInt32Array()
	var spine_stops := PackedFloat32Array()
	for joint: Array in SPINE:
		spine_bones.append(skeleton.find_bone(joint[0]))
		spine_stops.append(float(joint[1]) * length)
	builder.set_spine(spine_bones, spine_stops, Vector3.RIGHT)

	# Back colour above, belly colour below, with soft markings.
	var sections := _resample(profile["sections"])
	var max_height := 0.0
	for section: Array in sections:
		max_height = maxf(max_height, section[2])
	builder.color_rule = func(point: Vector3, _base: Color) -> Color:
		var height := point.y / (max_height * length)
		var shade := top.lerp(belly, smoothstep(0.15, -0.5, height))
		if profile.get("bands", false) and height > -0.25 and sin(point.x / length * 40.0) > 0.45:
			shade = shade.darkened(0.16)
		if profile.get("scales", false) and height > -0.35:
			var row := int(floor(point.x / length * 14.0))
			var column := int(floor(point.y / length * 14.0 + 0.5 * float(row % 2)))
			if (row + column) % 2 == 0:
				shade = shade.lightened(0.1)
		return shade

	var rings: Array = []
	for section: Array in sections:
		var centre := Vector3(section[0], section[3], 0.0) * length
		rings.append(builder.ring(
			centre, Vector3(0.0, 0.0, section[1] * length), Vector3(0.0, section[2] * length, 0.0),
			BODY_SEGMENTS, profile["squareness"]))
	var first: Array = sections[0]
	var last: Array = sections[sections.size() - 1]
	builder.loft(rings,
		Vector3(float(first[0]) + 0.025, first[3], 0.0) * length,
		Vector3(float(last[0]) - 0.02, last[3], 0.0) * length)
	builder.color_rule = Callable()

	# Fins follow the spine so they bend with the body.
	builder.color = fin
	var fin_thickness := 0.032 * length
	for fin_name: String in ["tail", "dorsal", "anal"]:
		if profile.has(fin_name):
			builder.puffy_outline(_outline(profile[fin_name], length), fin_thickness)

	_add_pectoral_fins(builder, profile, skeleton)
	_add_face(builder, profile, skeleton)
	if profile.get("whiskers", false):
		_add_whiskers(builder, length, skeleton, fin)
	return builder.commit(MaterialBuilder.surface_materials())


## Round paddle fins at the shoulders: the fish's arms.
func _add_pectoral_fins(builder: RefCounted, profile: Dictionary, skeleton: Skeleton3D) -> void:
	var length: float = profile["length"]
	var pectoral: Array = profile["pectoral"]
	var span: float = pectoral[2] * length
	var outline := PackedVector2Array()
	for step: int in 9:
		var angle := TAU * float(step) / 9.0
		outline.append(Vector2(0.55 * span + cos(angle) * 0.5 * span, sin(angle) * 0.34 * span))
	builder.color = profile["fin"]
	for side: float in [-1.0, 1.0]:
		var bone := "fin_left" if side < 0.0 else "fin_right"
		builder.set_bone(skeleton.find_bone(bone))
		var root := Vector3(pectoral[0] * length, pectoral[1] * length, _surface_z(profile, pectoral[0], pectoral[1]) * length * side)
		# The outline's X runs outward and slightly down; its Y runs forward.
		var outward := Vector3(0.0, -0.35, side).normalized()
		var forward := Vector3(1.0, 0.0, 0.0)
		builder.transform = Transform3D(Basis(outward, forward, outward.cross(forward)), root)
		builder.puffy_outline(outline, 0.04 * length)
	builder.transform = Transform3D.IDENTITY


## Big bead eyes with a white rim and a highlight, a soft mouth line and a
## touch of pink cheek (guide 9.1, applied to the fish).
func _add_face(builder: RefCounted, profile: Dictionary, skeleton: Skeleton3D) -> void:
	var length: float = profile["length"]
	var eye: Array = profile["eye"]
	var radius: float = eye[2] * length
	builder.set_bone(skeleton.find_bone("jaw_or_head"))
	for side: float in [-1.0, 1.0]:
		var surface := Vector3(eye[0], eye[1], _surface_z(profile, eye[0], eye[1]) * side) * length
		var outward := Vector3(0.15, 0.1, side).normalized()
		var centre := surface - outward * radius * 0.3
		builder.color = EYE_WHITE
		builder.sphere(centre, Vector3(radius, radius, radius * 0.75), 8, 4)
		builder.color = EYE_DARK
		var pupil := centre + outward * radius * 0.42 + Vector3(0.12, 0.0, 0.0) * radius
		builder.sphere(pupil, Vector3(radius, radius, radius * 0.7) * 0.68, 8, 4)
		builder.color = Style.EYE_SHINE
		builder.sphere(pupil + outward * radius * 0.42 + Vector3(0.18, 0.26, 0.0) * radius, Vector3.ONE * radius * 0.2, 6, 3)
		if profile.get("brow", false):
			# A heavy lid over the eye, lower toward the middle: unimpressed
			# and tough, not evil.
			builder.color = (profile["top"] as Color).darkened(0.2)
			var lid := centre + Vector3(0.0, radius * 0.72, 0.0) + outward * radius * 0.25
			builder.capsule(lid + Vector3(radius * 0.85, -radius * 0.22, 0.0), lid + Vector3(-radius * 0.85, radius * 0.12, 0.0), radius * 0.28, -1.0, 8, 2)
		builder.color = Style.BLUSH
		var cheek := Vector3(float(eye[0]) - 0.035, float(eye[1]) - 0.075, 0.0)
		var cheek_surface := Vector3(cheek.x, cheek.y, _surface_z(profile, cheek.x, cheek.y) * side) * length
		builder.sphere(cheek_surface, Vector3(radius * 0.55, radius * 0.32, radius * 0.4), 8, 3)

	# A soft mouth line wrapped round the snout.
	var front: Array = _section_at(profile, 0.47)
	var mouth_y := float(front[3]) - float(front[2]) * 0.3
	var mouth_x := 0.475
	var reach := _surface_z(profile, mouth_x, mouth_y) * 0.92
	builder.color = MOUTH
	builder.capsule(Vector3(mouth_x, mouth_y, -reach) * length, Vector3(mouth_x + 0.03, mouth_y + 0.004, 0.0) * length, 0.009 * length, -1.0, 4, 1)
	builder.capsule(Vector3(mouth_x + 0.03, mouth_y + 0.004, 0.0) * length, Vector3(mouth_x, mouth_y, reach) * length, 0.009 * length, -1.0, 4, 1)


## Four pairs of soft barbels (GDD 185.6): long maxillary, short nasal, two chin pairs.
func _add_whiskers(builder: RefCounted, length: float, skeleton: Skeleton3D, tint: Color) -> void:
	var paths: Array = [
		[Vector3(0.47, -0.010, 0.09), Vector3(0.52, -0.020, 0.22), Vector3(0.44, -0.06, 0.34), 0.012],
		[Vector3(0.49, 0.022, 0.04), Vector3(0.54, 0.066, 0.07), Vector3(0.56, 0.11, 0.09), 0.009],
		[Vector3(0.45, -0.04, 0.07), Vector3(0.48, -0.09, 0.12), Vector3(0.43, -0.135, 0.155), 0.009],
		[Vector3(0.465, -0.042, 0.03), Vector3(0.495, -0.088, 0.04), Vector3(0.48, -0.13, 0.05), 0.008],
	]
	builder.set_bone(skeleton.find_bone("jaw_or_head"))
	builder.color = tint.darkened(0.1)
	for path: Array in paths:
		for side: float in [-1.0, 1.0]:
			var mirror := Vector3(1.0, 1.0, side)
			var start: Vector3 = path[0] * mirror * length
			var middle: Vector3 = path[1] * mirror * length
			var tip: Vector3 = path[2] * mirror * length
			var radius: float = path[3] * length
			builder.capsule(start, middle, radius, radius * 0.75, 4, 1)
			builder.capsule(middle, tip, radius * 0.75, radius * 0.45, 4, 1)


## Worn red boxing gloves on the pectoral fins: a big round fist and a cuff.
func _build_gloves(profile: Dictionary, skeleton: Skeleton3D) -> ArrayMesh:
	var length: float = profile["length"]
	var pectoral: Array = profile["pectoral"]
	var span: float = pectoral[2] * length
	var builder := SoftMesh.new()
	builder.enable_skinning()
	builder.select_surface(MaterialBuilder.SURFACE_ROUND)
	for side: float in [-1.0, 1.0]:
		builder.set_bone(skeleton.find_bone("fin_left" if side < 0.0 else "fin_right"))
		var base := Vector3(pectoral[0] * length, pectoral[1] * length, _surface_z(profile, pectoral[0], pectoral[1]) * length * side)
		var outward := Vector3(0.0, -0.35, side).normalized()
		var wrist := base + outward * span * 0.55
		var fist := base + outward * span * 1.0
		var size := 0.085 * length
		builder.color = GLOVE_CUFF
		builder.capsule(wrist, wrist + outward * size * 0.4, size * 0.62, size * 0.7, 8, 1)
		builder.color = GLOVE_RED
		builder.sphere(fist, Vector3(1.05, 1.0, 0.95) * size, 10, 5)
		builder.sphere(fist + Vector3(0.75, 0.25, -0.2 * side) * size, Vector3(0.45, 0.42, 0.42) * size, 8, 4)
		# A lighter worn patch on the knuckles.
		builder.color = GLOVE_RED.lightened(0.22)
		builder.sphere(fist + Vector3(0.45, 0.55, 0.3 * side) * size, Vector3(0.42, 0.3, 0.42) * size, 8, 3)
	return builder.commit(MaterialBuilder.surface_materials())


## Half-width of the body at (x, y) on its surface, in body lengths.
func _surface_z(profile: Dictionary, x: float, y: float) -> float:
	var section := _section_at(profile, x)
	var half_width: float = section[1]
	var half_height: float = section[2]
	var v := clampf((y - float(section[3])) / maxf(half_height, 0.0001), -1.0, 1.0)
	var exponent: float = profile["squareness"]
	return half_width * pow(maxf(1.0 - pow(absf(v), exponent), 0.0), 1.0 / exponent)


# --- Animation --------------------------------------------------------------

## The fishing-phase clips of the universal fish contract (GDD 172.6).
## The clips of each duel are added by the milestone that builds it.
func _build_clips(skeleton: Skeleton3D, length: float) -> Array:
	var clips: Array = []

	var idle := RigBuilder.Clip.new(skeleton, &"fish_idle_water", 2.4, true)
	_sway(idle, 2.4, 1, 7.0, 12.0, 16.0)
	idle.rot("fin_left", 0.0, Vector3(0, 0, -8)).rot("fin_left", 1.2, Vector3(0, 0, 10)).rot("fin_left", 2.4, Vector3(0, 0, -8))
	idle.rot("fin_right", 0.0, Vector3(0, 0, 8)).rot("fin_right", 1.2, Vector3(0, 0, -10)).rot("fin_right", 2.4, Vector3(0, 0, 8))
	clips.append(idle)

	var hooked := RigBuilder.Clip.new(skeleton, &"fish_hooked_pull", 0.6, true)
	_sway(hooked, 0.6, 2, 16.0, 26.0, 34.0)
	hooked.rot("body_front", 0.0, Vector3(0, -9, 0)).rot("body_front", 0.15, Vector3(0, 9, 0)).rot("body_front", 0.3, Vector3(0, -9, 0))
	hooked.rot("body_front", 0.45, Vector3(0, 9, 0)).rot("body_front", 0.6, Vector3(0, -9, 0))
	clips.append(hooked)

	# Out of the water: two flops on the bank, then still.
	var flop := RigBuilder.Clip.new(skeleton, &"fish_land_flop", 1.1)
	flop.move("root", 0.0, Vector3.ZERO).move("root", 0.18, Vector3(0, 0.22, 0) * length).move("root", 0.36, Vector3.ZERO)
	flop.move("root", 0.54, Vector3(0, 0.12, 0) * length).move("root", 0.72, Vector3.ZERO).move("root", 1.1, Vector3.ZERO)
	flop.rot("root", 0.0, Vector3(0, 0, 0)).rot("root", 0.18, Vector3(35, 0, 14)).rot("root", 0.36, Vector3(70, 0, 0))
	flop.rot("root", 0.54, Vector3(82, 0, -8)).rot("root", 0.72, Vector3(90, 0, 0)).rot("root", 1.1, Vector3(90, 0, 0))
	flop.rot("tail_base", 0.0, Vector3(0, 0, 0)).rot("tail_base", 0.18, Vector3(0, 34, 0)).rot("tail_base", 0.36, Vector3(0, -30, 0))
	flop.rot("tail_base", 0.54, Vector3(0, 22, 0)).rot("tail_base", 0.72, Vector3(0, -10, 0)).rot("tail_base", 1.1, Vector3(0, 0, 0))
	clips.append(flop)

	# The fish rears up on its tail and squares its fins.
	var challenge := RigBuilder.Clip.new(skeleton, &"fish_challenge", 1.6)
	challenge.rot("root", 0.0, Vector3(0, 0, 0)).rot("root", 0.5, Vector3(0, 0, 96)).rot("root", 0.75, Vector3(0, 0, 80)).rot("root", 1.6, Vector3(0, 0, 84))
	challenge.move("root", 0.0, Vector3.ZERO).move("root", 0.5, Vector3(0, 0.50, 0) * length).move("root", 1.6, Vector3(0, 0.46, 0) * length)
	challenge.rot("body_back", 0.0, Vector3(0, 0, 0)).rot("body_back", 0.5, Vector3(0, 0, -16)).rot("body_back", 1.6, Vector3(0, 0, -12))
	challenge.rot("tail_base", 0.0, Vector3(0, 0, 0)).rot("tail_base", 0.5, Vector3(0, 0, -34)).rot("tail_base", 1.6, Vector3(0, 0, -30))
	challenge.rot("fin_left", 0.0, Vector3(0, 0, 0)).rot("fin_left", 0.6, Vector3(0, -30, 0)).rot("fin_left", 0.9, Vector3(0, -72, 0)).rot("fin_left", 1.6, Vector3(0, -64, 0))
	challenge.rot("fin_right", 0.0, Vector3(0, 0, 0)).rot("fin_right", 0.6, Vector3(0, 30, 0)).rot("fin_right", 0.9, Vector3(0, 72, 0)).rot("fin_right", 1.6, Vector3(0, 64, 0))
	challenge.rot("jaw_or_head", 0.0, Vector3(0, 0, 0)).rot("jaw_or_head", 0.9, Vector3(0, 0, -14)).rot("jaw_or_head", 1.6, Vector3(0, 0, -10))
	clips.append(challenge)

	var defeat := RigBuilder.Clip.new(skeleton, &"fish_bucket_defeat", 1.0)
	defeat.rot("root", 0.0, Vector3(0, 0, 0)).rot("root", 0.4, Vector3(0, 0, -30)).rot("root", 1.0, Vector3(0, 0, -78))
	defeat.rot("tail_base", 0.0, Vector3(0, 0, 0)).rot("tail_base", 0.5, Vector3(0, 0, 18)).rot("tail_base", 1.0, Vector3(0, 0, 8))
	defeat.rot("jaw_or_head", 0.0, Vector3(0, 0, 0)).rot("jaw_or_head", 1.0, Vector3(0, 0, -12))
	clips.append(defeat)

	# One arc back into the lake.
	var escape := RigBuilder.Clip.new(skeleton, &"fish_escape_jump", 1.0)
	escape.move("root", 0.0, Vector3.ZERO).move("root", 0.35, Vector3(0.7, 0.75, 0) * length)
	escape.move("root", 0.7, Vector3(1.6, 0.55, 0) * length).move("root", 1.0, Vector3(2.4, -0.5, 0) * length)
	escape.rot("root", 0.0, Vector3(0, 0, 50)).rot("root", 0.35, Vector3(0, 0, 12)).rot("root", 0.7, Vector3(0, 0, -32)).rot("root", 1.0, Vector3(0, 0, -70))
	escape.rot("tail_base", 0.0, Vector3(0, 28, 0)).rot("tail_base", 0.25, Vector3(0, -28, 0)).rot("tail_base", 0.5, Vector3(0, 28, 0))
	escape.rot("tail_base", 0.75, Vector3(0, -28, 0)).rot("tail_base", 1.0, Vector3(0, 0, 0))
	clips.append(escape)
	return clips


## A travelling S-wave down the spine; amplitudes are in degrees.
func _sway(clip: RefCounted, duration: float, cycles: int, back: float, base: float, tip: float) -> void:
	var steps := cycles * 4
	for step: int in steps + 1:
		var time := duration * float(step) / float(steps)
		var phase := TAU * float(step) / 4.0
		clip.rot("body_back", time, Vector3(0, sin(phase) * back, 0))
		clip.rot("tail_base", time, Vector3(0, sin(phase - 0.9) * base, 0))
		clip.rot("tail_tip", time, Vector3(0, sin(phase - 1.8) * tip, 0))


# --- Helpers ----------------------------------------------------------------

func _outline(points: Array, length: float) -> PackedVector2Array:
	var outline := PackedVector2Array()
	for point: Array in points:
		outline.append(Vector2(point[0], point[1]) * length)
	return outline


## Doubles the cross-sections with a smooth curve through the given ones.
func _resample(sections: Array) -> Array:
	var result: Array = []
	for index: int in sections.size() - 1:
		var before: Array = sections[maxi(index - 1, 0)]
		var from: Array = sections[index]
		var to: Array = sections[index + 1]
		var after: Array = sections[mini(index + 2, sections.size() - 1)]
		result.append(from)
		var middle: Array = []
		for field: int in 4:
			middle.append(cubic_interpolate(float(from[field]), float(to[field]), float(before[field]), float(after[field]), 0.5))
		# Overshoot can make a radius negative near the tips; keep it sane.
		middle[1] = maxf(middle[1], minf(from[1], to[1]))
		middle[2] = maxf(middle[2], minf(from[2], to[2]))
		result.append(middle)
	result.append(sections[sections.size() - 1])
	return result


# --- Boxing clips (GDD 49, 172.6, 172.7) ------------------------------------
# A boxing fish stands on its tail with its belly toward Darto. In that stance
# node +X points at the opponent, +Y is up and the fins are the arms: fin_left
# is on -Z, fin_right on +Z.
#
# Attack clips run on a normalized clock: the telegraph fills 0.0 to 1.0 and
# is played at 1 / FishData.boxing_telegraph_sec, so every species shows the
# same wind-up over its own telegraph time. After the impact the clip runs at
# normal speed.

const STAND_PITCH := 84.0
const ATTACK_IMPACT_TIME := 1.0
const ATTACK_CLIP_LENGTH := 1.5
const MIRROR_SUFFIX := "_mirror"
## Guard: tail curled as a foot, head tipped at the opponent, gloves up.
const BOX_GUARD: Dictionary = {
	"body_mid": Vector3(0, 0, 0),
	"body_front": Vector3(0, 0, 0),
	"jaw_or_head": Vector3(0, 0, -10),
	"body_back": Vector3(0, 0, -12),
	"tail_base": Vector3(0, 0, -30),
	"tail_tip": Vector3(0, 0, 0),
	"fin_left": Vector3(0, -64, 0),
	"fin_right": Vector3(0, 64, 0),
}
## Species signature (GDD 172.7): [seconds per bounce, bounce height in body
## lengths, sway in degrees]. Tilapia bounces fast, Arowana barely moves.
const BOX_STYLE: Dictionary = {
	&"catfish_bruiser": [1.0, 0.030, 4.0],
	&"tilapia_gym_rat": [0.6, 0.050, 6.0],
	&"gourami_shady": [1.6, 0.012, 2.0],
	&"carp_golden": [1.4, 0.022, 3.0],
	&"snakehead_sergeant": [0.8, 0.020, 1.5],
	&"arowana_don": [2.0, 0.010, 1.5],
}


func _build_boxing_clips(skeleton: Skeleton3D, fish_id: StringName, length: float) -> Array:
	var clips: Array = []
	var style: Array = BOX_STYLE[fish_id]
	var period: float = style[0]
	var bounce: float = style[1]
	var sway: float = style[2]

	# Two bounces per loop, swaying once to each side.
	var idle := RigBuilder.Clip.new(skeleton, &"box_idle", period * 2.0, true)
	var lifts: Array[float] = [0.0, bounce, 0.0, bounce, 0.0]
	var leans: Array[float] = [0.0, sway, 0.0, -sway, 0.0]
	for step: int in 5:
		var up := lifts[step] > 0.0
		_box_pose(idle, length, period * 0.5 * float(step), Vector3(leans[step], 0, STAND_PITCH), Vector3(0, lifts[step], 0), {
			"fin_left": Vector3(0, -70 if up else -64, 0), "fin_right": Vector3(0, 70 if up else 64, 0),
			"tail_base": Vector3(0, 0, -36 if up else -30)})
	clips.append(idle)

	for variant: String in ["a", "b", "c"]:
		clips.append(_attack_clip(skeleton, length, variant, 1.0))
		clips.append(_attack_clip(skeleton, length, variant, -1.0))

	# Both gloves in front of the face, a small lean away.
	var block := RigBuilder.Clip.new(skeleton, &"box_block", 0.3)
	_box_pose(block, length, 0.0)
	_box_pose(block, length, 0.08, Vector3(0, 0, 88), Vector3(-0.03, 0, 0), {
		"fin_left": Vector3(-38, -76, 0), "fin_right": Vector3(38, 76, 0), "jaw_or_head": Vector3(0, 0, -16)})
	_box_pose(block, length, 0.18, Vector3(0, 0, 88), Vector3(-0.03, 0, 0), {
		"fin_left": Vector3(-38, -76, 0), "fin_right": Vector3(38, 76, 0), "jaw_or_head": Vector3(0, 0, -16)})
	_box_pose(block, length, 0.3)
	clips.append(block)

	# Rocked back on its tail, head snapping away, gloves flung wide.
	var hit := RigBuilder.Clip.new(skeleton, &"box_hit", 0.4)
	_box_pose(hit, length, 0.0)
	_box_pose(hit, length, 0.08, Vector3(0, 0, 106), Vector3(-0.10, 0.01, 0), {
		"fin_left": Vector3(22, -28, 0), "fin_right": Vector3(-22, 28, 0),
		"jaw_or_head": Vector3(0, 0, 12), "body_back": Vector3(0, 0, -24)})
	_box_pose(hit, length, 0.22, Vector3(0, 0, 96), Vector3(-0.06, 0, 0), {
		"fin_left": Vector3(10, -46, 0), "fin_right": Vector3(-10, 46, 0), "jaw_or_head": Vector3(0, 0, 2)})
	_box_pose(hit, length, 0.4)
	clips.append(hit)

	# Down: one stagger, then flat on its back with the gloves limp.
	var ko := RigBuilder.Clip.new(skeleton, &"box_ko", 1.2)
	_box_pose(ko, length, 0.0)
	_box_pose(ko, length, 0.22, Vector3(8, 0, 112), Vector3(-0.08, 0.04, 0), {
		"fin_left": Vector3(18, -30, 0), "fin_right": Vector3(-18, 30, 0), "jaw_or_head": Vector3(0, 0, 14)})
	_box_pose(ko, length, 0.5, Vector3(-6, 0, 96), Vector3(-0.04, 0.0, 0), {
		"fin_left": Vector3(0, -40, 0), "fin_right": Vector3(0, 40, 0)})
	var down := {
		"fin_left": Vector3(0, -12, 0), "fin_right": Vector3(0, 12, 0), "jaw_or_head": Vector3(0, 0, 6),
		"body_back": Vector3(0, 0, 4), "tail_base": Vector3(0, 0, 14)}
	_box_pose(ko, length, 0.85, Vector3(0, 0, 174), Vector3(-0.36, -0.34, 0), down)
	_box_pose(ko, length, 0.95, Vector3(0, 0, 168), Vector3(-0.36, -0.31, 0), down)
	_box_pose(ko, length, 1.2, Vector3(0, 0, 174), Vector3(-0.36, -0.35, 0), down)
	clips.append(ko)
	return clips


## One attack. `side` +1 is the clip for a "dodge left" attack: the glove on
## the player's right (fin_left) winds up and the head tips toward it, then
## the whole fish lunges. `side` -1 is the mirror image. The wind-up pose is
## reached early and held, so the direction is readable for the whole
## telegraph (GDD 176.14).
func _attack_clip(skeleton: Skeleton3D, length: float, variant: String, side: float) -> RefCounted:
	var clip_name := "box_attack_%s%s" % [variant, "" if side > 0.0 else MIRROR_SUFFIX]
	var clip := RigBuilder.Clip.new(skeleton, StringName(clip_name), ATTACK_CLIP_LENGTH)
	var punching := "fin_left" if side > 0.0 else "fin_right"

	# [root rotation, root offset, punching fin, head] for wind-up and strike,
	# written for side +1.
	var wind_up: Array
	var strike: Array
	match variant:
		"a":  # straight
			wind_up = [Vector3(-14, 20, 88), Vector3(-0.06, 0.04, 0.02), Vector3(26, -82, 0), Vector3(0, 0, -4)]
			strike = [Vector3(6, -25, 70), Vector3(0.30, -0.02, -0.08), Vector3(-85, -10, 0), Vector3(0, 0, -18)]
		"b":  # hook
			wind_up = [Vector3(-10, 38, 86), Vector3(-0.04, 0.02, 0.05), Vector3(10, -22, 0), Vector3(0, 0, -6)]
			strike = [Vector3(10, -40, 76), Vector3(0.24, 0.0, -0.14), Vector3(-60, -32, 0), Vector3(0, 0, -16)]
		_:  # overhead
			wind_up = [Vector3(-12, 8, 98), Vector3(-0.05, 0.16, 0.02), Vector3(0, -112, 0), Vector3(0, 0, 4)]
			strike = [Vector3(4, -10, 56), Vector3(0.28, -0.06, -0.08), Vector3(-70, -42, 0), Vector3(0, 0, -22)]

	_box_pose(clip, length, 0.0)
	for time: float in [0.25, 0.8]:
		# A slow creep further into the wind-up keeps the hold alive.
		var creep := 1.0 if time < 0.5 else 1.15
		_box_pose(clip, length, time, _side_rot(wind_up[0] * Vector3(creep, creep, 1.0), side), _side_offset(wind_up[1], side), {
			punching: _fin_rot(wind_up[2], side), "jaw_or_head": wind_up[3]})
	for time: float in [ATTACK_IMPACT_TIME, 1.15]:
		_box_pose(clip, length, time, _side_rot(strike[0], side), _side_offset(strike[1], side), {
			punching: _fin_rot(strike[2], side), "jaw_or_head": strike[3]})
	_box_pose(clip, length, ATTACK_CLIP_LENGTH)
	clip.mark(&"telegraph_start", 0.0).mark(&"impact", ATTACK_IMPACT_TIME).mark(&"recovery_end", ATTACK_CLIP_LENGTH)
	return clip


## Keys the whole fish at `time`: the guard with `changes` on top.
func _box_pose(clip: RefCounted, length: float, time: float, root_rotation: Vector3 = Vector3(0, 0, STAND_PITCH), root_offset: Vector3 = Vector3.ZERO, changes: Dictionary = {}) -> void:
	clip.rot("root", time, root_rotation)
	clip.move("root", time, (Vector3(0, 0.46, 0) + root_offset) * length)
	for bone: String in BOX_GUARD:
		clip.rot(bone, time, changes.get(bone, BOX_GUARD[bone]))


## Mirrors a root rotation: lean and twist flip, the upright pitch does not.
func _side_rot(rotation: Vector3, side: float) -> Vector3:
	return Vector3(rotation.x * side, rotation.y * side, rotation.z)


func _side_offset(offset: Vector3, side: float) -> Vector3:
	return Vector3(offset.x, offset.y, offset.z * side)


## Fin angles are written for the left fin; the right fin is its mirror.
func _fin_rot(rotation: Vector3, side: float) -> Vector3:
	return Vector3(rotation.x * side, rotation.y * side, rotation.z)


# --- Arm wrestling clips (GDD 172.6) ----------------------------------------
# The fish stands on its tail on the table, belly toward Darto (+X), and
# grips with fin_left. How far the hands lean is applied by the scene; these
# clips are the body around it.

const ARM_GRIP_FIN := Vector3(-58, -34, 0)


func _build_arm_clips(skeleton: Skeleton3D, fish_id: StringName, length: float) -> Array:
	var clips: Array = []
	var style: Array = BOX_STYLE[fish_id]
	var sway: float = style[2]

	var idle := RigBuilder.Clip.new(skeleton, &"arm_idle", 1.6, true)
	for step: int in 5:
		var strain := 1.0 if step % 2 == 1 else 0.0
		_box_pose(idle, length, 0.4 * float(step), Vector3(sway * 0.5 * strain, 0, STAND_PITCH - 6.0), Vector3(0.02, 0, 0), {
			"fin_left": ARM_GRIP_FIN + Vector3(0, 0, 3 * strain), "fin_right": Vector3(0, 40, 0),
			"jaw_or_head": Vector3(0, 0, -14 - 3 * strain), "tail_base": Vector3(0, 0, -34)})
	clips.append(idle)

	# The burst: it hunches over the grip, tail braced, and trembles.
	var burst := RigBuilder.Clip.new(skeleton, &"arm_burst", 0.24, true)
	for step: int in 4:
		var shake := 1.5 if step % 2 == 1 else -1.5
		_box_pose(burst, length, 0.08 * float(step), Vector3(shake, 0, STAND_PITCH - 22.0), Vector3(0.07, -0.03, 0), {
			"fin_left": ARM_GRIP_FIN + Vector3(-10, 6, 0), "fin_right": Vector3(-20, 70, 0),
			"jaw_or_head": Vector3(0, 0, -26), "body_back": Vector3(0, 0, -22), "tail_base": Vector3(0, 0, -46)})
	clips.append(burst)

	# Won: it straightens, the gripping fin goes up.
	var win := RigBuilder.Clip.new(skeleton, &"arm_win", 1.0)
	_box_pose(win, length, 0.0, Vector3(0, 0, STAND_PITCH - 6.0), Vector3.ZERO, {"fin_left": ARM_GRIP_FIN})
	var proud := {"fin_left": Vector3(0, -120, 0), "fin_right": Vector3(0, 50, 0), "jaw_or_head": Vector3(0, 0, 8)}
	_box_pose(win, length, 0.4, Vector3(0, 0, STAND_PITCH + 6.0), Vector3(-0.02, 0.04, 0), proud)
	_box_pose(win, length, 1.0, Vector3(0, 0, STAND_PITCH + 4.0), Vector3(-0.02, 0.03, 0), proud)
	clips.append(win)

	# Lost: pinned, it slumps over sideways onto the table.
	var lose := RigBuilder.Clip.new(skeleton, &"arm_lose", 1.0)
	_box_pose(lose, length, 0.0, Vector3(0, 0, STAND_PITCH - 6.0), Vector3.ZERO, {"fin_left": ARM_GRIP_FIN})
	var slump := {"fin_left": Vector3(-30, -20, 0), "fin_right": Vector3(0, 20, 0), "jaw_or_head": Vector3(0, 0, 10), "tail_base": Vector3(0, 0, 10)}
	_box_pose(lose, length, 0.5, Vector3(-60, 0, STAND_PITCH - 10.0), Vector3(0, -0.2, 0.1), slump)
	_box_pose(lose, length, 1.0, Vector3(-82, 0, STAND_PITCH - 12.0), Vector3(0, -0.33, 0.12), slump)
	clips.append(lose)
	return clips


# --- Dance clips (GDD 172.6) ------------------------------------------------
# The fish stands on its tail facing the audience. The better the judgment,
# the bigger the move: GOOD is a fin wave, GREAT a twist, PERFECT a hop.

func _build_dance_clips(skeleton: Skeleton3D, fish_id: StringName, length: float) -> Array:
	var clips: Array = []
	var style: Array = BOX_STYLE[fish_id]
	var sway: float = style[2]

	# One loop is two beats at 120 BPM; the scene scales it to the song.
	var idle := RigBuilder.Clip.new(skeleton, &"dance_idle", 1.0, true)
	for step: int in 5:
		var up := step % 2 == 1
		_box_pose(idle, length, 0.25 * float(step), Vector3((sway + 6.0) * (1.0 if step == 1 else -1.0 if step == 3 else 0.0), 0, STAND_PITCH),
			Vector3(0, 0.04 if up else 0.0, 0), {
				"fin_left": Vector3(0, -40 if up else -20, 0), "fin_right": Vector3(0, 40 if up else 20, 0),
				"tail_base": Vector3(0, 0, -38 if up else -30)})
	clips.append(idle)

	var moves: Dictionary = {
		&"dance_good": [Vector3(8, 0, STAND_PITCH), Vector3(0, 0.03, 0), {"fin_left": Vector3(-50, -70, 0), "fin_right": Vector3(0, 30, 0)}],
		&"dance_great": [Vector3(-14, 40, STAND_PITCH), Vector3(0, 0.06, 0), {"fin_left": Vector3(0, -110, 0), "fin_right": Vector3(0, 110, 0), "jaw_or_head": Vector3(0, 0, 10)}],
		&"dance_perfect": [Vector3(0, 0, STAND_PITCH + 20.0), Vector3(0, 0.22, 0), {"fin_left": Vector3(-40, -130, 0), "fin_right": Vector3(40, 130, 0), "tail_base": Vector3(0, 0, -60), "jaw_or_head": Vector3(0, 0, 16)}],
	}
	for clip_name: StringName in moves:
		var move: Array = moves[clip_name]
		var clip := RigBuilder.Clip.new(skeleton, clip_name, 0.4)
		_box_pose(clip, length, 0.0)
		_box_pose(clip, length, 0.12, move[0], move[1], move[2])
		_box_pose(clip, length, 0.22, move[0], move[1], move[2])
		_box_pose(clip, length, 0.4)
		clips.append(clip)

	var miss := RigBuilder.Clip.new(skeleton, &"dance_miss", 0.5)
	_box_pose(miss, length, 0.0)
	_box_pose(miss, length, 0.15, Vector3(24, 0, STAND_PITCH - 14.0), Vector3(0, -0.02, 0), {"fin_left": Vector3(30, -10, 0), "fin_right": Vector3(-30, 10, 0), "jaw_or_head": Vector3(0, 0, 12)})
	_box_pose(miss, length, 0.3, Vector3(-10, 0, STAND_PITCH - 6.0), Vector3.ZERO, {"fin_left": Vector3(10, -20, 0)})
	_box_pose(miss, length, 0.5)
	clips.append(miss)

	var win := RigBuilder.Clip.new(skeleton, &"dance_win", 1.2, true)
	for step: int in 5:
		var spin := 90.0 * float(step)
		_box_pose(win, length, 0.3 * float(step), Vector3(0, spin, STAND_PITCH), Vector3(0, 0.08 if step % 2 == 1 else 0.0, 0),
			{"fin_left": Vector3(0, -130, 0), "fin_right": Vector3(0, 130, 0)})
	clips.append(win)

	var lose := RigBuilder.Clip.new(skeleton, &"dance_lose", 1.0)
	_box_pose(lose, length, 0.0)
	var slump := {"fin_left": Vector3(10, -6, 0), "fin_right": Vector3(-10, 6, 0), "jaw_or_head": Vector3(0, 0, 20), "body_back": Vector3(0, 0, 8)}
	_box_pose(lose, length, 0.5, Vector3(0, 0, STAND_PITCH - 30.0), Vector3(0, -0.05, 0), slump)
	_box_pose(lose, length, 1.0, Vector3(0, 0, STAND_PITCH - 34.0), Vector3(0, -0.06, 0), slump)
	clips.append(lose)
	return clips


# --- Signature accessories (GDD Section 69, 185.7-185.11) -------------------
# Bruiser Catfish has its whiskers and brow; the others get the one item that
# tells who they are at a glance, big enough to read from the diorama camera.

const HEADBAND_RED := Color("d2544a")
const HEADBAND_WHITE := Style.FLOUR
const KHAKI_BAND := Color("a39e74")
const BADGE_BRASS := Color("d9b45a")
const SHADES := Color("2a2220")
const CHAIN_GOLD := Style.GOLD
const CHAIN_MUTED := Color("d4af5a")
const SCAR := Color("f2d3b0")


func _build_signature(fish_id: StringName, profile: Dictionary, skeleton: Skeleton3D) -> ArrayMesh:
	var length: float = profile["length"]
	var eye: Array = profile["eye"]
	var builder := SoftMesh.new()
	builder.enable_skinning()
	builder.select_surface(MaterialBuilder.SURFACE_ROUND)
	builder.set_bone(skeleton.find_bone("jaw_or_head"))
	match fish_id:
		&"tilapia_gym_rat":
			# A red sweatband with a white stripe, round the forehead.
			_head_band(builder, profile, float(eye[0]) - 0.065, 0.06, 1.06, HEADBAND_RED)
			_head_band(builder, profile, float(eye[0]) - 0.065, 0.02, 1.1, HEADBAND_WHITE)
		&"gourami_shady":
			# Dark round sunglasses over both eyes, joined by a bridge.
			var radius: float = float(eye[2]) * length
			for side: float in [-1.0, 1.0]:
				var surface := Vector3(eye[0], eye[1], _surface_z(profile, eye[0], eye[1]) * side) * length
				var outward := Vector3(0.15, 0.1, side).normalized()
				builder.color = SHADES
				builder.sphere(surface + outward * radius * 0.55, Vector3(radius * 1.3, radius * 1.05, radius * 0.5), 10, 4)
				builder.capsule(surface + outward * radius * 0.4 + Vector3(-radius * 1.2, radius * 0.3, 0.0),
					surface + Vector3(-radius * 3.2, radius * 0.5, 0.0), radius * 0.16, -1.0, 6, 2)
			var top := Vector3(float(eye[0]) + 0.01, float(eye[1]) + 0.02, 0.0) * length
			var reach := _surface_z(profile, float(eye[0]) + 0.01, float(eye[1]) + 0.02) * length
			builder.capsule(top - Vector3(0, 0, reach - radius * 0.6), top + Vector3(0, 0, reach - radius * 0.6), radius * 0.18, -1.0, 6, 2)
		&"carp_golden":
			# An oversized gold chain of beads behind the head, with a medallion.
			builder.set_bone(skeleton.find_bone("body_front"))
			_bead_ring(builder, profile, 0.24, 1.08, 16, 0.03, CHAIN_GOLD, 0.06)
			builder.color = CHAIN_GOLD.lightened(0.12)
			var section := _section_at(profile, 0.22)
			builder.sphere(Vector3(0.215, float(section[3]) - float(section[2]) * 1.15, 0.0) * length, Vector3(0.045, 0.045, 0.03) * length, 10, 5)
		&"snakehead_sergeant":
			# A desaturated khaki headband with a plain brass badge in front.
			_head_band(builder, profile, float(eye[0]) - 0.08, 0.055, 1.07, KHAKI_BAND)
			var section := _section_at(profile, float(eye[0]) - 0.05)
			builder.color = BADGE_BRASS
			builder.transform = Transform3D(Basis(Vector3.BACK, deg_to_rad(-20.0)), Vector3(float(eye[0]) - 0.05, float(section[3]) + float(section[2]) * 1.02, 0.0) * length)
			builder.rounded_slab(Vector3(0.05, 0.026, 0.05) * length, Vector3.ZERO, 0.006 * length)
			builder.transform = Transform3D.IDENTITY
		&"arowana_don":
			# Only a thin muted-gold chain, a scar and darker fin edges (GDD 69).
			builder.set_bone(skeleton.find_bone("body_front"))
			_bead_ring(builder, profile, 0.26, 1.05, 22, 0.011, CHAIN_MUTED, 0.025)
			builder.set_bone(skeleton.find_bone("jaw_or_head"))
			builder.color = SCAR
			var scar_x := float(eye[0]) - 0.075
			var scar_y := float(eye[1]) - 0.04
			for side: float in [1.0]:
				var at := Vector3(scar_x, scar_y, _surface_z(profile, scar_x, scar_y) * side + 0.004 * side) * length
				builder.capsule(at + Vector3(0.03, 0.022, 0.0) * length, at - Vector3(0.03, 0.022, 0.0) * length, 0.006 * length, -1.0, 6, 2)
			builder.set_bone(skeleton.find_bone("tail_base"))
			builder.color = Color("4a1d1a")
			builder.puffy_outline(_outline([[-0.56, 0.11], [-0.635, 0.0], [-0.56, -0.11], [-0.59, 0.0]], length), 0.036 * length)
	return builder.commit(MaterialBuilder.surface_materials()) if not builder.is_empty() else null


## Cross-section [x, half_width, half_height, y] at `x`, interpolated.
func _section_at(profile: Dictionary, x: float) -> Array:
	var sections: Array = profile["sections"]
	for index: int in sections.size() - 1:
		var front: Array = sections[index]
		var back: Array = sections[index + 1]
		if x <= float(front[0]) and x >= float(back[0]):
			var weight := (float(front[0]) - x) / maxf(float(front[0]) - float(back[0]), 0.0001)
			return [x, lerpf(front[1], back[1], weight), lerpf(front[2], back[2], weight), lerpf(front[3], back[3], weight)]
	return sections[0] if x > float((sections[0] as Array)[0]) else sections[sections.size() - 1]


## A soft band round the head at `x`, `width` body lengths wide.
func _head_band(builder: RefCounted, profile: Dictionary, x: float, width: float, scale: float, color: Color) -> void:
	var length: float = profile["length"]
	builder.color = color
	var rings: Array = []
	for step: Array in [[-0.5, 0.985], [0.0, 1.0], [0.5, 0.985]]:
		var at: float = x + width * float(step[0])
		var section := _section_at(profile, at)
		var grow: float = scale * float(step[1])
		var centre := Vector3(at, float(section[3]), 0.0) * length
		rings.append(builder.ring(centre, Vector3(0, 0, float(section[1]) * grow * length), Vector3(0, float(section[2]) * grow * length, 0), 16, float(profile["squareness"])))
	builder.loft(rings)


## A loop of beads round the body at `x`, sagging toward the belly.
func _bead_ring(builder: RefCounted, profile: Dictionary, x: float, scale: float, count: int, bead: float, color: Color, sag: float) -> void:
	var length: float = profile["length"]
	var section := _section_at(profile, x)
	builder.color = color
	for index: int in count:
		var angle := TAU * float(index) / float(count)
		var droop := sag * maxf(-sin(angle), 0.0)
		var point := Vector3(x - droop * 0.5, float(section[3]) + sin(angle) * float(section[2]) * scale - droop, cos(angle) * float(section[1]) * scale)
		builder.sphere(point * length, Vector3.ONE * bead * length, 6, 3)


# --- Suwit clips (GDD 172.6) ------------------------------------------------
# The fish stands behind the table. Its tell is mostly in the UI; the body
# only adds attitude: a calm nod for a true tell, a shifty glance for a lie.

func _build_suwit_clips(skeleton: Skeleton3D, fish_id: StringName, length: float) -> Array:
	var clips: Array = []
	var ready_pose := {"fin_left": Vector3(-20, -70, 0), "fin_right": Vector3(0, 30, 0)}
	var ready := RigBuilder.Clip.new(skeleton, &"suwit_ready", 0.6, true)
	for step: int in 3:
		var lift := 0.03 if step == 1 else 0.0
		_box_pose(ready, length, 0.3 * float(step), Vector3(0, 0, STAND_PITCH), Vector3(0, lift, 0), ready_pose.merged({"fin_left": Vector3(-20, -70 - 30 * int(step == 1), 0)}, true))
	clips.append(ready)

	var truth := RigBuilder.Clip.new(skeleton, &"suwit_tell_true", 0.8)
	_box_pose(truth, length, 0.0, Vector3(0, 0, STAND_PITCH), Vector3.ZERO, ready_pose)
	_box_pose(truth, length, 0.3, Vector3(0, 0, STAND_PITCH - 8.0), Vector3.ZERO, ready_pose.merged({"jaw_or_head": Vector3(0, 0, -22)}, true))
	_box_pose(truth, length, 0.8, Vector3(0, 0, STAND_PITCH), Vector3.ZERO, ready_pose)
	clips.append(truth)

	var fake := RigBuilder.Clip.new(skeleton, &"suwit_tell_fake", 0.8)
	_box_pose(fake, length, 0.0, Vector3(0, 0, STAND_PITCH), Vector3.ZERO, ready_pose)
	_box_pose(fake, length, 0.25, Vector3(0, 18, STAND_PITCH), Vector3.ZERO, ready_pose.merged({"jaw_or_head": Vector3(0, 20, 0)}, true))
	_box_pose(fake, length, 0.55, Vector3(0, -14, STAND_PITCH), Vector3.ZERO, ready_pose.merged({"jaw_or_head": Vector3(0, -16, 0)}, true))
	_box_pose(fake, length, 0.8, Vector3(0, 0, STAND_PITCH), Vector3.ZERO, ready_pose)
	clips.append(fake)

	var reveal := RigBuilder.Clip.new(skeleton, &"suwit_reveal", 0.5)
	_box_pose(reveal, length, 0.0, Vector3(0, 0, STAND_PITCH), Vector3.ZERO, ready_pose)
	_box_pose(reveal, length, 0.15, Vector3(0, -20, STAND_PITCH - 10.0), Vector3(0.06, 0, 0), {"fin_left": Vector3(-80, -20, 0), "fin_right": Vector3(0, 30, 0)})
	_box_pose(reveal, length, 0.5, Vector3(0, -20, STAND_PITCH - 10.0), Vector3(0.06, 0, 0), {"fin_left": Vector3(-80, -20, 0), "fin_right": Vector3(0, 30, 0)})
	clips.append(reveal)

	var win := RigBuilder.Clip.new(skeleton, &"suwit_win", 0.9)
	_box_pose(win, length, 0.0)
	_box_pose(win, length, 0.4, Vector3(0, 0, STAND_PITCH + 8.0), Vector3(0, 0.05, 0), {"fin_left": Vector3(0, -130, 0), "fin_right": Vector3(0, 130, 0), "jaw_or_head": Vector3(0, 0, 10)})
	_box_pose(win, length, 0.9, Vector3(0, 0, STAND_PITCH + 6.0), Vector3(0, 0.03, 0), {"fin_left": Vector3(0, -120, 0), "fin_right": Vector3(0, 120, 0)})
	clips.append(win)

	var lose := RigBuilder.Clip.new(skeleton, &"suwit_lose", 0.9)
	_box_pose(lose, length, 0.0)
	_box_pose(lose, length, 0.5, Vector3(0, 0, STAND_PITCH - 24.0), Vector3(0, -0.04, 0), {"fin_left": Vector3(10, -10, 0), "fin_right": Vector3(-10, 10, 0), "jaw_or_head": Vector3(0, 0, 18)})
	_box_pose(lose, length, 0.9, Vector3(0, 0, STAND_PITCH - 26.0), Vector3(0, -0.05, 0), {"fin_left": Vector3(10, -10, 0), "fin_right": Vector3(-10, 10, 0), "jaw_or_head": Vector3(0, 0, 20)})
	clips.append(lose)

	var draw := RigBuilder.Clip.new(skeleton, &"suwit_draw", 0.7)
	_box_pose(draw, length, 0.0)
	_box_pose(draw, length, 0.3, Vector3(0, 0, STAND_PITCH), Vector3(0, 0.02, 0), {"fin_left": Vector3(30, -60, 0), "fin_right": Vector3(-30, 60, 0), "jaw_or_head": Vector3(10, 0, 0)})
	_box_pose(draw, length, 0.7)
	clips.append(draw)
	return clips
