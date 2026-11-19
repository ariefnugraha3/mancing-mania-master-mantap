class_name StoryTimelines
extends RefCounted
## The story's staging and steps (GDD 173, 183), read from
## res://data/story/story_timelines.json. Every visible line in it is a key
## of the text table, so the copy lives in one place with the rest of the
## game's English text.

const PATH := "res://data/story/story_timelines.json"
const STEP_KEYS: Array[String] = ["text", "phone", "title", "sub", "unlock", "body", "button"]

static var _doc: Dictionary = {}


static func get_timeline(event_id: StringName) -> Dictionary:
	return (_load().get("timelines", {}) as Dictionary).get(String(event_id), {})


static func get_credits() -> Array:
	return _load().get("credits", [])


static func get_banter() -> Array:
	return _load().get("banter", [])


static func get_cepatcash_count() -> int:
	return int((_load().get("cepatcash", {}) as Dictionary).get("count", 0))


static func get_cepatcash_darto_count() -> int:
	return int((_load().get("cepatcash", {}) as Dictionary).get("darto", 0))


## Every text key the story uses, for the completeness tests (NAR-001).
static func all_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	var timelines: Dictionary = _load().get("timelines", {})
	for event_id: String in timelines:
		var timeline: Dictionary = timelines[event_id]
		for list_name: String in ["steps", "after_sale", "after_payment"]:
			for step: Dictionary in timeline.get(list_name, []):
				for field: String in STEP_KEYS:
					if step.has(field):
						keys.append(str(step[field]))
				for note_key: String in step.get("note", []):
					keys.append(note_key)
	for line: Dictionary in get_credits():
		keys.append(str(line["key"]))
	for exchange: Array in get_banter():
		for line: Dictionary in exchange:
			keys.append(str(line["text"]))
	for index: int in get_cepatcash_count():
		keys.append("cepatcash.%d.title" % (index + 1))
		keys.append("cepatcash.%d.body" % (index + 1))
	for index: int in get_cepatcash_darto_count():
		keys.append("cepatcash.darto.%d" % (index + 1))
	return keys


## Lines of a "say" list as {speaker, text} for the DialogueBox.
static func to_dialogue(steps: Array) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for step: Dictionary in steps:
		if step.has("say"):
			lines.append({"speaker": speaker_name(StringName(step["say"])), "text": line_text(StringName(step["text"]))})
	return lines


## A spoken or chat line in the player's language, with the player's own
## numbers filled in where the copy asks for them.
static func line_text(key: StringName) -> String:
	return TextDb.tf(key, line_values())


## The `{name}` values story lines may use: how often the catfish has won a
## duel against Darto, quoted by the family in the epilogue.
static func line_values() -> Dictionary:
	return {"catfish_losses": int(GameState.get_fish_book_entry(&"catfish_bruiser").get("losses", 0))}


static func speaker_name(who: StringName) -> String:
	var key := StringName("speaker.%s" % who)
	if TextDb.has_key(key):
		return TextDb.t(key)
	return FishDialogue.speaker_name(who)


static func reload() -> void:
	_doc = {}


static func _load() -> Dictionary:
	if not _doc.is_empty():
		return _doc
	var text := FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		GameLog.error(&"STORY", "story timelines could not be read", {"path": PATH})
		return {}
	_doc = parsed
	return _doc
