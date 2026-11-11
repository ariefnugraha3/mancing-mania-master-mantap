@tool
extends RefCounted
## Generates the UI art from code (GDD 184.11): the project Theme built from
## StyleBoxFlat and the design tokens, and the application icon drawn from
## polygons and circles. Nothing here reads an external image or font.

const GeneratorIo := preload("res://tools/generators/generator_io.gd")

const GENERATOR_ID := "ui_art_builder"
const GENERATOR_VERSION := 1

const THEME_PATH := "res://generated/ui/ui_theme.tres"
const ICON_PATH := "res://generated/ui/app_icon.png"
const ICON_SIZE := 512
const ICON_SUPERSAMPLE := 2
const GRABBER_SIZE := 28


## Builds every UI asset and records it in `manifest`. Returns error messages.
func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()

	var theme := build_theme()
	var theme_error := GeneratorIo.save_text_resource(theme, THEME_PATH)
	if theme_error != OK:
		errors.append("ui_theme: could not save (%s)" % error_string(theme_error))
	else:
		manifest.register("ui_theme", GENERATOR_ID, GENERATOR_VERSION, 0, THEME_PATH)

	var icon := build_app_icon()
	var icon_error := icon.save_png(ICON_PATH)
	if icon_error != OK:
		errors.append("ui_app_icon: could not save (%s)" % error_string(icon_error))
	else:
		manifest.register("ui_app_icon", GENERATOR_ID, GENERATOR_VERSION, 0, ICON_PATH)
	return errors


# --- Theme ------------------------------------------------------------------

func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = UiTokens.FONT_BODY

	_style_labels(theme)
	_style_buttons(theme)
	_style_panels(theme)
	_style_progress_bar(theme)
	_style_slider(theme)
	_style_tabs(theme)
	_style_misc(theme)
	return theme


func _style_labels(theme: Theme) -> void:
	theme.set_color(&"font_color", &"Label", UiTokens.INK_900)
	theme.set_constant(&"line_spacing", &"Label", 6)

	_label_variation(theme, UiTokens.TYPE_TITLE, UiTokens.FONT_HERO, UiTokens.INK_900)
	_label_variation(theme, UiTokens.TYPE_SCREEN_TITLE, UiTokens.FONT_SCREEN_TITLE, UiTokens.INK_900)
	_label_variation(theme, UiTokens.TYPE_HEADER, UiTokens.FONT_HEADER, UiTokens.INK_900)
	_label_variation(theme, UiTokens.TYPE_SMALL, UiTokens.FONT_SMALL, UiTokens.INK_700)


func _label_variation(theme: Theme, type_name: StringName, font_size: int, color: Color) -> void:
	theme.set_type_variation(type_name, &"Label")
	theme.set_font_size(&"font_size", type_name, font_size)
	theme.set_color(&"font_color", type_name, color)


func _style_buttons(theme: Theme) -> void:
	_button_family(theme, &"Button", "button", UiTokens.CREAM_50, UiTokens.INK_900)

	theme.set_type_variation(UiTokens.TYPE_CTA_BUTTON, &"Button")
	_button_family(theme, UiTokens.TYPE_CTA_BUTTON, "cta", UiTokens.TERRACOTTA_500, UiTokens.CREAM_50)

	theme.set_type_variation(UiTokens.TYPE_DANGER_BUTTON, &"Button")
	_button_family(theme, UiTokens.TYPE_DANGER_BUTTON, "danger", UiTokens.RED_500, UiTokens.CREAM_50)


## One button look in all five interaction states (GDD 167.5).
func _button_family(theme: Theme, type_name: StringName, id_prefix: String, fill: Color, text: Color) -> void:
	var is_light := fill.get_luminance() > 0.6
	var hover_fill := fill.lerp(UiTokens.SUN_500, 0.3) if is_light else fill.lightened(0.12)
	var pressed_fill := UiTokens.PAPER_200 if is_light else fill.darkened(0.16)

	var normal := _button_box("%s_normal" % id_prefix, fill, UiTokens.INK_700, 3)
	var hover := _button_box("%s_hover" % id_prefix, hover_fill, UiTokens.INK_900, 3)
	var pressed := _button_box("%s_pressed" % id_prefix, pressed_fill, UiTokens.INK_900, 0)
	# A pressed button sinks by the height of the shadow it just lost.
	pressed.content_margin_top += 2.0
	pressed.content_margin_bottom -= 2.0
	var disabled := _button_box(
		"%s_disabled" % id_prefix,
		Color(UiTokens.CREAM_100, 0.55),
		Color(UiTokens.INK_700, 0.35),
		0)

	var focus := StyleBoxFlat.new()
	_set_id(focus, "%s_focus" % id_prefix)
	focus.draw_center = false
	focus.border_color = UiTokens.LAKE_500
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(UiTokens.RADIUS_BUTTON + 3)
	focus.set_expand_margin_all(4.0)

	theme.set_stylebox(&"normal", type_name, normal)
	theme.set_stylebox(&"hover", type_name, hover)
	theme.set_stylebox(&"pressed", type_name, pressed)
	theme.set_stylebox(&"disabled", type_name, disabled)
	theme.set_stylebox(&"focus", type_name, focus)

	theme.set_font_size(&"font_size", type_name, UiTokens.FONT_BUTTON)
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		theme.set_color(color_name, type_name, text)
	if is_light:
		theme.set_color(&"font_disabled_color", type_name, Color(UiTokens.INK_700, 0.6))
	else:
		theme.set_color(&"font_disabled_color", type_name, Color(UiTokens.INK_700, 0.6))


func _button_box(id: String, fill: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	_set_id(box, id)
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(UiTokens.BORDER_WIDTH)
	box.set_corner_radius_all(UiTokens.RADIUS_BUTTON)
	box.content_margin_left = UiTokens.SPACE_24
	box.content_margin_right = UiTokens.SPACE_24
	box.content_margin_top = UiTokens.SPACE_12
	box.content_margin_bottom = UiTokens.SPACE_12
	if shadow_size > 0:
		box.shadow_color = Color(UiTokens.INK_900, 0.22)
		box.shadow_size = shadow_size
		box.shadow_offset = Vector2(0.0, 2.0)
	box.anti_aliasing = true
	return box


func _style_panels(theme: Theme) -> void:
	var panel := StyleBoxFlat.new()
	_set_id(panel, "panel")
	panel.bg_color = UiTokens.CREAM_100
	panel.border_color = UiTokens.INK_700
	panel.set_border_width_all(UiTokens.BORDER_WIDTH)
	panel.set_corner_radius_all(UiTokens.RADIUS_PANEL)
	panel.set_content_margin_all(UiTokens.SPACE_24)
	panel.shadow_color = Color(UiTokens.INK_900, 0.2)
	panel.shadow_size = 8
	panel.shadow_offset = Vector2(0.0, 4.0)
	theme.set_stylebox(&"panel", &"PanelContainer", panel)
	theme.set_stylebox(&"panel", &"Panel", panel)

	theme.set_constant(&"separation", &"VBoxContainer", UiTokens.SPACE_12)
	theme.set_constant(&"separation", &"HBoxContainer", UiTokens.SPACE_12)
	theme.set_constant(&"h_separation", &"GridContainer", UiTokens.SPACE_16)
	theme.set_constant(&"v_separation", &"GridContainer", UiTokens.SPACE_12)


func _style_progress_bar(theme: Theme) -> void:
	var background := StyleBoxFlat.new()
	_set_id(background, "progress_background")
	background.bg_color = UiTokens.PAPER_200
	background.border_color = UiTokens.INK_700
	background.set_border_width_all(UiTokens.BORDER_WIDTH)
	background.set_corner_radius_all(8)

	var fill := StyleBoxFlat.new()
	_set_id(fill, "progress_fill")
	fill.bg_color = UiTokens.LAKE_500
	fill.border_color = UiTokens.INK_700
	fill.set_border_width_all(UiTokens.BORDER_WIDTH)
	fill.set_corner_radius_all(8)

	theme.set_stylebox(&"background", &"ProgressBar", background)
	theme.set_stylebox(&"fill", &"ProgressBar", fill)
	theme.set_color(&"font_color", &"ProgressBar", UiTokens.INK_900)
	theme.set_font_size(&"font_size", &"ProgressBar", UiTokens.FONT_SMALL)


func _style_slider(theme: Theme) -> void:
	var track := StyleBoxFlat.new()
	_set_id(track, "slider_track")
	track.bg_color = UiTokens.PAPER_200
	track.border_color = UiTokens.INK_700
	track.set_border_width_all(1)
	track.set_corner_radius_all(5)
	track.content_margin_top = 5.0
	track.content_margin_bottom = 5.0

	var filled := StyleBoxFlat.new()
	_set_id(filled, "slider_filled")
	filled.bg_color = UiTokens.LAKE_500
	filled.set_corner_radius_all(5)

	theme.set_stylebox(&"slider", &"HSlider", track)
	theme.set_stylebox(&"grabber_area", &"HSlider", filled)
	theme.set_stylebox(&"grabber_area_highlight", &"HSlider", filled)

	theme.set_icon(&"grabber", &"HSlider", _grabber_texture("slider_grabber", UiTokens.TERRACOTTA_500))
	theme.set_icon(&"grabber_highlight", &"HSlider", _grabber_texture("slider_grabber_highlight", UiTokens.SUN_500))
	theme.set_icon(&"grabber_disabled", &"HSlider", _grabber_texture("slider_grabber_disabled", UiTokens.PAPER_200))


## A round slider handle described purely by numbers: a radial gradient that is
## solid fill in the middle, an ink ring near the rim and transparent outside.
## A parametric texture keeps the saved theme small and byte-identical between
## runs, which embedded pixel data would not.
func _grabber_texture(id: String, fill: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	_set_id(gradient, "%s_gradient" % id)
	gradient.offsets = PackedFloat32Array([0.0, 0.72, 0.8, 0.9, 0.97])
	gradient.colors = PackedColorArray([fill, fill, UiTokens.INK_900, UiTokens.INK_900, Color(UiTokens.INK_900, 0.0)])

	var texture := GradientTexture2D.new()
	_set_id(texture, id)
	texture.gradient = gradient
	texture.width = GRABBER_SIZE
	texture.height = GRABBER_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _style_tabs(theme: Theme) -> void:
	var selected := _tab_box("tab_selected", UiTokens.CREAM_50, UiTokens.INK_900)
	var unselected := _tab_box("tab_unselected", UiTokens.PAPER_200, Color(UiTokens.INK_700, 0.6))
	var hovered := _tab_box("tab_hovered", UiTokens.PAPER_200.lerp(UiTokens.SUN_500, 0.3), UiTokens.INK_700)
	var focus := StyleBoxFlat.new()
	_set_id(focus, "tab_focus")
	focus.draw_center = false
	focus.border_color = UiTokens.LAKE_500
	focus.set_border_width_all(3)
	focus.set_corner_radius_all(UiTokens.RADIUS_BUTTON)

	for type_name: StringName in [&"TabBar", &"TabContainer"]:
		theme.set_stylebox(&"tab_selected", type_name, selected)
		theme.set_stylebox(&"tab_unselected", type_name, unselected)
		theme.set_stylebox(&"tab_hovered", type_name, hovered)
		theme.set_stylebox(&"tab_focus", type_name, focus)
		theme.set_color(&"font_selected_color", type_name, UiTokens.INK_900)
		theme.set_color(&"font_unselected_color", type_name, UiTokens.INK_700)
		theme.set_color(&"font_hovered_color", type_name, UiTokens.INK_900)
		theme.set_font_size(&"font_size", type_name, UiTokens.FONT_SMALL)
		theme.set_constant(&"h_separation", type_name, UiTokens.SPACE_4)

	var body := StyleBoxFlat.new()
	_set_id(body, "tab_panel")
	body.bg_color = UiTokens.CREAM_50
	body.border_color = UiTokens.INK_700
	body.set_border_width_all(UiTokens.BORDER_WIDTH)
	body.set_corner_radius_all(UiTokens.RADIUS_BUTTON)
	body.corner_radius_top_left = 0
	body.set_content_margin_all(UiTokens.SPACE_16)
	theme.set_stylebox(&"panel", &"TabContainer", body)


func _tab_box(id: String, fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	_set_id(box, id)
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(UiTokens.BORDER_WIDTH)
	box.border_width_bottom = 0
	box.corner_radius_top_left = UiTokens.RADIUS_BUTTON
	box.corner_radius_top_right = UiTokens.RADIUS_BUTTON
	box.content_margin_left = UiTokens.SPACE_12
	box.content_margin_right = UiTokens.SPACE_12
	box.content_margin_top = UiTokens.SPACE_12
	box.content_margin_bottom = UiTokens.SPACE_12
	return box


func _style_misc(theme: Theme) -> void:
	var separator := StyleBoxLine.new()
	_set_id(separator, "separator")
	separator.color = Color(UiTokens.INK_700, 0.35)
	separator.thickness = 2
	theme.set_stylebox(&"separator", &"HSeparator", separator)
	theme.set_constant(&"separation", &"HSeparator", UiTokens.SPACE_12)


## Fixed sub-resource IDs keep the saved .tres identical between runs.
func _set_id(resource: Resource, id: String) -> void:
	resource.resource_scene_unique_id = id


# --- Application icon -------------------------------------------------------

## Warm cream sky over the lake, with a low-poly fish wearing a boxing glove
## (GDD 186.4). Drawn oversized and scaled down for smooth edges.
func build_app_icon() -> Image:
	var size := ICON_SIZE * ICON_SUPERSAMPLE
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var unit := float(size)
	var horizon := int(unit * 0.60)

	# Sky: cream at the top warming toward the horizon.
	var sky_low := UiTokens.CREAM_100.lerp(UiTokens.SUN_500, 0.35)
	for y: int in horizon:
		var blend := float(y) / float(horizon)
		image.fill_rect(Rect2i(0, y, size, 1), UiTokens.CREAM_50.lerp(sky_low, blend * blend))

	_fill_circle(image, Vector2(0.73, 0.27) * unit, 0.125 * unit, UiTokens.SUN_500)

	# Lake with a lighter band under the horizon and a few ripple strokes.
	var lake_deep := UiTokens.LAKE_500.darkened(0.12)
	for y: int in range(horizon, size):
		var blend := float(y - horizon) / float(size - horizon)
		image.fill_rect(Rect2i(0, y, size, 1), UiTokens.LAKE_500.lightened(0.14).lerp(lake_deep, blend))
	var ripple := Color(UiTokens.CREAM_50, 1.0).lerp(UiTokens.LAKE_500, 0.45)
	for stroke: Vector3 in [Vector3(0.10, 0.70, 0.22), Vector3(0.58, 0.76, 0.26), Vector3(0.22, 0.86, 0.30), Vector3(0.66, 0.92, 0.16)]:
		_fill_capsule(image, Vector2(stroke.x, stroke.y) * unit, stroke.z * unit, 0.011 * unit, ripple)

	# Splash where the fish left the water.
	for drop: Vector3 in [Vector3(0.30, 0.585, 0.030), Vector3(0.39, 0.60, 0.040), Vector3(0.49, 0.59, 0.030), Vector3(0.235, 0.555, 0.018), Vector3(0.555, 0.55, 0.016)]:
		_fill_circle(image, Vector2(drop.x, drop.y) * unit, drop.z * unit, UiTokens.CREAM_50)

	_draw_fish(image, unit)
	_round_corners(image, 0.19 * unit)
	image.resize(ICON_SIZE, ICON_SIZE, Image.INTERPOLATE_LANCZOS)
	return image


func _draw_fish(image: Image, unit: float) -> void:
	var transform := Transform2D(deg_to_rad(-24.0), Vector2(0.47, 0.40) * unit)
	var scale := unit * 1.28
	var body_color := UiTokens.TERRACOTTA_500
	var belly_color := UiTokens.TERRACOTTA_500.lightened(0.28)
	var fin_color := UiTokens.TERRACOTTA_500.darkened(0.24)

	var tail := [Vector2(-0.185, 0.0), Vector2(-0.325, -0.105), Vector2(-0.285, 0.0), Vector2(-0.325, 0.11)]
	var dorsal := [Vector2(-0.06, -0.085), Vector2(0.015, -0.165), Vector2(0.105, -0.09)]
	var body := [
		Vector2(-0.205, 0.0), Vector2(-0.085, -0.085), Vector2(0.08, -0.095), Vector2(0.20, -0.045),
		Vector2(0.24, 0.01), Vector2(0.19, 0.062), Vector2(0.06, 0.097), Vector2(-0.09, 0.077),
	]
	var belly := [Vector2(-0.09, 0.077), Vector2(0.06, 0.097), Vector2(0.19, 0.062), Vector2(0.105, 0.022), Vector2(-0.07, 0.024)]
	var gill := [Vector2(0.085, -0.06), Vector2(0.10, -0.01), Vector2(0.085, 0.045), Vector2(0.07, -0.01)]

	_fill_polygon(image, _place(tail, transform, scale), fin_color)
	_fill_polygon(image, _place(dorsal, transform, scale), fin_color)
	_fill_polygon(image, _place(body, transform, scale), body_color)
	_fill_polygon(image, _place(belly, transform, scale), belly_color)
	_fill_polygon(image, _place(gill, transform, scale), fin_color)

	_fill_circle(image, transform * (Vector2(0.158, -0.028) * scale), 0.021 * scale, UiTokens.CREAM_50)
	_fill_circle(image, transform * (Vector2(0.163, -0.028) * scale), 0.010 * scale, UiTokens.INK_900)

	# Boxing glove: cuff, fist and thumb.
	var cuff := [Vector2(0.045, 0.085), Vector2(0.085, 0.068), Vector2(0.105, 0.112), Vector2(0.066, 0.13)]
	_fill_polygon(image, _place(cuff, transform, scale), UiTokens.CREAM_50)
	var glove_color := UiTokens.RED_500.lightened(0.06)
	_fill_circle(image, transform * (Vector2(0.142, 0.118) * scale), 0.066 * scale, glove_color)
	_fill_circle(image, transform * (Vector2(0.192, 0.078) * scale), 0.030 * scale, glove_color)
	_fill_circle(image, transform * (Vector2(0.122, 0.098) * scale), 0.018 * scale, UiTokens.RED_500.lightened(0.3))


func _place(points: Array, transform: Transform2D, scale: float) -> PackedVector2Array:
	var placed := PackedVector2Array()
	for point: Vector2 in points:
		placed.append(transform * (point * scale))
	return placed


func _fill_polygon(image: Image, polygon: PackedVector2Array, color: Color) -> void:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point: Vector2 in polygon:
		bounds = bounds.expand(point)
	var area := Rect2i(bounds.grow(1.0)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), polygon):
				image.set_pixel(x, y, color)


func _fill_circle(image: Image, centre: Vector2, radius: float, color: Color) -> void:
	var area := Rect2i(Rect2(centre - Vector2(radius, radius), Vector2(radius, radius) * 2.0).grow(1.0))
	area = area.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var radius_squared := radius * radius
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			if (Vector2(x + 0.5, y + 0.5) - centre).length_squared() <= radius_squared:
				image.set_pixel(x, y, color)


## A horizontal stroke with round ends, starting at `start`.
func _fill_capsule(image: Image, start: Vector2, length: float, radius: float, color: Color) -> void:
	image.fill_rect(Rect2i(Rect2(start - Vector2(0.0, radius), Vector2(length, radius * 2.0))), color)
	_fill_circle(image, start, radius, color)
	_fill_circle(image, start + Vector2(length, 0.0), radius, color)


## Makes everything outside a rounded square transparent.
func _round_corners(image: Image, radius: float) -> void:
	var size := image.get_width()
	var limit := int(ceil(radius))
	for y: int in limit:
		for x: int in limit:
			var offset := Vector2(radius - (x + 0.5), radius - (y + 0.5))
			if offset.length() <= radius:
				continue
			for corner: Vector2i in [Vector2i(x, y), Vector2i(size - 1 - x, y), Vector2i(x, size - 1 - y), Vector2i(size - 1 - x, size - 1 - y)]:
				image.set_pixel(corner.x, corner.y, Color(0.0, 0.0, 0.0, 0.0))
