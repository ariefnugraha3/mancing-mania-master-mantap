class_name DanceConfig
extends Resource
## Joget Koplo tuning (GDD 170.6). Stored at res://data/balance/dance_config.tres.

@export_group("Track")
@export var bpm_min: int = 132
@export var bpm_max: int = 156
@export var duration_min_sec: float = 36.0
@export var duration_max_sec: float = 44.0

@export_group("Judgment")
@export var perfect_window_ms: int = 55
@export var great_window_ms: int = 100
@export var good_window_ms: int = 175

@export_group("Score")
@export var perfect_score: int = 1000
@export var great_score: int = 700
@export var good_score: int = 350
@export var combo_step: int = 10
@export var combo_bonus_step: float = 0.10
@export var combo_bonus_max: float = 0.50

@export_group("Upgrade")
@export var coffee_visual_slow_per_level: float = 0.12
