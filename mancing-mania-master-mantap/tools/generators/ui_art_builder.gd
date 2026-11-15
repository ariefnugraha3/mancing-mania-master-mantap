@tool
extends RefCounted
## Generates the UI art from code (GDD 184.11): the project Theme built from
## StyleBoxFlat and the design tokens, and the application icon drawn from
## polygons and circles. Nothing here reads an external image; the Theme's
## fonts point at the two licensed font files (GDD 184.12, revision 6.3).

const GeneratorIo := preload("res://tools/generators/generator_io.gd")

const GENERATOR_ID := "ui_art_builder"
const GENERATOR_VERSION := 4

const THEME_PATH := "res://generated/ui/ui_theme.tres"
const ICON_PATH := "res://generated/ui/app_icon.png"
const ICON_SIZE := 512
const ICON_SUPERSAMPLE := 2
const GRABBER_SIZE := 34


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

	var regular := UiSkin.make_body_font(UiTokens.FONT_WEIGHT_REGULAR)
	_set_id(regular, "font_regular")
	theme.default_font = regular
	var bold := UiSkin.make_body_font(UiTokens.FONT_WEIGHT_BOLD)
	_set_id(bold, "font_bold")
	var heavy := UiSkin.make_display_font(bold)
	_set_id(heavy, "font_heavy")

	_style_labels(theme, bold, heavy)
	_style_buttons(theme, bold)
	_style_panels(theme, bold)
	_style_progress_bar(theme, bold)
	_style_slider(theme)
	_style_tabs(theme, bold)
	_style_scrollbars(theme)
	_style_misc(theme)
	return theme


func _style_labels(theme: Theme, bold: FontVariation, heavy: FontVariation) -> void:
	theme.set_color(&"font_color", &"Label", UiTokens.INK_900)
	theme.set_constant(&"line_spacing", &"Label", 6)

	_label_variation(theme, UiTokens.TYPE_TITLE, UiTokens.FONT_HERO, UiTokens.INK_900, heavy)
	_label_variation(theme, UiTokens.TYPE_SCREEN_TITLE, UiTokens.FONT_SCREEN_TITLE, UiTokens.INK_900, heavy)
	_label_variation(theme, UiTokens.TYPE_HEADER, UiTokens.FONT_HEADER, UiTokens.INK_900, bold)
	_label_variation(theme, UiTokens.TYPE_SMALL, UiTokens.FONT_SMALL, UiTokens.INK_700, null)

	# Ribbon title on top of a card: cream letters with a rim of the ribbon colour.
	_label_variation(theme, UiTokens.TYPE_RIBBON_LABEL, UiTokens.FONT_HEADER, UiTokens.CREAM_50, heavy)
	theme.set_color(&"font_outline_color", UiTokens.TYPE_RIBBON_LABEL, UiSkin.edge_of(UiTokens.TERRACOTTA_500))
	theme.set_constant(&"outline_size", UiTokens.TYPE_RIBBON_LABEL, 6)

	# The speaker's name tag on dialogue cards.
	_label_variation(theme, UiTokens.TYPE_NAME_TAG, UiTokens.FONT_BODY + 1, UiTokens.CREAM_50, bold)
	var tag := UiSkin.pill(UiTokens.TERRACOTTA_500, 3, 16, Vector2(UiTokens.SPACE_16, 2.0))
	_set_id(tag, "name_tag")
	theme.set_stylebox(&"normal", UiTokens.TYPE_NAME_TAG, tag)
	theme.set_color(&"font_outline_color", UiTokens.TYPE_NAME_TAG, UiSkin.edge_of(UiTokens.TERRACOTTA_500))
	theme.set_constant(&"outline_size", UiTokens.TYPE_NAME_TAG, 4)

	# Section headers inside long cards (Settings): a small paper tab.
	_label_variation(theme, UiTokens.TYPE_SECTION, UiTokens.FONT_BODY, UiTokens.INK_900, bold)
	var section := UiSkin.pill(UiTokens.PAPER_200, 3, 14, Vector2(UiTokens.SPACE_16, 3.0), 2)
	section.shadow_size = 0
	_set_id(section, "section_tag")
	theme.set_stylebox(&"normal", UiTokens.TYPE_SECTION, section)


func _label_variation(theme: Theme, type_name: StringName, font_size: int, color: Color, font: Font) -> void:
	theme.set_type_variation(type_name, &"Label")
	theme.set_font_size(&"font_size", type_name, font_size)
	theme.set_color(&"font_color", type_name, color)
	if font != null:
		theme.set_font(&"font", type_name, font)


func _style_buttons(theme: Theme, bold: FontVariation) -> void:
	_button_family(theme, &"Button", "button", UiTokens.CREAM_50, UiTokens.INK_900, bold)

	theme.set_type_variation(UiTokens.TYPE_CTA_BUTTON, &"Button")
	_button_family(theme, UiTokens.TYPE_CTA_BUTTON, "cta", UiTokens.TERRACOTTA_500, UiTokens.CREAM_50, bold)

	theme.set_type_variation(UiTokens.TYPE_DANGER_BUTTON, &"Button")
	_button_family(theme, UiTokens.TYPE_DANGER_BUTTON, "danger", UiTokens.RED_500, UiTokens.CREAM_50, bold)

	theme.set_type_variation(UiTokens.TYPE_ACCENT_BUTTON, &"Button")
	_button_family(theme, UiTokens.TYPE_ACCENT_BUTTON, "accent", UiTokens.LAKE_500, UiTokens.CREAM_50, bold)

	# A round cream button for icons only (Pause).
	theme.set_type_variation(UiTokens.TYPE_ROUND_BUTTON, &"Button")
	_button_family(theme, UiTokens.TYPE_ROUND_BUTTON, "round", UiTokens.CREAM_50, UiTokens.INK_900, bold, 30, Vector2(12.0, 8.0))


## One button look in all five interaction states (GDD 167.5): a face, a rim,
## a darker lip that the face sinks into when pressed, and a gold focus ring.
func _button_family(theme: Theme, type_name: StringName, id_prefix: String, fill: Color, text: Color, font: Font,
		radius: int = UiTokens.RADIUS_BUTTON, padding: Vector2 = Vector2(UiTokens.SPACE_24, 9.0)) -> void:
	for state: String in [UiSkin.STATE_NORMAL, UiSkin.STATE_HOVER, UiSkin.STATE_PRESSED, UiSkin.STATE_DISABLED]:
		var box := UiSkin.button_box(fill, state, radius, UiTokens.LIP, padding)
		_set_id(box, "%s_%s" % [id_prefix, state])
		theme.set_stylebox(StringName(state), type_name, box)
		if state == UiSkin.STATE_PRESSED:
			# Hover while held looks like pressed.
			theme.set_stylebox(&"hover_pressed", type_name, box)
	var focus := UiSkin.focus_box(radius)
	_set_id(focus, "%s_focus" % id_prefix)
	theme.set_stylebox(&"focus", type_name, focus)

	theme.set_font(&"font", type_name, font)
	theme.set_font_size(&"font_size", type_name, UiTokens.FONT_BUTTON)
	var light_text := text.get_luminance() > 0.6
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		theme.set_color(color_name, type_name, text)
	# Sticker icons keep their own colours (IconPainter, revision 6.4): white
	# leaves them as drawn, and a faded white draws the muted disabled look.
	for color_name: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_focus_color", &"icon_hover_pressed_color"]:
		theme.set_color(color_name, type_name, Color.WHITE)
	theme.set_color(&"font_disabled_color", type_name, Color(UiTokens.INK_700, 0.55))
	theme.set_color(&"icon_disabled_color", type_name, Color(1.0, 1.0, 1.0, 0.45))
	# Cream letters on a coloured face get a rim of the face colour, like the
	# painted lettering on a cart.
	theme.set_color(&"font_outline_color", type_name, UiSkin.edge_of(fill) if light_text else Color(0, 0, 0, 0))
	theme.set_constant(&"outline_size", type_name, 5 if light_text else 0)
	theme.set_constant(&"h_separation", type_name, UiTokens.SPACE_12)
	theme.set_constant(&"icon_max_width", type_name, 28)


func _style_panels(theme: Theme, bold: FontVariation) -> void:
	var panel := UiSkin.card()
	_set_id(panel, "panel")
	theme.set_stylebox(&"panel", &"PanelContainer", panel)
	theme.set_stylebox(&"panel", &"Panel", panel)

	# A smaller card inside a card (price cards, list rows).
	theme.set_type_variation(UiTokens.TYPE_CARD_PANEL, &"PanelContainer")
	var inner := UiSkin.card(UiTokens.CREAM_50, 18, UiTokens.SPACE_16, 3)
	inner.shadow_size = 6
	inner.shadow_offset = Vector2(0.0, 3.0)
	_set_id(inner, "card_panel")
	theme.set_stylebox(&"panel", UiTokens.TYPE_CARD_PANEL, inner)

	theme.set_type_variation(UiTokens.TYPE_WELL_PANEL, &"PanelContainer")
	var well := UiSkin.well(Color(UiTokens.PAPER_200, 0.7))
	_set_id(well, "well_panel")
	theme.set_stylebox(&"panel", UiTokens.TYPE_WELL_PANEL, well)

	theme.set_type_variation(UiTokens.TYPE_RIBBON_PANEL, &"PanelContainer")
	var ribbon := UiSkin.ribbon()
	_set_id(ribbon, "ribbon_panel")
	theme.set_stylebox(&"panel", UiTokens.TYPE_RIBBON_PANEL, ribbon)

	theme.set_constant(&"separation", &"VBoxContainer", UiTokens.SPACE_12)
	theme.set_constant(&"separation", &"HBoxContainer", UiTokens.SPACE_12)
	theme.set_constant(&"h_separation", &"GridContainer", UiTokens.SPACE_16)
	theme.set_constant(&"v_separation", &"GridContainer", UiTokens.SPACE_12)

	var tooltip := UiSkin.pill(UiTokens.INK_900, 0, 12, Vector2(UiTokens.SPACE_12, UiTokens.SPACE_8))
	_set_id(tooltip, "tooltip")
	theme.set_stylebox(&"panel", &"TooltipPanel", tooltip)
	theme.set_color(&"font_color", &"TooltipLabel", UiTokens.CREAM_50)
	theme.set_font(&"font", &"TooltipLabel", bold)


func _style_progress_bar(theme: Theme, bold: FontVariation) -> void:
	var background := UiSkin.bar_background()
	_set_id(background, "progress_background")
	var fill := UiSkin.bar_fill(UiTokens.LAKE_500)
	_set_id(fill, "progress_fill")
	theme.set_stylebox(&"background", &"ProgressBar", background)
	theme.set_stylebox(&"fill", &"ProgressBar", fill)
	theme.set_color(&"font_color", &"ProgressBar", UiTokens.INK_900)
	theme.set_color(&"font_outline_color", &"ProgressBar", UiTokens.CREAM_50)
	theme.set_constant(&"outline_size", &"ProgressBar", 4)
	theme.set_font(&"font", &"ProgressBar", bold)
	theme.set_font_size(&"font_size", &"ProgressBar", UiTokens.FONT_SMALL)


func _style_slider(theme: Theme) -> void:
	var track := UiSkin.well(UiTokens.PAPER_200, 10, 0.0)
	_set_id(track, "slider_track")
	track.content_margin_top = 7.0
	track.content_margin_bottom = 7.0

	var filled := UiSkin.bar_fill(UiTokens.LAKE_500)
	_set_id(filled, "slider_filled")
	filled.border_width_bottom = 2
	filled.set_corner_radius_all(10)

	theme.set_stylebox(&"slider", &"HSlider", track)
	theme.set_stylebox(&"grabber_area", &"HSlider", filled)
	theme.set_stylebox(&"grabber_area_highlight", &"HSlider", filled)

	theme.set_icon(&"grabber", &"HSlider", _grabber_texture("slider_grabber", UiTokens.TERRACOTTA_500))
	theme.set_icon(&"grabber_highlight", &"HSlider", _grabber_texture("slider_grabber_highlight", UiTokens.SUN_500))
	theme.set_icon(&"grabber_disabled", &"HSlider", _grabber_texture("slider_grabber_disabled", UiTokens.PAPER_200))


## A round slider knob described purely by numbers: a radial gradient with a
## cream centre dot, the knob colour, a darker rim and a transparent outside.
## A parametric texture keeps the saved theme small and byte-identical between
## runs, which embedded pixel data would not.
func _grabber_texture(id: String, fill: Color) -> GradientTexture2D:
	var rim := UiSkin.edge_of(fill)
	var gradient := Gradient.new()
	_set_id(gradient, "%s_gradient" % id)
	gradient.offsets = PackedFloat32Array([0.0, 0.26, 0.32, 0.7, 0.76, 0.9, 0.97])
	gradient.colors = PackedColorArray([UiTokens.CREAM_50, UiTokens.CREAM_50, fill, fill, rim, rim, Color(rim, 0.0)])

	var texture := GradientTexture2D.new()
	_set_id(texture, id)
	texture.gradient = gradient
	texture.width = GRABBER_SIZE
	texture.height = GRABBER_SIZE
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


func _style_tabs(theme: Theme, bold: FontVariation) -> void:
	var selected := UiSkin.tab(true, false, UiTokens.CREAM_50)
	_set_id(selected, "tab_selected")
	var unselected := UiSkin.tab(false, false)
	_set_id(unselected, "tab_unselected")
	var hovered := UiSkin.tab(false, true)
	_set_id(hovered, "tab_hovered")
	var focus := UiSkin.focus_box(16)
	_set_id(focus, "tab_focus")

	for type_name: StringName in [&"TabBar", &"TabContainer"]:
		theme.set_stylebox(&"tab_selected", type_name, selected)
		theme.set_stylebox(&"tab_unselected", type_name, unselected)
		theme.set_stylebox(&"tab_hovered", type_name, hovered)
		theme.set_stylebox(&"tab_focus", type_name, focus)
		theme.set_color(&"font_selected_color", type_name, UiTokens.INK_900)
		theme.set_color(&"font_unselected_color", type_name, UiTokens.INK_700)
		theme.set_color(&"font_hovered_color", type_name, UiTokens.INK_900)
		theme.set_font(&"font", type_name, bold)
		theme.set_font_size(&"font_size", type_name, UiTokens.FONT_SMALL)
		theme.set_constant(&"h_separation", type_name, UiTokens.SPACE_4)

	var body := UiSkin.card(UiTokens.CREAM_50, UiTokens.RADIUS_PANEL, UiTokens.SPACE_16, 4)
	_set_id(body, "tab_panel")
	body.corner_radius_top_left = 0
	# The page sits inside a card whose body scrolls and clips, so it casts
	# no shadow of its own (a clipped shadow reads as a square band).
	body.shadow_size = 0
	theme.set_stylebox(&"panel", &"TabContainer", body)


## Soft rounded scroll bars in the paper colours instead of the engine grey.
func _style_scrollbars(theme: Theme) -> void:
	for type_name: StringName in [&"VScrollBar", &"HScrollBar"]:
		var vertical := type_name == &"VScrollBar"
		var track := StyleBoxFlat.new()
		_set_id(track, "%s_track" % type_name)
		track.bg_color = Color(UiTokens.PAPER_200, 0.7)
		track.set_corner_radius_all(8)
		if vertical:
			track.content_margin_left = 6.0
			track.content_margin_right = 6.0
		else:
			track.content_margin_top = 6.0
			track.content_margin_bottom = 6.0
		theme.set_stylebox(&"scroll", type_name, track)
		theme.set_stylebox(&"scroll_focus", type_name, track)
		for item: Array in [[&"grabber", UiTokens.EDGE_CREAM], [&"grabber_highlight", UiTokens.EDGE_PAPER], [&"grabber_pressed", UiTokens.EDGE_PAPER.darkened(0.1)]]:
			var grab := StyleBoxFlat.new()
			_set_id(grab, "%s_%s" % [type_name, item[0]])
			grab.bg_color = item[1]
			grab.set_corner_radius_all(8)
			grab.anti_aliasing = true
			theme.set_stylebox(item[0], type_name, grab)


func _style_misc(theme: Theme) -> void:
	var separator := StyleBoxLine.new()
	_set_id(separator, "separator")
	separator.color = Color(UiTokens.EDGE_CREAM, 0.8)
	separator.thickness = 3
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
