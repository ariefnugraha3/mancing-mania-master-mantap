class_name LocationData
extends Resource
## One fishing spot (GDD revision 6.7, Section 165.7). Stored at
## res://data/locations/<id>.tres. The spot decides which fish bite, how the
## water behaves and which duels its Wheel of Fate holds; selling is always
## at Bu Yati's warung, wherever the fish came from.

@export var id: StringName = &""
## 1 for Cempaka Lake up to 5 for Mawar Pier.
@export_range(1, 5) var tier: int = 1
## The Market event whose completion opens the spot; empty for the first spot.
@export var unlock_event: StringName = &""
## Price of the access item sold at the warung (Rp); 0 when none is needed.
@export var access_price: int = 0

@export_group("Water")
## Multiplies the bite wait (deep water waits longer).
@export var wait_multiplier: float = 1.0
## Multiplies every fish's strike window (a current gives less time).
@export var strike_window_multiplier: float = 1.0
## Multiplies the BIG ONE chance.
@export var big_one_multiplier: float = 1.0
## Multiplies cosmetic weights.
@export var weight_multiplier: float = 1.0
## A river current: added to the reel marker's velocity (negative pushes the
## marker down, toward losing the fish).
@export var reel_drift: float = 0.0
## Tides: the water changes every this many casts (0 = no tide). High tide
## brings fish; low tide uncovers trash.
@export var tide_period_casts: int = 0
@export var tide_high_trash_multiplier: float = 1.0
@export var tide_low_trash_multiplier: float = 1.0
## Waves: extra line stress per second at the crest of a wave.
@export var wave_stress_per_sec: float = 0.0
@export var wave_period_sec: float = 3.2

@export_group("Duels")
## The eight segments of this spot's Wheel of Fate, clockwise from the top.
## A duel's share of the segments is its chance.
@export var wheel_segments: Array[StringName] = []

@export_group("Look and Sound")
@export var set_scene: PackedScene
## AudioManager ambience state at this spot.
@export var ambience: StringName = &"lake"


## The duels this spot can roll, in Wheel order, each once.
func get_duel_ids() -> Array[StringName]:
	var duels: Array[StringName] = []
	for duel_id: StringName in wheel_segments:
		if not duels.has(duel_id):
			duels.append(duel_id)
	return duels


## True at high tide for the cast with `cast_index` (only on tidal water).
func is_high_tide(cast_index: int) -> bool:
	if tide_period_casts <= 0:
		return true
	return (maxi(cast_index, 0) / tide_period_casts) % 2 == 0


## Trash chance for a cast at this spot.
func trash_probability(base: float, cast_index: int) -> float:
	if tide_period_casts <= 0:
		return base
	var multiplier := tide_high_trash_multiplier if is_high_tide(cast_index) else tide_low_trash_multiplier
	return clampf(base * multiplier, 0.0, 0.9)


## Extra line stress per second from the waves at `time_sec` (0 when calm).
func wave_stress(time_sec: float) -> float:
	if wave_stress_per_sec <= 0.0:
		return 0.0
	var phase := sin(TAU * time_sec / maxf(wave_period_sec, 0.1))
	return wave_stress_per_sec * maxf(phase, 0.0)
