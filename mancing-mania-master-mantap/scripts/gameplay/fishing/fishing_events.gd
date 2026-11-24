class_name FishingEvents
extends RefCounted
## Which small happening comes next at the fishing spot, and when (revision
## 6.12): a fish leaps, a bird dives, a frog croaks, a dragonfly rests on the
## float, something drifts past, the family texts, a drizzle passes, a
## neighbour rides by, children fly kites; and the comic ones: a fish mocks the
## bait, the debt collector rides by, ducks parade past, a cat judges the
## bucket.
##
## Only quiet fishing counts toward the next one: Darto idle or waiting for a
## bite, with nothing else on screen. One happens at a time; the same one never
## comes twice running, and the rarer ones keep a few others between them.
## Rules only: the world, the HUD and the rewards are FishingEventDirector's.

const FISH_JUMP := &"fish_jump"
const BIRD := &"bird"
const FROG := &"frog"
const DRAGONFLY := &"dragonfly"
const SANDAL := &"sandal"
const BOTTLE := &"bottle"
const FAMILY := &"family"
const DRIZZLE := &"drizzle"
const MOTOR := &"motor"
const KITES := &"kites"
## The comic ones (revision 6.12): a fish pops up to mock the bait, CepatCash's
## debt collector rides by, a family of ducks parades past, and an orange cat
## inspects the bucket.
const HECKLE := &"heckle"
const COLLECTOR := &"collector"
const DUCKS := &"ducks"
const CAT := &"cat"

## Seconds of quiet fishing between two happenings, picked afresh each time
## ("often": one every 20-40 s).
const GAP_SEC := Vector2(20.0, 40.0)
## The first one comes a little sooner after arriving at a spot.
const FIRST_GAP_SEC := Vector2(10.0, 18.0)
## Retry soon when nothing could happen just now (no float in the water for
## the dragonfly, say).
const RETRY_SEC := 2.0

const LAND_SPOTS: Array[StringName] = [&"cempaka", &"kenanga", &"melati", &"anggrek"]
const FRESH_SPOTS: Array[StringName] = [&"cempaka", &"kenanga", &"melati"]
## Spots by the sea get a gull instead of a kingfisher.
const SEA_SPOTS: Array[StringName] = [&"anggrek", &"mawar"]

## weight: how likely among the possible ones; spots: where it can happen
## (empty: everywhere); float: needs the float in the water; spacing: how many
## other happenings must come before it happens again.
const EVENTS: Dictionary = {
	FISH_JUMP: {"weight": 3.0, "spots": [], "float": false, "spacing": 1},
	BIRD: {"weight": 2.0, "spots": [], "float": false, "spacing": 2},
	FROG: {"weight": 2.0, "spots": FRESH_SPOTS, "float": false, "spacing": 2},
	DRAGONFLY: {"weight": 2.0, "spots": LAND_SPOTS, "float": true, "spacing": 2},
	SANDAL: {"weight": 1.0, "spots": [], "float": false, "spacing": 4},
	BOTTLE: {"weight": 1.2, "spots": [], "float": false, "spacing": 4},
	FAMILY: {"weight": 1.6, "spots": [], "float": false, "spacing": 3},
	DRIZZLE: {"weight": 0.9, "spots": [], "float": false, "spacing": 5},
	MOTOR: {"weight": 1.3, "spots": LAND_SPOTS, "float": false, "spacing": 3},
	KITES: {"weight": 1.3, "spots": LAND_SPOTS, "float": false, "spacing": 3},
	HECKLE: {"weight": 2.0, "spots": [], "float": false, "spacing": 2},
	COLLECTOR: {"weight": 1.0, "spots": LAND_SPOTS, "float": false, "spacing": 4},
	DUCKS: {"weight": 1.4, "spots": LAND_SPOTS, "float": false, "spacing": 3},
	CAT: {"weight": 1.4, "spots": [], "float": false, "spacing": 3},
}

var _rng: RandomNumberGenerator
var _location: StringName
var _quiet_left: float = 0.0
var _running: StringName = &""
var _history: Array[StringName] = []


func _init(location_id: StringName, rng: RandomNumberGenerator) -> void:
	_location = location_id
	_rng = rng
	_quiet_left = _rng.randf_range(FIRST_GAP_SEC.x, FIRST_GAP_SEC.y)


## Counts `delta` seconds of fishing. Returns the happening to start now, or
## &"" when none is due (or one is still running, or it was not quiet).
func advance(delta: float, quiet: bool, float_in_water: bool) -> StringName:
	if _running != &"" or not quiet:
		return &""
	_quiet_left -= delta
	if _quiet_left > 0.0:
		return &""
	var next := choose(float_in_water)
	if next == &"":
		_quiet_left = RETRY_SEC
		return &""
	_running = next
	_history.append(next)
	return next


## Starts `event_id` now, outside the schedule (tests and QA).
func force(event_id: StringName) -> void:
	_running = event_id
	_history.append(event_id)


## The happening has ended: the wait for the next one starts.
func finish() -> void:
	_running = &""
	_quiet_left = _rng.randf_range(GAP_SEC.x, GAP_SEC.y)


func get_running() -> StringName:
	return _running


func get_quiet_left() -> float:
	return _quiet_left


func get_history() -> Array[StringName]:
	return _history.duplicate()


## The happenings that may come now, at this spot.
func candidates(float_in_water: bool) -> Array[StringName]:
	var found: Array[StringName] = []
	for event_id: StringName in EVENTS:
		var event: Dictionary = EVENTS[event_id]
		var spots: Array = event["spots"]
		if not spots.is_empty() and not spots.has(_location):
			continue
		if bool(event["float"]) and not float_in_water:
			continue
		var spacing := int(event["spacing"])
		if _history.slice(maxi(_history.size() - spacing, 0)).has(event_id):
			continue
		found.append(event_id)
	return found


## One of the possible happenings, by weight; &"" when none is possible.
func choose(float_in_water: bool) -> StringName:
	var found := candidates(float_in_water)
	var total := 0.0
	for event_id: StringName in found:
		total += float(EVENTS[event_id]["weight"])
	if total <= 0.0:
		return &""
	var roll := _rng.randf() * total
	for event_id: StringName in found:
		roll -= float(EVENTS[event_id]["weight"])
		if roll <= 0.0:
			return event_id
	return found.back()


static func is_sea(location_id: StringName) -> bool:
	return SEA_SPOTS.has(location_id)
