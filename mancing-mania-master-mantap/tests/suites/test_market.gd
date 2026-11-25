extends "res://tests/test_suite.gd"
## Market economy and the story trigger queue (GDD 72-80, 177; QA matrix
## MKT-001..011, STORY-001..007 and 011, BOOK-001..005).

const STORAGE_DIR := "user://test_tmp/market"
const ALL_DEBT_MILESTONES: Array[StringName] = [
	&"story_debt_100k", &"story_debt_300k", &"story_debt_600k",
	&"story_debt_1000k", &"story_debt_1400k", &"story_debt_1650k",
]

var _market: MarketController
var _events: Array[String] = []


func get_suite_name() -> String:
	return "market"


func before_all() -> void:
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)


func after_all() -> void:
	SaveManager.simulate_write_failure = false
	DebugService.clear_dev_dirty()
	GameState.clear_game()
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


func before_each() -> void:
	SaveManager.simulate_write_failure = false
	SaveManager.delete_save()
	DebugService.clear_dev_dirty()
	GameState.clear_game()
	GameState.new_game()
	_events.clear()
	_market = MarketController.new()
	_market.auto_route = false
	_market.transaction_lock_enabled = false
	_market.transaction_completed.connect(func(kind: StringName, _result: Dictionary) -> void: _events.append("done:%s" % kind))
	_market.save_failed.connect(func() -> void: _events.append("save_failed"))
	_market.market_left.connect(func(event_id: StringName) -> void: _events.append("left:%s" % event_id))


func after_each() -> void:
	_market.free()


func _saved() -> Dictionary:
	var parsed: Variant = read_json(SaveManager.get_save_path())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## Earns `amount` and pays it all toward the debt through the Market.
func _pay(amount: int) -> int:
	GameState.add_cash(amount)
	return _market.pay_debt(amount)


# --- Selling ----------------------------------------------------------------

# MKT-001, MKT-002, MKT-003
func test_sale_values_are_exact() -> bool:
	# Cempaka Lake's six fish and the trash (the spot fish follow below).
	for item_id: StringName in ContentIds.fish_of_location(ContentIds.START_LOCATION) + ContentIds.TRASH_IDS:
		GameState.add_bucket_item(item_id)
	var preview := _market.get_sell_preview()
	var expected: Dictionary = {
		&"catfish_bruiser": 18000, &"tilapia_gym_rat": 26000, &"gourami_shady": 34000,
		&"carp_golden": 52000, &"snakehead_sergeant": 78000, &"arowana_don": 300000,
		&"trash_sandal": 500, &"trash_can": 300, &"trash_tyre": 1000,
	}
	check_eq(preview["lines"].size(), 9, "one line per item")
	for line: Dictionary in preview["lines"]:
		check_eq(line["unit_value"], expected[line["item_id"]], "%s unit value" % line["item_id"])
		check_eq(line["subtotal"], expected[line["item_id"]], "%s subtotal" % line["item_id"])
		if line["item_id"] == &"arowana_don":
			# Rp 240,000 x BOSS 1.25 = Rp 300,000, shown without ambiguity.
			check_eq(line["base_value"], 240000, "arowana base value")
			check_eq(line["multiplier"], 1.25, "arowana boss premium")
	check_eq(preview["fish_total"], 508000, "fish total")
	check_eq(preview["trash_total"], 1800, "trash total")
	check_eq(preview["total"], 509800, "grand total")
	return true


# Revision 6.7: fish from every spot sell at Bu Yati's for their own price,
# legends with the 1.25 premium.
func test_spot_fish_sell_at_the_market() -> bool:
	var expected_total := 0
	for location_id: StringName in ContentIds.LOCATION_IDS:
		if location_id == ContentIds.START_LOCATION:
			continue
		for fish: FishData in GameData.get_location_fish(location_id):
			GameState.add_bucket_item(fish.id)
			expected_total += roundi(float(fish.sale_base) * fish.sale_multiplier)
	var preview := _market.get_sell_preview()
	check_eq(preview["lines"].size(), 20, "one line per spot fish")
	for line: Dictionary in preview["lines"]:
		var fish := GameData.get_fish(line["item_id"])
		check_eq(line["unit_value"], fish.get_sale_value(), "%s unit value" % fish.id)
		if fish.is_legend():
			check_eq(line["multiplier"], 1.25, "%s legend premium" % fish.id)
	check_eq(preview["fish_total"], expected_total, "spot fish total")
	var cash := GameState.get_cash()
	_market.sell_all()
	check_eq(GameState.get_cash(), cash + expected_total, "sold for exactly that")
	check_eq(GameState.get_bucket_total_count(), 0, "the bucket is empty")
	return true


func test_a_catch_is_not_cash_until_it_is_sold() -> bool:
	GameState.add_bucket_item(&"arowana_don", 2)
	check_eq(GameState.get_cash(), 10000, "a full bucket does not change cash")
	_market.get_sell_preview()
	_market.get_sell_preview()
	check_eq(GameState.get_cash(), 10000, "previewing a sale pays nothing")
	check_eq(GameState.get_bucket_quantity(&"arowana_don"), 2, "previewing removes nothing")
	check_eq(_events.size(), 0, "a preview is not a transaction")
	return true


## Selling is the only place in the game that turns a catch into cash. The one
## other way money comes in is the message bottle at the fishing spot
## (revision 6.12, GDD 25.1): a little money, now and then.
func test_only_the_market_adds_cash() -> bool:
	var callers := PackedStringArray()
	for root: String in ["res://autoload", "res://scripts"]:
		_find_calls(root, "GameState.add_cash(", callers)
	callers.sort()
	check_eq(callers, PackedStringArray([
		"res://scripts/gameplay/fishing/fishing_event_director.gd",
		"res://scripts/gameplay/market/market_controller.gd"]),
		"GameState.add_cash is called only by the MarketController and the message bottle")
	return true


func _find_calls(path: String, needle: String, found: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		if file_name.ends_with(".gd") and FileAccess.get_file_as_string(path.path_join(file_name)).contains(needle):
			found.append(path.path_join(file_name))
	for child: String in directory.get_directories():
		_find_calls(path.path_join(child), needle, found)


# MKT-004
func test_sell_all() -> bool:
	GameState.add_bucket_item(&"catfish_bruiser", 3)
	GameState.add_bucket_item(&"carp_golden", 1)
	GameState.add_bucket_item(&"trash_can", 2)
	GameState.add_bucket_item(&"trash_sandal", 1)
	var sale := _market.sell_all()
	check_eq(sale["total"], 107100, "3 catfish + 1 carp + 2 cans + 1 sandal")
	check_eq(sale["items_sold"], 7, "items sold")
	check_eq(sale["cash_before"], 10000, "cash before")
	check_eq(sale["cash_after"], 117100, "cash after")
	check_eq(GameState.get_cash(), 117100, "cash increased by the total")
	check_eq(GameState.get_bucket_total_count(), 0, "bucket is empty")
	check_eq(GameState.get_stat(&"lifetime_sales"), 107100, "lifetime sales")
	check_eq(_events, ["done:sell"], "one transaction reported")
	check_eq(_saved()["cash"], 117100, "sale was autosaved (cash)")
	check_eq(_saved()["bucket"]["catfish_bruiser"], 0, "sale was autosaved (bucket)")

	var again := _market.sell_all()
	check_eq(again["total"], 0, "selling an empty bucket pays nothing")
	check_eq(GameState.get_cash(), 117100, "cash unchanged")
	check_eq(_events.size(), 1, "an empty sale is not a transaction")
	return true


# MKT-005
func test_category_sell_removes_only_that_category() -> bool:
	GameState.add_bucket_item(&"gourami_shady", 2)
	GameState.add_bucket_item(&"trash_tyre", 3)
	var fish_sale := _market.sell_category(MarketController.CATEGORY_FISH)
	check_eq(fish_sale["total"], 68000, "fish sale total")
	check_eq(GameState.get_bucket_quantity(&"gourami_shady"), 0, "fish removed")
	check_eq(GameState.get_bucket_quantity(&"trash_tyre"), 3, "trash kept")
	check_eq(GameState.get_cash(), 78000, "cash after fish sale")

	var trash_sale := _market.sell_category(MarketController.CATEGORY_TRASH)
	check_eq(trash_sale["total"], 3000, "trash sale total")
	check_eq(GameState.get_bucket_total_count(), 0, "bucket empty after both")
	check_eq(GameState.get_cash(), 81000, "cash after trash sale")
	check_eq(_market.sell_category(&"antiques")["total"], 0, "unknown category sells nothing")
	return true


# --- Upgrades ---------------------------------------------------------------

# MKT-006
func test_upgrade_needs_enough_cash() -> bool:
	check(not _market.purchase_upgrade(&"rod"), "Rp 10,000 cannot buy an Rp 18,000 rod")
	check_eq(GameState.get_upgrade_level(&"rod"), 0, "level unchanged")
	check_eq(GameState.get_cash(), 10000, "cash unchanged")
	check_eq(_events.size(), 0, "a blocked purchase is not a transaction")
	check(not _market.purchase_upgrade(&"jetpack"), "unknown upgrade is refused")
	return true


# MKT-007, MKT-008
func test_all_upgrade_prices_and_the_level_cap() -> bool:
	var prices: Dictionary = {
		&"bait": [12000, 30000, 68000], &"rod": [18000, 44000, 96000], &"tonic": [15000, 38000, 82000],
		&"coffee": [14000, 34000, 74000], &"charm": [20000, 50000, 110000],
	}
	GameState.add_cash(1_400_000)
	check(_market.purchase_upgrade(&"bait"), "bait Lv1 open before paying debt")
	check(not _market.purchase_upgrade(&"bait"), "bait Lv2 blocked until Rp 100,000 debt is paid")
	check_eq(_market.pay_debt(350_000), 350_000, "paying Rp 350,000 debt opens Lv2 and Lv3")
	var start := GameState.get_cash()
	var spent := 0
	for upgrade_id: StringName in prices:
		var start_level := GameState.get_upgrade_level(upgrade_id)
		for level: int in range(start_level, 3):
			var before := GameState.get_cash()
			check(_market.purchase_upgrade(upgrade_id), "%s Lv%d purchase" % [upgrade_id, level + 1])
			check_eq(before - GameState.get_cash(), prices[upgrade_id][level], "%s Lv%d price" % [upgrade_id, level + 1])
			spent += int(prices[upgrade_id][level])
		check_eq(GameState.get_upgrade_level(upgrade_id), 3, "%s reached Lv3" % upgrade_id)
		check(not _market.purchase_upgrade(upgrade_id), "%s has no Lv4" % upgrade_id)
	check_eq(spent + 12000, 705000, "all fifteen steps cost Rp 705,000")
	check_eq(GameState.get_cash(), start - spent, "exactly that much was charged")
	check_eq(_saved()["upgrades"]["charm"], 3, "purchases were autosaved")
	return true


func test_unpaid_sales_trigger_collector_fee_and_reset_on_payment() -> bool:
	GameState.add_bucket_item(&"catfish_bruiser", 1)
	var sale1 := _market.sell_all()
	check_eq(sale1["unpaid_sales"], 1, "first unpaid sale counted")
	check_eq(sale1["collector_fee"], 0, "no fee on first unpaid sale")
	check(not GameState.is_debt_overdue(), "still not overdue after one sale")

	GameState.add_bucket_item(&"catfish_bruiser", 1)
	var sale2 := _market.sell_all()
	check_eq(sale2["unpaid_sales"], 2, "second unpaid sale counted")
	check_eq(sale2["collector_fee"], 0, "no fee yet on second unpaid sale")
	check(GameState.is_debt_overdue(), "collector harassment begins after two unpaid sales")

	var cash_before := GameState.get_cash()
	GameState.add_bucket_item(&"gourami_shady", 2)
	var sale3 := _market.sell_all()
	check_eq(sale3["unpaid_sales"], 3, "third unpaid sale counted")
	check_eq(sale3["total"], 68000, "gross sale total stays intact")
	check_eq(sale3["collector_fee"], ContentIds.DEBT_REMINDER_FEE, "Rp 10,000 reminder fee deducted")
	check_eq(sale3["net_total"], 58000, "net payout after fee")
	check_eq(GameState.get_cash(), cash_before + 58000, "cash increased by net payout")
	check_eq(GameState.get_debt_remaining(), ContentIds.DEBT_ORIGINAL, "reminder fee does not reduce debt")

	# Small trash sale caps the fee at 50% so Darto never walks away with nothing.
	var cash_before_trash := GameState.get_cash()
	GameState.add_bucket_item(&"trash_tyre", 1)
	var sale4 := _market.sell_all()
	check_eq(sale4["total"], 1000, "trash tyre gross")
	check_eq(sale4["collector_fee"], 500, "fee capped at half of small sale")
	check_eq(GameState.get_cash(), cash_before_trash + 500, "Darto still receives half")

	check_eq(_market.pay_debt(ContentIds.DEBT_MIN_RELIEF_PAYMENT), ContentIds.DEBT_MIN_RELIEF_PAYMENT, "pay relief amount")
	check_eq(GameState.get_unpaid_sales(), 0, "payment resets unpaid sale counter")
	check(not GameState.is_debt_overdue(), "overdue state cleared")

	GameState.add_bucket_item(&"catfish_bruiser", 1)
	var sale5 := _market.sell_all()
	check_eq(sale5["collector_fee"], 0, "no fee on next sale after paying debt")
	return true


func test_debt_panel_milestones_and_receipt_shortcut() -> bool:
	check(MarketDebtPanel.next_milestone_text(0).contains("100"), "first goal targets 100k")
	check(MarketDebtPanel.next_milestone_text(100_000).contains("350"), "second goal targets 350k")
	check(MarketDebtPanel.next_milestone_text(350_000).contains("700"), "third goal targets 700k")
	check(MarketDebtPanel.next_milestone_text(700_000).contains("1,100") or MarketDebtPanel.next_milestone_text(700_000).contains("1.100"), "fourth goal targets 1.1M")
	check(MarketDebtPanel.next_milestone_text(1_850_000).contains("2,000") or MarketDebtPanel.next_milestone_text(1_850_000).contains("2.000"), "final goal targets 2M")
	check_eq(MarketDebtPanel.next_milestone_text(ContentIds.DEBT_ORIGINAL), "", "no next goal once paid")

	var receipt := ReceiptOverlay.new()
	tree.root.add_child(receipt)
	await wait_frames(2)
	var jumped := [false]
	receipt.pay_debt_requested.connect(func() -> void: jumped[0] = true)
	receipt.open({"lines": [], "total": 68000, "collector_fee": 10000, "unpaid_sales": 3, "cash_after": 68000})
	await wait_frames(2)
	check(receipt.get_pay_debt_button().visible, "PAY DEBT button shows while debt remains")
	receipt.get_pay_debt_button().pressed.emit()
	check(jumped[0], "pressing PAY DEBT emits pay_debt_requested")
	check(not receipt.is_open(), "and closes the receipt")

	GameState.debug_set_debt_remaining(0)
	receipt.open({"lines": [], "total": 20000, "collector_fee": 0, "unpaid_sales": 0, "cash_after": 20000})
	await wait_frames(2)
	check(not receipt.get_pay_debt_button().visible, "PAY DEBT button hides once debt is cleared")
	receipt.hide_overlay()
	receipt.queue_free()
	await wait_frames(1)
	return true


func test_shop_shows_real_effects() -> bool:
	check_eq(UpgradeEffects.describe(&"rod", 0), TextDb.t(&"upgrade.effect.none"), "Lv0 has no bonus")
	check(UpgradeEffects.describe(&"rod", 1).contains("0.035"), "rod Lv1 shows +0.035")
	check(UpgradeEffects.describe(&"rod", 2).contains("0.070"), "rod Lv2 shows +0.070")
	check(UpgradeEffects.describe(&"bait", 1).contains("82"), "bait Lv1 shows 82%")
	check(UpgradeEffects.describe(&"bait", 3).contains("46"), "bait Lv3 shows 46%")
	check(UpgradeEffects.describe(&"tonic", 2).contains("150") and UpgradeEffects.describe(&"tonic", 2).contains("140"), "tonic Lv2 shows HP 150 and stamina 140%")
	check(UpgradeEffects.describe(&"coffee", 3).contains("64"), "coffee Lv3 shows 64%")
	check(UpgradeEffects.describe(&"charm", 2).contains("2"), "charm Lv2 shows 2 charges")

	check_near(UpgradeEffects.bait_wait_multiplier(2), 0.64, 0.0001, "bait multiplier")
	check_near(UpgradeEffects.rod_half_width_bonus(3), 0.105, 0.0001, "rod bonus")
	check_eq(UpgradeEffects.tonic_max_hp(3), 175.0, "tonic HP")
	check_near(UpgradeEffects.tonic_stamina_multiplier(3), 1.6, 0.0001, "tonic stamina")
	check_near(UpgradeEffects.coffee_speed_multiplier(1), 0.88, 0.0001, "coffee speed")
	check_eq(UpgradeEffects.charm_charges(3), 3, "charm charges")
	check_eq(UpgradeEffects.charm_charges(9), 3, "levels above the cap are clamped")
	return true


# --- Debt -------------------------------------------------------------------

# MKT-009
func test_debt_payment_is_capped_by_cash() -> bool:
	check_eq(_market.get_max_debt_payment(), 10000, "the most that can be paid is the cash on hand")
	check_eq(_market.pay_debt(100000), 10000, "paying more than the cash pays only the cash")
	check_eq(GameState.get_cash(), 0, "cash is spent, never negative")
	check_eq(GameState.get_debt_remaining(), 1990000, "debt went down by what was paid")
	check_eq(_market.pay_debt(25000), 0, "nothing left to pay with")
	check_eq(_market.pay_debt(-500), 0, "negative payments are refused")
	check_eq(_events, ["done:debt"], "only the real payment was a transaction")
	return true


# MKT-010
func test_debt_cannot_be_overpaid() -> bool:
	GameState.add_cash(5_000_000)
	check_eq(_market.pay_debt(5_000_000), 2_000_000, "payment stops at the remaining debt")
	check_eq(GameState.get_debt_remaining(), 0, "debt is exactly zero")
	check_eq(GameState.get_debt_paid(), 2_000_000, "everything paid")
	check_eq(GameState.get_cash(), 10000 + 5_000_000 - 2_000_000, "the rest stays in cash")
	check_eq(_market.pay_debt(1000), 0, "a cleared debt accepts no more payments")
	check_eq(_market.get_max_debt_payment(), 0, "nothing more can be paid")
	check_eq(_saved()["debt"]["remaining"], 0, "payment was autosaved")
	return true


# MKT-011
func test_double_tap_does_not_repeat_a_transaction() -> bool:
	_market.transaction_lock_enabled = true
	GameState.add_cash(500000)
	GameState.add_bucket_item(&"carp_golden", 1)
	var cash := GameState.get_cash()

	check(_market.purchase_upgrade(&"bait"), "first press buys")
	check(not _market.purchase_upgrade(&"bait"), "second press in the same instant is ignored")
	check_eq(GameState.get_upgrade_level(&"bait"), 1, "only one level was bought")
	check_eq(GameState.get_cash(), cash - 12000, "only one price was charged")
	check_eq(_market.pay_debt(25000), 0, "another transaction right after is ignored too")
	check_eq(_market.sell_all()["total"], 0, "and so is a sale")
	check_eq(GameState.get_bucket_quantity(&"carp_golden"), 1, "the fish is still in the bucket")

	await wait_seconds(0.35)
	check_eq(_market.pay_debt(25000), 25000, "after the lock the next press works")
	return true


func test_failed_autosave_is_reported_and_state_is_kept() -> bool:
	GameState.add_bucket_item(&"tilapia_gym_rat", 1)
	SaveManager.simulate_write_failure = true
	var sale := _market.sell_all()
	SaveManager.simulate_write_failure = false
	check_eq(sale["total"], 26000, "the sale still happened")
	check_eq(GameState.get_cash(), 36000, "runtime state is kept")
	check(_events.has("save_failed"), "the failed save is reported, not hidden")
	check(SaveManager.has_unsaved_changes(), "unsaved changes are flagged")
	return true


# --- Story triggers and Market-exit arbitration -----------------------------

# STORY-001, STORY-002
func test_milestone_trigger_queues_once() -> bool:
	StoryDirector.begin_market_visit()
	_pay(60000)
	check(StoryDirector.get_pending_events().is_empty(), "no milestone below Rp 100,000")
	_pay(40000)
	check_eq(StoryDirector.get_pending_events(), [&"story_debt_100k"], "Rp 100,000 paid queues the first milestone")
	StoryDirector.evaluate_story_triggers()
	StoryDirector.evaluate_story_triggers()
	_pay(10000)
	check_eq(StoryDirector.get_pending_events(), [&"story_debt_100k"], "the same trigger never queues twice")

	StoryDirector.complete_event(&"story_debt_100k", false)
	StoryDirector.evaluate_story_triggers()
	check(StoryDirector.get_pending_events().is_empty(), "a seen event is never queued again")
	return true


# STORY-003
func test_one_event_per_market_visit() -> bool:
	StoryDirector.begin_market_visit()
	_pay(100000)
	check_eq(StoryDirector.resolve_market_exit_event(), &"story_debt_100k", "the visit gets its event")
	StoryDirector.complete_event(&"story_debt_100k", true)
	_pay(250000)
	check(StoryDirector.get_pending_events().has(&"story_debt_300k"), "another milestone was reached in the same visit")
	check_eq(StoryDirector.resolve_market_exit_event(), &"", "but this visit already had its one event")

	StoryDirector.begin_market_visit()
	check_eq(StoryDirector.resolve_market_exit_event(), &"story_debt_300k", "it plays on the next visit")
	return true


## The debt milestones among `events`, without the spot openings of
## revision 6.7 (those queue on the same thresholds and rank below them).
static func _milestones(events: Array) -> Array:
	return events.filter(func(event_id: StringName) -> bool: return not String(event_id).begins_with("story_unlock_"))


# STORY-004
func test_higher_priority_goes_first_and_the_other_waits() -> bool:
	StoryDirector.begin_market_visit()
	_pay(350000)
	check_eq(_milestones(StoryDirector.get_pending_events()).size(), 2, "two thresholds crossed by one payment")
	check(StoryDirector.get_pending_events().has(&"story_unlock_kenanga"), "the river's opening waits in the queue too")
	var first := StoryDirector.resolve_market_exit_event()
	check_eq(first, &"story_debt_300k", "the higher-priority milestone is shown")
	StoryDirector.complete_event(first, false)
	check_eq(_milestones(StoryDirector.get_pending_events()), [&"story_debt_100k"], "the other stays pending")

	StoryDirector.begin_market_visit()
	check_eq(StoryDirector.resolve_market_exit_event(), &"story_debt_100k", "and plays on the next visit")
	return true


# STORY-005, STORY-006, STORY-011
func test_paying_everything_reaches_the_finale_without_arowana() -> bool:
	StoryDirector.begin_market_visit()
	check_eq(_pay(2_000_000), 2_000_000, "the whole debt is paid from ordinary sales money")
	check_eq(GameState.get_fish_book_entry(&"arowana_don")["wins"], 0, "Don Arowana was never beaten")
	var pending := StoryDirector.get_pending_events()
	check(pending.has(&"story_debt_paid"), "the finale event is queued")
	check_eq(_milestones(pending).size(), 7, "all six milestones and the finale were crossed at once")

	check_eq(StoryDirector.resolve_market_exit_event(), &"story_debt_paid", "the finale outranks every milestone")
	StoryDirector.complete_event(&"story_debt_paid", false)
	check(_milestones(StoryDirector.get_pending_events()).is_empty(), "obsolete milestones are retired")
	for event_id: StringName in ALL_DEBT_MILESTONES:
		check(StoryDirector.is_event_seen(event_id), "%s will never play after the ending" % event_id)
	check_eq(GameState.get_story_value(&"chapter"), "finale", "the story is in its finale")

	# Revision 6.7: the four spots still open after the ending, one a visit,
	# in the order they would have opened.
	for spot: StringName in [&"story_unlock_kenanga", &"story_unlock_melati", &"story_unlock_anggrek", &"story_unlock_mawar"]:
		StoryDirector.begin_market_visit()
		StoryDirector.evaluate_story_triggers()
		var opening := StoryDirector.resolve_market_exit_event()
		check_eq(opening, spot, "%s plays after the ending" % spot)
		StoryDirector.complete_event(opening, true)
	check(GameState.is_location_unlocked(&"mawar"), "every spot is open")
	StoryDirector.begin_market_visit()
	StoryDirector.evaluate_story_triggers()
	check_eq(StoryDirector.resolve_market_exit_event(), &"", "nothing is left to play")
	return true


func test_arowana_event_ranks_between_milestones_and_finale() -> bool:
	StoryDirector.begin_market_visit()
	GameState.record_fish_win(&"arowana_don", 6.2, &"boxing")
	_pay(1_850_000)
	check_eq(StoryDirector.resolve_market_exit_event(), &"story_arowana_first_win", "the Arowana scene outranks the debt milestones")
	StoryDirector.complete_event(&"story_arowana_first_win", false)
	check_eq(GameState.get_story_value(&"arowana_first_win_seen"), true, "its flag is set")

	StoryDirector.begin_market_visit()
	_pay(150000)
	check_eq(StoryDirector.resolve_market_exit_event(), &"story_debt_paid", "but the finale outranks everything")
	return true


# BOOK-001, STORY-007 (the unlock survives a skip)
func test_fish_book_unlocks_with_the_600k_milestone() -> bool:
	check_eq(GameState.get_story_value(&"fish_book_unlocked"), false, "the Fish Book starts locked")
	StoryDirector.begin_market_visit()
	_pay(700000)
	check_eq(GameState.get_story_value(&"fish_book_unlocked"), false, "reaching the amount alone does not unlock it")
	check_eq(StoryDirector.resolve_market_exit_event(), &"story_debt_600k", "the 600k milestone is chosen")
	StoryDirector.complete_event(&"story_debt_600k", true)
	check_eq(GameState.get_story_value(&"fish_book_unlocked"), true, "a skipped event still unlocks the Fish Book")
	check(StoryDirector.is_event_seen(&"story_debt_600k"), "and is marked seen")
	check_eq(GameState.get_story_value(&"chapter"), "chapter_4", "and moves the chapter on")
	return true


func test_leaving_the_market_resolves_and_saves() -> bool:
	StoryDirector.begin_market_visit()
	check(StoryDirector.is_event_seen(&"story_first_market"), "the first visit counts as the Market tutorial event")
	check_eq(GameState.get_story_value(&"chapter"), "chapter_1", "chapter one begins")
	_pay(700000)
	_market.leave_market()
	check_eq(_events[_events.size() - 1], "left:story_debt_600k", "leaving reports the resolved event")
	check(not StoryDirector.is_event_seen(&"story_debt_600k"), "the Story scene has not played it yet")
	# What the Story scene does when the call ends (watched or skipped).
	StoryDirector.complete_event(&"story_debt_600k", true)
	check(SaveManager.save_game(&"story"), "saved after the scene")
	check_eq(GameState.get_story_value(&"fish_book_unlocked"), true, "its unlock applied")
	check_eq(_saved()["story"]["fish_book_unlocked"], true, "and was saved")
	check_eq(_milestones(_saved()["story"]["pending_events"]).size(), 2, "the two lower milestones are saved as pending")
	check(_market.is_leaving(), "the visit is over")
	check_eq(_market.pay_debt(1000), 0, "no transactions after leaving")
	_market.leave_market()
	check_eq(_events.count("left:story_debt_600k"), 1, "leaving twice does nothing more")
	return true


func test_story_queue_survives_save_and_load() -> bool:
	StoryDirector.begin_market_visit()
	StoryDirector.begin_market_visit()
	_pay(350000)
	check(SaveManager.save_game(&"test"), "saved")
	var pending_before := StoryDirector.get_pending_events()
	GameState.clear_game()
	check(SaveManager.load_game(), "loaded")
	check_eq(StoryDirector.get_pending_events(), pending_before, "pending events restored in order")
	check_eq(GameState.get_story_value(&"market_visit_serial"), 2, "visit serial restored")
	check_eq(StoryDirector.resolve_market_exit_event(), &"story_debt_300k", "arbitration continues after a reload")
	return true


func test_story_data_is_valid() -> bool:
	var events: Array = StoryDirector.get_all_events()
	check_eq(events.size(), 17, "seventeen narrative events (revision 6.7 added four spot openings)")
	check_empty(DataValidator.validate_story_events(events, StoryDirector.TRIGGER_TYPES), "story data validation")

	var wrong_priority: StoryEvent = StoryDirector.get_event(&"story_debt_300k").duplicate()
	wrong_priority.priority = 999
	check_contains(DataValidator.validate_story_events([wrong_priority], StoryDirector.TRIGGER_TYPES), "does not match the arbitration table", "priority drift is caught")

	var bad_reference: StoryEvent = StoryDirector.get_event(&"story_debt_paid").duplicate()
	var bogus: Array[StringName] = [&"story_invented"]
	bad_reference.supersedes = bogus
	bad_reference.trigger_type = &"full_moon"
	var errors := DataValidator.validate_story_events([bad_reference], StoryDirector.TRIGGER_TYPES)
	check_contains(errors, "references unknown event", "unknown reference is caught")
	check_contains(errors, "unknown trigger_type", "unknown trigger type is caught")
	return true


# --- Fish Book and Records --------------------------------------------------

# BOOK-002, BOOK-003, BOOK-005
func test_fish_book_and_record_counters() -> bool:
	GameState.record_encounter(&"tilapia_gym_rat")
	GameState.record_fish_loss(&"tilapia_gym_rat")
	check(not GameState.is_fish_discovered(&"tilapia_gym_rat"), "a loss does not reveal the entry")
	GameState.record_encounter(&"tilapia_gym_rat")
	GameState.record_fish_win(&"tilapia_gym_rat", 1.8, &"arm_wrestle")
	check(GameState.is_fish_discovered(&"tilapia_gym_rat"), "the first defeat reveals the entry")
	GameState.record_fish_win(&"tilapia_gym_rat", 1.2, &"arm_wrestle")
	GameState.record_fish_win(&"tilapia_gym_rat", 2.3, &"dance")
	var entry := GameState.get_fish_book_entry(&"tilapia_gym_rat")
	check_eq(entry["encounters"], 2, "encounters")
	check_eq(entry["wins"], 3, "wins")
	check_eq(entry["losses"], 1, "losses")
	check_eq(entry["best_weight_kg"], 2.3, "best weight only rises")
	check_eq(entry["favourite_duel"], "arm_wrestle", "favourite duel")
	check_eq(GameState.get_stat(&"largest_fish_id"), "tilapia_gym_rat", "largest fish record")
	return true


# Exit gate: save and reload preserve everything the Market touched.
func test_market_session_round_trips_through_the_save() -> bool:
	StoryDirector.begin_market_visit()
	GameState.add_bucket_item(&"snakehead_sergeant", 4)
	GameState.add_bucket_item(&"trash_sandal", 2)
	_market.sell_category(MarketController.CATEGORY_FISH)
	_market.purchase_upgrade(&"rod")
	_market.purchase_upgrade(&"bait")
	_market.pay_debt(120000)
	_market.leave_market()
	# The Story scene finishes the visit's event and saves.
	StoryDirector.complete_event(&"story_debt_100k", true)
	check(SaveManager.save_game(&"story"), "saved after the scene")
	var before := GameState.export_save_state()
	before.erase("last_played_at_utc")
	before.erase("system")

	GameState.clear_game()
	check(SaveManager.load_game(), "reload succeeds")
	var after := GameState.export_save_state()
	after.erase("last_played_at_utc")
	after.erase("system")
	check_eq(JSON.stringify(after, "", true), JSON.stringify(before, "", true), "state after reload equals state before")
	check_eq(GameState.get_cash(), 10000 + 312000 - 18000 - 12000 - 120000, "cash")
	check_eq(GameState.get_bucket_quantity(&"trash_sandal"), 2, "unsold trash is still in the bucket")
	check_eq(GameState.get_upgrade_level(&"rod"), 1, "rod level")
	check_eq(GameState.get_debt_paid(), 120000, "debt paid")
	check(_events.has("left:story_debt_100k"), "the milestone event was resolved on leaving")
	check(StoryDirector.is_event_seen(&"story_debt_100k"), "and seen once its scene ended")
	return true


# BOOK-004
func test_big_one_is_rare_and_always_in_the_top_tenth() -> bool:
	var fish_rolls := 0
	var big_ones := 0
	var misplaced := 0
	var out_of_range := 0
	for index: int in 40000:
		var encounter := EncounterRoller.roll(5000 + index, 0)
		if encounter["kind"] != EncounterRoller.KIND_FISH:
			continue
		fish_rolls += 1
		var fish := GameData.get_fish(encounter["item_id"])
		var weight: float = encounter["weight_kg"]
		# Weights are rounded to 10 g, so allow half a step at the boundary.
		var top_tenth := lerpf(fish.weight_min_kg, fish.weight_max_kg, EncounterRoller.BIG_ONE_PERCENTILE)
		if weight < fish.weight_min_kg - 0.006 or weight > fish.weight_max_kg + 0.006:
			out_of_range += 1
		if encounter["is_big_one"]:
			big_ones += 1
			if weight < top_tenth - 0.006:
				misplaced += 1
		elif weight > top_tenth + 0.006:
			misplaced += 1
	check(fish_rolls > 30000, "enough fish rolled (%d)" % fish_rolls)
	check_near(float(big_ones) / float(fish_rolls), 0.05, 0.006, "about 5% of fish are a BIG ONE")
	check_eq(misplaced, 0, "a BIG ONE is always in the top tenth of its species, and nothing else is")
	check_eq(out_of_range, 0, "every weight stays inside the species range")
	return true
