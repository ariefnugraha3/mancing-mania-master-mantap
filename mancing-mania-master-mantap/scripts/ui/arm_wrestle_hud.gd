class_name ArmWrestleHud
extends CanvasLayer
## Arm wrestling HUD (GDD 50-56, 95, 167.9, 168.8): the position bar, Darto's
## stamina with its power bands, the round clock, the burst warning and the
## big MASH button.
##
## The portrait screen keeps Darto and the fish at the table in the upper
## part, the bars just above the thumbs, and one large MASH button across the
## bottom (GDD Section 95). It feeds the same `arm_mash` action as the
## keyboard; the key is named above it while a keyboard is in use.

signal pause_pressed()

## MASH fills this share of the screen height, within MASH_HEIGHT_RANGE.
const MASH_HEIGHT_PORTRAIT_SHARE := 0.28
const MASH_HEIGHT_RANGE := Vector2(150.0, 240.0)
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
		_timer.add_theme_stylebox_override(&"panel", HudChip.timer_style(urgent))

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


## The portrait screen always shows the MASH button.
func uses_touch_layout() -> bool:
	return true


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
	HudChip.style_bar(_stamina_bar, UiTokens.LAKE_500)
	_stamina_box.add_child(_stamina_bar)
	# Notches where the power bands change (GDD Section 53).
	_stamina_bar.draw.connect(func() -> void:
		for share: float in [0.1, 0.3, 0.6]:
			var x := _stamina_bar.size.x * share
			_stamina_bar.draw_line(Vector2(x, 3.0), Vector2(x, _stamina_bar.size.y - 3.0), Color(UiTokens.CREAM_50, 0.85), 3.0))


func _build_timer() -> void:
	_timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timer.add_theme_stylebox_override(&"panel", HudChip.timer_style(false))
	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.custom_minimum_size.x = 64.0
	_timer_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_HEADER)
	_timer_label.add_theme_font_override(&"font", UiSkin.heavy_font())
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
	UiSkin.sign_text(_banner_title, 44, DioramaStyle.BUTTER, 12)
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

func _on_layout_changed(_value: StringName = &"") -> void:
	_layout()


func _layout() -> void:
	var area := _safe_root.size
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	var gap := float(UiTokens.SPACE_12)

	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	_place(_timer, Rect2((area.x - 88.0) * 0.5, 0.0, 88.0, row))
	# Bottom: MASH across the full width, in reach of both thumbs.
	var mash_height := clampf(roundf(area.y * MASH_HEIGHT_PORTRAIT_SHARE), MASH_HEIGHT_RANGE.x, MASH_HEIGHT_RANGE.y)
	var mash_top := area.y - mash_height
	_place(_mash, Rect2(0.0, mash_top, area.x, mash_height))
	_mash.visible = true
	# Just above it: the position bar, then Darto's stamina, read at a glance.
	var bar_width := minf(area.x, 560.0)
	var bar_left := (area.x - bar_width) * 0.5
	var stamina_top := mash_top - gap - 46.0
	var bars_top := stamina_top - UiTokens.SPACE_8 - 60.0
	_place(_position_bar, Rect2(bar_left, bars_top, bar_width, 60.0))
	_place(_stamina_box, Rect2(bar_left, stamina_top, bar_width * 0.66, 46.0))
	_place(_warning, Rect2(0.0, bars_top - 100.0, area.x, 48.0))
	_keys.visible = InputManager.is_keyboard_active()
	_keys.text = TextDb.tf(&"arm.keys", {"key": _key_name(&"arm_mash")})
	_place(_keys, Rect2(0.0, mash_top - 30.0, area.x, 28.0))
	_place(_hint, Rect2(0.0, bars_top - 72.0, area.x, 64.0))
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	UiTokens.place_banner(_banner_title, _banner_body, area.y * 0.12, area.x)


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
