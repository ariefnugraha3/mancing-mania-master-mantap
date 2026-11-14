class_name ReceiptOverlay
extends OverlayPanel
## Sale receipt (GDD 74): every line that was sold, the total and the cash
## Darto holds now. It reports a finished transaction and changes nothing.

var _rows: VBoxContainer
var _total_label: Label
var _cash_label: Label
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

	_cash_label = make_label("", UiTokens.TYPE_SMALL)
	content.add_child(_cash_label)

	_close_button = make_button(TextDb.t(&"common.ok"), UiTokens.TYPE_CTA_BUTTON)
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)


## Shows the result of MarketController.sell_all() / sell_category().
func open(sale: Dictionary) -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for line: Dictionary in sale["lines"]:
		_rows.add_child(MarketSellPanel.make_sale_line(line))
	_total_label.text = Money.format_rp(int(sale["total"]))
	_cash_label.text = TextDb.tf(&"market.receipt.cash", {"cash": Money.format_rp(int(sale["cash_after"]))})
	show_overlay()
	focus_later(_close_button)


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	hide_overlay()
