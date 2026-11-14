class_name HudChip
extends RefCounted
## The small cream chips used by the in-game HUDs (GDD 93, 167.9): an icon and
## a value, readable over the 3D scene. The lake and the Market build theirs
## here, so cash looks the same wherever it is shown.


## Background of a chip that is not a button.
static func make_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UiTokens.CREAM_100, 0.94)
	box.border_color = UiTokens.INK_700
	box.set_border_width_all(2)
	box.set_corner_radius_all(UiTokens.RADIUS_BUTTON)
	box.content_margin_left = UiTokens.SPACE_16
	box.content_margin_right = UiTokens.SPACE_16
	box.content_margin_top = UiTokens.SPACE_8
	box.content_margin_bottom = UiTokens.SPACE_8
	return box


## Adds an icon and a label, centred, to a chip or button. Returns the label.
static func add_content(parent: Control, icon_id: StringName) -> Label:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	if parent is Button:
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(row)
	var icon := UiIcon.new()
	icon.icon_id = icon_id
	icon.icon_size = 26.0
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	row.add_child(label)
	return label


## Turns a button into the square Pause button every HUD has top right.
static func make_pause_button(button: GameButton) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(UiTokens.TOUCH_TARGET_PREFERRED, UiTokens.TOUCH_TARGET_PREFERRED)
	button.click_sfx = &"ui_back"
	var icon := UiIcon.new()
	icon.icon_id = UiIcon.ICON_PAUSE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 14.0
	icon.offset_top = 14.0
	icon.offset_right = -14.0
	icon.offset_bottom = -14.0
	button.add_child(icon)
