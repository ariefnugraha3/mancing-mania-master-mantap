class_name DataValidator
extends RefCounted
## Pure validation rules for the data resources (GDD 170, QA BOOT-002..004).
## Every function returns human-readable errors; an empty result means valid.
## The sets are passed in so tests can feed deliberately broken data.

const PROBABILITY_TOLERANCE := 0.0001


static func validate_fish_set(fish: Array, require_models: bool = false, require_portraits: bool = false) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	var chance_total := 0.0

	for entry: Variant in fish:
		var data := entry as FishData
		if data == null:
			errors.append("fish: entry is not a FishData resource")
			continue
		var tag := "fish '%s'" % data.id
		if data.id == &"":
			errors.append("fish: empty id")
		elif seen.has(data.id):
			errors.append("%s: duplicate id" % tag)
		elif not ContentIds.FISH_IDS.has(data.id):
			errors.append("%s: id is not part of the v1.0 fish roster" % tag)
		seen[data.id] = true

		if data.display_name.strip_edges().is_empty():
			errors.append("%s: display_name is empty" % tag)
		if data.species_label.strip_edges().is_empty():
			errors.append("%s: species_label is empty" % tag)
		if data.tier < 1 or data.tier > 5:
			errors.append("%s: tier %d is outside 1-5" % [tag, data.tier])
		if data.sale_base < 0:
			errors.append("%s: sale_base is negative" % tag)
		if data.sale_multiplier <= 0.0:
			errors.append("%s: sale_multiplier must be > 0" % tag)
		if data.conditional_chance <= 0.0 or data.conditional_chance > 1.0:
			errors.append("%s: conditional_chance must be in (0, 1]" % tag)
		if data.strike_window_sec <= 0.0:
			errors.append("%s: strike_window_sec must be > 0" % tag)
		if data.reel_half_width <= 0.0 or data.reel_half_width > 0.245:
			errors.append("%s: reel_half_width must be in (0, 0.245]" % tag)
		if data.reel_move_speed <= 0.0:
			errors.append("%s: reel_move_speed must be > 0" % tag)
		if data.line_stress_per_sec <= 0.0:
			errors.append("%s: line_stress_per_sec must be > 0" % tag)
		if data.boxing_hp <= 0.0:
			errors.append("%s: boxing_hp must be > 0" % tag)
		if data.boxing_attack <= 0.0:
			errors.append("%s: boxing_attack must be > 0" % tag)
		if data.boxing_telegraph_sec <= 0.0:
			errors.append("%s: boxing_telegraph_sec must be > 0" % tag)
		if data.arm_strength < 0.0 or data.arm_strength > 100.0:
			errors.append("%s: arm_strength must be 0-100" % tag)
		if data.rhythm_skill < 0.0 or data.rhythm_skill > 100.0:
			errors.append("%s: rhythm_skill must be 0-100" % tag)
		if data.tell_truth_probability < 0.0 or data.tell_truth_probability > 1.0:
			errors.append("%s: tell_truth_probability must be 0-1" % tag)
		if data.weight_min_kg <= 0.0:
			errors.append("%s: weight_min_kg must be > 0" % tag)
		if data.weight_max_kg <= data.weight_min_kg:
			errors.append("%s: weight_max_kg must be greater than weight_min_kg" % tag)
		if data.dialogue_sequence_id == &"":
			errors.append("%s: dialogue_sequence_id is empty" % tag)
		if require_models and data.model_scene == null:
			errors.append("%s: model_scene is missing" % tag)
		if require_portraits and data.portrait_texture == null:
			errors.append("%s: portrait_texture is missing" % tag)
		chance_total += data.conditional_chance

	for fish_id: StringName in ContentIds.FISH_IDS:
		if not seen.has(fish_id):
			errors.append("fish: missing FishData for '%s'" % fish_id)
	if not fish.is_empty() and absf(chance_total - 1.0) > PROBABILITY_TOLERANCE:
		errors.append("fish: conditional chances sum to %.4f instead of 1.0" % chance_total)
	return errors


static func validate_trash_set(trash: Array, require_models: bool = false) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	var chance_total := 0.0

	for entry: Variant in trash:
		var data := entry as TrashData
		if data == null:
			errors.append("trash: entry is not a TrashData resource")
			continue
		var tag := "trash '%s'" % data.id
		if data.id == &"":
			errors.append("trash: empty id")
		elif seen.has(data.id):
			errors.append("%s: duplicate id" % tag)
		elif not ContentIds.TRASH_IDS.has(data.id):
			errors.append("%s: id is not part of the v1.0 trash list" % tag)
		seen[data.id] = true

		if data.display_name.strip_edges().is_empty():
			errors.append("%s: display_name is empty" % tag)
		if data.chance <= 0.0 or data.chance > 1.0:
			errors.append("%s: chance must be in (0, 1]" % tag)
		if data.sale_value <= 0:
			errors.append("%s: sale_value must be > 0" % tag)
		if require_models and data.model_scene == null:
			errors.append("%s: model_scene is missing" % tag)
		chance_total += data.chance

	for trash_id: StringName in ContentIds.TRASH_IDS:
		if not seen.has(trash_id):
			errors.append("trash: missing TrashData for '%s'" % trash_id)
	if not trash.is_empty() and absf(chance_total - 1.0) > PROBABILITY_TOLERANCE:
		errors.append("trash: chances sum to %.4f instead of 1.0" % chance_total)
	return errors


## `check_config_link` also verifies `effect_per_level` against the balance
## config named by `stat_key`; tests switch it off when feeding synthetic data.
static func validate_upgrade_set(upgrades: Array, check_config_link: bool = true) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}

	for entry: Variant in upgrades:
		var data := entry as UpgradeData
		if data == null:
			errors.append("upgrade: entry is not an UpgradeData resource")
			continue
		var tag := "upgrade '%s'" % data.id
		if data.id == &"":
			errors.append("upgrade: empty id")
		elif seen.has(data.id):
			errors.append("%s: duplicate id" % tag)
		elif not ContentIds.UPGRADE_IDS.has(data.id):
			errors.append("%s: id is not part of the v1.0 upgrade list" % tag)
		seen[data.id] = true

		if data.name.strip_edges().is_empty():
			errors.append("%s: name is empty" % tag)
		if data.max_level != ContentIds.UPGRADE_MAX_LEVEL:
			errors.append("%s: max_level must be %d" % [tag, ContentIds.UPGRADE_MAX_LEVEL])
		if data.prices.size() != ContentIds.UPGRADE_MAX_LEVEL:
			errors.append("%s: prices must contain exactly %d entries, found %d" % [
				tag, ContentIds.UPGRADE_MAX_LEVEL, data.prices.size()])
		for index: int in data.prices.size():
			if data.prices[index] <= 0:
				errors.append("%s: prices[%d] must be > 0" % [tag, index])
			elif index > 0 and data.prices[index] <= data.prices[index - 1]:
				errors.append("%s: prices must increase with level" % tag)
		if data.stat_key == &"":
			errors.append("%s: stat_key is empty" % tag)
		if data.effect_per_level <= 0.0:
			errors.append("%s: effect_per_level must be > 0" % tag)
		if data.effect_unit.strip_edges().is_empty():
			errors.append("%s: effect_unit is empty" % tag)
		if data.description.strip_edges().is_empty():
			errors.append("%s: description is empty" % tag)
		if check_config_link and data.stat_key != &"":
			var config_effect := GameData.get_config_effect(data.stat_key)
			if is_nan(config_effect):
				errors.append("%s: stat_key '%s' does not exist in any balance config" % [tag, data.stat_key])
			elif not is_equal_approx(config_effect, data.effect_per_level):
				errors.append("%s: effect_per_level %s does not match balance config value %s" % [
					tag, data.effect_per_level, config_effect])

	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		if not seen.has(upgrade_id):
			errors.append("upgrade: missing UpgradeData for '%s'" % upgrade_id)
	return errors


static func validate_balance(
	fishing: FishingBalance,
	boxing: BoxingConfig,
	arm: ArmWrestleConfig,
	dance: DanceConfig,
	suwit: SuwitConfig,
) -> PackedStringArray:
	var errors := PackedStringArray()

	if fishing == null:
		errors.append("balance: fishing_balance.tres is missing")
	else:
		if fishing.trash_probability < 0.0 or fishing.trash_probability > 1.0:
			errors.append("fishing: trash_probability must be 0-1")
		if fishing.big_one_probability < 0.0 or fishing.big_one_probability > 1.0:
			errors.append("fishing: big_one_probability must be 0-1")
		if fishing.base_wait_min_sec <= 0.0 or fishing.base_wait_max_sec < fishing.base_wait_min_sec:
			errors.append("fishing: base wait range is invalid")
		if fishing.wait_min_final_sec <= 0.0:
			errors.append("fishing: wait_min_final_sec must be > 0")
		if fishing.false_nibble_min < 0 or fishing.false_nibble_max < fishing.false_nibble_min:
			errors.append("fishing: false nibble range is invalid")
		if fishing.marker_hold_velocity <= 0.0 or fishing.marker_release_velocity >= 0.0:
			errors.append("fishing: marker velocities must be up when held and down when released")
		if fishing.stress_break_value <= 0.0:
			errors.append("fishing: stress_break_value must be > 0")
		if fishing.rod_half_width_max <= 0.0 or fishing.rod_half_width_max > 0.5:
			errors.append("fishing: rod_half_width_max is out of range")
		if fishing.bait_wait_reduction_per_level * ContentIds.UPGRADE_MAX_LEVEL >= 1.0:
			errors.append("fishing: bait reduction would remove waiting entirely")

	if boxing == null:
		errors.append("balance: boxing_config.tres is missing")
	else:
		if boxing.player_base_hp <= 0.0 or boxing.round_time_sec <= 0.0:
			errors.append("boxing: base HP and round time must be > 0")
		if boxing.normal_attack_cd_max < boxing.normal_attack_cd_min:
			errors.append("boxing: normal attack cooldown range is invalid")
		if boxing.boss_attack_cd_max < boxing.boss_attack_cd_min:
			errors.append("boxing: boss attack cooldown range is invalid")
		if boxing.blocked_damage_multiplier < 0.0 or boxing.blocked_damage_multiplier > 1.0:
			errors.append("boxing: blocked_damage_multiplier must be 0-1")

	if arm == null:
		errors.append("balance: arm_wrestle_config.tres is missing")
	else:
		if arm.position_min >= arm.position_max:
			errors.append("arm: position range is invalid")
		if arm.round_time_sec <= 0.0 or arm.base_stamina <= 0.0:
			errors.append("arm: round time and base stamina must be > 0")
		if arm.max_press_rate_per_sec <= 0.0:
			errors.append("arm: max_press_rate_per_sec must be > 0")

	if dance == null:
		errors.append("balance: dance_config.tres is missing")
	else:
		if dance.bpm_min <= 0 or dance.bpm_max < dance.bpm_min:
			errors.append("dance: BPM range is invalid")
		if dance.duration_max_sec < dance.duration_min_sec:
			errors.append("dance: duration range is invalid")
		if not (dance.perfect_window_ms < dance.great_window_ms and dance.great_window_ms < dance.good_window_ms):
			errors.append("dance: judgment windows must widen from PERFECT to GOOD")
		if dance.coffee_visual_slow_per_level * ContentIds.UPGRADE_MAX_LEVEL >= 1.0:
			errors.append("dance: coffee slow-down would stop the notes")

	if suwit == null:
		errors.append("balance: suwit_config.tres is missing")
	else:
		if suwit.wins_required <= 0:
			errors.append("suwit: wins_required must be > 0")
		if suwit.tell_time_from_start_sec >= suwit.countdown_sec:
			errors.append("suwit: the tell must appear before the countdown ends")
	return errors
