class_name FishingHud
extends CanvasLayer
## Fishing HUD (GDD 93, 147, 167.9, 168.4). It shows only what the moment
## needs: cash, bucket count, one contextual prompt, the reel read-out while
## reeling, and the Market and Pause buttons.
##
## Tutorial prompts appear one at a time and stop once the player has done the
## thing. Touch layouts add one large contextual button; it feeds the same
## input actions as the keyboard and mouse.

signal pause_pressed()
signal market_pressed()
signal bucket_pressed()

const ACTION_BUTTON_SIZE := Vector2(260.0, 76.0)
const TRACK_HEIGHT_LANDSCAPE := 320.0
const TRACK_HEIGHT_PORTRAIT := 400.0

@onready var _safe_root: Control = $SafeRoot
@onready var _top_bar: HBoxContainer = $SafeRoot/TopBar
@onready var _cash_widget: PanelContainer = $SafeRoot/TopBar/CashWidget
@onready var _bucket_widget: Button = $SafeRoot/TopBar/BucketWidget
@onready var _prompt: VBoxContainer = $SafeRoot/ContextPrompt
@onready var _reel_hud: ReelHud = $SafeRoot/ReelHUD
@onready var _action_button: GameButton = $SafeRoot/ContextActionButton
@onready var _market_button: GameButton = $SafeRoot/MarketButton
@onready var _pause_button: GameButton = $SafeRoot/PauseButton

var _cash_label: Label
var _bucket_label: Label
var _prompt_label: Label
var _sub_label: Label
var _strike_bar: ProgressBar
var _state: StringName = FishingController.STATE_IDLE
var _banner_left: float = 0.0
var _hint_left: float = 0.0
var _market_available: bool = false


func _ready() -> void:
	_build_top_bar()
	_build_prompt()
	_build_buttons()
	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(_on_layout_changed)
	InputManager.input_device_changed.connect(_on_layout_changed)
	GameState.cash_changed.connect(set_cash)
	GameState.bucket_changed.connect(set_bucket_count)
	set_cash(GameState.get_cash())
	set_bucket_count(GameState.get_bucket_total_count())
	set_state(FishingController.STATE_IDLE)
	_layout.call_deferred()


func _process(delta: float) -> void:
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_refresh_prompt()
	if _hint_left > 0.0:
		_hint_left -= delta
		if _hint_left <= 0.0:
			_refresh_prompt()


# --- Called by the fishing scene --------------------------------------------

func set_cash(cash: int) -> void:
	_cash_label.text = Money.format_rp(cash)


func set_bucket_count(count: int) -> void:
	_bucket_label.text = TextDb.tf(&"fishing.hud.bucket", {"count": count})


func set_market_available(available: bool) -> void:
	_market_available = available
	_refresh_buttons()


func set_state(state: StringName) -> void:
	_state = state
	if state == FishingController.STATE_REELING:
		_reel_hud.show_reel()
	else:
		_reel_hud.hide_reel()
	if state != FishingController.STATE_LANDED and state != FishingController.STATE_ESCAPED:
		_banner_left = 0.0
	_hint_left = 0.0
	_refresh_prompt()
	_refresh_buttons()


func set_strike_ratio(ratio: float) -> void:
	_strike_bar.value = ratio


func update_reel(reel: ReelSimulation, held: bool, delta: float) -> void:
	_reel_hud.update_reel(reel, held, delta)
	if GameState.is_tutorial_seen(&"reeling_seen") or _banner_left > 0.0:
		return
	# First reel: teach one thing at a time, in the order it matters.
	if reel.get_stress_band() >= 2:
		_show(TextDb.t(&"fishing.prompt.release"), "", false)
	elif not held:
		_show(TextDb.t(_by_device(&"fishing.prompt.reel_keyboard", &"fishing.prompt.reel_touch")), "", false)
	else:
		_show(TextDb.t(&"fishing.prompt.zone"), "", false)


## A headline that takes over the prompt for a few seconds (catch reveal,
## escape). `accent` uses the large critical-prompt size.
func show_banner(title: String, subtitle: String, seconds: float, accent: bool = true) -> void:
	_banner_left = seconds
	_show(title, subtitle, accent)
	_strike_bar.visible = false


## A short tutorial line that gives way to the normal prompt afterwards.
func show_hint(text: String, seconds: float) -> void:
	if _banner_left > 0.0:
		return
	_hint_left = seconds
	_show(text, "", false)


# --- Prompt -----------------------------------------------------------------

func _refresh_prompt() -> void:
	if _banner_left > 0.0 or _hint_left > 0.0:
		return
	_strike_bar.visible = _state == FishingController.STATE_STRIKE_WINDOW
	var learning := not GameState.is_tutorial_seen(&"fishing_seen")
	match _state:
		FishingController.STATE_IDLE:
			if learning:
				_show(TextDb.t(_by_device(&"fishing.prompt.cast_keyboard", &"fishing.prompt.cast_touch")), "", false)
			else:
				_show("", "", false)
		FishingController.STATE_WAITING:
			_show(TextDb.t(&"fishing.prompt.wait") if learning else "", "", false)
		FishingController.STATE_BITE_WARNING:
			_show(TextDb.t(&"fishing.prompt.warning"), "", false)
		FishingController.STATE_STRIKE_WINDOW:
			_show(TextDb.t(&"fishing.prompt.strike"), "", true)
		_:
			_show("", "", false)


func _show(title: String, subtitle: String, accent: bool) -> void:
	_prompt_label.text = title
	_prompt_label.visible = title != ""
	_prompt_label.add_theme_font_size_override(&"font_size", 34 if accent else UiTokens.FONT_HEADER)
	_sub_label.text = subtitle
	_sub_label.visible = subtitle != ""


func _by_device(keyboard_key: StringName, touch_key: StringName) -> StringName:
	return touch_key if _uses_touch_layout() else keyboard_key


func _uses_touch_layout() -> bool:
	return InputManager.is_touch_primary() or PlatformService.get_viewport_class() == PlatformService.PORTRAIT


# --- Buttons ----------------------------------------------------------------

func _refresh_buttons() -> void:
	var idle := _state == FishingController.STATE_IDLE
	_market_button.disabled = not (idle and _market_available)
	_action_button.visible = _uses_touch_layout()
	match _state:
		FishingController.STATE_IDLE:
			_set_action(&"fishing.action.cast", false)
		FishingController.STATE_WAITING, FishingController.STATE_BITE_WARNING, FishingController.STATE_STRIKE_WINDOW:
			_set_action(&"fishing.action.strike", false)
		FishingController.STATE_REELING:
			_set_action(&"fishing.action.reel", false)
		_:
			_set_action(&"fishing.action.wait", true)


func _set_action(text_key: StringName, disabled: bool) -> void:
	_action_button.text = TextDb.t(text_key)
	_action_button.disabled = disabled


func _on_action_down() -> void:
	InputManager.press_action(&"fish_cast")
	InputManager.press_action(&"fish_reel")


func _on_action_up() -> void:
	InputManager.release_action(&"fish_cast")
	InputManager.release_action(&"fish_reel")


# --- Construction -----------------------------------------------------------

func _build_top_bar() -> void:
	_top_bar.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	_cash_widget.add_theme_stylebox_override(&"panel", HudChip.make_style())
	_cash_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cash_label = HudChip.add_content(_cash_widget, UiIcon.ICON_CASH)
	_cash_label.custom_minimum_size.x = 118.0

	_bucket_widget.custom_minimum_size = Vector2(170.0, UiTokens.TOUCH_TARGET_MIN)
	_bucket_widget.focus_mode = Control.FOCUS_NONE
	_bucket_label = HudChip.add_content(_bucket_widget, UiIcon.ICON_BUCKET)
	_bucket_widget.pressed.connect(func() -> void: bucket_pressed.emit())


func _build_prompt() -> void:
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.alignment = BoxContainer.ALIGNMENT_BEGIN
	_prompt.add_theme_constant_override(&"separation", UiTokens.SPACE_8)

	_prompt_label = _outlined_label(UiTokens.FONT_HEADER)
	_prompt.add_child(_prompt_label)
	_sub_label = _outlined_label(UiTokens.FONT_BODY)
	_prompt.add_child(_sub_label)

	# The reaction bar drains while the strike window is open.
	_strike_bar = ProgressBar.new()
	_strike_bar.name = "StrikeBar"
	_strike_bar.max_value = 1.0
	_strike_bar.show_percentage = false
	_strike_bar.custom_minimum_size = Vector2(300.0, 16.0)
	_strike_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_strike_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strike_bar.visible = false
	_prompt.add_child(_strike_bar)


func _outlined_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(label, font_size)
	return label


func _build_buttons() -> void:
	_action_button.custom_minimum_size = ACTION_BUTTON_SIZE
	_action_button.theme_type_variation = UiTokens.TYPE_CTA_BUTTON
	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.click_sfx = &""
	_action_button.add_theme_font_size_override(&"font_size", 26)
	_action_button.button_down.connect(_on_action_down)
	_action_button.button_up.connect(_on_action_up)

	_market_button.focus_mode = Control.FOCUS_NONE
	_market_button.custom_minimum_size = Vector2(170.0, UiTokens.TOUCH_TARGET_PREFERRED)
	var market_label := HudChip.add_content(_market_button, UiIcon.ICON_MARKET)
	market_label.text = TextDb.t(&"fishing.hud.market")
	_market_button.pressed.connect(func() -> void: market_pressed.emit())

	HudChip.make_pause_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())


# --- Layout -----------------------------------------------------------------

func _on_layout_changed(_value: StringName) -> void:
	_layout()
	_refresh_prompt()
	_refresh_buttons()


## Anchors every block to its place for the current viewport class. Positions
## come from anchors and container sizes only, never fixed screen coordinates.
func _layout() -> void:
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var area := _safe_root.size

	UiTokens.anchor_at(_top_bar, Control.PRESET_TOP_LEFT)
	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	UiTokens.anchor_at(_market_button, Control.PRESET_BOTTOM_LEFT)
	UiTokens.anchor_at(_action_button, Control.PRESET_CENTER_BOTTOM)
	if portrait:
		# Keep the big button clear of the Market button on narrow screens.
		_action_button.offset_top -= UiTokens.TOUCH_TARGET_PREFERRED + UiTokens.SPACE_16
		_action_button.offset_bottom -= UiTokens.TOUCH_TARGET_PREFERRED + UiTokens.SPACE_16

	# Prompt: a centred column under the top bar.
	var prompt_width := minf(area.x - UiTokens.SPACE_32, 620.0)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_prompt.offset_left = -prompt_width * 0.5
	_prompt.offset_right = prompt_width * 0.5
	_prompt.offset_top = 84.0 if portrait else 72.0
	_prompt.offset_bottom = _prompt.offset_top + 180.0

	# Reel read-out: right edge, vertically centred.
	_reel_hud.set_track_height(TRACK_HEIGHT_PORTRAIT if portrait else TRACK_HEIGHT_LANDSCAPE)
	var reel_size := _reel_hud.custom_minimum_size
	_reel_hud.set_home(Vector2(area.x - reel_size.x - UiTokens.SPACE_16, (area.y - reel_size.y) * 0.5 - (40.0 if portrait else 0.0)))
