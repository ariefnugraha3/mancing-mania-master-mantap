class_name MarketFishBookPanel
extends MarketPanel
## FISH BOOK page (GDD 81, 82, 174.9). The book opens when the story hands it
## over. A fish gets its name, portrait and description once Darto has beaten
## it; until then it is an ink silhouette with a row of question marks.
##
## The book only reads GameState. Nothing here can change a record.

const PORTRAIT_SIZE := Vector2(144.0, 81.0)
const SILHOUETTE_SHADER := preload("res://shaders/ui_silhouette.gdshader")


func build() -> void:
	set_heading(TextDb.t(&"market.book.title"))


func refresh() -> void:
	clear_children(body)
	if not is_unlocked():
		body.add_child(make_label(TextDb.t(&"market.book.locked"), UiTokens.TYPE_SMALL))
		return
	for fish_id: StringName in ContentIds.FISH_IDS:
		body.add_child(_make_entry(fish_id))
		body.add_child(make_rule())


static func is_unlocked() -> bool:
	return bool(GameState.get_story_value(&"fish_book_unlocked"))


func _make_entry(fish_id: StringName) -> HBoxContainer:
	var fish := GameData.get_fish(fish_id)
	var entry := GameState.get_fish_book_entry(fish_id)
	var discovered := bool(entry.get("discovered", false))

	var row := HBoxContainer.new()
	row.name = "Entry_%s" % fish_id
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_12)

	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.texture = fish.portrait_texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not discovered:
		var silhouette := ShaderMaterial.new()
		silhouette.shader = SILHOUETTE_SHADER
		portrait.material = silhouette
	row.add_child(portrait)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 2)
	row.add_child(column)

	var name_label := make_label(fish.display_name.to_upper() if discovered else TextDb.t(&"market.book.unknown"))
	name_label.name = "Name"
	name_label.add_theme_font_size_override(&"font_size", UiTokens.FONT_BUTTON)
	column.add_child(name_label)

	if discovered:
		column.add_child(make_label(fish.species_label, UiTokens.TYPE_SMALL))
		var description := make_label(TextDb.t(StringName("fish.%s.description" % fish_id)))
		description.add_theme_font_size_override(&"font_size", UiTokens.FONT_SMALL)
		column.add_child(description)
	else:
		column.add_child(make_label(TextDb.t(&"market.book.undiscovered"), UiTokens.TYPE_SMALL))

	if int(entry.get("encounters", 0)) > 0:
		column.add_child(make_label(TextDb.tf(&"market.book.stats", {
			"weight": "%.2f" % float(entry.get("best_weight_kg", 0.0)),
			"encounters": int(entry.get("encounters", 0)),
			"wins": int(entry.get("wins", 0)),
			"losses": int(entry.get("losses", 0)),
		}), UiTokens.TYPE_SMALL))
	if discovered:
		var favourite := str(entry.get("favourite_duel", ""))
		if favourite == "":
			column.add_child(make_label(TextDb.t(&"market.book.favourite_none"), UiTokens.TYPE_SMALL))
		else:
			column.add_child(make_label(TextDb.tf(&"market.book.favourite", {
				"duel": TextDb.t(StringName("duel.%s" % favourite))}), UiTokens.TYPE_SMALL))
	return row
