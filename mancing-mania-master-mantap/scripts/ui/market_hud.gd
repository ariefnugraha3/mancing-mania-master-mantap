class_name MarketHud
extends CanvasLayer
## Market screen (GDD 73, 167.9, 168.5, 176.16): Bu Yati's ledger. Five tabs in
## a fixed order, one page open at a time, cash always in view and one explicit
## way out.
##
## The ledger sits beside the warung on wide screens and under it on tall
## ones, so Bu Yati and Darto stay visible while the player does business.
## The screen shows state and reports requests; it never changes game state.

signal leave_pressed()
signal pause_pressed()
signal tab_changed(tab_id: StringName)

const TAB_SELL := &"sell"
const TAB_UPGRADES := &"upgrades"
const TAB_DEBT := &"debt"
const TAB_FISH_BOOK := &"fish_book"
const TAB_RECORDS := &"records"
## The order is fixed by GDD 167.9.
const TAB_ORDER: Array[StringName] = [TAB_SELL, TAB_UPGRADES, TAB_DEBT, TAB_FISH_BOOK, TAB_RECORDS]

const TAB_HEIGHT := 48.0
const TAB_FONT_SIZE := 15
const LEDGER_WIDTH_RATIO := 0.48
const LEDGER_WIDTH_RANGE := Vector2(500.0, 640.0)
## On tall screens the ledger starts this far down; the warung shows above it.
const LEDGER_TOP_RATIO_PORTRAIT := 0.37
const LEAVE_WIDTH := 240.0
const HINT_FONT_SIZE := 24
const CASH_COUNT_SEC := 0.45

@onready var _safe_root: Control = $SafeRoot
@onready var _header: HBoxContainer = $SafeRoot/HeaderBar
@onready var _tab_bar: HBoxContainer = $SafeRoot/TabBar
@onready var _tab_content: PanelContainer = $SafeRoot/TabContent
@onready var _leave_button: GameButton = $SafeRoot/LeaveMarketButton
@onready var sell_panel: MarketSellPanel = $SafeRoot/TabContent/SellPanel
@onready var upgrade_panel: MarketUpgradePanel = $SafeRoot/TabContent/UpgradePanel
@onready var debt_panel: MarketDebtPanel = $SafeRoot/TabContent/DebtPanel
@onready var fish_book_panel: MarketFishBookPanel = $SafeRoot/TabContent/FishBookPanel
@onready var records_panel: MarketRecordsPanel = $SafeRoot/TabContent/RecordsPanel

var _tab_buttons: Dictionary[StringName, GameButton] = {}
var _panels: Dictionary[StringName, MarketPanel] = {}
var _current_tab: StringName = TAB_SELL
var _cash_label: Label
var _hint_label: Label
var _hint_left: float = 0.0
var _shown_cash: float = 0.0
var _cash_tween: Tween


func _ready() -> void:
	_panels = {
		TAB_SELL: sell_panel, TAB_UPGRADES: upgrade_panel, TAB_DEBT: debt_panel,
		TAB_FISH_BOOK: fish_book_panel, TAB_RECORDS: records_panel,
	}
	_tab_buttons = {
		TAB_SELL: $SafeRoot/TabBar/SellTabButton as GameButton,
		TAB_UPGRADES: $SafeRoot/TabBar/UpgradeTabButton as GameButton,
		TAB_DEBT: $SafeRoot/TabBar/DebtTabButton as GameButton,
		TAB_FISH_BOOK: $SafeRoot/TabBar/FishBookTabButton as GameButton,
		TAB_RECORDS: $SafeRoot/TabBar/RecordsTabButton as GameButton,
	}
	_build_header()
	_build_tabs()
	_build_hint()
	_tab_content.add_theme_stylebox_override(&"panel", _ledger_style())

	_leave_button.text = TextDb.t(&"market.leave")
	_leave_button.click_sfx = &"ui_back"
	_leave_button.pressed.connect(func() -> void: leave_pressed.emit())

	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(_on_viewport_class_changed)
	GameState.cash_changed.connect(_on_cash_changed)
	_show_cash(float(GameState.get_cash()))
	select_tab(TAB_SELL, false)
	_layout.call_deferred()


func _process(delta: float) -> void:
	if _hint_left > 0.0:
		_hint_left -= delta
		if _hint_left <= 0.0:
			_hint_label.visible = false


# --- Called by the Market scene ---------------------------------------------

## Opens a page. `announce` is off for the initial page, which nobody chose.
func select_tab(tab_id: StringName, announce: bool = true) -> void:
	if not _panels.has(tab_id):
		return
	_current_tab = tab_id
	for id: StringName in _panels:
		_panels[id].visible = id == tab_id
		_style_tab(_tab_buttons[id], id == tab_id)
	_panels[tab_id].refresh()
	_panels[tab_id].scroll_to_top()
	if announce:
		tab_changed.emit(tab_id)


func get_current_tab() -> StringName:
	return _current_tab


func get_tab_button(tab_id: StringName) -> GameButton:
	return _tab_buttons.get(tab_id)


## Re-reads the game state on every page.
func refresh_pages() -> void:
	for tab_id: StringName in _panels:
		_panels[tab_id].refresh()


## One line of guidance over the scene. With `seconds` at 0 it stays until it
## is replaced; an empty text hides it.
func show_hint(text: String, seconds: float = 0.0) -> void:
	_hint_label.text = text
	_hint_label.visible = text != ""
	_hint_left = seconds


func get_hint_text() -> String:
	return _hint_label.text if _hint_label.visible else ""


func set_leave_enabled(enabled: bool) -> void:
	_leave_button.disabled = not enabled


## Keyboard and gamepad start on the main action of the open page.
func focus_default() -> void:
	await get_tree().process_frame
	if not is_inside_tree() or InputManager.is_touch_primary():
		return
	var target: Control = _tab_buttons[_current_tab]
	if _current_tab == TAB_SELL and not sell_panel.get_sell_all_button().disabled:
		target = sell_panel.get_sell_all_button()
	target.grab_focus()


# --- Cash -------------------------------------------------------------------

## Cash counts to its new value instead of jumping (GDD 167.10).
func _on_cash_changed(cash: int) -> void:
	if _cash_tween != null and _cash_tween.is_valid():
		_cash_tween.kill()
	if GameState.get_setting(&"reduced_motion"):
		_show_cash(float(cash))
		return
	_cash_tween = create_tween()
	_cash_tween.tween_method(_show_cash, _shown_cash, float(cash), CASH_COUNT_SEC) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _show_cash(value: float) -> void:
	_shown_cash = value
	_cash_label.text = Money.format_rp(roundi(value))


# --- Construction -----------------------------------------------------------

func _build_header() -> void:
	_header.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var cash_chip := PanelContainer.new()
	cash_chip.name = "CashWidget"
	cash_chip.add_theme_stylebox_override(&"panel", HudChip.make_style())
	cash_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cash_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(cash_chip)
	_cash_label = HudChip.add_content(cash_chip, UiIcon.ICON_CASH)
	_cash_label.custom_minimum_size.x = 132.0

	var title := Label.new()
	title.name = "Title"
	title.text = TextDb.t(&"market.header.title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(title, UiTokens.FONT_HEADER)
	_header.add_child(title)

	var pause_button := GameButton.new()
	pause_button.name = "PauseButton"
	HudChip.make_pause_button(pause_button)
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_header.add_child(pause_button)


func _build_tabs() -> void:
	_tab_bar.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	# The open tab is drawn over the ledger's top edge, like a real divider.
	_tab_bar.z_index = 1
	for tab_id: StringName in TAB_ORDER:
		var button := _tab_buttons[tab_id]
		button.text = TextDb.t(StringName("market.tab.%s" % (&"savings" if tab_id == TAB_DEBT and MarketDebtPanel.is_savings_mode() else tab_id)))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.min_height = int(TAB_HEIGHT)
		button.custom_minimum_size.y = TAB_HEIGHT
		button.clip_text = true
		button.add_theme_font_size_override(&"font_size", TAB_FONT_SIZE)
		button.pressed.connect(select_tab.bind(tab_id))


func _build_hint() -> void:
	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.visible = false
	UiTokens.outline_text(_hint_label, HINT_FONT_SIZE)
	_safe_root.add_child(_hint_label)


func _style_tab(button: GameButton, active: bool) -> void:
	button.add_theme_stylebox_override(&"normal", _tab_box(active, false))
	button.add_theme_stylebox_override(&"hover", _tab_box(active, true))
	button.add_theme_stylebox_override(&"pressed", _tab_box(true, false))
	var text_color := UiTokens.INK_900 if active else UiTokens.INK_700
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(color_name, text_color)


## A ledger divider tab: the open one is the colour of the page and has no
## bottom edge, so it reads as part of the page below it.
func _tab_box(active: bool, hover: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = UiTokens.CREAM_100
	if not active:
		box.bg_color = UiTokens.PAPER_200.lightened(0.12) if hover else UiTokens.PAPER_200
	box.border_color = UiTokens.INK_700
	box.set_border_width_all(UiTokens.BORDER_WIDTH)
	box.border_width_bottom = 0 if active else UiTokens.BORDER_WIDTH
	box.corner_radius_top_left = UiTokens.RADIUS_BUTTON
	box.corner_radius_top_right = UiTokens.RADIUS_BUTTON
	box.content_margin_left = UiTokens.SPACE_4
	box.content_margin_right = UiTokens.SPACE_4
	box.content_margin_top = UiTokens.SPACE_8
	box.content_margin_bottom = UiTokens.SPACE_8
	return box


func _ledger_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = UiTokens.CREAM_100
	box.border_color = UiTokens.INK_700
	box.set_border_width_all(UiTokens.BORDER_WIDTH)
	box.corner_radius_bottom_left = UiTokens.RADIUS_PANEL
	box.corner_radius_bottom_right = UiTokens.RADIUS_PANEL
	box.set_content_margin_all(UiTokens.SPACE_16)
	box.shadow_color = Color(UiTokens.INK_900, 0.2)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0.0, 4.0)
	return box


# --- Layout -----------------------------------------------------------------

func _on_viewport_class_changed(_viewport_class: StringName) -> void:
	_layout()


## Places every block for the current screen shape. Positions come from the
## safe area and the tokens only, never from fixed screen coordinates.
func _layout() -> void:
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var area := _safe_root.size
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	var gap := float(UiTokens.SPACE_12)

	_place(_header, Rect2(0.0, 0.0, area.x, row))

	var ledger: Rect2
	if portrait:
		var top := roundf(area.y * LEDGER_TOP_RATIO_PORTRAIT)
		ledger = Rect2(0.0, top, area.x, area.y - top - row - gap)
		_place(_leave_button, Rect2(0.0, area.y - row, area.x, row))
		# One line, resting just above the tabs.
		_place(_hint_label, Rect2(0.0, top - HINT_FONT_SIZE * 2.0, area.x, HINT_FONT_SIZE * 2.0))
		_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		var width := clampf(area.x * LEDGER_WIDTH_RATIO, LEDGER_WIDTH_RANGE.x, LEDGER_WIDTH_RANGE.y)
		var top := row + gap
		ledger = Rect2(area.x - width, top, width, area.y - top)
		_place(_leave_button, Rect2(0.0, area.y - row, LEAVE_WIDTH, row))
		_place(_hint_label, Rect2(0.0, top + gap, area.x - width - UiTokens.SPACE_24, 120.0))
		_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	_place(_tab_bar, Rect2(ledger.position, Vector2(ledger.size.x, TAB_HEIGHT)))
	# The page starts under the tabs, sharing their bottom edge.
	var overlap := float(UiTokens.BORDER_WIDTH)
	_place(_tab_content, Rect2(
		ledger.position + Vector2(0.0, TAB_HEIGHT - overlap),
		ledger.size - Vector2(0.0, TAB_HEIGHT - overlap)))


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
