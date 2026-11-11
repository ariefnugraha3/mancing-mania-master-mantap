class_name ArmWrestleConfig
extends Resource
## Panco Maut tuning (GDD 170.5). Stored at res://data/balance/arm_wrestle_config.tres.

@export_group("Round")
@export var round_time_sec: float = 32.0
@export var position_min: float = -100.0
@export var position_max: float = 100.0

@export_group("Stamina")
@export var base_stamina: float = 100.0
@export var stamina_bonus_per_level: float = 0.20
@export var regen_delay_sec: float = 0.35
@export var regen_per_sec: float = 26.0

@export_group("Mash")
@export var press_impulse: float = 4.8
@export var press_stamina_cost: float = 7.0
@export var max_press_rate_per_sec: float = 10.0

@export_group("Tiebreak")
@export var sudden_grip_threshold: float = 2.0
@export var sudden_grip_target: float = 5.0
@export var sudden_grip_max_sec: float = 5.0
@export var boss_rematch_sec: float = 10.0
