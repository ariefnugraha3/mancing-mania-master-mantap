@tool
extends RefCounted
## Generates Danau Cempaka, the lake set (GDD 4, 103, 174.6, 184.9, 185.13).
##
## Composition target: water as generous negative space, a near bank with
## grass and reeds, one major shade tree, a distant warung, a road with power
## poles and low-detail houses on the far side. Everything is placed from a
## fixed seed, so the set is identical on every run.
##
## The lake and the Market are built here. The home and duel sets are added
## by their own milestones; the motorcycles arrive with the vehicle builder.

const MeshBuilder := preload("res://tools/generators/mesh_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")
const ScatterFieldScript := preload("res://scripts/actors/scatter_field.gd")

const GENERATOR_ID := "environment_builder"
const GENERATOR_VERSION := 1
const LAKE_SET_PATH := "res://generated/scenes/environment/env_lake_set.tscn"
const PLACEMENT_SEED := 20261112

# Lake set layout, in metres. The camera looks roughly along -Z across the water.
const DARTO_SPOT := Vector2(0.0, 2.6)
const FLOAT_SPOT := Vector2(0.4, -4.2)
const BUCKET_SPOT := Vector2(0.95, 3.0)
const SHADE_TREE_SPOT := Vector2(-3.6, 4.6)
const SECOND_TREE_SPOT := Vector2(8.4, 7.6)
const WARUNG_SPOT := Vector2(12.4, -16.0)
const ROAD_X := Vector2(15.4, 18.4)

const TERRAIN_STEP := 1.25
const TERRAIN_MIN := Vector2(-46.0, -70.0)
const TERRAIN_MAX := Vector2(34.0, 14.0)

# Palette (GDD 103).
const GRASS := Color("7d9150")
const GRASS_LIGHT := Color("98a65e")
const GRASS_DARK := Color("67804a")
const EARTH := Color("ad9a68")
const MUD := Color("8a7757")
const LAKE_BED := Color("5f6a55")
const ASPHALT := Color("6e6861")
const FAR_HAZE := Color("a9b79f")
const TRUNK := Color("6a5340")
const LEAF := Color("5d8145")
const LEAF_LIGHT := Color("90a550")
const LEAF_DARK := Color("476a3f")
const CREAM := Color("e9dcc0")
const TERRACOTTA := Color("b8654e")
const FADED_RED := Color("a9534d")
const WOOD := Color("8a6a4a")

## Direction pointing from the scene toward the sun: low, from the left.
const TO_SUN := Vector3(-0.75, 0.44, -0.2)


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var sets: Dictionary[String, Array] = {
		"env_lake_set": [build_lake_set, LAKE_SET_PATH],
		"env_market_set": [build_market_set, MARKET_SET_PATH],
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


func build_lake_set() -> Node3D:
	var random := RandomNumberGenerator.new()
	random.seed = PLACEMENT_SEED
	var solid: Material = load(MaterialBuilder.VERTEX_COLOR)
	var foliage: Material = load(MaterialBuilder.FOLIAGE_SWAY)
	var grass: Material = load(MaterialBuilder.GRASS_SWAY)

	var root := Node3D.new()
	root.name = "EnvLakeSet"
	root.add_child(_build_lighting())
	root.add_child(_instance("EnvLakeShore", _build_terrain(random), solid, false))
	var water := _instance("EnvLakeWater", _build_water(), load(MaterialBuilder.LAKE_WATER), false)
	root.add_child(water)

	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	trees.add_child(_build_tree("EnvTreeLargeA", SHADE_TREE_SPOT, 6.4, 3.6, 0.72, random, solid, foliage))
	trees.add_child(_build_tree("EnvTreeLargeB", SECOND_TREE_SPOT, 7.6, 2.5, 1.15, random, solid, foliage))

	root.add_child(_build_scatter("EnvGrassClusterA", _build_grass_cluster(random), grass, _grass_spots(random)))
	root.add_child(_build_scatter("EnvReedsClusterA", _build_reeds_cluster(random), grass, _reed_spots(random)))
	root.add_child(_instance("Rocks", _build_rocks(random), solid, true))
	root.add_child(_instance("FarShore", _build_far_shore(random), solid, false))
	root.add_child(_instance("EnvPowerPole", _build_power_poles(), solid, true))
	root.add_child(_instance("EnvMarketShell", _build_warung(), solid, true))
	root.add_child(_build_markers())
	return root


# --- Shape of the land ------------------------------------------------------

## Signed distance to the nearest shoreline: positive on land, negative in water.
static func land_distance(x: float, z: float) -> float:
	var near := z - (0.9 + 0.55 * sin(x * 0.31 + 0.4) + 0.3 * sin(x * 0.83 + 1.7))
	var east := x - (10.5 + 1.2 * sin(z * 0.21) + 0.5 * sin(z * 0.57 + 1.0))
	var west := (-13.0 - 1.5 * sin(z * 0.17 + 2.0)) - x
	var far := (-46.0 + 2.0 * sin(x * 0.12)) - z
	return maxf(maxf(near, east), maxf(west, far))


static func ground_height(x: float, z: float) -> float:
	var distance := land_distance(x, z)
	if distance <= 0.0:
		return -0.12 + maxf(distance, -4.0) * 0.22
	var height := 0.03 + (1.0 - exp(-distance * 0.55)) * 0.55
	height += 0.12 * sin(x * 0.4) * sin(z * 0.33) * minf(distance / 4.0, 1.0)
	# The far bank climbs into low hills.
	if z < -50.0:
		height += (-50.0 - z) * 0.14
	return height


static func ground_point(spot: Vector2) -> Vector3:
	return Vector3(spot.x, ground_height(spot.x, spot.y), spot.y)


# --- Lighting ---------------------------------------------------------------

func _build_lighting() -> Node3D:
	var lighting := Node3D.new()
	lighting.name = "Lighting"

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.transform = Transform3D(Basis.looking_at(-TO_SUN.normalized(), Vector3.UP), Vector3(0, 12, 0))
	sun.light_color = Color(1.0, 0.9, 0.72)
	sun.light_energy = 0.95
	sun.light_angular_distance = 2.0
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 42.0
	sun.shadow_bias = 0.06
	sun.shadow_opacity = 0.55
	lighting.add_child(sun)

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.5, 0.67, 0.74)
	sky_material.sky_horizon_color = Color(0.99, 0.88, 0.69)
	sky_material.sky_curve = 0.18
	sky_material.ground_bottom_color = Color(0.5, 0.58, 0.45)
	sky_material.ground_horizon_color = Color(0.82, 0.8, 0.66)
	sky_material.sun_angle_max = 22.0
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.55
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.96, 0.87, 0.72)
	environment.fog_density = 0.0022
	environment.fog_sky_affect = 0.0
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	lighting.add_child(world_environment)
	return lighting


# --- Terrain and water ------------------------------------------------------

func _build_terrain(random: RandomNumberGenerator) -> ArrayMesh:
	var columns := int((TERRAIN_MAX.x - TERRAIN_MIN.x) / TERRAIN_STEP)
	var rows := int((TERRAIN_MAX.y - TERRAIN_MIN.y) / TERRAIN_STEP)

	# Jittered grid points give irregular facets instead of a regular checker.
	var points: Array = []
	for row: int in rows + 1:
		var line := PackedVector3Array()
		for column: int in columns + 1:
			var x := TERRAIN_MIN.x + column * TERRAIN_STEP
			var z := TERRAIN_MIN.y + row * TERRAIN_STEP
			if row > 0 and row < rows and column > 0 and column < columns:
				x += random.randf_range(-0.36, 0.36)
				z += random.randf_range(-0.36, 0.36)
			line.append(Vector3(x, ground_height(x, z), z))
		points.append(line)

	var builder := MeshBuilder.new()
	var below := Vector3(0, -100, 0)
	for row: int in rows:
		for column: int in columns:
			var a: Vector3 = points[row][column]
			var b: Vector3 = points[row][column + 1]
			var c: Vector3 = points[row + 1][column + 1]
			var d: Vector3 = points[row + 1][column]
			# Alternate the diagonal so facets do not line up in stripes.
			if (row + column) % 2 == 0:
				_ground_triangle(builder, a, b, c, below, random)
				_ground_triangle(builder, a, c, d, below, random)
			else:
				_ground_triangle(builder, a, b, d, below, random)
				_ground_triangle(builder, b, c, d, below, random)
	return builder.commit()


func _ground_triangle(builder: RefCounted, a: Vector3, b: Vector3, c: Vector3, below: Vector3, random: RandomNumberGenerator) -> void:
	var centre := (a + b + c) / 3.0
	builder.color = _ground_color(centre.x, centre.z, random.randf())
	builder.triangle(a, b, c, Vector3(centre.x, below.y, centre.z))


func _ground_color(x: float, z: float, variation: float) -> Color:
	var distance := land_distance(x, z)
	if distance <= 0.0:
		return LAKE_BED
	if distance < 0.45:
		return MUD.lerp(EARTH, variation * 0.3)
	if distance < 1.1:
		return EARTH.lerp(GRASS, variation * 0.35)
	if x > ROAD_X.x and x < ROAD_X.y and z > -44.0:
		return ASPHALT.lightened(variation * 0.08)

	# Large soft patches of lighter and darker grass, plus per-facet variation.
	var patch := 0.5 + 0.5 * sin(x * 0.23 + 1.3) * sin(z * 0.19 + 0.6)
	var color := GRASS_DARK.lerp(GRASS_LIGHT, patch).lerp(GRASS, 0.45)
	color = color.lightened((variation - 0.5) * 0.1)
	# Distance haze toward the far bank.
	return color.lerp(FAR_HAZE, clampf((-z - 30.0) / 34.0, 0.0, 0.7))


func _build_water() -> ArrayMesh:
	var builder := MeshBuilder.new()
	builder.color = Color.WHITE
	var step := 3.0
	var x := -34.0
	while x < 34.0:
		var z := -48.0
		while z < 4.0:
			builder.quad(Vector3(x, 0, z), Vector3(x + step, 0, z), Vector3(x + step, 0, z + step), Vector3(x, 0, z + step), Vector3(x, -10, z))
			z += step
		x += step
	return builder.commit()


# --- Trees ------------------------------------------------------------------

## `spread` < 1 gives a wide flat crown (shade tree), > 1 a taller one.
func _build_tree(node_name: String, spot: Vector2, height: float, crown_radius: float, spread: float, random: RandomNumberGenerator, solid: Material, foliage: Material) -> Node3D:
	var tree := Node3D.new()
	tree.name = node_name
	tree.position = ground_point(spot)

	var trunk := MeshBuilder.new()
	trunk.color = TRUNK
	var lean := Vector3(random.randf_range(-0.25, 0.25), 0.0, random.randf_range(-0.2, 0.2))
	var knee := Vector3(0, height * 0.32, 0) + lean
	var fork := Vector3(0, height * 0.55, 0) + lean * 1.8
	trunk.tube(Vector3(0, -0.2, 0), knee, 0.3, 0.22, 7, true)
	trunk.color = TRUNK.lightened(0.05)
	trunk.tube(knee, fork, 0.22, 0.17, 7, false)

	var crown := MeshBuilder.new()
	var crown_centre := Vector3(lean.x * 2.2, height * 0.74, lean.z * 2.2)
	var crown_height := crown_radius * spread
	crown.color_rule = func(point: Vector3, base: Color) -> Color:
		# Lit from the upper left; undersides fall into cool shadow.
		var lift := clampf((point.y - (crown_centre.y - crown_height)) / (crown_height * 2.0), 0.0, 1.0)
		var sunny := clampf(0.5 - (point.x - crown_centre.x) / (crown_radius * 2.2), 0.0, 1.0)
		return base.lerp(LEAF_DARK, (1.0 - lift) * 0.7).lerp(LEAF_LIGHT, lift * sunny * 0.75)

	var branches := 5
	for index: int in branches:
		var angle := TAU * float(index) / float(branches) + random.randf_range(-0.3, 0.3)
		var reach := crown_radius * random.randf_range(0.45, 0.72)
		var clump := crown_centre + Vector3(cos(angle) * reach, random.randf_range(-0.25, 0.3) * crown_height, sin(angle) * reach)
		trunk.color = TRUNK.darkened(0.08)
		trunk.tube(fork, clump - Vector3(0, crown_height * 0.3, 0), 0.13, 0.05, 5, false)
		crown.color = LEAF.lightened(random.randf_range(-0.06, 0.06))
		var size := crown_radius * random.randf_range(0.48, 0.62)
		crown.blob(clump, Vector3(size, size * spread * 0.8, size), 8, 5, 0.12, random.randi())
	crown.color = LEAF
	crown.blob(crown_centre + Vector3(0, crown_height * 0.3, 0), Vector3(crown_radius * 0.7, crown_height * 0.75, crown_radius * 0.7), 9, 5, 0.12, random.randi())

	tree.add_child(_instance("Trunk", trunk.commit(), solid, true))
	tree.add_child(_instance("Crown", crown.commit(), foliage, true))
	return tree


# --- Grass and reeds --------------------------------------------------------

func _build_grass_cluster(random: RandomNumberGenerator) -> ArrayMesh:
	var builder := MeshBuilder.new()
	for blade: int in 7:
		var angle := random.randf() * TAU
		var offset := Vector3(cos(angle), 0, sin(angle)) * random.randf_range(0.0, 0.11)
		var height := random.randf_range(0.2, 0.4)
		var tip := offset * 1.9 + Vector3(0, height, 0)
		var width := Vector3(-sin(angle), 0, cos(angle)) * 0.022
		builder.color = GRASS.lerp(GRASS_LIGHT, random.randf())
		builder.double_sided_triangle(offset - width, offset + width, tip)
	return builder.commit()


func _build_reeds_cluster(random: RandomNumberGenerator) -> ArrayMesh:
	var builder := MeshBuilder.new()
	for stalk: int in 6:
		var angle := random.randf() * TAU
		var base := Vector3(cos(angle), 0, sin(angle)) * random.randf_range(0.02, 0.18)
		var height := random.randf_range(0.9, 1.55)
		var top := base * 1.5 + Vector3(0, height, 0)
		var width := Vector3(-sin(angle), 0, cos(angle)) * 0.016
		builder.color = Color("7f9455").lerp(Color("a7a763"), random.randf())
		builder.double_sided_triangle(base - width, base + width, top)
		if stalk % 2 == 0:
			# Brown seed head near the top.
			builder.color = Color("6b4a32")
			builder.tube(top - Vector3(0, 0.26, 0), top - Vector3(0, 0.08, 0), 0.02, 0.016, 5, true)
	return builder.commit()


func _grass_spots(random: RandomNumberGenerator) -> Array:
	var spots: Array = []
	var attempts := 0
	while spots.size() < 560 and attempts < 6000:
		attempts += 1
		var x := random.randf_range(-13.0, 12.5)
		var z := random.randf_range(0.0, 12.0)
		var distance := land_distance(x, z)
		if distance < 0.9:
			continue
		# Thicker near the water, sparser up the bank, and a worn clearing
		# where Darto stands and walks in.
		if random.randf() > 0.35 + 0.65 * exp(-distance * 0.35):
			continue
		if Vector2(x, z).distance_to(DARTO_SPOT) < 1.15 or (absf(x - 0.6) < 0.8 and z > 2.6):
			continue
		spots.append([Vector3(x, ground_height(x, z), z), random.randf() * TAU, random.randf_range(0.8, 1.5)])
	return spots


func _reed_spots(random: RandomNumberGenerator) -> Array:
	var spots: Array = []
	var attempts := 0
	while spots.size() < 110 and attempts < 5000:
		attempts += 1
		var x := random.randf_range(-12.5, 10.0)
		var z := random.randf_range(-1.5, 3.0)
		var distance := land_distance(x, z)
		if distance < -0.55 or distance > 0.5:
			continue
		# Keep the water in front of Darto open so the float is never hidden.
		if x > -2.2 and x < 2.6:
			continue
		spots.append([Vector3(x, minf(ground_height(x, z), 0.0) - 0.05, z), random.randf() * TAU, random.randf_range(0.8, 1.25)])
	return spots


## Instanced vegetation. The node stores the cluster mesh and the placements;
## ScatterField turns them into a MultiMesh when the scene loads.
func _build_scatter(node_name: String, mesh: ArrayMesh, material: Material, spots: Array) -> MultiMeshInstance3D:
	var placements := PackedFloat32Array()
	for spot: Array in spots:
		var basis := Basis(Vector3.UP, spot[1]).scaled(Vector3.ONE * float(spot[2]))
		ScatterFieldScript.pack_transform(placements, Transform3D(basis, spot[0]))
	var instance := MultiMeshInstance3D.new()
	instance.set_script(ScatterFieldScript)
	instance.name = node_name
	instance.set(&"cluster_mesh", mesh)
	instance.set(&"placements", placements)
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _build_rocks(random: RandomNumberGenerator) -> ArrayMesh:
	var builder := MeshBuilder.new()
	for spot: Vector2 in [Vector2(-2.6, 1.5), Vector2(-3.1, 1.2), Vector2(3.4, 1.9), Vector2(-7.5, 0.6), Vector2(6.8, 1.7), Vector2(2.9, 1.5)]:
		var size := random.randf_range(0.16, 0.36)
		builder.color = Color("8b8676").lerp(Color("6f6b5e"), random.randf())
		var centre := Vector3(spot.x, ground_height(spot.x, spot.y) + size * 0.3, spot.y)
		builder.blob(centre, Vector3(size, size * 0.6, size * 0.85), 6, 4, 0.18, random.randi())
	return builder.commit()


# --- Far side of the lake ---------------------------------------------------

## Low-detail tree line, houses and hills: enough to read as a lived-in place.
func _build_far_shore(random: RandomNumberGenerator) -> ArrayMesh:
	var builder := MeshBuilder.new()
	var haze := 0.45

	for hill: Array in [[-22.0, -66.0, 16.0, 6.0], [4.0, -68.0, 20.0, 7.5], [27.0, -64.0, 14.0, 5.0], [-44.0, -40.0, 9.0, 5.5], [-46.0, -12.0, 9.0, 4.5]]:
		builder.color = Color("7f9a7c").lerp(FAR_HAZE, 0.3)
		builder.blob(Vector3(hill[0], 1.5, hill[1]), Vector3(hill[2], hill[3], 12.0), 9, 4, 0.08, random.randi())

	# Trees along the west bank close the view on the left.
	var west_z := 6.0
	while west_z > -46.0:
		var west_x := (-13.0 - 1.5 * sin(west_z * 0.17 + 2.0)) - random.randf_range(2.0, 6.5)
		var west_size := random.randf_range(1.7, 3.0)
		var west_base := ground_height(west_x, west_z)
		var west_haze := clampf((-west_z - 8.0) / 60.0, 0.05, haze)
		builder.color = TRUNK.lerp(FAR_HAZE, west_haze)
		builder.tube(Vector3(west_x, west_base, west_z), Vector3(west_x, west_base + west_size * 1.1, west_z), 0.17, 0.1, 5, false)
		builder.color = LEAF_DARK.lerp(LEAF, random.randf()).lerp(FAR_HAZE, west_haze)
		builder.blob(Vector3(west_x, west_base + west_size * 1.5, west_z), Vector3(west_size, west_size * 0.85, west_size), 7, 4, 0.14, random.randi())
		west_z -= random.randf_range(2.6, 5.0)

	var x := -30.0
	while x < 30.0:
		var z := -49.5 + random.randf_range(-1.5, 1.0)
		var size := random.randf_range(1.6, 2.9)
		var base := ground_height(x, z)
		builder.color = TRUNK.lerp(FAR_HAZE, haze)
		builder.tube(Vector3(x, base, z), Vector3(x, base + size * 1.1, z), 0.16, 0.1, 5, false)
		builder.color = LEAF_DARK.lerp(LEAF, random.randf()).lerp(FAR_HAZE, haze)
		builder.blob(Vector3(x, base + size * 1.5, z), Vector3(size, size * 0.85, size), 7, 4, 0.14, random.randi())
		x += random.randf_range(2.2, 4.6)

	for house: Array in [[-17.0, -51.5, 0.0], [-9.5, -52.5, 0.3], [-2.0, -51.0, -0.2], [9.0, -52.0, 0.15], [21.0, -47.0, 1.3], [23.5, -30.0, 1.5], [22.0, -6.0, 1.6]]:
		_add_house(builder, Vector3(house[0], ground_height(house[0], house[1]), house[1]), house[2], random, haze if house[1] < -40.0 else 0.2)
	return builder.commit()


func _add_house(builder: RefCounted, base: Vector3, yaw: float, random: RandomNumberGenerator, haze: float) -> void:
	var width := random.randf_range(4.0, 5.6)
	var depth := random.randf_range(3.4, 4.4)
	var wall := 2.5
	builder.transform = Transform3D(Basis(Vector3.UP, yaw), base)
	builder.color = CREAM.lerp(Color("cdbf9f"), random.randf()).lerp(FAR_HAZE, haze)
	builder.box(Vector3(width, wall, depth), Vector3(0, wall * 0.5, 0))
	# Gable roof as a triangular prism along the house width.
	builder.color = TERRACOTTA.lerp(FADED_RED, random.randf()).lerp(FAR_HAZE, haze)
	var overhang := 0.35
	var half_w := width * 0.5 + overhang
	var half_d := depth * 0.5 + overhang
	var ridge := wall + 1.25
	var left := PackedVector3Array([Vector3(-half_w, wall, -half_d), Vector3(-half_w, wall, half_d), Vector3(-half_w, ridge, 0)])
	var right := PackedVector3Array([Vector3(half_w, wall, -half_d), Vector3(half_w, wall, half_d), Vector3(half_w, ridge, 0)])
	builder.loft([left, right], true, true)
	builder.color = Color("5a5046").lerp(FAR_HAZE, haze)
	builder.box(Vector3(0.9, 1.7, 0.06), Vector3(-width * 0.2, 0.85, depth * 0.5 + 0.01))
	builder.transform = Transform3D.IDENTITY


## Power poles along the road with two sagging wires.
func _build_power_poles() -> ArrayMesh:
	var builder := MeshBuilder.new()
	var pole_x := ROAD_X.x - 0.9
	var tops: Array[Vector3] = []
	var z := 10.0
	while z > -42.0:
		var base := Vector3(pole_x, ground_height(pole_x, z), z)
		builder.color = Color("6b6258")
		builder.tube(base - Vector3(0, 0.3, 0), base + Vector3(0, 6.6, 0), 0.11, 0.075, 6, true)
		builder.box(Vector3(0.09, 0.09, 1.5), base + Vector3(0, 6.2, 0))
		builder.color = Color("8d8a80")
		builder.box(Vector3(0.3, 0.38, 0.3), base + Vector3(0.25, 5.4, 0))
		tops.append(base + Vector3(0, 6.25, 0))
		z -= 10.5

	builder.color = Color("3a3631")
	for index: int in tops.size() - 1:
		for side: float in [-0.62, 0.62]:
			var from := tops[index] + Vector3(0, 0, side)
			var to := tops[index + 1] + Vector3(0, 0, side)
			var previous := from
			for step: int in range(1, 5):
				var along := float(step) / 4.0
				var point := from.lerp(to, along) - Vector3(0, sin(along * PI) * 0.45, 0)
				builder.tube(previous, point, 0.012, 0.012, 3, false)
				previous = point
	return builder.commit()


## Bu Yati's warung seen from across the water: an open shed with a tin roof.
## The full interior is the Market set; this is its distant shell.
func _build_warung() -> ArrayMesh:
	var builder := MeshBuilder.new()
	var base := ground_point(WARUNG_SPOT)
	# The open front faces the lake (-X).
	builder.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), base)
	var width := 5.2
	var depth := 3.4
	var height := 2.5

	builder.color = Color("9a8c78")
	builder.box(Vector3(width + 0.6, 0.16, depth + 0.6), Vector3(0, 0.08, 0))
	builder.color = WOOD
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		builder.box(Vector3(0.14, height, 0.14), Vector3(corner.x * width * 0.5, height * 0.5 + 0.16, corner.y * depth * 0.5))
	builder.color = CREAM.darkened(0.06)
	builder.box(Vector3(width, height * 0.82, 0.1), Vector3(0, height * 0.41 + 0.16, -depth * 0.5))
	builder.box(Vector3(0.1, height * 0.82, depth), Vector3(width * 0.5, height * 0.41 + 0.16, 0))

	# Tin roof sloping toward the front, faded red.
	builder.color = FADED_RED.lerp(TERRACOTTA, 0.4)
	var roof := PackedVector3Array([
		Vector3(-width * 0.5 - 0.5, height + 0.75, -depth * 0.5 - 0.3), Vector3(width * 0.5 + 0.5, height + 0.75, -depth * 0.5 - 0.3),
		Vector3(width * 0.5 + 0.5, height + 0.2, depth * 0.5 + 0.9), Vector3(-width * 0.5 - 0.5, height + 0.2, depth * 0.5 + 0.9)])
	var roof_under := PackedVector3Array()
	for point: Vector3 in roof:
		roof_under.append(point - Vector3(0, 0.08, 0))
	builder.loft([roof_under, roof], true, true)

	# Counter, banner and a plastic stool or two.
	builder.color = WOOD.lightened(0.1)
	builder.box(Vector3(width * 0.7, 0.9, 0.7), Vector3(-0.3, 0.61, depth * 0.5 - 0.2))
	builder.color = Color("e4ae55")
	builder.box(Vector3(width * 0.72, 0.5, 0.04), Vector3(0, height - 0.05, depth * 0.5 + 0.88))
	builder.color = FADED_RED
	builder.box(Vector3(0.36, 0.45, 0.36), Vector3(-1.9, 0.39, depth * 0.5 + 0.9))
	builder.color = Color("557f7a")
	builder.box(Vector3(0.36, 0.45, 0.36), Vector3(1.5, 0.39, depth * 0.5 + 1.1))
	builder.transform = Transform3D.IDENTITY
	return builder.commit()


# --- Markers ----------------------------------------------------------------

## Named positions the gameplay scenes read instead of hard-coding numbers.
func _build_markers() -> Node3D:
	var markers := Node3D.new()
	markers.name = "Markers"
	var darto := ground_point(DARTO_SPOT)
	var spots: Dictionary[String, Transform3D] = {
		"DartoSpot": Transform3D(Basis.IDENTITY, darto),
		"FloatSpot": Transform3D(Basis.IDENTITY, Vector3(FLOAT_SPOT.x, 0.0, FLOAT_SPOT.y)),
		"BucketSpot": Transform3D(Basis(Vector3.UP, 0.5), ground_point(BUCKET_SPOT)),
		"CameraLandscape": _look(Vector3(3.4, 2.4, 9.4), Vector3(0.2, 0.7, -4.0)),
		"CameraPortrait": _look(Vector3(0.9, 3.1, 10.6), Vector3(0.15, 0.9, -3.0)),
		"CameraMenu": _look(Vector3(4.2, 2.6, 10.6), Vector3(1.0, 0.8, -4.0)),
	}
	for marker_name: String in spots:
		var marker := Marker3D.new()
		marker.name = marker_name
		marker.transform = spots[marker_name]
		markers.add_child(marker)
	return markers


func _look(from: Vector3, target: Vector3) -> Transform3D:
	return Transform3D(Basis.looking_at(target - from, Vector3.UP), from)


func _instance(node_name: String, mesh: ArrayMesh, material: Material, casts_shadow: bool) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	if not casts_shadow:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


# --- Market set (GDD 72, 185.15) --------------------------------------------
# Bu Yati's warung up close: an open-front shed in warm wood, cream and faded
# red, with the counter facing the customer. The open front faces +Z.

const MARKET_SET_PATH := "res://generated/scenes/environment/env_market_set.tscn"
const PROP_PATH := "res://generated/scenes/props/%s.tscn"
const MARKET_FLOOR := Vector3(5.6, 0.14, 3.8)
const MARKET_FLOOR_CENTRE := Vector3(0.0, 0.07, -0.7)
const MARKET_WALL_HEIGHT := 2.5
const BU_YATI_SPOT := Vector3(-0.25, 0.14, -0.2)
const DARTO_MARKET_SPOT := Vector3(-1.25, 0.0, 2.05)
## Late afternoon: the sun is lower and warmer than at the lake.
const MARKET_TO_SUN := Vector3(-0.8, 0.34, 0.45)


func build_market_set() -> Node3D:
	var random := RandomNumberGenerator.new()
	random.seed = PLACEMENT_SEED + 3
	var solid: Material = load(MaterialBuilder.VERTEX_COLOR)
	var foliage: Material = load(MaterialBuilder.FOLIAGE_SWAY)

	var root := Node3D.new()
	root.name = "EnvMarketSet"
	var lighting := _build_lighting()
	var sun := lighting.get_node("Sun") as DirectionalLight3D
	sun.transform = Transform3D(Basis.looking_at(-MARKET_TO_SUN.normalized(), Vector3.UP), Vector3(0, 12, 0))
	sun.light_color = Color(1.0, 0.84, 0.62)
	sun.light_energy = 0.78
	sun.directional_shadow_max_distance = 24.0
	root.add_child(lighting)

	root.add_child(_instance("Ground", _build_market_ground(random), solid, false))
	root.add_child(_instance("EnvMarketShell", _build_market_shell(), solid, true))
	root.add_child(_instance("FarTrees", _build_market_far_trees(random), solid, false))

	var trees := Node3D.new()
	trees.name = "Trees"
	root.add_child(trees)
	for spot: Array in [[Vector2(-5.2, -5.5), 6.8, 3.2, 0.8], [Vector2(5.8, -6.5), 7.4, 2.6, 1.1], [Vector2(8.5, 2.5), 6.0, 2.8, 0.9]]:
		var tree := _build_tree("Tree%d" % trees.get_child_count(), Vector2.ZERO, spot[1], spot[2], spot[3], random, solid, foliage)
		tree.position = Vector3(spot[0].x, 0.0, spot[0].y)
		trees.add_child(tree)

	# Furniture, from the prop scenes generated earlier in the same run.
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)
	var counter_top := MARKET_FLOOR.y + 0.82
	var placements: Array = [
		["prop_market_table", "Counter", Vector3(-0.2, MARKET_FLOOR.y, 0.55), 0.0],
		["prop_market_scale", "Scale", Vector3(0.27, counter_top, 0.58), 0.0],
		["prop_market_thermos", "Thermos", Vector3(-1.1, counter_top, 0.42), 0.4],
		["prop_market_jar_set", "Jars", Vector3(0.7, counter_top, 0.36), -0.15],
		["prop_market_fan", "Fan", Vector3(-0.7, counter_top, 0.36), 0.35],
		["prop_market_freezer", "Freezer", Vector3(1.85, MARKET_FLOOR.y, -1.35), -0.12],
		["prop_market_price_board", "PriceBoard", Vector3(-1.35, 1.75, -2.5), 0.0],
		["prop_hanging_lamp", "HangingLamp", Vector3(0.35, 2.62, 0.25), 0.0],
		["prop_plastic_chair", "ChairA", Vector3(2.15, 0.0, 1.75), -2.3],
		["prop_plastic_chair", "ChairB", Vector3(1.35, 0.0, 2.25), 2.7],
	]
	for placement: Array in placements:
		var scene := load(PROP_PATH % placement[0]) as PackedScene
		if scene == null:
			push_error("environment_builder: missing prop scene %s" % placement[0])
			continue
		var prop: Node3D = scene.instantiate()
		prop.name = placement[1]
		prop.transform = Transform3D(Basis(Vector3.UP, placement[3]), placement[2])
		props.add_child(prop)

	# The warung lamp is already on in the late afternoon (GDD Section 5).
	var lamp_light := OmniLight3D.new()
	lamp_light.name = "LampLight"
	lamp_light.position = Vector3(0.35, 1.95, 0.25)
	lamp_light.light_color = Color(1.0, 0.82, 0.55)
	lamp_light.light_energy = 0.5
	lamp_light.omni_range = 4.0
	lamp_light.shadow_enabled = false
	root.add_child(lamp_light)

	var markers := Node3D.new()
	markers.name = "Markers"
	root.add_child(markers)
	var spots: Dictionary[String, Transform3D] = {
		# Characters face -Z; Bu Yati is turned to face her customers.
		"BuYatiSpot": Transform3D(Basis(Vector3.UP, PI), BU_YATI_SPOT),
		"DartoSpot": Transform3D(Basis(Vector3.UP, deg_to_rad(-24.0)), DARTO_MARKET_SPOT),
		"CameraLandscape": _look(Vector3(1.6, 1.7, 6.4), Vector3(1.73, 1.15, 0.4)),
		"CameraPortrait": _look(Vector3(-0.4, 1.6, 6.6), Vector3(-0.4, -0.45, 0.0)),
	}
	for marker_name: String in spots:
		var marker := Marker3D.new()
		marker.name = marker_name
		marker.transform = spots[marker_name]
		markers.add_child(marker)
	return root


## Packed earth around the warung fading into grass, with the road behind.
func _build_market_ground(random: RandomNumberGenerator) -> ArrayMesh:
	var builder := MeshBuilder.new()
	var step := 1.5
	var half := 21.0
	var points: Array = []
	var count := int(half * 2.0 / step)
	for row: int in count + 1:
		var line := PackedVector3Array()
		for column: int in count + 1:
			var x := -half + column * step
			var z := -half + row * step
			if row > 0 and row < count and column > 0 and column < count:
				x += random.randf_range(-0.4, 0.4)
				z += random.randf_range(-0.4, 0.4)
			line.append(Vector3(x, 0.02 * sin(x * 0.6) * sin(z * 0.5), z))
		points.append(line)
	for row: int in count:
		for column: int in count:
			var corners: Array = [points[row][column], points[row][column + 1], points[row + 1][column + 1], points[row + 1][column]]
			var pairs: Array = [[0, 1, 2], [0, 2, 3]] if (row + column) % 2 == 0 else [[0, 1, 3], [1, 2, 3]]
			for triangle: Array in pairs:
				var a: Vector3 = corners[triangle[0]]
				var b: Vector3 = corners[triangle[1]]
				var c: Vector3 = corners[triangle[2]]
				var centre := (a + b + c) / 3.0
				builder.color = _market_ground_color(centre.x, centre.z, random.randf())
				builder.triangle(a, b, c, Vector3(centre.x, -100.0, centre.z))
	# Beyond the detailed patch a plain skirt carries the grass out into the haze.
	var far := 150.0
	builder.color = GRASS.lerp(FAR_HAZE, 0.3)
	var below := Vector3(0, -100.0, 0)
	builder.quad(Vector3(-far, 0, -far), Vector3(far, 0, -far), Vector3(far, 0, -half), Vector3(-far, 0, -half), below)
	builder.quad(Vector3(-far, 0, half), Vector3(far, 0, half), Vector3(far, 0, far), Vector3(-far, 0, far), below)
	builder.quad(Vector3(-far, 0, -half), Vector3(-half, 0, -half), Vector3(-half, 0, half), Vector3(-far, 0, half), below)
	builder.quad(Vector3(half, 0, -half), Vector3(far, 0, -half), Vector3(far, 0, half), Vector3(half, 0, half), below)
	return builder.commit()


## A hazy line of tree crowns far behind the warung, so the horizon is not bare.
func _build_market_far_trees(random: RandomNumberGenerator) -> ArrayMesh:
	var builder := MeshBuilder.new()
	for index: int in 22:
		var angle := lerpf(-0.35, PI + 0.35, float(index) / 21.0) + random.randf_range(-0.05, 0.05)
		var distance := random.randf_range(46.0, 62.0)
		var size := random.randf_range(5.0, 8.5)
		builder.color = LEAF_DARK.lerp(LEAF, random.randf()).lerp(FAR_HAZE, 0.5)
		builder.blob(Vector3(cos(angle) * distance, size * 0.55, -sin(angle) * distance), Vector3(size * 1.5, size * 0.8, size), 7, 4, 0.18, random.randi())
	return builder.commit()


func _market_ground_color(x: float, z: float, variation: float) -> Color:
	# The road runs past behind the warung.
	if z < -8.0 and z > -11.5:
		return ASPHALT.lightened(variation * 0.08)
	var worn := clampf(1.0 - Vector2(x, z - 0.6).length() / 6.5, 0.0, 1.0)
	var grass := GRASS_DARK.lerp(GRASS_LIGHT, 0.5 + 0.5 * sin(x * 0.3 + 0.7) * sin(z * 0.27)).lerp(GRASS, 0.4)
	return grass.lerp(EARTH.lerp(MUD, 0.25), smoothstep(0.15, 0.6, worn)).lightened((variation - 0.5) * 0.08)


## Floor slab, posts, board walls, tin roof and a back shelf.
func _build_market_shell() -> ArrayMesh:
	var builder := MeshBuilder.new()
	var half_w := MARKET_FLOOR.x * 0.5
	var back := MARKET_FLOOR_CENTRE.z - MARKET_FLOOR.z * 0.5
	var front := MARKET_FLOOR_CENTRE.z + MARKET_FLOOR.z * 0.5
	var top := MARKET_FLOOR.y + MARKET_WALL_HEIGHT

	builder.color = Color("a39683")
	builder.box(MARKET_FLOOR, MARKET_FLOOR_CENTRE)

	builder.color = WOOD.darkened(0.12)
	for corner: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(1, 1)]:
		var z := back + 0.1 if corner.y == 0.0 else front - 0.1
		builder.box(Vector3(0.15, MARKET_WALL_HEIGHT, 0.15), Vector3(corner.x * (half_w - 0.1), MARKET_FLOOR.y + MARKET_WALL_HEIGHT * 0.5, z))
	builder.box(Vector3(MARKET_FLOOR.x, 0.12, 0.12), Vector3(0, top, front - 0.1))
	builder.box(Vector3(MARKET_FLOOR.x, 0.12, 0.12), Vector3(0, top + 0.45, back + 0.1))

	# Back wall of vertical boards in two cream tones, side walls waist-high.
	var boards := 14
	for board: int in boards:
		var x := -half_w + (float(board) + 0.5) * MARKET_FLOOR.x / float(boards)
		builder.color = CREAM.darkened(0.14 if board % 2 == 0 else 0.21)
		builder.box(Vector3(MARKET_FLOOR.x / float(boards) - 0.012, MARKET_WALL_HEIGHT + 0.4, 0.05), Vector3(x, MARKET_FLOOR.y + (MARKET_WALL_HEIGHT + 0.4) * 0.5, back + 0.05))
	builder.color = CREAM.darkened(0.2)
	for side: float in [-1.0, 1.0]:
		builder.box(Vector3(0.05, 1.05, MARKET_FLOOR.z - 0.3), Vector3(side * (half_w - 0.05), MARKET_FLOOR.y + 0.525, MARKET_FLOOR_CENTRE.z))

	# Corrugated tin roof, faded red, sloping down toward the front.
	var sheets := 9
	for sheet: int in sheets:
		var x0 := -half_w - 0.45 + float(sheet) * (MARKET_FLOOR.x + 0.9) / float(sheets)
		var x1 := x0 + (MARKET_FLOOR.x + 0.9) / float(sheets)
		builder.color = FADED_RED.lerp(TERRACOTTA, 0.35).darkened(0.05 if sheet % 2 == 0 else 0.14)
		var upper := PackedVector3Array([
			Vector3(x0, top + 0.62, back - 0.35), Vector3(x1, top + 0.62, back - 0.35),
			Vector3(x1, top + 0.12, front + 0.95), Vector3(x0, top + 0.12, front + 0.95)])
		var lower := PackedVector3Array()
		for point: Vector3 in upper:
			lower.append(point - Vector3(0, 0.05, 0))
		builder.loft([lower, upper], true, true)

	# Shelf on the back wall with a few things on it.
	builder.color = WOOD
	builder.box(Vector3(2.4, 0.04, 0.3), Vector3(0.7, MARKET_FLOOR.y + 1.35, back + 0.22))
	for item: Array in [[0.0, Color("a9534d"), 0.2], [0.35, Color("778b59"), 0.26], [0.7, Color("e4ae55"), 0.16], [1.1, Color("557f7a"), 0.22], [1.45, Color("d9b56a"), 0.18]]:
		builder.color = item[1]
		builder.tube(Vector3(-0.2 + float(item[0]), MARKET_FLOOR.y + 1.37, back + 0.22), Vector3(-0.2 + float(item[0]), MARKET_FLOOR.y + 1.37 + float(item[2]), back + 0.22), 0.07, 0.065, 8, true)

	# A faded banner across the front beam.
	builder.color = Color("e4ae55").darkened(0.05)
	builder.box(Vector3(3.2, 0.42, 0.03), Vector3(-0.3, top - 0.32, front - 0.02))
	builder.color = FADED_RED
	builder.box(Vector3(2.4, 0.07, 0.035), Vector3(-0.3, top - 0.3, front - 0.018))
	return builder.commit()
