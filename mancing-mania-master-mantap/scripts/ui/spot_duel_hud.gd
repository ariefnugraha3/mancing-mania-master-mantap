class_name SpotDuelHud
extends CanvasLayer
## Shared parts of the four spot-duel HUDs (revision 6.7): the Pause button,
## the big two-line banner, the key hint, score dots and the helpers that
## place controls on the portrait screen. Each duel's HUD builds its own
## widgets in `_build()` and arranges them in `_arrange(area)`.

signal pause_pressed()

@onready var _safe_root: Control = $SafeRoot

var _banner: Label
var _banner_body: Label
var _banner_left: float = 0.0
var _keys: Label
var _pause_button: GameButton
var _dots: HBoxContainer
var _player_dots: Array[Panel] = []
var _fish_dots: Array[Panel] = []


func _ready() -> void:
	_build()
	_banner = _outlined(40)
	UiSkin.sign_text(_banner, 44, DioramaStyle.BUTTER, 12)
	_banner_body = _outlined(UiTokens.FONT_HEADER)
	_banner.visible = false
	_banner_body.visible = false
	_keys = _outlined(UiTokens.FONT_SMALL)
	_keys.visible = false
	_pause_button = GameButton.new()
	_pause_button.name = "PauseButton"
	HudChip.make_pause_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_safe_root.add_child(_pause_button)
	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(func(_c: StringName) -> void: _layout())
	InputManager.input_device_changed.connect(func(_d: StringName) -> void: _layout())
	_layout.call_deferred()


func _process(delta: float) -> void:
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false
			_banner_body.visible = false


func show_banner(title: String, body: String, seconds: float) -> void:
	_banner.text = title
	_banner.visible = title != ""
	_banner_body.text = body
	_banner_body.visible = body != ""
	_banner_left = seconds


func get_banner_text() -> String:
	return _banner.text if _banner.visible else ""


# --- For subclasses -----------------------------------------------------------

func _build() -> void:
	pass


## Places the duel's own widgets. `top` is the first free row under Pause.
func _arrange(_area: Vector2, _top: float) -> void:
	pass


## The key hint shown while a keyboard is in use.
func _keys_text() -> String:
	return ""


## Bottom edge of the key hint's row (just above the buttons).
func _keys_bottom(area: Vector2) -> float:
	return area.y


# --- Helpers ------------------------------------------------------------------

func _layout() -> void:
	var area := _safe_root.size
	if area.x <= 0.0 or area.y <= 0.0:
		return
	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	var top := float(UiTokens.TOUCH_TARGET_PREFERRED) + UiTokens.SPACE_8
	if _dots != null:
		_dots.reset_size()
		var dots_size := _dots.get_combined_minimum_size()
		_place(_dots, Rect2((area.x - dots_size.x) * 0.5, top, dots_size.x, 40.0))
		top += 48.0
	_arrange(area, top)
	UiTokens.place_banner(_banner, _banner_body, area.y * 0.2, area.x)
	_keys.text = _keys_text()
	_keys.visible = InputManager.is_keyboard_active() and _keys.text != ""
	_place(_keys, Rect2(0.0, _keys_bottom(area) - 30.0, area.x, 28.0))


## Score dots like Suwit's: filled for a point won, hollow for one to go.
func _build_dots(count: int) -> void:
	_dots = HBoxContainer.new()
	_dots.name = "ScoreDots"
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	_safe_root.add_child(_dots)
	for side: int in 2:
		var label := Label.new()
		label.text = TextDb.t(&"boxing.hud.player" if side == 0 else &"suwit.hud.fish")
		UiTokens.outline_text(label, UiTokens.FONT_SMALL, UiTokens.CREAM_50, 6)
		if side == 1:
			var spacer := Control.new()
			spacer.custom_minimum_size.x = 24.0
			_dots.add_child(spacer)
		_dots.add_child(label)
		for index: int in count:
			var dot := Panel.new()
			dot.name = "Dot%d_%d" % [side, index]
			dot.custom_minimum_size = Vector2(26.0, 26.0)
			dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dots.add_child(dot)
			(_player_dots if side == 0 else _fish_dots).append(dot)
			_style_dot(dot, false, UiTokens.GRASS_500)


func _refresh_dots(player_points: int, fish_points: int) -> void:
	for index: int in _player_dots.size():
		_style_dot(_player_dots[index], index < player_points, UiTokens.GRASS_500)
		_style_dot(_fish_dots[index], index < fish_points, UiTokens.TERRACOTTA_500)


func _style_dot(dot: Panel, filled: bool, color: Color) -> void:
	if dot.has_meta(&"filled") and bool(dot.get_meta(&"filled")) == filled:
		return
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


## A big thumb button that fires `action` on the way down, like MASH.
func _action_button(node_name: String, text: String, icon_id: StringName, action: StringName, cta: bool = true) -> GameButton:
	var button := GameButton.new()
	button.name = node_name
	button.focus_mode = Control.FOCUS_NONE
	button.click_sfx = &""
	if icon_id != &"":
		button.icon_pixels = 40
		button.icon_id = icon_id
		button.expand_icon = false
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.text = text
	button.theme_type_variation = UiTokens.TYPE_CTA_BUTTON if cta else &""
	button.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	# Narrow side padding: four arrows share one phone-wide row, and a wider
	# minimum size would push the buttons into each other.
	button.set_side_padding(UiTokens.SPACE_4)
	button.clip_text = true
	button.button_down.connect(InputManager.press_action.bind(action))
	button.button_up.connect(InputManager.release_action.bind(action))
	_safe_root.add_child(button)
	return button


## A timer chip like the boxing and arm wrestling ones.
func _make_timer_chip() -> Array:
	var chip := PanelContainer.new()
	chip.name = "Timer"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override(&"panel", HudChip.timer_style(false))
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 64.0
	label.add_theme_font_size_override(&"font_size", UiTokens.FONT_HEADER)
	label.add_theme_font_override(&"font", UiSkin.heavy_font())
	chip.add_child(label)
	_safe_root.add_child(chip)
	return [chip, label]


func _outlined(font_size: int, color: Color = UiTokens.CREAM_50) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(label, font_size, color)
	_safe_root.add_child(label)
	return label


func _key(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return "?"


func _place(control: Control, rect: Rect2) -> void:
	UiTokens.place_at(control, rect)
