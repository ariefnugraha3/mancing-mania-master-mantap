@tool
extends RefCounted
## Shared pieces of every generated set and model (VISUAL_STYLE_GUIDE 6, 7):
## the light rig, fake-shadow discs, camera focus markers, ambient motion and
## the small node helpers the builders all need.

const SoftMesh := preload("res://tools/generators/soft_mesh.gd")
const Style := preload("res://scripts/visual/diorama_style.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")
const AmbientMotionScript := preload("res://scripts/visual/ambient_motion.gd")

const SHADOW_CHARACTER_MESH := MaterialBuilder.SHADOW_CHARACTER_MESH
const SHADOW_FURNITURE_MESH := MaterialBuilder.SHADOW_FURNITURE_MESH
const FOCUS_MARKER := "CameraFocus"


# --- Light (guide 6.1) ------------------------------------------------------

## The afternoon light rig: plain vanilla background, warm ambient, one warm
## sun shining the same way the camera looks, and optional interior lamps
## (`lamps` holds [position, range] pairs). No shadow maps, no SSAO, no glow,
## no fog.
static func lighting(lamps: Array = []) -> Node3D:
	var rig := Node3D.new()
	rig.name = "Lighting"

	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Style.VANILLA
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Style.SUN_GOLD
	environment.ambient_light_energy = Style.AMBIENT_ENERGY
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = Style.TONEMAP_WHITE
	environment.ssao_enabled = false
	environment.glow_enabled = false
	environment.fog_enabled = false
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	world_environment.environment = environment
	rig.add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Style.SUN_GOLD
	sun.light_energy = Style.SUN_ENERGY
	sun.shadow_enabled = false
	sun.rotation_degrees = Style.SUN_ROTATION_DEG
	sun.position = Vector3(0.0, 8.0, 0.0)
	rig.add_child(sun)

	for index: int in lamps.size():
		var lamp_spec: Array = lamps[index]
		var lamp := OmniLight3D.new()
		lamp.name = "Lamp%d" % (index + 1)
		lamp.light_color = Style.LAMP_WARM
		lamp.light_energy = Style.LAMP_ENERGY
		lamp.shadow_enabled = false
		lamp.position = lamp_spec[0]
		lamp.omni_range = lamp_spec[1]
		rig.add_child(lamp)
	return rig


## Lamp placements for a rectangular room (guide 6.1): one per 9 m2 of floor,
## at 0.9 x wall height, range max(3, 0.6 x the longest side).
static func room_lamps(floor_min: Vector2, floor_max: Vector2, wall_height: float) -> Array:
	var size := floor_max - floor_min
	var count := maxi(1, int(round(size.x * size.y / Style.LAMP_FLOOR_AREA)))
	var columns := maxi(1, int(round(sqrt(float(count) * size.x / maxf(size.y, 0.01)))))
	var rows := maxi(1, int(ceil(float(count) / float(columns))))
	var reach := maxf(3.0, 0.6 * maxf(size.x, size.y))
	var lamps: Array = []
	for row: int in rows:
		for column: int in columns:
			if lamps.size() >= count:
				break
			var x := floor_min.x + size.x * (float(column) + 0.5) / float(columns)
			var z := floor_min.y + size.y * (float(row) + 0.5) / float(rows)
			lamps.append([Vector3(x, wall_height * Style.LAMP_HEIGHT_RATIO, z), reach])
	return lamps


# --- Fake shadows (guide 6.2) -----------------------------------------------

## A soft disc under someone standing on the floor (radius 0.20 m by default).
static func character_shadow(radius: float = Style.CHARACTER_SHADOW_RADIUS) -> MeshInstance3D:
	var blob := mesh_instance("ShadowBlob", load(SHADOW_CHARACTER_MESH))
	blob.position = Vector3(0.0, Style.CHARACTER_SHADOW_Y, 0.0)
	blob.scale = Vector3(radius, 1.0, radius)
	return blob


## A disc 1.5 x the footprint of a piece of furniture (guide 6.2).
static func furniture_shadow(footprint: Vector2, centre: Vector2 = Vector2.ZERO) -> MeshInstance3D:
	var blob := mesh_instance("ShadowBlob", load(SHADOW_FURNITURE_MESH))
	blob.position = Vector3(centre.x, Style.FURNITURE_SHADOW_Y, centre.y)
	blob.scale = Vector3(footprint.x * 0.5 * Style.FURNITURE_SHADOW_SCALE, 1.0, footprint.y * 0.5 * Style.FURNITURE_SHADOW_SCALE)
	return blob


# --- Nodes --------------------------------------------------------------------

## A static mesh node. Nothing casts a real shadow in this game.
static func mesh_instance(node_name: String, mesh: Mesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Bakes a builder into a node with the shared materials.
static func bake(node_name: String, builder: RefCounted) -> MeshInstance3D:
	return mesh_instance(node_name, builder.commit(MaterialBuilder.surface_materials()))


static func marker(marker_name: String, transform: Transform3D) -> Marker3D:
	var made := Marker3D.new()
	made.name = marker_name
	made.transform = transform
	return made


## Where the camera looks, with its frame width for each layout (guide 2.4).
static func focus_marker(position: Vector3, width_landscape: float, width_portrait: float = Style.WIDTH_DEFAULT, marker_name: String = FOCUS_MARKER) -> Marker3D:
	var made := marker(marker_name, Transform3D(Basis.IDENTITY, position))
	made.set_meta(&"width_landscape", Style.clamp_width(width_landscape))
	made.set_meta(&"width_portrait", Style.clamp_width(width_portrait))
	return made


## An AmbientMotion node. Each entry is [node_path, mode, amplitude, speed,
## phase, axis].
static func motion(entries: Array) -> Node:
	var node := Node.new()
	node.name = "AmbientMotion"
	node.set_script(AmbientMotionScript)
	var targets: Array[NodePath] = []
	var modes := PackedStringArray()
	var params := PackedFloat32Array()
	for entry: Array in entries:
		targets.append(NodePath(entry[0]))
		modes.append(entry[1])
		params.append_array(PackedFloat32Array([entry[2], entry[3], entry[4], entry[5]]))
	node.set("targets", targets)
	node.set("modes", modes)
	node.set("params", params)
	return node


## A checkerboard of two colours on a flat rectangle (curtains, canopies,
## tablecloths, picnic mats): the pattern is geometry, not a texture.
static func checker(builder: RefCounted, origin: Vector3, along_u: Vector3, along_v: Vector3, cells_u: int, cells_v: int, first: Color, second: Color) -> void:
	var step_u := along_u / float(cells_u)
	var step_v := along_v / float(cells_v)
	var keep: Color = builder.color
	for u: int in cells_u:
		for v: int in cells_v:
			builder.color = first if (u + v) % 2 == 0 else second
			var corner := origin + step_u * float(u) + step_v * float(v)
			builder.flat_quad(corner, corner + step_u, corner + step_u + step_v, corner + step_v)
	builder.color = keep
