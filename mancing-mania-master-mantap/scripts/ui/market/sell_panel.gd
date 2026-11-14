class_name MarketSellPanel
extends MarketPanel
## SELL page (GDD 74, 75): what is in the Bucket, what each item pays and the
## total, with SELL ALL as the main action and one button per category.
##
## The page shows the same sale preview MarketController would pay out, so the
## number on screen and the cash received can never differ.

signal sell_all_requested()
signal sell_category_requested(category: StringName)

var _total_label: Label
var _sell_all: GameButton
var _sell_fish: GameButton
var _sell_trash: GameButton


func build() -> void:
	set_heading(TextDb.t(&"market.sell.title"))

	_total_label = add_value_row(actions, TextDb.t(&"market.sell.total"), UiTokens.TYPE_HEADER)

	_sell_all = make_button(TextDb.t(&"market.sell.sell_all"), UiTokens.TYPE_CTA_BUTTON)
	_sell_all.icon_id = IconPainter.CASH
	_sell_all.name = "SellAllButton"
	_sell_all.custom_minimum_size.y = 64.0
	_sell_all.add_theme_font_size_override(&"font_size", UiTokens.FONT_HEADER)
	_sell_all.pressed.connect(func() -> void: sell_all_requested.emit())
	actions.add_child(_sell_all)

	# The two sell buttons share a line, or stack when the text is large.
	var row := HFlowContainer.new()
	row.name = "SellRow"
	row.add_theme_constant_override(&"h_separation", UiTokens.SPACE_8)
	row.add_theme_constant_override(&"v_separation", UiTokens.SPACE_8)
	actions.add_child(row)
	_sell_fish = make_button(TextDb.t(&"market.sell.sell_fish"))
	_sell_fish.name = "SellFishButton"
	_sell_fish.pressed.connect(func() -> void: sell_category_requested.emit(MarketController.CATEGORY_FISH))
	row.add_child(_sell_fish)
	_sell_trash = make_button(TextDb.t(&"market.sell.sell_trash"))
	_sell_trash.name = "SellTrashButton"
	_sell_trash.pressed.connect(func() -> void: sell_category_requested.emit(MarketController.CATEGORY_TRASH))
	row.add_child(_sell_trash)


## Shows a sale preview from MarketController.get_sell_preview().
func show_preview(preview: Dictionary) -> void:
	clear_children(body)
	var lines: Array = preview["lines"]
	for line: Dictionary in lines:
		body.add_child(make_sale_line(line))
		body.add_child(make_rule())
	if lines.is_empty():
		body.add_child(make_label(TextDb.t(&"market.sell.empty"), UiTokens.TYPE_SMALL))

	_total_label.text = Money.format_rp(int(preview["total"]))
	var fish_count := 0
	var trash_count := 0
	for line: Dictionary in lines:
		if line["category"] == MarketController.CATEGORY_FISH:
			fish_count += int(line["quantity"])
		else:
			trash_count += int(line["quantity"])
	_sell_all.disabled = fish_count + trash_count == 0
	_sell_fish.disabled = fish_count == 0
	_sell_trash.disabled = trash_count == 0


func get_sell_all_button() -> GameButton:
	return _sell_all


## One line of a sale: "3x Bruiser Catfish ..... Rp 54,000" with the unit
## price underneath. The boss fish shows how its multiplier is applied.
## The receipt uses the same line, so both read exactly alike.
static func make_sale_line(line: Dictionary) -> VBoxContainer:
	var block := VBoxContainer.new()
	block.add_theme_constant_override(&"separation", 0)

	var row := HBoxContainer.new()
	block.add_child(row)
	var name_label := Label.new()
	name_label.text = TextDb.tf(&"market.sell.row", {"count": line["quantity"], "name": line["name"]})
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = Money.format_rp(int(line["subtotal"]))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	var unit_label := Label.new()
	unit_label.theme_type_variation = UiTokens.TYPE_SMALL
	unit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unit_label.text = TextDb.tf(&"market.sell.each", {"value": Money.format_rp(int(line["unit_value"]))})
	var multiplier := float(line["multiplier"])
	if not is_equal_approx(multiplier, 1.0):
		unit_label.text = TextDb.tf(&"market.sell.boss", {
			"base": Money.format_rp(int(line["base_value"])),
			# Exact, without padding: 1.25 stays 1.25 and 2.0 becomes 2.
			"multiplier": String.num(multiplier, 2),
			"value": Money.format_rp(int(line["unit_value"])),
		})
	block.add_child(unit_label)
	return block
