@tool
extends RefCounted
## Generates the fifteen sets as warm miniature dioramas (VISUAL_STYLE_GUIDE 1, 6,
## 7; GDD 4, 103, 174.6, 184.9, 185.13-185.19).
##
## Every set is built for the one fixed camera: orthographic, looking from
## the -X,-Z side toward +X,+Z at 35 degrees. Positions are worked out in
## screen terms with `uv(u, v)`: `u` runs to the right of the screen and `v`
## into the picture. Rooms are dollhouse cut-aways: the walls nearest the
## camera are only 0.16 m high, the far walls are full height with checkered
## curtains. Outdoor sets sit in a wide patch of land so the edge of the
## world never shows, with the surroundings pulled toward the background
## colour so the playable diorama stays the centre of attention.
##
## Each set carries the guide's light rig, a `CameraFocus` marker (where the
## gameplay camera looks and how wide it frames, per layout), the named spots
## the scenes stand people on, and an AmbientMotion node for the little life
## in it (swaying reeds and crowns, drifting water lines).

const SoftMesh := preload("res://tools/generators/soft_mesh.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")
const Kit := preload("res://tools/generators/diorama_kit.gd")
const Style := preload("res://scripts/visual/diorama_style.gd")
const ScatterFieldScript := preload("res://scripts/actors/scatter_field.gd")

const GENERATOR_ID := "environment_builder"
const GENERATOR_VERSION := 2
const PLACEMENT_SEED := 20261114
const PROP_PATH := "res://generated/scenes/props/%s.tscn"

const LAKE_SET_PATH := "res://generated/scenes/environment/env_lake_set.tscn"
const MARKET_SET_PATH := "res://generated/scenes/environment/env_market_set.tscn"
const BOXING_SET_PATH := "res://generated/scenes/environment/env_boxing_set.tscn"
const ARM_SET_PATH := "res://generated/scenes/environment/env_arm_set.tscn"
const DANCE_SET_PATH := "res://generated/scenes/environment/env_dance_set.tscn"
const SUWIT_SET_PATH := "res://generated/scenes/environment/env_suwit_set.tscn"
const HOME_SET_PATH := "res://generated/scenes/environment/env_home_set.tscn"
## Revision 6.7: the four new fishing spots and their duel arenas.
const SET_PATH := "res://generated/scenes/environment/%s.tscn"

const SQRT_HALF := 0.70710678
const WATER_Y := 0.0
const LAND_Y := 0.09

const WOOD := Style.PINE
const WOOD_DARK := Color("a8784a")
const CREAM := Color("f6e7c8")
const PLASTER := Color("f3dcc0")
const PLASTER_SHADE := Color("e8c9a6")
const FADED_RED := Color("cf6a58")
const ROOF := Color("cf7a55")

## The set being built collects its swaying and drifting nodes here.
var _motion: Array = []
var _random := RandomNumberGenerator.new()


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var sets: Dictionary[String, Array] = {
		"env_lake_set": [build_lake_set, LAKE_SET_PATH],
		"env_market_set": [build_market_set, MARKET_SET_PATH],
		"env_boxing_set": [build_boxing_set, BOXING_SET_PATH],
		"env_arm_set": [build_arm_set, ARM_SET_PATH],
		"env_dance_set": [build_dance_set, DANCE_SET_PATH],
		"env_suwit_set": [build_suwit_set, SUWIT_SET_PATH],
		"env_home_set": [build_home_set, HOME_SET_PATH],
		"env_river_set": [build_river_set, SET_PATH % "env_river_set"],
		"env_reservoir_set": [build_reservoir_set, SET_PATH % "env_reservoir_set"],
		"env_estuary_set": [build_estuary_set, SET_PATH % "env_estuary_set"],
		"env_pier_set": [build_pier_set, SET_PATH % "env_pier_set"],
		"env_silat_set": [build_silat_set, SET_PATH % "env_silat_set"],
		"env_tambang_set": [build_tambang_set, SET_PATH % "env_tambang_set"],
		"env_gasing_set": [build_gasing_set, SET_PATH % "env_gasing_set"],
		"env_pinang_set": [build_pinang_set, SET_PATH % "env_pinang_set"],
	}
	for set_id: String in sets:
		var root: Node3D = sets[set_id][0].call()
		var path: String = sets[set_id][1]
		var save_error := GeneratorIo.save_scene(root, path)
		root.free()
		if save_error != OK:
			errors.append("%s: could not save (%s)" % [set_id, error_string(save_error)])
		else:
			manifest.register(set_id, GENERATOR_ID, GENERATOR_VERSION, PLACEMENT_SEED, path)
	return errors


# --- Screen-space placement ---------------------------------------------------

## A world point from screen terms: `u` to the right, `v` into the picture.
static func uv(u: float, v: float, y: float = 0.0) -> Vector3:
	return Vector3((v - u) * SQRT_HALF, y, (v + u) * SQRT_HALF)


static func to_uv(point: Vector3) -> Vector2:
	return Vector2((point.z - point.x) * SQRT_HALF, (point.x + point.z) * SQRT_HALF)


## Yaw that turns a person (who faces -Z) to face `direction`.
static func person_yaw(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


## Yaw that turns a standing fish (belly toward +X) to face `direction`.
static func fish_yaw(direction: Vector3) -> float:
	return atan2(-direction.z, direction.x)


## Directions in screen terms.
static func toward_camera() -> Vector3:
	return Vector3(-SQRT_HALF, 0.0, -SQRT_HALF)


static func into_picture() -> Vector3:
	return Vector3(SQRT_HALF, 0.0, SQRT_HALF)


static func screen_right() -> Vector3:
	return Vector3(-SQRT_HALF, 0.0, SQRT_HALF)


func _begin(set_seed: int) -> void:
	_motion = []
	_random.seed = PLACEMENT_SEED + set_seed


func _finish(root: Node3D) -> void:
	if not _motion.is_empty():
		root.add_child(Kit.motion(_motion))


# --- Lake set (GDD 4, 185.13) -------------------------------------------------
# A small pond: Darto's grassy bank at the bottom of the screen, the water
# above him, reeds and one big shade tree, his motorcycle parked behind him,
# and across the water a line of trees, the road, the power poles, a few low
# houses and Bu Yati's warung, all a little muted.

## The pond is an ellipse in screen terms (centre u, v and semi-axes).
const POND_CENTRE := Vector2(0.6, 3.4)
const POND_AXES := Vector2(7.6, 2.8)
const DARTO_UV := Vector2(0.0, 0.0)
const FLOAT_UV := Vector2(0.35, 2.55)


## Signed distance in metres from the shoreline: positive on land.
static func pond_distance(u: float, v: float) -> float:
	var du := (u - POND_CENTRE.x) / POND_AXES.x
	var dv := (v - POND_CENTRE.y) / POND_AXES.y
	var wobble := 0.12 * sin(u * 1.3 + 0.4) + 0.08 * sin(u * 2.7 + v * 0.9)
	return (sqrt(du * du + dv * dv) - 1.0) * POND_AXES.y + wobble


static func lake_height(u: float, v: float) -> float:
	var distance := pond_distance(u, v)
	if distance < 0.0:
		return LAND_Y - 0.06 + maxf(distance, -1.2) * 0.3
	var rise := LAND_Y + 0.025 * sin(u * 0.7) * sin(v * 0.5) * minf(distance, 1.0)
	return lerpf(LAND_Y - 0.06, rise, smoothstep(0.0, 0.28, distance))


static func lake_point(u: float, v: float) -> Vector3:
	return uv(u, v, lake_height(u, v))


func build_lake_set() -> Node3D:
	_begin(1)
	var root := Node3D.new()
	root.name = "EnvLakeSet"
	root.add_child(Kit.lighting())

	# Ground: grass, a sandy rim at the water and a worn path to Darto's spot.
	var ground := SoftMesh.new()
	ground.color_rule = func(point: Vector3, _base: Color) -> Color:
		var at := to_uv(point)
		var distance := pond_distance(at.x, at.y)
		var tint := Style.GRASS.lerp(Style.GRASS_LIGHT, 0.5 + 0.5 * sin(at.x * 0.6 + 1.0) * sin(at.y * 0.45))
		if distance < 0.42:
			tint = tint.lerp(Style.SAND, smoothstep(0.42, 0.18, distance))
		if distance < 0.0:
			tint = Style.SOIL_DEEP
		var path := absf(at.x - 0.35 * sin(at.y * 0.4) - 0.15 * at.y) < 0.32 and at.y < -0.25 and at.y > -6.0
		if path:
			tint = tint.lerp(Style.SAND.darkened(0.04), 0.7)
		return _mute_far(tint, at, Vector2(0.0, 1.5), 7.0, 16.0)
	var rows: Array = []
	for row: int in 61:
		var v := -12.0 + float(row) * 0.5
		var line := PackedVector3Array()
		for column: int in 61:
			var u := -15.0 + float(column) * 0.5
			line.append(lake_point(u, v))
		rows.append(line)
	ground.grid(rows)
	root.add_child(Kit.bake("EnvLakeShore", ground))

	root.add_child(Kit.bake("EnvLakeWater", _pond_water()))
	var waves := Node3D.new()
	waves.name = "WaterLines"
	root.add_child(waves)
	for index: int in 9:
		var at := Vector2(POND_CENTRE.x + _random.randf_range(-5.5, 5.5), POND_CENTRE.y + _random.randf_range(-1.6, 1.8))
		if pond_distance(at.x, at.y) > -0.6:
			at = POND_CENTRE + Vector2(_random.randf_range(-3.0, 3.0), _random.randf_range(-0.8, 0.8))
		var line := _water_line(_random.randf_range(0.35, 0.8))
		line.name = "Line%d" % index
		line.position = uv(at.x, at.y, WATER_Y + 0.004)
		line.rotation.y = person_yaw(screen_right()) + PI * 0.5
		waves.add_child(line)
		_motion.append(["../WaterLines/%s" % line.name, "drift", _random.randf_range(0.12, 0.25), _random.randf_range(0.25, 0.45), _random.randf_range(0.0, TAU), 0])

	var plants := Node3D.new()
	plants.name = "Plants"
	root.add_child(plants)
	for spec: Array in [[Vector2(-1.7, 0.95), 9], [Vector2(-2.4, 1.15), 7], [Vector2(2.6, 0.95), 8], [Vector2(-5.4, 2.0), 9], [Vector2(5.3, 1.5), 8], [Vector2(-0.9, 6.3), 7], [Vector2(3.6, 6.25), 8]]:
		var reeds := _reed_cluster(spec[1])
		reeds.name = "Reeds%d" % plants.get_child_count()
		var spot: Vector2 = spec[0]
		reeds.position = uv(spot.x, spot.y, WATER_Y - 0.02)
		plants.add_child(reeds)
		_motion.append(["../Plants/%s" % reeds.name, "sway", 0.05, _random.randf_range(0.8, 1.2), _random.randf_range(0.0, TAU), 0])
	for spec: Array in [[Vector2(-4.0, 2.6), 0.0], [Vector2(4.6, 2.3), 1.0], [Vector2(1.9, 5.4), 2.0]]:
		var pad := _lily_pads(int(spec[1]))
		pad.name = "LilyPads%d" % int(spec[1])
		var spot: Vector2 = spec[0]
		pad.position = uv(spot.x, spot.y, WATER_Y + 0.003)
		plants.add_child(pad)
	for spec: Array in [[Vector2(-1.3, -1.5)], [Vector2(1.9, -2.6)], [Vector2(-3.7, -2.4)], [Vector2(3.5, -0.4)], [Vector2(-2.6, -4.3)], [Vector2(0.9, -5.2)]]:
		var flowers := _flower_patch()
		flowers.name = "Flowers%d" % plants.get_child_count()
		var spot: Vector2 = spec[0]
		flowers.position = lake_point(spot.x, spot.y)
		plants.add_child(flowers)

	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	# The one major shade tree, left of Darto (GDD 185.13).
	trees.add_child(_tree("EnvTreeLargeA", lake_point(-3.3, -0.8), 2.3, 0.85, 0.0))
	trees.add_child(_tree("EnvTreeLargeB", lake_point(5.8, -1.6), 1.9, 0.7, 0.05))
	for index: int in 9:
		var u := -8.0 + float(index) * 2.1 + _random.randf_range(-0.5, 0.5)
		var v := 7.3 + _random.randf_range(0.0, 1.4)
		if pond_distance(u, v) < 0.4:
			v += 1.0
		trees.add_child(_tree("FarTree%d" % index, lake_point(u, v), _random.randf_range(1.5, 2.1), _random.randf_range(0.55, 0.75), 0.25))
	for spec: Array in [[Vector2(-6.2, -1.0), 0.0], [Vector2(-1.8, -3.4), 0.0], [Vector2(4.2, -4.0), 0.1], [Vector2(-5.5, 4.9), 0.2], [Vector2(6.6, 4.4), 0.2]]:
		var bush := _bush(spec[1])
		bush.name = "Bush%d" % trees.get_child_count()
		var spot: Vector2 = spec[0]
		bush.position = lake_point(spot.x, spot.y)
		trees.add_child(bush)

	var rocks := SoftMesh.new()
	for spec: Array in [[Vector2(1.5, 0.55), 0.13], [Vector2(1.8, 0.62), 0.08], [Vector2(-3.4, 1.4), 0.15], [Vector2(-6.9, 3.0), 0.12], [Vector2(6.4, 2.8), 0.14], [Vector2(-1.0, 6.25), 0.1]]:
		var spot: Vector2 = spec[0]
		_rock(rocks, lake_point(spot.x, spot.y), spec[1])
	root.add_child(Kit.bake("Rocks", rocks))
	root.add_child(_build_scatter("EnvGrassClusterA", _grass_tuft(), _tuft_spots()))

	root.add_child(_far_side())
	root.add_child(_warung_shell(lake_point(-3.2, 7.4), 0.25))

	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_motorcycle_darto", "Motorcycle", lake_point(1.6, -1.65), person_yaw(screen_right()) - PI * 0.5 - 0.35)

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	var darto := lake_point(DARTO_UV.x, DARTO_UV.y)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(into_picture())), darto)))
	markers.add_child(Kit.marker("FloatSpot", Transform3D(Basis.IDENTITY, uv(FLOAT_UV.x, FLOAT_UV.y, WATER_Y))))
	markers.add_child(Kit.marker("BucketSpot", Transform3D(Basis(Vector3.UP, 0.5), lake_point(0.72, -0.18))))
	markers.add_child(Kit.focus_marker(uv(0.25, 1.35, 0.3), 8.6, 6.8))
	markers.add_child(_focus_pair("MenuFocus", uv(-2.6, 1.3, 0.3), 9.8, uv(0.0, 0.9, 0.3), 6.8))
	markers.add_child(Kit.focus_marker(uv(0.35, 0.1, 0.35), 5.6, 5.6, "ResultFocus"))
	markers.add_child(_focus_pair("WheelFocus", uv(2.4, 1.1, 0.4), 6.8, uv(0.4, -0.6, 0.4), 6.2))
	markers.add_child(Kit.focus_marker(uv(0.0, 2.2, 0.4), 11.0, 8.0, "StoryWide"))
	markers.add_child(Kit.focus_marker(uv(0.4, 0.2, 0.4), 6.2, 6.2, "StoryMedium"))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.0, 0.5), 5.6, 5.6, "StoryDarto"))
	markers.add_child(Kit.focus_marker(uv(0.35, 2.2, 0.2), 6.8, 6.8, "StoryWater"))
	_finish(root)
	return root


func _pond_water() -> RefCounted:
	var water := SoftMesh.new()
	water.color_rule = func(point: Vector3, _base: Color) -> Color:
		var at := to_uv(point)
		var depth := -pond_distance(at.x, at.y)
		var tint := Style.WATER_SHALLOW.lerp(Style.WATER, smoothstep(0.0, 0.6, depth)).lerp(Style.WATER_DEEP, smoothstep(0.8, 2.2, depth))
		return _mute_far(tint, at, Vector2(0.0, 1.5), 7.0, 16.0)
	var rows: Array = []
	for row: int in 17:
		var v := POND_CENTRE.y - POND_AXES.y - 0.6 + float(row) * (POND_AXES.y * 2.0 + 1.2) / 16.0
		var line := PackedVector3Array()
		for column: int in 37:
			var u := POND_CENTRE.x - POND_AXES.x - 0.8 + float(column) * (POND_AXES.x * 2.0 + 1.6) / 36.0
			line.append(uv(u, v, WATER_Y))
		rows.append(line)
	water.grid(rows)
	return water


## A pale streak lying on the water (guide 4.2: pattern from geometry).
func _water_line(length: float) -> MeshInstance3D:
	var builder := SoftMesh.new()
	builder.color = Style.WATER_LINE
	builder.transform = Transform3D(Basis.from_scale(Vector3(1.0, 0.25, 1.0)), Vector3.ZERO)
	builder.capsule(Vector3(-length * 0.5, 0, 0), Vector3(length * 0.5, 0, 0), 0.016, -1.0, 6, 2)
	return Kit.bake("Line", builder)


func _reed_cluster(count: int) -> Node3D:
	var builder := SoftMesh.new()
	for index: int in count:
		var angle := TAU * float(index) / float(count) + _random.randf_range(-0.3, 0.3)
		var spread := _random.randf_range(0.03, 0.16)
		var base := Vector3(cos(angle) * spread, 0.0, sin(angle) * spread)
		var height := _random.randf_range(0.32, 0.55)
		var lean := Vector3(base.x * 0.6, 0.0, base.z * 0.6)
		builder.color = Style.REED.lerp(Style.LEAF_DEEP, _random.randf())
		builder.capsule(base, base + lean + Vector3(0, height, 0), 0.011, 0.006, 6, 2)
		if index % 2 == 0:
			builder.color = Style.CARAMEL.lightened(0.15)
			var head := base + lean + Vector3(0, height * 0.82, 0)
			builder.capsule(head - Vector3(0, 0.035, 0), head + Vector3(0, 0.035, 0), 0.017, -1.0, 8, 2)
	var node := Kit.bake("Reeds", builder)
	return node


func _lily_pads(variant: int) -> Node3D:
	var builder := SoftMesh.new()
	for index: int in 3:
		var angle := float(index) * 2.1 + float(variant)
		var at := Vector3(cos(angle) * 0.18, 0.0, sin(angle) * 0.14)
		builder.color = Style.LEAF.lerp(Style.LEAF_DEEP, 0.3 * float(index % 2))
		builder.cylinder(at, at + Vector3(0, 0.008, 0), 0.1 - 0.015 * float(index), -1.0, 12)
	builder.color = Style.STRAWBERRY
	builder.sphere(Vector3(0.0, 0.03, 0.0), Vector3(0.035, 0.028, 0.035), 8, 4)
	builder.color = Style.BUTTER
	builder.sphere(Vector3(0.0, 0.05, 0.0), Vector3.ONE * 0.012, 6, 3)
	return Kit.bake("Pads", builder)


func _flower_patch() -> Node3D:
	var builder := SoftMesh.new()
	var colours: Array[Color] = [Style.STRAWBERRY, Style.BUTTER, Style.FLOUR, Style.PERIWINKLE]
	for index: int in 6:
		var at := Vector3(_random.randf_range(-0.18, 0.18), 0.0, _random.randf_range(-0.18, 0.18))
		builder.color = Style.LEAF_DEEP
		builder.capsule(at, at + Vector3(0, 0.06, 0), 0.005, -1.0, 4, 1)
		builder.color = colours[(index + _random.randi() % 4) % colours.size()]
		builder.sphere(at + Vector3(0, 0.07, 0), Vector3(0.02, 0.014, 0.02), 6, 3)
	return Kit.bake("Flowers", builder)


## A round tree: a trunk and a crown of soft spheres. The crown is its own
## node so it can sway; a fake shadow sits under the crown.
func _tree(node_name: String, base: Vector3, height: float, crown: float, mute: float) -> Node3D:
	var tree := Node3D.new()
	tree.name = node_name
	tree.position = base
	var trunk := SoftMesh.new()
	trunk.color = Style.muted(Style.BARK, mute)
	trunk.capsule(Vector3.ZERO, Vector3(0, height * 0.62, 0), 0.075 * height, 0.05 * height, 8, 2)
	trunk.capsule(Vector3(0, height * 0.42, 0), Vector3(crown * 0.35, height * 0.6, 0.0), 0.03 * height, 0.02 * height, 6, 2)
	tree.add_child(Kit.bake("Trunk", trunk))
	var leaves := SoftMesh.new()
	var tints: Array[Color] = [Style.LEAF, Style.LEAF_LIGHT, Style.LEAF_DEEP, Style.LEAF]
	for index: int in 5:
		var angle := TAU * float(index) / 5.0 + _random.randf_range(-0.3, 0.3)
		var offset := Vector3(cos(angle) * crown * 0.45, _random.randf_range(-0.15, 0.2) * crown, sin(angle) * crown * 0.45)
		if index == 4:
			offset = Vector3(0.0, crown * 0.35, 0.0)
		leaves.color = Style.muted(tints[index % tints.size()], mute)
		leaves.sphere(offset, Vector3.ONE * crown * _random.randf_range(0.55, 0.7), 12, 6, 0.04, _random.randi())
	var canopy := Kit.bake("Crown", leaves)
	canopy.position = Vector3(0, height * 0.72, 0)
	tree.add_child(canopy)
	tree.add_child(Kit.furniture_shadow(Vector2(crown * 1.5, crown * 1.5)))
	_motion.append(["../%s/Crown" % _tree_path(tree), "sway", 0.018, _random.randf_range(0.6, 0.9), _random.randf_range(0.0, TAU), 0])
	return tree


## Trees can live under a parent; the motion path is filled in by `_finish`.
func _tree_path(tree: Node3D) -> String:
	return "Trees/%s" % tree.name


func _bush(mute: float) -> Node3D:
	var builder := SoftMesh.new()
	for index: int in 3:
		var at := Vector3((float(index) - 1.0) * 0.16, 0.12 + 0.04 * float(index % 2), _random.randf_range(-0.05, 0.05))
		builder.color = Style.muted([Style.LEAF_DEEP, Style.LEAF, Style.LEAF_LIGHT][index], mute)
		builder.sphere(at, Vector3(0.17, 0.15, 0.16) * _random.randf_range(0.85, 1.1), 12, 6, 0.05, _random.randi())
	var node := Node3D.new()
	node.add_child(Kit.bake("Leaves", builder))
	node.add_child(Kit.furniture_shadow(Vector2(0.6, 0.35)))
	return node


func _rock(builder: RefCounted, at: Vector3, size: float) -> void:
	builder.color = Style.STONE.lerp(Style.STONE_DEEP, _random.randf())
	builder.sphere(at + Vector3(0, size * 0.35, 0), Vector3(size, size * 0.62, size * 0.85), 10, 5, 0.08, _random.randi())


func _grass_tuft() -> ArrayMesh:
	var builder := SoftMesh.new()
	for index: int in 4:
		var angle := TAU * float(index) / 4.0 + 0.4
		var base := Vector3(cos(angle) * 0.02, 0.0, sin(angle) * 0.02)
		builder.color = Style.GRASS_DEEP.lerp(Style.LEAF_LIGHT, 0.25 * float(index % 3))
		builder.cone(base, base + Vector3(cos(angle) * 0.03, 0.09 + 0.02 * float(index % 2), sin(angle) * 0.03), 0.014, 5)
	return builder.commit(MaterialBuilder.surface_materials())


func _tuft_spots() -> Array:
	var spots: Array = []
	var attempts := 0
	while spots.size() < 220 and attempts < 4000:
		attempts += 1
		var u := _random.randf_range(-12.0, 12.0)
		var v := _random.randf_range(-11.0, 14.0)
		var distance := pond_distance(u, v)
		if distance < 0.35:
			continue
		if Vector2(u, v).distance_to(DARTO_UV) < 0.6 or Vector2(u, v).distance_to(Vector2(1.6, -1.65)) < 0.6:
			continue
		spots.append([lake_point(u, v), _random.randf_range(0.0, TAU), _random.randf_range(0.8, 1.3)])
	return spots


func _build_scatter(node_name: String, mesh: ArrayMesh, spots: Array) -> MultiMeshInstance3D:
	var field := MultiMeshInstance3D.new()
	field.name = node_name
	field.set_script(ScatterFieldScript)
	field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var placements := PackedFloat32Array()
	for spot: Array in spots:
		var transform := Transform3D(Basis(Vector3.UP, spot[1]).scaled(Vector3.ONE * float(spot[2])), spot[0])
		ScatterFieldScript.pack_transform(placements, transform)
	field.set("cluster_mesh", mesh)
	field.set("placements", placements)
	return field


## The far side of the pond: the road with its power poles and low houses,
## all pulled toward the background colour (guide 5.2).
func _far_side() -> Node3D:
	var far := Node3D.new()
	far.name = "FarShore"
	var road := SoftMesh.new()
	for step: int in 16:
		var u0 := -15.0 + float(step) * 2.0
		var u1 := u0 + 2.0
		road.color = Style.muted(Style.ROAD, 0.3)
		road.flat_quad(uv(u0, 9.7, LAND_Y + 0.01), uv(u1, 9.7, LAND_Y + 0.01), uv(u1, 10.8, LAND_Y + 0.01), uv(u0, 10.8, LAND_Y + 0.01))
		road.color = Style.muted(Style.FLOUR, 0.3)
		road.flat_quad(uv(u0 + 0.3, 10.22, LAND_Y + 0.012), uv(u0 + 1.2, 10.22, LAND_Y + 0.012), uv(u0 + 1.2, 10.28, LAND_Y + 0.012), uv(u0 + 0.3, 10.28, LAND_Y + 0.012))
	far.add_child(Kit.bake("Road", road))

	var poles := SoftMesh.new()
	var tops: Array[Vector3] = []
	for index: int in 6:
		var base := uv(-11.0 + float(index) * 4.6, 9.45, LAND_Y)
		poles.color = Style.muted(WOOD_DARK, 0.3)
		poles.capsule(base, base + Vector3(0, 1.9, 0), 0.04, 0.03, 8, 2)
		poles.capsule(base + Vector3(0, 1.75, 0) - screen_right() * 0.0 + Vector3(0.18, 0, -0.18), base + Vector3(0, 1.75, 0) - Vector3(0.18, 0, -0.18), 0.02, -1.0, 6, 2)
		tops.append(base + Vector3(0, 1.75, 0))
	poles.color = Style.muted(Color("6a5a4c"), 0.3)
	for index: int in tops.size() - 1:
		var from := tops[index]
		var to := tops[index + 1]
		var previous := from
		for step: int in range(1, 7):
			var along := float(step) / 6.0
			var point := from.lerp(to, along) - Vector3(0, sin(along * PI) * 0.22, 0)
			poles.capsule(previous, point, 0.006, -1.0, 4, 1)
			previous = point
	far.add_child(Kit.bake("EnvPowerPole", poles))

	var houses := SoftMesh.new()
	for index: int in 6:
		var at := uv(-9.5 + float(index) * 3.9 + _random.randf_range(-0.6, 0.6), 12.0 + _random.randf_range(0.0, 1.2), LAND_Y)
		_house(houses, at, _random.randf_range(-0.3, 0.3), 0.35)
	far.add_child(Kit.bake("Houses", houses))
	return far


## A small house: plastered walls, a terracotta roof, a door and a window.
func _house(builder: RefCounted, at: Vector3, yaw: float, mute: float) -> void:
	var size := Vector3(_random.randf_range(1.1, 1.5), _random.randf_range(0.75, 0.9), _random.randf_range(0.9, 1.1))
	builder.transform = Transform3D(Basis(Vector3.UP, yaw + PI * 0.25), at)
	builder.color = Style.muted([PLASTER, Style.MINT.lerp(PLASTER, 0.5), Style.STRAWBERRY.lerp(PLASTER, 0.55)][_random.randi() % 3], mute)
	builder.rounded_slab(size, Vector3(0, size.y * 0.5, 0), 0.04)
	builder.color = Style.muted(ROOF, mute)
	# A gable: each half slopes down toward its own eave. Turning about +X
	# by +angle lowers the +Z edge, so the half on the +Z side takes +angle
	# (a negative sign here made a V-shaped, upside-down roof).
	for side: float in [-1.0, 1.0]:
		builder.transform = Transform3D(Basis(Vector3.UP, yaw + PI * 0.25) * Basis(Vector3.RIGHT, 0.62 * side), at + Basis(Vector3.UP, yaw + PI * 0.25) * Vector3(0, size.y + 0.17, size.z * 0.22 * side))
		builder.rounded_slab(Vector3(size.x + 0.16, 0.06, size.z * 0.66), Vector3.ZERO, 0.025)
	builder.transform = Transform3D(Basis(Vector3.UP, yaw + PI * 0.25), at)
	builder.color = Style.muted(WOOD_DARK, mute)
	builder.rounded_slab(Vector3(0.22, 0.42, 0.03), Vector3(-size.x * 0.22, 0.21, -size.z * 0.5), 0.01)
	builder.color = Style.muted(Style.WATER_SHALLOW, mute)
	builder.rounded_slab(Vector3(0.24, 0.2, 0.03), Vector3(size.x * 0.2, 0.48, -size.z * 0.5), 0.01)
	builder.transform = Transform3D.IDENTITY


## Bu Yati's warung seen from across the water: a booth with a checkered
## canopy (GDD 185.13: the Market distant but readable).
func _warung_shell(at: Vector3, mute: float) -> Node3D:
	var builder := SoftMesh.new()
	var turn := Basis(Vector3.UP, person_yaw(toward_camera()))
	builder.transform = Transform3D(turn, at)
	builder.color = Style.muted(PLASTER, mute)
	builder.rounded_slab(Vector3(1.4, 0.9, 0.9), Vector3(0, 0.45, 0.1), 0.04)
	builder.color = Style.muted(WOOD, mute)
	builder.rounded_slab(Vector3(1.3, 0.42, 0.3), Vector3(0, 0.21, -0.45), 0.03)
	builder.color = Style.muted(WOOD_DARK, mute)
	for x: float in [-0.64, 0.64]:
		builder.capsule(Vector3(x, 0, -0.62), Vector3(x, 1.05, -0.62), 0.03, -1.0, 6, 2)
	var canopy_basis := turn * Basis(Vector3.RIGHT, -0.32)
	builder.transform = Transform3D(canopy_basis, at + turn * Vector3(0, 1.08, -0.35))
	Kit.checker(builder, Vector3(-0.72, 0.0, -0.4), Vector3(1.44, 0, 0), Vector3(0, 0, 0.8), 8, 4, Style.muted(FADED_RED, mute), Style.muted(Style.FLOUR, mute))
	builder.transform = Transform3D.IDENTITY
	var node := Kit.bake("EnvMarketShell", builder)
	return node


## A focus marker whose portrait framing looks somewhere else.
func _focus_pair(marker_name: String, landscape: Vector3, width_landscape: float, portrait: Vector3, width_portrait: float) -> Marker3D:
	var made := Kit.focus_marker(landscape, width_landscape, width_portrait, marker_name)
	made.set_meta(&"focus_portrait", portrait)
	return made


## Pulls far-away ground toward the background colour.
func _mute_far(tint: Color, at: Vector2, centre: Vector2, from: float, to: float) -> Color:
	return Style.muted(tint, Style.SURROUNDING_MUTE * smoothstep(from, to, at.distance_to(centre)) * 1.6)


func _place(parent: Node3D, prop_id: String, node_name: String, position: Vector3, yaw: float = 0.0) -> Node3D:
	var scene := load(PROP_PATH % prop_id) as PackedScene
	if scene == null:
		push_error("environment_builder: missing prop scene %s" % prop_id)
		return null
	var prop: Node3D = scene.instantiate()
	prop.name = node_name
	prop.transform = Transform3D(Basis(Vector3.UP, yaw), position)
	parent.add_child(prop)
	return prop


# --- A patch of lakeside land for the duel sets --------------------------------

## Grass around the action, a strip of water at the top of the picture and a
## few trees and bushes at the sides. `water_v` is where the water starts.
static func shore_v(u: float, water_v: float) -> float:
	return water_v + 0.35 * sin(u * 0.7 + 1.0) + 0.15 * sin(u * 1.9 + 0.3)


func _lakeside(root: Node3D, water_v: float, centre: Vector2 = Vector2.ZERO) -> void:
	var ground := SoftMesh.new()
	ground.color_rule = func(point: Vector3, _base: Color) -> Color:
		var at := to_uv(point)
		var edge := shore_v(at.x, water_v)
		var tint := Style.GRASS.lerp(Style.GRASS_LIGHT, 0.5 + 0.5 * sin(at.x * 0.7 + 0.5) * sin(at.y * 0.55 + 1.0))
		if at.y > edge - 0.45:
			tint = tint.lerp(Style.SAND, smoothstep(edge - 0.45, edge - 0.15, at.y))
		return _mute_far(tint, at, centre, 4.0, 12.0)
	var rows: Array = []
	for row: int in 49:
		var v := -12.0 + float(row) * 0.5
		var line := PackedVector3Array()
		for column: int in 49:
			var u := -12.0 + float(column) * 0.5
			var edge := shore_v(u, water_v)
			var y := 0.0 if v < edge - 0.15 else lerpf(0.0, -0.18, smoothstep(edge - 0.15, edge + 0.3, v))
			line.append(uv(u, v, y))
		rows.append(line)
	ground.grid(rows)
	root.add_child(Kit.bake("Ground", ground))
	var tufts: Array = []
	while tufts.size() < 140:
		var tu := _random.randf_range(-9.0, 9.0)
		var tv := _random.randf_range(-9.0, water_v - 0.4)
		if Vector2(tu, tv).distance_to(centre) < 1.7 or tv > shore_v(tu, water_v) - 0.4:
			continue
		tufts.append([uv(tu, tv), _random.randf_range(0.0, TAU), _random.randf_range(0.8, 1.3)])
	root.add_child(_build_scatter("GrassTufts", _grass_tuft(), tufts))
	var plants := Node3D.new()
	plants.name = "Plants"
	root.add_child(plants)
	for spot: Vector2 in [Vector2(-2.2, -1.4), Vector2(2.4, -1.1), Vector2(-3.1, 0.9), Vector2(3.3, 0.6), Vector2(-0.6, -2.9)]:
		var flowers := _flower_patch()
		flowers.name = "Flowers%d" % plants.get_child_count()
		flowers.position = uv(spot.x + centre.x, spot.y + centre.y)
		plants.add_child(flowers)
	var water := SoftMesh.new()
	water.color_rule = func(point: Vector3, _base: Color) -> Color:
		var at := to_uv(point)
		var tint := Style.WATER_SHALLOW.lerp(Style.WATER_DEEP, smoothstep(water_v, water_v + 3.0, at.y))
		return _mute_far(tint, at, centre, 4.0, 12.0)
	var water_rows: Array = []
	for row: int in 9:
		var v := water_v - 0.3 + float(row) * 1.2
		var line := PackedVector3Array()
		for column: int in 13:
			line.append(uv(-12.0 + float(column) * 2.0, v, -0.05))
		water_rows.append(line)
	water.grid(water_rows)
	root.add_child(Kit.bake("EnvLakeWater", water))
	var waves := Node3D.new()
	waves.name = "WaterLines"
	root.add_child(waves)
	for index: int in 5:
		var line := _water_line(_random.randf_range(0.35, 0.7))
		line.name = "Line%d" % index
		line.position = uv(_random.randf_range(-4.0, 4.0), water_v + _random.randf_range(0.6, 2.4), -0.046)
		line.rotation.y = person_yaw(screen_right()) + PI * 0.5
		waves.add_child(line)
		_motion.append(["../WaterLines/%s" % line.name, "drift", 0.15, _random.randf_range(0.25, 0.45), _random.randf_range(0.0, TAU), 0])
	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	for spec: Array in [[Vector2(-3.6, 1.6), 2.0, 0.8], [Vector2(3.9, 2.0), 1.8, 0.7], [Vector2(-5.4, -2.2), 1.7, 0.65], [Vector2(5.6, -1.4), 1.9, 0.7]]:
		var spot: Vector2 = spec[0]
		trees.add_child(_tree("Tree%d" % trees.get_child_count(), uv(spot.x + centre.x, spot.y + centre.y), spec[1], spec[2], 0.1))
	for spec: Vector2 in [Vector2(-2.6, -2.0), Vector2(2.9, -2.4), Vector2(-4.4, 0.4)]:
		var bush := _bush(0.05)
		bush.name = "Bush%d" % trees.get_child_count()
		bush.position = uv(spec.x + centre.x, spec.y + centre.y)
		trees.add_child(bush)
	for index: int in 4:
		var reeds := _reed_cluster(7)
		reeds.name = "Reeds%d" % index
		var reed_u := -3.0 + float(index) * 2.1 + _random.randf_range(-0.4, 0.4)
		reeds.position = uv(reed_u, shore_v(reed_u, water_v) + 0.05, -0.05)
		trees.add_child(reeds)
		_motion.append(["../Trees/%s" % reeds.name, "sway", 0.05, _random.randf_range(0.8, 1.2), _random.randf_range(0.0, TAU), 0])


# --- Market set (GDD 72, 185.15) ----------------------------------------------
# Bu Yati's warung as a dollhouse room, 3.0 x 2.5 m: terracotta tiles, the
# two far walls full height with a window and checkered curtains, the two
# near walls cut down to 0.16 m. The counter (top at 0.42 m) runs across the
# room; Bu Yati stands behind it, Darto in front.

const MARKET_ROOM := Vector2(3.0, 2.5)
const MARKET_WALL := 2.0


func build_market_set() -> Node3D:
	_begin(3)
	var root := Node3D.new()
	root.name = "EnvMarketSet"
	root.add_child(Kit.lighting(Kit.room_lamps(Vector2.ZERO, MARKET_ROOM, MARKET_WALL)))
	_outdoor_lot(root, Vector2(1.5, 1.25))
	root.add_child(_room("Room", MARKET_ROOM, MARKET_WALL, "terracotta", [[1, 1.0], [0, 0.72]], [], FADED_RED))

	var counter_z := 1.45
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	var behind := person_yaw(toward_camera())
	_place(props, "prop_market_table", "Counter", Vector3(1.5, 0.0, counter_z), PI)
	var top := Style.COUNTER_TOP
	_place(props, "prop_market_scale", "Scale", Vector3(1.05, top, counter_z + 0.02), PI + 0.3)
	_place(props, "prop_market_thermos", "Thermos", Vector3(2.0, top, counter_z + 0.1), 0.4)
	_place(props, "prop_market_jar_set", "Jars", Vector3(1.6, top, counter_z + 0.08), PI)
	_place(props, "prop_market_fan", "Fan", Vector3(2.35, top, counter_z + 0.04), PI + 0.5)
	_place(props, "prop_market_freezer", "Freezer", Vector3(2.62, 0.0, 0.7), PI * 0.5)
	_place(props, "prop_plastic_chair", "ChairA", Vector3(0.45, 0.0, 0.45), behind + 0.5)
	_place(props, "prop_plastic_chair", "ChairB", Vector3(0.95, 0.0, 0.32), behind - 0.2)
	_place(props, "prop_market_price_board", "PriceBoard", Vector3(2.25, 1.1, MARKET_ROOM.y - 0.07), PI)
	_place(props, "prop_hanging_lamp", "HangingLamp", Vector3(1.45, 1.62, 1.95))
	var bracket := SoftMesh.new()
	bracket.color = WOOD_DARK
	bracket.capsule(Vector3(1.45, 1.64, MARKET_ROOM.y - 0.02), Vector3(1.45, 1.64, 1.93), 0.022, -1.0, 8, 2)
	bracket.capsule(Vector3(1.45, 1.64, MARKET_ROOM.y - 0.02), Vector3(1.45, 1.42, MARKET_ROOM.y - 0.02), 0.018, -1.0, 8, 2)
	props.add_child(Kit.bake("LampBracket", bracket))

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.add_child(Kit.marker("BuYatiSpot", Transform3D(Basis(Vector3.UP, person_yaw(Vector3(-0.35, 0, -1).normalized())), Vector3(1.35, 0.0, counter_z + 0.42))))
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(Vector3(0.35, 0, 1).normalized())), Vector3(1.05, 0.0, 0.78))))
	markers.add_child(_focus_pair("CameraFocus", Vector3(1.5, 0.45, 1.25) + screen_right() * 2.25, 9.2, Vector3(1.5, 0.45, 1.25), 6.2))
	markers.add_child(Kit.focus_marker(Vector3(1.25, 0.5, 1.1), 5.6, 5.6, "StoryTwoShot"))
	markers.add_child(Kit.focus_marker(Vector3(1.05, 0.55, 0.78), 5.6, 5.6, "StoryDarto"))
	_finish(root)
	return root


## Ground around a building: grass, a sandy yard, a strip of road and a tree,
## muted with distance.
func _outdoor_lot(root: Node3D, centre: Vector2) -> void:
	var ground := SoftMesh.new()
	ground.color_rule = func(point: Vector3, _base: Color) -> Color:
		var at := Vector2(point.x, point.z)
		var tint := Style.GRASS.lerp(Style.GRASS_LIGHT, 0.5 + 0.5 * sin(at.x * 0.8) * sin(at.y * 0.6 + 1.0))
		var yard := absf(at.x - centre.x) < 2.6 and at.y < centre.y + 1.6 and at.y > centre.y - 2.9
		if yard:
			tint = tint.lerp(Style.SAND, 0.75)
		if at.y < centre.y - 3.3 and at.y > centre.y - 4.5:
			tint = Style.ROAD
		return _mute_far(tint, at, centre, 3.5, 11.0)
	var rows: Array = []
	for row: int in 41:
		var z := centre.y - 10.0 + float(row) * 0.5
		var line := PackedVector3Array()
		for column: int in 41:
			line.append(Vector3(centre.x - 10.0 + float(column) * 0.5, -0.004, z))
		rows.append(line)
	ground.grid(rows)
	root.add_child(Kit.bake("Ground", ground))
	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	for spec: Array in [[Vector3(-1.4, 0, 3.6), 2.0, 0.8], [Vector3(5.2, 0, 1.0), 1.8, 0.7], [Vector3(4.6, 0, -2.4), 1.6, 0.6], [Vector3(-2.6, 0, -1.6), 1.7, 0.65]]:
		trees.add_child(_tree("Tree%d" % trees.get_child_count(), spec[0], spec[1], spec[2], 0.1))
	for spec: Vector3 in [Vector3(-0.9, 0, 0.6), Vector3(3.8, 0, 3.4), Vector3(4.0, 0, -0.6)]:
		var bush := _bush(0.05)
		bush.name = "Bush%d" % trees.get_child_count()
		bush.position = spec
		trees.add_child(bush)


## A dollhouse room from (0, 0, 0) to (size.x, wall, size.y): `floor_style`
## tiles, full-height far walls (z = size.y and x = size.x) and 0.16 m near
## walls (z = 0 and x = 0). `windows` holds [wall, centre] pairs (wall 0 is
## the back wall at z = size.y, 1 the right wall at x = size.x); `doors`
## the same for doors.
func _room(node_name: String, size: Vector2, wall: float, floor_style: String, windows: Array, doors: Array, curtain: Color) -> Node3D:
	var room := Node3D.new()
	room.name = node_name
	var floor_mesh := SoftMesh.new()
	var tiles := Vector2i(int(round(size.x / Style.TILE)), int(round(size.y / Style.TILE)))
	floor_mesh.color = WOOD_DARK
	floor_mesh.rounded_slab(Vector3(size.x, 0.06, size.y), Vector3(size.x * 0.5, -0.03, size.y * 0.5), 0.015)
	for x: int in tiles.x:
		for z: int in tiles.y:
			var corner := Vector3(float(x) * Style.TILE, 0.001, float(z) * Style.TILE)
			match floor_style:
				"terracotta":
					floor_mesh.color = Style.TERRACOTTA.lightened(0.18) if (x + z) % 2 == 0 else Style.TERRACOTTA.lightened(0.3)
				_:
					floor_mesh.color = WOOD.lightened(0.08 if x % 2 == 0 else -0.02)
			var inset := 0.008
			floor_mesh.flat_quad(corner + Vector3(inset, 0, inset), corner + Vector3(Style.TILE - inset, 0, inset), corner + Vector3(Style.TILE - inset, 0, Style.TILE - inset), corner + Vector3(inset, 0, Style.TILE - inset))
	room.add_child(Kit.bake("Floor", floor_mesh))

	var walls := SoftMesh.new()
	var thick := Style.WALL_THICKNESS
	walls.color_rule = func(point: Vector3, base: Color) -> Color:
		return base.darkened(0.06) if point.y < 0.12 else base
	# Near walls, cut low (guide 7).
	walls.color = PLASTER_SHADE
	walls.rounded_slab(Vector3(size.x + thick, Style.LOW_WALL, thick), Vector3(size.x * 0.5, Style.LOW_WALL * 0.5, -thick * 0.5), 0.03)
	walls.rounded_slab(Vector3(thick, Style.LOW_WALL, size.y + thick), Vector3(-thick * 0.5, Style.LOW_WALL * 0.5, size.y * 0.5), 0.03)
	# Far walls, full height, with holes left for windows and doors.
	walls.color = PLASTER
	_wall_with_openings(walls, 0, size, wall, windows, doors)
	_wall_with_openings(walls, 1, size, wall, windows, doors)
	walls.color_rule = Callable()
	walls.color = WOOD_DARK
	walls.rounded_slab(Vector3(size.x + thick * 2.0, 0.07, thick * 1.3), Vector3(size.x * 0.5, wall + 0.035, size.y + thick * 0.5), 0.02)
	walls.rounded_slab(Vector3(thick * 1.3, 0.07, size.y + thick * 2.0), Vector3(size.x + thick * 0.5, wall + 0.035, size.y * 0.5), 0.02)
	room.add_child(Kit.bake("Walls", walls))

	var dressing := SoftMesh.new()
	for window: Array in windows:
		_window(dressing, int(window[0]), float(window[1]), size, wall, curtain)
	for door: Array in doors:
		_door(dressing, int(door[0]), float(door[1]), size)
	room.add_child(Kit.bake("WindowsAndDoors", dressing))
	return room


func _wall_with_openings(builder: RefCounted, wall_index: int, size: Vector2, height: float, windows: Array, doors: Array) -> void:
	var thick := Style.WALL_THICKNESS
	var length := size.x if wall_index == 0 else size.y
	var holes: Array = []
	for window: Array in windows:
		if int(window[0]) == wall_index:
			holes.append([float(window[1]) - Style.WINDOW_WIDTH * 0.5, float(window[1]) + Style.WINDOW_WIDTH * 0.5, height * 0.55 - 0.3, height * 0.55 + 0.3])
	for door: Array in doors:
		if int(door[0]) == wall_index:
			holes.append([float(door[1]) - 0.36, float(door[1]) + 0.36, 0.0, 1.2])
	holes.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var cursor := 0.0
	var pieces: Array = []
	for hole: Array in holes:
		pieces.append([cursor, hole[0], 0.0, height])
		pieces.append([hole[0], hole[1], 0.0, hole[2]])
		pieces.append([hole[0], hole[1], hole[3], height])
		cursor = hole[1]
	pieces.append([cursor, length, 0.0, height])
	for piece: Array in pieces:
		var along: float = float(piece[1]) - float(piece[0])
		var tall: float = float(piece[3]) - float(piece[2])
		if along < 0.01 or tall < 0.01:
			continue
		var middle: float = (float(piece[0]) + float(piece[1])) * 0.5
		var lift: float = (float(piece[2]) + float(piece[3])) * 0.5
		if wall_index == 0:
			builder.rounded_slab(Vector3(along, tall, thick), Vector3(middle, lift, size.y + thick * 0.5), 0.015)
		else:
			builder.rounded_slab(Vector3(thick, tall, along), Vector3(size.x + thick * 0.5, lift, middle), 0.015)


## A window frame with glass and checkered curtains (guide 7).
func _window(builder: RefCounted, wall_index: int, centre: float, size: Vector2, height: float, curtain: Color) -> void:
	var thick := Style.WALL_THICKNESS
	var lift := height * 0.55
	var half := Style.WINDOW_WIDTH * 0.5
	var basis := Basis.IDENTITY if wall_index == 0 else Basis(Vector3.UP, PI * 0.5)
	var origin := Vector3(centre, lift, size.y + thick * 0.5) if wall_index == 0 else Vector3(size.x + thick * 0.5, lift, centre)
	builder.transform = Transform3D(basis, origin)
	builder.color = Style.WATER_SHALLOW.lightened(0.25)
	builder.rounded_slab(Vector3(Style.WINDOW_WIDTH, 0.6, 0.02), Vector3(0, 0, 0.01), 0.005)
	builder.color = WOOD_DARK
	builder.rounded_slab(Vector3(Style.WINDOW_WIDTH + 0.08, 0.05, thick + 0.04), Vector3(0, -0.32, 0), 0.015)
	builder.rounded_slab(Vector3(Style.WINDOW_WIDTH + 0.06, 0.04, thick + 0.02), Vector3(0, 0.32, 0), 0.012)
	builder.rounded_slab(Vector3(0.03, 0.62, 0.03), Vector3(0, 0, -0.01), 0.008)
	# Two checkered curtain panels tied back at the sides (geometry pattern).
	for side: float in [-1.0, 1.0]:
		Kit.checker(builder, Vector3(side * half - (0.0 if side < 0.0 else 0.2), -0.28, -thick * 0.5 - 0.012), Vector3(0.2, 0, 0), Vector3(0, 0.6, 0), 3, 8, curtain, Style.FLOUR)
	builder.transform = Transform3D.IDENTITY


func _door(builder: RefCounted, wall_index: int, centre: float, size: Vector2) -> void:
	var thick := Style.WALL_THICKNESS
	var basis := Basis.IDENTITY if wall_index == 0 else Basis(Vector3.UP, PI * 0.5)
	var origin := Vector3(centre, 0.0, size.y + thick * 0.5) if wall_index == 0 else Vector3(size.x + thick * 0.5, 0.0, centre)
	builder.transform = Transform3D(basis, origin)
	builder.color = WOOD
	builder.rounded_slab(Vector3(0.68, 1.16, 0.04), Vector3(0, 0.58, 0.01), 0.02)
	builder.color = WOOD_DARK
	builder.rounded_slab(Vector3(0.78, 0.06, thick + 0.04), Vector3(0, 1.22, 0), 0.015)
	builder.color = Style.GOLD
	builder.sphere(Vector3(0.24, 0.58, -0.02), Vector3.ONE * 0.022, 8, 4)
	builder.transform = Transform3D.IDENTITY


# --- Boxing set (GDD 185.16) ----------------------------------------------------
# A small roped square on the grass by the water. Darto stands in the near half
# with his back to the camera, the fish on its low stool in the far half,
# facing him; a string of warm bulbs hangs behind the far ropes.

## Darto stands left and nearer, the fish right and further away, so neither
## hides the other and both read from the diorama camera.
const BOXING_DARTO_UV := Vector2(-0.55, -0.5)
const BOXING_FISH_UV := Vector2(0.55, 0.5)


func build_boxing_set() -> Node3D:
	_begin(4)
	var root := Node3D.new()
	root.name = "EnvBoxingSet"
	root.add_child(Kit.lighting())
	_lakeside(root, 2.6)
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_boxing_mat", "Mat", Vector3(0, 0.0, 0))
	_place(props, "prop_boxing_ropes", "Ropes", Vector3(0, 0.0, 0))
	var fish_floor := uv(BOXING_FISH_UV.x, BOXING_FISH_UV.y, 0.03)
	var darto_spot := uv(BOXING_DARTO_UV.x, BOXING_DARTO_UV.y, 0.03)
	var to_darto := (darto_spot - fish_floor).normalized()
	_place(props, "prop_boxing_corner_stool", "FishStool", fish_floor, person_yaw(to_darto) + PI)
	_place(props, "prop_boxing_corner_stool", "DartoStool", uv(-1.55, -1.0), 0.6)
	_place(props, "prop_bucket_blue", "Bucket", uv(1.6, -0.9), 0.0)
	var lights := _place(props, "prop_dance_string_light", "Bulbs", uv(0.0, 1.95), person_yaw(toward_camera()) + PI)
	lights.scale = Vector3(0.9, 0.75, 0.9)

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	var fish_spot := fish_floor + Vector3(0.0, 0.12, 0.0)
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw(to_darto)), fish_spot)))
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(-to_darto)), darto_spot)))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.0, 0.45), 6.2, 5.6))
	_finish(root)
	return root


# --- Arm wrestling set (GDD 185.17) ---------------------------------------------
# One sturdy table on the grass. Darto stands on its left, the fish on its
# right, both side-on to the camera, so the locked hands sit in the middle of
# the screen and lean left or right with the match.

const ARM_DARTO := 0.36
const ARM_FISH := 0.3


func build_arm_set() -> Node3D:
	_begin(5)
	var root := Node3D.new()
	root.name = "EnvArmSet"
	root.add_child(Kit.lighting())
	_lakeside(root, 2.4)
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_arm_table", "Table", Vector3.ZERO)
	var top := 0.28
	_place(props, "prop_arm_elbow_pad", "PadDarto", uv(-0.1, 0.0, top))
	_place(props, "prop_arm_elbow_pad", "PadFish", uv(0.08, 0.0, top))
	_place(props, "prop_bucket_blue", "Bucket", uv(1.5, -0.7), 0.0)
	_place(props, "prop_boxing_corner_stool", "Stool", uv(-1.5, 0.6), 0.4)

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(screen_right())), uv(-ARM_DARTO, 0.0))))
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw(-screen_right())), uv(ARM_FISH, 0.0))))
	markers.add_child(Kit.marker("GripPoint", Transform3D(Basis.IDENTITY, uv(-0.03, 0.0, top + 0.2))))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.0, 0.4), 5.6, 5.6))
	_finish(root)
	return root


# --- Dance set (GDD 185.18) -------------------------------------------------------
# A low stage facing the camera, string lights behind it. Darto and the fish
# dance side by side, both facing the audience.

func build_dance_set() -> Node3D:
	_begin(6)
	var root := Node3D.new()
	root.name = "EnvDanceSet"
	root.add_child(Kit.lighting())
	_lakeside(root, 2.8)
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	var facing := person_yaw(toward_camera())
	_place(props, "prop_dance_platform", "Platform", Vector3.ZERO)
	var back := _place(props, "prop_dance_string_light", "StringLight", Vector3(0.0, 0.0, 1.0))
	back.scale = Vector3(0.78, 1.0, 1.0)
	var side := _place(props, "prop_dance_string_light", "StringLightSide", Vector3(1.0, 0.0, 0.0), PI * 0.5)
	side.scale = Vector3(0.78, 1.0, 1.0)
	_place(props, "prop_plastic_chair", "ChairA", uv(-1.9, -1.2), facing + 0.3)
	_place(props, "prop_plastic_chair", "ChairB", uv(2.0, -1.0), facing - 0.4)
	var stage_top := 0.12
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, facing), uv(-0.5, 0.05, stage_top))))
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw((toward_camera() - screen_right()).normalized())), uv(0.5, 0.05, stage_top))))
	markers.add_child(_focus_pair("CameraFocus", uv(1.45, 0.25, 0.45), 6.2, uv(0.0, 0.3, 0.5), 5.6))
	_finish(root)
	return root


# --- Suwit set (GDD 185.19) -------------------------------------------------------
# A small wooden deck with a round table under one warm lamp; Darto on the
# left, the fish on the right.

func build_suwit_set() -> Node3D:
	_begin(7)
	var root := Node3D.new()
	root.name = "EnvSuwitSet"
	root.add_child(Kit.lighting([[uv(0.0, 0.25, 1.25), 3.0]]))
	_lakeside(root, 2.3)
	var deck := SoftMesh.new()
	var deck_centre := uv(0.0, 0.15)
	for board: int in 6:
		var x := -0.75 + float(board) * 0.3
		deck.color = WOOD.lightened(0.06 if board % 2 == 0 else -0.03)
		deck.rounded_slab(Vector3(0.29, 0.08, 1.8), deck_centre + Vector3(x, 0.04, 0.0), 0.02)
	deck.color = WOOD_DARK
	deck.capsule(uv(0.62, 0.62, 0.0), uv(0.62, 0.62, 1.45), 0.035, -1.0, 8, 2)
	deck.capsule(uv(0.62, 0.62, 1.42), uv(0.0, 0.2, 1.42), 0.025, -1.0, 6, 2)
	root.add_child(Kit.bake("Deck", deck))
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_suwit_table", "Table", uv(0.0, 0.15, 0.08))
	_place(props, "prop_hanging_lamp", "Lamp", uv(0.0, 0.2, 1.4))
	_place(props, "prop_drink_glass", "Glass", uv(-0.12, 0.25, 0.08 + 0.307))
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(screen_right())), uv(-0.44, 0.15, 0.08))))
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw(-screen_right())), uv(0.44, 0.15, 0.08))))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.2, 0.42), 5.6, 5.6))
	_finish(root)
	return root


# --- Home set (GDD 183.3, 185.14) ---------------------------------------------------
# A small modest room: a woven floor mat, a low table with the rice cooker and
# the old fan, shoes by the door, fishing gear in the corner, and enough empty
# floor that it never feels cluttered. Afternoon light through one window.

const HOME_ROOM := Vector2(3.0, 2.5)
const HOME_WALL := 1.8


func build_home_set() -> Node3D:
	_begin(8)
	var root := Node3D.new()
	root.name = "EnvHomeSet"
	root.add_child(Kit.lighting(Kit.room_lamps(Vector2.ZERO, HOME_ROOM, HOME_WALL)))
	_outdoor_lot(root, Vector2(1.5, 1.25))
	root.add_child(_room("Room", HOME_ROOM, HOME_WALL, "planks", [[0, 0.9]], [[1, 1.7]], Style.PERIWINKLE))

	var furniture := SoftMesh.new()
	# Woven floor mat (a checker of two tones).
	furniture.color = Style.CUSTARD.lerp(CREAM, 0.4)
	furniture.rounded_slab(Vector3(1.3, 0.012, 1.0), Vector3(1.0, 0.006, 1.35), 0.005)
	Kit.checker(furniture, Vector3(0.4, 0.0125, 0.9), Vector3(1.2, 0, 0), Vector3(0, 0, 0.9), 8, 6, Style.CUSTARD.lerp(CREAM, 0.2), Style.CUSTARD.lerp(CREAM, 0.6))
	# Low table.
	furniture.color = WOOD
	furniture.rounded_slab(Vector3(0.62, 0.035, 0.4), Vector3(1.0, 0.2, 1.65), 0.012)
	furniture.color = WOOD_DARK
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		furniture.rounded_slab(Vector3(0.04, 0.18, 0.04), Vector3(1.0 + corner.x * 0.26, 0.09, 1.65 + corner.y * 0.15), 0.01)
	# Shoes by the door.
	for index: int in 2:
		furniture.color = [Color("6b4a3a"), Color("c2675a")][index]
		furniture.sphere(Vector3(2.65, 0.035, 1.25 + 0.12 * float(index)), Vector3(0.06, 0.035, 0.04), 8, 4)
	root.add_child(Kit.bake("Furniture", furniture))
	root.add_child(Kit.furniture_shadow(Vector2(0.62, 0.4), Vector2(1.0, 1.65)))

	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_rice_cooker", "RiceCooker", Vector3(0.85, 0.218, 1.7), 0.3)
	_place(props, "prop_market_fan", "Fan", Vector3(1.15, 0.218, 1.72), PI + 0.4)
	_place(props, "prop_bucket_blue", "Bucket", Vector3(2.6, 0.0, 2.15), 0.0)
	_place(props, "prop_helmet", "Helmet", Vector3(2.2, 0.0, 2.25), 0.4)
	_place(props, "prop_plastic_chair", "Chair", Vector3(0.5, 0.0, 0.8), person_yaw(Vector3(1, 0, 1)) + 0.3)
	var rod := _place(props, "prop_fishing_rod_basic", "Rod", Vector3(2.82, 0.6, 2.32))
	rod.transform = Transform3D(Basis(Vector3.UP, PI * 1.25) * Basis(Vector3.RIGHT, deg_to_rad(62.0)), Vector3(2.5, 0.02, 2.0))

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(Vector3(1.0, 0, 0.4).normalized())), Vector3(1.1, 0.0, 0.85))))
	markers.add_child(Kit.marker("RiniSpot", Transform3D(Basis(Vector3.UP, person_yaw(Vector3(-1.0, 0, -0.6).normalized())), Vector3(2.35, 0.0, 1.45))))
	markers.add_child(Kit.focus_marker(Vector3(1.5, 0.5, 1.25), 5.6, 5.6))
	markers.add_child(Kit.focus_marker(Vector3(1.5, 0.5, 1.25), 6.2, 5.6, "StoryWide"))
	markers.add_child(Kit.focus_marker(Vector3(1.1, 0.5, 0.85), 5.6, 5.6, "StoryDarto"))
	markers.add_child(Kit.focus_marker(Vector3(2.35, 0.5, 1.45), 5.6, 5.6, "StoryRini"))
	markers.add_child(Kit.focus_marker(Vector3(2.5, 0.55, 1.7), 5.6, 5.6, "StoryDoor"))
	_finish(root)
	return root


# --- The four new fishing spots (revision 6.7) ---------------------------------
# Every spot set carries the lake set's working markers (DartoSpot, FloatSpot,
# BucketSpot, CameraFocus, ResultFocus, WheelFocus) at the same screen
# positions, so fishing and the result play out the same way everywhere: the
# water starts just past Darto, the float lands at the same place, and the
# catch comes down on the bank (or deck) to his right.

const SPOT_FLOAT_UV := Vector2(0.35, 2.55)
const PIER_DECK_Y := 0.3
const MUD := Color("a8a294")
const MUD_WET := Color("857e70")
const BRACKISH_SHALLOW := Color("b7d2bf")
const BRACKISH := Color("a0c4b0")
const BRACKISH_DEEP := Color("88b2a2")
const SEA_SHALLOW := Color("a6dbe0")
const SEA := Color("86c4d8")
const SEA_DEEP := Color("6aaccb")
const CONCRETE := Color("d9d2c4")
const CONCRETE_SHADE := Color("bdb5a6")
const BAMBOO := Color("c9c27a")
const BAMBOO_DEEP := Color("9fa45c")
const MANGROVE_BARK := Color("8a6a4f")
const ROOF_BLUE := Color("7fa6c9")
const NET_BLUE := Color("6c93b8")
const FLAG_RED := Color("d9483b")
const BOAT_COLOURS: Array[Color] = [Color("e07a5f"), Color("7fb3d5"), Color("f2cc6b"), Color("8fc79a")]


static func spot_height(distance: float) -> float:
	if distance < 0.0:
		return LAND_Y - 0.06 + maxf(distance, -1.2) * 0.3
	return lerpf(LAND_Y - 0.06, LAND_Y, smoothstep(0.0, 0.28, distance))


## Ground and water for a spot. `land` gives the signed distance in metres
## from the water's edge at (u, v), positive on land; `tint` colours the land
## at (u, v, distance); `water` is [shallow, mid, deep].
func _spot_ground(root: Node3D, land: Callable, tint: Callable, water: Array, centre: Vector2 = Vector2(0.0, 1.5)) -> void:
	var ground := SoftMesh.new()
	ground.color_rule = func(point: Vector3, _base: Color) -> Color:
		var at := to_uv(point)
		var distance: float = land.call(at.x, at.y)
		return _mute_far(tint.call(at.x, at.y, distance), at, centre, 7.0, 16.0)
	var rows: Array = []
	for row: int in 61:
		var v := -12.0 + float(row) * 0.5
		var line := PackedVector3Array()
		for column: int in 61:
			var u := -15.0 + float(column) * 0.5
			line.append(uv(u, v, spot_height(land.call(u, v))))
		rows.append(line)
	ground.grid(rows)
	root.add_child(Kit.bake("Ground", ground))

	var sheet := SoftMesh.new()
	sheet.color_rule = func(point: Vector3, _base: Color) -> Color:
		var at := to_uv(point)
		var depth := -float(land.call(at.x, at.y))
		var colour: Color = (water[0] as Color).lerp(water[1], smoothstep(0.0, 0.6, depth)).lerp(water[2], smoothstep(0.8, 2.4, depth))
		return _mute_far(colour, at, centre, 7.0, 16.0)
	var water_rows: Array = []
	for row: int in 33:
		var v := -12.0 + float(row) * 1.0
		var line := PackedVector3Array()
		for column: int in 31:
			line.append(uv(-15.0 + float(column) * 1.0, v, WATER_Y))
		water_rows.append(line)
	sheet.grid(water_rows)
	root.add_child(Kit.bake("Water", sheet))


## Pale streaks on the water. `speed` scales how fast they slide (rivers run).
func _spot_water_lines(root: Node3D, land: Callable, count: int, area: Rect2, amplitude: float, speed: float) -> void:
	var waves := Node3D.new()
	waves.name = "WaterLines"
	root.add_child(waves)
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 400:
		attempts += 1
		var at := Vector2(_random.randf_range(area.position.x, area.end.x), _random.randf_range(area.position.y, area.end.y))
		if float(land.call(at.x, at.y)) > -0.4:
			continue
		var line := _water_line(_random.randf_range(0.35, 0.8))
		line.name = "Line%d" % placed
		line.position = uv(at.x, at.y, WATER_Y + 0.004)
		line.rotation.y = person_yaw(screen_right()) + PI * 0.5
		waves.add_child(line)
		_motion.append(["../WaterLines/%s" % line.name, "drift", amplitude, speed * _random.randf_range(0.8, 1.2), _random.randf_range(0.0, TAU), 0])
		placed += 1


## The working markers every fishing spot shares with the lake set.
func _spot_markers(root: Node3D, darto_y: float) -> Node3D:
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(into_picture())), uv(0.0, 0.0, darto_y))))
	markers.add_child(Kit.marker("FloatSpot", Transform3D(Basis.IDENTITY, uv(SPOT_FLOAT_UV.x, SPOT_FLOAT_UV.y, WATER_Y))))
	markers.add_child(Kit.marker("BucketSpot", Transform3D(Basis(Vector3.UP, 0.5), uv(0.72, -0.18, darto_y))))
	markers.add_child(Kit.focus_marker(uv(0.25, 1.35, 0.3 + darto_y * 0.5), 8.6, 6.8))
	markers.add_child(Kit.focus_marker(uv(0.35, 0.1, 0.35 + darto_y), 5.6, 5.6, "ResultFocus"))
	markers.add_child(_focus_pair("WheelFocus", uv(2.4, 1.1, 0.4 + darto_y), 6.8, uv(0.4, -0.6, 0.4 + darto_y), 6.2))
	markers.add_child(Kit.focus_marker(uv(0.0, 2.2, 0.4), 11.0, 8.0, "StoryWide"))
	return markers


func _spot_grass(u: float, v: float, distance: float) -> Color:
	var tint := Style.GRASS.lerp(Style.GRASS_LIGHT, 0.5 + 0.5 * sin(u * 0.6 + 1.0) * sin(v * 0.45))
	if distance < 0.42:
		tint = tint.lerp(Style.SAND, smoothstep(0.42, 0.18, distance))
	return Style.SOIL_DEEP if distance < 0.0 else tint


# --- Kenanga River --------------------------------------------------------------
# A clear river running across the picture over pebbles and boulders, with a
# bamboo footbridge on the right and bamboo clumps on both banks. The far bank
# is lower and greener; the water lines slide quickly downstream.

static func river_land(u: float, v: float) -> float:
	var near := 0.75 + 0.18 * sin(u * 0.6 + 0.3)
	var far := 5.4 + 0.3 * sin(u * 0.45 + 1.2)
	return maxf(near - v, v - far)


func build_river_set() -> Node3D:
	_begin(11)
	var root := Node3D.new()
	root.name = "EnvRiverSet"
	root.add_child(Kit.lighting())
	var land := func(u: float, v: float) -> float: return river_land(u, v)
	_spot_ground(root, land, _river_tint, [Style.WATER_SHALLOW, Style.WATER, Style.WATER_DEEP])
	_spot_water_lines(root, land, 14, Rect2(-8.0, 1.2, 16.0, 3.8), 0.45, 0.9)

	var stones := SoftMesh.new()
	for spec: Array in [[Vector2(-2.6, 1.6), 0.24], [Vector2(-1.9, 3.9), 0.3], [Vector2(1.9, 4.4), 0.26], [Vector2(-4.6, 2.7), 0.34],
			[Vector2(5.4, 2.2), 0.22], [Vector2(2.6, 1.3), 0.16], [Vector2(-0.8, 5.1), 0.2], [Vector2(1.4, 0.75), 0.14], [Vector2(-1.6, 0.6), 0.18]]:
		var spot: Vector2 = spec[0]
		# Boulders stand well out of the water, grey against the stream.
		stones.color = Style.STONE_DEEP.lerp(Color("9a958c"), _random.randf())
		var size: float = spec[1]
		stones.sphere(uv(spot.x, spot.y, WATER_Y + size * 0.1), Vector3(size, size * 0.62, size * 0.85), 10, 5, 0.08, _random.randi())
	root.add_child(Kit.bake("Boulders", stones))

	var plants := Node3D.new()
	plants.name = "Trees"
	root.add_child(plants)
	for spec: Array in [[Vector2(-3.2, -0.6), 9], [Vector2(3.4, -1.1), 7], [Vector2(-6.4, 0.2), 8], [Vector2(-2.0, 6.6), 9], [Vector2(2.8, 6.9), 8], [Vector2(6.8, 6.2), 7]]:
		var clump := _bamboo_clump(spec[1])
		clump.name = "Bamboo%d" % plants.get_child_count()
		var spot: Vector2 = spec[0]
		clump.position = uv(spot.x, spot.y, spot_height(river_land(spot.x, spot.y)))
		plants.add_child(clump)
		_motion.append(["../Trees/%s" % clump.name, "sway", 0.025, _random.randf_range(0.5, 0.8), _random.randf_range(0.0, TAU), 0])
	for index: int in 7:
		var u := -9.0 + float(index) * 3.0 + _random.randf_range(-0.6, 0.6)
		var v := 8.2 + _random.randf_range(0.0, 1.6)
		plants.add_child(_tree("FarTree%d" % index, uv(u, v, LAND_Y), _random.randf_range(1.5, 2.0), _random.randf_range(0.55, 0.75), 0.25))
	for spot: Vector2 in [Vector2(-5.2, -1.8), Vector2(5.6, -0.6), Vector2(-1.4, -3.0)]:
		var bush := _bush(0.05)
		bush.name = "Bush%d" % plants.get_child_count()
		bush.position = uv(spot.x, spot.y, LAND_Y)
		plants.add_child(bush)
	for index: int in 4:
		var reeds := _reed_cluster(6)
		reeds.name = "Reeds%d" % index
		var reed_u := -5.5 + float(index) * 3.2
		reeds.position = uv(reed_u, 0.75 + 0.18 * sin(reed_u * 0.6 + 0.3) + 0.1, WATER_Y - 0.02)
		plants.add_child(reeds)
		_motion.append(["../Trees/%s" % reeds.name, "sway", 0.05, _random.randf_range(0.8, 1.2), _random.randf_range(0.0, TAU), 0])

	root.add_child(_bamboo_bridge(4.3, 0.2, 6.0))
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_motorcycle_darto", "Motorcycle", uv(1.6, -1.65, LAND_Y), person_yaw(screen_right()) - PI * 0.5 - 0.35)
	_spot_markers(root, LAND_Y)
	_finish(root)
	return root


func _river_tint(u: float, v: float, distance: float) -> Color:
	var tint := _spot_grass(u, v, distance)
	if distance >= 0.0 and distance < 0.5:
		# A pebble beach along both banks.
		var pebble := Style.STONE.lerp(Style.SAND, 0.5 + 0.5 * sin(u * 7.0) * sin(v * 6.0))
		tint = tint.lerp(pebble, smoothstep(0.5, 0.15, distance))
	return tint


## A clump of bamboo: tall jointed canes leaning out, with leafy tips.
func _bamboo_clump(count: int) -> Node3D:
	var builder := SoftMesh.new()
	for index: int in count:
		var angle := TAU * float(index) / float(count) + _random.randf_range(-0.3, 0.3)
		var base := Vector3(cos(angle), 0.0, sin(angle)) * _random.randf_range(0.04, 0.16)
		var height := _random.randf_range(1.3, 2.1)
		var lean := Vector3(cos(angle), 0.0, sin(angle)) * height * 0.28
		var top := base + lean + Vector3(0.0, height, 0.0)
		builder.color = BAMBOO.lerp(BAMBOO_DEEP, _random.randf())
		builder.capsule(base, top, 0.028, 0.018, 6, 2)
		builder.color = BAMBOO_DEEP.darkened(0.1)
		for joint: int in range(1, 5):
			var at := base.lerp(top, float(joint) * 0.2)
			builder.sphere(at, Vector3(0.032, 0.012, 0.032), 6, 2)
		builder.color = Style.LEAF.lerp(Style.LEAF_LIGHT, _random.randf())
		builder.sphere(top, Vector3(0.22, 0.12, 0.22) * _random.randf_range(0.8, 1.2), 8, 4, 0.04, _random.randi())
	var node := Node3D.new()
	node.add_child(Kit.bake("Canes", builder))
	node.add_child(Kit.furniture_shadow(Vector2(0.6, 0.6)))
	return node


## A bamboo footbridge across the river at `u`, from `v_from` to `v_to`.
func _bamboo_bridge(u: float, v_from: float, v_to: float) -> Node3D:
	var builder := SoftMesh.new()
	var deck_y := 0.36
	var steps := int((v_to - v_from) / 0.18)
	for step: int in steps:
		var v := v_from + float(step) * 0.18
		builder.color = BAMBOO.lerp(Style.PINE, 0.3 + 0.2 * float(step % 2))
		builder.capsule(uv(u - 0.36, v, deck_y), uv(u + 0.36, v, deck_y), 0.04, -1.0, 6, 2)
	builder.color = BAMBOO_DEEP
	for side: float in [-0.4, 0.4]:
		builder.capsule(uv(u + side, v_from, deck_y + 0.36), uv(u + side, v_to, deck_y + 0.36), 0.022, -1.0, 6, 2)
		var post_v := v_from
		while post_v <= v_to + 0.01:
			builder.color = BAMBOO_DEEP.darkened(0.08)
			builder.capsule(uv(u + side, post_v, -0.4), uv(u + side, post_v, deck_y + 0.4), 0.03, -1.0, 6, 2)
			post_v += 1.2
	return Kit.bake("Bridge", builder)


# --- Melati Reservoir -------------------------------------------------------------
# Wide still water held back by a concrete dam on the far side. Darto stands
# on the concrete edge of the bank; the cooperative office sits behind him on
# the left, floating fish-net cages bob out on the water, and Nisa's school is
# on the far right bank.

static func reservoir_land(u: float, v: float) -> float:
	var near := 0.7 + 0.15 * sin(u * 0.5)
	var right := 7.5 + 0.5 * sin(v * 0.6)
	return maxf(maxf(near - v, v - 10.6), u - right)


func build_reservoir_set() -> Node3D:
	_begin(12)
	var root := Node3D.new()
	root.name = "EnvReservoirSet"
	root.add_child(Kit.lighting())
	var land := func(u: float, v: float) -> float: return reservoir_land(u, v)
	_spot_ground(root, land, _reservoir_tint, [Style.WATER_SHALLOW, Style.WATER.lerp(Style.WATER_DEEP, 0.3), Style.WATER_DEEP.darkened(0.05)])
	_spot_water_lines(root, land, 10, Rect2(-8.0, 1.5, 14.0, 7.0), 0.12, 0.3)
	# The concrete edge of the bank, in slabs.
	var edge := SoftMesh.new()
	var along := Basis(screen_right(), Vector3.UP, toward_camera())
	var slab_u := -11.0
	var slab := 0
	while slab_u < 6.6:
		var shore := 0.7 + 0.15 * sin(slab_u * 0.5)
		edge.color = CONCRETE if slab % 2 == 0 else CONCRETE_SHADE
		edge.transform = Transform3D(along, uv(slab_u, shore - 0.16, LAND_Y - 0.01))
		edge.rounded_slab(Vector3(0.78, 0.1, 0.34), Vector3.ZERO, 0.02)
		slab_u += 0.8
		slab += 1
	edge.transform = Transform3D.IDENTITY
	root.add_child(Kit.bake("ConcreteEdge", edge))

	# The dam: a long concrete wall with a spillway and its gate towers.
	var dam := SoftMesh.new()
	dam.color = Style.muted(CONCRETE, 0.25)
	for index: int in 10:
		var u0 := -15.0 + float(index) * 3.0
		dam.transform = Transform3D(Basis(screen_right(), Vector3.UP, toward_camera()), uv(u0 + 1.5, 11.0, 0.3))
		dam.rounded_slab(Vector3(3.0, 0.6, 0.8), Vector3.ZERO, 0.03)
	dam.color = Style.muted(CONCRETE_SHADE, 0.25)
	for tower_u: float in [-1.6, 0.0, 1.6]:
		dam.transform = Transform3D(Basis(screen_right(), Vector3.UP, toward_camera()), uv(tower_u, 11.0, 0.75))
		dam.rounded_slab(Vector3(0.5, 0.9, 0.9), Vector3.ZERO, 0.04)
	dam.transform = Transform3D.IDENTITY
	dam.color = Style.muted(Color("6b6f73"), 0.25)
	dam.capsule(uv(-15.0, 10.65, 0.66), uv(15.0, 10.65, 0.66), 0.015, -1.0, 4, 1)
	root.add_child(Kit.bake("Dam", dam))
	var hills := SoftMesh.new()
	for index: int in 7:
		hills.color = Style.muted(Style.LEAF_DEEP.lerp(Style.LEAF, _random.randf()), 0.45)
		hills.sphere(uv(-12.0 + float(index) * 4.2, 14.0 + _random.randf_range(0.0, 1.5), 0.0), Vector3(3.0, 1.4, 2.2) * _random.randf_range(0.8, 1.2), 14, 6)
	root.add_child(Kit.bake("Hills", hills))

	# Floating net cages (keramba): square frames on blue drums.
	var cages := Node3D.new()
	cages.name = "Cages"
	root.add_child(cages)
	for index: int in 3:
		var cage := _net_cage()
		cage.name = "Cage%d" % index
		cage.position = uv(2.2 + float(index) * 1.25, 5.6 + 0.2 * float(index % 2), WATER_Y)
		cage.rotation.y = person_yaw(screen_right()) + PI * 0.5
		cages.add_child(cage)
		_motion.append(["../Cages/%s" % cage.name, "bob", 0.012, 0.35, float(index), 1])

	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	trees.add_child(_tree("ShadeTree", uv(-3.6, -1.2, LAND_Y), 2.1, 0.8, 0.0))
	trees.add_child(_tree("SchoolTree", uv(9.6, 2.4, LAND_Y), 1.9, 0.7, 0.2))
	for spot: Vector2 in [Vector2(5.0, -1.8), Vector2(-6.6, 0.3)]:
		var bush := _bush(0.05)
		bush.name = "Bush%d" % trees.get_child_count()
		bush.position = uv(spot.x, spot.y, LAND_Y)
		trees.add_child(bush)

	# The cooperative office behind Darto, and the school across the water.
	var buildings := SoftMesh.new()
	_house(buildings, uv(-5.2, -2.4, LAND_Y), 0.1, 0.0)
	_house(buildings, uv(9.4, 4.4, LAND_Y), -0.2, 0.25)
	_house(buildings, uv(10.6, 6.2, LAND_Y), -0.1, 0.3)
	# Flag poles in front of both.
	for spot: Vector2 in [Vector2(-3.9, -1.6), Vector2(8.6, 3.6)]:
		buildings.color = Style.FLOUR.darkened(0.1)
		buildings.capsule(uv(spot.x, spot.y, LAND_Y), uv(spot.x, spot.y, LAND_Y + 1.5), 0.018, -1.0, 6, 2)
		buildings.color = FLAG_RED
		buildings.transform = Transform3D(Basis(screen_right(), Vector3.UP, toward_camera()), uv(spot.x + 0.17, spot.y, LAND_Y + 1.42))
		buildings.rounded_slab(Vector3(0.3, 0.1, 0.01), Vector3.ZERO, 0.004)
		buildings.color = Style.FLOUR
		buildings.rounded_slab(Vector3(0.3, 0.1, 0.01), Vector3(0.0, -0.1, 0.0), 0.004)
		buildings.transform = Transform3D.IDENTITY
	root.add_child(Kit.bake("Buildings", buildings))

	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_motorcycle_darto", "Motorcycle", uv(1.6, -1.65, LAND_Y), person_yaw(screen_right()) - PI * 0.5 - 0.35)
	_place(props, "prop_plastic_chair", "Chair", uv(-1.4, -1.1, LAND_Y), person_yaw(into_picture()) + 0.4)
	_spot_markers(root, LAND_Y)
	_finish(root)
	return root


func _reservoir_tint(u: float, v: float, distance: float) -> Color:
	var tint := _spot_grass(u, v, distance)
	if distance >= 0.0 and distance < 0.55 and u < 7.0:
		# The concrete edge, in slabs.
		var slab := CONCRETE if posmod(int(floor(u * 1.6)), 2) == 0 else CONCRETE_SHADE
		tint = tint.lerp(slab, smoothstep(0.55, 0.3, distance))
	return tint


## A floating net cage: a square bamboo frame on four blue drums.
func _net_cage() -> Node3D:
	var builder := SoftMesh.new()
	var half := 0.5
	builder.color = NET_BLUE
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		builder.capsule(Vector3(corner.x * half, 0.02, corner.y * half - 0.08), Vector3(corner.x * half, 0.02, corner.y * half + 0.08), 0.07, -1.0, 8, 2)
	builder.color = BAMBOO.lerp(Style.PINE, 0.4)
	for index: int in 4:
		var a := Vector2(-1, -1).rotated(PI * 0.5 * float(index)) * half
		var b := Vector2(-1, -1).rotated(PI * 0.5 * float(index + 1)) * half
		builder.capsule(Vector3(a.x, 0.09, a.y), Vector3(b.x, 0.09, b.y), 0.025, -1.0, 6, 2)
	builder.color = Style.WATER_DEEP.darkened(0.2)
	builder.rounded_slab(Vector3(0.86, 0.01, 0.86), Vector3(0.0, 0.004, 0.0), 0.004)
	return Kit.bake("Cage", builder)


# --- Anggrek Estuary --------------------------------------------------------------
# Grey-brown mud flats where the river meets the sea, brackish green water,
# mangroves on stilted roots along both banks, a little canoe pulled up on
# the mud, and stilt houses on the far side.

static func estuary_land(u: float, v: float) -> float:
	var near := 0.8 + 0.25 * sin(u * 0.7)
	var far := 6.5 + 0.4 * sin(u * 0.3)
	return maxf(near - v, v - far)


func build_estuary_set() -> Node3D:
	_begin(13)
	var root := Node3D.new()
	root.name = "EnvEstuarySet"
	root.add_child(Kit.lighting())
	var land := func(u: float, v: float) -> float: return estuary_land(u, v)
	_spot_ground(root, land, _estuary_tint, [BRACKISH_SHALLOW, BRACKISH, BRACKISH_DEEP])
	_spot_water_lines(root, land, 10, Rect2(-8.0, 1.4, 16.0, 4.6), 0.2, 0.45)

	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	for spec: Array in [[Vector2(-2.9, 0.4), 1.0], [Vector2(-4.4, 1.1), 1.2], [Vector2(3.1, 0.7), 1.0], [Vector2(5.3, 1.0), 1.15],
			[Vector2(-6.6, 0.6), 1.1], [Vector2(-3.2, 7.0), 1.2], [Vector2(0.4, 7.2), 1.0], [Vector2(3.4, 6.9), 1.15], [Vector2(6.6, 6.6), 1.0]]:
		var spot: Vector2 = spec[0]
		var mangrove := _mangrove(spec[1], 0.0 if spot.y < 3.0 else 0.2)
		mangrove.name = "Mangrove%d" % trees.get_child_count()
		mangrove.position = uv(spot.x, spot.y, spot_height(estuary_land(spot.x, spot.y)))
		trees.add_child(mangrove)
		_motion.append(["../Trees/%s/Crown" % mangrove.name, "sway", 0.02, _random.randf_range(0.6, 0.9), _random.randf_range(0.0, TAU), 0])

	# Stilt houses on the far bank.
	var village := SoftMesh.new()
	for index: int in 4:
		var at := uv(-6.0 + float(index) * 3.6, 8.6 + _random.randf_range(0.0, 0.8), LAND_Y)
		village.color = Style.muted(WOOD_DARK, 0.3)
		for corner: Vector2 in [Vector2(-0.5, -0.4), Vector2(0.5, -0.4), Vector2(-0.5, 0.4), Vector2(0.5, 0.4)]:
			village.capsule(at + Vector3(corner.x, 0.0, corner.y), at + Vector3(corner.x, 0.55, corner.y), 0.035, -1.0, 6, 2)
		_house(village, at + Vector3(0.0, 0.5, 0.0), _random.randf_range(-0.3, 0.3), 0.3)
	root.add_child(Kit.bake("Village", village))

	# Channel posts and a canoe pulled up on the mud.
	var posts := SoftMesh.new()
	for spot: Vector2 in [Vector2(-1.4, 2.2), Vector2(1.8, 3.6), Vector2(-3.6, 4.4), Vector2(4.6, 2.6)]:
		posts.color = WOOD_DARK
		posts.capsule(uv(spot.x, spot.y, -0.3), uv(spot.x, spot.y, 0.45), 0.04, 0.032, 6, 2)
	_boat(posts, uv(-2.2, -0.8, LAND_Y), person_yaw(screen_right()) + 0.3, 1.3, BOAT_COLOURS[0])
	root.add_child(Kit.bake("Posts", posts))

	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	root.add_child(_crab_basket(uv(-0.9, -0.5, LAND_Y)))
	_place(props, "prop_motorcycle_darto", "Motorcycle", uv(1.6, -1.65, LAND_Y), person_yaw(screen_right()) - PI * 0.5 - 0.35)
	_spot_markers(root, LAND_Y)
	_finish(root)
	return root


func _estuary_tint(u: float, v: float, distance: float) -> Color:
	if distance < 0.0:
		return MUD_WET.darkened(0.1)
	var tint := MUD.lerp(MUD.lightened(0.08), 0.5 + 0.5 * sin(u * 1.3) * sin(v * 1.1))
	tint = tint.lerp(MUD_WET, smoothstep(0.8, 0.0, distance))
	if distance > 2.6:
		tint = tint.lerp(Style.GRASS_DEEP, smoothstep(2.6, 4.0, distance))
	return tint


## A mangrove: a short trunk on arching stilt roots and a dense dark crown.
## The crown is its own node so it can sway.
func _mangrove(scale: float, mute: float) -> Node3D:
	var tree := Node3D.new()
	var trunk := SoftMesh.new()
	trunk.color = Style.muted(MANGROVE_BARK, mute)
	var fork := Vector3(0.0, 0.55 * scale, 0.0)
	trunk.capsule(fork, Vector3(0.0, 1.1 * scale, 0.0), 0.06 * scale, 0.045 * scale, 8, 2)
	for index: int in 6:
		var angle := TAU * float(index) / 6.0 + _random.randf_range(-0.3, 0.3)
		var out := Vector3(cos(angle), 0.0, sin(angle)) * _random.randf_range(0.32, 0.48) * scale
		var mid := fork * 0.7 + out * 0.6 + Vector3(0.0, 0.08 * scale, 0.0)
		trunk.capsule(fork, mid, 0.032 * scale, 0.026 * scale, 6, 2)
		trunk.capsule(mid, out - Vector3(0.0, 0.05, 0.0), 0.026 * scale, 0.02 * scale, 6, 2)
	tree.add_child(Kit.bake("Trunk", trunk))
	var leaves := SoftMesh.new()
	for index: int in 5:
		var angle := TAU * float(index) / 5.0 + _random.randf_range(-0.3, 0.3)
		var offset := Vector3(cos(angle) * 0.32, _random.randf_range(-0.08, 0.12), sin(angle) * 0.32) * scale
		if index == 4:
			offset = Vector3(0.0, 0.2, 0.0) * scale
		leaves.color = Style.muted([Style.LEAF_DEEP, Style.LEAF, Style.LEAF_DEEP.darkened(0.08)][index % 3], mute)
		leaves.sphere(offset, Vector3.ONE * 0.4 * scale * _random.randf_range(0.85, 1.1), 12, 6, 0.04, _random.randi())
	var crown := Kit.bake("Crown", leaves)
	crown.position = Vector3(0.0, 1.2 * scale, 0.0)
	tree.add_child(crown)
	tree.add_child(Kit.furniture_shadow(Vector2(1.0, 1.0) * scale))
	return tree


## A small wooden boat: a rounded hull, a coloured stripe and a thwart.
func _boat(builder: RefCounted, at: Vector3, yaw: float, length: float, colour: Color) -> void:
	var turn := Basis(Vector3.UP, yaw)
	builder.transform = Transform3D(turn, at)
	builder.color = WOOD
	builder.sphere(Vector3(0.0, 0.08, 0.0), Vector3(length * 0.5, 0.14, 0.24), 16, 6)
	builder.color = colour
	builder.sphere(Vector3(0.0, 0.13, 0.0), Vector3(length * 0.48, 0.05, 0.245), 16, 4)
	builder.color = WOOD_DARK
	builder.rounded_slab(Vector3(length * 0.78, 0.03, 0.36), Vector3(0.0, 0.17, 0.0), 0.012)
	builder.color = WOOD
	builder.rounded_slab(Vector3(0.08, 0.04, 0.42), Vector3(0.05, 0.2, 0.0), 0.01)
	builder.transform = Transform3D.IDENTITY


## A woven crab basket with its lid.
func _crab_basket(at: Vector3) -> Node3D:
	var builder := SoftMesh.new()
	builder.color = Style.CARAMEL.lightened(0.35)
	builder.cylinder(at, at + Vector3(0.0, 0.2, 0.0), 0.13, 0.16, 14)
	builder.color = Style.CARAMEL.lightened(0.2)
	for ring_index: int in 3:
		var y := 0.04 + float(ring_index) * 0.06
		builder.torus(at + Vector3(0.0, y, 0.0), Vector3.UP, 0.135 + 0.01 * float(ring_index), 0.012)
	builder.color = Style.CARAMEL.lightened(0.15)
	builder.cylinder(at + Vector3(0.0, 0.2, 0.0), at + Vector3(0.0, 0.24, 0.0), 0.17, 0.1, 14)
	var node := Kit.bake("CrabBasket", builder)
	return node


# --- Mawar Pier -------------------------------------------------------------------
# A long wooden pier running out to sea. Darto fishes from its end; the sea
# fills the picture, fishing boats ride at anchor on the right, and the fish
# auction hall (TPI) stands on the beach to the left.

static func pier_land(u: float, v: float) -> float:
	return -6.5 + 0.6 * sin(v * 0.35) - u


func build_pier_set() -> Node3D:
	_begin(14)
	var root := Node3D.new()
	root.name = "EnvPierSet"
	root.add_child(Kit.lighting())
	var land := func(u: float, v: float) -> float: return pier_land(u, v)
	_spot_ground(root, land, _pier_tint, [SEA_SHALLOW, SEA, SEA_DEEP])
	_spot_water_lines(root, land, 16, Rect2(-5.0, -6.0, 14.0, 14.0), 0.18, 0.5)

	# The pier: planks across, edge beams and pilings.
	var pier := SoftMesh.new()
	var deck := Basis(screen_right(), Vector3.UP, toward_camera())
	var v := 0.6
	var plank := 0
	while v > -12.0:
		pier.color = WOOD.lerp(WOOD_DARK, 0.15 * float(plank % 3))
		pier.transform = Transform3D(deck, uv(0.2, v, PIER_DECK_Y - 0.025))
		pier.rounded_slab(Vector3(2.0, 0.05, 0.19), Vector3.ZERO, 0.012)
		v -= 0.21
		plank += 1
	pier.transform = Transform3D.IDENTITY
	pier.color = WOOD_DARK
	for side: float in [-0.85, 1.25]:
		pier.capsule(uv(side, 0.65, PIER_DECK_Y - 0.06), uv(side, -12.0, PIER_DECK_Y - 0.06), 0.045, -1.0, 6, 2)
		var post_v := 0.55
		while post_v > -12.0:
			pier.capsule(uv(side, post_v, -0.6), uv(side, post_v, PIER_DECK_Y + 0.05), 0.06, -1.0, 8, 2)
			post_v -= 1.4
	# Bollards and a coil of rope at the end.
	pier.color = Color("4a4440")
	for spot: Vector2 in [Vector2(-0.7, 0.45), Vector2(1.1, 0.45)]:
		pier.cylinder(uv(spot.x, spot.y, PIER_DECK_Y), uv(spot.x, spot.y, PIER_DECK_Y + 0.14), 0.05, -1.0, 10)
		pier.sphere(uv(spot.x, spot.y, PIER_DECK_Y + 0.15), Vector3(0.065, 0.03, 0.065), 10, 3)
	pier.color = Style.CARAMEL.lightened(0.3)
	for loop: int in 3:
		pier.torus(uv(-0.55, -0.6, PIER_DECK_Y + 0.02 + 0.025 * float(loop)), Vector3.UP, 0.12 - 0.015 * float(loop), 0.016)
	# Fish crates stacked by the rail.
	for index: int in 3:
		pier.color = [Color("5b8fc7"), Color("d9604c"), Color("5b8fc7")][index]
		pier.transform = Transform3D(deck, uv(-0.45, -1.6 - 0.02 * float(index), PIER_DECK_Y + 0.07 + (0.14 if index >= 2 else 0.0)))
		pier.rounded_slab(Vector3(0.36, 0.14, 0.26), Vector3(0.38 * float(index % 2), 0.0, 0.0), 0.02)
	pier.transform = Transform3D.IDENTITY
	root.add_child(Kit.bake("Pier", pier))

	# Boats at anchor on the right, each bobbing on its own.
	var boats := Node3D.new()
	boats.name = "Boats"
	root.add_child(boats)
	for index: int in 3:
		var builder := SoftMesh.new()
		_boat(builder, Vector3.ZERO, 0.0, 1.9 - 0.2 * float(index), BOAT_COLOURS[(index + 1) % BOAT_COLOURS.size()])
		builder.color = Style.FLOUR
		builder.rounded_slab(Vector3(0.36, 0.28, 0.3), Vector3(-0.25, 0.36, 0.0), 0.03)
		builder.color = ROOF_BLUE
		builder.rounded_slab(Vector3(0.44, 0.04, 0.38), Vector3(-0.25, 0.52, 0.0), 0.015)
		var boat := Kit.bake("Boat%d" % index, builder)
		boat.position = uv(3.4 + float(index) * 1.9, 3.2 + float(index) * 1.6, -0.06)
		boat.rotation.y = person_yaw(screen_right()) + PI * 0.5 + _random.randf_range(-0.4, 0.4)
		boats.add_child(boat)
		_motion.append(["../Boats/%s" % boat.name, "bob", 0.02, 0.45, float(index) * 1.7, 1])

	# The auction hall (TPI) on the beach: open sides, a big blue roof.
	var hall := SoftMesh.new()
	var hall_at := uv(-9.6, 3.4, LAND_Y)
	var turn := Basis(Vector3.UP, person_yaw(screen_right()))
	hall.transform = Transform3D(turn, hall_at)
	hall.color = Style.muted(CONCRETE, 0.2)
	hall.rounded_slab(Vector3(3.2, 0.12, 2.2), Vector3(0.0, 0.06, 0.0), 0.03)
	hall.color = Style.muted(Style.FLOUR, 0.2)
	for corner: Vector2 in [Vector2(-1.4, -0.9), Vector2(1.4, -0.9), Vector2(-1.4, 0.9), Vector2(1.4, 0.9), Vector2(0.0, -0.9), Vector2(0.0, 0.9)]:
		hall.capsule(Vector3(corner.x, 0.1, corner.y), Vector3(corner.x, 1.3, corner.y), 0.06, -1.0, 8, 2)
	hall.color = Style.muted(ROOF_BLUE, 0.2)
	for side: float in [-1.0, 1.0]:
		# Each half slopes down to its own eave (see _house).
		hall.transform = Transform3D(turn * Basis(Vector3.RIGHT, 0.38 * side), hall_at + turn * Vector3(0.0, 1.5, 0.62 * side))
		hall.rounded_slab(Vector3(3.6, 0.07, 1.4), Vector3.ZERO, 0.025)
	hall.transform = Transform3D.IDENTITY
	root.add_child(Kit.bake("AuctionHall", hall))

	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	for index: int in 4:
		trees.add_child(_palm("Palm%d" % index, uv(-8.2 - float(index % 2) * 1.6, -2.0 + float(index) * 2.6, LAND_Y)))
	_spot_markers(root, PIER_DECK_Y)
	_finish(root)
	return root


func _pier_tint(u: float, v: float, distance: float) -> Color:
	if distance < 0.0:
		return Style.SAND.darkened(0.15)
	return Style.SAND.lerp(Style.SAND.lightened(0.1), 0.5 + 0.5 * sin(u * 0.9) * sin(v * 0.7))


## A coconut palm: a curved trunk and a fan of fronds (the crown can sway).
func _palm(node_name: String, base: Vector3) -> Node3D:
	var tree := Node3D.new()
	tree.name = node_name
	tree.position = base
	var trunk := SoftMesh.new()
	trunk.color = Style.BARK.lightened(0.1)
	var previous := Vector3.ZERO
	for step: int in range(1, 6):
		var along := float(step) / 5.0
		var point := Vector3(0.35 * along * along, 2.2 * along, 0.0)
		trunk.capsule(previous, point, 0.07 - 0.015 * along, -1.0, 8, 2)
		previous = point
	tree.add_child(Kit.bake("Trunk", trunk))
	var fronds := SoftMesh.new()
	for index: int in 7:
		var angle := TAU * float(index) / 7.0
		var out := Vector3(cos(angle), 0.0, sin(angle))
		fronds.color = Style.LEAF.lerp(Style.LEAF_DEEP, float(index % 2) * 0.6)
		fronds.capsule(Vector3.ZERO, out * 0.55 + Vector3(0.0, 0.1, 0.0), 0.05, 0.02, 6, 2)
		fronds.capsule(out * 0.55 + Vector3(0.0, 0.1, 0.0), out * 0.95 - Vector3(0.0, 0.2, 0.0), 0.02, 0.008, 6, 2)
	fronds.color = Style.BARK
	fronds.sphere(Vector3(0.05, -0.08, 0.0), Vector3.ONE * 0.09, 8, 4)
	var crown := Kit.bake("Crown", fronds)
	crown.position = previous
	tree.add_child(crown)
	_motion.append(["../Trees/%s/Crown" % node_name, "sway", 0.03, _random.randf_range(0.5, 0.8), _random.randf_range(0.0, TAU), 0])
	return tree


# --- Spot duel arenas (revision 6.7) ------------------------------------------------

## Silat: a bamboo platform with a woven mat by the river, banners on two
## tall bamboo poles behind and a drum at the side.
func build_silat_set() -> Node3D:
	_begin(21)
	var root := Node3D.new()
	root.name = "EnvSilatSet"
	root.add_child(Kit.lighting())
	_lakeside(root, 2.6)
	var deck_y := 0.1
	var stage := SoftMesh.new()
	var turn := Basis(screen_right(), Vector3.UP, toward_camera())
	stage.color = BAMBOO.lerp(Style.PINE, 0.5)
	stage.transform = Transform3D(turn, uv(0.0, 0.0, deck_y * 0.5))
	stage.rounded_slab(Vector3(2.6, deck_y, 2.2), Vector3.ZERO, 0.03)
	stage.transform = Transform3D.IDENTITY
	# (Kit.checker faces its quads along along_u x along_v: into the picture
	# first, then right, so the mat faces up.)
	Kit.checker(stage, uv(-1.1, -0.9, deck_y + 0.004), into_picture() * 1.8, screen_right() * 2.2, 7, 8, Style.CUSTARD.lerp(CREAM, 0.3), Style.CUSTARD.lerp(CREAM, 0.7))
	stage.color = BAMBOO_DEEP
	for corner: Vector2 in [Vector2(-1.3, -1.1), Vector2(1.3, -1.1), Vector2(-1.3, 1.1), Vector2(1.3, 1.1)]:
		stage.capsule(uv(corner.x, corner.y, 0.0), uv(corner.x, corner.y, deck_y + 0.02), 0.05, -1.0, 6, 2)
	for side: float in [-1.15, 1.15]:
		stage.color = BAMBOO_DEEP
		stage.capsule(uv(side, 1.25, 0.0), uv(side, 1.25, 2.0), 0.035, 0.025, 6, 2)
		for stripe: int in 2:
			stage.color = [FLAG_RED, Style.FLOUR][stripe]
			stage.transform = Transform3D(turn, uv(side + 0.12, 1.25, 1.75 - 0.22 * float(stripe)))
			stage.rounded_slab(Vector3(0.22, 0.2, 0.01), Vector3.ZERO, 0.004)
			stage.transform = Transform3D.IDENTITY
	stage.color = BAMBOO_DEEP
	stage.capsule(uv(-1.15, 1.25, 1.9), uv(1.15, 1.25, 1.9), 0.022, -1.0, 6, 2)
	# The drum (kendang) at the side.
	stage.color = Style.CARAMEL.lightened(0.1)
	stage.capsule(uv(1.75, -0.6, 0.16), uv(1.95, -0.3, 0.16), 0.14, 0.11, 12, 3)
	stage.color = CREAM
	stage.sphere(uv(1.75, -0.6, 0.16), Vector3(0.12, 0.12, 0.12), 10, 4)
	root.add_child(Kit.bake("Stage", stage))
	var trees := root.get_node("Trees") as Node3D
	for spec: Vector2 in [Vector2(-3.0, 1.8), Vector2(3.2, 1.6)]:
		var clump := _bamboo_clump(7)
		clump.name = "Bamboo%d" % trees.get_child_count()
		clump.position = uv(spec.x, spec.y)
		trees.add_child(clump)
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	var fish_floor := uv(0.5, 0.42, deck_y)
	var darto_floor := uv(-0.5, -0.42, deck_y)
	var to_darto := (darto_floor - fish_floor).normalized()
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw(to_darto)), fish_floor)))
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(-to_darto)), darto_floor)))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.1, 0.5), 6.2, 5.6))
	_finish(root)
	return root


## Tug of War: a sandy lane on the reservoir bank with a chalk line at each
## end and the middle mark, a bunting string behind and two chairs for the
## spectators who never come.
func build_tambang_set() -> Node3D:
	_begin(22)
	var root := Node3D.new()
	root.name = "EnvTambangSet"
	root.add_child(Kit.lighting())
	_lakeside(root, 2.8)
	var lane := SoftMesh.new()
	var turn := Basis(screen_right(), Vector3.UP, toward_camera())
	lane.color = Style.SAND.darkened(0.03)
	lane.transform = Transform3D(turn, uv(0.0, 0.0, 0.006))
	lane.rounded_slab(Vector3(3.4, 0.012, 0.9), Vector3.ZERO, 0.005)
	lane.color = Style.FLOUR
	for line_u: float in [-1.05, 0.0, 1.05]:
		lane.transform = Transform3D(turn, uv(line_u, 0.0, 0.014))
		lane.rounded_slab(Vector3(0.05 if line_u != 0.0 else 0.03, 0.006, 0.86), Vector3.ZERO, 0.002)
	lane.transform = Transform3D.IDENTITY
	for line_u: float in [-1.05, 1.05]:
		lane.color = WOOD_DARK
		lane.capsule(uv(line_u, 0.5, 0.0), uv(line_u, 0.5, 0.55), 0.015, -1.0, 6, 2)
		lane.color = FLAG_RED if line_u < 0.0 else Style.FLOUR
		lane.transform = Transform3D(turn, uv(line_u + 0.08, 0.5, 0.5))
		lane.rounded_slab(Vector3(0.16, 0.1, 0.01), Vector3.ZERO, 0.004)
		lane.transform = Transform3D.IDENTITY
	root.add_child(Kit.bake("Lane", lane))
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	var lights := _place(props, "prop_dance_string_light", "Bunting", uv(0.0, 1.6), person_yaw(toward_camera()) + PI)
	lights.scale = Vector3(0.9, 0.8, 0.9)
	_place(props, "prop_plastic_chair", "ChairA", uv(-1.9, -1.3), person_yaw(into_picture()) + 0.5)
	_place(props, "prop_plastic_chair", "ChairB", uv(1.9, -1.3), person_yaw(into_picture()) - 0.5)
	_place(props, "prop_bucket_blue", "Bucket", uv(2.3, 0.4), 0.0)
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw(screen_right())), uv(-0.62, 0.0))))
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw(-screen_right())), uv(0.6, 0.0))))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.0, 0.4), 6.2, 5.6))
	_finish(root)
	return root


## Spinning Tops: a woven tray on packed mud by the estuary, ringed by
## mangroves, with a crab basket for a seat.
func build_gasing_set() -> Node3D:
	_begin(23)
	var root := Node3D.new()
	root.name = "EnvGasingSet"
	root.add_child(Kit.lighting())
	_lakeside(root, 2.5)
	var arena := SoftMesh.new()
	var centre := uv(0.0, 0.1)
	arena.color = MUD
	arena.cylinder(centre + Vector3(0.0, 0.0, 0.0), centre + Vector3(0.0, 0.01, 0.0), 1.25, -1.0, 28)
	# The tampah: a shallow woven tray with a rim.
	arena.color = Style.CUSTARD.lerp(CREAM, 0.3)
	arena.cylinder(centre + Vector3(0.0, 0.01, 0.0), centre + Vector3(0.0, 0.025, 0.0), 0.62, -1.0, 28)
	for ring_index: int in 4:
		arena.color = Style.CUSTARD.lerp(Style.CARAMEL, 0.15 + 0.1 * float(ring_index % 2))
		arena.torus(centre + Vector3(0.0, 0.026, 0.0), Vector3.UP, 0.15 + 0.13 * float(ring_index), 0.008)
	arena.color = Style.CARAMEL.lightened(0.25)
	arena.torus(centre + Vector3(0.0, 0.04, 0.0), Vector3.UP, 0.62, 0.03)
	root.add_child(Kit.bake("Arena", arena))
	root.add_child(_crab_basket(uv(-1.5, -0.7)))
	var trees := root.get_node("Trees") as Node3D
	for spec: Vector2 in [Vector2(-2.6, 1.6), Vector2(2.8, 1.4)]:
		var mangrove := _mangrove(0.9, 0.0)
		mangrove.name = "Mangrove%d" % trees.get_child_count()
		mangrove.position = uv(spec.x, spec.y)
		trees.add_child(mangrove)
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	var darto_spot := uv(-0.95, -0.4)
	var fish_spot := uv(0.95, 0.45)
	markers.add_child(Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, person_yaw((centre - darto_spot).normalized())), darto_spot)))
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw((centre - fish_spot).normalized())), fish_spot)))
	markers.add_child(Kit.marker("ArenaCentre", Transform3D(Basis.IDENTITY, centre + Vector3(0.0, 0.03, 0.0))))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.1, 0.35), 6.2, 5.6))
	_finish(root)
	return root


const PINANG_POLE_HEIGHT := 2.0
const PINANG_CLIMB := 1.3


## Greased Pole: two tall greased poles on the beach by the pier, each with a
## ring of prizes and a red-and-white flag on top.
func build_pinang_set() -> Node3D:
	_begin(24)
	var root := Node3D.new()
	root.name = "EnvPinangSet"
	root.add_child(Kit.lighting())
	_lakeside(root, 2.4)
	var poles := SoftMesh.new()
	var turn := Basis(screen_right(), Vector3.UP, toward_camera())
	for pole_u: float in [-0.5, 0.5]:
		var base := uv(pole_u, 0.25)
		var top := base + Vector3(0.0, PINANG_POLE_HEIGHT, 0.0)
		poles.color = Color("7a5236")
		poles.capsule(base - Vector3(0.0, 0.05, 0.0), top, 0.06, 0.05, 10, 3)
		# The grease: a glossy darker streak down the front.
		poles.color = Color("4e3524")
		poles.capsule(base + toward_camera() * 0.03 + Vector3(0.0, 0.1, 0.0), top + toward_camera() * 0.025 - Vector3(0.0, 0.2, 0.0), 0.04, 0.03, 8, 2)
		poles.color = Style.CARAMEL.lightened(0.3)
		poles.torus(top - Vector3(0.0, 0.12, 0.0), Vector3.UP, 0.32, 0.025)
		for index: int in 6:
			var angle := TAU * float(index) / 6.0
			var hang := top - Vector3(0.0, 0.12, 0.0) + Vector3(cos(angle), 0.0, sin(angle)) * 0.32
			poles.color = Style.FLOUR.darkened(0.2)
			poles.capsule(hang, hang - Vector3(0.0, 0.18, 0.0), 0.005, -1.0, 4, 1)
			poles.color = [FLAG_RED, Style.BUTTER, NET_BLUE, Style.MINT, Style.STRAWBERRY, Style.CUSTARD][index]
			if index % 2 == 0:
				poles.transform = Transform3D(turn, hang - Vector3(0.0, 0.24, 0.0))
				poles.rounded_slab(Vector3(0.12, 0.1, 0.08), Vector3.ZERO, 0.015)
				poles.transform = Transform3D.IDENTITY
			else:
				poles.sphere(hang - Vector3(0.0, 0.24, 0.0), Vector3.ONE * 0.06, 8, 4)
		poles.color = Style.FLOUR.darkened(0.1)
		poles.capsule(top, top + Vector3(0.0, 0.35, 0.0), 0.012, -1.0, 6, 2)
		poles.color = FLAG_RED
		poles.transform = Transform3D(turn, top + Vector3(0.0, 0.3, 0.0) + screen_right() * 0.12)
		poles.rounded_slab(Vector3(0.24, 0.08, 0.01), Vector3.ZERO, 0.003)
		poles.color = Style.FLOUR
		poles.rounded_slab(Vector3(0.24, 0.08, 0.01), Vector3(0.0, -0.08, 0.0), 0.003)
		poles.transform = Transform3D.IDENTITY
	root.add_child(Kit.bake("Poles", poles))
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	_place(props, "prop_plastic_chair", "Chair", uv(-1.8, -1.2), person_yaw(into_picture()) + 0.4)
	_place(props, "prop_bucket_blue", "Bucket", uv(1.6, -0.9), 0.0)
	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	var facing := person_yaw(into_picture())
	var darto := Kit.marker("DartoSpot", Transform3D(Basis(Vector3.UP, facing), uv(-0.5, 0.06)))
	darto.set_meta(&"climb_height", PINANG_CLIMB)
	markers.add_child(darto)
	markers.add_child(Kit.marker("FishSpot", Transform3D(Basis(Vector3.UP, fish_yaw(into_picture())), uv(0.5, 0.08))))
	markers.add_child(Kit.focus_marker(uv(0.0, 0.2, 1.0), 6.0, 5.6))
	_finish(root)
	return root
