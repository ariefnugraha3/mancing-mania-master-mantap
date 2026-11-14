class_name TextDb
extends RefCounted
## Lookup for centralized player-visible text.
## A missing key is loud on purpose: it logs an error and renders as "#key#"
## so it is caught in QA instead of shipping as blank text.

const UI_TEXT_PATH := "res://data/dialogue/ui_text.tres"

static var _entries: Dictionary[String, String] = {}
static var _loaded: bool = false


static func t(key: StringName) -> String:
	_ensure_loaded()
	var id := String(key)
	if _entries.has(id):
		var value: String = _entries[id]
		# An entry whose whole value is another key is an alias of it (story
		# chat lines reuse the line before them), followed a few steps at most.
		var hops := 0
		while hops < 4 and value != id and _entries.has(value):
			id = value
			value = _entries[id]
			hops += 1
		return value
	GameLog.error(&"TEXT", "missing text key", {"key": id})
	return "#%s#" % id


## Formats a text entry with `{name}` placeholders.
static func tf(key: StringName, values: Dictionary) -> String:
	return t(key).format(values)


static func has_key(key: StringName) -> bool:
	_ensure_loaded()
	return _entries.has(String(key))


static func get_all_keys() -> PackedStringArray:
	_ensure_loaded()
	return PackedStringArray(_entries.keys())


static func reload() -> void:
	_loaded = false
	_entries = {}
	_ensure_loaded()


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var table := load(UI_TEXT_PATH) as TextTable
	if table == null:
		GameLog.error(&"TEXT", "text table could not be loaded", {"path": UI_TEXT_PATH})
		return
	_entries = table.entries
