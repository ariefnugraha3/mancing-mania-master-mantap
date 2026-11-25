class_name EncounterRoller
extends RefCounted
## Decides what is on the hook (GDD Sections 25, 26, 28, 29, 30, 82).
##
## Everything about an encounter comes from one encounter seed through named
## RNG channels, so a reported seed replays the exact same bite: what it is,
## how heavy, how long the wait was and where the false nibbles fell.

const KIND_FISH := &"fish"
const KIND_TRASH := &"trash"
## BIG ONE catches weigh in at the 90th percentile of the species or above.
const BIG_ONE_PERCENTILE := 0.9
## False nibbles fall inside this share of the waiting time.
const NIBBLE_WINDOW := Vector2(0.18, 0.82)


## Rolls a full encounter. `forced_item` (debug or the scripted first fish)
## replaces the catch roll but nothing else. `location_id` is the spot: its
## fish, its water and, on tidal water, the tide of cast `cast_index`
## (revision 6.7).
static func roll(seed: int, bait_level: int, forced_item: StringName = &"", wait_override_sec: float = -1.0,
		location_id: StringName = ContentIds.START_LOCATION, cast_index: int = 0, wait_scale: float = 1.0) -> Dictionary:
	var balance := GameData.get_fishing_balance()
	var location := GameData.get_location(location_id)
	var trash_chance := location.trash_probability(balance.trash_probability, cast_index) if location != null else balance.trash_probability
	var trash_roll := RNGService.roll_float(&"trash", seed)
	var item_id := forced_item
	if item_id == &"":
		if trash_roll < trash_chance:
			item_id = pick_trash(RNGService.roll_float(&"trash_type", seed))
		else:
			item_id = pick_fish(RNGService.roll_float(&"fish", seed), location_id)

	var encounter := {
		"seed": seed,
		"item_id": item_id,
		"kind": KIND_FISH if GameData.is_fish(item_id) else KIND_TRASH,
		"weight_kg": 0.0,
		"is_big_one": false,
		"strike_window_sec": balance.trash_strike_window_sec,
		"wait_sec": wait_time(RNGService.roll_float(&"wait", seed), bait_level, location, wait_scale),
		"nibble_times": [],
		"location": location_id,
	}
	if wait_override_sec > 0.0:
		encounter["wait_sec"] = wait_override_sec

	if encounter["kind"] == KIND_FISH:
		var fish := GameData.get_fish(item_id)
		var big_chance := balance.big_one_probability * (location.big_one_multiplier if location != null else 1.0)
		var is_big := RNGService.roll_float(&"big_one", seed) < big_chance
		encounter["is_big_one"] = is_big
		var heavier := location.weight_multiplier if location != null else 1.0
		encounter["weight_kg"] = snappedf(weight(fish, RNGService.roll_float(&"weight", seed), is_big) * heavier, 0.01)
		encounter["strike_window_sec"] = fish.strike_window_sec * (location.strike_window_multiplier if location != null else 1.0)

	var nibble_span := balance.false_nibble_max - balance.false_nibble_min + 1
	var nibbles := balance.false_nibble_min + RNGService.choose_index(&"nibble_count", seed, nibble_span)
	var times: Array[float] = []
	for index: int in nibbles:
		var share := lerpf(NIBBLE_WINDOW.x, NIBBLE_WINDOW.y, RNGService.roll_float(StringName("nibble_%d" % index), seed))
		times.append(share * float(encounter["wait_sec"]))
	times.sort()
	encounter["nibble_times"] = times
	return encounter


## Maps a uniform roll to one of the spot's fish by their conditional chances.
static func pick_fish(roll_value: float, location_id: StringName = ContentIds.START_LOCATION) -> StringName:
	var cumulative := 0.0
	var fish_list := GameData.get_location_fish(location_id)
	for fish: FishData in fish_list:
		cumulative += fish.conditional_chance
		if roll_value < cumulative:
			return fish.id
	return fish_list[fish_list.size() - 1].id


## Maps a uniform roll to a trash item by the chances in TrashData.
static func pick_trash(roll_value: float) -> StringName:
	var cumulative := 0.0
	for trash: TrashData in GameData.get_all_trash():
		cumulative += trash.chance
		if roll_value < cumulative:
			return trash.id
	return ContentIds.TRASH_IDS[ContentIds.TRASH_IDS.size() - 1]


## Seconds from the end of the cast to the real bite (GDD Section 25). Deep
## water waits longer, fast water shorter (the spot's wait multiplier).
static func wait_time(roll_value: float, bait_level: int, location: LocationData = null, wait_scale: float = 1.0) -> float:
	var balance := GameData.get_fishing_balance()
	var base := lerpf(balance.base_wait_min_sec, balance.base_wait_max_sec, roll_value)
	if location != null:
		base *= location.wait_multiplier
	var multiplier := 1.0 - balance.bait_wait_reduction_per_level * float(clampi(bait_level, 0, ContentIds.UPGRADE_MAX_LEVEL))
	return maxf(base * multiplier * maxf(wait_scale, 0.1), balance.wait_min_final_sec)


## Cosmetic weight inside the species range (GDD Section 82).
static func weight(fish: FishData, roll_value: float, is_big_one: bool) -> float:
	var share := lerpf(BIG_ONE_PERCENTILE, 1.0, roll_value) if is_big_one else roll_value * BIG_ONE_PERCENTILE
	return snappedf(lerpf(fish.weight_min_kg, fish.weight_max_kg, share), 0.01)
