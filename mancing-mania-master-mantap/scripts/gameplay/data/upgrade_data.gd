class_name UpgradeData
extends Resource
## One upgrade family, Lv0-Lv3 (GDD 170.2). Stored at res://data/upgrades/<id>.tres.

@export var id: StringName = &""
@export var name: String = ""
@export var max_level: int = 3
## prices[level] is the cost of going from `level` to `level + 1`.
@export var prices: Array[int] = []
## Name of the balance-config field that actually drives gameplay.
## `effect_per_level` must match that field; boot validation checks it.
@export var stat_key: StringName = &""
@export var effect_per_level: float = 0.0
@export var effect_unit: String = ""
@export_multiline var description: String = ""


## Cost of the next level, or -1 when already at max level.
func get_price_for_level(current_level: int) -> int:
	if current_level < 0 or current_level >= max_level or current_level >= prices.size():
		return -1
	return prices[current_level]


func get_total_cost() -> int:
	var total := 0
	for price: int in prices:
		total += price
	return total
