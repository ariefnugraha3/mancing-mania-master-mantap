extends "res://tests/test_suite.gd"
## GameState economy and progression API (GDD 22, 169.2) plus SAVE-012:
## no sequence of transactions may ever push cash or debt out of range.

const STORAGE_DIR := "user://test_tmp/game_state"


func get_suite_name() -> String:
	return "state"


func before_all() -> void:
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)


func after_all() -> void:
	GameState.set_setting(&"input_remap", {})
	GameState.clear_game()
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


func before_each() -> void:
	GameState.clear_game()
	for key: String in SaveSchema.default_settings():
		GameState.set_setting(StringName(key), SaveSchema.default_settings()[key])
	DebugService.clear_dev_dirty()
	GameState.new_game()


func test_new_game_starting_state() -> bool:
	check_eq(GameState.get_cash(), 10000, "starting cash")
	check_eq(GameState.get_debt_original(), 2_000_000, "debt original")
	check_eq(GameState.get_debt_paid(), 0, "debt paid")
	check_eq(GameState.get_debt_remaining(), 2_000_000, "debt remaining")
	check_eq(GameState.get_bucket_total_count(), 0, "bucket empty")
	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		check_eq(GameState.get_upgrade_level(upgrade_id), 0, "%s starts at Lv0" % upgrade_id)
	for fish_id: StringName in ContentIds.FISH_IDS:
		check(not GameState.is_fish_discovered(fish_id), "%s starts undiscovered" % fish_id)
	check(GameState.has_active_game(), "game is active")
	check_eq(GameState.get_story_value(&"chapter"), "prologue", "starting chapter")
	return true


func test_cash_can_never_go_negative() -> bool:
	GameState.add_cash(2000)
	check_eq(GameState.get_cash(), 12000, "cash after add")
	check(GameState.can_spend(12000), "can spend everything")
	check(not GameState.can_spend(12001), "cannot overspend")
	check(not GameState.spend_cash(12001), "overspend is refused")
	check_eq(GameState.get_cash(), 12000, "refused spend changes nothing")
	check(GameState.spend_cash(4000), "valid spend")
	check_eq(GameState.get_cash(), 8000, "cash after spend")
	check(not GameState.spend_cash(-50), "negative spend is refused")
	GameState.add_cash(-999)
	check_eq(GameState.get_cash(), 8000, "negative add is ignored")
	return true


func test_pay_debt_is_capped_by_cash_and_remaining() -> bool:
	check_eq(GameState.pay_debt(15000), 10000, "payment capped by cash")
	check_eq(GameState.get_cash(), 0, "cash spent")
	check_eq(GameState.get_debt_paid(), 10000, "paid after first payment")
	check_eq(GameState.get_debt_remaining(), 1_990_000, "remaining after first payment")
	check_eq(GameState.pay_debt(500), 0, "nothing to pay with")
	check_eq(GameState.pay_debt(-100), 0, "negative payment ignored")

	GameState.add_cash(5_000_000)
	check_eq(GameState.pay_debt(5_000_000), 1_990_000, "payment capped by remaining debt")
	check_eq(GameState.get_debt_remaining(), 0, "debt cleared")
	check_eq(GameState.get_debt_paid(), 2_000_000, "everything paid")
	check_eq(GameState.get_cash(), 5_000_000 - 1_990_000, "only the debt was charged")
	check_eq(GameState.get_stat(&"lifetime_debt_paid"), 2_000_000, "lifetime stat follows the ledger")
	check_eq(GameState.pay_debt(1000), 0, "no payment once the debt is zero")
	return true


# SAVE-012
func test_random_transactions_keep_invariants() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261111
	var original := GameState.get_debt_original()
	for step: int in 4000:
		match rng.randi_range(0, 4):
			0:
				GameState.add_cash(rng.randi_range(-5000, 400000))
			1:
				GameState.pay_debt(rng.randi_range(-1000, 900000))
			2:
				GameState.spend_cash(rng.randi_range(-1000, 300000))
			3:
				GameState.buy_next_upgrade(ContentIds.UPGRADE_IDS[rng.randi_range(0, 4)])
			4:
				GameState.add_bucket_item(ContentIds.FISH_IDS[rng.randi_range(0, 5)], rng.randi_range(1, 3))
		var ok := GameState.get_cash() >= 0
		ok = ok and GameState.get_debt_remaining() >= 0 and GameState.get_debt_remaining() <= original
		ok = ok and GameState.get_debt_paid() + GameState.get_debt_remaining() == original
		for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
			var level := GameState.get_upgrade_level(upgrade_id)
			ok = ok and level >= 0 and level <= 3
		if not check(ok, "invariants hold after step %d" % step):
			break
	return true


func test_bucket_items() -> bool:
	GameState.add_bucket_item(&"catfish_bruiser", 3)
	GameState.add_bucket_item(&"trash_can")
	check_eq(GameState.get_bucket_quantity(&"catfish_bruiser"), 3, "catfish quantity")
	check_eq(GameState.get_bucket_total_count(), 4, "bucket total")
	GameState.add_bucket_item(&"golden_whale", 2)
	GameState.add_bucket_item(&"carp_golden", 0)
	check_eq(GameState.get_bucket_total_count(), 4, "invalid adds are ignored")

	check(not GameState.remove_bucket_item(&"catfish_bruiser", 5), "cannot remove more than held")
	check(GameState.remove_bucket_item(&"catfish_bruiser", 2), "valid removal")
	check_eq(GameState.get_bucket_quantity(&"catfish_bruiser"), 1, "catfish after removal")

	GameState.add_bucket_item(&"arowana_don")
	var to_clear: Array[StringName] = [&"catfish_bruiser", &"arowana_don", &"carp_golden"]
	var removed := GameState.clear_bucket_items(to_clear)
	check_eq(removed.size(), 2, "only held items are reported")
	check_eq(removed.get(&"catfish_bruiser"), 1, "removed catfish")
	check_eq(removed.get(&"arowana_don"), 1, "removed arowana")
	check_eq(GameState.get_bucket_total_count(), 1, "the can stays")
	return true


func test_upgrade_purchases() -> bool:
	check(not GameState.can_buy_upgrade(&"rod"), "cannot afford the rod at start")
	check(not GameState.buy_next_upgrade(&"rod"), "purchase without cash is refused")
	check_eq(GameState.get_upgrade_level(&"rod"), 0, "level unchanged")

	GameState.add_cash(600000)
	var cash := GameState.get_cash()
	check(GameState.buy_next_upgrade(&"rod"), "buy rod Lv1 without debt milestone")
	check_eq(GameState.get_cash(), cash - 18000, "Lv1 price charged")
	check(GameState.is_upgrade_locked_by_debt(&"rod"), "Lv2 is locked behind Rp 100,000 debt milestone")
	check_eq(GameState.get_upgrade_debt_requirement(&"rod"), 100000, "Lv2 debt requirement is Rp 100,000")
	check(not GameState.can_buy_upgrade(&"rod"), "cannot buy Lv2 before paying Rp 100,000 debt")
	check(not GameState.buy_next_upgrade(&"rod"), "Lv2 purchase refused while debt-locked")

	GameState.pay_debt(100000)
	check(not GameState.is_upgrade_locked_by_debt(&"rod"), "paying Rp 100,000 debt unlocks Lv2")
	check(GameState.buy_next_upgrade(&"rod"), "buy rod Lv2")
	check(GameState.is_upgrade_locked_by_debt(&"rod"), "Lv3 is locked behind Rp 350,000 debt milestone")
	check_eq(GameState.get_upgrade_debt_requirement(&"rod"), 350000, "Lv3 debt requirement is Rp 350,000")
	check(not GameState.buy_next_upgrade(&"rod"), "Lv3 purchase refused while debt-locked")

	GameState.pay_debt(250000)
	check(not GameState.is_upgrade_locked_by_debt(&"rod"), "paying Rp 350,000 total debt unlocks Lv3")
	check(GameState.buy_next_upgrade(&"rod"), "buy rod Lv3")
	check_eq(GameState.get_cash(), cash - 350000 - 158000, "debt and all three rod prices charged")
	check_eq(GameState.get_upgrade_level(&"rod"), 3, "rod at max")
	check(not GameState.can_buy_upgrade(&"rod"), "nothing above max level")
	check(not GameState.buy_next_upgrade(&"rod"), "max level purchase is refused")
	check(not GameState.buy_next_upgrade(&"jetpack"), "unknown upgrade is refused")
	check_eq(GameState.get_cash(), cash - 350000 - 158000, "refused purchases cost nothing")
	return true


func test_debt_delinquency_tracking_and_relief() -> bool:
	check_eq(GameState.get_unpaid_sales(), 0, "starts with zero unpaid sales")
	check(not GameState.is_debt_overdue(), "not overdue at start")
	check(not GameState.is_debt_fee_active(), "fee inactive at start")

	check_eq(GameState.record_unpaid_sale(), 1, "first unpaid sale recorded")
	check(not GameState.is_debt_overdue(), "one unpaid sale is not overdue yet")
	check_eq(GameState.record_unpaid_sale(), 2, "second unpaid sale triggers collector")
	check(GameState.is_debt_overdue(), "overdue after two unpaid sales")
	check(not GameState.is_debt_fee_active(), "fee starts on third unpaid sale")
	check_eq(GameState.record_unpaid_sale(), 3, "third unpaid sale activates fee")
	check(GameState.is_debt_fee_active(), "fee active at three unpaid sales")

	GameState.add_cash(20000)
	check_eq(GameState.pay_debt(5000), 5000, "small payment accepted")
	check(GameState.is_debt_overdue(), "payment under Rp 10,000 does not clear overdue")
	check_eq(GameState.pay_debt(10000), 10000, "relief payment accepted")
	check_eq(GameState.get_unpaid_sales(), 0, "Rp 10,000 payment resets unpaid sales")
	check(not GameState.is_debt_overdue(), "overdue cleared after relief payment")

	GameState.debug_set_debt_remaining(0)
	check_eq(GameState.record_unpaid_sale(), 0, "sales after debt is cleared never increment unpaid_sales")
	check(not GameState.is_debt_overdue(), "cleared debt is never overdue")
	return true


func test_fish_book_records() -> bool:
	GameState.record_encounter(&"catfish_bruiser")
	GameState.record_encounter(&"catfish_bruiser")
	check(not GameState.is_fish_discovered(&"catfish_bruiser"), "an encounter alone does not discover")

	GameState.record_fish_win(&"catfish_bruiser", 2.4, &"suwit")
	GameState.record_fish_win(&"catfish_bruiser", 1.9, &"dance")
	var entry := GameState.get_fish_book_entry(&"catfish_bruiser")
	check(GameState.is_fish_discovered(&"catfish_bruiser"), "a win discovers the fish")
	check_eq(entry["encounters"], 2, "encounters")
	check_eq(entry["wins"], 2, "wins")
	check_eq(entry["best_weight_kg"], 2.4, "best weight keeps the maximum")
	# One win each: the tie resolves in boxing, arm_wrestle, dance, suwit order.
	check_eq(entry["favourite_duel"], "dance", "favourite duel tiebreak")

	GameState.record_fish_win(&"catfish_bruiser", 2.0, &"suwit")
	check_eq(GameState.get_fish_book_entry(&"catfish_bruiser")["favourite_duel"], "suwit", "favourite follows most wins")

	GameState.record_fish_loss(&"catfish_bruiser")
	check_eq(GameState.get_fish_book_entry(&"catfish_bruiser")["losses"], 1, "losses")

	GameState.record_fish_win(&"arowana_don", 7.1, &"boxing")
	check_eq(GameState.get_stat(&"largest_fish_id"), "arowana_don", "largest fish id")
	check_eq(GameState.get_stat(&"largest_fish_weight_kg"), 7.1, "largest fish weight")

	GameState.record_fish_win(&"sea_monster", 99.0, &"boxing")
	GameState.record_fish_win(&"carp_golden", 3.0, &"karaoke")
	check_eq(GameState.get_stat(&"largest_fish_id"), "arowana_don", "invalid records are ignored")
	check(not GameState.is_fish_discovered(&"carp_golden"), "unknown duel does not record a win")
	check(GameState.get_fish_book_entry(&"sea_monster").is_empty(), "unknown fish has no entry")
	return true


func test_stats() -> bool:
	GameState.increment_stat(&"total_casts")
	GameState.increment_stat(&"total_casts", 4)
	check_eq(GameState.get_stat(&"total_casts"), 5, "counter increments")
	GameState.increment_stat(&"largest_fish_id")
	GameState.increment_stat(&"made_up_stat")
	GameState.increment_stat(&"total_casts", -3)
	check_eq(GameState.get_stat(&"total_casts"), 5, "invalid increments are ignored")
	GameState.add_play_time(12.5)
	GameState.add_play_time(-4.0)
	check_eq(GameState.get_stat(&"play_time_sec"), 12.5, "play time accumulates")
	return true


func test_settings_are_normalized() -> bool:
	check(GameState.set_setting(&"music_volume", 0.4), "valid volume accepted")
	check_eq(GameState.get_setting(&"music_volume"), 0.4, "volume stored")
	GameState.set_setting(&"music_volume", 7.0)
	check_eq(GameState.get_setting(&"music_volume"), 1.0, "volume clamped high")
	GameState.set_setting(&"music_volume", -1.0)
	check_eq(GameState.get_setting(&"music_volume"), 0.0, "volume clamped low")

	GameState.set_setting(&"hud_shake", "reduced")
	check_eq(GameState.get_setting(&"hud_shake"), "reduced", "enum accepted")
	GameState.set_setting(&"hud_shake", "earthquake")
	check_eq(GameState.get_setting(&"hud_shake"), "on", "invalid enum falls back to the default")

	GameState.set_setting(&"ui_scale", 1.2)
	check_eq(GameState.get_setting(&"ui_scale"), 1.15, "ui scale snaps to an allowed step")
	GameState.set_setting(&"rhythm_input_offset_ms", 400)
	check_eq(GameState.get_setting(&"rhythm_input_offset_ms"), 150, "rhythm offset clamped")
	GameState.set_setting(&"skip_hold_sec", 1.1)
	check_eq(GameState.get_setting(&"skip_hold_sec"), 1.2, "skip hold snaps to an allowed step")
	check(not GameState.set_setting(&"unicorn_mode", true), "unknown setting is refused")
	return true


func test_settings_survive_a_new_game() -> bool:
	GameState.set_setting(&"sfx_volume", 0.3)
	GameState.set_setting(&"quality_preset", "high")
	GameState.add_cash(50000)
	GameState.new_game()
	check_eq(GameState.get_cash(), 10000, "progress was reset")
	check_eq(GameState.get_setting(&"sfx_volume"), 0.3, "volume kept")
	check_eq(GameState.get_setting(&"quality_preset"), "high", "quality kept")
	return true


func test_signals_report_new_values() -> bool:
	var seen := {"cash": -1, "paid": -1, "remaining": -1, "bucket": -1, "upgrade": ""}
	var on_cash := func(value: int) -> void: seen["cash"] = value
	var on_debt := func(paid: int, remaining: int) -> void:
		seen["paid"] = paid
		seen["remaining"] = remaining
	var on_bucket := func(total: int) -> void: seen["bucket"] = total
	var on_upgrade := func(upgrade_id: StringName, level: int) -> void: seen["upgrade"] = "%s:%d" % [upgrade_id, level]
	GameState.cash_changed.connect(on_cash)
	GameState.debt_changed.connect(on_debt)
	GameState.bucket_changed.connect(on_bucket)
	GameState.upgrade_changed.connect(on_upgrade)

	GameState.add_cash(90000)
	check_eq(seen["cash"], 100000, "cash_changed value")
	GameState.pay_debt(25000)
	check_eq(seen["paid"], 25000, "debt_changed paid")
	check_eq(seen["remaining"], 1_975_000, "debt_changed remaining")
	GameState.add_bucket_item(&"gourami_shady", 2)
	check_eq(seen["bucket"], 2, "bucket_changed total")
	GameState.buy_next_upgrade(&"bait")
	check_eq(seen["upgrade"], "bait:1", "upgrade_changed payload")

	GameState.cash_changed.disconnect(on_cash)
	GameState.debt_changed.disconnect(on_debt)
	GameState.bucket_changed.disconnect(on_bucket)
	GameState.upgrade_changed.disconnect(on_upgrade)
	return true


func test_export_matches_the_save_schema() -> bool:
	GameState.add_cash(50000)
	GameState.pay_debt(20000)
	GameState.record_fish_win(&"tilapia_gym_rat", 1.5, &"arm_wrestle")
	var exported := GameState.export_save_state()
	var normalized := SaveSchema.normalize(exported)
	check(not normalized.is_empty(), "exported state is a valid save")
	check_empty(SaveSchema.last_repairs, "exported state needs no repair")

	# The export is a copy: changing it must not reach the live state.
	exported["cash"] = 1
	exported["bucket"]["catfish_bruiser"] = 99
	check_eq(GameState.get_cash(), 10000 + 50000 - 20000, "export is detached (cash)")
	check_eq(GameState.get_bucket_quantity(&"catfish_bruiser"), 0, "export is detached (bucket)")
	return true


func test_story_and_tutorial_flags() -> bool:
	var events: Array[StringName] = [&"story_debt_100k", &"story_not_real", &"story_debt_100k"]
	GameState.set_story_events(&"pending_events", events)
	check_eq(GameState.get_story_events(&"pending_events").size(), 1, "only known, unique events are stored")
	GameState.set_story_value(&"fish_book_unlocked", true)
	check_eq(GameState.get_story_value(&"fish_book_unlocked"), true, "story flag stored")
	GameState.set_story_value(&"fish_book_unlocked", "yes")
	check_eq(GameState.get_story_value(&"fish_book_unlocked"), true, "wrong type is refused")
	GameState.set_story_value(&"secret_ending", true)
	check_eq(GameState.get_story_value(&"secret_ending"), null, "unknown story key is refused")

	check(not GameState.is_tutorial_seen(&"fishing_seen"), "tutorial starts unseen")
	GameState.set_tutorial_seen(&"fishing_seen")
	check(GameState.is_tutorial_seen(&"fishing_seen"), "tutorial marked seen")
	return true
