class_name SuwitHud
extends CanvasLayer
## Suwit HUD (GDD 64-68, 168.10, 185.19): score dots, the countdown, the
## fish's tell, the three move buttons and the Charm.
##
## The move buttons are far apart and large, so a thumb never hits the
## neighbour (SUWIT-009). Every move is a hand symbol and a word.

signal move_pressed(move: StringName)
signal charm_pressed()
signal pause_pressed()

const BUTTON_SIZE := Vector2(110.0, 130.0)
## The fish's tell card: one size whatever it says (revision 6.12). Its word
## wraps to at most two lines and shrinks, down to TELL_MIN_FONT, until the
## longest word fits; the card never grows past the edge of the screen.
const TELL_ICON := 84.0
const TELL_MIN_FONT := 13

@onready var _safe_root: Control = $SafeRoot
@onready var _dots: HBoxContainer = $SafeRoot/ScoreDots
@onready var _countdown: Label = $SafeRoot/Countdown
@onready var _tell: PanelContainer = $SafeRoot/TellWidget
@onready var _row: HBoxContainer = $SafeRoot/ChoiceRow
@onready var _rock: GameButton = $SafeRoot/ChoiceRow/RockButton
@onready var _scissors: GameButton = $SafeRoot/ChoiceRow/ScissorsButton
@onready var _paper: GameButton = $SafeRoot/ChoiceRow/PaperButton
@onready var _charm: GameButton = $SafeRoot/CharmButton

var _tell_icon: MoveIcon
var _tell_label: Label
var _player_dots: Array[Panel] = []
var _fish_dots: Array[Panel] = []
var _banner: Label
var _banner_body: Label
var _banner_left: float = 0.0
var _keys: Label
var _pause_button: GameButton
var _buttons: Dictionary[StringName, GameButton] = {}


func _ready() -> void:
	_buttons = {SuwitController.ROCK: _rock, SuwitController.SCISSORS: _scissors, SuwitController.PAPER: _paper}
	for move: StringName in _buttons:
		_build_move_button(_buttons[move], move)
	_charm.focus_mode = Control.FOCUS_NONE
	_charm.pressed.connect(func() -> void: charm_pressed.emit())
	_row.add_theme_constant_override(&"separation", UiTokens.SPACE_32)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_tell()
	_build_dots()
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(_countdown, 64)
	_banner = _outlined(40)
	_banner_body = _outlined(UiTokens.FONT_HEADER)
	_keys = _outlined(UiTokens.FONT_SMALL)
	_keys.text = TextDb.tf(&"suwit.keys", {
		"rock": _key(&"suwit_rock"), "scissors": _key(&"suwit_scissors"), "paper": _key(&"suwit_paper"), "charm": _key(&"suwit_charm")})
	_pause_button = GameButton.new()
	_pause_button.name = "PauseButton"
	HudChip.make_pause_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_safe_root.add_child(_pause_button)
	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(func(_c: StringName) -> void: _layout())
	_layout.call_deferred()


func _process(delta: float) -> void:
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false
			_banner_body.visible = false


func refresh(snapshot: Dictionary) -> void:
	var counting: bool = snapshot["state"] == SuwitController.STATE_COUNTDOWN
	_countdown.visible = counting
	_countdown.text = str(ceili(float(snapshot["countdown_left"])))
	for index: int in _player_dots.size():
		_style_dot(_player_dots[index], index < int(snapshot["player_wins"]), UiTokens.GRASS_500)
		_style_dot(_fish_dots[index], index < int(snapshot["fish_wins"]), UiTokens.TERRACOTTA_500)
	var charm_move: StringName = snapshot["charm_move"]
	var tell: StringName = snapshot["tell"]
	if charm_move != &"":
		_tell.visible = true
		_tell_icon.move = charm_move
		_tell_icon.highlighted = true
		_tell_label.text = TextDb.tf(&"suwit.real_move", {"move": TextDb.t(StringName("suwit.move.%s" % charm_move))})
	elif tell != &"":
		_tell.visible = true
		_tell_icon.move = tell
		_tell_icon.highlighted = false
		_tell_label.text = TextDb.t(StringName("suwit.move.%s" % tell))
	else:
		_tell.visible = counting
		_tell_icon.move = &""
		_tell_label.text = TextDb.t(&"suwit.tell")
	_fit_tell_text()
	var picked: StringName = snapshot["player_move"]
	for move: StringName in _buttons:
		_buttons[move].disabled = not counting or (picked != &"" and picked != move)
	var charges := int(snapshot["charm_charges"])
	_charm.text = TextDb.tf(&"suwit.charm", {"count": charges}) if charges > 0 else TextDb.t(&"suwit.charm_none")
	_charm.disabled = not counting or charges <= 0 or charm_move != &""


func show_banner(title: String, body: String, seconds: float) -> void:
	_banner.text = title
	_banner.visible = title != ""
	_banner_body.text = body
	_banner_body.visible = body != ""
	_banner_left = seconds


func get_move_button(move: StringName) -> GameButton:
	return _buttons[move]


func get_tell_label_text() -> String:
	return _tell_label.text if _tell.visible else ""


func get_charm_button() -> GameButton:
	return _charm


# --- Construction -----------------------------------------------------------

func _build_move_button(button: GameButton, move: StringName) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = BUTTON_SIZE
	button.pressed.connect(func() -> void: move_pressed.emit(move))
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(column)
	var icon := MoveIcon.new()
	icon.move = move
	icon.custom_minimum_size = Vector2(80.0, 80.0)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(icon)
	var label := Label.new()
	label.text = TextDb.t(StringName("suwit.move.%s" % move))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	column.add_child(label)


func _build_tell() -> void:
	_tell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tell.add_theme_stylebox_override(&"panel", UiSkin.card(UiTokens.CREAM_50, 22, UiTokens.SPACE_12, 3))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_tell.add_child(column)
	_tell_icon = MoveIcon.new()
	_tell_icon.custom_minimum_size = Vector2(TELL_ICON, TELL_ICON)
	_tell_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_tell_icon)
	_tell_label = Label.new()
	_tell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tell_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tell_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tell_label.max_lines_visible = 2
	_tell_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	_tell_label.add_theme_font_override(&"font", UiSkin.bold_font())
	column.add_child(_tell_label)
	_tell.visible = false


## The tell's word at the largest size, from FONT_BUTTON down, whose longest
## word fits the card and whose whole text fits two lines.
func _fit_tell_text() -> void:
	var font := _tell_label.get_theme_font(&"font")
	var room := _tell.size.x - _tell.get_theme_stylebox(&"panel").get_minimum_size().x
	var font_size := UiTokens.FONT_BUTTON
	while font_size > TELL_MIN_FONT:
		var lines := font.get_multiline_string_size(_tell_label.text, HORIZONTAL_ALIGNMENT_CENTER, room, font_size).y / font.get_height(font_size)
		if OverlayPanel.longest_word_width(font, font_size, _tell_label.text) <= room and lines <= 2.05:
			break
		font_size -= 1
	_tell_label.add_theme_font_size_override(&"font_size", font_size)


func _build_dots() -> void:
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	var wins := GameData.get_suwit_config().wins_required
	for side: int in 2:
		var label := Label.new()
		label.text = TextDb.t(&"boxing.hud.player" if side == 0 else &"suwit.hud.fish")
		UiTokens.outline_text(label, UiTokens.FONT_SMALL, UiTokens.CREAM_50, 6)
		if side == 1:
			var spacer := Control.new()
			spacer.custom_minimum_size.x = 24.0
			_dots.add_child(spacer)
		_dots.add_child(label)
		for index: int in wins:
			var dot := Panel.new()
			dot.name = "Dot%d_%d" % [side, index]
			dot.custom_minimum_size = Vector2(26.0, 26.0)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dots.add_child(dot)
			(_player_dots if side == 0 else _fish_dots).append(dot)


## A won point is a filled round dot with a thick border; an open one is a
## hollow ring. Filled versus hollow reads without the colours (GDD 189.5).
func _style_dot(dot: Panel, filled: bool, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(15)
	box.border_color = UiTokens.INK_900 if filled else UiTokens.CREAM_50
	box.set_border_width_all(UiTokens.hud_border(4) if filled else UiTokens.hud_border(3))
	box.bg_color = color if filled else Color(UiTokens.INK_900, 0.35)
	box.shadow_color = UiTokens.SHADOW
	box.shadow_size = 3
	box.shadow_offset = Vector2(0.0, 2.0)
	box.anti_aliasing = true
	dot.add_theme_stylebox_override(&"panel", box)
	dot.set_meta(&"filled", filled)


func _outlined(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	UiTokens.outline_text(label, font_size)
	_safe_root.add_child(label)
	return label


func _key(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return ""


func _layout() -> void:
	var area := _safe_root.size
	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	_dots.reset_size()
	var dots_size := _dots.get_combined_minimum_size()
	# The score dots get their own row under Pause, centred.
	var dots_top := float(UiTokens.TOUCH_TARGET_PREFERRED) + UiTokens.SPACE_8
	_place(_dots, Rect2((area.x - dots_size.x) * 0.5, dots_top, dots_size.x, 40.0))
	# Bottom: the Charm across the thumb zone; above it, the three moves,
	# as wide as the screen allows with a clear gap between them.
	# A clear gap, so a thumb never presses the neighbour (SUWIT-009).
	var gap := float(UiTokens.SPACE_24 if PlatformService.is_tablet() else 20)
	var row_width := minf(area.x, 560.0)
	var button := Vector2((row_width - gap * 2.0) / 3.0, clampf(roundf(area.y * 0.18), 120.0, 170.0))
	_row.add_theme_constant_override(&"separation", int(gap))
	for move: StringName in _buttons:
		_buttons[move].custom_minimum_size = button
	var charm_height := float(UiTokens.TOUCH_TARGET_PREFERRED)
	var charm_width := minf(row_width, 320.0)
	_place(_charm, Rect2((area.x - charm_width) * 0.5, area.y - charm_height, charm_width, charm_height))
	_place(_row, Rect2((area.x - row_width) * 0.5, _charm.position.y - button.y - UiTokens.SPACE_16, row_width, button.y))
	# The tell sits beside the fish, never over its face: one fixed card with
	# room for the hand and two lines of its largest text.
	var line := _tell_label.get_theme_font(&"font").get_height(UiTokens.FONT_BUTTON) + float(_tell_label.get_theme_constant(&"line_spacing"))
	var two_lines := line * 2.0
	_tell_label.custom_minimum_size.y = two_lines
	var column_gap := float((_tell.get_child(0) as BoxContainer).get_theme_constant(&"separation"))
	var tell_size := Vector2(minf(170.0, area.x * 0.44), _tell.get_theme_stylebox(&"panel").get_minimum_size().y + TELL_ICON + column_gap + two_lines)
	var under_dots := dots_top + 48.0
	_place(_tell, Rect2(area.x - tell_size.x, under_dots, tell_size.x, tell_size.y))
	_fit_tell_text()
	_place(_countdown, Rect2(0.0, under_dots, area.x * 0.45, 80.0))
	# The intro banner's first line starts under the tell card, never over it.
	var title_line := _banner.get_theme_font(&"font").get_height(_banner.get_theme_font_size(&"font_size"))
	var banner_top := maxf(area.y * 0.2, _tell.position.y + _tell.size.y + UiTokens.SPACE_8 + title_line - UiTokens.BANNER_TITLE_HEIGHT)
	UiTokens.place_banner(_banner, _banner_body, banner_top, area.x)
	_keys.visible = InputManager.is_keyboard_active()
	_place(_keys, Rect2(0.0, _row.position.y - 30.0, area.x, 28.0))


func _place(control: Control, rect: Rect2) -> void:
	UiTokens.place_at(control, rect)
