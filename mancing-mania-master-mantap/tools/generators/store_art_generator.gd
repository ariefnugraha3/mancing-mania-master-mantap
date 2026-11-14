extends SceneTree
## Store graphics from the real game (GDD 186.4-186.6). Run windowed, twice:
##
##   godot --path . --resolution 590x1049 --script res://tools/generators/store_art_generator.gd -- --mode=portrait
##   godot --path . --resolution 1024x500 --script res://tools/generators/store_art_generator.gd -- --mode=feature
##
## Portrait mode writes the icon, the adaptive icon layers and five phone
## screenshots; feature mode writes the 1024x500 feature graphic. Everything
## is a capture of a real scene: nothing is painted or mocked up.
##
## Phone screenshots are 1080x1920. A desktop window cannot be taller than the
## screen, so they are rendered at the largest 9:16 window that fits and
## scaled up; capture them on a 1080x1920 device for the final listing.

const OUT_DIR := "res://build/store/google_play"
const SHOT_SIZE := Vector2i(1080, 1920)
const FEATURE_SIZE := Vector2i(1024, 500)
const ICON_SOURCE := "res://generated/ui/app_icon.png"
const ICON_BACKGROUND := Color("fff7e6")

var _finished: Array[StringName] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var mode := "portrait"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--mode="):
			mode = argument.trim_prefix("--mode=")
	var router: Node = root.get_node("SceneRouter")
	router.transition_finished.connect(func(scene_id: StringName) -> void: _finished.append(scene_id))
	root.get_node("AudioManager").initialize_procedural_audio()
	root.get_node("SaveManager").configure_storage("user://store_art")
	var state: Node = root.get_node("GameState")
	state.new_game()
	var story: Node = root.get_node("StoryDirector")
	for event_id: StringName in [&"story_prologue_zero", &"story_first_fish", &"story_first_market"]:
		story.complete_event(event_id, true)
	for tutorial: StringName in [&"fishing_seen", &"market_seen", &"wheel_seen", &"boxing_seen", &"dance_seen"]:
		state.set_tutorial_seen(tutorial)
	if mode == "feature":
		await _feature(router)
	else:
		_icons()
		await _screenshots(router, state)
	print("[STORE] done ", mode)
	quit(0)


func _icons() -> void:
	var icon := Image.load_from_file(ProjectSettings.globalize_path(ICON_SOURCE))
	icon.convert(Image.FORMAT_RGBA8)
	var store_icon := icon.duplicate() as Image
	store_icon.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	_save(store_icon, "icon_512.png", false)
	# Adaptive icon: plain cream background, the icon inside the safe zone.
	var background := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	background.fill(ICON_BACKGROUND)
	_save(background, "adaptive_background_432.png", false)
	var foreground := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	foreground.fill(Color(0, 0, 0, 0))
	var inner := icon.duplicate() as Image
	inner.resize(288, 288, Image.INTERPOLATE_LANCZOS)
	foreground.blend_rect(inner, Rect2i(Vector2i.ZERO, inner.get_size()), Vector2i(72, 72))
	_save(foreground, "adaptive_foreground_432.png", true)


func _screenshots(router: Node, state: Node) -> void:
	var debug: Node = root.get_node("DebugService")
	state.current_catch = {"fish_id": &"catfish_bruiser", "weight_kg": 2.4, "is_big_one": false, "seed": 11}
	await _go(func() -> void: router.goto_fishing(), &"fishing", 3.0)
	await _capture("screenshot_01_fishing_1080x1920.png")

	debug.set_auto_duel(true)
	await _go(func() -> void: router.goto_duel(&"boxing", &"catfish_bruiser"), &"boxing", 4.2)
	await _capture("screenshot_02_fish_duel_1080x1920.png")

	state.add_bucket_item(&"snakehead_sergeant", 1)
	state.add_bucket_item(&"tilapia_gym_rat", 2)
	state.add_bucket_item(&"trash_sandal", 1)
	await _go(func() -> void: router.goto_market(), &"market", 2.5)
	await _capture("screenshot_03_market_1080x1920.png")

	state.current_catch = {"fish_id": &"tilapia_gym_rat", "weight_kg": 1.1, "is_big_one": false, "seed": 12}
	await _go(func() -> void: router.goto_duel(&"dance", &"tilapia_gym_rat"), &"dance", 10.0)
	await _capture("screenshot_04_dance_1080x1920.png")
	debug.set_auto_duel(false)

	# Fish Book with a few pages filled in.
	state.set_story_value(&"fish_book_unlocked", true)
	for fish_id: StringName in [&"catfish_bruiser", &"tilapia_gym_rat", &"gourami_shady", &"carp_golden"]:
		state.record_encounter(fish_id)
		state.record_fish_win(fish_id, 2.0, &"boxing")
	await _go(func() -> void: router.goto_market(), &"market", 1.0)
	var hud: Node = current_scene.get_node("MarketCanvas")
	hud.select_tab(&"fish_book")
	await _wait(1.0)
	await _capture("screenshot_05_fishbook_1080x1920.png")


func _feature(router: Node) -> void:
	await _go(func() -> void: router.goto_main_menu(), &"main_menu", 2.5)
	# The title over the lake, without the menu buttons.
	for path: String in ["MenuCanvas/SafeRoot/MenuButtons", "MenuCanvas/SafeRoot/VersionLabel"]:
		var node := current_scene.get_node_or_null(path) as CanvasItem
		if node != null:
			node.visible = false
	await _wait(0.4)
	var image := await _grab()
	if image.get_size() != FEATURE_SIZE:
		image.resize(FEATURE_SIZE.x, FEATURE_SIZE.y, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	_save(image, "feature_1024x500.png", false)


func _go(route: Callable, scene_id: StringName, settle_sec: float) -> void:
	var count := _finished.count(scene_id)
	route.call()
	var waited := 0.0
	while _finished.count(scene_id) <= count and waited < 30.0:
		await process_frame
		waited += 1.0 / 60.0
	await _wait(settle_sec)


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < int(seconds * 1000.0):
		await process_frame


func _grab() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _capture(file_name: String) -> void:
	var image := await _grab()
	if image.get_size() != SHOT_SIZE:
		image.resize(SHOT_SIZE.x, SHOT_SIZE.y, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	_save(image, file_name, false)


func _save(image: Image, file_name: String, keep_alpha: bool) -> void:
	if not keep_alpha and image.get_format() == Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGB8)
	var path := ProjectSettings.globalize_path(OUT_DIR.path_join(file_name))
	image.save_png(path)
	print("[STORE] ", path, " ", image.get_size())
