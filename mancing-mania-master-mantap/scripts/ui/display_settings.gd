class_name DisplaySettings
extends RefCounted
## Applies the display settings (GDD 167, 189.2, 189.3, 190.1):
##
## - UI SCALE scales every control, never the 3D world (canvas content scale).
## - TEXT SCALE scales the project theme's font sizes; labels sized in code go
##   through text_size().
## - QUALITY LOW/MEDIUM/HIGH changes 3D resolution, scatter density and
##   anti-aliasing. Art direction stays the same at every level: there are no
##   real shadows at any level, only the fake shadow discs, and no screen
##   effects (VISUAL_STYLE_GUIDE 6.1). MSAA is for desktop only: phones and
##   tablets never use it at any level (revision 6.11, see msaa_for()).
## - On a phone or tablet the game draws at most PHONE_MAX_FPS frames a second,
##   and the 3D world at most `phone_density` pixels per canvas point
##   (revision 6.12, see scale_3d_for_device()). Text and buttons stay sharp:
##   they are drawn at the screen's full resolution.

## `phone_density`: the most 3D pixels per canvas point on a phone or tablet.
## A phone screen packs about 3 pixels into each point; drawing the 3D world
## at every one of them made the GPU fill 3.3 million pixels a frame.
const QUALITY: Dictionary = {
	"low": {"scale_3d": 0.75, "scatter": 0.5, "msaa": Viewport.MSAA_DISABLED, "phone_density": 1.5},
	"medium": {"scale_3d": 1.0, "scatter": 1.0, "msaa": Viewport.MSAA_2X, "phone_density": 2.0},
	"high": {"scale_3d": 1.0, "scatter": 1.0, "msaa": Viewport.MSAA_4X, "phone_density": 2.75},
}
## A phone or tablet never draws more frames than this. Many phones refresh at
## 90 or 120 Hz, and an uncapped game draws every one of those frames: up to
## twice the work, and the heat, for no gain in a game like this one.
const PHONE_MAX_FPS := 60
## The 3D world never drops below this share of the screen's resolution.
const MIN_SCALE_3D := 0.4

static var _base_font_sizes: Dictionary = {}
static var _applied_text_scale: float = 1.0
static var _watching_window: bool = false
## The device language as LANGUAGE "auto" sees it. Empty means ask the OS;
## the test runner pins it so results never depend on the machine.
static var system_language_override: String = ""


static func apply_all(tree: SceneTree) -> void:
	apply_language()
	apply_ui_scale(tree)
	apply_text_scale()
	apply_quality(tree)


static func apply_setting(tree: SceneTree, key: StringName) -> void:
	match key:
		&"ui_scale":
			apply_ui_scale(tree)
		&"text_scale":
			apply_text_scale()
		&"quality_preset":
			apply_quality(tree)
		&"language":
			apply_language()


## LANGUAGE (GDD 133): the chosen language, or for "auto" the device's
## when the game has it (Indonesian for an Indonesian phone), else English.
static func apply_language() -> void:
	TextDb.set_language(resolve_language(str(GameState.get_setting(&"language"))))


static func resolve_language(setting: String) -> String:
	if TextDb.LANGUAGES.has(setting):
		return setting
	var system := system_language_override if not system_language_override.is_empty() else OS.get_locale_language()
	# "in" is the old ISO code for Indonesian that some devices still report.
	if system == "in":
		system = TextDb.INDONESIAN
	return system if TextDb.LANGUAGES.has(system) else TextDb.ENGLISH


static func apply_ui_scale(tree: SceneTree) -> void:
	if tree == null or tree.root == null:
		return
	tree.root.content_scale_factor = float(GameState.get_setting(&"ui_scale"))


## A font size set in code, scaled like the theme's.
static func text_size(base: int) -> int:
	return roundi(float(base) * float(GameState.get_setting(&"text_scale")))


static func apply_text_scale() -> void:
	var theme := ThemeDB.get_project_theme()
	if theme == null:
		return
	if _base_font_sizes.is_empty():
		if theme.default_font_size > 0:
			_base_font_sizes["__default"] = theme.default_font_size
		for type_name: StringName in theme.get_font_size_type_list():
			for size_name: StringName in theme.get_font_size_list(type_name):
				_base_font_sizes["%s/%s" % [type_name, size_name]] = theme.get_font_size(size_name, type_name)
	var scale := float(GameState.get_setting(&"text_scale"))
	if is_equal_approx(scale, _applied_text_scale):
		return
	_applied_text_scale = scale
	for key: String in _base_font_sizes:
		var size := roundi(float(_base_font_sizes[key]) * scale)
		if key == "__default":
			theme.default_font_size = size
		else:
			var parts := key.split("/")
			theme.set_font_size(StringName(parts[1]), StringName(parts[0]), size)


static func get_quality() -> Dictionary:
	return QUALITY.get(str(GameState.get_setting(&"quality_preset")), QUALITY["medium"])


static func apply_quality(tree: SceneTree) -> void:
	if tree == null or tree.root == null:
		return
	var quality := get_quality()
	var root := tree.root
	var on_phone := runs_on_phone()
	root.scaling_3d_scale = scale_3d_for_device(quality, on_phone, pixels_per_point(root))
	root.msaa_3d = msaa_for(quality)
	Engine.max_fps = max_fps_for_device(on_phone)
	# The window settles its size after boot on some devices: the 3D share
	# follows it.
	if not _watching_window:
		_watching_window = true
		root.size_changed.connect(func() -> void: root.scaling_3d_scale = scale_3d_for_device(get_quality(), runs_on_phone(), pixels_per_point(root)))
	# The root viewport is never rendered direct to screen: on Android with the
	# Compatibility renderer that draws the whole game upside down (revision
	# 6.12, seen on a phone).
	if tree.current_scene != null:
		apply_quality_to(tree.current_scene)


## Phones and tablets never get 3D MSAA, whatever the preset (revision 6.11).
## With the Compatibility renderer on mobile GPUs, MSAA makes Godot 4.7 create
## a new framebuffer every frame without freeing the old one; after 2-4
## minutes the app runs out of memory and Android kills it. The device check
## comes before the preset, so no setting can turn MSAA back on there.
static func msaa_for(quality: Dictionary) -> Viewport.MSAA:
	return msaa_for_device(quality, runs_on_phone())


static func msaa_for_device(quality: Dictionary, on_phone: bool) -> Viewport.MSAA:
	if on_phone:
		return Viewport.MSAA_DISABLED
	return quality["msaa"]


## The share of the screen's resolution the 3D world is drawn at. On a phone
## or tablet it is capped at the preset's `phone_density` pixels per canvas
## point (revision 6.12): on a 1220 x 2712 phone, MEDIUM draws the world at
## 64%, about 1.4 million pixels instead of 3.3 million, and the bilinear
## upscale of this soft, flat-coloured art is hard to tell from full size.
## A desktop window keeps the preset's own share.
static func scale_3d_for_device(quality: Dictionary, on_phone: bool, points_to_pixels: float) -> float:
	var scale := float(quality["scale_3d"])
	if on_phone and points_to_pixels > 0.0:
		scale = minf(scale, float(quality["phone_density"]) / points_to_pixels)
	return clampf(scale, MIN_SCALE_3D, 1.0)


## Screen pixels per canvas point at UI SCALE 100% (about 3 on a phone).
static func pixels_per_point(root: Window) -> float:
	var design := Vector2(root.content_scale_size)
	if design.x <= 0.0 or design.y <= 0.0:
		return 1.0
	return maxf(minf(float(root.size.x) / design.x, float(root.size.y) / design.y), 1.0)


## Frames a second the game may draw: PHONE_MAX_FPS on a phone or tablet, no
## cap (0) on a desktop, where the monitor's V-Sync sets the pace.
static func max_fps_for_device(on_phone: bool) -> int:
	return PHONE_MAX_FPS if on_phone else 0


## A phone or tablet: the Android or iOS app, or the Web build in a phone's
## browser.
static func runs_on_phone() -> bool:
	for feature: String in ["mobile", "android", "ios", "web_android", "web_ios"]:
		if OS.has_feature(feature):
			return true
	return false


## Scatter density of a freshly opened scene. Lights never cast real shadows.
static func apply_quality_to(scene: Node) -> void:
	var quality := get_quality()
	for light: Node in scene.find_children("*", "Light3D", true, false):
		(light as Light3D).shadow_enabled = false
	for field: Node in scene.find_children("*", "MultiMeshInstance3D", true, false):
		var multimesh := (field as MultiMeshInstance3D).multimesh
		if multimesh == null:
			continue
		var share := float(quality["scatter"])
		multimesh.visible_instance_count = -1 if share >= 1.0 else int(multimesh.instance_count * share)
