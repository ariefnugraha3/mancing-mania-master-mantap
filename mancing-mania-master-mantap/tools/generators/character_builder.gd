@tool
extends RefCounted
## Generates the four people as chibi diorama characters (VISUAL_STYLE_GUIDE 9,
## GDD 184.6, 185.2-185.5).
##
## Every person shares one 0.90 m chibi build: a head of about 42 % of the
## height, a soft lathed torso with crisp colour bands, short capsule limbs
## and round hands and feet. The whole body is baked into one vertex-coloured
## mesh bound rigidly to a small skeleton (each bone is the pivot of one
## segment, the guide's node pivots), so the duel clips keep working and a
## character costs a couple of draw calls. Characters face -Z; their right
## hand is on +X. Variation (hair, cap, clothes, skin, height) is data.

const SoftMesh := preload("res://tools/generators/soft_mesh.gd")
const RigBuilder := preload("res://tools/generators/rig_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")
const Kit := preload("res://tools/generators/diorama_kit.gd")
const Style := preload("res://scripts/visual/diorama_style.gd")

const GENERATOR_ID := "character_builder"
const GENERATOR_VERSION := 2
const DARTO_PATH := "res://generated/scenes/characters/chr_darto.tscn"
const BU_YATI_PATH := "res://generated/scenes/characters/chr_bu_yati.tscn"
const RINI_PATH := "res://generated/scenes/characters/chr_rini.tscn"
const NISA_PATH := "res://generated/scenes/characters/chr_nisa.tscn"

## [bone, parent, joint position]. 0.90 m tall (guide 9.1): hips at 0.25 m,
## neck at 0.515 m, shoulders on the 0.44 m chest line.
const BONES: Array = [
	["root", "", Vector3(0, 0, 0)],
	["pelvis", "root", Vector3(0, 0.25, 0)],
	["spine_lower", "pelvis", Vector3(0, 0.29, 0)],
	["spine_upper", "spine_lower", Vector3(0, 0.40, 0)],
	["neck", "spine_upper", Vector3(0, 0.505, 0)],
	["head", "neck", Vector3(0, 0.525, 0)],
	["upper_arm_l", "spine_upper", Vector3(-0.142, 0.44, 0)],
	["forearm_l", "upper_arm_l", Vector3(-0.158, 0.368, 0)],
	["hand_l", "forearm_l", Vector3(-0.174, 0.300, 0)],
	["upper_arm_r", "spine_upper", Vector3(0.142, 0.44, 0)],
	["forearm_r", "upper_arm_r", Vector3(0.158, 0.368, 0)],
	["hand_r", "forearm_r", Vector3(0.174, 0.300, 0)],
	["thigh_l", "pelvis", Vector3(-0.066, 0.25, 0)],
	["shin_l", "thigh_l", Vector3(-0.066, 0.165, 0)],
	["foot_l", "shin_l", Vector3(-0.066, 0.08, 0)],
	["thigh_r", "pelvis", Vector3(0.066, 0.25, 0)],
	["shin_r", "thigh_r", Vector3(0.066, 0.165, 0)],
	["foot_r", "shin_r", Vector3(0.066, 0.08, 0)],
]

const HEAD_CENTRE := Vector3(0.0, 0.70, 0.0)
const HEAD_RADII := Vector3(0.205, 0.19, 0.196)
## The eye line sits at 45 % of the head height from the chin (guide 9.1).
const EYE_Y := 0.672
const BROW_Y := 0.722
const LIMB_SEGMENTS := 6
const BODY_SEGMENTS := 12
const MOUTH := Color("8a3f2e")

## Who looks like what (GDD 185.2-185.5, palettes moved into the warm range).
const DARTO: Dictionary = {
	"node": "ChrDarto", "scale": 1.0,
	"skin": Color("dca982"), "skin_shade": Color("c8916a"), "hair": Color("3b2a20"),
	"top": Color("b7a68c"), "lower": Color("67706b"), "shoes": Color("8c6248"),
	"lower_kind": "shorts", "sleeves": "short", "belly": 0.150,
	"hair_style": "cap", "cap": Color("7b7b66"), "bag": Color("727d6a"),
	"mouth": "flat", "brow_tilt": -0.007,
}
const BU_YATI: Dictionary = {
	"node": "ChrBuYati", "scale": 0.91,
	"skin": Color("cf9f78"), "skin_shade": Color("ba8962"), "hair": Color("a7a5a5"),
	"top": Color("93504a"), "lower": Color("80845f"), "shoes": Color("8a5444"),
	"lower_kind": "skirt", "sleeves": "short", "belly": 0.150,
	"hair_style": "bun", "apron": Color("f7ead0"),
	"mouth": "down", "brow_tilt": 0.0,
}
const RINI: Dictionary = {
	"node": "ChrRini", "scale": 0.93,
	"skin": Color("e2b18a"), "skin_shade": Color("cc9a70"), "hair": Color("3b2a20"),
	"top": Color("7f9bc7"), "lower": Color("a86a55"), "shoes": Color("6b4a3a"),
	"lower_kind": "long_skirt", "sleeves": "long", "belly": 0.138,
	"hair_style": "low_tail", "tie": Color("c96a5c"),
	"mouth": "flat", "brow_tilt": 0.002,
}
const NISA: Dictionary = {
	"node": "ChrNisa", "scale": 0.885,
	"skin": Color("e8bd95"), "skin_shade": Color("d4a47a"), "hair": Color("2f2119"),
	"top": Color("8fc0ea"), "lower": Color("eee6d8"), "shoes": Color("c2675a"),
	"lower_kind": "trousers", "sleeves": "short", "belly": 0.136,
	"hair_style": "pigtails", "tie": Color("c96a5c"),
	"mouth": "smile", "brow_tilt": 0.004,
}

const GLOVE_RED := Color("c8574a")
const GLOVE_CUFF := Style.FLOUR


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var characters: Dictionary[String, Array] = {
		"chr_darto": [build_darto, DARTO_PATH],
		"chr_bu_yati": [build_bu_yati, BU_YATI_PATH],
		"chr_rini": [build_rini, RINI_PATH],
		"chr_nisa": [build_nisa, NISA_PATH],
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
	if _clip_skeleton != null:
		_clip_skeleton.free()
		_clip_skeleton = null
	return errors


func build_darto() -> Node3D:
	var clips := _build_darto_clips()
	clips.append_array(_build_darto_story_clips())
	clips.append_array(_build_darto_boxing_clips())
	clips.append_array(_build_darto_arm_clips())
	clips.append_array(_build_darto_dance_clips())
	clips.append_array(_build_darto_suwit_clips())
	var root := _assemble(DARTO, clips)
	var gloves := Kit.mesh_instance("BoxingGloves", _build_gloves(root.get_node("Skeleton3D")))
	gloves.skeleton = NodePath("../../Skeleton3D")
	gloves.visible = false
	root.get_node("AccessoryMeshes").add_child(gloves)
	return root


func build_bu_yati() -> Node3D:
	return _assemble(BU_YATI, _build_bu_yati_clips())


func build_rini() -> Node3D:
	return _assemble(RINI, _build_family_clips())


func build_nisa() -> Node3D:
	return _assemble(NISA, _build_family_clips())


## One person: skeleton, baked body, face markers, a fake shadow and clips.
func _assemble(person: Dictionary, clips: Array) -> Node3D:
	var root := Node3D.new()
	root.name = person["node"]
	var skeleton := RigBuilder.make_skeleton(BONES)
	root.add_child(skeleton)

	var body_meshes := Node3D.new()
	body_meshes.name = "BodyMeshes"
	root.add_child(body_meshes)
	var body := Kit.mesh_instance("Body", _build_body(skeleton, person))
	body.skeleton = NodePath("../../Skeleton3D")
	body_meshes.add_child(body)

	var accessories := Node3D.new()
	accessories.name = "AccessoryMeshes"
	root.add_child(accessories)

	# Anchors that follow the head, for dialogue and look-at targets.
	var face := BoneAttachment3D.new()
	face.name = "FaceMarkers"
	root.add_child(face)
	face.set_use_external_skeleton(true)
	face.set_external_skeleton(NodePath("../Skeleton3D"))
	face.bone_name = "head"
	for marker: Array in [["EyeLine", Vector3(0, EYE_Y - 0.525, -0.18)], ["Mouth", Vector3(0, 0.10, -0.18)], ["HeadTop", Vector3(0, 0.37, 0)]]:
		var node := Marker3D.new()
		node.name = marker[0]
		node.position = marker[1]
		face.add_child(node)

	root.add_child(Kit.character_shadow())
	root.add_child(_make_player(skeleton, clips))
	# Shorter people are the same build scaled down; a skinned mesh follows
	# the scale of the character's root.
	root.scale = Vector3.ONE * float(person["scale"])
	return root


func _make_player(skeleton: Skeleton3D, clips: Array) -> AnimationPlayer:
	var player := RigBuilder.make_player(clips)
	return player


# --- Body -------------------------------------------------------------------

func _build_body(skeleton: Skeleton3D, person: Dictionary) -> ArrayMesh:
	var builder := SoftMesh.new()
	builder.enable_skinning()
	builder.select_surface(MaterialBuilder.SURFACE_ROUND)
	_add_torso(builder, skeleton, person)
	_add_head(builder, skeleton, person)
	_add_face(builder, skeleton, person)
	_add_hair(builder, skeleton, person)
	for side: float in [-1.0, 1.0]:
		_add_arm(builder, skeleton, person, side)
		_add_leg(builder, skeleton, person, side)
	return builder.commit(MaterialBuilder.surface_materials())


## The torso is one lathe from the hips to the neck (guide 9.1): round hips,
## a soft belly, sloping shoulders and a short neck. Clothing edges come from
## pairs of nearly equal profile points, so each colour line is crisp.
func _add_torso(builder: RefCounted, skeleton: Skeleton3D, person: Dictionary) -> void:
	var belly: float = person["belly"]
	var skirt := String(person["lower_kind"]).contains("skirt")
	var profile := PackedVector2Array()
	if skirt:
		profile.append_array([Vector2(0.0, 0.255), Vector2(0.118, 0.258)])
	else:
		profile.append_array([Vector2(0.0, 0.198), Vector2(0.078, 0.201), Vector2(0.120, 0.216), Vector2(0.137, 0.244)])
	profile.append_array([
		Vector2(0.141, 0.277), Vector2(0.141, 0.280),
		Vector2(belly - 0.004, 0.300), Vector2(belly, 0.336), Vector2(belly - 0.007, 0.376),
		Vector2(0.131, 0.411), Vector2(0.110, 0.440), Vector2(0.080, 0.466),
		Vector2(0.056, 0.486), Vector2(0.051, 0.490), Vector2(0.047, 0.530), Vector2(0.0, 0.540)])
	var lower: Color = person["lower"]
	var top: Color = person["top"]
	var skin: Color = person["skin_shade"]
	builder.color_rule = func(point: Vector3, _base: Color) -> Color:
		if point.y > 0.488:
			return skin
		return lower if point.y < 0.2785 else top
	builder.set_spine(
		PackedInt32Array([_bone(skeleton, "pelvis"), _bone(skeleton, "spine_lower"), _bone(skeleton, "spine_upper"), _bone(skeleton, "neck")]),
		PackedFloat32Array([0.25, 0.30, 0.42, 0.50]), Vector3.UP)
	builder.lathe(profile, BODY_SEGMENTS)
	builder.color_rule = Callable()

	builder.set_bone(_bone(skeleton, "pelvis"))
	var skirt_profile := PackedVector2Array()
	var hem := 0.112 if person["lower_kind"] == "skirt" else 0.062
	if skirt:
		skirt_profile = PackedVector2Array([
			Vector2(0.0, hem), Vector2(0.170, hem), Vector2(0.176, hem + 0.012),
			Vector2(0.163, 0.20), Vector2(0.146, 0.262), Vector2(0.139, 0.285), Vector2(0.0, 0.29)])
		builder.color = lower
		builder.lathe(skirt_profile, BODY_SEGMENTS)
	if person.has("apron"):
		_add_apron(builder, skeleton, person["apron"], profile, skirt_profile, hem + 0.022)
	if person.has("bag"):
		# Darto's waist bag, worn at the front and a little to his right.
		var bag: Color = person["bag"]
		builder.color = bag.darkened(0.25)
		builder.torus(Vector3(0.0, 0.283, 0.0), Vector3.UP, 0.143, 0.0075, 10, 3)
		builder.color = bag
		builder.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(-16.0)), Vector3(0.05, 0.287, -0.148))
		builder.rounded_slab(Vector3(0.105, 0.064, 0.05), Vector3.ZERO, 0.018)
		builder.transform = Transform3D.IDENTITY


## A cloth apron hugging the blouse and skirt (guide 4.2: cloth may be thin),
## from the chest to just above the hem, with a pocket and a waist tie.
func _add_apron(builder: RefCounted, skeleton: Skeleton3D, cloth: Color, torso: PackedVector2Array, skirt: PackedVector2Array, bottom: float) -> void:
	builder.set_spine(
		PackedInt32Array([_bone(skeleton, "pelvis"), _bone(skeleton, "spine_lower"), _bone(skeleton, "spine_upper")]),
		PackedFloat32Array([0.25, 0.30, 0.42]), Vector3.UP)
	builder.color = cloth
	var rows: Array = []
	for step: int in 9:
		var y := lerpf(0.402, bottom, float(step) / 8.0)
		var radius := maxf(_radius_at(torso, y), _radius_at(skirt, y)) + 0.006
		var half := deg_to_rad(36.0 if y > 0.3 else 42.0)
		var row := PackedVector3Array()
		for column: int in 7:
			var angle := lerpf(-half, half, float(column) / 6.0)
			row.append(Vector3(sin(angle) * radius, y, -cos(angle) * radius))
		rows.append(row)
	builder.grid(rows, Vector3.FORWARD)
	builder.set_bone(_bone(skeleton, "pelvis"))
	builder.color = cloth.darkened(0.08)
	builder.torus(Vector3(0.0, 0.286, 0.0), Vector3.UP, 0.144, 0.0075, 12, 4)
	var pocket_y := 0.2
	var pocket_r := maxf(_radius_at(torso, pocket_y), _radius_at(skirt, pocket_y)) + 0.012
	builder.rounded_slab(Vector3(0.09, 0.055, 0.012), Vector3(0.0, pocket_y, -pocket_r), 0.005)


## The radius of a lathe profile at height `y` (0 outside it).
func _radius_at(profile: PackedVector2Array, y: float) -> float:
	for index: int in profile.size() - 1:
		var a := profile[index]
		var b := profile[index + 1]
		if y >= minf(a.y, b.y) and y <= maxf(a.y, b.y) and absf(b.y - a.y) > 0.00001:
			return lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
	return 0.0


func _add_head(builder: RefCounted, skeleton: Skeleton3D, person: Dictionary) -> void:
	builder.set_bone(_bone(skeleton, "head"))
	builder.color = person["skin"]
	builder.sphere(HEAD_CENTRE, HEAD_RADII)
	# Small round ears.
	for side: float in [-1.0, 1.0]:
		builder.sphere(Vector3(0.196 * side, 0.676, 0.012), Vector3(0.03, 0.04, 0.024), 8, 3)


## Big dark bead eyes with a highlight, small brows, a simple mouth and pink
## cheeks (guide 9.1). Expression changes reshape these parts only.
func _add_face(builder: RefCounted, skeleton: Skeleton3D, person: Dictionary) -> void:
	builder.set_bone(_bone(skeleton, "head"))
	var tilt: float = person["brow_tilt"]
	for side: float in [-1.0, 1.0]:
		var eye := _on_face(0.073 * side, EYE_Y, 0.004)
		builder.color = Style.INK
		builder.sphere(eye, Vector3(0.026, 0.032, 0.013), 8, 4)
		builder.color = Style.EYE_SHINE
		builder.sphere(eye + Vector3(-0.008, 0.011, -0.011), Vector3.ONE * 0.0075, 6, 2)
		builder.color = Style.BLUSH
		builder.sphere(_on_face(0.122 * side, 0.636, 0.001), Vector3(0.03, 0.016, 0.008), 6, 2)
		builder.color = person["hair"]
		var inner := _on_face(0.048 * side, BROW_Y, 0.005)
		var outer := _on_face(0.098 * side, BROW_Y + tilt, 0.005)
		builder.capsule(inner, outer, 0.0068, -1.0, 4, 1)
	builder.color = person["skin_shade"]
	builder.sphere(_on_face(0.0, 0.648, 0.002), Vector3(0.016, 0.012, 0.011), 8, 3)
	builder.color = MOUTH
	match String(person["mouth"]):
		"smile":
			builder.torus(_on_face(0.0, 0.632, 0.0), Vector3(0.0, 0.25, -1.0), 0.02, 0.0055, 8, 4, -PI * 0.4, PI * 0.4)
		"down":
			builder.torus(_on_face(0.0, 0.596, 0.0), Vector3(0.0, 0.25, -1.0), 0.018, 0.005, 8, 4, PI * 0.65, PI * 1.35)
		_:
			builder.capsule(_on_face(-0.019, 0.612, 0.001), _on_face(0.019, 0.612, 0.001), 0.0055, -1.0, 4, 1)


## Hair is a dome over the skull, tipped back so its front edge (the fringe)
## ends above the brows; a cap sits higher still (guide 9.1).
func _add_hair(builder: RefCounted, skeleton: Skeleton3D, person: Dictionary) -> void:
	builder.set_bone(_bone(skeleton, "head"))
	var hair: Color = person["hair"]
	builder.color = hair
	match String(person["hair_style"]):
		"cap":
			_dome(builder, 1.04, -14.0, 30.0)
			for x: float in [-0.075, 0.0, 0.075]:
				builder.sphere(_on_face(x, 0.762 - absf(x) * 0.12, -0.012), Vector3(0.044, 0.024, 0.026), 8, 3)
			builder.color = person["cap"]
			_dome(builder, 1.095, 12.0, 16.0)
			builder.sphere(HEAD_CENTRE + Vector3(0.0, 0.2, 0.056), Vector3(0.018, 0.012, 0.018), 6, 3)
			builder.color = (person["cap"] as Color).darkened(0.1)
			builder.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-98.0)), Vector3(0.0, 0.787, -0.152))
			builder.puffy_outline(PackedVector2Array([
				Vector2(-0.135, -0.03), Vector2(0.135, -0.03), Vector2(0.13, 0.03), Vector2(0.10, 0.075),
				Vector2(0.045, 0.104), Vector2(-0.045, 0.104), Vector2(-0.10, 0.075), Vector2(-0.13, 0.03)]), 0.016)
			builder.transform = Transform3D.IDENTITY
		"bun":
			_dome(builder, 1.05, -12.0, 26.0)
			for x: float in [-0.07, 0.0, 0.07]:
				builder.sphere(_on_face(x, 0.762 - absf(x) * 0.15, -0.014), Vector3(0.046, 0.022, 0.026), 8, 3)
			builder.sphere(HEAD_CENTRE + Vector3(0.0, 0.115, 0.17), Vector3(0.075, 0.07, 0.068), 10, 5)
		"low_tail":
			_dome(builder, 1.05, -12.0, 28.0)
			for x: float in [-0.08, 0.0, 0.08]:
				builder.sphere(_on_face(x, 0.764 - absf(x) * 0.12, -0.013), Vector3(0.046, 0.024, 0.026), 8, 3)
			builder.capsule(HEAD_CENTRE + Vector3(0.0, -0.03, 0.2), HEAD_CENTRE + Vector3(0.0, -0.15, 0.215), 0.045, 0.03, 8, 3)
			builder.color = person["tie"]
			builder.torus(HEAD_CENTRE + Vector3(0.0, -0.045, 0.2), Vector3(0.0, 1.0, 0.1), 0.034, 0.009, 10, 5)
		"pigtails":
			_dome(builder, 1.05, -12.0, 26.0)
			for x: float in [-0.08, 0.0, 0.08]:
				builder.sphere(_on_face(x, 0.764 - absf(x) * 0.12, -0.013), Vector3(0.046, 0.024, 0.026), 8, 3)
			for side: float in [-1.0, 1.0]:
				builder.color = hair
				builder.capsule(HEAD_CENTRE + Vector3(0.19 * side, -0.02, 0.07), HEAD_CENTRE + Vector3(0.235 * side, -0.13, 0.08), 0.04, 0.03, 8, 3)
				builder.color = person["tie"]
				builder.sphere(HEAD_CENTRE + Vector3(0.195 * side, -0.01, 0.07), Vector3.ONE * 0.022, 8, 4)


## A cap of the head ellipsoid from `rim_deg` latitude to the crown, `scale`
## times the head size, tipped back by `tilt_deg` (front edge rises).
func _dome(builder: RefCounted, scale: float, rim_deg: float, tilt_deg: float) -> void:
	var profile := PackedVector2Array([Vector2(0.0, sin(deg_to_rad(rim_deg)))])
	for step: int in 6:
		var latitude := deg_to_rad(lerpf(rim_deg, 90.0, float(step) / 5.0))
		profile.append(Vector2(cos(latitude), sin(latitude)))
	var basis := Basis(Vector3.RIGHT, deg_to_rad(tilt_deg)) * Basis.from_scale(HEAD_RADII * scale)
	builder.lathe(profile, 10, Transform3D(basis, HEAD_CENTRE + Vector3(0.0, 0.004, 0.0)))


func _add_arm(builder: RefCounted, skeleton: Skeleton3D, person: Dictionary, side: float) -> void:
	var suffix := "_l" if side < 0.0 else "_r"
	var shoulder := _joint("upper_arm" + suffix)
	var elbow := _joint("forearm" + suffix)
	var wrist := _joint("hand" + suffix)
	var top: Color = person["top"]
	var skin: Color = person["skin"]
	var long_sleeves: bool = person["sleeves"] == "long"
	builder.set_bone(_bone(skeleton, "upper_arm" + suffix))
	if long_sleeves:
		_limb(builder, shoulder, elbow, 0.049, 0.045, -1.0, top, top)
	else:
		_limb(builder, shoulder, elbow, 0.051, 0.043, 0.58, top, skin, 0.006)
	builder.set_bone(_bone(skeleton, "forearm" + suffix))
	if long_sleeves:
		_limb(builder, elbow, wrist, 0.045, 0.040, 0.72, top, skin, 0.004)
	else:
		_limb(builder, elbow, wrist, 0.043, 0.039, -1.0, skin, skin)
	builder.set_bone(_bone(skeleton, "hand" + suffix))
	builder.color = skin
	builder.sphere(wrist + Vector3(0.003 * side, -0.024, -0.004), Vector3(0.043, 0.044, 0.04), 8, 4)


func _add_leg(builder: RefCounted, skeleton: Skeleton3D, person: Dictionary, side: float) -> void:
	var suffix := "_l" if side < 0.0 else "_r"
	var hip := _joint("thigh" + suffix)
	var knee := _joint("shin" + suffix)
	var ankle := _joint("foot" + suffix)
	var lower: Color = person["lower"]
	var skin: Color = person["skin"]
	var kind := String(person["lower_kind"])
	builder.set_bone(_bone(skeleton, "thigh" + suffix))
	match kind:
		"shorts":
			_limb(builder, hip, knee, 0.060, 0.050, 0.62, lower, skin, 0.006)
		"trousers":
			_limb(builder, hip, knee, 0.058, 0.052, -1.0, lower, lower)
		_:
			_limb(builder, hip, knee, 0.054, 0.048, -1.0, skin, skin)
	builder.set_bone(_bone(skeleton, "shin" + suffix))
	if kind == "trousers":
		_limb(builder, knee, ankle, 0.052, 0.048, 0.86, lower, skin, 0.002)
	else:
		_limb(builder, knee, ankle, 0.049, 0.044, -1.0, skin, skin)
	builder.set_bone(_bone(skeleton, "foot" + suffix))
	var shoes: Color = person["shoes"]
	var foot := Vector3(ankle.x, 0.0, 0.0)
	if kind == "shorts":
		# Sandals: a sole, a bare foot and one strap.
		builder.color = skin
		builder.sphere(foot + Vector3(0.0, 0.042, -0.02), Vector3(0.045, 0.034, 0.064), 8, 4)
		builder.color = shoes
		builder.rounded_slab(Vector3(0.082, 0.018, 0.13), foot + Vector3(0.0, 0.009, -0.024), 0.008)
		builder.color = shoes.darkened(0.15)
		builder.capsule(foot + Vector3(-0.038, 0.056, -0.04), foot + Vector3(0.038, 0.056, -0.04), 0.01, -1.0, 4, 1)
	else:
		builder.color = shoes
		builder.sphere(foot + Vector3(0.0, 0.038, -0.022), Vector3(0.05, 0.038, 0.07), 8, 4)
		builder.color = shoes.darkened(0.2)
		builder.rounded_slab(Vector3(0.098, 0.018, 0.146), foot + Vector3(0.0, 0.009, -0.022), 0.008)


## A short soft limb from `from` to `to`, optionally changing colour (and
## radius) at `split` (0..1 along it): sleeves, shorts and cuffs.
func _limb(builder: RefCounted, from: Vector3, to: Vector3, radius_from: float, radius_to: float, split: float, first: Color, second: Color, step: float = 0.0) -> void:
	var axis := to - from
	var length := axis.length()
	var direction := axis / length
	var profile := PackedVector2Array([Vector2(0.0, -radius_from * 0.8), Vector2(radius_from, 0.0)])
	if split > 0.0:
		var at := length * split
		var radius_at := lerpf(radius_from, radius_to, split)
		profile.append_array([Vector2(radius_at + step, at - 0.001), Vector2(radius_at, at + 0.001)])
	profile.append_array([Vector2(radius_to, length), Vector2(0.0, length + radius_to * 0.8)])
	builder.color_rule = func(point: Vector3, _base: Color) -> Color:
		if split <= 0.0:
			return first
		return first if (point - from).dot(direction) < length * split else second
	var helper := Vector3.FORWARD if absf(direction.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := direction.cross(helper).normalized()
	builder.lathe(profile, LIMB_SEGMENTS, Transform3D(Basis(x, direction, x.cross(direction).normalized()), from), 50.0)
	builder.color_rule = Callable()


## Worn red gloves over both hands, hidden until the boxing scene shows them.
func _build_gloves(skeleton: Skeleton3D) -> ArrayMesh:
	var builder := SoftMesh.new()
	builder.enable_skinning()
	builder.select_surface(MaterialBuilder.SURFACE_ROUND)
	for side: float in [-1.0, 1.0]:
		builder.set_bone(_bone(skeleton, "hand_l" if side < 0.0 else "hand_r"))
		var wrist := _joint("hand_l" if side < 0.0 else "hand_r")
		builder.color = GLOVE_CUFF
		builder.capsule(wrist + Vector3(0.0, 0.012, 0.0), wrist + Vector3(0.0, -0.01, 0.0), 0.05, -1.0, 10, 2)
		builder.color = GLOVE_RED
		builder.sphere(wrist + Vector3(0.0, -0.05, -0.01), Vector3(0.068, 0.07, 0.07))
		builder.sphere(wrist + Vector3(-0.045 * side, -0.035, -0.04), Vector3(0.028, 0.034, 0.028), 8, 4)
		builder.color = GLOVE_RED.lightened(0.22)
		builder.sphere(wrist + Vector3(0.0, -0.075, -0.045), Vector3(0.04, 0.026, 0.03), 8, 3)
	return builder.commit(MaterialBuilder.surface_materials())


func _bone(skeleton: Skeleton3D, bone_name: String) -> int:
	return skeleton.find_bone(bone_name)


func _joint(bone_name: String) -> Vector3:
	for row: Array in BONES:
		if row[0] == bone_name:
			return row[2]
	return Vector3.ZERO


## A point on the front of the head at (x, y), pushed out by `lift`.
func _on_face(x: float, y: float, lift: float) -> Vector3:
	var u := x / HEAD_RADII.x
	var v := (y - HEAD_CENTRE.y) / HEAD_RADII.y
	var z := -HEAD_RADII.z * sqrt(maxf(0.0, 1.0 - u * u - v * v))
	var normal := Vector3(x / (HEAD_RADII.x * HEAD_RADII.x), (y - HEAD_CENTRE.y) / (HEAD_RADII.y * HEAD_RADII.y), z / (HEAD_RADII.z * HEAD_RADII.z)).normalized()
	return Vector3(x, y, z) + normal * lift


# --- Clip helpers -------------------------------------------------------------

## Keys the whole body at `time`: `base` with `changes` on top. `offset`
## moves the whole body, `tip` pitches it backward around the feet, `breath`
## lifts the chest. Keying every joint in every clip keeps blends clean.
func _key(clip: RefCounted, base: Dictionary, time: float, changes: Dictionary = {}, offset: Vector3 = Vector3.ZERO, tip: float = 0.0, breath: float = 0.0) -> void:
	clip.rot("root", time, Vector3(tip, 0, 0))
	clip.move("root", time, offset)
	clip.move("spine_lower", time, Vector3(0.0, breath, 0.0))
	for bone: String in base:
		clip.rot(bone, time, changes.get(bone, base[bone]))


## A looping breath (guide 10): 1.35 rad/s, the chest rising 0.012 m and the
## arms swinging 0.05 rad, layered on `base` + `changes`.
func _breathing_loop(clip_name: StringName, base: Dictionary, changes: Dictionary = {}, offset: Vector3 = Vector3.ZERO) -> RefCounted:
	var length := TAU / Style.BREATH_RAD_PER_SEC
	var clip := RigBuilder.Clip.new(_skeleton_for_clips(), clip_name, length, true)
	var swing := rad_to_deg(Style.BREATH_ARM_SWING)
	for step: int in 5:
		var time := length * float(step) / 4.0
		var wave := sin(TAU * float(step) / 4.0)
		var breath := Style.BREATH_BOB * (0.5 - 0.5 * cos(TAU * float(step) / 4.0))
		var pose := base.merged(changes, true)
		var moved := pose.duplicate()
		for arm: String in ["upper_arm_l", "upper_arm_r"]:
			if pose.has(arm):
				var angle: Vector3 = pose[arm]
				moved[arm] = angle + Vector3(swing * wave * (1.0 if arm == "upper_arm_l" else -1.0), 0.0, 0.0)
		var head: Vector3 = pose.get("head", Vector3.ZERO)
		moved["head"] = head + Vector3(-1.5 * wave, 0.0, 0.0)
		_key(clip, moved, time, {}, offset, 0.0, breath)
	return clip


var _clip_skeleton: Skeleton3D


## Clips only need bone names and rests; one shared skeleton serves them all.
func _skeleton_for_clips() -> Skeleton3D:
	if _clip_skeleton == null:
		_clip_skeleton = RigBuilder.make_skeleton(BONES)
	return _clip_skeleton


func _clip(clip_name: StringName, length: float, loop: bool = false) -> RefCounted:
	return RigBuilder.Clip.new(_skeleton_for_clips(), clip_name, length, loop)


# --- Darto: fishing and Market (GDD 172.1) ------------------------------------

## Relaxed fishing stance: rod held forward and up in the right hand, left hand
## near the reel, a slight forward slouch. Degrees: X pitch (positive swings a
## hanging limb forward), Y yaw, Z roll.
const FISHING_POSE: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-3, 0, 0),
	"spine_upper": Vector3(-2, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(-3, 0, 0),
	"upper_arm_r": Vector3(44, 0, 10),
	"forearm_r": Vector3(46, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(40, 0, 22),
	"forearm_l": Vector3(58, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(6, 0, -3),
	"shin_l": Vector3(-6, 0, 0),
	"foot_l": Vector3(0, 0, 0),
	"thigh_r": Vector3(-4, 0, 3),
	"shin_r": Vector3(-3, 0, 0),
	"foot_r": Vector3(7, 0, 0),
}


func _build_darto_clips() -> Array:
	var clips: Array = []
	var back_swing := {
		"upper_arm_r": Vector3(130, 0, 10), "forearm_r": Vector3(50, 0, 0),
		"spine_lower": Vector3(3, 0, 0), "spine_upper": Vector3(6, -14, 0),
		"upper_arm_l": Vector3(14, 0, -4), "forearm_l": Vector3(22, 0, 0), "head": Vector3(-2, 0, 0),
	}
	var forward_swing := {
		"upper_arm_r": Vector3(64, 0, 4), "forearm_r": Vector3(10, 0, 0),
		"spine_lower": Vector3(-8, 0, 0), "spine_upper": Vector3(-10, 8, 0),
		"upper_arm_l": Vector3(16, 0, -4), "forearm_l": Vector3(26, 0, 0),
	}
	var reel := {
		"upper_arm_r": Vector3(52, 0, 10), "forearm_r": Vector3(58, 0, 0),
		"spine_lower": Vector3(4, 0, 0), "spine_upper": Vector3(3, 0, 0),
		"upper_arm_l": Vector3(44, 0, 22), "forearm_l": Vector3(66, 0, 0), "head": Vector3(-6, 0, 0),
	}

	clips.append(_breathing_loop(&"idle_fishing", FISHING_POSE))

	var prepare := _clip(&"cast_prepare", 0.30)
	_key(prepare, FISHING_POSE, 0.0)
	_key(prepare, FISHING_POSE, 0.30, back_swing)
	clips.append(prepare)

	# The float leaves the rod tip at 0.18 s here, which is 0.48 s into the cast.
	var forward := _clip(&"cast_forward", 0.42)
	_key(forward, FISHING_POSE, 0.0, back_swing)
	_key(forward, FISHING_POSE, 0.18, {
		"upper_arm_r": Vector3(92, 0, 6), "forearm_r": Vector3(28, 0, 0),
		"spine_lower": Vector3(-3, 0, 0), "spine_upper": Vector3(-4, -2, 0)})
	_key(forward, FISHING_POSE, 0.42, forward_swing)
	forward.mark(&"release_float", 0.18)
	clips.append(forward)

	var settle := _clip(&"cast_settle", 0.63)
	_key(settle, FISHING_POSE, 0.0, forward_swing)
	_key(settle, FISHING_POSE, 0.33, {"upper_arm_r": Vector3(52, 0, 6), "forearm_r": Vector3(36, 0, 0), "spine_upper": Vector3(-5, 2, 0)})
	_key(settle, FISHING_POSE, 0.63)
	settle.mark(&"cast_complete", 0.63)
	clips.append(settle)

	var reel_hold := _clip(&"reel_hold", 1.0, true)
	_key(reel_hold, FISHING_POSE, 0.0, reel)
	_key(reel_hold, FISHING_POSE, 0.5, reel.merged({"forearm_l": Vector3(84, 0, 0), "upper_arm_l": Vector3(48, 0, 24), "upper_arm_r": Vector3(54, 0, 10)}, true))
	_key(reel_hold, FISHING_POSE, 1.0, reel)
	clips.append(reel_hold)

	var relax := _clip(&"reel_release_relax", 0.35)
	_key(relax, FISHING_POSE, 0.0, reel)
	_key(relax, FISHING_POSE, 0.35, {"upper_arm_r": Vector3(46, 0, 10), "forearm_r": Vector3(50, 0, 0)})
	clips.append(relax)

	var jerk := _clip(&"line_stress_jerk", 0.30)
	_key(jerk, FISHING_POSE, 0.0, reel)
	_key(jerk, FISHING_POSE, 0.10, reel.merged({"upper_arm_r": Vector3(36, 0, 10), "forearm_r": Vector3(46, 0, 0), "spine_upper": Vector3(-10, 0, 0)}, true))
	_key(jerk, FISHING_POSE, 0.30, reel)
	clips.append(jerk)

	var land := _clip(&"land_fish", 1.10)
	_key(land, FISHING_POSE, 0.0, reel)
	_key(land, FISHING_POSE, 0.30, {
		"upper_arm_r": Vector3(104, 0, 12), "forearm_r": Vector3(70, 0, 0), "spine_lower": Vector3(10, 0, 0),
		"spine_upper": Vector3(10, 0, 0), "upper_arm_l": Vector3(76, 0, 18), "forearm_l": Vector3(76, 0, 0)})
	_key(land, FISHING_POSE, 0.55, {
		"upper_arm_r": Vector3(124, 0, 12), "forearm_r": Vector3(52, 0, 0), "spine_lower": Vector3(8, 0, 0),
		"spine_upper": Vector3(8, 0, 0), "upper_arm_l": Vector3(66, 0, 16), "forearm_l": Vector3(66, 0, 0), "head": Vector3(8, 0, 0)},
		Vector3(0, 0.01, 0))
	_key(land, FISHING_POSE, 0.80, {"upper_arm_r": Vector3(78, 0, 10), "forearm_r": Vector3(64, 0, 0), "spine_upper": Vector3(2, 0, 0)})
	_key(land, FISHING_POSE, 1.10, {"upper_arm_r": Vector3(60, 0, 10), "forearm_r": Vector3(56, 0, 0)})
	land.mark(&"fish_reveal", 0.55)
	clips.append(land)

	var empty := _clip(&"empty_pull", 0.80)
	_key(empty, FISHING_POSE, 0.0)
	_key(empty, FISHING_POSE, 0.20, {"upper_arm_r": Vector3(88, 0, 10), "forearm_r": Vector3(64, 0, 0), "spine_upper": Vector3(4, 0, 0)})
	_key(empty, FISHING_POSE, 0.50, {"upper_arm_r": Vector3(64, 0, 10), "forearm_r": Vector3(56, 0, 0)})
	_key(empty, FISHING_POSE, 0.80)
	clips.append(empty)

	var react := _clip(&"fish_escape_react", 1.00)
	_key(react, FISHING_POSE, 0.0)
	_key(react, FISHING_POSE, 0.30, {"spine_upper": Vector3(-10, 0, 0), "head": Vector3(-18, 0, 0), "upper_arm_r": Vector3(26, 0, 10), "forearm_r": Vector3(40, 0, 0)}, Vector3(0, -0.006, 0))
	_key(react, FISHING_POSE, 0.55, {"spine_upper": Vector3(-10, 0, 0), "head": Vector3(-14, 16, 0), "upper_arm_r": Vector3(26, 0, 10), "forearm_r": Vector3(40, 0, 0)}, Vector3(0, -0.006, 0))
	_key(react, FISHING_POSE, 0.75, {"spine_upper": Vector3(-9, 0, 0), "head": Vector3(-14, -16, 0), "upper_arm_r": Vector3(28, 0, 10), "forearm_r": Vector3(42, 0, 0)}, Vector3(0, -0.006, 0))
	_key(react, FISHING_POSE, 1.00)
	clips.append(react)

	var bucket := _clip(&"bucket_add", 0.75)
	_key(bucket, FISHING_POSE, 0.0)
	_key(bucket, FISHING_POSE, 0.30, {
		"spine_lower": Vector3(-20, 0, 0), "spine_upper": Vector3(-18, -22, 0), "head": Vector3(-6, -10, 0),
		"upper_arm_l": Vector3(70, 0, 4), "forearm_l": Vector3(18, 0, 0), "upper_arm_r": Vector3(34, 0, 10),
		"thigh_l": Vector3(18, 0, -3), "shin_l": Vector3(-22, 0, 0), "thigh_r": Vector3(10, 0, 3), "shin_r": Vector3(-16, 0, 0)},
		Vector3(0, -0.01, 0))
	_key(bucket, FISHING_POSE, 0.45, {
		"spine_lower": Vector3(-22, 0, 0), "spine_upper": Vector3(-20, -22, 0), "head": Vector3(-6, -10, 0),
		"upper_arm_l": Vector3(78, 0, 4), "forearm_l": Vector3(10, 0, 0), "upper_arm_r": Vector3(34, 0, 10),
		"thigh_l": Vector3(18, 0, -3), "shin_l": Vector3(-22, 0, 0), "thigh_r": Vector3(10, 0, 3), "shin_r": Vector3(-16, 0, 0)},
		Vector3(0, -0.01, 0))
	_key(bucket, FISHING_POSE, 0.75)
	bucket.mark(&"bucket_commit", 0.45)
	clips.append(bucket)

	# At the warung: arms down, weight on one leg, a slow breath.
	clips.append(_breathing_loop(&"market_idle", FISHING_POSE, STANDING))
	return clips


## Standing at ease: arms down and a little out from the round body.
const STANDING: Dictionary = {
	"upper_arm_r": Vector3(4, 0, 12), "forearm_r": Vector3(12, 0, 0),
	"upper_arm_l": Vector3(6, 0, -12), "forearm_l": Vector3(14, 0, 0),
	"spine_lower": Vector3(-1, 0, 0), "spine_upper": Vector3(-2, 0, 0), "head": Vector3(-2, 0, 0),
}


# --- Darto: story clips -----------------------------------------------------

## Seated on a plastic chair: thighs level, shins down, the hips 0.076 m lower.
const SIT_DROP := Vector3(0, -0.076, 0)


func _build_darto_story_clips() -> Array:
	var clips: Array = []
	var sitting := {"thigh_l": Vector3(84, 0, -8), "thigh_r": Vector3(84, 0, 8), "shin_l": Vector3(-82, 0, 0), "shin_r": Vector3(-82, 0, 0),
		"upper_arm_r": Vector3(30, 0, 14), "forearm_r": Vector3(40, 0, 0), "upper_arm_l": Vector3(30, 0, -14), "forearm_l": Vector3(40, 0, 0),
		"spine_lower": Vector3(-6, 0, 0), "spine_upper": Vector3(-4, 0, 0), "head": Vector3(-2, 0, 0)}
	clips.append(_breathing_loop(&"sit_lake", DANCE_POSE, sitting, SIT_DROP))

	# Phone in the right hand in front of the chest, head down to read it.
	var holding := {"upper_arm_r": Vector3(54, 0, 6), "forearm_r": Vector3(96, 0, -50), "head": Vector3(-14, 0, 0),
		"upper_arm_l": Vector3(8, 0, -12), "forearm_l": Vector3(14, 0, 0)}
	var phone := _clip(&"phone_look", 3.0, true)
	_key(phone, DANCE_POSE, 0.0, holding)
	_key(phone, DANCE_POSE, 1.5, holding.merged({"head": Vector3(-16, 4, 0)}, true), Vector3.ZERO, 0.0, Style.BREATH_BOB)
	_key(phone, DANCE_POSE, 3.0, holding)
	clips.append(phone)

	var phone_sit := _clip(&"phone_sit", 3.0, true)
	_key(phone_sit, DANCE_POSE, 0.0, sitting.merged(holding, true), SIT_DROP)
	_key(phone_sit, DANCE_POSE, 1.5, sitting.merged(holding, true), SIT_DROP, 0.0, Style.BREATH_BOB)
	_key(phone_sit, DANCE_POSE, 3.0, sitting.merged(holding, true), SIT_DROP)
	clips.append(phone_sit)

	var laugh := _clip(&"small_laugh", 1.0)
	_key(laugh, DANCE_POSE, 0.0)
	_key(laugh, DANCE_POSE, 0.25, {"spine_upper": Vector3(-6, 0, 0), "head": Vector3(-8, 0, 0)}, Vector3(0, 0.006, 0))
	_key(laugh, DANCE_POSE, 0.5, {"spine_upper": Vector3(2, 0, 0), "head": Vector3(2, 0, 0)})
	_key(laugh, DANCE_POSE, 1.0)
	clips.append(laugh)
	return clips


# --- Bu Yati (GDD 172.8) ------------------------------------------------------

## Standing behind the counter with both hands resting near it.
const COUNTER_POSE: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-2, 0, 0),
	"spine_upper": Vector3(-2, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(-2, 0, 0),
	"upper_arm_r": Vector3(30, 0, 12),
	"forearm_r": Vector3(44, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(28, 0, -12),
	"forearm_l": Vector3(48, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(0, 0, -2),
	"shin_l": Vector3(0, 0, 0),
	"foot_l": Vector3(0, 0, 0),
	"thigh_r": Vector3(0, 0, 2),
	"shin_r": Vector3(0, 0, 0),
	"foot_r": Vector3(0, 0, 0),
}


## Small, economical movements only.
func _build_bu_yati_clips() -> Array:
	var clips: Array = []
	clips.append(_breathing_loop(&"market_idle", COUNTER_POSE))

	var look := _clip(&"look_darto", 1.2)
	_key(look, COUNTER_POSE, 0.0)
	_key(look, COUNTER_POSE, 0.35, {"head": Vector3(-4, 16, 0), "neck": Vector3(0, 6, 0)})
	_key(look, COUNTER_POSE, 0.9, {"head": Vector3(-4, 16, 0), "neck": Vector3(0, 6, 0)})
	_key(look, COUNTER_POSE, 1.2)
	clips.append(look)

	# One hand to the scale, a glance down, then back.
	var weigh := _clip(&"weigh_fish", 1.6)
	var weighing := {"upper_arm_r": Vector3(56, 0, -2), "forearm_r": Vector3(36, 0, 0), "head": Vector3(-14, -8, 0), "spine_upper": Vector3(-6, 0, 0)}
	_key(weigh, COUNTER_POSE, 0.0)
	_key(weigh, COUNTER_POSE, 0.5, weighing)
	_key(weigh, COUNTER_POSE, 1.1, weighing)
	_key(weigh, COUNTER_POSE, 1.6)
	clips.append(weigh)

	var count := _clip(&"cash_count", 1.4)
	_key(count, COUNTER_POSE, 0.0)
	for step: int in 4:
		var time := 0.25 + 0.25 * float(step)
		var flick := 66.0 if step % 2 == 0 else 52.0
		_key(count, COUNTER_POSE, time, {
			"upper_arm_r": Vector3(40, 0, 2), "forearm_r": Vector3(flick, 0, 0),
			"upper_arm_l": Vector3(40, 0, -2), "forearm_l": Vector3(60, 0, 0), "head": Vector3(-12, 0, 0)})
	_key(count, COUNTER_POSE, 1.4)
	clips.append(count)

	# Her deadpan beat is a tiny head settle.
	var blink := _clip(&"deadpan_blink", 0.6)
	_key(blink, COUNTER_POSE, 0.0)
	_key(blink, COUNTER_POSE, 0.3, {"head": Vector3(-5, 0, 0)}, Vector3(0, -0.003, 0))
	_key(blink, COUNTER_POSE, 0.6)
	clips.append(blink)
	return clips


# --- Rini and Nisa (GDD 151, 152, 172.8) --------------------------------------

func _build_family_clips() -> Array:
	var clips: Array = []
	clips.append(_breathing_loop(&"idle_home", COUNTER_POSE, {
		"upper_arm_r": Vector3(6, 0, 12), "forearm_r": Vector3(10, 0, 0), "upper_arm_l": Vector3(6, 0, -12), "forearm_l": Vector3(10, 0, 0)}))

	var sitting := {"thigh_l": Vector3(84, 0, -6), "thigh_r": Vector3(84, 0, 6), "shin_l": Vector3(-80, 0, 0), "shin_r": Vector3(-80, 0, 0),
		"upper_arm_r": Vector3(30, 0, 12), "forearm_r": Vector3(40, 0, 0), "upper_arm_l": Vector3(30, 0, -12), "forearm_l": Vector3(40, 0, 0)}
	clips.append(_breathing_loop(&"sit_lake", COUNTER_POSE, sitting, SIT_DROP))

	var look := _clip(&"look_darto", 1.2)
	_key(look, COUNTER_POSE, 0.0)
	_key(look, COUNTER_POSE, 0.4, {"head": Vector3(-4, 18, 0), "neck": Vector3(0, 8, 0)})
	_key(look, COUNTER_POSE, 1.2, {"head": Vector3(-4, 18, 0), "neck": Vector3(0, 8, 0)})
	clips.append(look)

	var pause := _clip(&"deadpan_pause", 1.0)
	_key(pause, COUNTER_POSE, 0.0)
	_key(pause, COUNTER_POSE, 0.5, {"head": Vector3(-8, 0, 0)})
	_key(pause, COUNTER_POSE, 1.0)
	clips.append(pause)

	var smile := _clip(&"small_smile", 1.0)
	_key(smile, COUNTER_POSE, 0.0)
	_key(smile, COUNTER_POSE, 0.4, {"head": Vector3(4, 0, 6)}, Vector3(0, 0.004, 0))
	_key(smile, COUNTER_POSE, 1.0, {"head": Vector3(2, 0, 3)})
	clips.append(smile)

	var shoes := _clip(&"put_on_shoes", 2.0)
	var bent := {"spine_lower": Vector3(-34, 0, 0), "spine_upper": Vector3(-26, 0, 0), "head": Vector3(8, 0, 0),
		"upper_arm_r": Vector3(70, 0, 12), "forearm_r": Vector3(20, 0, 0), "upper_arm_l": Vector3(70, 0, -12), "forearm_l": Vector3(20, 0, 0),
		"thigh_r": Vector3(40, 0, 4), "shin_r": Vector3(-50, 0, 0)}
	_key(shoes, COUNTER_POSE, 0.0)
	_key(shoes, COUNTER_POSE, 0.6, bent, Vector3(0, -0.012, 0))
	_key(shoes, COUNTER_POSE, 1.4, bent, Vector3(0, -0.012, 0))
	_key(shoes, COUNTER_POSE, 2.0)
	clips.append(shoes)

	var phone := _clip(&"phone_call_idle", 3.0, true)
	var holding := {"upper_arm_r": Vector3(24, 0, 34), "forearm_r": Vector3(140, 0, 0), "head": Vector3(-4, 8, 0)}
	_key(phone, COUNTER_POSE, 0.0, holding)
	_key(phone, COUNTER_POSE, 1.5, holding.merged({"head": Vector3(-6, -4, 0)}, true), Vector3.ZERO, 0.0, Style.BREATH_BOB)
	_key(phone, COUNTER_POSE, 3.0, holding)
	clips.append(phone)

	var lean := _clip(&"lean_forward", 0.8)
	_key(lean, COUNTER_POSE, 0.0, sitting, SIT_DROP)
	_key(lean, COUNTER_POSE, 0.4, sitting.merged({"spine_upper": Vector3(-16, 0, 0), "head": Vector3(6, 0, 0)}, true), SIT_DROP)
	_key(lean, COUNTER_POSE, 0.8, sitting.merged({"spine_upper": Vector3(-14, 0, 0)}, true), SIT_DROP)
	clips.append(lean)

	var laugh := _clip(&"laugh_small", 0.8)
	_key(laugh, COUNTER_POSE, 0.0, sitting, SIT_DROP)
	for step: int in range(1, 4):
		_key(laugh, COUNTER_POSE, 0.2 * float(step), sitting.merged({"spine_upper": Vector3(-6 if step % 2 == 1 else 2, 0, 0), "head": Vector3(-8 if step % 2 == 1 else 0, 0, 0)}, true), SIT_DROP + Vector3(0, 0.004 if step % 2 == 1 else 0.0, 0))
	_key(laugh, COUNTER_POSE, 0.8, sitting, SIT_DROP)
	clips.append(laugh)
	return clips


# --- Darto: boxing (GDD 172.2) ------------------------------------------------

## Guarded but slightly awkward: round gloves up by the chin, knees soft.
const BOX_GUARD: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-6, 0, 0),
	"spine_upper": Vector3(-6, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(4, 0, 0),
	"upper_arm_r": Vector3(62, 0, 18),
	"forearm_r": Vector3(96, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(68, 0, -16),
	"forearm_l": Vector3(90, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(22, 0, -4),
	"shin_l": Vector3(-30, 0, 0),
	"foot_l": Vector3(8, 0, 0),
	"thigh_r": Vector3(-6, 0, 5),
	"shin_r": Vector3(-22, 0, 0),
	"foot_r": Vector3(22, 0, 0),
}
## Soft knees drop the hips; the root offset keeps the feet on the ground.
const BOX_CROUCH := Vector3(0, -0.012, 0)


func _build_darto_boxing_clips() -> Array:
	var clips: Array = []

	var idle := _clip(&"box_idle", 1.2, true)
	for step: int in 5:
		var down := step % 2 == 1
		_box_key(idle, 0.3 * float(step), {
			"spine_upper": Vector3(-8 if down else -6, 0, 0),
			"upper_arm_l": Vector3(71 if down else 68, 0, -16), "upper_arm_r": Vector3(65 if down else 62, 0, 18),
		}, Vector3(0, -0.006 if down else 0.0, 0))
	clips.append(idle)

	# A lean from the hips with the head kept level. The lean is reached at
	# `lean_peak`, where the scene can hold it until the punch has passed.
	for side: float in [-1.0, 1.0]:
		var dodge := _clip(&"box_dodge_left" if side < 0.0 else &"box_dodge_right", 0.32)
		var lean := {
			"spine_lower": Vector3(-6, 0, -16 * side), "spine_upper": Vector3(-6, 0, -12 * side),
			"head": Vector3(4, 0, 14 * side), "pelvis": Vector3(0, 0, -6 * side),
			"thigh_l": Vector3(22, 0, -4 + 9 * side), "thigh_r": Vector3(-6, 0, 5 + 9 * side),
		}
		_box_key(dodge, 0.0)
		_box_key(dodge, 0.10, lean, Vector3(0.12 * side, -0.012, 0))
		_box_key(dodge, 0.20, lean, Vector3(0.12 * side, -0.012, 0))
		_box_key(dodge, 0.32)
		dodge.mark(&"lean_peak", 0.10)
		clips.append(dodge)

	# Jab: the lead (left) hand snaps out. Lands at 0.11 s, back by 0.36 s.
	var jab := _clip(&"box_jab", 0.36)
	var jab_out := {
		"upper_arm_l": Vector3(92, 0, -4), "forearm_l": Vector3(6, 0, 0),
		"spine_upper": Vector3(-10, -14, 0), "spine_lower": Vector3(-7, -6, 0)}
	_box_key(jab, 0.0)
	_box_key(jab, 0.11, jab_out, Vector3(0, 0, -0.03))
	_box_key(jab, 0.17, jab_out, Vector3(0, 0, -0.03))
	_box_key(jab, 0.36)
	jab.mark(&"hit_frame", 0.11)
	clips.append(jab)

	# Cross: the rear (right) hand with the whole body behind it. Lands at
	# 0.20 s, back by 0.64 s.
	var cross := _clip(&"box_cross", 0.64)
	var cross_load := {
		"upper_arm_r": Vector3(40, 0, 26), "forearm_r": Vector3(120, 0, 0),
		"spine_upper": Vector3(-6, -16, 0)}
	var cross_out := {
		"upper_arm_r": Vector3(94, 0, 2), "forearm_r": Vector3(4, 0, 0),
		"upper_arm_l": Vector3(52, 0, -18), "spine_upper": Vector3(-14, 28, 0),
		"spine_lower": Vector3(-9, 12, 0), "thigh_r": Vector3(4, 0, 5), "shin_r": Vector3(-30, 0, 0)}
	_box_key(cross, 0.0)
	_box_key(cross, 0.08, cross_load)
	_box_key(cross, 0.20, cross_out, Vector3(0, -0.004, -0.06))
	_box_key(cross, 0.30, cross_out, Vector3(0, -0.004, -0.06))
	_box_key(cross, 0.64)
	cross.mark(&"hit_frame", 0.20)
	clips.append(cross)

	# Knocked toward his left (a punch from the right) and the mirror of it.
	for side: float in [-1.0, 1.0]:
		var hit := _clip(&"box_hit_left" if side < 0.0 else &"box_hit_right", 0.45)
		var rocked := {
			"spine_lower": Vector3(8, 10 * side, -10 * side), "spine_upper": Vector3(10, 16 * side, -8 * side),
			"head": Vector3(-12, 22 * side, -10 * side),
			"upper_arm_l": Vector3(40, 0, -34), "upper_arm_r": Vector3(36, 0, 34),
			"forearm_l": Vector3(70, 0, 0), "forearm_r": Vector3(74, 0, 0)}
		_box_key(hit, 0.0)
		_box_key(hit, 0.08, rocked, Vector3(0.05 * side, -0.006, 0.05))
		_box_key(hit, 0.24, rocked, Vector3(0.06 * side, -0.006, 0.06))
		_box_key(hit, 0.45)
		clips.append(hit)

	# Down on his back, arms out. The last pose is held.
	var ko := _clip(&"box_ko", 1.2)
	var stagger := {
		"spine_lower": Vector3(10, 0, 0), "spine_upper": Vector3(14, 0, 0), "head": Vector3(-16, 0, 0),
		"upper_arm_l": Vector3(20, 0, -40), "upper_arm_r": Vector3(18, 0, 40),
		"forearm_l": Vector3(40, 0, 0), "forearm_r": Vector3(44, 0, 0)}
	var flat := {
		"spine_lower": Vector3(0, 0, 0), "spine_upper": Vector3(0, 0, 0), "head": Vector3(-8, 0, 0),
		"upper_arm_l": Vector3(0, 0, -70), "upper_arm_r": Vector3(0, 0, 70),
		"forearm_l": Vector3(12, 0, 0), "forearm_r": Vector3(12, 0, 0),
		"thigh_l": Vector3(4, 0, -10), "thigh_r": Vector3(-2, 0, 10),
		"shin_l": Vector3(-6, 0, 0), "shin_r": Vector3(-4, 0, 0), "foot_l": Vector3(0, 0, 0), "foot_r": Vector3(0, 0, 0)}
	_box_key(ko, 0.0)
	_box_key(ko, 0.3, stagger, Vector3(0, -0.006, 0.06), 14.0)
	_box_key(ko, 0.75, flat, Vector3(0, 0.17, 0.12), 86.0)
	_box_key(ko, 0.88, flat, Vector3(0, 0.19, 0.12), 82.0)
	_box_key(ko, 1.2, flat, Vector3(0, 0.17, 0.12), 86.0)
	clips.append(ko)

	# Understated: the guard comes down and one fist goes up, barely.
	var win := _clip(&"box_win", 1.1)
	var relief := {
		"spine_lower": Vector3(-2, 0, 0), "spine_upper": Vector3(-2, 0, 0), "head": Vector3(-6, 0, 0),
		"upper_arm_l": Vector3(8, 0, -12), "forearm_l": Vector3(20, 0, 0),
		"upper_arm_r": Vector3(70, 0, 12), "forearm_r": Vector3(96, 0, 0),
		"thigh_l": Vector3(6, 0, -4), "shin_l": Vector3(-8, 0, 0), "foot_l": Vector3(2, 0, 0),
		"thigh_r": Vector3(-2, 0, 5), "shin_r": Vector3(-6, 0, 0), "foot_r": Vector3(8, 0, 0)}
	_box_key(win, 0.0)
	_box_key(win, 0.45, relief, -BOX_CROUCH)
	_box_key(win, 0.7, relief.merged({"upper_arm_r": Vector3(80, 0, 12), "head": Vector3(-9, 0, 0)}, true), -BOX_CROUCH + Vector3(0, 0.006, 0))
	_box_key(win, 1.1, relief, -BOX_CROUCH)
	clips.append(win)
	return clips


## The boxing guard with `changes` on top; offsets are from the crouch.
func _box_key(clip: RefCounted, time: float, changes: Dictionary = {}, offset: Vector3 = Vector3.ZERO, tip: float = 0.0) -> void:
	_key(clip, BOX_GUARD, time, changes, BOX_CROUCH + offset, tip)


# --- Darto: arm wrestling (GDD 172.3) -----------------------------------------
# Leaning over the table with his right elbow on the pad. The forearm's lean
# left or right is set by the scene from the match position; these clips are
# the effort in the rest of his body.

const ARM_POSE: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-14, 0, 0),
	"spine_upper": Vector3(-16, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(14, 0, 0),
	"upper_arm_r": Vector3(80, 0, 6),
	"forearm_r": Vector3(96, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(62, 0, -20),
	"forearm_l": Vector3(50, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(18, 0, -4),
	"shin_l": Vector3(-14, 0, 0),
	"foot_l": Vector3(-4, 0, 0),
	"thigh_r": Vector3(-10, 0, 6),
	"shin_r": Vector3(-6, 0, 0),
	"foot_r": Vector3(16, 0, 0),
}
const ARM_DROP := Vector3(0, -0.01, 0)


func _build_darto_arm_clips() -> Array:
	var clips: Array = []

	var grip := _clip(&"arm_idle_grip", 2.0, true)
	_arm_key(grip, 0.0)
	_arm_key(grip, 1.0, {"spine_upper": Vector3(-20, 0, 0), "head": Vector3(20, 0, 0)}, Vector3.ZERO, Style.BREATH_BOB)
	_arm_key(grip, 2.0)
	clips.append(grip)

	var light := _clip(&"arm_push_light", 0.5, true)
	var leaning := {"spine_upper": Vector3(-22, 0, -4), "spine_lower": Vector3(-16, 0, -3), "head": Vector3(16, 0, 4)}
	_arm_key(light, 0.0, leaning)
	_arm_key(light, 0.25, leaning.merged({"spine_upper": Vector3(-24, 0, -5)}, true))
	_arm_key(light, 0.5, leaning)
	clips.append(light)

	# Everything into it: shoulder over the grip, free hand clamped on the table.
	var hard := _clip(&"arm_push_hard", 0.2, true)
	var straining := {
		"spine_upper": Vector3(-28, 0, -9), "spine_lower": Vector3(-18, 0, -6), "head": Vector3(8, 0, 8),
		"upper_arm_l": Vector3(60, 0, -10), "forearm_l": Vector3(28, 0, 0),
		"thigh_l": Vector3(24, 0, -4), "shin_l": Vector3(-20, 0, 0)}
	_arm_key(hard, 0.0, straining)
	_arm_key(hard, 0.1, straining.merged({"spine_upper": Vector3(-29, 0, -10), "head": Vector3(7, 0, 9)}, true), Vector3(0, -0.002, 0))
	_arm_key(hard, 0.2, straining)
	clips.append(hard)

	# Out of breath: the body sags while the arm holds on.
	var recover := _clip(&"arm_recover", 1.2, true)
	var tired := {"spine_upper": Vector3(-12, 0, 0), "spine_lower": Vector3(-12, 0, 0), "head": Vector3(26, 0, 0),
		"upper_arm_l": Vector3(24, 0, -12), "forearm_l": Vector3(26, 0, 0)}
	_arm_key(recover, 0.0, tired)
	_arm_key(recover, 0.6, tired.merged({"spine_upper": Vector3(-10, 0, 0), "head": Vector3(28, 0, 0)}, true), Vector3.ZERO, Style.BREATH_BOB * 1.5)
	_arm_key(recover, 1.2, tired)
	clips.append(recover)

	var win := _clip(&"arm_win", 1.0)
	_arm_key(win, 0.0)
	var upright := {"spine_upper": Vector3(-6, 0, 0), "spine_lower": Vector3(-6, 0, 0), "head": Vector3(-4, 0, 0),
		"upper_arm_l": Vector3(160, 0, -14), "forearm_l": Vector3(20, 0, 0)}
	_arm_key(win, 0.5, upright, Vector3(0, 0.01, 0))
	_arm_key(win, 1.0, upright, Vector3(0, 0.01, 0))
	clips.append(win)

	var lose := _clip(&"arm_lose", 1.0)
	_arm_key(lose, 0.0)
	var slumped := {"spine_upper": Vector3(-30, 0, 0), "spine_lower": Vector3(-22, 0, 0), "head": Vector3(-8, 0, 0),
		"upper_arm_l": Vector3(24, 0, -8), "forearm_l": Vector3(10, 0, 0)}
	_arm_key(lose, 0.5, slumped, Vector3(0, -0.01, 0))
	_arm_key(lose, 1.0, slumped, Vector3(0, -0.012, 0))
	clips.append(lose)
	return clips


func _arm_key(clip: RefCounted, time: float, changes: Dictionary = {}, offset: Vector3 = Vector3.ZERO, breath: float = 0.0) -> void:
	_key(clip, ARM_POSE, time, changes, ARM_DROP + offset, 0.0, breath)


# --- Darto: dance (GDD 172.4) -------------------------------------------------
# Standing, facing the audience. One move per lane: lanes 1 and 2 are his
# left arm (low, then high), lanes 3 and 4 his right (high, then low), so the
# body echoes where the note was on screen.

const DANCE_POSE: Dictionary = {
	"pelvis": Vector3(0, 0, 0),
	"spine_lower": Vector3(-2, 0, 0),
	"spine_upper": Vector3(-2, 0, 0),
	"neck": Vector3(0, 0, 0),
	"head": Vector3(-2, 0, 0),
	"upper_arm_r": Vector3(10, 0, 20),
	"forearm_r": Vector3(40, 0, 0),
	"hand_r": Vector3(0, 0, 0),
	"upper_arm_l": Vector3(10, 0, -20),
	"forearm_l": Vector3(40, 0, 0),
	"hand_l": Vector3(0, 0, 0),
	"thigh_l": Vector3(6, 0, -4),
	"shin_l": Vector3(-10, 0, 0),
	"foot_l": Vector3(4, 0, 0),
	"thigh_r": Vector3(6, 0, 4),
	"shin_r": Vector3(-10, 0, 0),
	"foot_r": Vector3(4, 0, 0),
}


func _build_darto_dance_clips() -> Array:
	var clips: Array = []

	# Two beats at 120 BPM per loop; the scene scales it to the song tempo.
	var idle := _clip(&"dance_idle_bounce", 1.0, true)
	for step: int in 5:
		var down := step % 2 == 1
		var lean := 6.0 * (1.0 if step == 1 else -1.0 if step == 3 else 0.0)
		_key(idle, DANCE_POSE, 0.25 * float(step), {
			"spine_upper": Vector3(-4 if down else -2, 0, lean), "pelvis": Vector3(0, 0, -lean * 0.5),
			"thigh_l": Vector3(14 if down else 6, 0, -4), "shin_l": Vector3(-22 if down else -10, 0, 0),
			"thigh_r": Vector3(14 if down else 6, 0, 4), "shin_r": Vector3(-22 if down else -10, 0, 0),
		}, Vector3(0, -0.01 if down else 0.0, 0))
	clips.append(idle)

	var lanes: Array = [
		{"upper_arm_l": Vector3(20, 0, -70), "forearm_l": Vector3(10, 0, 0), "spine_upper": Vector3(-2, 0, -8)},
		{"upper_arm_l": Vector3(20, 0, -160), "forearm_l": Vector3(20, 0, 0), "spine_upper": Vector3(-2, 0, -4)},
		{"upper_arm_r": Vector3(20, 0, 160), "forearm_r": Vector3(20, 0, 0), "spine_upper": Vector3(-2, 0, 4)},
		{"upper_arm_r": Vector3(20, 0, 70), "forearm_r": Vector3(10, 0, 0), "spine_upper": Vector3(-2, 0, 8)},
	]
	for lane: int in lanes.size():
		var clip := _clip(StringName("dance_hit_lane_%d" % (lane + 1)), 0.3)
		_key(clip, DANCE_POSE, 0.0)
		_key(clip, DANCE_POSE, 0.08, lanes[lane], Vector3(0, -0.006, 0))
		_key(clip, DANCE_POSE, 0.16, lanes[lane], Vector3(0, -0.006, 0))
		_key(clip, DANCE_POSE, 0.3)
		clips.append(clip)

	# High combo: both arms up, hips going.
	var combo := _clip(&"dance_combo_high", 1.0, true)
	for step: int in 5:
		var side := 1.0 if step % 2 == 1 else -1.0
		_key(combo, DANCE_POSE, 0.25 * float(step), {
			"upper_arm_l": Vector3(10, 0, -150 - 10 * side), "upper_arm_r": Vector3(10, 0, 150 - 10 * side),
			"forearm_l": Vector3(30, 0, 0), "forearm_r": Vector3(30, 0, 0),
			"pelvis": Vector3(0, 0, 8 * side), "spine_upper": Vector3(-2, 0, -10 * side),
		}, Vector3(0, -0.006 if step % 2 == 1 else 0.0, 0))
	clips.append(combo)

	var miss := _clip(&"dance_miss", 0.5)
	_key(miss, DANCE_POSE, 0.0)
	var stumble := {"spine_upper": Vector3(10, 0, 10), "head": Vector3(10, 0, 8), "thigh_r": Vector3(-14, 0, 10),
		"upper_arm_l": Vector3(30, 0, -44), "upper_arm_r": Vector3(30, 0, 44)}
	_key(miss, DANCE_POSE, 0.15, stumble, Vector3(0.02, -0.008, 0))
	_key(miss, DANCE_POSE, 0.5)
	clips.append(miss)

	var win := _clip(&"dance_win", 1.0, true)
	for step: int in 5:
		var up := step % 2 == 1
		_key(win, DANCE_POSE, 0.25 * float(step), {
			"upper_arm_r": Vector3(20, 0, 170 if up else 150), "forearm_r": Vector3(10, 0, 0),
			"upper_arm_l": Vector3(40, 0, -34), "forearm_l": Vector3(90, 0, 0),
		}, Vector3(0, 0.015 if up else 0.0, 0))
	clips.append(win)

	var lose := _clip(&"dance_lose", 1.0)
	_key(lose, DANCE_POSE, 0.0)
	var defeated := {"spine_upper": Vector3(16, 0, 0), "spine_lower": Vector3(8, 0, 0), "head": Vector3(18, 0, 0),
		"upper_arm_l": Vector3(4, 0, -10), "upper_arm_r": Vector3(4, 0, 10), "forearm_l": Vector3(6, 0, 0), "forearm_r": Vector3(6, 0, 0)}
	_key(lose, DANCE_POSE, 0.6, defeated, Vector3(0, -0.006, 0))
	_key(lose, DANCE_POSE, 1.0, defeated, Vector3(0, -0.006, 0))
	clips.append(lose)
	return clips


# --- Darto: Suwit (GDD 172.5) -------------------------------------------------
# At the table, right fist shaking on the count, then thrown forward. With no
# finger bones the three moves differ by wrist and arm; the UI names them.

func _build_darto_suwit_clips() -> Array:
	var clips: Array = []
	var ready_pose := {"upper_arm_r": Vector3(48, 0, 12), "forearm_r": Vector3(66, 0, 0), "spine_upper": Vector3(-6, 0, 0)}
	var ready := _clip(&"suwit_ready", 0.5, true)
	_key(ready, DANCE_POSE, 0.0, ready_pose)
	_key(ready, DANCE_POSE, 0.25, ready_pose.merged({"forearm_r": Vector3(92, 0, 0)}, true))
	_key(ready, DANCE_POSE, 0.5, ready_pose)
	clips.append(ready)

	var throws: Dictionary = {
		&"suwit_rock": {"upper_arm_r": Vector3(76, 0, 8), "forearm_r": Vector3(20, 0, 0), "hand_r": Vector3(0, 0, 0)},
		&"suwit_scissors": {"upper_arm_r": Vector3(76, 0, 8), "forearm_r": Vector3(20, 0, 0), "hand_r": Vector3(0, 70, 0)},
		&"suwit_paper": {"upper_arm_r": Vector3(76, 0, 8), "forearm_r": Vector3(20, 0, 0), "hand_r": Vector3(-60, 0, 0)},
	}
	for clip_name: StringName in throws:
		var clip := _clip(clip_name, 0.6)
		_key(clip, DANCE_POSE, 0.0, ready_pose)
		var thrown: Dictionary = (throws[clip_name] as Dictionary).merged({"spine_upper": Vector3(-10, 0, 0)}, true)
		_key(clip, DANCE_POSE, 0.12, thrown, Vector3(0, 0, -0.02))
		_key(clip, DANCE_POSE, 0.6, thrown, Vector3(0, 0, -0.02))
		clips.append(clip)

	var win := _clip(&"suwit_win", 0.9)
	_key(win, DANCE_POSE, 0.0, ready_pose)
	_key(win, DANCE_POSE, 0.4, {"upper_arm_r": Vector3(30, 0, 150), "forearm_r": Vector3(20, 0, 0), "head": Vector3(-6, 0, 0)}, Vector3(0, 0.008, 0))
	_key(win, DANCE_POSE, 0.9, {"upper_arm_r": Vector3(30, 0, 140), "forearm_r": Vector3(30, 0, 0)})
	clips.append(win)

	var lose := _clip(&"suwit_lose", 0.9)
	_key(lose, DANCE_POSE, 0.0, ready_pose)
	var defeated := {"spine_upper": Vector3(16, 0, 0), "head": Vector3(18, 0, 0), "upper_arm_r": Vector3(6, 0, 12), "forearm_r": Vector3(10, 0, 0)}
	_key(lose, DANCE_POSE, 0.5, defeated, Vector3(0, -0.004, 0))
	_key(lose, DANCE_POSE, 0.9, defeated, Vector3(0, -0.004, 0))
	clips.append(lose)

	var draw := _clip(&"suwit_draw", 0.7)
	_key(draw, DANCE_POSE, 0.0, ready_pose)
	_key(draw, DANCE_POSE, 0.3, {"upper_arm_r": Vector3(30, 0, 44), "upper_arm_l": Vector3(30, 0, -44), "forearm_r": Vector3(60, 0, 0), "forearm_l": Vector3(60, 0, 0), "head": Vector3(0, 0, 10)})
	_key(draw, DANCE_POSE, 0.7, ready_pose)
	clips.append(draw)
	return clips
