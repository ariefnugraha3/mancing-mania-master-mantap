class_name TravelOverlay
extends OverlayPanel
## WHERE TO? (revision 6.7): the five fishing spots in order, each with its
## trait and how much of its Fish Book page is filled. A spot that is not open
## says what opens it; an open spot without its gear says where to buy it.
## GO moves Darto there. Selling is always at Bu Yati's, whichever spot he
## fishes.

signal travel_requested(location_id: StringName)

var _rows: VBoxContainer
var _close_button: GameButton
var _go_buttons: Dictionary[StringName, GameButton] = {}


func build_content() -> void:
	layer = 50
	panel_width = 620.0
	set_title(TextDb.t(&"travel.title"))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	content.add_child(_rows)
	_close_button = make_button(TextDb.t(&"common.close"))
	_close_button.click_sfx = &"ui_back"
	_close_button.icon_id = IconPainter.CLOSE
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)


func open() -> void:
	_rebuild()
	show_overlay()
	var current := GameState.get_current_location()
	for location_id: StringName in _go_buttons:
		if location_id != current:
			focus_later(_go_buttons[location_id])
			return
	focus_later(_close_button)


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	hide_overlay()


func get_go_button(location_id: StringName) -> GameButton:
	return _go_buttons.get(location_id)


## The line under a spot's name: what it is like, or why it is closed.
static func status_text(location_id: StringName) -> String:
	var location := GameData.get_location(location_id)
	if location == null:
		return ""
	if not GameState.is_location_unlocked(location_id):
		var event := StoryDirector.get_event(location.unlock_event)
		if event != null and int(GameState.get_stat(&"lifetime_debt_paid")) >= int(event.trigger_value):
			return TextDb.t(&"travel.locked_event")
		var amount := int(event.trigger_value) if event != null else 0
		return TextDb.tf(&"travel.locked_debt", {"amount": Money.format_rp(amount)})
	if not GameState.has_location_gear(location_id):
		return TextDb.tf(&"travel.need_gear", {"gear": TextDb.t(StringName("location.%s.gear" % location_id))})
	return TextDb.t(StringName("location.%s.trait" % location_id))


## How many of the spot's fish have been beaten, as "Fish Book: 2 / 5".
static func fish_count_text(location_id: StringName) -> String:
	var fish_ids := ContentIds.fish_of_location(location_id)
	var beaten := 0
	for fish_id: StringName in fish_ids:
		if int(GameState.get_fish_book_entry(fish_id).get("wins", 0)) > 0:
			beaten += 1
	return TextDb.tf(&"travel.fish_count", {"count": beaten, "total": fish_ids.size()})


func _rebuild() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_go_buttons.clear()
	var current := GameState.get_current_location()
	for location_id: StringName in ContentIds.LOCATION_IDS:
		_rows.add_child(_make_row(location_id, current))


func _make_row(location_id: StringName, current: StringName) -> Control:
	var card := PanelContainer.new()
	card.name = String(location_id)
	var here := location_id == current
	card.add_theme_stylebox_override(&"panel", UiSkin.well(UiTokens.CREAM_50 if here else UiTokens.PAPER_200, 16, UiTokens.SPACE_12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	card.add_child(row)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override(&"separation", 2)
	row.add_child(text)
	var unlocked := GameState.is_location_unlocked(location_id)
	var name_label := make_label(TextDb.t(StringName("location.%s.name" % location_id)) if unlocked else TextDb.t(&"travel.locked_name"), UiTokens.TYPE_HEADER)
	text.add_child(name_label)
	var status := make_label(status_text(location_id))
	status.add_theme_font_size_override(&"font_size", UiTokens.FONT_SMALL)
	text.add_child(status)
	if unlocked:
		var count := make_label(fish_count_text(location_id))
		count.add_theme_font_size_override(&"font_size", UiTokens.FONT_SMALL)
		count.add_theme_color_override(&"font_color", UiTokens.INK_700)
		text.add_child(count)
	if here:
		var tag := Label.new()
		tag.text = TextDb.t(&"travel.here")
		tag.theme_type_variation = UiTokens.TYPE_NAME_TAG
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(tag)
	elif GameState.can_fish_at(location_id):
		var go := GameButton.new()
		go.name = "Go"
		go.text = TextDb.t(&"travel.go")
		go.icon_id = IconPainter.PLAY
		go.theme_type_variation = UiTokens.TYPE_CTA_BUTTON
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		go.custom_minimum_size.x = 110.0
		go.pressed.connect(_on_go.bind(location_id))
		row.add_child(go)
		_go_buttons[location_id] = go
	return card


func _on_go(location_id: StringName) -> void:
	hide_overlay()
	travel_requested.emit(location_id)
