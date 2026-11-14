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
##   effects (VISUAL_STYLE_GUIDE 6.1). HIGH uses 4x MSAA on desktop and 2x on
##   phones, as the guide asks.

const QUALITY: Dictionary = {
	"low": {"scale_3d": 0.75, "scatter": 0.5, "msaa": Viewport.MSAA_DISABLED},
	"medium": {"scale_3d": 1.0, "scatter": 1.0, "msaa": Viewport.MSAA_2X},
	"high": {"scale_3d": 1.0, "scatter": 1.0, "msaa": Viewport.MSAA_4X},
}

static var _base_font_sizes: Dictionary = {}
static var _applied_text_scale: float = 1.0


static func apply_all(tree: SceneTree) -> void:
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
	root.scaling_3d_scale = float(quality["scale_3d"])
	root.msaa_3d = msaa_for(quality)
	if tree.current_scene != null:
		apply_quality_to(tree.current_scene)


## Phones and tablets cap anti-aliasing at 2x (VISUAL_STYLE_GUIDE 6.1).
static func msaa_for(quality: Dictionary) -> Viewport.MSAA:
	var wanted: Viewport.MSAA = quality["msaa"]
	if OS.has_feature("mobile") and wanted > Viewport.MSAA_2X:
		return Viewport.MSAA_2X
	return wanted


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
