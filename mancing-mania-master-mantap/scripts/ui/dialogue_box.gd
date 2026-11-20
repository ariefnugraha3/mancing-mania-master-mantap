class_name DialogueBox
extends CanvasLayer
## On-screen dialogue (GDD 167.9, 168.12, 189.13): a box at the bottom of the
## safe area with the speaker's name and the line. There is no voice acting.
##
## A tap, click or confirm shows the next line; dialogue never advances by
## itself. Cancel (Esc / Android back) skips the rest of the conversation.

signal finished()

## The speech card, here and in the story scene (StoryUi): this wide at most,
## at least this tall, at the bottom of the safe area.
const CARD_WIDTH := 640.0
const CARD_HEIGHT := 190.0
## Text appears this many characters per second at the "normal" setting.
const CHARS_PER_SEC: Dictionary = {"relaxed": 30.0, "normal": 55.0, "fast": 110.0, "instant": 0.0}

var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _hint: Label
var _lines: Array[Dictionary] = []
var _index: int = -1
var _shown_chars: float = 0.0
var _playing: bool = false
var _input_was_enabled: bool = true
var _auto_left: float = 0.0
## QA only: how long each line stays up when dialogue advances by itself.
const AUTO_ADVANCE_SEC := 0.25


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_panel = PanelContainer.new()
	_panel.name = "Box"
	root.add_child(_panel)
	# A speech card: the speaker's name on a crust tag, the line in larger
	# type, and a bouncing arrow with the hint at the bottom right.
	_panel.add_theme_stylebox_override(&"panel", UiSkin.card(UiTokens.CREAM_50, 22, UiTokens.SPACE_16, 4))
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	_panel.add_child(column)
	_speaker = Label.new()
	_speaker.name = "Speaker"
	_speaker.theme_type_variation = UiTokens.TYPE_NAME_TAG
	_speaker.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(_speaker)
	_text = Label.new()
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	style_line(_text)
	column.add_child(_text)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_END
	foot.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	column.add_child(foot)
	_hint = Label.new()
	_hint.name = "Advance"
	_hint.theme_type_variation = UiTokens.TYPE_SMALL
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	# Wraps rather than widening the card past the screen at the largest text.
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hint.text = TextDb.t(&"dialogue.advance")
	foot.add_child(_hint)
	foot.add_child(AdvanceArrow.new())
	root.resized.connect(_layout)
	PlatformService.safe_area_changed.connect(_layout)
	_layout.call_deferred()
	visible = false


## The line's label in a speech card. It fills the card's spare height, so the
## TAP TO CONTINUE row always sits at the bottom of the card, and it is laid
## out with the whole line from the first letter: a line that types itself
## out never re-wraps or grows the card halfway through.
static func style_line(label: Label) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = 56.0
	label.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(UiTokens.FONT_BODY + 2))


## Places a speech card the same way everywhere: at the bottom centre of the
## safe area, CARD_WIDTH at most and CARD_HEIGHT tall. The size lives in the
## anchors, never in `size`, so a card that needs more room for a long line
## grows upward and goes back to CARD_HEIGHT for the next one.
static func place_card(card: Control, area: Vector2) -> void:
	var safe := Rect2(PlatformService.get_safe_rect())
	var edge := float(UiTokens.SPACE_12)
	var bottom_inset := area.y - safe.end.y + edge
	var width := minf(CARD_WIDTH, safe.size.x - edge * 2.0)
	card.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	card.offset_left = -width * 0.5
	card.offset_right = width * 0.5
	card.offset_bottom = -bottom_inset
	card.offset_top = -bottom_inset - CARD_HEIGHT


func _process(delta: float) -> void:
	if not _playing or _index < 0:
		return
	if DebugService.is_auto_dialogue_enabled():
		_auto_left -= delta
		if _auto_left <= 0.0:
			_auto_left = AUTO_ADVANCE_SEC
			_next()
			return
	var speed: float = CHARS_PER_SEC.get(str(GameState.get_setting(&"dialogue_speed")), 55.0)
	var total := _text.get_total_character_count()
	_shown_chars = float(total) if speed <= 0.0 else minf(_shown_chars + speed * delta, float(total))
	_text.visible_characters = int(_shown_chars)


## Shows `lines` ({speaker, text}) one at a time. Await `finished`.
func play(lines: Array[Dictionary]) -> void:
	_lines = lines
	if lines.is_empty():
		finished.emit.call_deferred()
		return
	_playing = true
	visible = true
	_input_was_enabled = InputManager.is_gameplay_input_enabled()
	InputManager.set_gameplay_input_enabled(false)
	_index = -1
	_next()


func is_playing() -> bool:
	return _playing


## The line on screen, for tests.
func get_current_line() -> Dictionary:
	return _lines[_index] if _playing and _index >= 0 and _index < _lines.size() else {}


## Advances as a tap would: completes a line that is still appearing, or
## moves to the next one.
func advance() -> void:
	if not _playing:
		return
	if _text.visible_characters >= 0 and _text.visible_characters < _text.get_total_character_count():
		_shown_chars = float(_text.get_total_character_count())
		_text.visible_characters = -1
		return
	_next()


func skip() -> void:
	if _playing:
		_close()


## The dialogue has the controls while it is up. Input is read here, before
## the GUI: a Space, Enter, click or tap meant for the next line would
## otherwise also press the button that has focus or sits under the finger
## (in the Market, the dialogue advanced and a Market button fired at once).
## An overlay opened over the dialogue (Pause, a prompt) keeps its own input.
func _input(event: InputEvent) -> void:
	if not _playing or _overlay_open():
		return
	# A touch also arrives as an emulated mouse click: the touch advances, its
	# mouse copy is only kept away from the buttons.
	var mouse := event as InputEventMouseButton
	if mouse != null and mouse.device == InputEvent.DEVICE_ID_EMULATION:
		if mouse.pressed:
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(InputActions.UI_CANCEL):
		get_viewport().set_input_as_handled()
		skip()
	elif _is_advance(event):
		get_viewport().set_input_as_handled()
		advance()


static func _is_advance(event: InputEvent) -> bool:
	if InputActions.is_primary_press(event):
		return true
	for action: StringName in [InputActions.UI_CONFIRM, &"ui_accept", &"fish_cast"]:
		if event.is_action_pressed(action):
			return true
	return false


func _overlay_open() -> bool:
	return is_inside_tree() and get_tree().get_first_node_in_group(OverlayPanel.OPEN_GROUP) != null


func _next() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
		return
	_speaker.text = str(_lines[_index].get("speaker", ""))
	_text.text = str(_lines[_index].get("text", ""))
	_shown_chars = 0.0
	_text.visible_characters = 0


func _close() -> void:
	_playing = false
	visible = false
	_index = -1
	InputManager.set_gameplay_input_enabled(_input_was_enabled)
	finished.emit()


func _layout() -> void:
	place_card(_panel, (_panel.get_parent() as Control).size)
