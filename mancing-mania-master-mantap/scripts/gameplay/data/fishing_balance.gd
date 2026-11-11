class_name FishingBalance
extends Resource
## Fishing-phase tuning (GDD 170.3). Stored at res://data/balance/fishing_balance.tres.

@export_group("Encounter")
@export var trash_probability: float = 0.16
@export var big_one_probability: float = 0.05

@export_group("Waiting")
@export var base_wait_min_sec: float = 4.5
@export var base_wait_max_sec: float = 9.5
@export var wait_min_final_sec: float = 1.75
@export var false_nibble_min: int = 0
@export var false_nibble_max: int = 2
@export var false_strike_delay_sec: float = 0.8
@export var bait_wait_reduction_per_level: float = 0.18

@export_group("Reel")
@export var marker_hold_velocity: float = 0.72
@export var marker_release_velocity: float = -0.58
@export var input_ease_sec: float = 0.12
@export var landing_gain_per_sec: float = 18.0
@export var landing_loss_outside_per_sec: float = 3.0
@export var rod_half_width_per_level: float = 0.035
@export var rod_half_width_max: float = 0.245

@export_group("Line Stress")
@export var stress_recover_inside_per_sec: float = 30.0
@export var stress_recover_release_per_sec: float = 16.0
@export var stress_break_value: float = 100.0
