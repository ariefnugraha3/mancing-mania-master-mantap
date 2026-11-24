class_name UpgradeEffects
extends RefCounted
## What each upgrade level really does, in numbers and in words (GDD 76, 78).
##
## The numbers come from the same balance configs that gameplay reads, so the
## shop can never promise something different from what the player gets. The
## shop must show the current effect, the next effect, the exact price and the
## maximum level for every item (GDD Section 78).


## The effect of an upgrade at `level` as one line of player-facing text.
static func describe(upgrade_id: StringName, level: int) -> String:
	# The bucket always has a size, even before the first upgrade.
	if upgrade_id == &"bucket":
		return TextDb.tf(&"upgrade.effect.bucket", {"count": bucket_capacity(level)})
	if level <= 0:
		return TextDb.t(&"upgrade.effect.none")
	match upgrade_id:
		&"bait":
			return TextDb.tf(&"upgrade.effect.bait", {"percent": roundi(bait_wait_multiplier(level) * 100.0)})
		&"rod":
			return TextDb.tf(&"upgrade.effect.rod", {"width": Money.decimal(rod_half_width_bonus(level), 3)})
		&"tonic":
			return TextDb.tf(&"upgrade.effect.tonic", {
				"hp": roundi(tonic_max_hp(level)), "stamina": roundi(tonic_stamina_multiplier(level) * 100.0)})
		&"coffee":
			return TextDb.tf(&"upgrade.effect.coffee", {"percent": roundi(coffee_speed_multiplier(level) * 100.0)})
		&"charm":
			return TextDb.tf(&"upgrade.effect.charm", {"charges": charm_charges(level)})
	return ""


## How many catches the bucket holds with Big Bucket: 5 + 5 x level.
static func bucket_capacity(level: int) -> int:
	var balance := GameData.get_fishing_balance()
	return balance.bucket_base_capacity + roundi(balance.bucket_capacity_per_level * float(_clamp(level)))


## Wait time multiplier from Super Pellet Bait: 1 - 0.18 x level.
static func bait_wait_multiplier(level: int) -> float:
	return 1.0 - GameData.get_fishing_balance().bait_wait_reduction_per_level * float(_clamp(level))


## Extra green-zone half-width from the Carbon Fibre Rod: +0.035 x level.
static func rod_half_width_bonus(level: int) -> float:
	return GameData.get_fishing_balance().rod_half_width_per_level * float(_clamp(level))


## Boxing max HP with Herbal Tonic: 100 + 25 x level.
static func tonic_max_hp(level: int) -> float:
	var boxing := GameData.get_boxing_config()
	return boxing.player_base_hp + boxing.hp_per_tonic_level * float(_clamp(level))


## Arm wrestling max stamina with Herbal Tonic: 1 + 0.20 x level.
static func tonic_stamina_multiplier(level: int) -> float:
	return 1.0 + GameData.get_arm_wrestle_config().stamina_bonus_per_level * float(_clamp(level))


## Dance note travel speed with Black Coffee: 1 - 0.12 x level.
static func coffee_speed_multiplier(level: int) -> float:
	return 1.0 - GameData.get_dance_config().coffee_visual_slow_per_level * float(_clamp(level))


## Suwit reveal charges per duel with the Agate Charm Ring: 1 x level.
static func charm_charges(level: int) -> int:
	return GameData.get_suwit_config().charm_charge_per_level * _clamp(level)


static func _clamp(level: int) -> int:
	return clampi(level, 0, ContentIds.UPGRADE_MAX_LEVEL)
