class_name SaveSchema
extends RefCounted
## Save schema version 5 (GDD Section 171): defaults plus the normalization
## that turns any parsed JSON into a dictionary the game can trust.
##
## One documented extension over GDD 171.5: every fish_book entry also stores
## `duel_wins` (wins per duel mode). `favourite_duel` is defined as the mode
## with the most wins, which cannot be derived without those counts.
## See docs/implementation_decisions.md (D-003).

const VERSION := 5
const ENGINE_VERSION_LABEL := "4.7"

const HUD_SHAKE_MODES: Array[String] = ["on", "reduced", "off"]
const UI_SCALES: Array[float] = [0.9, 1.0, 1.15, 1.30]
const TEXT_SCALES: Array[float] = [1.0, 1.15, 1.30, 1.50]
const ARM_INPUT_MODES: Array[String] = ["mash", "hold_assist"]
const HANDEDNESS_MODES: Array[String] = ["right", "left"]
const DIALOGUE_SPEEDS: Array[String] = ["instant", "fast", "normal", "relaxed"]
const SKIP_HOLD_OPTIONS: Array[float] = [0.4, 0.8, 1.2]
const QUALITY_PRESETS: Array[String] = ["low", "medium", "high"]
const PLATFORMS: Array[String] = ["web", "android", "other"]
const RHYTHM_OFFSET_LIMIT_MS := 150
## Seeds stay inside 31 bits so they survive the JSON float round trip exactly.
const MAX_SAVE_SEED := 0x7FFFFFFF

const VOLUME_KEYS: Array[String] = [
	"master_volume", "music_volume", "sfx_volume", "ambience_volume", "ui_volume",
]

const INT_STAT_KEYS: Array[String] = [
	"total_casts",
	"successful_strikes",
	"failed_strikes",
	"lines_broken",
	"trash_caught",
	"fish_landed",
	"duel_wins",
	"duel_losses",
	"boxing_wins",
	"arm_wrestle_wins",
	"dance_wins",
	"suwit_wins",
	"don_arowana_defeated",
	"lifetime_sales",
	"lifetime_debt_paid",
	"family_savings",
]

const STORY_BOOL_KEYS: Array[String] = [
	"ending_completed",
	"postgame_unlocked",
	"fish_book_unlocked",
	"arowana_first_win_seen",
]

## Notes about every value the last normalize() call had to repair.
## Empty means the input already matched the schema.
static var last_repairs: PackedStringArray = PackedStringArray()


# --- Defaults ---------------------------------------------------------------

static func make_default(save_seed: int) -> Dictionary:
	var now := utc_timestamp()
	return {
		"version": VERSION,
		"created_at_utc": now,
		"last_played_at_utc": now,
		"cash": ContentIds.STARTING_CASH,
		"debt": {
			"original": ContentIds.DEBT_ORIGINAL,
			"paid": 0,
			"remaining": ContentIds.DEBT_ORIGINAL,
		},
		"upgrades": default_upgrades(),
		"bucket": default_bucket(),
		"fish_book": default_fish_book(),
		"stats": default_stats(),
		"story": default_story(),
		"tutorials": default_tutorials(),
		"settings": default_settings(),
		"rng": {
			"save_seed": sanitize_seed(save_seed),
			"encounter_counter": 0,
			"duel_counter": 0,
		},
		"system": default_system(),
	}


static func default_upgrades() -> Dictionary:
	var upgrades := {}
	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		upgrades[String(upgrade_id)] = 0
	return upgrades


static func default_bucket() -> Dictionary:
	var bucket := {}
	for item_id: StringName in ContentIds.get_bucket_item_ids():
		bucket[String(item_id)] = 0
	return bucket


static func default_fish_book_entry() -> Dictionary:
	var duel_wins := {}
	for duel_id: StringName in ContentIds.DUEL_IDS:
		duel_wins[String(duel_id)] = 0
	return {
		"discovered": false,
		"best_weight_kg": 0.0,
		"encounters": 0,
		"wins": 0,
		"losses": 0,
		"favourite_duel": "",
		"duel_wins": duel_wins,
	}


static func default_fish_book() -> Dictionary:
	var book := {}
	for fish_id: StringName in ContentIds.FISH_IDS:
		book[String(fish_id)] = default_fish_book_entry()
	return book


static func default_stats() -> Dictionary:
	var stats := {}
	for key: String in INT_STAT_KEYS:
		stats[key] = 0
	stats["largest_fish_id"] = ""
	stats["largest_fish_weight_kg"] = 0.0
	stats["play_time_sec"] = 0.0
	return stats


static func default_story() -> Dictionary:
	return {
		"chapter": "prologue",
		"seen_events": [],
		"pending_events": [],
		"ending_completed": false,
		"postgame_unlocked": false,
		"fish_book_unlocked": false,
		"arowana_first_win_seen": false,
		"market_visit_serial": 0,
		"last_market_event_visit_serial": -1,
	}


static func default_tutorials() -> Dictionary:
	var tutorials := {}
	for tutorial_id: StringName in ContentIds.TUTORIAL_IDS:
		tutorials[String(tutorial_id)] = false
	return tutorials


static func default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 0.80,
		"sfx_volume": 0.90,
		"ambience_volume": 0.75,
		"ui_volume": 0.85,
		"hud_shake": "on",
		"reduced_flash": false,
		"reduced_motion": false,
		"high_contrast_hud": false,
		"ui_scale": 1.0,
		"text_scale": 1.0,
		"rhythm_beat_pulse": true,
		"rhythm_input_offset_ms": 0,
		"rhythm_visual_offset_ms": 0,
		"arm_input_mode": "mash",
		"mobile_handedness": "right",
		"dialogue_speed": "normal",
		"skip_hold_sec": 0.8,
		"quality_preset": "medium",
		"fullscreen_web": false,
		"input_remap": {},
	}


static func default_system() -> Dictionary:
	return {
		"schema_version": VERSION,
		"engine_version": ENGINE_VERSION_LABEL,
		"build_version": build_version(),
		"last_platform": current_platform(),
	}


static func build_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


static func current_platform() -> String:
	if OS.has_feature("web"):
		return "web"
	if OS.has_feature("android"):
		return "android"
	return "other"


static func utc_timestamp() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"


## The schema version stored in a parsed save, or 0 when it has none.
static func read_version(data: Dictionary) -> int:
	return _read_int(data.get("version"), 0)


static func sanitize_seed(save_seed: int) -> int:
	var clean := save_seed & MAX_SAVE_SEED
	return clean if clean > 0 else 1


# --- Normalization ----------------------------------------------------------

## Returns a schema-v5 dictionary built from `raw`, or an empty dictionary when
## the data cannot be trusted at all (GDD 171.12). `raw` must already be at
## VERSION; older versions go through SaveManager.migrate_save() first.
static func normalize(raw: Variant) -> Dictionary:
	last_repairs = PackedStringArray()
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = raw
	if _read_int(source.get("version"), 0) != VERSION:
		return {}

	var debt := _normalize_debt(_as_dictionary(source.get("debt")), _as_dictionary(source.get("stats")))
	if debt.is_empty():
		return {}

	var out := make_default(1)
	out["created_at_utc"] = _take_string(source, "created_at_utc", out["created_at_utc"], "created_at_utc")
	out["last_played_at_utc"] = _take_string(source, "last_played_at_utc", out["last_played_at_utc"], "last_played_at_utc")
	out["cash"] = _take_int(source, "cash", ContentIds.STARTING_CASH, 0, 9_000_000_000_000, "cash")
	out["debt"] = debt
	out["upgrades"] = _normalize_upgrades(_take_dictionary(source, "upgrades"))
	out["bucket"] = _normalize_bucket(_take_dictionary(source, "bucket"))
	out["fish_book"] = _normalize_fish_book(_take_dictionary(source, "fish_book"))
	out["stats"] = _normalize_stats(_take_dictionary(source, "stats"), int(debt["paid"]))
	out["story"] = _normalize_story(_take_dictionary(source, "story"))
	out["tutorials"] = _normalize_tutorials(_take_dictionary(source, "tutorials"))
	out["settings"] = normalize_settings(_take_dictionary(source, "settings"))
	out["rng"] = _normalize_rng(_take_dictionary(source, "rng"))
	out["system"] = _normalize_system(_take_dictionary(source, "system"))

	for key: Variant in source:
		if not out.has(key):
			_note("dropped unknown top-level field '%s'" % key)
	return out


## Normalizes a whole settings block; unknown keys are dropped.
static func normalize_settings(source: Dictionary) -> Dictionary:
	var settings := default_settings()
	for key: String in settings.keys():
		if source.has(key):
			var normalized: Variant = normalize_setting(key, source[key])
			if not _same_value(normalized, source[key]):
				_note("settings.%s repaired" % key)
			settings[key] = normalized
		else:
			_note("settings.%s missing" % key)
	return settings


## Returns the valid value for one setting, falling back to its default when
## `value` has the wrong type or is outside the allowed set. Returns null for
## an unknown key.
static func normalize_setting(key: String, value: Variant) -> Variant:
	var defaults := default_settings()
	if not defaults.has(key):
		return null
	var fallback: Variant = defaults[key]
	if VOLUME_KEYS.has(key):
		return clampf(_read_float(value, fallback), 0.0, 1.0)
	match key:
		"hud_shake":
			return _read_enum(value, HUD_SHAKE_MODES, fallback)
		"ui_scale":
			return _read_option(value, UI_SCALES, fallback)
		"text_scale":
			return _read_option(value, TEXT_SCALES, fallback)
		"rhythm_input_offset_ms", "rhythm_visual_offset_ms":
			return clampi(_read_int(value, fallback), -RHYTHM_OFFSET_LIMIT_MS, RHYTHM_OFFSET_LIMIT_MS)
		"arm_input_mode":
			return _read_enum(value, ARM_INPUT_MODES, fallback)
		"mobile_handedness":
			return _read_enum(value, HANDEDNESS_MODES, fallback)
		"dialogue_speed":
			return _read_enum(value, DIALOGUE_SPEEDS, fallback)
		"skip_hold_sec":
			return _read_option(value, SKIP_HOLD_OPTIONS, fallback)
		"quality_preset":
			return _read_enum(value, QUALITY_PRESETS, fallback)
		"input_remap":
			return normalize_input_remap(value)
	# Everything left is a boolean toggle.
	return value if typeof(value) == TYPE_BOOL else fallback


## Keeps only valid keyboard/mouse overrides: { action: ["key:<physical>", "mouse:<button>"] }.
static func normalize_input_remap(value: Variant) -> Dictionary:
	var clean := {}
	if typeof(value) != TYPE_DICTIONARY:
		return clean
	var source: Dictionary = value
	for action: Variant in source:
		if typeof(action) != TYPE_STRING and typeof(action) != TYPE_STRING_NAME:
			continue
		if not InputActions.REMAPPABLE.has(StringName(action)):
			continue
		if typeof(source[action]) != TYPE_ARRAY:
			continue
		var tokens: Array = []
		for token: Variant in source[action]:
			if typeof(token) == TYPE_STRING and is_valid_binding_token(token) and not tokens.has(token):
				tokens.append(token)
		if not tokens.is_empty():
			clean[String(action)] = tokens
	return clean


static func is_valid_binding_token(token: String) -> bool:
	var parts := token.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int():
		return false
	var code := parts[1].to_int()
	match parts[0]:
		"key":
			return code > 0
		"mouse":
			return code >= MOUSE_BUTTON_LEFT and code <= MOUSE_BUTTON_XBUTTON2
	return false


static func _normalize_debt(source: Dictionary, stats_source: Dictionary) -> Dictionary:
	var original := ContentIds.DEBT_ORIGINAL
	var paid := _read_int(source.get("paid"), -1)
	var remaining := _read_int(source.get("remaining"), -1)
	var paid_valid := _is_number(source.get("paid")) and paid >= 0 and paid <= original
	var remaining_valid := _is_number(source.get("remaining")) and remaining >= 0 and remaining <= original

	if _read_int(source.get("original"), -1) != original:
		_note("debt.original repaired")

	if paid_valid and remaining_valid and paid + remaining == original:
		pass
	elif paid_valid:
		# `paid` only ever grows, so it wins when the pair disagrees.
		_note("debt.remaining recomputed from debt.paid")
		remaining = original - paid
	elif remaining_valid:
		_note("debt.paid recomputed from debt.remaining")
		paid = original - remaining
	else:
		var lifetime := _read_int(stats_source.get("lifetime_debt_paid"), -1)
		if _is_number(stats_source.get("lifetime_debt_paid")) and lifetime >= 0 and lifetime <= original:
			_note("debt recovered from stats.lifetime_debt_paid")
			paid = lifetime
			remaining = original - paid
		else:
			return {}
	return {"original": original, "paid": paid, "remaining": remaining}


static func _normalize_upgrades(source: Dictionary) -> Dictionary:
	var upgrades := default_upgrades()
	for key: String in upgrades.keys():
		upgrades[key] = _take_int(source, key, 0, 0, ContentIds.UPGRADE_MAX_LEVEL, "upgrades.%s" % key)
	return upgrades


static func _normalize_bucket(source: Dictionary) -> Dictionary:
	var bucket := default_bucket()
	for key: String in bucket.keys():
		bucket[key] = _take_int(source, key, 0, 0, 1_000_000_000, "bucket.%s" % key)
	return bucket


static func _normalize_fish_book(source: Dictionary) -> Dictionary:
	var book := default_fish_book()
	for fish_key: String in book.keys():
		var entry_source := _take_dictionary(source, fish_key, "fish_book.%s" % fish_key)
		var path := "fish_book.%s" % fish_key
		var entry: Dictionary = book[fish_key]
		entry["discovered"] = _take_bool(entry_source, "discovered", false, path + ".discovered")
		entry["best_weight_kg"] = _take_float(entry_source, "best_weight_kg", 0.0, 0.0, 1000.0, path + ".best_weight_kg")
		entry["encounters"] = _take_int(entry_source, "encounters", 0, 0, 1_000_000_000, path + ".encounters")
		entry["wins"] = _take_int(entry_source, "wins", 0, 0, 1_000_000_000, path + ".wins")
		entry["losses"] = _take_int(entry_source, "losses", 0, 0, 1_000_000_000, path + ".losses")

		var wins_source := _take_dictionary(entry_source, "duel_wins", path + ".duel_wins")
		var duel_wins: Dictionary = entry["duel_wins"]
		for duel_key: String in duel_wins.keys():
			duel_wins[duel_key] = _take_int(wins_source, duel_key, 0, 0, 1_000_000_000, "%s.duel_wins.%s" % [path, duel_key])

		var favourite := favourite_duel_from_wins(duel_wins)
		if str(entry_source.get("favourite_duel", "")) != favourite:
			_note("%s.favourite_duel recomputed" % path)
		entry["favourite_duel"] = favourite
	return book


## The duel mode with the most wins; ties resolve in ContentIds.DUEL_IDS order.
static func favourite_duel_from_wins(duel_wins: Dictionary) -> String:
	var best_id := ""
	var best_wins := 0
	for duel_id: StringName in ContentIds.DUEL_IDS:
		var wins := _read_int(duel_wins.get(String(duel_id)), 0)
		if wins > best_wins:
			best_wins = wins
			best_id = String(duel_id)
	return best_id


static func _normalize_stats(source: Dictionary, debt_paid: int) -> Dictionary:
	var stats := default_stats()
	for key: String in INT_STAT_KEYS:
		stats[key] = _take_int(source, key, 0, 0, 9_000_000_000_000, "stats.%s" % key)
	# Narrative milestones read lifetime_debt_paid, so it must agree with the ledger.
	if stats["lifetime_debt_paid"] != debt_paid:
		_note("stats.lifetime_debt_paid aligned with debt.paid")
		stats["lifetime_debt_paid"] = debt_paid

	var largest_id := _take_string(source, "largest_fish_id", "", "stats.largest_fish_id")
	if largest_id != "" and not ContentIds.FISH_IDS.has(StringName(largest_id)):
		_note("stats.largest_fish_id was not a known fish")
		largest_id = ""
	stats["largest_fish_id"] = largest_id
	stats["largest_fish_weight_kg"] = _take_float(source, "largest_fish_weight_kg", 0.0, 0.0, 1000.0, "stats.largest_fish_weight_kg")
	if largest_id == "":
		stats["largest_fish_weight_kg"] = 0.0
	stats["play_time_sec"] = _take_float(source, "play_time_sec", 0.0, 0.0, 1.0e12, "stats.play_time_sec")
	return stats


static func _normalize_story(source: Dictionary) -> Dictionary:
	var story := default_story()
	var chapter := _take_string(source, "chapter", "prologue", "story.chapter")
	if not ContentIds.CHAPTER_IDS.has(StringName(chapter)):
		_note("story.chapter was not a known chapter")
		chapter = "prologue"
	story["chapter"] = chapter

	var seen := _clean_event_list(source.get("seen_events"), [], "story.seen_events")
	story["seen_events"] = seen
	story["pending_events"] = _clean_event_list(source.get("pending_events"), seen, "story.pending_events")

	for key: String in STORY_BOOL_KEYS:
		story[key] = _take_bool(source, key, false, "story.%s" % key)
	story["market_visit_serial"] = _take_int(source, "market_visit_serial", 0, 0, 1_000_000_000, "story.market_visit_serial")
	story["last_market_event_visit_serial"] = _take_int(
		source, "last_market_event_visit_serial", -1, -1, 1_000_000_000, "story.last_market_event_visit_serial")
	return story


## Keeps known event IDs once each, dropping anything listed in `exclude`.
static func _clean_event_list(value: Variant, exclude: Array, path: String) -> Array:
	var clean: Array = []
	if typeof(value) != TYPE_ARRAY:
		_note("%s was not a list" % path)
		return clean
	for item: Variant in value:
		var is_text := typeof(item) == TYPE_STRING or typeof(item) == TYPE_STRING_NAME
		var event_id := String(item) if is_text else ""
		if not is_text or not ContentIds.STORY_EVENT_IDS.has(StringName(event_id)):
			_note("%s dropped unknown event '%s'" % [path, item])
		elif clean.has(event_id) or exclude.has(event_id):
			_note("%s dropped duplicate or already-seen event '%s'" % [path, event_id])
		else:
			clean.append(event_id)
	return clean


static func _normalize_tutorials(source: Dictionary) -> Dictionary:
	var tutorials := default_tutorials()
	for key: String in tutorials.keys():
		tutorials[key] = _take_bool(source, key, false, "tutorials.%s" % key)
	return tutorials


static func _normalize_rng(source: Dictionary) -> Dictionary:
	var seed_value := _read_int(source.get("save_seed"), 0)
	if not _is_number(source.get("save_seed")) or seed_value <= 0 or seed_value > MAX_SAVE_SEED:
		# A lost seed only changes future rolls; progression stays intact.
		_note("rng.save_seed regenerated")
		seed_value = sanitize_seed(randi())
	return {
		"save_seed": seed_value,
		"encounter_counter": _take_int(source, "encounter_counter", 0, 0, 2_000_000_000, "rng.encounter_counter"),
		"duel_counter": _take_int(source, "duel_counter", 0, 0, 2_000_000_000, "rng.duel_counter"),
	}


static func _normalize_system(source: Dictionary) -> Dictionary:
	var system := default_system()
	system["engine_version"] = _take_string(source, "engine_version", system["engine_version"], "system.engine_version")
	system["build_version"] = _take_string(source, "build_version", system["build_version"], "system.build_version")
	var platform := _take_string(source, "last_platform", system["last_platform"], "system.last_platform")
	system["last_platform"] = platform if PLATFORMS.has(platform) else "other"
	return system


# --- Typed readers ----------------------------------------------------------

static func _note(message: String) -> void:
	last_repairs.append(message)


static func _is_number(value: Variant) -> bool:
	var type := typeof(value)
	return (type == TYPE_INT or type == TYPE_FLOAT) and is_finite(float(value))


static func _read_int(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return fallback
	return int(clampf(float(value), -9.0e15, 9.0e15))


static func _read_float(value: Variant, fallback: float) -> float:
	return float(value) if _is_number(value) else fallback


static func _read_enum(value: Variant, options: Array[String], fallback: String) -> String:
	if typeof(value) == TYPE_STRING and options.has(value):
		return value
	return fallback


## Snaps a number to the closest allowed option.
static func _read_option(value: Variant, options: Array[float], fallback: float) -> float:
	if not _is_number(value):
		return fallback
	var best := options[0]
	for option: float in options:
		if absf(option - float(value)) < absf(best - float(value)):
			best = option
	return best


static func _same_value(a: Variant, b: Variant) -> bool:
	if _is_number(a) and _is_number(b):
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b


static func _as_dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


static func _take_dictionary(source: Dictionary, key: String, path: String = "") -> Dictionary:
	var value: Variant = source.get(key)
	if typeof(value) == TYPE_DICTIONARY:
		return value
	_note("%s was missing or not an object" % (path if path != "" else key))
	return {}


static func _take_int(source: Dictionary, key: String, fallback: int, low: int, high: int, path: String) -> int:
	var value: Variant = source.get(key)
	if not _is_number(value):
		_note("%s was missing or not a number" % path)
		return fallback
	var number := _read_int(value, fallback)
	var clamped := clampi(number, low, high)
	if clamped != number or not is_equal_approx(float(value), float(number)):
		_note("%s clamped from %s to %d" % [path, value, clamped])
	return clamped


static func _take_float(source: Dictionary, key: String, fallback: float, low: float, high: float, path: String) -> float:
	var value: Variant = source.get(key)
	if not _is_number(value):
		_note("%s was missing or not a number" % path)
		return fallback
	var clamped := clampf(float(value), low, high)
	if not is_equal_approx(clamped, float(value)):
		_note("%s clamped from %s to %s" % [path, value, clamped])
	return clamped


static func _take_bool(source: Dictionary, key: String, fallback: bool, path: String) -> bool:
	var value: Variant = source.get(key)
	if typeof(value) == TYPE_BOOL:
		return value
	_note("%s was missing or not a boolean" % path)
	return fallback


static func _take_string(source: Dictionary, key: String, fallback: String, path: String) -> String:
	var value: Variant = source.get(key)
	if typeof(value) == TYPE_STRING:
		return value
	_note("%s was missing or not text" % path)
	return fallback
