@tool
extends RefCounted
## Generates the six fish from procedural body profiles (GDD 184.7, 185.6-185.11).
##
## Each species has its own cross-section profile, fins and colours, so the
## silhouettes differ by shape and not just by tint. The mesh is skinned along a
## spine, which lets the body bend smoothly when the fish swims or flops.
##
## Bruiser Catfish is at final quality. The other five have their real body
## shapes; their signature accessories and personality clips are added by the
## milestone that builds their dialogue. Every fish owns boxing gloves and the
## boxing clips of the universal contract (GDD 172.6).

const MeshBuilder := preload("res://tools/generators/mesh_builder.gd")
const RigBuilder := preload("res://tools/generators/rig_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")

const GENERATOR_ID := "fish_builder"
const GENERATOR_VERSION := 1
const SCENE_PATH := "res://generated/scenes/fish/fish_%s.tscn"

const BODY_SEGMENTS := 12
const EYE_WHITE := Color("efe9d8")
const EYE_DARK := Color("1d1b19")
const GLOVE_RED := Color("a4483f")
const GLOVE_CUFF := Color("e9dcc0")

## Spine joints along the body, from tail to head, as fractions of body length.
const SPINE: Array = [
	["tail_tip", -0.46], ["tail_base", -0.36], ["body_back", -0.22],
	["body_mid", -0.05], ["body_front", 0.12], ["jaw_or_head", 0.30],
]

## Cross-sections are [x, half_width, half_height, y] in body lengths, listed
## from the snout (+x) to the tail (-x). Fin outlines are in the side plane.
const PROFILES: Dictionary = {
	&"catfish_bruiser": {
		"length": 0.82, "squareness": 2.6,
		"top": Color("3f463a"), "belly": Color("b9b39a"), "fin": Color("2c3129"),
		"sections": [
			[0.50, 0.035, 0.020, -0.005], [0.46, 0.085, 0.040, 0.0], [0.38, 0.125, 0.062, 0.0],
			[0.26, 0.130, 0.078, 0.005], [0.10, 0.105, 0.085, 0.01], [-0.08, 0.080, 0.080, 0.01],
			[-0.25, 0.055, 0.068, 0.008], [-0.38, 0.030, 0.050, 0.005], [-0.46, 0.014, 0.036, 0.0]],
		"tail": [[-0.44, 0.03], [-0.56, 0.085], [-0.60, 0.05], [-0.585, 0.0], [-0.60, -0.05], [-0.56, -0.085], [-0.44, -0.03]],
		"dorsal": [[0.18, 0.082], [0.12, 0.14], [-0.10, 0.125], [-0.38, 0.07], [-0.40, 0.04], [-0.10, 0.07], [0.12, 0.078]],
		"anal": [[-0.05, -0.068], [-0.10, -0.115], [-0.36, -0.07], [-0.38, -0.04], [-0.10, -0.058]],
		"pectoral": [0.20, -0.03, 0.115, 0.15],
		"eye": [0.395, 0.050, 0.094, 0.036],
		"whiskers": true, "gloves": true, "brow": true,
	},
	&"tilapia_gym_rat": {
		"length": 0.56, "squareness": 2.0,
		"top": Color("71858c"), "belly": Color("dcd5c5"), "fin": Color("55666d"),
		"sections": [
			[0.50, 0.020, 0.030, 0.0], [0.44, 0.045, 0.090, 0.0], [0.32, 0.070, 0.170, 0.01],
			[0.12, 0.080, 0.215, 0.01], [-0.08, 0.070, 0.200, 0.01], [-0.26, 0.045, 0.140, 0.0],
			[-0.38, 0.025, 0.075, 0.0], [-0.45, 0.014, 0.050, 0.0]],
		"tail": [[-0.43, 0.04], [-0.58, 0.13], [-0.60, 0.0], [-0.58, -0.13], [-0.43, -0.04]],
		"dorsal": [[0.22, 0.18], [0.15, 0.27], [-0.05, 0.27], [-0.28, 0.21], [-0.33, 0.12], [-0.05, 0.19]],
		"anal": [[-0.10, -0.18], [-0.16, -0.24], [-0.30, -0.17], [-0.32, -0.10]],
		"pectoral": [0.22, -0.06, 0.07, 0.14],
		"eye": [0.40, 0.045, 0.048, 0.024],
	},
	&"gourami_shady": {
		"length": 0.60, "squareness": 2.0,
		"top": Color("86775a"), "belly": Color("d9caa9"), "fin": Color("665840"),
		"sections": [
			[0.50, 0.018, 0.030, 0.0], [0.44, 0.040, 0.100, 0.0], [0.30, 0.060, 0.200, 0.0],
			[0.10, 0.070, 0.250, 0.0], [-0.12, 0.065, 0.240, 0.0], [-0.30, 0.040, 0.160, 0.0],
			[-0.42, 0.020, 0.070, 0.0], [-0.47, 0.012, 0.045, 0.0]],
		"tail": [[-0.45, 0.04], [-0.56, 0.10], [-0.60, 0.05], [-0.60, -0.05], [-0.56, -0.10], [-0.45, -0.04]],
		"dorsal": [[0.05, 0.235], [-0.05, 0.31], [-0.30, 0.24], [-0.36, 0.13], [-0.10, 0.20]],
		"anal": [[0.10, -0.225], [0.0, -0.31], [-0.32, -0.22], [-0.38, -0.10], [-0.10, -0.20]],
		"pectoral": [0.24, -0.05, 0.06, 0.12],
		"eye": [0.40, 0.05, 0.043, 0.022],
	},
	&"carp_golden": {
		"length": 0.66, "squareness": 2.1,
		"top": Color("c8942e"), "belly": Color("f0d68c"), "fin": Color("d47a2c"),
		"sections": [
			[0.50, 0.030, 0.035, -0.01], [0.44, 0.060, 0.085, 0.0], [0.32, 0.085, 0.140, 0.015],
			[0.12, 0.100, 0.180, 0.03], [-0.08, 0.090, 0.165, 0.025], [-0.26, 0.060, 0.115, 0.01],
			[-0.39, 0.030, 0.065, 0.0], [-0.46, 0.016, 0.045, 0.0]],
		"tail": [[-0.44, 0.04], [-0.60, 0.15], [-0.56, 0.0], [-0.60, -0.15], [-0.44, -0.04]],
		"dorsal": [[0.16, 0.19], [0.08, 0.30], [-0.24, 0.20], [-0.28, 0.12], [-0.05, 0.17]],
		"anal": [[-0.14, -0.14], [-0.20, -0.22], [-0.30, -0.13], [-0.30, -0.09]],
		"pectoral": [0.24, -0.07, 0.085, 0.17],
		"eye": [0.40, 0.04, 0.062, 0.024],
	},
	&"snakehead_sergeant": {
		"length": 0.86, "squareness": 2.4,
		"top": Color("3b4937"), "belly": Color("c9c3a5"), "fin": Color("2d382b"),
		"bands": true,
		"sections": [
			[0.50, 0.035, 0.028, 0.0], [0.45, 0.065, 0.050, 0.0], [0.36, 0.078, 0.066, 0.0],
			[0.18, 0.080, 0.075, 0.0], [-0.05, 0.075, 0.075, 0.0], [-0.25, 0.060, 0.066, 0.0],
			[-0.40, 0.035, 0.050, 0.0], [-0.47, 0.016, 0.035, 0.0]],
		"tail": [[-0.45, 0.03], [-0.57, 0.08], [-0.61, 0.0], [-0.57, -0.08], [-0.45, -0.03]],
		"dorsal": [[0.14, 0.072], [0.10, 0.125], [-0.38, 0.105], [-0.42, 0.04], [-0.10, 0.068]],
		"anal": [[-0.02, -0.07], [-0.06, -0.12], [-0.38, -0.10], [-0.42, -0.04], [-0.10, -0.066]],
		"pectoral": [0.26, -0.03, 0.075, 0.13],
		"eye": [0.42, 0.035, 0.06, 0.02],
	},
	&"arowana_don": {
		"length": 1.0, "squareness": 2.0,
		"top": Color("b3553b"), "belly": Color("e7b76c"), "fin": Color("73291f"),
		"scales": true,
		"sections": [
			[0.50, 0.020, 0.030, 0.035], [0.45, 0.045, 0.070, 0.02], [0.34, 0.060, 0.105, 0.0],
			[0.12, 0.065, 0.120, -0.005], [-0.12, 0.060, 0.115, -0.005], [-0.30, 0.045, 0.095, 0.0],
			[-0.42, 0.028, 0.070, 0.0], [-0.48, 0.014, 0.045, 0.0]],
		"tail": [[-0.46, 0.04], [-0.56, 0.085], [-0.61, 0.0], [-0.56, -0.085], [-0.46, -0.04]],
		"dorsal": [[-0.20, 0.108], [-0.26, 0.17], [-0.44, 0.10], [-0.44, 0.055], [-0.30, 0.09]],
		"anal": [[-0.10, -0.115], [-0.18, -0.19], [-0.44, -0.10], [-0.44, -0.055], [-0.20, -0.10]],
		"pectoral": [0.26, -0.07, 0.058, 0.20],
		"eye": [0.42, 0.055, 0.042, 0.022],
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

	var material: Material = load(MaterialBuilder.VERTEX_COLOR)
	var body_meshes := Node3D.new()
	body_meshes.name = "BodyMeshes"
	root.add_child(body_meshes)
	body_meshes.add_child(_mesh_instance("Body", _build_body(profile, skeleton), material))

	var accessories := Node3D.new()
	accessories.name = "AccessoryMeshes"
	root.add_child(accessories)
	# Every fish boxes, so every fish has gloves. Scenes hide them until needed.
	accessories.add_child(_mesh_instance("Gloves", _build_gloves(profile, skeleton), material))

	var clips := _build_clips(skeleton, length)
	clips.append_array(_build_boxing_clips(skeleton, fish_id, length))
	clips.append_array(_build_arm_clips(skeleton, fish_id, length))
	root.add_child(RigBuilder.make_player(clips))
	return root


# --- Rig --------------------------------------------------------------------

func _bone_rows(profile: Dictionary) -> Array:
	var length: float = profile["length"]
	var pectoral: Array = profile["pectoral"]
	var fin_x: float = pectoral[0] * length
	var fin_y: float = pectoral[1] * length
	var fin_z: float = pectoral[2] * length
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


func _mesh_instance(node_name: String, mesh: ArrayMesh, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.skeleton = NodePath("../../Skeleton3D")
	return instance


# --- Body -------------------------------------------------------------------

func _build_body(profile: Dictionary, skeleton: Skeleton3D) -> ArrayMesh:
	var length: float = profile["length"]
	var top: Color = profile["top"]
	var belly: Color = profile["belly"]
	var fin: Color = profile["fin"]
	var builder := MeshBuilder.new()
	builder.enable_skinning()

	var spine_bones := PackedInt32Array()
	var spine_stops := PackedFloat32Array()
	for joint: Array in SPINE:
		spine_bones.append(skeleton.find_bone(joint[0]))
		spine_stops.append(float(joint[1]) * length)
	builder.set_spine(spine_bones, spine_stops, Vector3.RIGHT)

	# Body: back colour above, belly colour below, with optional markings.
	var sections := _resample(profile["sections"])
	var max_height := 0.0
	for section: Array in sections:
		max_height = maxf(max_height, section[2])
	builder.color_rule = func(point: Vector3, _base: Color) -> Color:
		var height := point.y / (max_height * length)
		var shade := top.lerp(belly, smoothstep(0.05, -0.45, height))
		if profile.get("bands", false) and height > -0.2 and sin(point.x / length * 46.0) > 0.35:
			shade = shade.darkened(0.3)
		if profile.get("scales", false):
			var cell := int(floor(point.x / length * 16.0)) + int(floor(point.y / length * 16.0))
			if cell % 2 == 0:
				shade = shade.lightened(0.14)
		return shade

	var rings: Array = []
	for section: Array in sections:
		var centre := Vector3(section[0], section[3], 0.0) * length
		rings.append(builder.ring(
			centre, Vector3(0.0, 0.0, section[1] * length), Vector3(0.0, section[2] * length, 0.0),
			BODY_SEGMENTS, profile["squareness"]))
	builder.loft(rings, true, true)
	builder.color_rule = Callable()

	# Fins follow the spine so they bend with the body.
	builder.color = fin
	var fin_thickness := 0.012 * length
	for fin_name: String in ["tail", "dorsal", "anal"]:
		if profile.has(fin_name):
			builder.slab(_outline(profile[fin_name], length), fin_thickness)

	_add_pectoral_fins(builder, profile, skeleton)
	_add_face(builder, profile, skeleton)
	if profile.get("whiskers", false):
		_add_whiskers(builder, length, skeleton, fin)
	return builder.commit()


func _add_pectoral_fins(builder: RefCounted, profile: Dictionary, skeleton: Skeleton3D) -> void:
	var length: float = profile["length"]
	var pectoral: Array = profile["pectoral"]
	var span: float = pectoral[3] * length
	var outline := PackedVector2Array([
		Vector2(0.0, 0.30 * span), Vector2(0.85 * span, 0.16 * span),
		Vector2(span, -0.24 * span), Vector2(0.1 * span, -0.36 * span)])
	builder.color = profile["fin"]
	for side: float in [-1.0, 1.0]:
		var bone := "fin_left" if side < 0.0 else "fin_right"
		builder.set_bone(skeleton.find_bone(bone))
		# The outline's X runs outward and slightly down; its Y runs forward.
		var outward := Vector3(0.0, -0.3, side).normalized()
		var forward := Vector3(1.0, 0.0, 0.0)
		var basis := Basis(outward, forward, outward.cross(forward))
		builder.transform = Transform3D(basis, Vector3(pectoral[0], pectoral[1], pectoral[2] * side) * length)
		builder.slab(outline, 0.014 * length)
	builder.transform = Transform3D.IDENTITY


func _add_face(builder: RefCounted, profile: Dictionary, skeleton: Skeleton3D) -> void:
	var length: float = profile["length"]
	var eye: Array = profile["eye"]
	builder.set_bone(skeleton.find_bone("jaw_or_head"))
	for side: float in [-1.0, 1.0]:
		var centre := Vector3(eye[0], eye[1], eye[2] * side) * length
		var radius: float = eye[3] * length
		builder.color = EYE_WHITE
		builder.blob(centre, Vector3.ONE * radius, 6, 4)
		builder.color = EYE_DARK
		builder.blob(centre + Vector3(0.45, 0.0, 0.5 * side) * radius, Vector3.ONE * radius * 0.6, 6, 4)
		if profile.get("brow", false):
			# A heavy lid over the top of the eye, lower toward the middle:
			# unimpressed and tough, not evil.
			var tilt := Basis(Vector3(1.0, 0.0, 0.0), deg_to_rad(-20.0 * side)) * Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(-10.0))
			builder.transform = Transform3D(tilt, centre + Vector3(0.2, 0.72, 0.1 * side) * radius)
			builder.color = profile["top"].darkened(0.25)
			builder.box(Vector3(2.3, 0.42, 2.1) * radius)
			builder.transform = Transform3D.IDENTITY

	# A wide mouth line wrapped around the snout.
	var first: Array = profile["sections"][1]
	builder.color = EYE_DARK
	builder.box(
		Vector3(0.05, 0.011, first[1] * 2.05) * length,
		Vector3(first[0] - 0.004, first[3] - first[2] * 0.45, 0.0) * length)


## Four pairs of barbels (GDD 185.6): long maxillary, short nasal, two chin pairs.
func _add_whiskers(builder: RefCounted, length: float, skeleton: Skeleton3D, tint: Color) -> void:
	var paths: Array = [
		[Vector3(0.46, -0.010, 0.070), Vector3(0.51, -0.020, 0.200), Vector3(0.42, -0.055, 0.330), 0.0075],
		[Vector3(0.47, 0.020, 0.030), Vector3(0.53, 0.062, 0.062), Vector3(0.55, 0.105, 0.085), 0.0055],
		[Vector3(0.44, -0.034, 0.052), Vector3(0.47, -0.082, 0.112), Vector3(0.42, -0.130, 0.152), 0.0055],
		[Vector3(0.455, -0.036, 0.020), Vector3(0.485, -0.082, 0.036), Vector3(0.47, -0.128, 0.046), 0.005],
	]
	builder.set_bone(skeleton.find_bone("jaw_or_head"))
	builder.color = tint.lightened(0.08)
	for path: Array in paths:
		for side: float in [-1.0, 1.0]:
			var mirror := Vector3(1.0, 1.0, side)
			var start: Vector3 = path[0] * mirror * length
			var middle: Vector3 = path[1] * mirror * length
			var tip: Vector3 = path[2] * mirror * length
			var radius: float = path[3] * length
			builder.tube(start, middle, radius, radius * 0.7, 5, true)
			builder.tube(middle, tip, radius * 0.7, radius * 0.25, 5, true)


## Worn red boxing gloves on the pectoral fins: fist, thumb and a cream cuff.
func _build_gloves(profile: Dictionary, skeleton: Skeleton3D) -> ArrayMesh:
	var length: float = profile["length"]
	var pectoral: Array = profile["pectoral"]
	var span: float = pectoral[3] * length
	var builder := MeshBuilder.new()
	builder.enable_skinning()
	for side: float in [-1.0, 1.0]:
		builder.set_bone(skeleton.find_bone("fin_left" if side < 0.0 else "fin_right"))
		var base := Vector3(pectoral[0], pectoral[1], pectoral[2] * side) * length
		var outward := Vector3(0.0, -0.3, side).normalized()
		var wrist := base + outward * span * 0.55
		var fist := base + outward * span * 1.05
		var size := 0.074 * length
		builder.color = GLOVE_CUFF
		builder.tube(wrist, wrist + outward * size * 0.5, size * 0.62, size * 0.7, 8, true)
		builder.color = GLOVE_RED
		builder.blob(fist, Vector3(1.05, 1.0, 0.95) * size, 8, 5, 0.04, 11)
		builder.blob(fist + Vector3(0.75, 0.25, -0.2 * side) * size, Vector3(0.48, 0.42, 0.42) * size, 6, 4)
		# A lighter worn patch on the knuckles.
		builder.color = GLOVE_RED.lightened(0.22)
		builder.blob(fist + Vector3(0.35, 0.55, 0.35 * side) * size, Vector3(0.42, 0.3, 0.42) * size, 6, 3)
	return builder.commit()


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
