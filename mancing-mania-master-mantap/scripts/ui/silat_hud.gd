class_name SilatHud
extends SpotDuelHud
## Silat HUD (revision 6.7): the score dots, a card where the fish's moves
## appear one at a time, a row of slots for the sequence, the answer clock
## and four big arrow buttons along the bottom.
##
## Each move is an arrow and a word, so nothing depends on colour, and the
## arrows sit in the same order as the keys (S D J K).

const ICONS: Dictionary[StringName, StringName] = {
	SilatController.LEFT: IconPainter.ARROW_LEFT,
	SilatController.DOWN: IconPainter.ARROW_DOWN,
	SilatController.UP: IconPainter.ARROW_UP,
	SilatController.RIGHT: IconPainter.ARROW_RIGHT,
}
const ACTIONS: Dictionary[StringName, StringName] = {
	SilatController.LEFT: &"dance_lane_1",
	SilatController.DOWN: &"dance_lane_2",
	SilatController.UP: &"dance_lane_3",
	SilatController.RIGHT: &"dance_lane_4",
}
const SLOT_SIZE := 30.0

var _status: Label
var _card: PanelContainer
var _card_icon: UiIcon
var _card_label: Label
var _slots: HBoxContainer
var _clock: ProgressBar
var _buttons: Dictionary[StringName, GameButton] = {}


func _build() -> void:
	_build_dots(SilatController.POINTS_REQUIRED)
	_status = _outlined(30, DioramaStyle.BUTTER)
	_card = PanelContainer.new()
	_card.name = "MoveCard"
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_stylebox_override(&"panel", UiSkin.card(UiTokens.CREAM_50, 22, UiTokens.SPACE_12, 3))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(column)
	_card_icon = UiIcon.new()
	_card_icon.icon_size = 84.0
	_card_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_card_icon)
	_card_label = Label.new()
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	_card_label.add_theme_font_override(&"font", UiSkin.bold_font())
	_card_label.add_theme_color_override(&"font_color", UiTokens.INK_900)
	column.add_child(_card_label)
	_safe_root.add_child(_card)
	_card.visible = false
	_slots = HBoxContainer.new()
	_slots.name = "Slots"
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slots.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	_safe_root.add_child(_slots)
	_clock = ProgressBar.new()
	_clock.name = "AnswerClock"
	_clock.show_percentage = false
	_clock.max_value = 1.0
	_clock.step = 0.0
	_clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudChip.style_bar(_clock, UiTokens.SUN_500)
	_safe_root.add_child(_clock)
	for move: StringName in SilatController.MOVES:
		var button := _action_button("%sButton" % String(move).capitalize(), TextDb.t(StringName("silat.move.%s" % move)), ICONS[move], ACTIONS[move], false)
		button.add_theme_font_size_override(&"font_size", UiTokens.FONT_SMALL)
		_buttons[move] = button


func refresh(snapshot: Dictionary) -> void:
	if not snapshot.has("player_points"):
		return
	_refresh_dots(int(snapshot["player_points"]), int(snapshot["fish_points"]))
	var state: StringName = snapshot["state"]
	var showing := state == SilatController.STATE_SHOW
	var answering := state == SilatController.STATE_INPUT
	_status.visible = showing or answering
	_status.text = TextDb.t(&"silat.watch" if showing else &"silat.your_turn")
	var move: StringName = snapshot["show_move"]
	_card.visible = showing and move != &""
	if move != &"":
		_card_icon.icon_id = ICONS[move]
		_card_label.text = TextDb.t(StringName("silat.move.%s" % move))
	_set_slots(int(snapshot["sequence_length"]), int(snapshot["show_index"]) + 1 if showing else int(snapshot["input_index"]), showing)
	_slots.visible = showing or answering
	_clock.visible = answering
	if answering:
		_clock.value = float(snapshot["time_left"]) / maxf(float(snapshot["window_sec"]), 0.01)
	for key: StringName in _buttons:
		_buttons[key].disabled = not answering


func get_move_button(move: StringName) -> GameButton:
	return _buttons[move]


func get_status_text() -> String:
	return _status.text if _status.visible else ""


## Slots show how long the sequence is and how far along it is: filled for
## shown or answered moves, hollow for the rest.
func _set_slots(count: int, filled: int, showing: bool) -> void:
	while _slots.get_child_count() < count:
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots.add_child(slot)
	for index: int in _slots.get_child_count():
		var slot := _slots.get_child(index) as Panel
		slot.visible = index < count
		var tone := UiTokens.SUN_500 if showing else UiTokens.GRASS_500
		_style_dot(slot, index < filled, tone)


func _keys_text() -> String:
	return TextDb.tf(&"silat.keys", {
		"left": _key(&"dance_lane_1"), "down": _key(&"dance_lane_2"), "up": _key(&"dance_lane_3"), "right": _key(&"dance_lane_4")})


func _keys_bottom(area: Vector2) -> float:
	return area.y - _button_height(area) - UiTokens.SPACE_8


func _button_height(area: Vector2) -> float:
	return clampf(roundf(area.y * 0.16), 110.0, 150.0)


func _arrange(area: Vector2, top: float) -> void:
	var gap := 12.0
	var row_width := minf(area.x, 600.0)
	var height := _button_height(area)
	var width := (row_width - gap * 3.0) / 4.0
	var left := (area.x - row_width) * 0.5
	var index := 0
	for move: StringName in SilatController.MOVES:
		_place(_buttons[move], Rect2(left + float(index) * (width + gap), area.y - height, width, height))
		index += 1
	var above := area.y - height - 40.0
	_place(_clock, Rect2((area.x - minf(area.x, 360.0)) * 0.5, above - 24.0, minf(area.x, 360.0), 20.0))
	_place(_slots, Rect2(0.0, above - 24.0 - SLOT_SIZE - UiTokens.SPACE_12, area.x, SLOT_SIZE))
	# The status reads on the left; the move card sits beside the fish on the
	# right, never over its face (like the Suwit tell).
	_place(_status, Rect2(0.0, top, area.x * 0.5, 40.0))
	var card := Vector2(minf(150.0, area.x * 0.4), 150.0)
	_place(_card, Rect2(area.x - card.x, top, card.x, card.y))
