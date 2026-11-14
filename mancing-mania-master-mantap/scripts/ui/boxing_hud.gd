class_name BoxingHud
extends CanvasLayer
## Boxing HUD (GDD 42, 94, 167.9, 168.7): both HP bars, the round clock, the
## telegraph read-out and the four controls.
##
## Keyboard players see their four keys named at the bottom of the screen.
## Touch layouts get four large buttons in the lower part of the screen, dodge
## on the left and punches on the right, clear of the fight above them. The
## buttons feed the same input actions as the keyboard.

signal pause_pressed()

const BAR_WIDTH_LANDSCAPE := 360.0
const BAR_HEIGHT := 22.0
const HP_CATCH_UP_PER_SEC := 1.6
const WIDGET_SIZE := Vector2(520.0, 112.0)
## Share of the screen height that belongs to the fight in portrait (GDD 94).
const FIGHT_SHARE_PORTRAIT := 0.62
const LOW_TIME_SEC := 10.0

@onready var _safe_root: Control = $SafeRoot
@onready var _player_hp: VBoxContainer = $SafeRoot/PlayerHP
@onready var _fish_hp: VBoxContainer = $SafeRoot/FishHP
@onready var _timer: PanelContainer = $SafeRoot/RoundTimer
@onready var _widget: TelegraphWidget = $SafeRoot/TelegraphWidget
@onready var _controls: Control = $SafeRoot/MobileControls
@onready var _dodge_left: GameButton = $SafeRoot/MobileControls/DodgeLeftButton
@onready var _dodge_right: GameButton = $SafeRoot/MobileControls/DodgeRightButton
@onready var _jab: GameButton = $SafeRoot/MobileControls/JabButton
@onready var _cross: GameButton = $SafeRoot/MobileControls/CrossButton

var _player_bar: ProgressBar
var _fish_bar: ProgressBar
var _fish_name: Label
var _timer_label: Label
var _pause_button: GameButton
var _banner_title: Label
var _banner_body: Label
var _banner_left: float = 0.0
var _timer_urgent: bool = false
var _hint: Label
var _keys: Label


func _ready() -> void:
	_player_bar = _build_hp(_player_hp, TextDb.t(&"boxing.hud.player"), UiTokens.GRASS_500, HORIZONTAL_ALIGNMENT_LEFT)
	_fish_bar = _build_hp(_fish_hp, "", UiTokens.TERRACOTTA_500, HORIZONTAL_ALIGNMENT_RIGHT)
	_fish_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	_fish_name = _fish_hp.get_child(0)
	_build_timer()
	_build_labels()
	_build_controls()

	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(_on_layout_changed)
	InputManager.input_device_changed.connect(_on_layout_changed)
	_layout.call_deferred()


func _process(delta: float) -> void:
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner_title.visible = false
			_banner_body.visible = false


# --- Called by the boxing scene ---------------------------------------------

func setup(fish: FishData, snapshot: Dictionary) -> void:
	_fish_name.text = fish.display_name.to_upper()
	_player_bar.max_value = float(snapshot["player_max_hp"])
	_player_bar.value = float(snapshot["player_hp"])
	_fish_bar.max_value = float(snapshot["fish_max_hp"])
	_fish_bar.value = float(snapshot["fish_hp"])
	_widget.clear()
	show_hint("")
	refresh(snapshot, 0.0)


## Brings every read-out up to date with the fight.
func refresh(snapshot: Dictionary, delta: float) -> void:
	# HP slides to its new value, so a hit reads as a loss and not a jump.
	var step := delta * HP_CATCH_UP_PER_SEC if delta > 0.0 else 1.0
	_player_bar.value = move_toward(_player_bar.value, float(snapshot["player_hp"]), step * _player_bar.max_value)
	_fish_bar.value = move_toward(_fish_bar.value, float(snapshot["fish_hp"]), step * _fish_bar.max_value)

	var sudden: bool = snapshot["sudden_death"]
	var seconds := ceili(float(snapshot["time_left"]))
	_timer_label.text = TextDb.t(&"boxing.hud.sudden_death") if sudden else TextDb.tf(&"boxing.hud.timer", {"seconds": seconds})
	# The last seconds are marked by a heavier frame as well as a colour.
	var urgent := sudden or float(snapshot["time_left"]) <= LOW_TIME_SEC
	if urgent != _timer_urgent:
		_timer_urgent = urgent
		_timer.add_theme_stylebox_override(&"panel", _timer_style(urgent))

	var telegraph_sec := maxf(float(snapshot["telegraph_sec"]), 0.01)
	if snapshot["attack_direction"] != &"":
		_widget.show_telegraph(
			snapshot["attack_direction"], float(snapshot["time_to_impact"]) / telegraph_sec,
			GameData.get_boxing_config().perfect_dodge_window_sec / telegraph_sec, snapshot["in_perfect_window"])
	elif snapshot["counter_open"]:
		var config := GameData.get_boxing_config()
		var window := config.perfect_counter_sec if snapshot["counter_perfect"] else config.normal_counter_sec
		_widget.show_counter(snapshot["counter_perfect"], float(snapshot["counter_left"]) / window)
	else:
		_widget.clear()


## A headline over the fight for a few seconds (round start, sudden death).
func show_banner(title: String, body: String, seconds: float) -> void:
	_banner_title.text = title
	_banner_title.visible = title != ""
	_banner_body.text = body
	_banner_body.visible = body != ""
	_banner_left = seconds


## One line of tutorial guidance under the HP bars; an empty text hides it.
func show_hint(text: String) -> void:
	_hint.text = text
	_hint.visible = text != ""


func get_hint_text() -> String:
	return _hint.text if _hint.visible else ""


func get_widget() -> TelegraphWidget:
	return _widget


func get_shown_hp() -> Vector2:
	return Vector2(_player_bar.value, _fish_bar.value)


func uses_touch_layout() -> bool:
	return InputManager.is_touch_primary() or PlatformService.get_viewport_class() == PlatformService.PORTRAIT


# --- Construction -----------------------------------------------------------

func _build_hp(box: VBoxContainer, title: String, fill: Color, alignment: HorizontalAlignment) -> ProgressBar:
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	var label := Label.new()
	label.name = "Name"
	label.text = title
	label.horizontal_alignment = alignment
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(label, UiTokens.FONT_BUTTON, UiTokens.CREAM_50, 7)
	box.add_child(label)

	var bar := ProgressBar.new()
	bar.name = "Bar"
	bar.show_percentage = false
	bar.custom_minimum_size.y = BAR_HEIGHT
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill
	fill_box.border_color = UiTokens.INK_900
	fill_box.set_border_width_all(2)
	fill_box.set_corner_radius_all(5)
	bar.add_theme_stylebox_override(&"fill", fill_box)
	var back_box := StyleBoxFlat.new()
	back_box.bg_color = Color(UiTokens.INK_900, 0.7)
	back_box.border_color = UiTokens.INK_900
	back_box.set_border_width_all(2)
	back_box.set_corner_radius_all(5)
	bar.add_theme_stylebox_override(&"background", back_box)
	box.add_child(bar)
	return bar


func _build_timer() -> void:
	_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer.add_theme_stylebox_override(&"panel", _timer_style(false))
	_timer_label = Label.new()
	_timer_label.name = "Seconds"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size.x = 64.0
	_timer_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_HEADER)
	_timer.add_child(_timer_label)

	_pause_button = GameButton.new()
	_pause_button.name = "PauseButton"
	HudChip.make_pause_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_safe_root.add_child(_pause_button)


func _timer_style(urgent: bool) -> StyleBoxFlat:
	var box := HudChip.make_style()
	if urgent:
		box.bg_color = UiTokens.SUN_500
		box.border_color = UiTokens.INK_900
		box.set_border_width_all(4)
	return box


func _build_labels() -> void:
	_banner_title = _outlined(40)
	_banner_title.name = "BannerTitle"
	_banner_body = _outlined(UiTokens.FONT_HEADER)
	_banner_body.name = "BannerBody"
	_hint = _outlined(UiTokens.FONT_BUTTON)
	_hint.name = "Hint"
	_keys = _outlined(UiTokens.FONT_SMALL)
	_keys.name = "KeyHints"
	for label: Label in [_banner_title, _banner_body, _hint]:
		label.visible = false


func _outlined(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(label, font_size)
	_safe_root.add_child(label)
	return label


func _build_controls() -> void:
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var buttons: Dictionary[GameButton, Array] = {
		_dodge_left: [&"boxing.button.dodge_left", &"box_dodge_left", &""],
		_dodge_right: [&"boxing.button.dodge_right", &"box_dodge_right", &""],
		_jab: [&"boxing.button.jab", &"box_jab", UiTokens.TYPE_CTA_BUTTON],
		_cross: [&"boxing.button.cross", &"box_cross", UiTokens.TYPE_CTA_BUTTON],
	}
	for button: GameButton in buttons:
		var spec: Array = buttons[button]
		button.text = TextDb.t(spec[0])
		button.focus_mode = Control.FOCUS_NONE
		button.click_sfx = &""
		button.add_theme_font_size_override(&"font_size", 26)
		if spec[2] != &"":
			button.theme_type_variation = spec[2]
		# A touch acts on press, like a key, not on release.
		button.button_down.connect(InputManager.press_action.bind(spec[1]))
		button.button_up.connect(InputManager.release_action.bind(spec[1]))


## The four keys as they are bound right now, so a remap shows up here.
func _key_hint_text() -> String:
	return TextDb.tf(&"boxing.keys", {
		"left": _key_name(&"box_dodge_left"), "right": _key_name(&"box_dodge_right"),
		"jab": _key_name(&"box_jab"), "cross": _key_name(&"box_cross"),
	})


func _key_name(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
			return OS.get_keycode_string(code)
	return "?"


# --- Layout -----------------------------------------------------------------

func _on_layout_changed(_value: StringName) -> void:
	_layout()


## Places every block for the current screen shape and input device.
func _layout() -> void:
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var touch := uses_touch_layout()
	var area := _safe_root.size
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	var gap := float(UiTokens.SPACE_12)

	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	var bars_top := 0.0
	var bars_right := area.x - row - gap
	var bar_width := minf(BAR_WIDTH_LANDSCAPE, (bars_right - 120.0) * 0.5)
	if portrait:
		# The clock shares the top row with Pause; the bars get their own row.
		bars_top = row + gap
		bars_right = area.x
		bar_width = (area.x - gap) * 0.5
		_place(_timer, Rect2((area.x - 96.0) * 0.5, 0.0, 96.0, row))
	else:
		_place(_timer, Rect2((bars_right - 96.0) * 0.5, 0.0, 96.0, row))
	var bar_block := BAR_HEIGHT + 34.0
	_place(_player_hp, Rect2(0.0, bars_top, bar_width, bar_block))
	_place(_fish_hp, Rect2(bars_right - bar_width, bars_top, bar_width, bar_block))

	var under_bars := bars_top + bar_block + gap
	var widget_width := minf(WIDGET_SIZE.x, area.x)
	_place(_widget, Rect2((area.x - widget_width) * 0.5, under_bars + 34.0, widget_width, WIDGET_SIZE.y))
	_place(_hint, Rect2(0.0, under_bars, area.x, 32.0))
	_place(_banner_title, Rect2(0.0, area.y * (0.2 if portrait else 0.3), area.x, 56.0))
	_place(_banner_body, Rect2(0.0, area.y * (0.2 if portrait else 0.3) + 58.0, area.x, 40.0))

	_controls.visible = touch
	_keys.visible = not touch
	_keys.text = _key_hint_text()
	_place(_keys, Rect2(0.0, area.y - 30.0, area.x, 30.0))
	if portrait:
		# Bottom 38%: dodge on the left half, punches on the right half.
		var top := roundf(area.y * FIGHT_SHARE_PORTRAIT) + gap
		_place(_controls, Rect2(0.0, top, area.x, area.y - top))
	else:
		var height := 96.0
		_place(_controls, Rect2(0.0, area.y - height, area.x, height))
	_layout_controls(portrait)


## Dodge buttons sit under the left thumb, punches under the right; a
## left-handed layout swaps the two groups (GDD 189.12). Inside a group the
## order never changes, so DODGE LEFT is always the left one of the pair.
func _layout_controls(portrait: bool) -> void:
	var box := _controls.size
	var gap := float(UiTokens.SPACE_12)
	var dodges := [_dodge_left, _dodge_right]
	var punches := [_jab, _cross]
	var first: Array = punches if UiTokens.is_left_handed() else dodges
	var second: Array = dodges if UiTokens.is_left_handed() else punches
	if portrait:
		var half := (box.x - gap) * 0.5
		var button := Vector2((half - gap) * 0.5, minf(box.y, 220.0))
		var top := (box.y - button.y) * 0.5
		_place(first[0], Rect2(0.0, top, button.x, button.y))
		_place(first[1], Rect2(button.x + gap, top, button.x, button.y))
		_place(second[0], Rect2(half + gap, top, button.x, button.y))
		_place(second[1], Rect2(half + gap * 2.0 + button.x, top, button.x, button.y))
	else:
		var button := Vector2(168.0, box.y)
		_place(first[0], Rect2(0.0, 0.0, button.x, button.y))
		_place(first[1], Rect2(button.x + gap, 0.0, button.x, button.y))
		_place(second[0], Rect2(box.x - button.x * 2.0 - gap, 0.0, button.x, button.y))
		_place(second[1], Rect2(box.x - button.x, 0.0, button.x, button.y))


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
