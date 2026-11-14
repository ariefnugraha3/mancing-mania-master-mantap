extends Node
## Runtime source of truth for progression (GDD 128, 169.2).
##
## The state is kept in save-schema-v5 shape, so a save file is just an export
## of this node. Scenes and UI go through the methods below and never touch the
## dictionary itself.

signal cash_changed(new_cash: int)
signal debt_changed(paid: int, remaining: int)
signal bucket_changed(total_items: int)
signal upgrade_changed(upgrade_id: StringName, level: int)
signal fish_book_changed(fish_id: StringName)
signal stats_changed()
signal story_state_changed()
signal settings_changed(key: StringName)
## Emitted after the whole state was swapped (new game, load, reset).
## Settings listeners re-read everything on this instead of per-key signals.
signal state_replaced()

## Runtime-only encounter context; never saved.
var current_fish: StringName = &""
var current_duel: StringName = &""
## The fish just landed and on its way to a duel: fish_id, weight_kg,
## is_big_one and seed. Empty outside an encounter.
var current_catch: Dictionary = {}
var session_seed: int = 0

var _data: Dictionary = {}
var _has_active_game: bool = false


func _ready() -> void:
	_data = SaveSchema.make_default(1)
	session_seed = RNGService.get_session_seed()


# --- Lifecycle --------------------------------------------------------------

## Starts a fresh game. Settings chosen so far are kept.
func new_game() -> void:
	var settings: Dictionary = _data.get("settings", SaveSchema.default_settings()).duplicate(true)
	_data = SaveSchema.make_default(int(RNGService.cosmetic.randi()))
	_data["settings"] = settings
	_has_active_game = true
	_bind_rng()
	_emit_all()
	GameLog.info(&"STATE", "new game", {"save_seed": _data["rng"]["save_seed"]})


## Replaces the state with a normalized save (see SaveManager.validate_save()).
func apply_loaded_save(data: Dictionary) -> void:
	if data.is_empty():
		GameLog.error(&"STATE", "refused to apply an empty save")
		return
	_data = data.duplicate(true)
	_has_active_game = true
	_bind_rng()
	_emit_all()


## A deep copy of the state in save-schema-v5 shape.
func export_save_state() -> Dictionary:
	var snapshot := _data.duplicate(true)
	snapshot["rng"] = RNGService.get_persist_state()
	return snapshot


## Drops the current game but keeps settings (used by RESET SAVE).
func clear_game() -> void:
	var settings: Dictionary = _data.get("settings", SaveSchema.default_settings()).duplicate(true)
	_data = SaveSchema.make_default(1)
	_data["settings"] = settings
	_has_active_game = false
	current_fish = &""
	current_duel = &""
	current_catch = {}
	_emit_all()


## True once a game was started or loaded in this session.
func has_active_game() -> bool:
	return _has_active_game


# --- Cash -------------------------------------------------------------------

func get_cash() -> int:
	return int(_data["cash"])


func add_cash(amount: int) -> void:
	if amount <= 0:
		if amount < 0:
			GameLog.error(&"STATE", "add_cash rejected a negative amount", {"amount": amount})
		return
	_data["cash"] = get_cash() + amount
	cash_changed.emit(get_cash())


func can_spend(amount: int) -> bool:
	return amount >= 0 and get_cash() >= amount


func spend_cash(amount: int) -> bool:
	if amount < 0 or not can_spend(amount):
		return false
	if amount == 0:
		return true
	_data["cash"] = get_cash() - amount
	cash_changed.emit(get_cash())
	return true


# --- Debt -------------------------------------------------------------------

func get_debt_original() -> int:
	return int(_data["debt"]["original"])


func get_debt_paid() -> int:
	return int(_data["debt"]["paid"])


func get_debt_remaining() -> int:
	return int(_data["debt"]["remaining"])


## Pays up to `amount` toward the debt and returns what was actually paid.
## The payment is capped by both the cash on hand and the remaining debt.
func pay_debt(amount: int) -> int:
	if amount <= 0:
		return 0
	var payment := mini(amount, mini(get_cash(), get_debt_remaining()))
	if payment <= 0:
		return 0
	_data["cash"] = get_cash() - payment
	var debt: Dictionary = _data["debt"]
	debt["paid"] = get_debt_paid() + payment
	debt["remaining"] = get_debt_original() - int(debt["paid"])
	_data["stats"]["lifetime_debt_paid"] = int(debt["paid"])
	cash_changed.emit(get_cash())
	debt_changed.emit(get_debt_paid(), get_debt_remaining())
	stats_changed.emit()
	return payment


# --- Bucket -----------------------------------------------------------------

func add_bucket_item(item_id: StringName, quantity: int = 1) -> void:
	if not GameData.is_bucket_item(item_id) or quantity <= 0:
		GameLog.error(&"STATE", "add_bucket_item rejected", {"item": item_id, "quantity": quantity})
		return
	var bucket: Dictionary = _data["bucket"]
	bucket[String(item_id)] = get_bucket_quantity(item_id) + quantity
	bucket_changed.emit(get_bucket_total_count())


func remove_bucket_item(item_id: StringName, quantity: int) -> bool:
	if quantity <= 0 or get_bucket_quantity(item_id) < quantity:
		return false
	var bucket: Dictionary = _data["bucket"]
	bucket[String(item_id)] = get_bucket_quantity(item_id) - quantity
	bucket_changed.emit(get_bucket_total_count())
	return true


func get_bucket_quantity(item_id: StringName) -> int:
	return int(_data["bucket"].get(String(item_id), 0))


func get_bucket_total_count() -> int:
	var total := 0
	for quantity: Variant in _data["bucket"].values():
		total += int(quantity)
	return total


## Empties the given items and returns what was removed as { item_id: quantity }.
func clear_bucket_items(item_ids: Array[StringName]) -> Dictionary:
	var removed := {}
	var bucket: Dictionary = _data["bucket"]
	for item_id: StringName in item_ids:
		var quantity := get_bucket_quantity(item_id)
		if quantity > 0:
			removed[item_id] = quantity
			bucket[String(item_id)] = 0
	if not removed.is_empty():
		bucket_changed.emit(get_bucket_total_count())
	return removed


# --- Upgrades ---------------------------------------------------------------

func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(_data["upgrades"].get(String(upgrade_id), 0))


func can_buy_upgrade(upgrade_id: StringName) -> bool:
	var price := _next_upgrade_price(upgrade_id)
	return price >= 0 and can_spend(price)


func buy_next_upgrade(upgrade_id: StringName) -> bool:
	var price := _next_upgrade_price(upgrade_id)
	if price < 0 or not spend_cash(price):
		return false
	var level := get_upgrade_level(upgrade_id) + 1
	_data["upgrades"][String(upgrade_id)] = level
	upgrade_changed.emit(upgrade_id, level)
	return true


# --- Fish Book --------------------------------------------------------------

func record_encounter(fish_id: StringName) -> void:
	var entry := _fish_entry(fish_id)
	if entry.is_empty():
		return
	entry["encounters"] = int(entry["encounters"]) + 1
	fish_book_changed.emit(fish_id)


func record_fish_win(fish_id: StringName, weight_kg: float, duel_id: StringName) -> void:
	var entry := _fish_entry(fish_id)
	if entry.is_empty():
		return
	if not ContentIds.DUEL_IDS.has(duel_id):
		GameLog.error(&"STATE", "record_fish_win got an unknown duel", {"duel": duel_id})
		return
	entry["discovered"] = true
	entry["wins"] = int(entry["wins"]) + 1
	entry["best_weight_kg"] = maxf(float(entry["best_weight_kg"]), weight_kg)
	var duel_wins: Dictionary = entry["duel_wins"]
	duel_wins[String(duel_id)] = int(duel_wins[String(duel_id)]) + 1
	entry["favourite_duel"] = SaveSchema.favourite_duel_from_wins(duel_wins)

	var stats: Dictionary = _data["stats"]
	if weight_kg > float(stats["largest_fish_weight_kg"]):
		stats["largest_fish_weight_kg"] = weight_kg
		stats["largest_fish_id"] = String(fish_id)
		stats_changed.emit()
	fish_book_changed.emit(fish_id)


func record_fish_loss(fish_id: StringName) -> void:
	var entry := _fish_entry(fish_id)
	if entry.is_empty():
		return
	entry["losses"] = int(entry["losses"]) + 1
	fish_book_changed.emit(fish_id)


func is_fish_discovered(fish_id: StringName) -> bool:
	return bool(_data["fish_book"].get(String(fish_id), {}).get("discovered", false))


## A copy of one Fish Book entry, or an empty dictionary for an unknown fish.
func get_fish_book_entry(fish_id: StringName) -> Dictionary:
	return _data["fish_book"].get(String(fish_id), {}).duplicate(true)


# --- Stats ------------------------------------------------------------------

func increment_stat(stat_id: StringName, amount: int = 1) -> void:
	var key := String(stat_id)
	if not SaveSchema.INT_STAT_KEYS.has(key) or amount < 0:
		GameLog.error(&"STATE", "increment_stat rejected", {"stat": stat_id, "amount": amount})
		return
	if amount == 0:
		return
	_data["stats"][key] = int(_data["stats"][key]) + amount
	stats_changed.emit()


func add_play_time(seconds: float) -> void:
	if seconds <= 0.0:
		return
	_data["stats"]["play_time_sec"] = float(_data["stats"]["play_time_sec"]) + seconds


func get_stat(stat_id: StringName) -> Variant:
	return _data["stats"].get(String(stat_id))


# --- Story and tutorials ----------------------------------------------------

func get_story_value(key: StringName) -> Variant:
	return _data["story"].get(String(key))


func set_story_value(key: StringName, value: Variant) -> void:
	var id := String(key)
	var story: Dictionary = _data["story"]
	if not story.has(id) or typeof(story[id]) != typeof(value):
		GameLog.error(&"STATE", "set_story_value rejected", {"key": key, "value": value})
		return
	if typeof(value) == TYPE_ARRAY:
		GameLog.error(&"STATE", "use set_story_events for event lists", {"key": key})
		return
	if story[id] == value:
		return
	story[id] = value
	story_state_changed.emit()


## `key` is &"seen_events" or &"pending_events".
func get_story_events(key: StringName) -> Array[StringName]:
	var events: Array[StringName] = []
	for event_id: Variant in _data["story"].get(String(key), []):
		events.append(StringName(event_id))
	return events


func set_story_events(key: StringName, events: Array[StringName]) -> void:
	var id := String(key)
	if id != "seen_events" and id != "pending_events":
		GameLog.error(&"STATE", "set_story_events rejected", {"key": key})
		return
	var serialized: Array = []
	for event_id: StringName in events:
		if ContentIds.STORY_EVENT_IDS.has(event_id) and not serialized.has(String(event_id)):
			serialized.append(String(event_id))
	_data["story"][id] = serialized
	story_state_changed.emit()


func is_tutorial_seen(tutorial_id: StringName) -> bool:
	return bool(_data["tutorials"].get(String(tutorial_id), false))


func set_tutorial_seen(tutorial_id: StringName, seen: bool = true) -> void:
	var id := String(tutorial_id)
	if not _data["tutorials"].has(id):
		GameLog.error(&"STATE", "unknown tutorial flag", {"tutorial": tutorial_id})
		return
	_data["tutorials"][id] = seen


# --- Settings ---------------------------------------------------------------

func get_setting(key: StringName) -> Variant:
	return _data["settings"].get(String(key))


## Stores a setting after normalizing it. Returns false for an unknown key.
func set_setting(key: StringName, value: Variant) -> bool:
	var id := String(key)
	var normalized: Variant = SaveSchema.normalize_setting(id, value)
	if normalized == null:
		GameLog.error(&"STATE", "unknown setting", {"key": key})
		return false
	var settings: Dictionary = _data["settings"]
	if typeof(settings[id]) == typeof(normalized) and settings[id] == normalized:
		return true
	settings[id] = normalized
	settings_changed.emit(key)
	return true


# --- Debug mutations (debug builds only, routed through DebugService) -------

func debug_set_cash(value: int) -> void:
	if not OS.is_debug_build():
		return
	_data["cash"] = maxi(value, 0)
	cash_changed.emit(get_cash())


func debug_set_debt_remaining(value: int) -> void:
	if not OS.is_debug_build():
		return
	var debt: Dictionary = _data["debt"]
	debt["remaining"] = clampi(value, 0, get_debt_original())
	debt["paid"] = get_debt_original() - int(debt["remaining"])
	_data["stats"]["lifetime_debt_paid"] = int(debt["paid"])
	debt_changed.emit(get_debt_paid(), get_debt_remaining())
	stats_changed.emit()


func debug_set_upgrade_level(upgrade_id: StringName, level: int) -> void:
	if not OS.is_debug_build() or not ContentIds.UPGRADE_IDS.has(upgrade_id):
		return
	_data["upgrades"][String(upgrade_id)] = clampi(level, 0, ContentIds.UPGRADE_MAX_LEVEL)
	upgrade_changed.emit(upgrade_id, get_upgrade_level(upgrade_id))


# --- Internals --------------------------------------------------------------

func _next_upgrade_price(upgrade_id: StringName) -> int:
	if not ContentIds.UPGRADE_IDS.has(upgrade_id):
		return -1
	var upgrade := GameData.get_upgrade(upgrade_id)
	if upgrade == null:
		return -1
	return upgrade.get_price_for_level(get_upgrade_level(upgrade_id))


func _fish_entry(fish_id: StringName) -> Dictionary:
	if not ContentIds.FISH_IDS.has(fish_id):
		GameLog.error(&"STATE", "unknown fish", {"fish": fish_id})
		return {}
	return _data["fish_book"][String(fish_id)]


func _bind_rng() -> void:
	var rng: Dictionary = _data["rng"]
	RNGService.initialize_session(int(rng["save_seed"]))
	RNGService.restore_counters(int(rng["encounter_counter"]), int(rng["duel_counter"]))


func _emit_all() -> void:
	state_replaced.emit()
	cash_changed.emit(get_cash())
	debt_changed.emit(get_debt_paid(), get_debt_remaining())
	bucket_changed.emit(get_bucket_total_count())
	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		upgrade_changed.emit(upgrade_id, get_upgrade_level(upgrade_id))
	stats_changed.emit()
	story_state_changed.emit()
