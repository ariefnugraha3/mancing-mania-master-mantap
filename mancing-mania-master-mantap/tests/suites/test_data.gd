extends "res://tests/test_suite.gd"
## BOOT-001..004 and the authoritative data tables (GDD 28-40, 75-77, 170).
## These tests lock the numbers: a balance value can only change together with
## the GDD and docs/balance_changes.md.

const BootController := preload("res://scripts/ui/boot_controller.gd")

## id: [tier, sale_base, multiplier, chance, strike, half_width, move_speed,
##      stress, hp, attack, telegraph, arm, rhythm, truth]
const FISH_TABLE: Dictionary = {
	&"catfish_bruiser": [1, 18000, 1.0, 0.30, 0.79, 0.175, 0.36, 32.0, 70.0, 12.0, 0.82, 42.0, 62.0, 0.78],
	&"tilapia_gym_rat": [2, 26000, 1.0, 0.24, 0.74, 0.165, 0.42, 35.0, 90.0, 14.0, 0.75, 50.0, 68.0, 0.72],
	&"gourami_shady": [2, 34000, 1.0, 0.20, 0.70, 0.155, 0.48, 39.0, 105.0, 16.0, 0.69, 56.0, 72.0, 0.46],
	&"carp_golden": [3, 52000, 1.0, 0.14, 0.65, 0.140, 0.54, 43.0, 120.0, 18.0, 0.63, 62.0, 78.0, 0.61],
	&"snakehead_sergeant": [4, 78000, 1.0, 0.09, 0.60, 0.125, 0.63, 48.0, 145.0, 22.0, 0.57, 72.0, 84.0, 0.52],
	&"arowana_don": [5, 240000, 1.25, 0.03, 0.55, 0.110, 0.72, 54.0, 190.0, 26.0, 0.51, 84.0, 90.0, 0.34],
}

## Chance of each result per successful encounter (GDD Section 29).
const EFFECTIVE_CHANCE: Dictionary = {
	&"catfish_bruiser": 0.2520,
	&"tilapia_gym_rat": 0.2016,
	&"gourami_shady": 0.1680,
	&"carp_golden": 0.1176,
	&"snakehead_sergeant": 0.0756,
	&"arowana_don": 0.0252,
}

const UPGRADE_PRICES: Dictionary = {
	&"bait": [12000, 30000, 68000],
	&"rod": [18000, 44000, 96000],
	&"tonic": [15000, 38000, 82000],
	&"coffee": [14000, 34000, 74000],
	&"charm": [20000, 50000, 110000],
}


func get_suite_name() -> String:
	return "data"


func test_boot_validation_passes_with_shipped_data() -> bool:
	check_empty(GameData.validate_all(), "GameData.validate_all")
	check_empty(BootController.collect_validation_errors(), "boot validation")
	return true


func test_content_manifest_counts() -> bool:
	check_eq(ContentIds.FISH_IDS.size(), 6, "fish roster size")
	check_eq(ContentIds.TRASH_IDS.size(), 3, "trash list size")
	check_eq(ContentIds.UPGRADE_IDS.size(), 5, "upgrade families")
	check_eq(ContentIds.DUEL_IDS.size(), 4, "duel modes")
	check_eq(ContentIds.STORY_EVENT_IDS.size(), 13, "narrative events")
	check_eq(GameData.get_all_fish().size(), 6, "fish resources")
	check_eq(GameData.get_all_trash().size(), 3, "trash resources")
	check_eq(GameData.get_all_upgrades().size(), 5, "upgrade resources")
	return true


func test_fish_master_stats_match_gdd() -> bool:
	for fish_id: StringName in FISH_TABLE:
		var row: Array = FISH_TABLE[fish_id]
		var fish := GameData.get_fish(fish_id)
		if not check(fish != null, "%s resource exists" % fish_id):
			continue
		check_eq(fish.id, fish_id, "%s id" % fish_id)
		check_eq(fish.tier, row[0], "%s tier" % fish_id)
		check_eq(fish.sale_base, row[1], "%s sale_base" % fish_id)
		check_eq(fish.sale_multiplier, row[2], "%s sale_multiplier" % fish_id)
		check_eq(fish.conditional_chance, row[3], "%s conditional_chance" % fish_id)
		check_eq(fish.strike_window_sec, row[4], "%s strike_window_sec" % fish_id)
		check_eq(fish.reel_half_width, row[5], "%s reel_half_width" % fish_id)
		check_eq(fish.reel_move_speed, row[6], "%s reel_move_speed" % fish_id)
		check_eq(fish.line_stress_per_sec, row[7], "%s line_stress_per_sec" % fish_id)
		check_eq(fish.boxing_hp, row[8], "%s boxing_hp" % fish_id)
		check_eq(fish.boxing_attack, row[9], "%s boxing_attack" % fish_id)
		check_eq(fish.boxing_telegraph_sec, row[10], "%s boxing_telegraph_sec" % fish_id)
		check_eq(fish.arm_strength, row[11], "%s arm_strength" % fish_id)
		check_eq(fish.rhythm_skill, row[12], "%s rhythm_skill" % fish_id)
		check_eq(fish.tell_truth_probability, row[13], "%s tell_truth_probability" % fish_id)
	return true


func test_sale_values_and_boss_premium() -> bool:
	check_eq(GameData.get_item_sale_value(&"catfish_bruiser"), 18000, "catfish value")
	check_eq(GameData.get_item_sale_value(&"tilapia_gym_rat"), 26000, "tilapia value")
	check_eq(GameData.get_item_sale_value(&"gourami_shady"), 34000, "gourami value")
	check_eq(GameData.get_item_sale_value(&"carp_golden"), 52000, "carp value")
	check_eq(GameData.get_item_sale_value(&"snakehead_sergeant"), 78000, "snakehead value")
	# Rp 240,000 x BOSS 1.25 = Rp 300,000 (GDD Section 40).
	check_eq(GameData.get_item_sale_value(&"arowana_don"), 300000, "arowana effective value")
	check(GameData.get_fish(&"arowana_don").has_sale_multiplier(), "arowana shows a multiplier")
	check_eq(GameData.get_item_sale_value(&"trash_sandal"), 500, "sandal value")
	check_eq(GameData.get_item_sale_value(&"trash_can"), 300, "can value")
	check_eq(GameData.get_item_sale_value(&"trash_tyre"), 1000, "tyre value")
	check_eq(GameData.get_item_sale_value(&"not_an_item"), 0, "unknown item value")
	return true


func test_encounter_probabilities_match_gdd() -> bool:
	var balance := GameData.get_fishing_balance()
	check_eq(balance.trash_probability, 0.16, "trash probability")
	var total := balance.trash_probability
	for fish_id: StringName in EFFECTIVE_CHANCE:
		var effective := (1.0 - balance.trash_probability) * GameData.get_fish(fish_id).conditional_chance
		check_near(effective, EFFECTIVE_CHANCE[fish_id], 0.00001, "%s effective chance" % fish_id)
		total += effective
	check_near(total, 1.0, 0.00001, "all encounter results sum to 100%")

	check_eq(GameData.get_trash(&"trash_sandal").chance, 0.45, "sandal chance")
	check_eq(GameData.get_trash(&"trash_can").chance, 0.40, "can chance")
	check_eq(GameData.get_trash(&"trash_tyre").chance, 0.15, "tyre chance")
	return true


func test_upgrade_prices_and_total_cost() -> bool:
	var grand_total := 0
	var steps := 0
	for upgrade_id: StringName in UPGRADE_PRICES:
		var upgrade := GameData.get_upgrade(upgrade_id)
		if not check(upgrade != null, "%s resource exists" % upgrade_id):
			continue
		var expected: Array = UPGRADE_PRICES[upgrade_id]
		check_eq(upgrade.max_level, 3, "%s max level" % upgrade_id)
		for level: int in 3:
			check_eq(upgrade.get_price_for_level(level), expected[level], "%s price Lv%d" % [upgrade_id, level + 1])
		check_eq(upgrade.get_price_for_level(3), -1, "%s has no Lv4" % upgrade_id)
		grand_total += upgrade.get_total_cost()
		steps += upgrade.prices.size()
	check_eq(GameData.get_upgrade(&"bait").get_total_cost(), 110000, "bait total")
	check_eq(GameData.get_upgrade(&"rod").get_total_cost(), 158000, "rod total")
	check_eq(GameData.get_upgrade(&"tonic").get_total_cost(), 135000, "tonic total")
	check_eq(GameData.get_upgrade(&"coffee").get_total_cost(), 122000, "coffee total")
	check_eq(GameData.get_upgrade(&"charm").get_total_cost(), 180000, "charm total")
	check_eq(grand_total, 705000, "total upgrade cost (GDD Section 77)")
	check_eq(steps, 15, "purchasable upgrade steps")
	return true


func test_balance_configs_match_gdd() -> bool:
	var fishing := GameData.get_fishing_balance()
	check_eq(fishing.base_wait_min_sec, 4.5, "wait min")
	check_eq(fishing.base_wait_max_sec, 9.5, "wait max")
	check_eq(fishing.wait_min_final_sec, 1.75, "wait floor")
	check_eq(fishing.bait_wait_reduction_per_level, 0.18, "bait reduction")
	check_eq(fishing.false_nibble_max, 2, "false nibble max")
	check_eq(fishing.false_strike_delay_sec, 0.8, "false strike delay")
	check_eq(fishing.marker_hold_velocity, 0.72, "marker hold velocity")
	check_eq(fishing.marker_release_velocity, -0.58, "marker release velocity")
	check_eq(fishing.input_ease_sec, 0.12, "input ease")
	check_eq(fishing.landing_gain_per_sec, 18.0, "landing gain")
	check_eq(fishing.landing_loss_outside_per_sec, 3.0, "landing loss")
	check_eq(fishing.stress_recover_inside_per_sec, 30.0, "stress recover inside")
	check_eq(fishing.stress_recover_release_per_sec, 16.0, "stress recover release")
	check_eq(fishing.stress_break_value, 100.0, "stress break")
	check_eq(fishing.rod_half_width_per_level, 0.035, "rod width per level")
	check_eq(fishing.rod_half_width_max, 0.245, "rod width clamp")
	check_eq(fishing.big_one_probability, 0.05, "BIG ONE chance")

	var boxing := GameData.get_boxing_config()
	check_eq(boxing.player_base_hp, 100.0, "boxing base HP")
	check_eq(boxing.hp_per_tonic_level, 25.0, "tonic HP")
	check_eq(boxing.jab_damage, 11.0, "jab damage")
	check_eq(boxing.cross_damage, 18.0, "cross damage")
	check_eq(boxing.blocked_damage_multiplier, 0.40, "blocked multiplier")
	check_eq(boxing.perfect_dodge_window_sec, 0.18, "perfect dodge window")
	check_eq(boxing.perfect_counter_sec, 0.85, "perfect counter window")
	check_eq(boxing.perfect_damage_multiplier, 2.4, "perfect multiplier")
	check_eq(boxing.normal_counter_sec, 0.62, "normal counter window")
	check_eq(boxing.normal_damage_multiplier, 2.0, "normal multiplier")
	check_eq(boxing.round_time_sec, 60.0, "boxing round time")
	check_eq(boxing.boss_attack_cd_min, 0.95, "boss cooldown min")

	var arm := GameData.get_arm_wrestle_config()
	check_eq(arm.round_time_sec, 32.0, "arm round time")
	check_eq(arm.press_impulse, 4.8, "press impulse")
	check_eq(arm.press_stamina_cost, 7.0, "press stamina cost")
	check_eq(arm.max_press_rate_per_sec, 10.0, "press rate cap")
	check_eq(arm.regen_delay_sec, 0.35, "regen delay")
	check_eq(arm.regen_per_sec, 26.0, "regen rate")
	check_eq(arm.stamina_bonus_per_level, 0.20, "tonic stamina bonus")

	var dance := GameData.get_dance_config()
	check_eq(dance.bpm_min, 132, "bpm min")
	check_eq(dance.bpm_max, 156, "bpm max")
	check_eq(dance.perfect_window_ms, 55, "perfect window")
	check_eq(dance.great_window_ms, 100, "great window")
	check_eq(dance.good_window_ms, 175, "good window")
	check_eq(dance.perfect_score, 1000, "perfect score")
	check_eq(dance.combo_bonus_max, 0.50, "combo bonus cap")
	check_eq(dance.coffee_visual_slow_per_level, 0.12, "coffee slow-down")

	var suwit := GameData.get_suwit_config()
	check_eq(suwit.wins_required, 2, "suwit wins required")
	check_eq(suwit.countdown_sec, 3.0, "suwit countdown")
	check_eq(suwit.tell_time_from_start_sec, 1.1, "suwit tell time")
	check_eq(suwit.charm_reveal_sec, 0.8, "charm reveal")
	return true


# BOOT-002
func test_missing_fish_data_fails_validation() -> bool:
	var fish := GameData.get_all_fish()
	fish.pop_back()
	var errors := DataValidator.validate_fish_set(fish)
	check_contains(errors, "missing FishData for 'arowana_don'", "missing fish is reported")
	return true


# BOOT-003
func test_duplicate_fish_id_fails_validation() -> bool:
	var fish: Array = GameData.get_all_fish()
	var copy: FishData = GameData.get_fish(&"catfish_bruiser").duplicate()
	fish.append(copy)
	var errors := DataValidator.validate_fish_set(fish)
	check_contains(errors, "duplicate id", "duplicate id is reported")
	return true


# BOOT-004
func test_invalid_upgrade_prices_fail_validation() -> bool:
	var two_prices: Array[int] = [18000, 44000]
	var short_list: UpgradeData = GameData.get_upgrade(&"rod").duplicate()
	short_list.prices = two_prices
	var upgrades: Array = [short_list]
	check_contains(DataValidator.validate_upgrade_set(upgrades), "exactly 3 entries", "short price list")

	var bad_prices: Array[int] = [18000, -5, 96000]
	var negative: UpgradeData = GameData.get_upgrade(&"rod").duplicate()
	negative.prices = bad_prices
	upgrades = [negative]
	check_contains(DataValidator.validate_upgrade_set(upgrades), "must be > 0", "non-positive price")
	return true


func test_upgrade_effect_must_match_balance_config() -> bool:
	var drifted: UpgradeData = GameData.get_upgrade(&"bait").duplicate()
	drifted.effect_per_level = 0.25
	var upgrades: Array = [drifted]
	check_contains(DataValidator.validate_upgrade_set(upgrades), "does not match balance config", "drifted effect")
	return true


func test_out_of_range_fish_values_fail_validation() -> bool:
	var broken: FishData = GameData.get_fish(&"carp_golden").duplicate()
	broken.reel_half_width = 0.4
	broken.tier = 9
	broken.weight_max_kg = broken.weight_min_kg
	var fish: Array = [broken]
	var errors := DataValidator.validate_fish_set(fish)
	check_contains(errors, "reel_half_width", "half width range")
	check_contains(errors, "tier 9", "tier range")
	check_contains(errors, "weight_max_kg", "weight range")
	return true


func test_input_map_has_every_action_with_gdd_defaults() -> bool:
	var defaults: Dictionary = {
		&"fish_cast": KEY_SPACE, &"fish_reel": KEY_SPACE, &"open_market": KEY_E,
		&"open_bucket": KEY_B, &"pause": KEY_ESCAPE, &"box_dodge_left": KEY_A,
		&"box_dodge_right": KEY_D, &"box_jab": KEY_J, &"box_cross": KEY_K,
		&"arm_mash": KEY_SPACE, &"dance_lane_1": KEY_S, &"dance_lane_2": KEY_D,
		&"dance_lane_3": KEY_J, &"dance_lane_4": KEY_K, &"suwit_rock": KEY_1,
		&"suwit_scissors": KEY_2, &"suwit_paper": KEY_3, &"suwit_charm": KEY_C,
		&"ui_confirm": KEY_ENTER, &"ui_cancel": KEY_ESCAPE,
	}
	for action: StringName in defaults:
		if not check(InputMap.has_action(action), "action %s exists" % action):
			continue
		var found := false
		for event: InputEvent in InputManager.get_default_events(action):
			var key := event as InputEventKey
			if key != null and (key.physical_keycode == defaults[action] or key.keycode == defaults[action]):
				found = true
		check(found, "%s is bound to %s" % [action, OS.get_keycode_string(defaults[action])])

	for action: StringName in [&"fish_cast", &"fish_reel"]:
		var has_click := false
		for event: InputEvent in InputManager.get_default_events(action):
			var mouse := event as InputEventMouseButton
			if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT:
				has_click = true
		check(has_click, "%s also accepts left click" % action)
	check_eq(InputActions.REMAPPABLE.size(), 20, "remappable action count (GDD 189.15)")
	return true


func test_text_table_is_complete_and_clean() -> bool:
	var keys := TextDb.get_all_keys()
	check(keys.size() > 0, "text table loaded")
	for key: String in keys:
		var text := TextDb.t(StringName(key))
		check(not text.strip_edges().is_empty(), "text '%s' is not empty" % key)
		check(not text.contains("TODO") and not text.contains("FIXME"), "text '%s' has no placeholder marker" % key)
	check_eq(TextDb.t(&"definitely.missing.key"), "#definitely.missing.key#", "missing key is visible, not blank")
	check_eq(TextDb.tf(&"menu.version", {"version": "1.2.3"}), "v1.2.3", "formatted text")
	return true
