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

const BUTTON_SIZE := Vector2(180.0, 150.0)

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
		_tell_icon.tint = UiTokens.LAKE_500
		_tell_label.text = TextDb.tf(&"suwit.real_move", {"move": TextDb.t(StringName("suwit.move.%s" % charm_move))})
	elif tell != &"":
		_tell.visible = true
		_tell_icon.move = tell
		_tell_icon.tint = UiTokens.INK_900
		_tell_label.text = TextDb.t(StringName("suwit.move.%s" % tell))
	else:
		_tell.visible = counting
		_tell_icon.move = &""
		_tell_label.text = TextDb.t(&"suwit.tell")
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
	_tell.add_theme_stylebox_override(&"panel", HudChip.make_style())
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_tell.add_child(column)
	_tell_icon = MoveIcon.new()
	_tell_icon.custom_minimum_size = Vector2(96.0, 96.0)
	_tell_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_tell_icon)
	_tell_label = Label.new()
	_tell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tell_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	column.add_child(_tell_label)
	_tell.visible = false


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
	box.set_corner_radius_all(13)
	box.border_color = UiTokens.INK_900 if filled else UiTokens.CREAM_50
	box.set_border_width_all(UiTokens.hud_border(4) if filled else UiTokens.hud_border(3))
	box.bg_color = color if filled else Color(UiTokens.INK_900, 0.35)
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
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var area := _safe_root.size
	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	_dots.reset_size()
	_place(_dots, Rect2((area.x - _dots.get_combined_minimum_size().x) * 0.5, 8.0, _dots.get_combined_minimum_size().x, 40.0))
	var button := BUTTON_SIZE if not portrait else Vector2((area.x - UiTokens.SPACE_24 * 2.0) / 3.0, 170.0)
	var row_width := button.x * 3.0 + float(UiTokens.SPACE_32) * 2.0 if not portrait else area.x
	_row.add_theme_constant_override(&"separation", UiTokens.SPACE_32 if not portrait else UiTokens.SPACE_24)
	for move: StringName in _buttons:
		_buttons[move].custom_minimum_size = button
	var charm_height := float(UiTokens.TOUCH_TARGET_PREFERRED)
	_place(_charm, Rect2((area.x - 260.0) * 0.5, area.y - charm_height - (34.0 if not portrait else 0.0), 260.0, charm_height))
	_place(_row, Rect2((area.x - row_width) * 0.5, _charm.position.y - button.y - UiTokens.SPACE_16, row_width, button.y))
	# The tell sits beside the fish, never over its face.
	_place(_tell, Rect2(area.x * (0.86 if not portrait else 0.78) - 90.0, area.y * (0.2 if not portrait else 0.1), 180.0, 150.0))
	_place(_countdown, Rect2(0.0, area.y * 0.1, area.x * (0.5 if not portrait else 0.4), 80.0))
	_place(_banner, Rect2(0.0, area.y * 0.32, area.x, 56.0))
	_place(_banner_body, Rect2(0.0, area.y * 0.32 + 58.0, area.x, 40.0))
	_keys.visible = not portrait and not InputManager.is_touch_primary()
	_place(_keys, Rect2(0.0, area.y - 30.0, area.x, 30.0))


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
