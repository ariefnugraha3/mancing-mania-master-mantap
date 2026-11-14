extends SceneTree
## Renders the visual reference sheets from the generated assets (GDD 184.14,
## 185.21). The sheets are QA material for the art lock, not runtime content.
##
## Rendering needs a real graphics device, so run this WITHOUT --headless,
## after generate_all_assets.gd:
##   godot --path . --script res://tools/generators/reference_sheet_generator.gd
##
## Model sheets show side, front, back, three-quarter, silhouette and a hero
## pose on neutral cream, with the palette and a scale bar underneath.
## Set sheets are a single shot through the set's own lighting.
##
## The same run renders the Fish Book portraits (GDD 174.9). Unlike the
## sheets those are runtime textures: one fish each on a transparent
## background, so the book can also show them as an ink silhouette.

const Manifest := preload("res://tools/generators/generator_manifest.gd")

const GENERATOR_ID := "reference_sheet_generator"
const GENERATOR_VERSION := 1
const OUTPUT_DIR := "res://generated/references/"
const CELL := 512
const STRIP_HEIGHT := 96
const PORTRAIT_DIR := "res://generated/textures/fish_book/"
const PORTRAIT_SIZE := Vector2i(512, 288)
const FISH_SCENE := "res://generated/scenes/fish/fish_%s.tscn"
const FISH_IDS: Array[String] = [
	"catfish_bruiser", "tilapia_gym_rat", "gourami_shady",
	"carp_golden", "snakehead_sergeant", "arowana_don",
]
const BACKGROUND := Color("fff7e6")
const INK := Color("352f29")

## kind "model": `size` is the height of the framed area in metres and
## `centre` is the point the cameras look at.
const SUBJECTS: Array = [
	{
		"id": "ref_fish_catfish", "kind": "model",
		"scene": "res://generated/scenes/fish/fish_catfish_bruiser.tscn",
		"size": 0.95, "centre": Vector3(0.0, 0.0, 0.0),
		"hero_clip": "fish_challenge", "hero_time": 1.6, "hero_centre": Vector3(0.0, 0.42, 0.0),
		"palette": ["3f463a", "b9b39a", "2c3129", "a4483f", "e9dcc0"],
	},
	{
		"id": "ref_chr_darto", "kind": "model",
		"scene": "res://generated/scenes/characters/chr_darto.tscn",
		"size": 2.0, "centre": Vector3(0.0, 0.88, 0.0), "front_axis": Vector3(0.0, 0.0, -1.0),
		"hero_clip": "idle_fishing", "hero_time": 0.0, "hero_centre": Vector3(0.0, 0.88, 0.0),
		"palette": ["a78d68", "4f554e", "b98a62", "6a6655", "2a2622"],
	},
	{
		"id": "ref_set_lake", "kind": "set",
		"scene": "res://generated/scenes/environment/env_lake_set.tscn",
		"camera_position": Vector3(4.6, 2.5, 9.2), "camera_target": Vector3(-0.6, 0.7, -3.5), "fov": 50.0,
	},
	{
		"id": "ref_chr_bu_yati", "kind": "model",
		"scene": "res://generated/scenes/characters/chr_bu_yati.tscn",
		"size": 1.9, "centre": Vector3(0.0, 0.8, 0.0), "front_axis": Vector3(0.0, 0.0, -1.0),
		"hero_clip": "weigh_fish", "hero_time": 0.9, "hero_centre": Vector3(0.0, 0.8, 0.0),
		"palette": ["7c4a44", "6b6a4b", "d6c4a0", "b08260", "5a554f"],
	},
	{
		"id": "ref_set_market", "kind": "set",
		"scene": "res://generated/scenes/environment/env_market_set.tscn",
		"camera_marker": "Markers/CameraLandscape", "fov": 50.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_bu_yati.tscn", "marker": "Markers/BuYatiSpot", "clip": "market_idle"},
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "market_idle"},
		],
	},
	{
		"id": "ref_set_boxing", "kind": "set",
		"scene": "res://generated/scenes/environment/env_boxing_set.tscn",
		"camera_marker": "Markers/CameraLandscape", "fov": 45.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "box_idle", "show": "AccessoryMeshes/BoxingGloves"},
			{"scene": "res://generated/scenes/fish/fish_catfish_bruiser.tscn", "marker": "Markers/FishSpot", "clip": "box_attack_a", "time": 0.8},
		],
	},
	{
		"id": "ref_set_boxing_portrait", "kind": "set", "size": Vector2i(720, 1280),
		"scene": "res://generated/scenes/environment/env_boxing_set.tscn",
		"camera_marker": "Markers/CameraPortrait", "fov": 55.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "box_dodge_left", "time": 0.12, "show": "AccessoryMeshes/BoxingGloves"},
			{"scene": "res://generated/scenes/fish/fish_arowana_don.tscn", "marker": "Markers/FishSpot", "clip": "box_attack_c", "time": 1.0},
		],
	},
	{
		"id": "ref_set_arm", "kind": "set",
		"scene": "res://generated/scenes/environment/env_arm_set.tscn",
		"camera_marker": "Markers/CameraLandscape", "fov": 45.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "arm_push_hard"},
			{"scene": "res://generated/scenes/fish/fish_carp_golden.tscn", "marker": "Markers/FishSpot", "clip": "arm_burst"},
		],
	},
	{
		"id": "ref_set_dance", "kind": "set",
		"scene": "res://generated/scenes/environment/env_dance_set.tscn",
		"camera_marker": "Markers/CameraLandscape", "fov": 45.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "dance_hit_lane_2", "time": 0.12},
			{"scene": "res://generated/scenes/fish/fish_gourami_shady.tscn", "marker": "Markers/FishSpot", "clip": "dance_great", "time": 0.15},
		],
	},
	{
		"id": "ref_set_suwit", "kind": "set",
		"scene": "res://generated/scenes/environment/env_suwit_set.tscn",
		"camera_marker": "Markers/CameraLandscape", "fov": 45.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "suwit_ready"},
			{"scene": "res://generated/scenes/fish/fish_gourami_shady.tscn", "marker": "Markers/FishSpot", "clip": "suwit_tell_fake", "time": 0.3},
		],
	},
	{
		"id": "ref_fish_lineup", "kind": "set",
		"scene": "res://generated/scenes/environment/env_dance_set.tscn",
		"camera_position": Vector3(0.0, 1.0, 3.2), "camera_target": Vector3(0.0, 0.85, 0.0), "fov": 42.0,
		"lineup": true,
	},
	{
		"id": "ref_set_home", "kind": "set",
		"scene": "res://generated/scenes/environment/env_home_set.tscn",
		"camera_marker": "Markers/CameraWide", "fov": 48.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "market_idle"},
			{"scene": "res://generated/scenes/characters/chr_rini.tscn", "marker": "Markers/RiniSpot", "clip": "put_on_shoes", "time": 1.0},
		],
	},
	{
		"id": "ref_set_market_portrait", "kind": "set", "size": Vector2i(720, 1280),
		"scene": "res://generated/scenes/environment/env_market_set.tscn",
		"camera_marker": "Markers/CameraPortrait", "fov": 50.0,
		"actors": [
			{"scene": "res://generated/scenes/characters/chr_bu_yati.tscn", "marker": "Markers/BuYatiSpot", "clip": "market_idle"},
			{"scene": "res://generated/scenes/characters/chr_darto.tscn", "marker": "Markers/DartoSpot", "clip": "market_idle"},
		],
	},
]

var _viewport: SubViewport
var _camera: Camera3D
var _stage: Node3D


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var manifest: RefCounted = Manifest.read()
	if manifest == null:
		push_error("[REF] run generate_all_assets.gd first: no generator manifest found")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)

	var failures := 0
	for subject: Dictionary in SUBJECTS:
		if not ResourceLoader.exists(subject["scene"]):
			print("[REF] skipped %s (asset not generated yet)" % subject["id"])
			continue
		var image: Image = await _render_subject(subject)
		var output: String = OUTPUT_DIR + subject["id"] + ".png"
		if image == null or image.save_png(output) != OK:
			push_error("[REF] could not render %s" % subject["id"])
			failures += 1
			continue
		manifest.register(subject["id"], GENERATOR_ID, GENERATOR_VERSION, 0, output)
		print("[REF] %s" % output)

	DirAccess.make_dir_recursive_absolute(PORTRAIT_DIR)
	for fish_id: String in FISH_IDS:
		var scene_path := FISH_SCENE % fish_id
		if not ResourceLoader.exists(scene_path):
			print("[REF] skipped portrait %s (fish not generated yet)" % fish_id)
			continue
		var portrait: Image = await _render_portrait(scene_path)
		var portrait_path := "%stex_fishbook_%s.png" % [PORTRAIT_DIR, fish_id]
		if portrait == null or portrait.save_png(portrait_path) != OK:
			push_error("[REF] could not render portrait %s" % fish_id)
			failures += 1
			continue
		manifest.register("tex_fishbook_%s" % fish_id, GENERATOR_ID, GENERATOR_VERSION, 0, portrait_path)
		print("[REF] %s" % portrait_path)

	if not manifest.write():
		failures += 1
	quit(1 if failures > 0 else 0)


func _render_subject(subject: Dictionary) -> Image:
	if subject["kind"] == "set":
		return await _render_set(subject)
	return await _render_model(subject)


# --- Model sheets -----------------------------------------------------------

func _render_model(subject: Dictionary) -> Image:
	_open_stage(Vector2i(CELL, CELL), true)
	var model: Node3D = load(subject["scene"]).instantiate()
	_stage.add_child(model)

	var size: float = subject["size"]
	var centre: Vector3 = subject["centre"]
	# Fish face +X; characters face -Z. "front" always looks at the face.
	var front: Vector3 = subject.get("front_axis", Vector3(1.0, 0.0, 0.0))
	var side := front.cross(Vector3.UP).normalized()
	var sheet := Image.create(CELL * 3, CELL * 2 + STRIP_HEIGHT, false, Image.FORMAT_RGBA8)
	sheet.fill(BACKGROUND)

	var views: Array = [
		[-side, true], [front, true], [-front, true],
		[(front * 0.8 - side * 0.7 + Vector3(0.0, 0.45, 0.0)).normalized(), false],
	]
	for index: int in views.size():
		_aim(centre, views[index][0], size, views[index][1])
		sheet.blit_rect(await _capture(), Rect2i(0, 0, CELL, CELL), Vector2i((index % 3) * CELL, (index / 3) * CELL))

	# Silhouette: the side view in flat ink.
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = INK
	var originals: Dictionary = {}
	for mesh: MeshInstance3D in _mesh_instances(model):
		originals[mesh] = mesh.material_override
		mesh.material_override = ink
	_aim(centre, -side, size, true)
	sheet.blit_rect(await _capture(), Rect2i(0, 0, CELL, CELL), Vector2i(CELL, CELL))
	for mesh: MeshInstance3D in originals:
		mesh.material_override = originals[mesh]

	# Hero pose from one of the model's own clips.
	var player := model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(subject["hero_clip"]):
		player.play(subject["hero_clip"])
		player.seek(subject["hero_time"], true)
		player.pause()
	_aim(subject["hero_centre"], (front * 0.9 - side * 0.5 + Vector3(0.0, 0.3, 0.0)).normalized(), size, false)
	sheet.blit_rect(await _capture(), Rect2i(0, 0, CELL, CELL), Vector2i(CELL * 2, CELL))

	_draw_strip(sheet, subject, size)
	_close_stage()
	return sheet


func _draw_strip(sheet: Image, subject: Dictionary, size: float) -> void:
	var top := CELL * 2
	var swatch := 64
	var x := 24
	for hex: String in subject.get("palette", []):
		sheet.fill_rect(Rect2i(x - 2, top + 14, swatch + 4, swatch + 4), INK)
		sheet.fill_rect(Rect2i(x, top + 16, swatch, swatch), Color(hex))
		x += swatch + 16
	# Scale bar: half a metre at the scale of the orthographic views.
	var pixels_per_metre := float(CELL) / size
	var bar := int(pixels_per_metre * 0.5)
	var bar_x := sheet.get_width() - bar - 32
	sheet.fill_rect(Rect2i(bar_x, top + 44, bar, 6), INK)
	sheet.fill_rect(Rect2i(bar_x, top + 30, 4, 34), INK)
	sheet.fill_rect(Rect2i(bar_x + bar - 4, top + 30, 4, 34), INK)


# --- Set sheets -------------------------------------------------------------

func _render_set(subject: Dictionary) -> Image:
	_open_stage(subject.get("size", Vector2i(1280, 720)), false)
	var set_root: Node3D = load(subject["scene"]).instantiate()
	_stage.add_child(set_root)
	# A line-up of all six fish in their dance pose, gloves off.
	if subject.get("lineup", false):
		var ids: Array[String] = FISH_IDS
		for index: int in ids.size():
			var fish: Node3D = load(FISH_SCENE % ids[index]).instantiate()
			_stage.add_child(fish)
			fish.position = Vector3(-1.75 + 0.7 * float(index), 0.34, 0.0)
			fish.rotation.y = PI
			var gloves := fish.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
			if gloves != null:
				gloves.visible = false
			var fish_player := fish.get_node("AnimationPlayer") as AnimationPlayer
			fish_player.play(&"dance_idle")
			fish_player.seek(0.0, true)
			fish_player.pause()
	# Sets can be shot with their cast standing on the set's own markers.
	for actor: Dictionary in subject.get("actors", []):
		var spot := set_root.get_node_or_null(actor["marker"]) as Node3D
		if spot == null or not ResourceLoader.exists(actor["scene"]):
			continue
		var model: Node3D = load(actor["scene"]).instantiate()
		_stage.add_child(model)
		model.global_transform = spot.global_transform
		var shown := model.get_node_or_null(actor.get("show", "")) as Node3D
		if shown != null:
			shown.visible = true
		var player := model.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if player != null and player.has_animation(actor["clip"]):
			player.play(actor["clip"])
			player.seek(actor.get("time", 0.0), true)
			player.pause()
	_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera.fov = subject["fov"]
	_camera.near = 0.1
	_camera.far = 400.0
	var camera_spot := set_root.get_node_or_null(subject.get("camera_marker", "")) as Node3D
	if camera_spot != null:
		_camera.global_transform = camera_spot.global_transform
	else:
		_camera.look_at_from_position(subject["camera_position"], subject["camera_target"], Vector3.UP)
	var image: Image = await _capture()
	_close_stage()
	return image


# --- Fish Book portraits ----------------------------------------------------

## One fish, facing right and turned slightly toward the viewer, on a
## transparent background. The frame is fitted to the fish itself, so a small
## catfish and Don Arowana fill their portraits equally.
func _render_portrait(scene_path: String) -> Image:
	_open_stage(PORTRAIT_SIZE, true, true)
	var model: Node3D = load(scene_path).instantiate()
	_stage.add_child(model)
	# The book shows the fish as it lives in the lake, without its gloves.
	var gloves := model.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = false
	await process_frame
	var bounds := AABB()
	var first := true
	for mesh: MeshInstance3D in _mesh_instances(model):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var direction := Vector3(0.36, 0.2, 1.0).normalized()
	# An orthographic `size` is the frame height: fit the length to the width.
	var aspect := float(PORTRAIT_SIZE.x) / float(PORTRAIT_SIZE.y)
	var size := maxf((bounds.size.x * 0.97 + bounds.size.z * 0.4) / aspect, bounds.size.y * 1.1) * 1.06
	_aim(bounds.get_center(), direction, size, true)
	var image: Image = await _capture()
	_close_stage()
	return image


# --- Stage ------------------------------------------------------------------

## A private 3D world. Model sheets get neutral cream and a studio light; set
## sheets bring their own environment and sun.
func _open_stage(size: Vector2i, studio: bool, transparent: bool = false) -> void:
	_viewport = SubViewport.new()
	_viewport.size = size
	_viewport.transparent_bg = transparent
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(_viewport)

	_stage = Node3D.new()
	_viewport.add_child(_stage)
	_camera = Camera3D.new()
	_stage.add_child(_camera)
	_camera.current = true
	if not studio:
		return

	var environment := Environment.new()
	# A portrait keeps the viewport's transparent clear colour as background.
	environment.background_mode = Environment.BG_CLEAR_COLOR if transparent else Environment.BG_COLOR
	environment.background_color = BACKGROUND
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 0.97, 0.92)
	environment.ambient_light_energy = 0.75
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	_stage.add_child(world_environment)

	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.95, 0.86)
	key.light_energy = 1.15
	_stage.add_child(key)
	key.look_at_from_position(Vector3(2.0, 3.0, 2.5), Vector3.ZERO, Vector3.UP)


func _close_stage() -> void:
	_viewport.queue_free()
	_viewport = null


## Places the camera `direction` away from `centre`, looking back at it.
func _aim(centre: Vector3, direction: Vector3, size: float, orthographic: bool) -> void:
	if orthographic:
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = size
	else:
		_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		_camera.fov = 30.0
	var distance := size * 2.2
	_camera.near = 0.05
	_camera.far = distance * 4.0
	_camera.look_at_from_position(centre + direction * distance, centre, Vector3.UP)


func _capture() -> Image:
	# Two frames let skinning and the new camera reach the render target.
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := _viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


func _mesh_instances(node: Node) -> Array:
	var found: Array = []
	if node is MeshInstance3D:
		found.append(node)
	for child: Node in node.get_children():
		found.append_array(_mesh_instances(child))
	return found
