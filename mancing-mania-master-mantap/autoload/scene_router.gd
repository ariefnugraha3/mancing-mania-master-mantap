extends Node
## Centralized scene changes with one shared fade (GDD 89, 169.4, 176.3, 176.9).
##
## A route request is ignored while another one is running, so a double tap can
## never start two transitions. Scenes are loaded on a background thread and a
## loading label appears if that takes noticeable time.

signal transition_started(from_scene: StringName, to_scene: StringName)
signal transition_finished(scene_id: StringName)

const SCENE_BOOT := &"boot"
const SCENE_MAIN_MENU := &"main_menu"
const SCENE_FISHING := &"fishing"
const SCENE_MARKET := &"market"
const SCENE_WHEEL := &"wheel"
const SCENE_RESULT := &"result"
const SCENE_STORY := &"story"
const SCENE_CREDITS := &"credits"

## Scene files follow GDD Section 168. A scene that a later milestone has not
## built yet is simply absent on disk; has_scene() reports that.
const SCENE_PATHS: Dictionary[StringName, String] = {
	SCENE_BOOT: "res://scenes/boot/boot.tscn",
	SCENE_MAIN_MENU: "res://scenes/menu/main_menu.tscn",
	SCENE_FISHING: "res://scenes/fishing/fishing.tscn",
	SCENE_MARKET: "res://scenes/market/market.tscn",
	SCENE_WHEEL: "res://scenes/wheel/wheel.tscn",
	&"boxing": "res://scenes/boxing/boxing.tscn",
	&"arm_wrestle": "res://scenes/arm_wrestle/arm_wrestle.tscn",
	&"dance": "res://scenes/dance/dance.tscn",
	&"suwit": "res://scenes/suwit/suwit.tscn",
	&"silat": "res://scenes/silat/silat.tscn",
	&"tambang": "res://scenes/tambang/tambang.tscn",
	&"gasing": "res://scenes/gasing/gasing.tscn",
	&"pinang": "res://scenes/pinang/pinang.tscn",
	SCENE_RESULT: "res://scenes/result/result.tscn",
	SCENE_STORY: "res://scenes/story/story.tscn",
	SCENE_CREDITS: "res://scenes/credits/credits.tscn",
}

const FADE_OUT_SEC := 0.18
const FADE_IN_SEC := 0.24
const FADE_COLOR := Color(0.208, 0.184, 0.161)

var _current_scene_id: StringName = SCENE_BOOT
var _context: Dictionary = {}
var _reload_context: Dictionary = {}
var _busy: bool = false
var _layer: CanvasLayer
var _fade_rect: ColorRect
var _loading_label: Label
## The spinner and LOADING... over the dark screen of every scene change
## (revision 6.12): they show as the screen darkens and fade with it.
var _loading: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	set_process(true)
	# Display settings follow the save: UI and text scale, graphics quality.
	GameState.settings_changed.connect(func(key: StringName) -> void: DisplaySettings.apply_setting(get_tree(), key))
	GameState.state_replaced.connect(func() -> void: DisplaySettings.apply_all(get_tree()))
	# The language right away, so the boot screen's first words are in it.
	DisplaySettings.apply_language()
	DisplaySettings.apply_all.call_deferred(get_tree())


func _process(_delta: float) -> void:
	var dark := _fade_rect.color.a
	_loading.visible = dark > 0.35
	_loading.modulate.a = clampf((dark - 0.35) / 0.5, 0.0, 1.0)


# --- Public API (GDD 169.4) -------------------------------------------------

func goto_main_menu() -> void:
	_route(SCENE_MAIN_MENU, {})


func goto_fishing() -> void:
	_route(SCENE_FISHING, {})


func goto_market() -> void:
	_route(SCENE_MARKET, {})


func goto_wheel(fish_id: StringName) -> void:
	_route(SCENE_WHEEL, {"fish_id": fish_id})


func goto_duel(duel_id: StringName, fish_id: StringName) -> void:
	if not ContentIds.DUEL_IDS.has(duel_id):
		GameLog.error(&"ROUTER", "unknown duel", {"duel": duel_id})
		return
	_route(duel_id, {"duel_id": duel_id, "fish_id": fish_id})


func goto_result(result: Dictionary) -> void:
	_route(SCENE_RESULT, {"result": result})


func goto_story(event_id: StringName) -> void:
	_route(SCENE_STORY, {"event_id": event_id})


## The credits roll. From the Main Menu they return there; after the ending
## they lead on to the post-game unlock (GDD 183.14, 183.15).
func goto_credits(from_menu: bool = false) -> void:
	_route(SCENE_CREDITS, {"from_menu": from_menu})


func reload_current_scene(extra_context: Dictionary = {}) -> void:
	var target := _resolve_current_scene_id()
	if target == &"" or target == SCENE_BOOT:
		return
	var next_reload := {}
	var scene := get_tree().current_scene
	if scene != null and scene.has_method(&"get_reload_context"):
		var preserved: Variant = scene.call(&"get_reload_context")
		if typeof(preserved) == TYPE_DICTIONARY:
			next_reload.merge(preserved as Dictionary, true)
	next_reload.merge(extra_context, true)
	_route(target, _context, next_reload)


## One-shot state preserved across reload_current_scene() (e.g. active tab when
## switching language). Reading it clears it so later scene loads start fresh.
func consume_reload_context() -> Dictionary:
	var copy := _reload_context.duplicate(true)
	_reload_context.clear()
	return copy


func _resolve_current_scene_id() -> StringName:
	if _current_scene_id != SCENE_BOOT and has_scene(_current_scene_id):
		return _current_scene_id
	var scene := get_tree().current_scene
	if scene != null and not scene.scene_file_path.is_empty():
		for scene_id: StringName in SCENE_PATHS:
			if SCENE_PATHS[scene_id] == scene.scene_file_path:
				return scene_id
	return _current_scene_id


# --- Extras -----------------------------------------------------------------

## True when the scene for `scene_id` exists in this build.
func has_scene(scene_id: StringName) -> bool:
	return SCENE_PATHS.has(scene_id) and ResourceLoader.exists(SCENE_PATHS[scene_id])


func get_current_scene_id() -> StringName:
	return _current_scene_id


## What the current scene was opened with (fish_id, duel_id, result, event_id).
func get_context() -> Dictionary:
	return _context.duplicate(true)


func is_transitioning() -> bool:
	return _busy


# --- Internals --------------------------------------------------------------

func _route(scene_id: StringName, context: Dictionary, reload_context: Dictionary = {}) -> void:
	if _busy:
		GameLog.info(&"ROUTER", "ignored route during transition", {"to": scene_id})
		return
	if not has_scene(scene_id):
		GameLog.error(&"ROUTER", "scene is not available in this build", {"scene": scene_id})
		return

	_busy = true
	var from_scene := _current_scene_id
	transition_started.emit(from_scene, scene_id)
	InputManager.set_gameplay_input_enabled(false)
	get_tree().paused = false
	_loading_label.text = TextDb.t(&"common.loading")

	await _fade_to(1.0, FADE_OUT_SEC)
	var packed := await _load_scene(SCENE_PATHS[scene_id])
	if packed == null:
		GameLog.error(&"ROUTER", "scene failed to load", {"scene": scene_id})
		await _fade_to(0.0, FADE_IN_SEC)
		InputManager.set_gameplay_input_enabled(true)
		_busy = false
		return

	_context = context.duplicate(true)
	_reload_context = reload_context.duplicate(true)
	_current_scene_id = scene_id
	get_tree().change_scene_to_packed(packed)
	# The old scene left the tree just now and the new one has not drawn yet:
	# the letters the old one drew are dropped while the screen is black
	# (revision 6.12). Text that stays on screen across scenes redraws.
	UiSkin.release_glyph_caches()
	for node: Node in get_tree().root.get_children():
		node.propagate_call(&"queue_redraw")
	# The swap happens at the end of the frame; wait until the new scene is in.
	await get_tree().process_frame
	await get_tree().process_frame
	if get_tree().current_scene != null:
		DisplaySettings.apply_quality_to(get_tree().current_scene)

	await _fade_to(0.0, FADE_IN_SEC)
	InputManager.set_gameplay_input_enabled(true)
	_busy = false
	GameLog.info(&"ROUTER", "scene changed", {"from": from_scene, "to": scene_id})
	transition_finished.emit(scene_id)


func _load_scene(path: String) -> PackedScene:
	var request_error := ResourceLoader.load_threaded_request(path)
	if request_error != OK:
		return load(path) as PackedScene
	while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
	if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
		return null
	return ResourceLoader.load_threaded_get(path) as PackedScene


func _fade_to(alpha: float, duration: float) -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "color:a", alpha, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if alpha <= 0.0:
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "RouterTransitionLayer"
	_layer.layer = 100
	add_child(_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "FadeRect"
	_fade_rect.color = Color(FADE_COLOR, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_fade_rect)

	_loading = CenterContainer.new()
	_loading.name = "Loading"
	_loading.set_anchors_preset(Control.PRESET_FULL_RECT)
	_loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading.visible = false
	_layer.add_child(_loading)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", 14)
	_loading.add_child(column)
	var spinner := LoadingSpinner.new()
	spinner.name = "Spinner"
	spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(spinner)
	_loading_label = Label.new()
	_loading_label.name = "LoadingLabel"
	_loading_label.text = TextDb.t(&"common.loading")
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.add_theme_color_override(&"font_color", LoadingSpinner.COLOR)
	_loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_loading_label)
