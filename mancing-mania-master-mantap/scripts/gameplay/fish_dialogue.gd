class_name FishDialogue
extends RefCounted
## Picks the fish's lines (GDD Section 166).
##
## Each fish has a first-meeting conversation (a DialogueSequence) and four
## pools: LAND, PLAYER_WIN, FISH_WIN_ESCAPE and REEL_ESCAPE. Darto has three
## reaction pools. Picks use their own seeded stream, separate from every
## economic roll, so dialogue can never change gameplay odds.

const POOL_LAND := &"land"
const POOL_PLAYER_WIN := &"player_win"
const POOL_FISH_WIN := &"fish_win"
const POOL_REEL_ESCAPE := &"reel_escape"
const FISH_POOLS: Dictionary = {POOL_LAND: 4, POOL_PLAYER_WIN: 4, POOL_FISH_WIN: 4, POOL_REEL_ESCAPE: 3}
const DARTO_AFTER_WIN := &"after_win"
const DARTO_AFTER_LOSS := &"after_loss"
const DARTO_AFTER_REEL_ESCAPE := &"after_reel_escape"
const DARTO_POOLS: Dictionary = {DARTO_AFTER_WIN: 4, DARTO_AFTER_LOSS: 4, DARTO_AFTER_REEL_ESCAPE: 3}
const SEQUENCE_PATH := "res://data/dialogue/%s.tres"
const AROWANA_FIRST_WIN := &"fish_arowana_don_first_win"


## One line from a fish's pool, as {speaker, text}.
static func pick(fish_id: StringName, pool: StringName, seed: int) -> Dictionary:
	var count: int = FISH_POOLS.get(pool, 0)
	var index := _index(seed, "%s:%s" % [fish_id, pool], count)
	return {"speaker": speaker_name(fish_id), "text": TextDb.t(StringName("dialogue.%s.%s.%d" % [fish_id, pool, index + 1]))}


## One of Darto's reactions, as {speaker, text}.
static func pick_darto(pool: StringName, seed: int) -> Dictionary:
	var count: int = DARTO_POOLS.get(pool, 0)
	var index := _index(seed, "darto:%s" % pool, count)
	return {"speaker": speaker_name(&"darto"), "text": TextDb.t(StringName("dialogue.darto.%s.%d" % [pool, index + 1]))}


## The fish's first-meeting conversation, as a list of {speaker, text}.
static func first_meeting(fish_id: StringName) -> Array[Dictionary]:
	var fish := GameData.get_fish(fish_id)
	return sequence_lines(fish.dialogue_sequence_id if fish != null else &"")


static func sequence_lines(sequence_id: StringName) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var path := SEQUENCE_PATH % sequence_id
	if not ResourceLoader.exists(path):
		return lines
	var sequence := load(path) as DialogueSequence
	if sequence == null:
		return lines
	for entry: DialogueEntry in sequence.entries:
		lines.append({"speaker": speaker_name(entry.speaker_id), "text": entry.text, "pause": entry.post_pause_sec})
	return lines


## The lines after a duel: the fish speaks, then Darto reacts. Don Arowana's
## first defeat has its own exchange (GDD 166.6).
static func after_duel(fish_id: StringName, player_won: bool, seed: int, first_boss_win: bool = false) -> Array[Dictionary]:
	if player_won and first_boss_win and fish_id == ContentIds.BOSS_FISH_ID:
		return sequence_lines(AROWANA_FIRST_WIN)
	var lines: Array[Dictionary] = []
	lines.append(pick(fish_id, POOL_PLAYER_WIN if player_won else POOL_FISH_WIN, seed))
	lines.append(pick_darto(DARTO_AFTER_WIN if player_won else DARTO_AFTER_LOSS, seed))
	return lines


## Every text key the dialogue needs; used by the tests and boot validation.
static func required_keys() -> PackedStringArray:
	var keys := PackedStringArray(["speaker.darto"])
	for fish_id: StringName in ContentIds.FISH_IDS:
		for pool: StringName in FISH_POOLS:
			for index: int in FISH_POOLS[pool]:
				keys.append("dialogue.%s.%s.%d" % [fish_id, pool, index + 1])
	for pool: StringName in DARTO_POOLS:
		for index: int in DARTO_POOLS[pool]:
			keys.append("dialogue.darto.%s.%d" % [pool, index + 1])
	return keys


static func speaker_name(speaker_id: StringName) -> String:
	if speaker_id == &"darto":
		return TextDb.t(&"speaker.darto")
	var fish := GameData.get_fish(speaker_id)
	return fish.display_name.to_upper() if fish != null else String(speaker_id).to_upper()


static func _index(seed: int, channel: String, count: int) -> int:
	if count <= 0:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed ^ SynthDsp.stable_hash("dialogue:" + channel)
	return rng.randi() % count
