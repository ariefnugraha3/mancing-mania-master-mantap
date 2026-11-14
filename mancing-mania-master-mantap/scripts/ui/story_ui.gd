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
	# The same speech card as the in-game dialogue box: a crust name tag, the
	# line in larger type and a bouncing arrow by the prompt.
	_panel.add_theme_stylebox_override(&"panel", UiSkin.card(UiTokens.CREAM_50, 22, UiTokens.SPACE_16, 4))
	_speaker.theme_type_variation = UiTokens.TYPE_NAME_TAG
	_speaker.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.y = 56.0
	_line.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(UiTokens.FONT_BODY + 2))
	_prompt.text = TextDb.t(&"story.continue")
	_prompt.theme_type_variation = UiTokens.TYPE_SMALL
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# The prompt and its bouncing arrow share a row at the foot of the card.
	var foot := HBoxContainer.new()
	foot.name = "Foot"
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	_prompt.get_parent().add_child(foot)
	_prompt.reparent(foot, false)
	_prompt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var arrow := AdvanceArrow.new()
	arrow.name = "AdvanceArrow"
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	foot.add_child(arrow)
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
	var badge := LogoEmblem.new()
	badge.name = "UnlockEmblem"
	badge.diameter = 64.0
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(badge)
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
	PlatformService.safe_area_changed.connect(_layout)
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
	var note_style := UiSkin.card(UiTokens.CREAM_50, 16, UiTokens.SPACE_12, 2)
	note_style.shadow_size = 4
	card.add_theme_stylebox_override(&"panel", note_style)
	var column := VBoxContainer.new()
	card.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_override(&"font", UiSkin.bold_font())
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
	var style := UiSkin.pill(UiTokens.LAKE_500.lightened(0.5) if from_darto else UiTokens.CREAM_50, 2, 18, Vector2(UiTokens.SPACE_12, UiTokens.SPACE_8), 2)
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


## A chunky toy phone: a dark teal screen in a thick cocoa body.
func _phone_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("2f4746")
	box.border_color = UiTokens.INK_900
	box.set_border_width_all(10)
	box.border_width_top = 22
	box.border_width_bottom = 22
	box.set_corner_radius_all(30)
	box.set_content_margin_all(UiTokens.SPACE_16)
	box.content_margin_top = 30.0
	# No drop shadow: the phone clips its chat list, which would cut a shadow
	# into a square band.
	box.anti_aliasing = true
	return box


func _outlined(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	UiSkin.sign_text(label, size, UiTokens.CREAM_50 if size < UiTokens.FONT_HERO else DioramaStyle.BUTTER, 12)
	add_child(label)
	return label


func _layout() -> void:
	var area := size
	# Everything stays inside the safe area: clear of the notch at the top and
	# the home indicator or gesture bar at the bottom.
	var safe := Rect2(PlatformService.get_safe_rect())
	var edge := float(UiTokens.SPACE_12)
	var top_inset := safe.position.y + edge
	var bottom_inset := area.y - safe.end.y + edge
	var width := minf(640.0, safe.size.x - edge * 2.0)
	# Anchored to the bottom and growing upward, so a long line never pushes
	# the card off the screen.
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_left = -width * 0.5
	_panel.offset_right = width * 0.5
	_panel.offset_bottom = -bottom_inset
	_panel.offset_top = -bottom_inset - PANEL_HEIGHT
	var phone_width := minf(PHONE_WIDTH, safe.size.x - edge * 2.0)
	_phone.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_phone.size = Vector2(phone_width, minf(area.y * 0.56, 460.0))
	_phone.position = Vector2((area.x - phone_width) * 0.5, top_inset)
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
	_skip.position = Vector2(area.x - 216.0, area.y - bottom_inset - PANEL_HEIGHT - 28.0)
