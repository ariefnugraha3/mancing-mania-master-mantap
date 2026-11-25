class_name ReceiptOverlay
extends OverlayPanel
## Sale receipt (GDD 74): every line that was sold, the total, any CepatCash
## reminder fee deducted from the payout, and the cash Darto holds now. It
## reports a finished transaction and offers a direct jump to the Debt tab.

signal pay_debt_requested()

var _rows: VBoxContainer
var _total_label: Label
var _fee_row: HBoxContainer
var _fee_label: Label
var _cash_label: Label
var _warning_label: Label
var _pay_debt_button: GameButton
var _close_button: GameButton


func build_content() -> void:
	layer = 45
	panel_width = 440.0
	set_title(TextDb.t(&"market.receipt.title"))

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	content.add_child(_rows)

	var total_row := HBoxContainer.new()
	content.add_child(total_row)
	var total_name := make_label(TextDb.t(&"market.sell.total"), UiTokens.TYPE_HEADER)
	total_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_row.add_child(total_name)
	_total_label = make_label("", UiTokens.TYPE_HEADER)
	_total_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	total_row.add_child(_total_label)

	var alert_color := UiTokens.RED_500.darkened(0.18)
	_fee_row = HBoxContainer.new()
	_fee_row.name = "CollectorFeeRow"
	_fee_row.visible = false
	content.add_child(_fee_row)
	var fee_name := make_label(TextDb.t(&"market.receipt.collector_fee"), UiTokens.TYPE_SMALL)
	fee_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fee_name.add_theme_color_override(&"font_color", alert_color)
	_fee_row.add_child(fee_name)
	_fee_label = make_label("", UiTokens.TYPE_SMALL)
	_fee_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_fee_label.add_theme_color_override(&"font_color", alert_color)
	_fee_row.add_child(_fee_label)

	_cash_label = make_label("", UiTokens.TYPE_SMALL)
	content.add_child(_cash_label)

	_warning_label = make_label("", UiTokens.TYPE_SMALL)
	_warning_label.name = "DebtWarningLabel"
	_warning_label.add_theme_color_override(&"font_color", alert_color)
	_warning_label.visible = false
	content.add_child(_warning_label)

	_close_button = make_button(TextDb.t(&"common.ok"))
	_close_button.name = "CloseButton"
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)

	_pay_debt_button = make_button(TextDb.t(&"market.receipt.pay_debt"), UiTokens.TYPE_CTA_BUTTON)
	_pay_debt_button.name = "PayDebtButton"
	_pay_debt_button.pressed.connect(_on_pay_debt_pressed)
	footer.add_child(_pay_debt_button)


## Shows the result of MarketController.sell_all() / sell_category().
func open(sale: Dictionary) -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for line: Dictionary in sale["lines"]:
		_rows.add_child(MarketSellPanel.make_sale_line(line))
	var cash_after := int(sale.get("cash_after", 0))
	var fee := int(sale.get("collector_fee", 0))
	var unpaid := int(sale.get("unpaid_sales", 0))
	_total_label.text = Money.format_rp(int(sale["total"]))
	_fee_row.visible = fee > 0
	if fee > 0:
		_fee_label.text = "-%s" % Money.format_rp(fee)
	_cash_label.text = TextDb.tf(&"market.receipt.cash", {"cash": Money.format_rp(cash_after)})
	if fee > 0:
		_warning_label.text = TextDb.tf(&"market.receipt.fee_note", {"relief": Money.format_rp(ContentIds.DEBT_MIN_RELIEF_PAYMENT)})
		_warning_label.visible = true
	elif unpaid >= ContentIds.DEBT_HARASS_AFTER_SALES and GameState.get_debt_remaining() > 0:
		_warning_label.text = TextDb.tf(&"market.receipt.overdue_note", {"fee": Money.format_rp(ContentIds.DEBT_REMINDER_FEE)})
		_warning_label.visible = true
	else:
		_warning_label.visible = false
	var show_pay := GameState.get_debt_remaining() > 0 and cash_after > 0
	_pay_debt_button.visible = show_pay
	_close_button.theme_type_variation = &"" if show_pay else UiTokens.TYPE_CTA_BUTTON
	show_overlay()
	focus_later(_close_button)


func get_pay_debt_button() -> GameButton:
	return _pay_debt_button


func get_close_button() -> GameButton:
	return _close_button


func _on_pay_debt_pressed() -> void:
	hide_overlay()
	pay_debt_requested.emit()


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	hide_overlay()
