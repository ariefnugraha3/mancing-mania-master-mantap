class_name TrashData
extends Resource
## One of the three trash catches (GDD Sections 30 and 165.4).
## Trash never triggers the Wheel or a duel; it goes straight to the Bucket.

@export var id: StringName = &""
@export var display_name: String = ""
## Probability inside the trash pool.
@export_range(0.0, 1.0, 0.0001) var chance: float = 0.0
@export var sale_value: int = 0
@export var model_scene: PackedScene


func get_sale_value() -> int:
	return sale_value


## The name the player reads, in the current language (trash.<id>.name).
func get_display_name() -> String:
	return TextDb.text_or(StringName("trash.%s.name" % id), display_name)
