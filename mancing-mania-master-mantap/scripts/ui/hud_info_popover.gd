class_name HudInfoPopover
extends PanelContainer
## Small floating info card shown when the player taps a HUD chip (cash or
## remaining debt). Anchors under the tapped chip inside the safe area and
## dismisses on tap, outside tap, or after a few seconds.

const MAX_WIDTH := 300.0
const AUTO_HIDE_SEC := 4.5
const GAP_Y := 6.0

var _title: Label
var _body: Label
var _anchor: Control
var _time_left: float = 0.0


func _ready() -> void:
	name = "HudInfoPopover"
	visible = false
	z_index = 20
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override(&"panel", _card_style(false))

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	add_child(column)

	_title = Label.new()
	_title.name = "Title"
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_override(&"font", UiSkin.bold_font())
	_title.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(UiTokens.FONT_SMALL))
	column.add_child(_title)

	_body = Label.new()
	_body.name = "Body"
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(UiTokens.FONT_SMALL - 1))
	_body.add_theme_color_override(&"font_color", UiTokens.INK_700)
	column.add_child(_body)

	gui_input.connect(_on_gui_input)


func _process(delta: float) -> void:
	if not visible:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		hide_info()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var point := (event as InputEventMouseButton).position
		# Leave taps on the anchor chip to the chip's gui_input toggle, and
		# taps on the popover itself to _on_gui_input (so it consumes the tap).
		if _contains_viewport_point(_anchor, point) or _contains_viewport_point(self, point):
			return
		hide_info()


## Toggles or switches the floating info card under `anchor`.
func toggle_for(anchor: Control, title: String, body_text: String, warning: bool = false) -> void:
	if visible and _anchor == anchor:
		hide_info()
		return
	show_for(anchor, title, body_text, warning)


func show_for(anchor: Control, title: String, body_text: String, warning: bool = false) -> void:
	_anchor = anchor
	_title.text = title
	_body.text = body_text
	_title.add_theme_color_override(&"font_color", UiTokens.RED_500.darkened(0.2) if warning else UiTokens.INK_900)
	add_theme_stylebox_override(&"panel", _card_style(warning))
	_time_left = AUTO_HIDE_SEC
	visible = true
	AudioManager.play_ui(&"ui_click")
	_place_under_anchor()
	_place_under_anchor.call_deferred()


func hide_info() -> void:
	visible = false
	_anchor = null
	_time_left = 0.0


func get_title_text() -> String:
	return _title.text if visible else ""


func get_body_text() -> String:
	return _body.text if visible else ""


func get_target() -> Control:
	return _anchor if visible else null


func reposition() -> void:
	if visible:
		_place_under_anchor()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		hide_info()


func _place_under_anchor() -> void:
	var host := get_parent() as Control
	if host == null or _anchor == null or not is_instance_valid(_anchor):
		return
	var area := host.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	var width := minf(area.x, MAX_WIDTH)
	custom_minimum_size = Vector2(width, 0.0)
	var anchor_rect := _anchor.get_global_rect()
	var host_rect := host.get_global_rect()
	var local_x := clampf(anchor_rect.position.x - host_rect.position.x, 0.0, maxf(area.x - width, 0.0))
	var below_y := anchor_rect.end.y - host_rect.position.y + GAP_Y
	# Grow downward from just below the chip so wrapped text measures at `width`
	# instead of measuring one character per line before its first layout pass.
	if below_y > area.y * 0.65:
		grow_vertical = Control.GROW_DIRECTION_BEGIN
		var above_y := maxf(anchor_rect.position.y - host_rect.position.y - GAP_Y - 1.0, 0.0)
		UiTokens.place_at(self, Rect2(local_x, above_y, width, 1.0))
	else:
		grow_vertical = Control.GROW_DIRECTION_END
		UiTokens.place_at(self, Rect2(local_x, below_y, width, 1.0))


static func _contains_viewport_point(control: Control, viewport_point: Vector2) -> bool:
	if control == null or not is_instance_valid(control):
		return false
	var local := control.get_global_transform_with_canvas().affine_inverse() * viewport_point
	return Rect2(Vector2.ZERO, control.size).has_point(local)


static func _card_style(warning: bool) -> StyleBoxFlat:
	var fill := UiTokens.TERRACOTTA_500.lerp(UiTokens.CREAM_50, 0.86) if warning else UiTokens.CREAM_50
	var box := UiSkin.card(fill, 16, UiTokens.SPACE_12, 3)
	if warning:
		box.border_color = UiTokens.TERRACOTTA_500
	box.shadow_size = 10
	box.shadow_offset = Vector2(0.0, 4.0)
	return box
