class_name TextDb
extends RefCounted
## Lookup for centralized player-visible text, in the player's language
## (GDD 133, revision 6.6).
##
## English (`ui_text.tres`) is the source table and holds every key. Each other
## language has its own table with the same keys; a key it lacks falls back to
## English, and the tests require every table to be complete.
##
## A missing key is loud on purpose: it logs an error and renders as "#key#"
## so it is caught in QA instead of shipping as blank text.

const UI_TEXT_PATH := "res://data/dialogue/ui_text.tres"
const ENGLISH := "en"
const INDONESIAN := "id"
## Every language the game ships, English first.
const LANGUAGES: Array[String] = [ENGLISH, INDONESIAN]
const TRANSLATION_PATHS: Dictionary[String, String] = {
	INDONESIAN: "res://data/dialogue/ui_text_id.tres",
}

static var _entries: Dictionary[String, String] = {}
static var _local: Dictionary[String, String] = {}
static var _language: String = ENGLISH
static var _loaded: bool = false


static func t(key: StringName) -> String:
	_ensure_loaded()
	var id := String(key)
	if _entries.has(id) or _local.has(id):
		var value := _lookup(id)
		# An entry whose whole value is another key is an alias of it (story
		# chat lines reuse the line before them), followed a few steps at most.
		var hops := 0
		while hops < 4 and value != id and (_entries.has(value) or _local.has(value)):
			id = value
			value = _lookup(id)
			hops += 1
		return value
	GameLog.error(&"TEXT", "missing text key", {"key": id})
	return "#%s#" % id


## Formats a text entry with `{name}` placeholders.
static func tf(key: StringName, values: Dictionary) -> String:
	return t(key).format(values)


## Text that lives in a data resource in English (a fish's name, an upgrade's
## name, a fish's line): the current language's entry for `key` when it has
## one, else `english`.
static func text_or(key: StringName, english: String) -> String:
	_ensure_loaded()
	var id := String(key)
	if _language != ENGLISH and _local.has(id):
		return _local[id]
	return english


static func has_key(key: StringName) -> bool:
	_ensure_loaded()
	return _entries.has(String(key)) or _local.has(String(key))


static func get_all_keys() -> PackedStringArray:
	_ensure_loaded()
	return PackedStringArray(_entries.keys())


## The language the text is in now ("en", "id").
static func get_language() -> String:
	return _language


## Switches every lookup to `language`; an unknown code means English.
static func set_language(language: String) -> void:
	_ensure_loaded()
	var code := language if LANGUAGES.has(language) else ENGLISH
	if code == _language:
		return
	_language = code
	# A fresh dictionary, never clear(): the tables are the cached resources'.
	var none: Dictionary[String, String] = {}
	_local = _load_table(TRANSLATION_PATHS[code]) if TRANSLATION_PATHS.has(code) else none


## A whole table, for tests: English, or one translation as written.
static func get_table(language: String) -> Dictionary[String, String]:
	_ensure_loaded()
	if language == ENGLISH:
		return _entries
	return _load_table(TRANSLATION_PATHS.get(language, ""))


static func reload() -> void:
	_loaded = false
	var none: Dictionary[String, String] = {}
	_entries = none
	_local = none.duplicate()
	_ensure_loaded()
	if _language != ENGLISH and TRANSLATION_PATHS.has(_language):
		_local = _load_table(TRANSLATION_PATHS[_language])


static func _lookup(id: String) -> String:
	if _local.has(id):
		return _local[id]
	return _entries.get(id, id)


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_entries = _load_table(UI_TEXT_PATH)


static func _load_table(path: String) -> Dictionary[String, String]:
	var empty: Dictionary[String, String] = {}
	if path.is_empty() or not ResourceLoader.exists(path):
		GameLog.error(&"TEXT", "text table could not be loaded", {"path": path})
		return empty
	var table := load(path) as TextTable
	if table == null:
		GameLog.error(&"TEXT", "text table could not be loaded", {"path": path})
		return empty
	return table.entries
