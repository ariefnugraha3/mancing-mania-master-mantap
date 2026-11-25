class_name MarketHud
extends CanvasLayer
## Market screen (GDD 73, 167.9, 168.5, 176.16): Bu Yati's ledger. Five tabs in
## a fixed order, one page open at a time, cash always in view and one explicit
## way out.
##
## The ledger is a bottom sheet under the warung, so Bu Yati and Darto stay
## visible while the player does business; its folder tabs work like a phone's
## tab bar (an icon over a short label).
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

const TAB_HEIGHT := 58.0
const TAB_FONT_SIZE := 12
const TAB_ICONS: Dictionary = {
	TAB_SELL: IconPainter.CASH, TAB_UPGRADES: IconPainter.ARROW_UP, TAB_DEBT: IconPainter.LEDGER,
	TAB_FISH_BOOK: IconPainter.FISH, TAB_RECORDS: IconPainter.TROPHY,
}
## Rim of the ledger card; the tabs overlap it by this much.
const LEDGER_RIM := 4
## The ledger sheet never gets wider than this (tablets).
const LEDGER_MAX_WIDTH := 640.0
## The sheet starts this far down the screen; the warung shows above it.
const LEDGER_TOP_RATIO := 0.33
const LEAVE_HEIGHT := float(UiTokens.TOUCH_TARGET_PREFERRED)
const TITLE_FONT_SIZE := 24
const HINT_FONT_SIZE := 18
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
var _cash_chip: PanelContainer
var _cash_label: Label
var _title: Label
var _hint_label: Label
var _hint_left: float = 0.0
var _shown_cash: float = 0.0
var _cash_tween: Tween
var _info_popover: HudInfoPopover


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
	_info_popover = HudInfoPopover.new()
	_safe_root.add_child(_info_popover)
	_tab_content.add_theme_stylebox_override(&"panel", _ledger_style())

	_leave_button.text = TextDb.t(&"market.leave")
	_leave_button.click_sfx = &"ui_back"
	_leave_button.icon_id = IconPainter.BACK
	_leave_button.set_side_padding(UiTokens.SPACE_16)
	_leave_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A wrapped label changes the button's height once it is laid out.
	_leave_button.minimum_size_changed.connect(func() -> void: _layout.call_deferred())
	_leave_button.pressed.connect(func() -> void: leave_pressed.emit())

	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(_on_viewport_class_changed)
	GameState.cash_changed.connect(_on_cash_changed)
	GameState.debt_changed.connect(_on_debt_changed)
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
	if _info_popover != null:
		_info_popover.hide_info()
	for id: StringName in _panels:
		_panels[id].visible = id == tab_id
	_refresh_tab_styles()
	_panels[tab_id].refresh()
	_panels[tab_id].scroll_to_top()
	if is_node_ready():
		_layout.call_deferred()
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
	InputManager.give_focus(target)


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

	_cash_chip = PanelContainer.new()
	_cash_chip.name = "CashWidget"
	_cash_chip.add_theme_stylebox_override(&"panel", HudChip.make_style())
	_cash_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	_cash_chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_cash_chip.gui_input.connect(_on_cash_chip_input)
	_cash_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_header.add_child(_cash_chip)
	_cash_label = HudChip.add_content(_cash_chip, UiIcon.ICON_CASH)
	_cash_label.custom_minimum_size.x = 92.0

	# The header holds the cash chip and Pause; the shop's painted name hangs
	# on its own line under them, over the warung.
	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header.add_child(spacer)
	_title = Label.new()
	_title.name = "Title"
	_title.text = TextDb.t(&"market.header.title")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiSkin.sign_text(_title, TITLE_FONT_SIZE, DioramaStyle.BUTTER, 9)
	_safe_root.add_child(_title)

	var pause_button := GameButton.new()
	pause_button.name = "PauseButton"
	HudChip.make_pause_button(pause_button)
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_header.add_child(pause_button)


func _build_tabs() -> void:
	_tab_bar.add_theme_constant_override(&"separation", 3)
	# The open tab is drawn over the ledger's top edge, like a real divider.
	_tab_bar.z_index = 1
	for tab_id: StringName in TAB_ORDER:
		var button := _tab_buttons[tab_id]
		button.text = TextDb.t(StringName("market.tab.%s" % (&"savings" if tab_id == TAB_DEBT and MarketDebtPanel.is_savings_mode() else tab_id)))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = 1.0
		button.min_height = int(TAB_HEIGHT)
		button.custom_minimum_size = Vector2(0.0, TAB_HEIGHT)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(TAB_FONT_SIZE))
		# Icon over label, like a phone's tab bar.
		button.icon_id = TAB_ICONS[tab_id]
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_constant_override(&"icon_max_width", 22)
		button.add_theme_constant_override(&"h_separation", 0)
		button.pressed.connect(select_tab.bind(tab_id))


func _build_hint() -> void:
	_hint_label = Label.new()
	_hint_label.name = "Hint"
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.visible = false
	UiTokens.outline_text(_hint_label, HINT_FONT_SIZE)
	_safe_root.add_child(_hint_label)


func _on_debt_changed(_paid: int, _remaining: int) -> void:
	_refresh_tab_styles()


func _refresh_tab_styles() -> void:
	var overdue := GameState.is_debt_overdue()
	for id: StringName in _panels:
		_style_tab(_tab_buttons[id], id == _current_tab, id == TAB_DEBT and overdue)


func _style_tab(button: GameButton, active: bool, urgent: bool = false) -> void:
	button.add_theme_stylebox_override(&"normal", _tab_box(active, false, urgent))
	button.add_theme_stylebox_override(&"hover", _tab_box(active, true, urgent))
	button.add_theme_stylebox_override(&"pressed", _tab_box(true, false, urgent))
	button.add_theme_stylebox_override(&"focus", UiSkin.focus_box(16))
	if active or urgent:
		button.add_theme_font_override(&"font", UiSkin.bold_font())
	else:
		button.remove_theme_font_override(&"font")
	var text_color := UiTokens.INK_900 if active else (UiTokens.RED_500.darkened(0.2) if urgent else UiTokens.INK_700)
	for color_name: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		button.add_theme_color_override(color_name, text_color)


## A ledger folder tab: the open one is the colour of the page, stands a
## little taller and has no bottom edge, so it reads as part of the page.
func _tab_box(active: bool, hover: bool, urgent: bool = false) -> StyleBoxFlat:
	var box := UiSkin.tab(active, hover)
	if not active:
		# Closed tabs keep the page's top rim, so only the open one joins it.
		box.border_width_bottom = LEDGER_RIM
		if urgent:
			var tint := UiTokens.TERRACOTTA_500.lerp(UiTokens.CREAM_50, 0.72)
			box.bg_color = tint.lightened(0.06) if hover else tint
			box.border_color = UiTokens.TERRACOTTA_500
	box.content_margin_left = 2.0
	box.content_margin_right = 2.0
	box.content_margin_top = 6.0 if active else 8.0
	box.content_margin_bottom = 4.0
	return box


## The ledger page: the warm paper card, square at the top where the tabs
## join it.
func _ledger_style() -> StyleBoxFlat:
	var box := UiSkin.card(UiTokens.CREAM_100, UiTokens.RADIUS_PANEL, UiTokens.SPACE_16, LEDGER_RIM)
	box.corner_radius_top_left = 0
	box.corner_radius_top_right = 0
	return box


# --- Layout -----------------------------------------------------------------

func _on_viewport_class_changed(_viewport_class: StringName) -> void:
	_layout()


## Places every block on the portrait screen. Positions come from the safe
## area and the tokens only, never from fixed screen coordinates.
func _layout() -> void:
	var area := _safe_root.size
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	_place(_header, Rect2(0.0, 0.0, area.x, row))

	# Bottom: LEAVE MARKET across the thumb zone; above it, the ledger sheet.
	var width := minf(area.x, LEDGER_MAX_WIDTH)
	var left := (area.x - width) * 0.5
	# Very large text wraps the label, so the height is read at this width.
	_leave_button.size.x = width
	var leave_height := maxf(LEAVE_HEIGHT, _leave_button.get_combined_minimum_size().y)
	_place(_leave_button, Rect2(left, area.y - leave_height, width, leave_height))
	# The tabs are at least TAB_HEIGHT tall, more with large text.
	var tab_height := maxf(TAB_HEIGHT, _tab_bar.get_combined_minimum_size().y)
	var sheet_bottom := area.y - leave_height - UiTokens.SPACE_12
	# The sheet starts a third of the way down on every tab, so it never jumps
	# as the player moves between tabs (revision 6.12). A page with more than
	# fits scrolls inside it; it used to raise the sheet instead, and a page
	# not yet shown measured itself wrongly (no width to wrap in yet).
	var chrome := _tab_content.get_theme_stylebox(&"panel").get_minimum_size().y
	var top := maxf(roundf(area.y * LEDGER_TOP_RATIO), row + UiTokens.SPACE_8)
	var ledger := Rect2(left, top, width, sheet_bottom - top)
	# The shop's name hangs under the header, and one line of guidance rests
	# just above the tabs. When the sheet rises high, the name gives way.
	var title_rect := Rect2(0.0, row + UiTokens.SPACE_4, area.x, TITLE_FONT_SIZE * 1.6)
	var hint_height := HINT_FONT_SIZE * 2.2
	var hint_top := top - hint_height - UiTokens.SPACE_4
	_title.visible = hint_top >= title_rect.end.y
	_place(_title, title_rect)
	_place(_hint_label, Rect2(0.0, maxf(hint_top, row + UiTokens.SPACE_4), area.x, hint_height))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Still too short: every page lets its buttons scroll with the list.
	var page_room := ledger.size.y - tab_height + float(LEDGER_RIM) - chrome
	for id: StringName in _panels:
		_panels[id].set_actions_scroll(_panels[id].fixed_height() > page_room)
	_place(_tab_bar, Rect2(ledger.position, Vector2(ledger.size.x, tab_height)))
	# The page starts under the tabs, sharing their bottom edge.
	var overlap := float(LEDGER_RIM)
	_place(_tab_content, Rect2(
		ledger.position + Vector2(0.0, tab_height - overlap),
		ledger.size - Vector2(0.0, tab_height - overlap)))
	if _info_popover != null:
		_info_popover.reposition()


func _on_cash_chip_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_cash_chip.accept_event()
		if _info_popover != null:
			_info_popover.toggle_for(_cash_chip, TextDb.t(&"hud.info.cash.title"), TextDb.t(&"hud.info.cash.body"), false)


func _place(control: Control, rect: Rect2) -> void:
	UiTokens.place_at(control, rect)
