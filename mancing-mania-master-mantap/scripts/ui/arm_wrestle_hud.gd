class_name ArmWrestleHud
extends CanvasLayer
## Arm wrestling HUD (GDD 50-56, 95, 167.9, 168.8): the position bar, Darto's
## stamina with its power bands, the round clock, the burst warning and the
## big MASH button.
##
## The MASH button is one large target in the bottom part of the screen on
## touch layouts (GDD Section 95) and feeds the same `arm_mash` action as the
## keyboard. Keyboard players see their key named instead.

signal pause_pressed()

const MASH_HEIGHT_PORTRAIT_SHARE := 0.3
const MASH_SIZE_LANDSCAPE := Vector2(420.0, 120.0)
const STAMINA_HEIGHT := 22.0
const LOW_TIME_SEC := 8.0
const WARNING_PULSE_HZ := 5.0

@onready var _safe_root: Control = $SafeRoot
@onready var _position_bar: PositionBar = $SafeRoot/PositionBar
@onready var _stamina_box: VBoxContainer = $SafeRoot/StaminaBar
@onready var _timer: PanelContainer = $SafeRoot/RoundTimer
@onready var _warning: Label = $SafeRoot/BurstWarning
@onready var _mash: GameButton = $SafeRoot/MashButton

var _stamina_bar: ProgressBar
var _power_label: Label
var _timer_label: Label
var _timer_urgent: bool = false
var _pause_button: GameButton
var _banner_title: Label
var _banner_body: Label
var _banner_left: float = 0.0
var _hint: Label
var _keys: Label
var _clock: float = 0.0
var _warning_on: bool = false


func _ready() -> void:
	_build_position()
	_build_stamina()
	_build_timer()
	_build_labels()
	_build_mash()
	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(_on_layout_changed)
	InputManager.input_device_changed.connect(_on_layout_changed)
	_layout.call_deferred()


func _process(delta: float) -> void:
	_clock += delta
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner_title.visible = false
			_banner_body.visible = false
	if _warning_on:
		# The warning pulses in size, not just in colour (GDD 189.5).
		var pulse := 1.0 + 0.08 * sin(_clock * TAU * WARNING_PULSE_HZ)
		if GameState.get_setting(&"reduced_motion"):
			pulse = 1.0
		_warning.pivot_offset = _warning.size * 0.5
		_warning.scale = Vector2.ONE * pulse


# --- Called by the arm wrestling scene --------------------------------------

func setup(fish: FishData) -> void:
	_position_bar.set_names(TextDb.t(&"boxing.hud.player"), fish.display_name.to_upper())
	_position_bar.grip_band = GameData.get_arm_wrestle_config().sudden_grip_threshold
	show_hint("")


func refresh(snapshot: Dictionary) -> void:
	_position_bar.position_value = float(snapshot["position"])
	_stamina_bar.max_value = float(snapshot["max_stamina"])
	_stamina_bar.value = float(snapshot["stamina"])
	_power_label.text = TextDb.tf(&"arm.hud.power", {"percent": roundi(float(snapshot["power"]) * 100.0)})

	var label := TextDb.tf(&"boxing.hud.timer", {"seconds": ceili(float(snapshot["time_left"]))})
	if snapshot["sudden_grip"]:
		label = TextDb.t(&"arm.hud.sudden_grip")
	_timer_label.text = label
	var urgent: bool = snapshot["sudden_grip"] or float(snapshot["time_left"]) <= LOW_TIME_SEC
	if urgent != _timer_urgent:
		_timer_urgent = urgent
		var box := HudChip.make_style()
		if urgent:
			box.bg_color = UiTokens.SUN_500
			box.border_color = UiTokens.INK_900
			box.set_border_width_all(4)
		_timer.add_theme_stylebox_override(&"panel", box)

	var warning: bool = snapshot["burst_warning"] or snapshot["bursting"]
	_warning_on = warning
	_warning.visible = warning
	_warning.text = TextDb.t(&"arm.hud.burst" if snapshot["bursting"] else &"arm.hud.burst_warning")
	if not warning:
		_warning.scale = Vector2.ONE


func show_banner(title: String, body: String, seconds: float) -> void:
	_banner_title.text = title
	_banner_title.visible = title != ""
	_banner_body.text = body
	_banner_body.visible = body != ""
	_banner_left = seconds


func show_hint(text: String) -> void:
	_hint.text = text
	_hint.visible = text != ""


func get_hint_text() -> String:
	return _hint.text if _hint.visible else ""


func is_warning_visible() -> bool:
	return _warning.visible


func get_position_bar() -> PositionBar:
	return _position_bar


func uses_touch_layout() -> bool:
	return InputManager.is_touch_primary() or PlatformService.get_viewport_class() == PlatformService.PORTRAIT


# --- Construction -----------------------------------------------------------

func _build_position() -> void:
	_position_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_stamina() -> void:
	_stamina_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_box.add_theme_constant_override(&"separation", 2)
	_power_label = Label.new()
	_power_label.name = "Power"
	_power_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(_power_label, UiTokens.FONT_SMALL, UiTokens.CREAM_50, 6)
	_stamina_box.add_child(_power_label)
	_stamina_bar = ProgressBar.new()
	_stamina_bar.name = "Bar"
	_stamina_bar.show_percentage = false
	_stamina_bar.custom_minimum_size.y = STAMINA_HEIGHT
	_stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiTokens.LAKE_500
	fill.border_color = UiTokens.INK_900
	fill.set_border_width_all(2)
	fill.set_corner_radius_all(5)
	_stamina_bar.add_theme_stylebox_override(&"fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(UiTokens.INK_900, 0.7)
	back.border_color = UiTokens.INK_900
	back.set_border_width_all(2)
	back.set_corner_radius_all(5)
	_stamina_bar.add_theme_stylebox_override(&"background", back)
	_stamina_box.add_child(_stamina_bar)
	# Notches where the power bands change (GDD Section 53).
	_stamina_bar.draw.connect(func() -> void:
		for share: float in [0.1, 0.3, 0.6]:
			var x := _stamina_bar.size.x * share
			_stamina_bar.draw_line(Vector2(x, 0.0), Vector2(x, _stamina_bar.size.y), UiTokens.CREAM_50, 2.0))


func _build_timer() -> void:
	_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer.add_theme_stylebox_override(&"panel", HudChip.make_style())
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size.x = 64.0
	_timer_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_HEADER)
	_timer.add_child(_timer_label)
	_pause_button = GameButton.new()
	_pause_button.name = "PauseButton"
	HudChip.make_pause_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_safe_root.add_child(_pause_button)


func _build_labels() -> void:
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_warning.visible = false
	UiTokens.outline_text(_warning, 30, UiTokens.SUN_500)
	_banner_title = _outlined(40)
	_banner_body = _outlined(UiTokens.FONT_HEADER)
	_hint = _outlined(UiTokens.FONT_BUTTON)
	_keys = _outlined(UiTokens.FONT_SMALL)
	_banner_title.visible = false
	_banner_body.visible = false
	_hint.visible = false


func _outlined(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(label, font_size)
	_safe_root.add_child(label)
	return label


func _build_mash() -> void:
	_mash.text = TextDb.t(&"arm.button.hold" if HoldAssist.is_enabled() else &"arm.button.mash")
	_mash.theme_type_variation = UiTokens.TYPE_CTA_BUTTON
	_mash.focus_mode = Control.FOCUS_NONE
	_mash.click_sfx = &""
	_mash.add_theme_font_size_override(&"font_size", 44)
	# Each touch is one press, on the way down (GDD 176.1).
	_mash.button_down.connect(InputManager.press_action.bind(&"arm_mash"))
	_mash.button_up.connect(InputManager.release_action.bind(&"arm_mash"))


func _key_name(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return "?"


# --- Layout -----------------------------------------------------------------

func _on_layout_changed(_value: StringName) -> void:
	_layout()


func _layout() -> void:
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var touch := uses_touch_layout()
	var area := _safe_root.size
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	var gap := float(UiTokens.SPACE_12)

	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	_place(_timer, Rect2((area.x - 96.0) * 0.5, 0.0, 96.0, row))
	var bar_width := minf(area.x, 640.0)
	if portrait:
		# Characters in the top 60%, bars in the middle, MASH in the bottom 30%.
		var mash_top := roundf(area.y * (1.0 - MASH_HEIGHT_PORTRAIT_SHARE))
		_place(_mash, Rect2(0.0, mash_top, area.x, area.y - mash_top))
		var bars_top := roundf(area.y * 0.6)
		_place(_position_bar, Rect2(0.0, bars_top, area.x, 60.0))
		_place(_stamina_box, Rect2(0.0, bars_top + 66.0, area.x * 0.6, 46.0))
		_place(_warning, Rect2(0.0, bars_top - 56.0, area.x, 48.0))
	else:
		_place(_position_bar, Rect2((area.x - bar_width) * 0.5, row + gap, bar_width, 60.0))
		_place(_stamina_box, Rect2((area.x - bar_width) * 0.5, row + gap + 66.0, bar_width * 0.5, 46.0))
		_place(_warning, Rect2(0.0, row + gap + 120.0, area.x, 48.0))
		_place(_mash, Rect2(area.x - MASH_SIZE_LANDSCAPE.x, area.y - MASH_SIZE_LANDSCAPE.y, MASH_SIZE_LANDSCAPE.x, MASH_SIZE_LANDSCAPE.y))
	_mash.visible = touch
	_keys.visible = not touch
	_keys.text = TextDb.tf(&"arm.keys", {"key": _key_name(&"arm_mash")})
	_place(_keys, Rect2(0.0, area.y - 30.0, area.x, 30.0))
	_place(_hint, Rect2(0.0, (area.y * 0.6 - 100.0) if portrait else (area.y - 72.0), area.x, 32.0))
	_place(_banner_title, Rect2(0.0, area.y * 0.25, area.x, 56.0))
	_place(_banner_body, Rect2(0.0, area.y * 0.25 + 58.0, area.x, 40.0))


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
