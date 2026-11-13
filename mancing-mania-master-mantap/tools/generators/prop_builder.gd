@tool
extends RefCounted
## Generates props (GDD 174.5, 174.8): the fishing gear, the three trash
## catches and the furniture of Bu Yati's warung. The home and duel props are
## added by the milestones that build those sets.

const MeshBuilder := preload("res://tools/generators/mesh_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")

const GENERATOR_ID := "prop_builder"
const GENERATOR_VERSION := 1
const SCENE_PATH := "res://generated/scenes/props/%s.tscn"

const ROD := "prop_fishing_rod_basic"
const FLOAT := "prop_float_basic"
const BUCKET := "prop_bucket_blue"
const TRASH_SANDAL := "prop_trash_lost_sandal"
const TRASH_CAN := "prop_trash_rusty_can"
const TRASH_TYRE := "prop_trash_ancient_tyre"

## The rod is modelled along -Z from the grip at the origin.
const ROD_LENGTH := 2.5


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


func _wrap(builder: RefCounted) -> Node3D:
	var root := Node3D.new()
	var instance := MeshInstance3D.new()
	instance.name = "Mesh"
	instance.mesh = builder.commit()
	instance.material_override = load(MaterialBuilder.VERTEX_COLOR)
	root.add_child(instance)
	return root


## An old two-piece rod: cork grip, small reel, dark tapered blank, line guides.
func _build_rod() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = Color("3a2f27")
	builder.tube(Vector3(0, 0, 0.16), Vector3(0, 0, 0.12), 0.019, 0.021, 7)
	builder.color = Color("b08a5c")
	builder.tube(Vector3(0, 0, 0.12), Vector3(0, 0, -0.20), 0.021, 0.018, 7)
	builder.color = Color("3a2f27")
	builder.tube(Vector3(0, 0, -0.20), Vector3(0, 0, -0.26), 0.019, 0.013, 7)

	# Reel under the grip.
	builder.color = Color("59544c")
	builder.tube(Vector3(0, -0.02, -0.11), Vector3(0, -0.062, -0.11), 0.010, 0.010, 5)
	builder.tube(Vector3(-0.028, -0.085, -0.11), Vector3(0.028, -0.085, -0.11), 0.034, 0.034, 9)
	builder.color = Color("2a2622")
	builder.tube(Vector3(0.028, -0.085, -0.11), Vector3(0.062, -0.085, -0.11), 0.007, 0.007, 5)
	builder.tube(Vector3(0.062, -0.085, -0.11), Vector3(0.062, -0.125, -0.11), 0.009, 0.009, 5)

	# Blank in three tapering pieces, with a faded band at the joint.
	builder.color = Color("3d4038")
	builder.tube(Vector3(0, 0, -0.26), Vector3(0, 0, -1.15), 0.0125, 0.0085, 6)
	builder.color = Color("9b5a44")
	builder.tube(Vector3(0, 0, -1.15), Vector3(0, 0, -1.21), 0.0095, 0.0092, 6)
	builder.color = Color("3d4038")
	builder.tube(Vector3(0, 0, -1.21), Vector3(0, 0, -1.95), 0.0082, 0.0048, 6)
	builder.tube(Vector3(0, 0, -1.95), Vector3(0, 0, -ROD_LENGTH), 0.0048, 0.0022, 5)

	builder.color = Color("8d8a80")
	for guide: float in [-0.62, -1.05, -1.48, -1.86, -2.2]:
		builder.tube(Vector3(0, -0.006, guide), Vector3(0, -0.028, guide), 0.003, 0.003, 4)
		builder.tube(Vector3(0, -0.03, guide - 0.004), Vector3(0, -0.03, guide + 0.004), 0.011, 0.011, 6)

	var root := _wrap(builder)
	var tip := Marker3D.new()
	tip.name = "RodTip"
	tip.position = Vector3(0, 0, -ROD_LENGTH)
	root.add_child(tip)
	return root


## Classic bobber: red top, white belly, thin antenna. The origin sits on the
## waterline, so placing it at water height floats it correctly.
func _build_float() -> Node3D:
	var builder := MeshBuilder.new()
	var segments := 8
	var white := Color("f3ecd9")
	var red := Color("b9473c")
	var profile: Array = [
		[-0.085, 0.004, white], [-0.05, 0.022, white], [-0.012, 0.034, white],
		[0.0, 0.036, red], [0.03, 0.03, red], [0.058, 0.012, red], [0.07, 0.005, red],
	]
	for index: int in profile.size() - 1:
		var lower: Array = profile[index]
		var upper: Array = profile[index + 1]
		builder.color = upper[2]
		builder.tube(Vector3(0, lower[0], 0), Vector3(0, upper[0], 0), lower[1], upper[1], segments, index == 0)
	builder.color = Color("2a2622")
	builder.tube(Vector3(0, 0.07, 0), Vector3(0, 0.15, 0), 0.004, 0.003, 5)
	builder.color = red
	builder.blob(Vector3(0, 0.158, 0), Vector3.ONE * 0.011, 6, 3)
	return _wrap(builder)


## Faded blue plastic bucket with a wire handle resting to one side.
func _build_bucket() -> Node3D:
	var builder := MeshBuilder.new()
	var blue := Color("4f7fa3")
	var segments := 12
	var bottom := 0.115
	var top := 0.155
	var height := 0.27
	var wall := 0.012

	builder.color = blue
	builder.tube(Vector3(0, 0, 0), Vector3(0, height, 0), bottom, top, segments, true)
	# Dark interior disc slightly below the rim reads as an open bucket.
	builder.color = blue.darkened(0.45)
	builder.tube(Vector3(0, height - 0.035, 0), Vector3(0, height + 0.002, 0), top - wall * 2.2, top - wall, segments, true)
	builder.color = blue.lightened(0.12)
	builder.tube(Vector3(0, height - 0.012, 0), Vector3(0, height + 0.006, 0), top + 0.008, top + 0.008, segments, true)

	builder.color = Color("8d8a80")
	var previous := Vector3(-top - 0.004, height - 0.02, 0)
	for step: int in range(1, 9):
		var angle := PI * float(step) / 8.0
		var point := Vector3(-cos(angle) * (top + 0.004), height - 0.02 + sin(angle) * 0.05, sin(angle) * (top + 0.02))
		builder.tube(previous, point, 0.004, 0.004, 4, false)
		previous = point
	return _wrap(builder)


## A single rubber sandal that has clearly seen things.
func _build_sandal() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = Color("3f6a8a")
	var sole := PackedVector2Array([
		Vector2(-0.045, -0.12), Vector2(0.04, -0.125), Vector2(0.055, -0.03), Vector2(0.05, 0.08),
		Vector2(0.02, 0.13), Vector2(-0.03, 0.125), Vector2(-0.055, 0.05), Vector2(-0.05, -0.05)])
	builder.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0, 0.011, 0))
	builder.slab(sole, 0.022)
	builder.transform = Transform3D.IDENTITY
	builder.color = Color("d9cdb4")
	builder.tube(Vector3(0, 0.022, -0.085), Vector3(-0.05, 0.05, 0.0), 0.007, 0.007, 5)
	builder.tube(Vector3(0, 0.022, -0.085), Vector3(0.05, 0.05, 0.0), 0.007, 0.007, 5)
	builder.tube(Vector3(-0.05, 0.05, 0.0), Vector3(-0.045, 0.02, 0.03), 0.007, 0.007, 5)
	builder.tube(Vector3(0.05, 0.05, 0.0), Vector3(0.045, 0.02, 0.03), 0.007, 0.007, 5)
	return _wrap(builder)


## A dented tin can, mostly rust.
func _build_can() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		return base.lerp(Color("7a4a2f"), 0.55 if sin(point.y * 70.0 + point.x * 40.0) > 0.1 else 0.0)
	builder.color = Color("a39a8c")
	builder.tube(Vector3(0, 0, 0), Vector3(0.012, 0.11, 0), 0.036, 0.034, 9, true)
	builder.color_rule = Callable()
	builder.color = Color("6d665c")
	builder.tube(Vector3(0.012, 0.108, 0), Vector3(0.013, 0.114, 0), 0.036, 0.036, 9, true)
	builder.color = Color("3a342e")
	builder.tube(Vector3(0.012, 0.106, 0), Vector3(0.013, 0.116, 0), 0.026, 0.026, 9, true)
	return _wrap(builder)


## An old motorcycle tyre, lying flat.
func _build_tyre() -> Node3D:
	var builder := MeshBuilder.new()
	var outer := 0.29
	var tube_radius := 0.06
	var around := 16
	var across := 7
	var rings: Array = []
	for step: int in around + 1:
		var angle := TAU * float(step) / float(around)
		var centre := Vector3(cos(angle), 0.0, sin(angle)) * (outer - tube_radius)
		var outward := Vector3(cos(angle), 0.0, sin(angle)) * tube_radius
		rings.append(builder.ring(centre + Vector3(0, tube_radius, 0), outward, Vector3(0, tube_radius, 0), across, 2.6))
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		var angle := atan2(point.z, point.x)
		return base.lightened(0.08) if sin(angle * 22.0) > 0.2 else base
	builder.color = Color("2b2a28")
	builder.loft(rings, false, false)
	builder.color_rule = Callable()
	return _wrap(builder)


# --- Market props (GDD 72, 185.15) ------------------------------------------

const MARKET_TABLE := "prop_market_table"
const MARKET_SCALE := "prop_market_scale"
const MARKET_FREEZER := "prop_market_freezer"
const MARKET_THERMOS := "prop_market_thermos"
const MARKET_JAR_SET := "prop_market_jar_set"
const PLASTIC_CHAIR := "prop_plastic_chair"
const HANGING_LAMP := "prop_hanging_lamp"
const MARKET_PRICE_BOARD := "prop_market_price_board"
const MARKET_FAN := "prop_market_fan"

const TABLE_HEIGHT := 0.82
const WOOD := Color("8a6a4a")
const WOOD_DARK := Color("6b513a")
const CREAM := Color("e9dcc0")
const FADED_RED := Color("a9534d")
const OLIVE := Color("778b59")


## Rough wooden counter: uneven planks on a plain frame.
func _build_table() -> Node3D:
	var builder := MeshBuilder.new()
	var width := 2.3
	var depth := 0.78
	var planks := 5
	for plank: int in planks:
		var offset := (float(plank) + 0.5) / float(planks) - 0.5
		builder.color = WOOD.lightened(0.06 if plank % 2 == 0 else -0.04)
		builder.box(Vector3(width, 0.045, depth / float(planks) - 0.008), Vector3(0, TABLE_HEIGHT - 0.0225 - 0.004 * float(plank % 2), offset * depth))
	builder.color = WOOD_DARK
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		builder.box(Vector3(0.075, TABLE_HEIGHT - 0.045, 0.075), Vector3(corner.x * (width * 0.5 - 0.09), (TABLE_HEIGHT - 0.045) * 0.5, corner.y * (depth * 0.5 - 0.08)))
	builder.box(Vector3(width - 0.2, 0.06, 0.04), Vector3(0, TABLE_HEIGHT - 0.11, depth * 0.5 - 0.08))
	builder.box(Vector3(width - 0.2, 0.06, 0.04), Vector3(0, 0.22, -depth * 0.5 + 0.08))
	return _wrap(builder)


## Old dial scale with a metal pan on top.
func _build_scale() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = Color("7e8a86")
	builder.box(Vector3(0.26, 0.05, 0.22), Vector3(0, 0.025, 0))
	builder.color = Color("9aa39e")
	builder.box(Vector3(0.2, 0.22, 0.13), Vector3(0, 0.16, 0.01))
	# Dial face toward the customer (+Z), with a red needle.
	builder.color = CREAM
	builder.tube(Vector3(0, 0.17, 0.076), Vector3(0, 0.17, 0.084), 0.075, 0.075, 12, true)
	builder.color = FADED_RED
	builder.transform = Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(-35.0)), Vector3(0, 0.17, 0.088))
	builder.box(Vector3(0.008, 0.066, 0.004), Vector3(0, 0.03, 0))
	builder.transform = Transform3D.IDENTITY
	builder.color = Color("6f7a76")
	builder.tube(Vector3(0, 0.27, 0), Vector3(0, 0.31, 0), 0.02, 0.02, 6)
	builder.color = Color("b9c0bb")
	builder.tube(Vector3(0, 0.31, 0), Vector3(0, 0.345, 0), 0.07, 0.17, 12, true)
	return _wrap(builder)


## A yellowed chest freezer that has outlived several owners.
func _build_freezer() -> Node3D:
	var builder := MeshBuilder.new()
	var body := Color("ddd6c2")
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		# Rust creeping up from the bottom edge.
		return base.lerp(Color("8f5a3c"), clampf(0.7 - point.y * 5.0, 0.0, 0.55))
	builder.color = body
	builder.box(Vector3(1.15, 0.78, 0.62), Vector3(0, 0.39, 0))
	builder.color_rule = Callable()
	builder.color = body.lightened(0.08)
	builder.box(Vector3(1.18, 0.07, 0.65), Vector3(0, 0.815, 0))
	builder.color = Color("6f6a60")
	builder.box(Vector3(0.22, 0.03, 0.03), Vector3(0.3, 0.79, 0.335))
	builder.box(Vector3(1.0, 0.012, 0.012), Vector3(0, 0.775, 0.314))
	builder.color = Color("3a3631")
	builder.box(Vector3(0.3, 0.1, 0.012), Vector3(-0.32, 0.16, 0.312))
	return _wrap(builder)


## Tall thermos flask with a cup lid and a side handle.
func _build_thermos() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = FADED_RED
	builder.tube(Vector3(0, 0, 0), Vector3(0, 0.27, 0), 0.062, 0.062, 10, true)
	builder.color = CREAM
	builder.tube(Vector3(0, 0.07, 0), Vector3(0, 0.12, 0), 0.0635, 0.0635, 10, false)
	builder.color = Color("9aa39e")
	builder.tube(Vector3(0, 0.27, 0), Vector3(0, 0.30, 0), 0.058, 0.05, 10, true)
	builder.color = Color("d8d2c2")
	builder.tube(Vector3(0, 0.30, 0), Vector3(0, 0.36, 0), 0.05, 0.045, 10, true)
	builder.color = Color("3a3631")
	builder.tube(Vector3(0.062, 0.21, 0), Vector3(0.105, 0.2, 0), 0.01, 0.01, 5)
	builder.tube(Vector3(0.105, 0.2, 0), Vector3(0.105, 0.1, 0), 0.01, 0.01, 5)
	builder.tube(Vector3(0.105, 0.1, 0), Vector3(0.062, 0.09, 0), 0.01, 0.01, 5)
	return _wrap(builder)


## Three snack jars with red lids, each a different height.
func _build_jar_set() -> Node3D:
	var builder := MeshBuilder.new()
	var contents: Array[Color] = [Color("d9b56a"), Color("c98f5c"), Color("e3d2a4")]
	for index: int in 3:
		var x := (float(index) - 1.0) * 0.17
		var height := 0.2 + 0.04 * float((index + 1) % 3)
		builder.color = contents[index]
		builder.tube(Vector3(x, 0, 0), Vector3(x, height * 0.7, 0), 0.062, 0.066, 10, true)
		builder.color = Color("dfe6e0")
		builder.tube(Vector3(x, height * 0.7, 0), Vector3(x, height, 0), 0.066, 0.058, 10, false)
		builder.color = FADED_RED
		builder.tube(Vector3(x, height, 0), Vector3(x, height + 0.03, 0), 0.062, 0.062, 10, true)
	return _wrap(builder)


## Stackable plastic chair, faded red.
func _build_chair() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = FADED_RED.lightened(0.08)
	var seat := 0.44
	builder.box(Vector3(0.44, 0.03, 0.42), Vector3(0, seat, 0))
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		# Legs splay outward slightly, like the real thing.
		builder.tube(Vector3(corner.x * 0.18, seat, corner.y * 0.17), Vector3(corner.x * 0.22, 0, corner.y * 0.21), 0.022, 0.018, 5)
	builder.color = FADED_RED
	builder.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(8.0)), Vector3(0, seat, -0.2))
	builder.box(Vector3(0.42, 0.34, 0.025), Vector3(0, 0.27, 0))
	builder.box(Vector3(0.035, 0.12, 0.025), Vector3(-0.18, 0.06, 0))
	builder.box(Vector3(0.035, 0.12, 0.025), Vector3(0.18, 0.06, 0))
	builder.transform = Transform3D.IDENTITY
	return _wrap(builder)


## Bare bulb under a tin shade on a cord. The origin is where it hangs from.
func _build_lamp() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = Color("3a3631")
	builder.tube(Vector3(0, 0, 0), Vector3(0, -0.5, 0), 0.006, 0.006, 4, false)
	builder.color = Color("6f7a5e")
	builder.tube(Vector3(0, -0.5, 0), Vector3(0, -0.6, 0), 0.03, 0.17, 10, false)
	builder.color = Color("fff0c2")
	builder.blob(Vector3(0, -0.6, 0), Vector3(0.045, 0.06, 0.045), 7, 4)
	var root := _wrap(builder)
	var bulb := Marker3D.new()
	bulb.name = "BulbSpot"
	bulb.position = Vector3(0, -0.62, 0)
	root.add_child(bulb)
	return root


## Hand-painted price board: faded red header and rows of chalk marks.
func _build_price_board() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = WOOD_DARK
	builder.box(Vector3(0.9, 0.66, 0.03), Vector3(0, 0, 0))
	builder.color = CREAM.darkened(0.04)
	builder.box(Vector3(0.82, 0.58, 0.012), Vector3(0, 0, 0.018))
	builder.color = FADED_RED
	builder.box(Vector3(0.82, 0.1, 0.014), Vector3(0, 0.24, 0.02))
	builder.color = Color("5a5046")
	for row: int in 5:
		var y := 0.12 - 0.085 * float(row)
		builder.box(Vector3(0.34 - 0.03 * float(row % 3), 0.018, 0.014), Vector3(-0.2, y, 0.021))
		builder.box(Vector3(0.16, 0.018, 0.014), Vector3(0.27, y, 0.021))
	return _wrap(builder)


## Small desk fan with a round cage. The blades are a separate node, built
## around their own hub, so the scene can spin them (GDD 172.9).
func _build_fan() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = OLIVE.darkened(0.1)
	builder.tube(Vector3(0, 0, 0), Vector3(0, 0.03, 0), 0.085, 0.07, 10, true)
	builder.tube(Vector3(0, 0.03, 0), Vector3(0, 0.2, 0), 0.016, 0.014, 6)
	builder.tube(Vector3(0, 0.22, -0.06), Vector3(0, 0.22, 0.0), 0.04, 0.035, 8, true)
	builder.color = Color("c9cfc6")
	for ring: float in [0.0, 0.035]:
		var previous := Vector3(0.12, 0.22, ring + 0.01)
		for step: int in range(1, 13):
			var angle := TAU * float(step) / 12.0
			var point := Vector3(cos(angle) * 0.12, 0.22 + sin(angle) * 0.12, ring + 0.01)
			builder.tube(previous, point, 0.005, 0.005, 3, false)
			previous = point
	var root := _wrap(builder)

	var blades := MeshBuilder.new()
	blades.color = OLIVE.lightened(0.15)
	for blade: int in 3:
		blades.transform = Transform3D(Basis(Vector3(0, 0, 1), TAU * float(blade) / 3.0 + 0.3), Vector3.ZERO)
		blades.box(Vector3(0.1, 0.035, 0.006), Vector3(0.055, 0, 0))
	var blades_node := MeshInstance3D.new()
	blades_node.name = "Blades"
	blades_node.mesh = blades.commit()
	blades_node.material_override = load(MaterialBuilder.VERTEX_COLOR)
	blades_node.position = Vector3(0, 0.22, 0.028)
	root.add_child(blades_node)
	return root
