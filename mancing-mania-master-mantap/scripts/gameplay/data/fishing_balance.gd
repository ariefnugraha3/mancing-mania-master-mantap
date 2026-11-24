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

@export_group("Bucket")
## How many catches (fish and trash) the bucket holds before Darto must sell
## at the Market; each Big Bucket level adds more (revision 6.12).
@export var bucket_base_capacity: int = 5
@export var bucket_capacity_per_level: float = 5.0

@export_group("Reel")
@export var marker_hold_velocity: float = 0.72
@export var marker_release_velocity: float = -0.58
@export var input_ease_sec: float = 0.12
@export var landing_gain_per_sec: float = 18.0
@export var landing_loss_outside_per_sec: float = 3.0
@export var rod_half_width_per_level: float = 0.035
@export var rod_half_width_max: float = 0.245

@export_group("Bite")
## Reaction window for a trash bite (GDD Section 28).
@export var trash_strike_window_sec: float = 0.90
## How long the fish shadow circles the float before the real bite.
@export var bite_warning_sec: float = 1.1

@export_group("Green Zone")
## The fish picks a new target position at this interval (GDD Section 33).
@export var zone_retarget_min_sec: float = 0.65
@export var zone_retarget_max_sec: float = 1.40
## Chance that a boss-tier fish feints before each new target.
@export var boss_feint_probability: float = 0.35
@export var boss_feint_sec: float = 0.3

@export_group("Landing")
## Slow-motion beat when the catch breaks the surface (GDD Section 37).
@export var land_slowdown_sec: float = 0.25

@export_group("Line Stress")
@export var stress_recover_inside_per_sec: float = 30.0
@export var stress_recover_release_per_sec: float = 16.0
@export var stress_break_value: float = 100.0
