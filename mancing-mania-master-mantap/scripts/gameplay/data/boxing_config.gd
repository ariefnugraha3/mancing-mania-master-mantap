class_name BoxingConfig
extends Resource
## Tinju Empang tuning (GDD 170.4). Stored at res://data/balance/boxing_config.tres.

@export_group("Player")
@export var player_base_hp: float = 100.0
@export var hp_per_tonic_level: float = 25.0

@export_group("Attacks")
@export var jab_damage: float = 11.0
@export var jab_startup_sec: float = 0.11
@export var jab_recovery_sec: float = 0.25
@export var cross_damage: float = 18.0
@export var cross_startup_sec: float = 0.20
@export var cross_recovery_sec: float = 0.44
@export var blocked_damage_multiplier: float = 0.40

@export_group("Dodge")
@export var perfect_dodge_window_sec: float = 0.18
@export var perfect_freeze_sec: float = 0.07
@export var perfect_counter_sec: float = 0.85
@export var perfect_damage_multiplier: float = 2.4
@export var normal_counter_sec: float = 0.62
@export var normal_damage_multiplier: float = 2.0

@export_group("Round")
@export var round_time_sec: float = 60.0
@export var normal_attack_cd_min: float = 1.2
@export var normal_attack_cd_max: float = 2.1
@export var boss_attack_cd_min: float = 0.95
@export var boss_attack_cd_max: float = 1.65
