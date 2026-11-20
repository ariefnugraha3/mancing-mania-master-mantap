class_name StoryUi
extends Control
## The story's screen layer (GDD 168.3, 167.9): the dialogue box with the
## speaker's name, the phone (a chat app, see ChatPhone: account cards,
## CepatCash messages, chats, calls), the title card, unlock panels, the skip
## ring and the fade.
##
## A tap, click or confirm advances. Nothing important advances by itself.

signal advanced()

const PHONE_WIDTH := 340.0
const PHONE_MAX_HEIGHT := 480.0
const PANEL_HEIGHT := DialogueBox.CARD_HEIGHT

@onready var _panel: PanelContainer = $DialoguePanel
@onready var _speaker: Label = $DialoguePanel/Column/SpeakerLabel
@onready var _line: Label = $DialoguePanel/Column/DialogueLabel
@onready var _prompt: Label = $DialoguePanel/Column/ContinuePrompt
@onready var _skip: ProgressBar = $SkipHoldIndicator

var _phone: ChatPhone
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
	DialogueBox.style_line(_line)
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
	# Like the phone, the card never takes a tap: a tap on the line or on its
	# TAP TO CONTINUE prompt moves the story on as a tap anywhere else does.
	_quiet(_panel)
	_panel.visible = false
	_phone = ChatPhone.new()
	_phone.name = "Phone"
	_phone.visible = false
	add_child(_phone)
	move_child(_phone, _panel.get_index() + 1)
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


static func _quiet(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_quiet(child)


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


## A phone line ("TOTAL DEBT: Rp ..."): an account card in the chat that is
## open, or in the CepatCash chat when the phone has just come out.
func show_phone_line(text: String) -> void:
	if _phone.get_contact() == &"" or _phone.is_call_visible():
		_open_contact(ChatPhone.CEPATCASH, "")
	_phone.add_info(text)


## A notification is a message from the CepatCash business account: the
## title is its bold heading, the body its text.
func show_notification(title: String, body: String) -> void:
	_open_contact(ChatPhone.CEPATCASH, "")
	if body == "":
		_phone.add_message(title, false)
	else:
		_phone.add_message(body, false, title)


## A message bubble: the other person's on the left, Darto's on the right,
## in that person's chat.
func show_chat(sender: String, text: String, from_darto: bool, sender_id: StringName = &"") -> void:
	if not from_darto:
		_open_contact(sender_id if sender_id != &"" else StringName(sender.to_lower()), sender)
	elif _phone.get_contact() == &"" or _phone.is_call_visible():
		_open_contact(&"messages", TextDb.t(&"story.phone.messages"))
	_phone.add_message(text, from_darto)


func show_call(caller: String, caller_id: StringName = &"") -> void:
	_phone.show_call(caller_id if caller_id != &"" else StringName(caller.to_lower()), caller)


func close_phone() -> void:
	_phone.close()


## The phone, for tests.
func get_phone() -> ChatPhone:
	return _phone


func show_title(title: String, subtitle: String) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_title.visible = true
	_subtitle.visible = subtitle != ""
	# The title may need two lines on a phone; the subtitle goes under it.
	_place_title()


func hide_title() -> void:
	_title.visible = false
	_subtitle.visible = false


func show_unlock(title: String, body: String, button: String) -> void:
	_unlock_title.text = title
	_unlock_body.text = body
	_unlock_button.text = button
	_unlock.visible = true
	InputManager.give_focus.call_deferred(_unlock_button)


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


## Opens `contact`'s chat. The phone's contact name ("Rini") comes from
## story.phone.<id> when there is one, else from `fallback`.
func _open_contact(contact: StringName, fallback: String) -> void:
	var key := StringName("story.phone.%s" % contact)
	_phone.open_thread(contact, TextDb.t(key) if TextDb.has_key(key) else fallback.capitalize())


func _outlined(size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	UiSkin.sign_text(label, size, UiTokens.CREAM_50 if size < UiTokens.FONT_HERO else DioramaStyle.BUTTER, 12)
	add_child(label)
	return label


## The title card (the prologue's "CATCH AND BRAWL"): the
## title wraps on a narrow phone and the subtitle always sits under its last
## line instead of a fixed distance below its first.
func _place_title() -> void:
	var area := size
	var margin := float(UiTokens.SPACE_16)
	var width := maxf(area.x - margin * 2.0, 1.0)
	_place_wrapped(_title, Vector2(margin, area.y * 0.38), width, 70.0)
	_place_wrapped(_subtitle, Vector2(margin, _title.position.y + _title.size.y + 6.0), width, 40.0)


## Width first, then height: a wrapped label's minimum height depends on its
## width, and a control is never smaller than its (cached) minimum.
static func _place_wrapped(label: Label, at: Vector2, width: float, min_height: float) -> void:
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = at
	label.size = Vector2(width, label.size.y)
	label.update_minimum_size()
	label.size = Vector2(width, min_height)


func _layout() -> void:
	var area := size
	# Everything stays inside the safe area: clear of the notch at the top and
	# the home indicator or gesture bar at the bottom.
	var safe := Rect2(PlatformService.get_safe_rect())
	var edge := float(UiTokens.SPACE_12)
	var top_inset := safe.position.y + edge
	var bottom_inset := area.y - safe.end.y + edge
	# The same card, in the same place, as the dialogue box in play.
	DialogueBox.place_card(_panel, area)
	var phone_width := minf(PHONE_WIDTH, safe.size.x - edge * 2.0)
	# As tall as fits above the dialogue card, so a line can play under it.
	var phone_room := area.y - top_inset - bottom_inset - PANEL_HEIGHT - edge
	_phone.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_phone.size = Vector2(phone_width, clampf(minf(area.y * 0.6, PHONE_MAX_HEIGHT), 300.0, maxf(300.0, phone_room)))
	_phone.position = Vector2((area.x - phone_width) * 0.5, top_inset)
	_place_title()
	# Like every popup card (OverlayPanel): clear of the screen's sides and in
	# the middle of the screen, growing both ways as its text wraps.
	var unlock_width := minf(560.0, safe.size.x - float(OverlayPanel.SCREEN_MARGIN) * 2.0)
	_unlock.set_anchors_preset(Control.PRESET_CENTER)
	_unlock.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_unlock.grow_vertical = Control.GROW_DIRECTION_BOTH
	_unlock.offset_left = -unlock_width * 0.5
	_unlock.offset_right = unlock_width * 0.5
	_unlock.offset_top = 0.0
	_unlock.offset_bottom = 0.0
	_skip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_skip.size = Vector2(200.0, 12.0)
	_skip.position = Vector2(area.x - 216.0, area.y - bottom_inset - PANEL_HEIGHT - 28.0)
