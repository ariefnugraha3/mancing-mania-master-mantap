class_name FishingHud
extends CanvasLayer
## Fishing HUD (GDD 93, 147, 167.9, 168.4). It shows only what the moment
## needs: cash, bucket count, one contextual prompt, the reel read-out while
## reeling, and the Market and Pause buttons.
##
## Tutorial prompts appear one at a time and stop once the player has done the
## thing. The portrait screen is laid out for thumbs: the chips and Pause along
## the top, and one thumb row at the bottom with the large contextual button
## (CAST / STRIKE / REEL) and the Market button. The contextual button feeds
## the same input actions as the keyboard and mouse.

signal pause_pressed()
signal market_pressed()
signal bucket_pressed()

## The bottom thumb row: the contextual button and the Market button.
const THUMB_ROW_HEIGHT := 84.0
const MARKET_WIDTH := 96.0
## The thumb row never gets wider than this (tablets).
const THUMB_ROW_MAX_WIDTH := 520.0
const TRACK_HEIGHT_PHONE := 300.0
const TRACK_HEIGHT_TABLET := 360.0

@onready var _safe_root: Control = $SafeRoot
@onready var _top_bar: HFlowContainer = $SafeRoot/TopBar
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


## The bucket chip shows the bucket badge and the count; the full wording is
## its tooltip and accessibility name.
func set_bucket_count(count: int) -> void:
	_bucket_label.text = str(count)
	_bucket_widget.tooltip_text = TextDb.tf(&"fishing.hud.bucket", {"count": count})


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
	_prompt_label.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(34 if accent else UiTokens.FONT_HEADER))
	_sub_label.text = subtitle
	_sub_label.visible = subtitle != ""


func _by_device(keyboard_key: StringName, touch_key: StringName) -> StringName:
	return keyboard_key if InputManager.is_keyboard_active() else touch_key


## The portrait screen always shows the touch controls; keyboard wording is
## used only while a keyboard is the active device.
func _uses_touch_layout() -> bool:
	return true


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
	# A flow: on a narrow screen (or at a large UI scale) the bucket chip
	# drops under the cash chip instead of running into Pause.
	_top_bar.add_theme_constant_override(&"h_separation", UiTokens.SPACE_8)
	_top_bar.add_theme_constant_override(&"v_separation", UiTokens.SPACE_8)
	_cash_widget.add_theme_stylebox_override(&"panel", HudChip.make_style())
	_cash_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cash_label = HudChip.add_content(_cash_widget, UiIcon.ICON_CASH)
	_cash_label.custom_minimum_size.x = 92.0

	_bucket_widget.custom_minimum_size = Vector2(86.0, UiTokens.TOUCH_TARGET_MIN)
	_bucket_widget.focus_mode = Control.FOCUS_NONE
	_bucket_label = HudChip.add_content(_bucket_widget, UiIcon.ICON_BUCKET)
	_bucket_widget.pressed.connect(func() -> void: bucket_pressed.emit())


func _build_prompt() -> void:
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.alignment = BoxContainer.ALIGNMENT_BEGIN
	_prompt.add_theme_constant_override(&"separation", UiTokens.SPACE_8)

	_prompt_label = _outlined_label(UiTokens.FONT_HEADER)
	UiSkin.sign_text(_prompt_label, UiTokens.FONT_HEADER + 4, UiTokens.CREAM_50, 11)
	_prompt.add_child(_prompt_label)
	_sub_label = _outlined_label(UiTokens.FONT_BODY)
	_prompt.add_child(_sub_label)

	# The reaction bar drains while the strike window is open.
	_strike_bar = ProgressBar.new()
	_strike_bar.name = "StrikeBar"
	_strike_bar.max_value = 1.0
	_strike_bar.show_percentage = false
	_strike_bar.custom_minimum_size = Vector2(240.0, 18.0)
	_strike_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_strike_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strike_bar.visible = false
	# High Contrast makes the track opaque and its rim heavier (GDD 189.4).
	HudChip.style_bar(_strike_bar, UiTokens.SUN_500, 9)
	_prompt.add_child(_strike_bar)


func _outlined_label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(label, font_size)
	return label


func _build_buttons() -> void:
	_action_button.custom_minimum_size = Vector2(0.0, THUMB_ROW_HEIGHT)
	_action_button.theme_type_variation = UiTokens.TYPE_CTA_BUTTON
	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.click_sfx = &""
	_action_button.add_theme_font_size_override(&"font_size", 26)
	_action_button.button_down.connect(_on_action_down)
	_action_button.button_up.connect(_on_action_up)

	_market_button.focus_mode = Control.FOCUS_NONE
	_market_button.custom_minimum_size = Vector2(MARKET_WIDTH, THUMB_ROW_HEIGHT)
	var market_label := HudChip.add_stacked_content(_market_button, UiIcon.ICON_MARKET)
	market_label.text = TextDb.t(&"fishing.hud.market")
	_market_button.pressed.connect(func() -> void: market_pressed.emit())

	HudChip.make_pause_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())


# --- Layout -----------------------------------------------------------------

func _on_layout_changed(_value: StringName) -> void:
	_layout()
	_refresh_prompt()
	_refresh_buttons()


## Places every block on the portrait screen. Positions come from the safe
## area and the tokens only, never from fixed screen coordinates.
func _layout() -> void:
	var area := _safe_root.size
	var tablet := PlatformService.is_tablet()

	# Top: Pause on the right, the chips flowing in the space left of it.
	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	var chips_width := maxf(area.x - _pause_button.size.x - UiTokens.SPACE_8, 120.0)
	_top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_top_bar.position = Vector2.ZERO
	_top_bar.size = Vector2(chips_width, 0.0)
	_top_bar.size = Vector2(chips_width, _top_bar.get_combined_minimum_size().y)

	# Bottom: the thumb row. The Market button sits on the side away from the
	# main thumb; Left-handed swaps it (GDD 189.12).
	var row_width := minf(area.x, THUMB_ROW_MAX_WIDTH)
	var row := Rect2((area.x - row_width) * 0.5, area.y - THUMB_ROW_HEIGHT, row_width, THUMB_ROW_HEIGHT)
	var action_width := row.size.x - MARKET_WIDTH - UiTokens.SPACE_12
	var left_handed := UiTokens.is_left_handed()
	_place(_market_button, Rect2(row.position.x + (row.size.x - MARKET_WIDTH if left_handed else 0.0), row.position.y, MARKET_WIDTH, row.size.y))
	_place(_action_button, Rect2(row.position.x + (0.0 if left_handed else MARKET_WIDTH + UiTokens.SPACE_12), row.position.y, action_width, row.size.y))

	# Prompt: a centred column under the top bar.
	var prompt_width := minf(area.x, 560.0)
	_prompt.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt.position = Vector2((area.x - prompt_width) * 0.5, _top_bar.size.y + UiTokens.SPACE_16)
	_prompt.size = Vector2(prompt_width, 180.0)

	# Reel read-out: right edge, centred in the space above the thumb row.
	_reel_hud.set_track_height(TRACK_HEIGHT_TABLET if tablet else TRACK_HEIGHT_PHONE)
	var reel_size := _reel_hud.custom_minimum_size
	var free_top := _top_bar.size.y + UiTokens.SPACE_16
	var free_bottom := row.position.y - UiTokens.SPACE_16
	_reel_hud.set_home(Vector2(area.x - reel_size.x, maxf(free_top, (free_top + free_bottom - reel_size.y) * 0.5)))


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
