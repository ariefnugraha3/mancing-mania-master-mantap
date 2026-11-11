class_name FishData
extends Resource
## One of the six duel-capable fish (GDD 170.1). Stored at res://data/fish/<id>.tres.
## Values follow the authoritative tables in Sections 28, 32, 33, 35, 39 and 40.

@export var id: StringName = &""
@export var display_name: String = ""
@export var species_label: String = ""
@export_range(1, 5) var tier: int = 1

@export_group("Economy")
@export var sale_base: int = 0
@export var sale_multiplier: float = 1.0
## Probability inside the fish pool (after the trash roll failed).
@export_range(0.0, 1.0, 0.0001) var conditional_chance: float = 0.0

@export_group("Fishing")
@export var strike_window_sec: float = 0.0
@export_range(0.0, 0.245, 0.0001) var reel_half_width: float = 0.0
@export var reel_move_speed: float = 0.0
@export var line_stress_per_sec: float = 0.0

@export_group("Duels")
@export var boxing_hp: float = 0.0
@export var boxing_attack: float = 0.0
@export var boxing_telegraph_sec: float = 0.0
@export_range(0.0, 100.0) var arm_strength: float = 0.0
@export_range(0.0, 100.0) var rhythm_skill: float = 0.0
@export_range(0.0, 1.0, 0.0001) var tell_truth_probability: float = 0.0

@export_group("Flavor")
@export var weight_min_kg: float = 0.0
@export var weight_max_kg: float = 0.0
@export var dialogue_sequence_id: StringName = &""

@export_group("Generated Assets")
@export var model_scene: PackedScene
@export var portrait_texture: Texture2D


## Effective Market price. Don Arowana: Rp 240,000 x 1.25 = Rp 300,000.
func get_sale_value() -> int:
	return roundi(float(sale_base) * sale_multiplier)


func has_sale_multiplier() -> bool:
	return not is_equal_approx(sale_multiplier, 1.0)
