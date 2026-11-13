class_name MarketUpgradePanel
extends MarketPanel
## UPGRADES page (GDD 76-78). Every item states its level, what it does now,
## what the next level does, the exact price and the maximum level before the
## player spends anything. Flavour text alone is never enough.

signal upgrade_requested(upgrade_id: StringName)

## upgrade id -> {"level": Label, "current": Label, "next": Label, "button": GameButton}
var _cards: Dictionary[StringName, Dictionary] = {}


func build() -> void:
	set_heading(TextDb.t(&"market.upgrade.title"))
	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		var upgrade := GameData.get_upgrade(upgrade_id)
		if upgrade == null:
			continue
		body.add_child(_make_card(upgrade))


func refresh() -> void:
	for upgrade_id: StringName in _cards:
		var card: Dictionary = _cards[upgrade_id]
		var upgrade := GameData.get_upgrade(upgrade_id)
		var level := GameState.get_upgrade_level(upgrade_id)
		var price := upgrade.get_price_for_level(level)
		var button: GameButton = card["button"]
		(card["level"] as Label).text = TextDb.tf(&"market.upgrade.level", {"level": level, "max": upgrade.max_level})
		(card["current"] as Label).text = TextDb.tf(&"market.upgrade.current", {"effect": UpgradeEffects.describe(upgrade_id, level)})
		var next_label: Label = card["next"]
		if price < 0:
			next_label.visible = false
			button.text = TextDb.t(&"market.upgrade.max")
			button.disabled = true
		else:
			next_label.visible = true
			next_label.text = TextDb.tf(&"market.upgrade.next", {"effect": UpgradeEffects.describe(upgrade_id, level + 1)})
			button.text = TextDb.tf(&"market.upgrade.buy", {"price": Money.format_rp(price)})
			button.disabled = not GameState.can_buy_upgrade(upgrade_id)


func get_buy_button(upgrade_id: StringName) -> GameButton:
	return _cards[upgrade_id]["button"] if _cards.has(upgrade_id) else null


func _make_card(upgrade: UpgradeData) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card_%s" % upgrade.id
	card.add_theme_stylebox_override(&"panel", _card_style())

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	card.add_child(column)

	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	var name_label := make_label(upgrade.name.to_upper())
	name_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(name_label)
	var level_label := Label.new()
	level_label.theme_type_variation = UiTokens.TYPE_SMALL
	title_row.add_child(level_label)

	var current_label := make_label("", UiTokens.TYPE_SMALL)
	column.add_child(current_label)
	var next_label := make_label("", UiTokens.TYPE_SMALL)
	next_label.add_theme_color_override(&"font_color", UiTokens.INK_900)
	column.add_child(next_label)

	var button := make_button("", UiTokens.TYPE_CTA_BUTTON)
	button.name = "BuyButton"
	button.min_height = UiTokens.TOUCH_TARGET_MIN
	button.pressed.connect(func() -> void: upgrade_requested.emit(upgrade.id))
	column.add_child(button)

	_cards[upgrade.id] = {"level": level_label, "current": current_label, "next": next_label, "button": button}
	return card


## A price card: slightly darker paper with a thin ink border.
func _card_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UiTokens.PAPER_200, 0.55)
	box.border_color = Color(UiTokens.INK_700, 0.6)
	box.set_border_width_all(1)
	box.set_corner_radius_all(UiTokens.RADIUS_BUTTON)
	box.set_content_margin_all(UiTokens.SPACE_12)
	return box
