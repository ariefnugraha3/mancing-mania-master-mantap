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

@export_group("Fish")
## The fish's constant push per point of Arm Strength, in position units per
## second. The GDD fixes the stat but not the formula (D-066).
@export var fish_pressure_per_strength: float = 0.12
## How long the fish visibly tightens before a burst.
@export var burst_warning_sec: float = 0.7
@export var burst_min_sec: float = 0.65
@export var burst_max_sec: float = 1.15
@export var burst_cooldown_min_sec: float = 3.0
@export var burst_cooldown_max_sec: float = 5.5
## Extra push during a burst, as a share of the constant push:
## base + per_tier x tier, so higher tiers burst harder.
@export var burst_base_multiplier: float = 0.5
@export var burst_tier_multiplier: float = 0.2

@export_group("Tiebreak")
@export var sudden_grip_threshold: float = 2.0
@export var sudden_grip_target: float = 5.0
@export var sudden_grip_max_sec: float = 5.0
@export var boss_rematch_sec: float = 10.0
