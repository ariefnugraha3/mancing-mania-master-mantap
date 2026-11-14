class_name HudChip
extends RefCounted
## The chips used by the in-game HUDs (GDD 93, 167.9): a cream pill with a
## round coloured badge holding an icon, and a bold value, readable over the
## 3D scene. The lake and the Market build theirs here, so cash looks the same
## wherever it is shown.

const BADGE_SIZE := 38.0

## Badge colour per icon: gold for money, periwinkle for the bucket, crust for
## the Market, teal for the rod.
const BADGE_COLORS: Dictionary = {
	IconPainter.CASH: UiTokens.SUN_500,
	IconPainter.BUCKET: UiTokens.BLUE_400,
	IconPainter.MARKET: UiTokens.TERRACOTTA_500,
	IconPainter.ROD: UiTokens.LAKE_500,
	IconPainter.FISH: UiTokens.LAKE_500,
}


## Background of a chip that is not a button: a pill with a rim and a lip.
## High Contrast HUD (GDD 189.4) makes it opaque with a heavier ink rim.
static func make_style() -> StyleBoxFlat:
	var fill := Color(UiTokens.CREAM_50, 1.0 if UiTokens.is_high_contrast() else 0.95)
	var box := UiSkin.pill(fill, 4, UiTokens.RADIUS_CHIP, Vector2(UiTokens.SPACE_8, 4.0), UiTokens.hud_border(UiTokens.BORDER_WIDTH))
	if UiTokens.is_high_contrast():
		box.border_color = UiTokens.INK_900
	box.content_margin_right = UiTokens.SPACE_16
	return box


## A duel timer chip; urgent time turns it gold with a heavier ink rim.
static func timer_style(urgent: bool) -> StyleBoxFlat:
	var box := make_style()
	box.content_margin_left = UiTokens.SPACE_16
	if urgent:
		box.bg_color = UiTokens.SUN_500
		box.border_color = UiTokens.INK_900
		box.set_border_width_all(4)
		box.border_width_bottom = 8
	return box


## A HUD bar (HP, stamina, strike window): a dark sunken track with a cream
## rim drawn just outside it, and a rounded coloured fill with its own darker
## lip, so the empty part still reads over the lake.
static func style_bar(bar: ProgressBar, fill: Color, radius: int = 11) -> void:
	var rim := UiTokens.hud_border(3)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(UiTokens.INK_900, 0.78 if UiTokens.is_high_contrast() else 0.6)
	back.border_color = UiTokens.CREAM_50
	back.set_border_width_all(rim)
	back.set_expand_margin_all(float(rim))
	back.set_corner_radius_all(radius + rim)
	back.shadow_color = UiTokens.SHADOW
	back.shadow_size = 4
	back.shadow_offset = Vector2(0.0, 2.0)
	back.anti_aliasing = true
	bar.add_theme_stylebox_override(&"background", back)
	var front := UiSkin.bar_fill(fill)
	front.set_corner_radius_all(radius)
	bar.add_theme_stylebox_override(&"fill", front)


## Adds a badged icon and a label, centred, to a chip or button. Returns the label.
static func add_content(parent: Control, icon_id: StringName) -> Label:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	if parent is Button:
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = UiTokens.SPACE_8
		row.offset_right = -UiTokens.SPACE_16
		row.offset_bottom = -float(UiTokens.LIP)
	parent.add_child(row)
	row.add_child(make_badge(icon_id))
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override(&"font", UiSkin.bold_font())
	label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	return label


## A badge over a short bold caption, centred in a square-ish button (the
## Market button of the thumb row). Returns the caption label.
static func add_stacked_content(parent: Control, icon_id: StringName) -> Label:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override(&"separation", 2)
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.offset_bottom = -float(UiTokens.LIP)
	parent.add_child(column)
	var badge := make_badge(icon_id, 34.0)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(badge)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override(&"font", UiSkin.bold_font())
	label.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(UiTokens.FONT_SMALL - 2))
	column.add_child(label)
	return label


## A round coloured badge with an icon in it.
static func make_badge(icon_id: StringName, diameter: float = BADGE_SIZE) -> PanelContainer:
	var fill: Color = BADGE_COLORS.get(icon_id, UiTokens.LAKE_500)
	var badge := PanelContainer.new()
	badge.name = "Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.custom_minimum_size = Vector2(diameter, diameter)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override(&"panel", UiSkin.badge(fill, diameter))
	var icon := UiIcon.new()
	icon.icon_id = icon_id
	icon.icon_size = diameter * 0.62
	icon.tint = UiTokens.INK_900 if fill.get_luminance() > 0.62 else UiTokens.CREAM_50
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_child(icon)
	return badge


## Turns a button into the round Pause button every HUD has top right.
static func make_pause_button(button: GameButton) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.theme_type_variation = UiTokens.TYPE_ROUND_BUTTON
	button.custom_minimum_size = Vector2(UiTokens.TOUCH_TARGET_PREFERRED + 4, UiTokens.TOUCH_TARGET_PREFERRED + 4)
	button.click_sfx = &"ui_back"
	button.icon_id = IconPainter.PAUSE
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override(&"icon_max_width", 26)
