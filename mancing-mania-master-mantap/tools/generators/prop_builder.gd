@tool
extends RefCounted
## Generates every prop (GDD 174.5, 174.7, 174.8; VISUAL_STYLE_GUIDE 4, 8):
## fishing gear, trash catches, the warung furniture, the duel props and the
## story props.
##
## Sizes are tied to the 0.90 m chibi characters (guide 3): the warung counter
## top is 0.42 m, under the 0.44 m chest line, so Bu Yati stays visible behind
## it. Shapes are chunky and rounded (rounded slabs, capsules, lathes), each
## part has one warm colour, and each prop bakes into one mesh per material.
## Props that stand on the floor carry a soft fake shadow (guide 6.2).

const SoftMesh := preload("res://tools/generators/soft_mesh.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")
const Kit := preload("res://tools/generators/diorama_kit.gd")
const Style := preload("res://scripts/visual/diorama_style.gd")

const GENERATOR_ID := "prop_builder"
const GENERATOR_VERSION := 2
const SCENE_PATH := "res://generated/scenes/props/%s.tscn"

const ROD := "prop_fishing_rod_basic"
const FLOAT := "prop_float_basic"
const BUCKET := "prop_bucket_blue"
const TRASH_SANDAL := "prop_trash_lost_sandal"
const TRASH_CAN := "prop_trash_rusty_can"
const TRASH_TYRE := "prop_trash_ancient_tyre"

## The rod is modelled along -Z from the grip at the origin. Long and chunky
## on purpose: it is Darto's strongest secondary silhouette.
const ROD_LENGTH := 1.15

const WOOD := Style.PINE
const WOOD_DARK := Color("a8784a")
const CREAM := Color("f6e7c8")
const FADED_RED := Color("cf6a58")
const OLIVE := Color("9aa874")
const STEEL := Color("c9c6bd")
const DARK := Color("4a3c33")
const PASTEL_BLUE := Color("8fb3d9")


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var props: Dictionary[String, Callable] = {
		ROD: _build_rod,
		FLOAT: _build_float,
		BUCKET: _build_bucket,
		TRASH_SANDAL: _build_sandal,
		TRASH_CAN: _build_can,
		TRASH_TYRE: _build_tyre,
		MARKET_TABLE: _build_table,
		MARKET_SCALE: _build_scale,
		MARKET_FREEZER: _build_freezer,
		MARKET_THERMOS: _build_thermos,
		MARKET_JAR_SET: _build_jar_set,
		PLASTIC_CHAIR: _build_chair,
		HANGING_LAMP: _build_lamp,
		MARKET_PRICE_BOARD: _build_price_board,
		MARKET_FAN: _build_fan,
		BOXING_STOOL: _build_stool,
		BOXING_ROPES: _build_ropes,
		BOXING_MAT: _build_mat,
		ARM_TABLE: _build_arm_table,
		ARM_ELBOW_PAD: _build_elbow_pad,
		DANCE_PLATFORM: _build_dance_platform,
		DANCE_STRING_LIGHT: _build_string_light,
		SUWIT_TABLE: _build_suwit_table,
		MOTORCYCLE: _build_motorcycle,
		PHONE: _build_phone,
		HELMET: _build_helmet,
		DRINK_GLASS: _build_drink_glass,
		PICNIC_MAT: _build_picnic_mat,
		RICE_COOKER: _build_rice_cooker,
	}
	for prop_id: String in props:
		var root: Node3D = props[prop_id].call()
		root.name = prop_id.to_pascal_case()
		var path := SCENE_PATH % prop_id
		var save_error := GeneratorIo.save_scene(root, path)
		root.free()
		if save_error != OK:
			errors.append("%s: could not save (%s)" % [prop_id, error_string(save_error)])
		else:
			manifest.register(prop_id, GENERATOR_ID, GENERATOR_VERSION, 0, path)
	return errors


## One prop node: the baked mesh, plus a floor shadow when `footprint` is set.
func _wrap(builder: RefCounted, footprint: Vector2 = Vector2.ZERO, centre: Vector2 = Vector2.ZERO) -> Node3D:
	var root := Node3D.new()
	root.add_child(Kit.bake("Mesh", builder))
	if footprint != Vector2.ZERO:
		root.add_child(Kit.furniture_shadow(footprint, centre))
	return root


func _builder() -> RefCounted:
	return SoftMesh.new()


# --- Fishing gear and trash ---------------------------------------------------

## An old two-piece rod: cork grip, a round reel, a dark tapered blank with a
## faded band at the joint, and chunky guides.
func _build_rod() -> Node3D:
	var builder := _builder()
	builder.color = DARK
	builder.capsule(Vector3(0, 0, 0.09), Vector3(0, 0, 0.07), 0.016)
	builder.color = Color("d5a970")
	builder.capsule(Vector3(0, 0, 0.07), Vector3(0, 0, -0.10), 0.017, 0.015)
	builder.color = DARK
	builder.capsule(Vector3(0, 0, -0.10), Vector3(0, 0, -0.14), 0.014, 0.012)

	# Reel under the grip.
	builder.color = STEEL.darkened(0.15)
	builder.capsule(Vector3(0, -0.012, -0.05), Vector3(0, -0.035, -0.05), 0.008, -1.0, 6, 2)
	builder.color = STEEL
	builder.cylinder(Vector3(-0.022, -0.052, -0.05), Vector3(0.022, -0.052, -0.05), 0.026, -1.0, 12)
	builder.color = FADED_RED
	builder.sphere(Vector3(0.034, -0.062, -0.05), Vector3.ONE * 0.01, 8, 4)

	# Blank in tapering pieces.
	builder.color = Color("596150")
	builder.capsule(Vector3(0, 0, -0.14), Vector3(0, 0, -0.62), 0.011, 0.009, 8, 2)
	builder.color = FADED_RED
	builder.capsule(Vector3(0, 0, -0.62), Vector3(0, 0, -0.66), 0.0105, 0.0105, 8, 2)
	builder.color = Color("596150")
	builder.capsule(Vector3(0, 0, -0.66), Vector3(0, 0, -ROD_LENGTH), 0.0088, 0.0055, 8, 2)
	builder.color = STEEL
	for guide: float in [-0.34, -0.58, -0.82, -1.02]:
		builder.torus(Vector3(0, -0.018, guide), Vector3(0, 0, 1), 0.009, 0.0035, 8, 4)
	var root := _wrap(builder)
	var tip := Marker3D.new()
	tip.name = "RodTip"
	tip.position = Vector3(0, 0, -ROD_LENGTH)
	root.add_child(tip)
	return root


## A toy-sized bobber: red top, white belly, a short antenna. The origin sits
## on the waterline, so placing it at water height floats it correctly.
func _build_float() -> Node3D:
	var builder := _builder()
	var white := Style.FLOUR
	var red := FADED_RED
	builder.color_rule = func(point: Vector3, _base: Color) -> Color:
		return red if point.y > 0.002 else white
	builder.lathe(PackedVector2Array([
		Vector2(0.0, -0.05), Vector2(0.02, -0.046), Vector2(0.038, -0.024), Vector2(0.044, 0.0),
		Vector2(0.044, 0.004), Vector2(0.036, 0.026), Vector2(0.018, 0.042), Vector2(0.0, 0.046)]), 14)
	builder.color_rule = Callable()
	builder.color = DARK
	builder.capsule(Vector3(0, 0.04, 0), Vector3(0, 0.1, 0), 0.006, 0.005, 6, 2)
	builder.color = red
	builder.sphere(Vector3(0, 0.104, 0), Vector3.ONE * 0.012, 8, 4)
	return _wrap(builder)


## A pastel blue plastic bucket with a rolled rim and a wire handle.
func _build_bucket() -> Node3D:
	var builder := _builder()
	var height := 0.2
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		# The inside, seen over the rim, is a shade darker.
		return base.darkened(0.28) if point.y > 0.02 and Vector2(point.x, point.z).length() < 0.098 else base
	builder.color = PASTEL_BLUE
	builder.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.085, 0.0), Vector2(0.09, 0.01), Vector2(0.11, height),
		Vector2(0.098, height - 0.004), Vector2(0.084, 0.03), Vector2(0.0, 0.03)]), 16)
	builder.color_rule = Callable()
	builder.color = PASTEL_BLUE.lightened(0.12)
	builder.torus(Vector3(0, height, 0), Vector3.UP, 0.108, 0.011, 16, 6)
	builder.color = STEEL
	builder.torus(Vector3(0, height - 0.01, 0), Vector3(0.0, 0.3, 1.0), 0.106, 0.004, 12, 4, PI * 0.05, PI * 0.95)
	return _wrap(builder, Vector2(0.22, 0.22))


## A single rubber sandal that has clearly seen things.
func _build_sandal() -> Node3D:
	var builder := _builder()
	builder.color = Color("7fa7c9")
	builder.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0, 0.012, 0))
	builder.puffy_outline(PackedVector2Array([
		Vector2(-0.04, -0.085), Vector2(0.035, -0.09), Vector2(0.048, -0.02), Vector2(0.045, 0.055),
		Vector2(0.018, 0.092), Vector2(-0.025, 0.088), Vector2(-0.048, 0.035), Vector2(-0.045, -0.035)]), 0.024)
	builder.transform = Transform3D.IDENTITY
	builder.color = CREAM
	builder.torus(Vector3(0, 0.024, 0.0), Vector3(0.0, 0.2, 1.0), 0.04, 0.008, 10, 4, PI * 0.05, PI * 0.95)
	return _wrap(builder)


## A dented tin can, mostly rust.
func _build_can() -> Node3D:
	var builder := _builder()
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		return base.lerp(Color("b06a42"), 0.6 if sin(point.y * 90.0 + point.x * 50.0) > 0.1 else 0.0)
	builder.color = Color("cdc4b4")
	builder.transform = Transform3D(Basis(Vector3.BACK, deg_to_rad(8.0)), Vector3.ZERO)
	builder.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.03, 0.0), Vector2(0.034, 0.006), Vector2(0.032, 0.05),
		Vector2(0.035, 0.09), Vector2(0.033, 0.096), Vector2(0.024, 0.098), Vector2(0.0, 0.094)]), 12)
	builder.transform = Transform3D.IDENTITY
	builder.color_rule = Callable()
	return _wrap(builder)


## An old motorcycle tyre, lying flat.
func _build_tyre() -> Node3D:
	var builder := _builder()
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		var angle := atan2(point.z, point.x)
		return base.lightened(0.1) if sin(angle * 18.0) > 0.3 and point.y > 0.06 else base
	builder.color = Color("4f4843")
	builder.torus(Vector3(0, 0.05, 0), Vector3.UP, 0.14, 0.05, 16, 8)
	builder.color_rule = Callable()
	return _wrap(builder, Vector2(0.38, 0.38))


# --- Market props (GDD 72, 185.15) --------------------------------------------

const MARKET_TABLE := "prop_market_table"
const MARKET_SCALE := "prop_market_scale"
const MARKET_FREEZER := "prop_market_freezer"
const MARKET_THERMOS := "prop_market_thermos"
const MARKET_JAR_SET := "prop_market_jar_set"
const PLASTIC_CHAIR := "prop_plastic_chair"
const HANGING_LAMP := "prop_hanging_lamp"
const MARKET_PRICE_BOARD := "prop_market_price_board"
const MARKET_FAN := "prop_market_fan"

## The serving counter: under the 0.44 m chest line (guide 3).
const TABLE_HEIGHT := Style.COUNTER_TOP


## The warung counter: a rough plank top, a skirt of vertical boards toward
## the customer (+Z) and chunky legs. Two tiles wide (1.0 m), one deep.
func _build_table() -> Node3D:
	var builder := _builder()
	var width := 1.2
	var depth := 0.46
	var planks := 4
	for plank: int in planks:
		var offset := (float(plank) + 0.5) / float(planks) - 0.5
		builder.color = WOOD.lightened(0.06 if plank % 2 == 0 else -0.03)
		builder.rounded_slab(Vector3(width, 0.04, depth / float(planks) - 0.006), Vector3(0, TABLE_HEIGHT - 0.02 - 0.003 * float(plank % 2), offset * depth), 0.01)
	builder.color = WOOD_DARK
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		builder.rounded_slab(Vector3(0.06, TABLE_HEIGHT - 0.04, 0.06), Vector3(corner.x * (width * 0.5 - 0.06), (TABLE_HEIGHT - 0.04) * 0.5, corner.y * (depth * 0.5 - 0.06)), 0.012)
	# The front skirt hides Bu Yati's knees.
	var boards := 8
	for board: int in boards:
		var x := -width * 0.5 + 0.06 + (float(board) + 0.5) * (width - 0.12) / float(boards)
		builder.color = WOOD.darkened(0.04 if board % 2 == 0 else 0.1)
		builder.rounded_slab(Vector3((width - 0.12) / float(boards) - 0.008, TABLE_HEIGHT - 0.1, 0.02), Vector3(x, (TABLE_HEIGHT - 0.1) * 0.5 + 0.04, depth * 0.5 - 0.04), 0.006)
	return _wrap(builder, Vector2(width, depth))


## An old dial scale with a round pan, the dial facing the customer (+Z).
func _build_scale() -> Node3D:
	var builder := _builder()
	builder.color = Color("a9c2b8")
	builder.rounded_slab(Vector3(0.14, 0.03, 0.12), Vector3(0, 0.015, 0), 0.01)
	builder.rounded_slab(Vector3(0.11, 0.1, 0.075), Vector3(0, 0.08, 0.004), 0.02)
	builder.color = CREAM
	builder.cylinder(Vector3(0, 0.082, 0.04), Vector3(0, 0.082, 0.046), 0.038, -1.0, 14)
	builder.color = FADED_RED
	builder.capsule(Vector3(0, 0.082, 0.048), Vector3(0.018, 0.106, 0.048), 0.003, -1.0, 6, 2)
	builder.color = STEEL.darkened(0.1)
	builder.cylinder(Vector3(0, 0.13, 0), Vector3(0, 0.15, 0), 0.01)
	builder.color = STEEL
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.145), Vector2(0.04, 0.148), Vector2(0.085, 0.165), Vector2(0.08, 0.168), Vector2(0.0, 0.155)]), 16)
	return _wrap(builder)


## A yellowed chest freezer with a soft lid and a little rust at the bottom.
func _build_freezer() -> Node3D:
	var builder := _builder()
	var body := Color("f1ead8")
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		return base.lerp(Color("c98a5c"), clampf(0.45 - point.y * 9.0, 0.0, 0.4))
	builder.color = body
	builder.rounded_slab(Vector3(0.6, 0.34, 0.34), Vector3(0, 0.17, 0), 0.04)
	builder.color_rule = Callable()
	builder.color = body.lightened(0.05)
	builder.rounded_slab(Vector3(0.62, 0.05, 0.36), Vector3(0, 0.36, 0), 0.02)
	builder.color = STEEL.darkened(0.2)
	builder.capsule(Vector3(-0.06, 0.35, 0.185), Vector3(0.06, 0.35, 0.185), 0.012, -1.0, 8, 2)
	builder.color = PASTEL_BLUE
	builder.rounded_slab(Vector3(0.16, 0.06, 0.01), Vector3(-0.17, 0.09, 0.172), 0.004)
	return _wrap(builder, Vector2(0.62, 0.36))


## A thermos flask with a cup lid and a side handle.
func _build_thermos() -> Node3D:
	var builder := _builder()
	builder.color_rule = func(point: Vector3, _base: Color) -> Color:
		if point.y > 0.118:
			return STEEL
		return CREAM if point.y > 0.035 and point.y < 0.055 else FADED_RED
	builder.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.032, 0.0), Vector2(0.036, 0.008), Vector2(0.036, 0.034), Vector2(0.0365, 0.036),
		Vector2(0.0365, 0.054), Vector2(0.036, 0.056), Vector2(0.036, 0.112), Vector2(0.033, 0.119), Vector2(0.03, 0.122),
		Vector2(0.028, 0.15), Vector2(0.02, 0.158), Vector2(0.0, 0.16)]), 14)
	builder.color_rule = Callable()
	builder.color = DARK
	builder.torus(Vector3(0.04, 0.075, 0), Vector3(0, 0, 1), 0.026, 0.006, 10, 4, -PI * 0.5, PI * 0.5)
	return _wrap(builder)


## Three snack jars with red lids: glass shoulders over coloured snacks.
func _build_jar_set() -> Node3D:
	var builder := _builder()
	var contents: Array[Color] = [Color("e8c06e"), Color("d99a64"), Color("efd9a8")]
	for index: int in 3:
		var x := (float(index) - 1.0) * 0.085
		var height := 0.1 + 0.02 * float((index + 1) % 3)
		builder.select_surface(MaterialBuilder.SURFACE_SOLID)
		builder.color = contents[index]
		builder.cylinder(Vector3(x, 0.004, 0), Vector3(x, height * 0.72, 0), 0.034, 0.036, 12)
		builder.color = FADED_RED
		builder.cylinder(Vector3(x, height, 0), Vector3(x, height + 0.018, 0), 0.035, 0.033, 12)
		builder.select_surface(MaterialBuilder.SURFACE_GLASS)
		builder.color = Color("eaf4f0")
		builder.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.038, 0.0), Vector2(0.04, height * 0.8), Vector2(0.035, height), Vector2(0.0, height)]), 12, Transform3D(Basis.IDENTITY, Vector3(x, 0, 0)))
	return _wrap(builder)


## A stackable plastic chair in faded red: low seat for chibi legs, a round
## back up to the shoulders. The seat front faces -Z, like a person.
func _build_chair() -> Node3D:
	var builder := _builder()
	var seat := 0.13
	builder.color = FADED_RED.lightened(0.06)
	builder.rounded_slab(Vector3(0.26, 0.03, 0.24), Vector3(0, seat, 0), 0.012)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		# Legs splay outward slightly, like the real thing.
		builder.capsule(Vector3(corner.x * 0.1, seat - 0.01, corner.y * 0.09), Vector3(corner.x * 0.12, 0.012, corner.y * 0.11), 0.014, 0.011, 8, 2)
	builder.color = FADED_RED
	builder.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-8.0)), Vector3(0, seat, 0.11))
	builder.rounded_slab(Vector3(0.25, 0.2, 0.025), Vector3(0, 0.2, 0), 0.012)
	for side: float in [-1.0, 1.0]:
		builder.capsule(Vector3(0.1 * side, 0.0, 0), Vector3(0.1 * side, 0.1, 0), 0.012, -1.0, 6, 2)
	builder.transform = Transform3D.IDENTITY
	return _wrap(builder, Vector2(0.26, 0.24))


## A bulb under a tin shade on a cord. The origin is where it hangs from; the
## bulb really glows (guide 5.1: emission only for things that light up).
func _build_lamp() -> Node3D:
	var builder := _builder()
	builder.color = DARK
	builder.cylinder(Vector3(0, 0, 0), Vector3(0, -0.28, 0), 0.004, -1.0, 6)
	builder.color = OLIVE
	builder.lathe(PackedVector2Array([Vector2(0.0, -0.27), Vector2(0.016, -0.27), Vector2(0.03, -0.29), Vector2(0.09, -0.34), Vector2(0.085, -0.345), Vector2(0.0, -0.3)]), 14)
	builder.select_surface(MaterialBuilder.SURFACE_GLOW)
	builder.color = Style.BUTTER
	builder.sphere(Vector3(0, -0.345, 0), Vector3(0.026, 0.032, 0.026), 10, 5)
	var root := _wrap(builder)
	var bulb := Marker3D.new()
	bulb.name = "BulbSpot"
	bulb.position = Vector3(0, -0.36, 0)
	root.add_child(bulb)
	return root


## A hand-painted price board: faded red header and rows of chalk marks.
func _build_price_board() -> Node3D:
	var builder := _builder()
	builder.color = WOOD_DARK
	builder.rounded_slab(Vector3(0.46, 0.34, 0.025), Vector3.ZERO, 0.01)
	builder.color = CREAM
	builder.rounded_slab(Vector3(0.41, 0.29, 0.012), Vector3(0, 0, 0.012), 0.005)
	builder.color = FADED_RED
	builder.rounded_slab(Vector3(0.41, 0.06, 0.014), Vector3(0, 0.115, 0.014), 0.005)
	builder.color = DARK.lightened(0.15)
	for row: int in 4:
		var y := 0.055 - 0.05 * float(row)
		builder.capsule(Vector3(-0.17, y, 0.02), Vector3(-0.17 + 0.16 - 0.02 * float(row % 3), y, 0.02), 0.006, -1.0, 6, 2)
		builder.capsule(Vector3(0.1, y, 0.02), Vector3(0.17, y, 0.02), 0.006, -1.0, 6, 2)
	return _wrap(builder)


## A small desk fan with a round cage. The blades are a separate node, built
## around their own hub, so the scene can spin them (GDD 172.9).
func _build_fan() -> Node3D:
	var builder := _builder()
	builder.color = OLIVE.darkened(0.08)
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.055, 0.008), Vector2(0.045, 0.02), Vector2(0.0, 0.022)]), 14)
	builder.capsule(Vector3(0, 0.02, 0), Vector3(0, 0.1, 0), 0.008)
	builder.sphere(Vector3(0, 0.11, -0.022), Vector3(0.025, 0.025, 0.03), 10, 5)
	builder.color = STEEL
	for ring_z: float in [0.0, 0.02]:
		builder.torus(Vector3(0, 0.11, ring_z), Vector3(0, 0, 1), 0.06, 0.0035, 16, 4)
	builder.capsule(Vector3(0, 0.05, 0.01), Vector3(0, 0.17, 0.01), 0.003, -1.0, 4, 1)
	builder.capsule(Vector3(-0.06, 0.11, 0.01), Vector3(0.06, 0.11, 0.01), 0.003, -1.0, 4, 1)
	var root := _wrap(builder)

	var blades := _builder()
	blades.color = OLIVE.lightened(0.2)
	for blade: int in 3:
		blades.transform = Transform3D(Basis(Vector3(0, 0, 1), TAU * float(blade) / 3.0 + 0.3), Vector3.ZERO)
		blades.puffy_outline(PackedVector2Array([Vector2(0.008, -0.008), Vector2(0.05, -0.018), Vector2(0.056, 0.0), Vector2(0.05, 0.016), Vector2(0.008, 0.008)]), 0.006)
	blades.transform = Transform3D.IDENTITY
	blades.color = OLIVE.darkened(0.1)
	blades.sphere(Vector3.ZERO, Vector3(0.012, 0.012, 0.01), 8, 4)
	var blades_node := Kit.bake("Blades", blades)
	blades_node.position = Vector3(0, 0.11, 0.012)
	root.add_child(blades_node)
	return root


# --- Boxing props (GDD 174.7, 185.16) -----------------------------------------

const BOXING_STOOL := "prop_boxing_corner_stool"
const BOXING_ROPES := "prop_boxing_ropes"
const BOXING_MAT := "prop_boxing_mat"
## Height of the stool seat. The fish stands on it, so it looks Darto in the eye.
const STOOL_HEIGHT := 0.12
## Half the side of the roped square.
const RING_HALF := 1.2
const ROPE := Color("e8d3a6")
const BAMBOO := Color("d4b46a")


## A low wooden stool with a towel over one edge.
func _build_stool() -> Node3D:
	var builder := _builder()
	var seat := 0.3
	builder.color = WOOD
	builder.rounded_slab(Vector3(seat, 0.04, seat), Vector3(0, STOOL_HEIGHT - 0.02, 0), 0.014)
	builder.color = WOOD_DARK
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		builder.capsule(Vector3(corner.x * 0.11, STOOL_HEIGHT - 0.04, corner.y * 0.11), Vector3(corner.x * 0.13, 0.012, corner.y * 0.13), 0.016, 0.013, 8, 2)
	builder.color = CREAM
	builder.rounded_slab(Vector3(0.1, 0.012, 0.13), Vector3(0.07, STOOL_HEIGHT + 0.006, -0.08), 0.005)
	builder.rounded_slab(Vector3(0.1, 0.07, 0.012), Vector3(0.07, STOOL_HEIGHT - 0.03, -0.146), 0.005)
	return _wrap(builder, Vector2(0.32, 0.32))


## Bamboo posts and sagging ropes: a ring somebody put up in an afternoon.
## Like the near walls of a dollhouse, the two sides toward the camera (-X and
## -Z) have only stubby posts and no ropes, so nothing ever crosses the fight.
func _build_ropes() -> Node3D:
	var builder := _builder()
	var corners: Array[Vector3] = [
		Vector3(-RING_HALF, 0, -RING_HALF), Vector3(RING_HALF, 0, -RING_HALF),
		Vector3(RING_HALF, 0, RING_HALF), Vector3(-RING_HALF, 0, RING_HALF)]
	var tall := [false, true, true, true]
	for index: int in corners.size():
		var base := corners[index]
		var height := 0.72 + 0.03 * float(index % 2) if tall[index] else Style.LOW_WALL
		builder.color = BAMBOO.darkened(0.05 * float(index % 2))
		builder.capsule(base, base + Vector3(0, height, 0), 0.03, 0.026, 10, 3)
		builder.color = BAMBOO.darkened(0.22)
		if tall[index]:
			for knot: float in [0.28, 0.52]:
				builder.torus(base + Vector3(0, knot, 0), Vector3.UP, 0.03, 0.006, 10, 4)
	# Ropes on the far sides only: from corner 1 to 2 (+X side) and 2 to 3 (+Z).
	for height: float in [0.34, 0.58]:
		builder.color = ROPE if height > 0.5 else ROPE.darkened(0.1)
		for pair: Vector2i in [Vector2i(1, 2), Vector2i(2, 3)]:
			var from := corners[pair.x] + Vector3(0, height, 0)
			var to := corners[pair.y] + Vector3(0, height, 0)
			var previous := from
			for step: int in range(1, 7):
				var along := float(step) / 6.0
				var point := from.lerp(to, along) - Vector3(0, sin(along * PI) * 0.05, 0)
				builder.capsule(previous, point, 0.011, -1.0, 6, 1)
				previous = point
	return _wrap(builder)


## A patched woven mat with a soft border: the ring floor. The weave is a
## checker of two tones made from geometry, not a texture.
func _build_mat() -> Node3D:
	var builder := _builder()
	var half := RING_HALF - 0.06
	builder.color = FADED_RED.lerp(CREAM, 0.3)
	builder.rounded_slab(Vector3(half * 2.0, 0.03, half * 2.0), Vector3(0, 0.015, 0), 0.012)
	Kit.checker(builder, Vector3(-half + 0.08, 0.031, -half + 0.08), Vector3((half - 0.08) * 2.0, 0, 0), Vector3(0, 0, (half - 0.08) * 2.0), 8, 8,
		CREAM.darkened(0.04), CREAM.darkened(0.12))
	builder.color = OLIVE
	builder.rounded_slab(Vector3(0.36, 0.008, 0.26), Vector3(-0.5, 0.034, 0.4), 0.003)
	builder.color = FADED_RED
	builder.rounded_slab(Vector3(0.22, 0.008, 0.22), Vector3(0.6, 0.034, -0.5), 0.003)
	return _wrap(builder)


# --- Arm wrestling props (GDD 174.7, 185.17) ----------------------------------

const ARM_TABLE := "prop_arm_table"
const ARM_ELBOW_PAD := "prop_arm_elbow_pad"
## Just under a chibi elbow, so both can lean their forearms on it.
const ARM_TABLE_HEIGHT := 0.28


## A single sturdy table: thick top, four heavy legs and cross braces.
func _build_arm_table() -> Node3D:
	var builder := _builder()
	var top := Vector3(0.42, 0.05, 0.42)
	builder.color = WOOD.darkened(0.04)
	builder.rounded_slab(top, Vector3(0, ARM_TABLE_HEIGHT - top.y * 0.5, 0), 0.016)
	builder.color = WOOD.lightened(0.06)
	builder.rounded_slab(Vector3(top.x - 0.05, 0.008, top.z - 0.05), Vector3(0, ARM_TABLE_HEIGHT + 0.002, 0), 0.003)
	builder.color = WOOD_DARK
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		builder.rounded_slab(Vector3(0.055, ARM_TABLE_HEIGHT - top.y, 0.055), Vector3(corner.x * 0.16, (ARM_TABLE_HEIGHT - top.y) * 0.5, corner.y * 0.16), 0.014)
	builder.rounded_slab(Vector3(0.27, 0.035, 0.03), Vector3(0, 0.07, 0.16), 0.01)
	builder.rounded_slab(Vector3(0.27, 0.035, 0.03), Vector3(0, 0.07, -0.16), 0.01)
	return _wrap(builder, Vector2(0.42, 0.42))


## An exaggerated elbow pad: a fat cushion with a cream rim.
func _build_elbow_pad() -> Node3D:
	var builder := _builder()
	builder.color = FADED_RED.lightened(0.05)
	builder.sphere(Vector3(0, 0.022, 0), Vector3(0.07, 0.024, 0.062), 12, 5)
	builder.color = CREAM
	builder.torus(Vector3(0, 0.008, 0), Vector3.UP, 0.066, 0.009, 16, 5)
	return _wrap(builder)


# --- Dance props (GDD 174.7, 185.18) ------------------------------------------

const DANCE_PLATFORM := "prop_dance_platform"
const DANCE_STRING_LIGHT := "prop_dance_string_light"
const DANCE_PLATFORM_HEIGHT := 0.12


## A low wooden stage with painted bunting trim and one step at the front.
func _build_dance_platform() -> Node3D:
	var builder := _builder()
	var size := Vector3(2.0, DANCE_PLATFORM_HEIGHT, 2.0)
	builder.color = WOOD_DARK
	builder.rounded_slab(Vector3(size.x, size.y - 0.02, size.z), Vector3(0, (size.y - 0.02) * 0.5, 0), 0.02)
	var planks := 8
	for plank: int in planks:
		var x := -size.x * 0.5 + (float(plank) + 0.5) * size.x / float(planks)
		builder.color = WOOD.lightened(0.07 if plank % 2 == 0 else -0.02)
		builder.rounded_slab(Vector3(size.x / float(planks) - 0.008, 0.024, size.z - 0.02), Vector3(x, size.y - 0.012, 0), 0.006)
	# Bunting triangles along the two edges facing the camera (-Z and -X).
	for edge: int in 2:
		for index: int in 8:
			var along := -size.x * 0.5 + 0.14 + float(index) * (size.x - 0.28) / 7.0
			builder.color = [FADED_RED, Style.CUSTARD, Style.MINT][(index + edge) % 3]
			if edge == 0:
				builder.transform = Transform3D(Basis.IDENTITY, Vector3(along, size.y - 0.035, -size.z * 0.5 - 0.012))
			else:
				builder.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(-size.x * 0.5 - 0.012, size.y - 0.035, along))
			builder.puffy_outline(PackedVector2Array([Vector2(-0.07, 0.02), Vector2(0.07, 0.02), Vector2(0.0, -0.05)]), 0.012)
	builder.transform = Transform3D.IDENTITY
	builder.color = WOOD_DARK.lightened(0.05)
	builder.rounded_slab(Vector3(0.5, 0.06, 0.16), Vector3(0, 0.03, -size.z * 0.5 - 0.09), 0.014)
	return _wrap(builder, Vector2(size.x, size.z))


## Bamboo poles with a sagging wire of warm bulbs that really glow.
func _build_string_light() -> Node3D:
	var builder := _builder()
	var left := Vector3(-1.3, 0, 0)
	var right := Vector3(1.3, 0, 0)
	builder.color = BAMBOO
	for base: Vector3 in [left, right]:
		builder.capsule(base, base + Vector3(0, 1.45, 0), 0.026, 0.022, 10, 3)
	var top := 1.42
	var previous := left + Vector3(0, top, 0)
	for step: int in range(1, 11):
		var along := float(step) / 10.0
		var point := (left + Vector3(0, top, 0)).lerp(right + Vector3(0, top, 0), along) - Vector3(0, sin(along * PI) * 0.2, 0)
		builder.select_surface(MaterialBuilder.SURFACE_SOLID)
		builder.color = DARK
		builder.capsule(previous, point, 0.004, -1.0, 4, 1)
		if step < 10:
			builder.select_surface(MaterialBuilder.SURFACE_GLOW)
			builder.color = [Style.BUTTER, Style.CUSTARD, Style.STRAWBERRY][step % 3]
			builder.sphere(point - Vector3(0, 0.035, 0), Vector3(0.024, 0.03, 0.024), 8, 4)
		previous = point
	return _wrap(builder)


# --- Suwit props (GDD 174.7, 185.19) ------------------------------------------

const SUWIT_TABLE := "prop_suwit_table"
const SUWIT_TABLE_HEIGHT := 0.3


## A small round table with a woven cloth: calm, not a gambling table.
func _build_suwit_table() -> Node3D:
	var builder := _builder()
	builder.color = WOOD.darkened(0.06)
	builder.lathe(PackedVector2Array([Vector2(0.0, SUWIT_TABLE_HEIGHT - 0.035), Vector2(0.3, SUWIT_TABLE_HEIGHT - 0.035), Vector2(0.31, SUWIT_TABLE_HEIGHT - 0.02), Vector2(0.3, SUWIT_TABLE_HEIGHT), Vector2(0.0, SUWIT_TABLE_HEIGHT)]), 24)
	builder.color = WOOD_DARK
	builder.cylinder(Vector3(0, 0.02, 0), Vector3(0, SUWIT_TABLE_HEIGHT - 0.03, 0), 0.03, 0.026, 10)
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.15, 0.0), Vector2(0.14, 0.025), Vector2(0.0, 0.03)]), 16)
	builder.color = OLIVE.lerp(CREAM, 0.4)
	builder.cylinder(Vector3(0, SUWIT_TABLE_HEIGHT, 0), Vector3(0, SUWIT_TABLE_HEIGHT + 0.004, 0), 0.22, -1.0, 24)
	builder.color = FADED_RED.lerp(CREAM, 0.25)
	builder.cylinder(Vector3(0, SUWIT_TABLE_HEIGHT + 0.004, 0), Vector3(0, SUWIT_TABLE_HEIGHT + 0.007, 0), 0.12, -1.0, 24)
	return _wrap(builder, Vector2(0.62, 0.62))


# --- Story props (GDD 72, 156, 157, 174.5) ------------------------------------

const MOTORCYCLE := "prop_motorcycle_darto"
const PHONE := "prop_phone"
const HELMET := "prop_helmet"
const DRINK_GLASS := "prop_drink_glass"
const PICNIC_MAT := "prop_picnic_mat"
const RICE_COOKER := "prop_rice_cooker"


## Darto's old underbone motorcycle (motor bebek) as a chunky toy: round
## tyres, a front fork, the leg shield, a long seat, a round headlamp and a
## long exhaust, so it reads as a motorcycle from the diorama camera (GDD 185.12).
func _build_motorcycle() -> Node3D:
	var builder := _builder()
	var body := Color("7f8f6c")
	var dark := Color("4a433d")
	for x: float in [-0.3, 0.3]:
		builder.color = dark
		builder.torus(Vector3(x, 0.13, 0), Vector3(0, 0, 1), 0.1, 0.035, 16, 8)
		builder.select_surface(MaterialBuilder.SURFACE_METAL)
		builder.color = STEEL
		builder.cylinder(Vector3(x, 0.13, -0.025), Vector3(x, 0.13, 0.025), 0.065, -1.0, 12)
		builder.select_surface(MaterialBuilder.SURFACE_SOLID)
	builder.color = body
	# Mudguards, frame spine, engine cover, rear body and leg shield.
	builder.torus(Vector3(0.3, 0.13, 0), Vector3(0, 0, 1), 0.15, 0.022, 12, 6, -PI * 0.95, -PI * 0.15)
	builder.capsule(Vector3(0.2, 0.42, 0), Vector3(-0.02, 0.22, 0), 0.03)
	builder.rounded_slab(Vector3(0.24, 0.13, 0.12), Vector3(-0.09, 0.22, 0), 0.04)
	builder.rounded_slab(Vector3(0.34, 0.12, 0.13), Vector3(-0.2, 0.32, 0), 0.05)
	builder.rounded_slab(Vector3(0.05, 0.24, 0.18), Vector3(0.16, 0.32, 0), 0.02)
	builder.color = dark
	builder.rounded_slab(Vector3(0.32, 0.045, 0.13), Vector3(-0.18, 0.395, 0), 0.02)
	builder.select_surface(MaterialBuilder.SURFACE_METAL)
	builder.color = STEEL
	for z: float in [-0.04, 0.04]:
		builder.capsule(Vector3(0.3, 0.13, z), Vector3(0.23, 0.46, z), 0.012, -1.0, 6, 2)
	builder.capsule(Vector3(0.22, 0.49, -0.16), Vector3(0.22, 0.49, 0.16), 0.01, -1.0, 6, 2)
	builder.capsule(Vector3(-0.02, 0.13, 0.08), Vector3(-0.38, 0.17, 0.08), 0.02, 0.016, 8, 2)
	builder.select_surface(MaterialBuilder.SURFACE_SOLID)
	builder.color = dark
	for z: float in [-0.17, 0.17]:
		builder.capsule(Vector3(0.22, 0.49, z * 0.8), Vector3(0.22, 0.49, z), 0.014, -1.0, 6, 2)
	builder.color = CREAM
	builder.sphere(Vector3(0.27, 0.46, 0), Vector3(0.03, 0.035, 0.04), 10, 5)
	builder.color = FADED_RED
	builder.sphere(Vector3(-0.38, 0.33, 0), Vector3(0.012, 0.016, 0.03), 8, 4)
	return _wrap(builder, Vector2(0.78, 0.3))


## A chunky cheap smartphone: dark body, light screen on the -Z face. Held in
## the hand during story phone moments (GDD 173).
func _build_phone() -> Node3D:
	var builder := _builder()
	builder.color = Color("4b5a5a")
	builder.rounded_slab(Vector3(0.042, 0.075, 0.01), Vector3.ZERO, 0.005)
	builder.color = Color("dff0ea")
	builder.rounded_slab(Vector3(0.034, 0.062, 0.002), Vector3(0, 0.002, -0.005), 0.001)
	return _wrap(builder)


func _build_helmet() -> Node3D:
	var builder := _builder()
	builder.color = CREAM
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.1, 0.0), Vector2(0.105, 0.03), Vector2(0.09, 0.08), Vector2(0.05, 0.11), Vector2(0.0, 0.118)]), 16)
	builder.color = DARK
	builder.rounded_slab(Vector3(0.12, 0.03, 0.02), Vector3(0, 0.045, -0.1), 0.008)
	return _wrap(builder, Vector2(0.2, 0.2))


## A plain glass of sweet tea for the after-ending menu (GDD 157).
func _build_drink_glass() -> Node3D:
	var builder := _builder()
	builder.color = Color("d99a64")
	builder.cylinder(Vector3(0, 0.004, 0), Vector3(0, 0.05, 0), 0.02, 0.022, 12)
	builder.select_surface(MaterialBuilder.SURFACE_GLASS)
	builder.color = Color("f4faf6")
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.022, 0.0), Vector2(0.026, 0.065), Vector2(0.0, 0.065)]), 12)
	return _wrap(builder)


## A checkered picnic mat (the pattern is geometry, guide 4.2) with a pot of rice.
func _build_picnic_mat() -> Node3D:
	var builder := _builder()
	builder.color = CREAM
	builder.rounded_slab(Vector3(0.84, 0.012, 0.84), Vector3(0, 0.006, 0), 0.005)
	Kit.checker(builder, Vector3(-0.4, 0.0125, -0.4), Vector3(0.8, 0, 0), Vector3(0, 0, 0.8), 6, 6, FADED_RED.lightened(0.15), CREAM)
	builder.color = Color("eee3c9")
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.012), Vector2(0.06, 0.012), Vector2(0.075, 0.04), Vector2(0.07, 0.045), Vector2(0.0, 0.05)]), 14, Transform3D(Basis.IDENTITY, Vector3(0.18, 0, 0.12)))
	builder.color = Style.FLOUR
	builder.sphere(Vector3(0.18, 0.05, 0.12), Vector3(0.06, 0.022, 0.06), 10, 4)
	return _wrap(builder)


func _build_rice_cooker() -> Node3D:
	var builder := _builder()
	builder.color = Color("eef2ec")
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.065, 0.0), Vector2(0.075, 0.015), Vector2(0.075, 0.08), Vector2(0.07, 0.09), Vector2(0.0, 0.09)]), 16)
	builder.color = TERRACOTTA_SOFT
	builder.lathe(PackedVector2Array([Vector2(0.0, 0.088), Vector2(0.072, 0.088), Vector2(0.06, 0.115), Vector2(0.02, 0.125), Vector2(0.0, 0.125)]), 16)
	builder.color = DARK
	builder.capsule(Vector3(-0.015, 0.128, 0), Vector3(0.015, 0.128, 0), 0.008, -1.0, 6, 2)
	builder.rounded_slab(Vector3(0.03, 0.015, 0.012), Vector3(0, 0.04, 0.074), 0.004)
	return _wrap(builder)


const TERRACOTTA_SOFT := Color("d07a54")
