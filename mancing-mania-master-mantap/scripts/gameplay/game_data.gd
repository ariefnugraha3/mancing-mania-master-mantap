class_name GameData
extends RefCounted
## Read-only registry for the authoritative data resources under res://data/.
## Content is addressed by the closed ID lists in ContentIds, never by scanning
## directories, so exported builds resolve exactly the same files.

const FISH_PATH := "res://data/fish/%s.tres"
const TRASH_PATH := "res://data/trash/%s.tres"
const UPGRADE_PATH := "res://data/upgrades/%s.tres"
const FISHING_BALANCE_PATH := "res://data/balance/fishing_balance.tres"
const BOXING_CONFIG_PATH := "res://data/balance/boxing_config.tres"
const ARM_WRESTLE_CONFIG_PATH := "res://data/balance/arm_wrestle_config.tres"
const DANCE_CONFIG_PATH := "res://data/balance/dance_config.tres"
const SUWIT_CONFIG_PATH := "res://data/balance/suwit_config.tres"

static var _cache: Dictionary[String, Resource] = {}


static func get_fish(fish_id: StringName) -> FishData:
	return _load(FISH_PATH % fish_id) as FishData


static func get_all_fish() -> Array[FishData]:
	var all: Array[FishData] = []
	for fish_id: StringName in ContentIds.FISH_IDS:
		var fish := get_fish(fish_id)
		if fish != null:
			all.append(fish)
	return all


static func get_trash(trash_id: StringName) -> TrashData:
	return _load(TRASH_PATH % trash_id) as TrashData


static func get_all_trash() -> Array[TrashData]:
	var all: Array[TrashData] = []
	for trash_id: StringName in ContentIds.TRASH_IDS:
		var trash := get_trash(trash_id)
		if trash != null:
			all.append(trash)
	return all


static func get_upgrade(upgrade_id: StringName) -> UpgradeData:
	return _load(UPGRADE_PATH % upgrade_id) as UpgradeData


static func get_all_upgrades() -> Array[UpgradeData]:
	var all: Array[UpgradeData] = []
	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		var upgrade := get_upgrade(upgrade_id)
		if upgrade != null:
			all.append(upgrade)
	return all


static func get_fishing_balance() -> FishingBalance:
	return _load(FISHING_BALANCE_PATH) as FishingBalance


static func get_boxing_config() -> BoxingConfig:
	return _load(BOXING_CONFIG_PATH) as BoxingConfig


static func get_arm_wrestle_config() -> ArmWrestleConfig:
	return _load(ARM_WRESTLE_CONFIG_PATH) as ArmWrestleConfig


static func get_dance_config() -> DanceConfig:
	return _load(DANCE_CONFIG_PATH) as DanceConfig


static func get_suwit_config() -> SuwitConfig:
	return _load(SUWIT_CONFIG_PATH) as SuwitConfig


static func is_fish(item_id: StringName) -> bool:
	return ContentIds.FISH_IDS.has(item_id)


static func is_trash(item_id: StringName) -> bool:
	return ContentIds.TRASH_IDS.has(item_id)


static func is_bucket_item(item_id: StringName) -> bool:
	return is_fish(item_id) or is_trash(item_id)


## Market value of one Bucket item, boss premium included. 0 for unknown IDs.
static func get_item_sale_value(item_id: StringName) -> int:
	if is_fish(item_id):
		var fish := get_fish(item_id)
		return fish.get_sale_value() if fish != null else 0
	if is_trash(item_id):
		var trash := get_trash(item_id)
		return trash.get_sale_value() if trash != null else 0
	return 0


static func get_item_display_name(item_id: StringName) -> String:
	if is_fish(item_id):
		var fish := get_fish(item_id)
		return fish.display_name if fish != null else ""
	if is_trash(item_id):
		var trash := get_trash(item_id)
		return trash.display_name if trash != null else ""
	return ""


## Per-level effect that gameplay really applies for an upgrade's `stat_key`,
## read from the owning balance config. Returns NAN for an unknown key.
static func get_config_effect(stat_key: StringName) -> float:
	var owners: Array[Resource] = [
		get_fishing_balance(),
		get_boxing_config(),
		get_arm_wrestle_config(),
		get_dance_config(),
		get_suwit_config(),
	]
	for config: Resource in owners:
		if config != null and stat_key in config:
			return float(config.get(stat_key))
	return NAN


## Full data validation used by Boot (debug/test builds) and by the tests.
## Generated models are required for every fish and trash item. Fish Book
## portraits are checked only when `require_portraits` is set, which the
## milestone that renders them turns on.
static func validate_all(require_portraits: bool = false) -> PackedStringArray:
	var errors := PackedStringArray()

	errors.append_array(DataValidator.validate_fish_set(get_all_fish(), true, require_portraits))
	errors.append_array(DataValidator.validate_trash_set(get_all_trash(), true))
	errors.append_array(DataValidator.validate_upgrade_set(get_all_upgrades()))
	errors.append_array(DataValidator.validate_balance(
		get_fishing_balance(),
		get_boxing_config(),
		get_arm_wrestle_config(),
		get_dance_config(),
		get_suwit_config(),
	))
	return errors


## Drops cached resources so the next access reloads them from disk.
static func clear_cache() -> void:
	_cache.clear()


static func _load(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		return null
	var resource := ResourceLoader.load(path)
	if resource != null:
		_cache[path] = resource
	return resource
