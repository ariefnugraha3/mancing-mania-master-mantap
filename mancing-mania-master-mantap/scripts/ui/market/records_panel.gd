class_name MarketRecordsPanel
extends MarketPanel
## RECORDS page (GDD 83): lifetime numbers, read straight from the save. It is
## a quiet page of facts; none of them is a goal the game asks for.

## Counters shown as plain numbers, in display order.
const COUNT_ROWS: Array[StringName] = [
	&"total_casts", &"successful_strikes", &"lines_broken", &"trash_caught",
	&"fish_landed", &"duel_wins", &"duel_losses", &"boxing_wins",
	&"arm_wrestle_wins", &"dance_wins", &"suwit_wins", &"don_arowana_defeated",
]
## Counters shown as money.
const MONEY_ROWS: Array[StringName] = [&"lifetime_sales", &"lifetime_debt_paid"]

## row id -> value label
var _values: Dictionary[StringName, Label] = {}


func build() -> void:
	set_heading(TextDb.t(&"market.records.title"))
	for row_id: StringName in COUNT_ROWS:
		_add_row(row_id)
	_add_row(&"largest_fish")
	for row_id: StringName in MONEY_ROWS:
		_add_row(row_id)
	_add_row(&"play_time")


func refresh() -> void:
	for row_id: StringName in COUNT_ROWS:
		_values[row_id].text = Money.group_thousands(int(GameState.get_stat(row_id)))
	for row_id: StringName in MONEY_ROWS:
		_values[row_id].text = Money.format_rp(int(GameState.get_stat(row_id)))
	_values[&"largest_fish"].text = _largest_fish_text()
	_values[&"play_time"].text = format_play_time(float(GameState.get_stat(&"play_time_sec")))


func get_value_text(row_id: StringName) -> String:
	return _values[row_id].text if _values.has(row_id) else ""


## Hours, minutes and seconds as H:MM:SS.
static func format_play_time(seconds: float) -> String:
	var total := int(maxf(seconds, 0.0))
	@warning_ignore("integer_division")
	return "%d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]


func _add_row(row_id: StringName) -> void:
	_values[row_id] = add_value_row(body, TextDb.t(StringName("records.%s" % row_id)))
	body.add_child(make_rule())


func _largest_fish_text() -> String:
	var fish_id := str(GameState.get_stat(&"largest_fish_id"))
	if fish_id == "":
		return TextDb.t(&"records.largest_none")
	return TextDb.tf(&"records.largest_value", {
		"weight": "%.2f" % float(GameState.get_stat(&"largest_fish_weight_kg")),
		"name": GameData.get_item_display_name(StringName(fish_id)),
	})
