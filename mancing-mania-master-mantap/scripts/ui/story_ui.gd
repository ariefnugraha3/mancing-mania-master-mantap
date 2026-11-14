class_name StoryUi
extends Control
## The story's screen layer (GDD 168.3, 167.9): the dialogue box with the
## speaker's name, the phone (balance, notifications, messages, calls), the
## title card, unlock panels, the skip ring and the fade.
##
## A tap, click or confirm advances. Nothing important advances by itself.

signal advanced()

const PHONE_WIDTH := 340.0
const PANEL_HEIGHT := 158.0

@onready var _panel: PanelContainer = $DialoguePanel
@onready var _speaker: Label = $DialoguePanel/Column/SpeakerLabel
@onready var _line: Label = $DialoguePanel/Column/DialogueLabel
@onready var _prompt: Label = $DialoguePanel/Column/ContinuePrompt
@onready var _phone: PanelContainer = $NotificationPanel
@onready var _phone_lines: VBoxContainer = $NotificationPanel/Lines
@onready var _skip: ProgressBar = $SkipHoldIndicator

var _title: Label
var _subtitle: Label
var _unlock: PanelContainer
var _unlock_title: Label
var _unlock_body: Label
var _unlock_button: GameButton
var _fade: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker.theme_type_variation = UiTokens.TYPE_HEADER
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.y = 56.0
	_prompt.text = TextDb.t(&"story.continue")
	_prompt.theme_type_variation = UiTokens.TYPE_SMALL
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_panel.visible = false
	_phone.visible = false
	_phone.clip_contents = true
	_phone_lines.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_phone.add_theme_stylebox_override(&"panel", _phone_style())
	_phone_lines.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	_skip.show_percentage = false
	_skip.max_value = 1.0
	_skip.visible = false

	_title = _outlined(UiTokens.FONT_HERO)
	_subtitle = _outlined(UiTokens.FONT_HEADER)
	_unlock = PanelContainer.new()
	_unlock.name = "UnlockPanel"
	_unlock.visible = false
	add_child(_unlock)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	_unlock.add_child(column)
	_unlock_title = Label.new()
	_unlock_title.theme_type_variation = UiTokens.TYPE_SCREEN_TITLE
	_unlock_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unlock_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_unlock_title)
	_unlock_body = Label.new()
	_unlock_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_unlock_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_unlock_body)
	_unlock_button = GameButton.new()
	_unlock_button.theme_type_variation = UiTokens.TYPE_CTA_BUTTON
	_unlock_button.pressed.connect(func() -> void: advanced.emit())
	column.add_child(_unlock_button)

	_fade = ColorRect.new()
	_fade.name = "Fade"
	_fade.color = Color(UiTokens.INK_900, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	(get_parent().get_parent().get_node("FadeLayer") as CanvasLayer).add_child(_fade)
	resized.connect(_layout)
	_layout.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.UI_CONFIRM) or event.is_action_pressed(&"fish_cast") or InputActions.is_primary_press(event):
		get_viewport().set_input_as_handled()
		advanced.emit()


func show_line(speaker: String, text: String) -> void:
	_speaker.text = speaker
	_line.text = text
	_panel.visible = true


func hide_line() -> void:
	_panel.visible = false


func clear_line_if(_step: Dictionary) -> void:
	pass


func show_phone_line(text: String) -> void:
	_open_phone()
	_add_phone_label(text, UiTokens.FONT_BUTTON, HORIZONTAL_ALIGNMENT_CENTER)


func show_notification(title: String, body: String) -> void:
	_open_phone()
	var card := PanelContainer.new()
	card.add_theme_stylebox_override(&"panel", HudChip.make_style())
	var column := VBoxContainer.new()
	card.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override(&"font_size", UiTokens.FONT_SMALL + 2)
	column.add_child(heading)
	if body != "":
		var text := Label.new()
		text.text = body
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.theme_type_variation = UiTokens.TYPE_SMALL
		column.add_child(text)
	_phone_lines.add_child(card)


## A message bubble: the other person's on the left, Darto's on the right.
func show_chat(sender: String, text: String, from_darto: bool) -> void:
	if not _phone.visible:
		_open_phone()
		_add_phone_label(TextDb.t(&"story.phone.messages"), UiTokens.FONT_SMALL, HORIZONTAL_ALIGNMENT_CENTER)
	var bubble := PanelContainer.new()
	var style := HudChip.make_style()
	style.bg_color = UiTokens.LAKE_500.lightened(0.45) if from_darto else UiTokens.CREAM_50
	bubble.add_theme_stylebox_override(&"panel", style)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_END if from_darto else Control.SIZE_SHRINK_BEGIN
	var label := Label.new()
	label.text = text if from_darto else "%s: %s" % [sender, text]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 220.0
	bubble.add_child(label)
	_phone_lines.add_child(bubble)


func show_call(caller: String) -> void:
	_open_phone()
	_add_phone_label(TextDb.t(&"story.phone.call"), UiTokens.FONT_SMALL, HORIZONTAL_ALIGNMENT_CENTER)
	_add_phone_label(caller, UiTokens.FONT_SCREEN_TITLE, HORIZONTAL_ALIGNMENT_CENTER)


func close_phone() -> void:
	_phone.visible = false
	for child: Node in _phone_lines.get_children():
		child.queue_free()


func show_title(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_title.visible = true
	_subtitle.visible = subtitle != ""


func hide_title() -> void:
	_title.visible = false
	_subtitle.visible = false


func show_unlock(title: String, body: String, button: String) -> void:
	_unlock_title.text = title
	_unlock_body.text = body
	_unlock_button.text = button
	_unlock.visible = true
	_unlock_button.grab_focus.call_deferred()


func hide_unlock() -> void:
	_unlock.visible = false


func is_unlock_visible() -> bool:
	return _unlock.visible


func get_line_text() -> String:
	return _line.text if _panel.visible else ""


func set_skip_progress(value: float) -> void:
	_skip.visible = value > 0.0
	_skip.value = clampf(value, 0.0, 1.0)


func set_black(black: bool) -> void:
	_fade.modulate.a = 1.0 if black else 0.0


## Fades the picture out to black, or in from black.
func fade(out: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0 if out else 0.0, 0.6)
	await tween.finished


func _open_phone() -> void:
	if not _phone.visible:
		for child: Node in _phone_lines.get_children():
			child.queue_free()
	_phone.visible = true


func _add_phone_label(text: String, size: int, alignment: HorizontalAlignment) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", UiTokens.CREAM_50)
	_phone_lines.add_child(label)


func _phone_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("2f3a3a")
	box.border_color = UiTokens.INK_900
	box.set_border_width_all(6)
	box.set_corner_radius_all(22)
	box.set_content_margin_all(UiTokens.SPACE_16)
	return box


func _outlined(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	UiTokens.outline_text(label, size)
	add_child(label)
	return label


func _layout() -> void:
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var area := size
	var width := minf(760.0, area.x)
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.size = Vector2(width, PANEL_HEIGHT)
	_panel.position = Vector2((area.x - width) * 0.5, area.y - PANEL_HEIGHT - UiTokens.SPACE_12)
	var phone_width := minf(PHONE_WIDTH, area.x)
	_phone.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_phone.size = Vector2(phone_width, minf(area.y * 0.62, 460.0))
	_phone.position = Vector2(area.x - phone_width - 16.0 if not portrait else (area.x - phone_width) * 0.5, 16.0)
	_title.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_title.position = Vector2(0.0, area.y * 0.38)
	_title.size = Vector2(area.x, 70.0)
	_subtitle.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_subtitle.position = Vector2(0.0, area.y * 0.38 + 76.0)
	_subtitle.size = Vector2(area.x, 40.0)
	var unlock_width := minf(560.0, area.x)
	_unlock.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_unlock.size = Vector2(unlock_width, 0.0)
	_unlock.position = Vector2((area.x - unlock_width) * 0.5, area.y * 0.28)
	_skip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_skip.size = Vector2(200.0, 12.0)
	_skip.position = Vector2(area.x - 216.0, area.y - PANEL_HEIGHT - 40.0)
