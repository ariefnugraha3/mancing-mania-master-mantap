class_name MarketUpgradePanel
extends MarketPanel
## UPGRADES page (GDD 76-78). Every item states its level, what it does now,
## what the next level does, the exact price and the maximum level before the
## player spends anything. Flavour text alone is never enough.

signal upgrade_requested(upgrade_id: StringName)
## Travel gear for a fishing spot (revision 6.7).
signal gear_requested(location_id: StringName)

## upgrade id -> {"level": Label, "current": Label, "next": Label, "button": GameButton}
var _cards: Dictionary[StringName, Dictionary] = {}
## location id -> {"name": Label, "desc": Label, "button": GameButton}
var _gear: Dictionary[StringName, Dictionary] = {}


func build() -> void:
	set_heading(TextDb.t(&"market.upgrade.title"))
	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		var upgrade := GameData.get_upgrade(upgrade_id)
		if upgrade == null:
			continue
		body.add_child(_make_card(upgrade))
	# TRAVEL GEAR: one item per spot after the first, in the order they open.
	var gear_heading := make_label(TextDb.t(&"market.gear.title"), UiTokens.TYPE_SECTION)
	gear_heading.name = "GearHeading"
	body.add_child(gear_heading)
	for location_id: StringName in ContentIds.LOCATION_IDS:
		if location_id != ContentIds.START_LOCATION:
			body.add_child(_make_gear_card(location_id))


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
	for location_id: StringName in _gear:
		_refresh_gear(location_id)


func _refresh_gear(location_id: StringName) -> void:
	var card: Dictionary = _gear[location_id]
	var location := GameData.get_location(location_id)
	var button: GameButton = card["button"]
	var desc: Label = card["desc"]
	var unlocked := GameState.is_location_unlocked(location_id)
	(card["name"] as Label).text = TextDb.t(StringName("location.%s.gear" % location_id)).to_upper() if unlocked else TextDb.t(&"travel.locked_name")
	# A closed spot's gear says what opens the spot, like the map does.
	desc.text = TextDb.t(StringName("location.%s.gear_desc" % location_id)) if unlocked else TravelOverlay.status_text(location_id)
	if GameState.has_location_gear(location_id):
		button.text = TextDb.t(&"market.gear.owned")
		button.disabled = true
	else:
		button.text = TextDb.tf(&"market.gear.buy", {"price": Money.format_rp(location.access_price)})
		button.disabled = not GameState.can_buy_location_gear(location_id)


func get_gear_button(location_id: StringName) -> GameButton:
	return _gear[location_id]["button"] if _gear.has(location_id) else null


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
	var name_label := make_label(upgrade.get_display_name().to_upper())
	name_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	name_label.add_theme_font_override(&"font", UiSkin.bold_font())
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(name_label)
	# The level sits on a small gold tag, like a price sticker.
	var level_tag := PanelContainer.new()
	level_tag.name = "LevelTag"
	level_tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	level_tag.add_theme_stylebox_override(&"panel", UiSkin.pill(UiTokens.SUN_500, 2, 12, Vector2(10.0, 1.0), 2))
	title_row.add_child(level_tag)
	var level_label := Label.new()
	level_label.theme_type_variation = UiTokens.TYPE_SMALL
	level_label.add_theme_font_override(&"font", UiSkin.bold_font())
	level_label.add_theme_color_override(&"font_color", UiTokens.INK_900)
	level_tag.add_child(level_label)

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


func _make_gear_card(location_id: StringName) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Gear_%s" % location_id
	card.add_theme_stylebox_override(&"panel", _card_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	card.add_child(column)
	var name_label := make_label("")
	name_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	name_label.add_theme_font_override(&"font", UiSkin.bold_font())
	column.add_child(name_label)
	var desc := make_label("", UiTokens.TYPE_SMALL)
	column.add_child(desc)
	var button := make_button("", UiTokens.TYPE_CTA_BUTTON)
	button.name = "BuyGearButton"
	button.min_height = UiTokens.TOUCH_TARGET_MIN
	button.pressed.connect(func() -> void: gear_requested.emit(location_id))
	column.add_child(button)
	_gear[location_id] = {"name": name_label, "desc": desc, "button": button}
	return card


## A price card: a lighter paper slip with a caramel rim and a small lip,
## lying on the ledger page.
func _card_style() -> StyleBoxFlat:
	var box := UiSkin.pill(UiTokens.CREAM_50, 3, 16, Vector2(UiTokens.SPACE_12, UiTokens.SPACE_12), 2)
	box.shadow_size = 3
	box.shadow_offset = Vector2(0.0, 1.0)
	return box
