class_name MarketController
extends Node
## Every transaction at Bu Yati's warung (GDD Sections 72-80, 169.12, 176.9).
##
## Each transaction runs in the same order: validate, change GameState, queue
## story triggers, autosave, then report the result so the UI can show it.
## Selling is the only way a catch becomes cash, and paying debt can never
## exceed the cash on hand or the debt that is left.
##
## A short lock after each accepted transaction makes a double tap harmless:
## the second press is ignored instead of buying or paying twice.

## kind is &"sell", &"upgrade" or &"debt".
signal transaction_completed(kind: StringName, result: Dictionary)
## The autosave after a transaction failed; runtime state is kept (GDD 176.8).
signal save_failed()
## The visit is over. `event_id` is the story event resolved for this visit,
## or &"" when there was none.
signal market_left(event_id: StringName)

const CATEGORY_FISH := &"fish"
const CATEGORY_TRASH := &"trash"
const KIND_SELL := &"sell"
const KIND_UPGRADE := &"upgrade"
const KIND_DEBT := &"debt"
const KIND_SAVINGS := &"savings"
## Travel gear for a new fishing spot (revision 6.7).
const KIND_GEAR := &"gear"
const TRANSACTION_LOCK_MSEC := 250

## Turn off to route somewhere else after leaving (the Market scene shows an
## unlock notice first; tests do not change scene at all).
var auto_route: bool = true
## Tests switch the double-tap lock off to run transactions back to back.
var transaction_lock_enabled: bool = true

var _locked_until_msec: int = 0
var _leaving: bool = false


# --- Public API (GDD 169.12) ------------------------------------------------

## What selling everything would pay right now, line by line.
func get_sell_preview() -> Dictionary:
	return _build_sale(ContentIds.get_bucket_item_ids())


func sell_all() -> Dictionary:
	return _sell(ContentIds.get_bucket_item_ids())


## `category_id` is &"fish" or &"trash".
func sell_category(category_id: StringName) -> Dictionary:
	match category_id:
		CATEGORY_FISH:
			return _sell(ContentIds.FISH_IDS)
		CATEGORY_TRASH:
			return _sell(ContentIds.TRASH_IDS)
	GameLog.error(&"MARKET", "unknown sell category", {"category": category_id})
	return _empty_sale()


func purchase_upgrade(upgrade_id: StringName) -> bool:
	if _is_locked() or not GameState.can_buy_upgrade(upgrade_id):
		return false
	var upgrade := GameData.get_upgrade(upgrade_id)
	var price := upgrade.get_price_for_level(GameState.get_upgrade_level(upgrade_id))
	if not GameState.buy_next_upgrade(upgrade_id):
		return false
	_finish_transaction(KIND_UPGRADE, {
		"upgrade_id": upgrade_id,
		"level": GameState.get_upgrade_level(upgrade_id),
		"price": price,
	}, &"upgrade")
	return true


## Buys the travel gear that opens a fishing spot (revision 6.7). Refused for
## a spot that is not open, gear already owned, or without the cash.
func purchase_gear(location_id: StringName) -> bool:
	if _is_locked() or not GameState.can_buy_location_gear(location_id):
		return false
	var price := GameData.get_location(location_id).access_price
	if not GameState.buy_location_gear(location_id):
		return false
	_finish_transaction(KIND_GEAR, {"location_id": location_id, "price": price}, &"gear")
	return true


## Pays up to `amount` and returns what was really paid. The amount is capped
## by the cash on hand and by the remaining debt.
func pay_debt(amount: int) -> int:
	if _is_locked() or amount <= 0:
		return 0
	var was_overdue := GameState.is_debt_overdue()
	var paid := GameState.pay_debt(amount)
	if paid <= 0:
		return 0
	_finish_transaction(KIND_DEBT, {
		"paid": paid,
		"remaining": GameState.get_debt_remaining(),
		"total_paid": GameState.get_debt_paid(),
		"cleared_overdue": was_overdue and not GameState.is_debt_overdue(),
	}, &"debt")
	return paid


## Post-game FAMILY SAVINGS (GDD 19): cash goes in and only the number
## grows. There is no reward attached. Returns what was saved.
func deposit_savings(amount: int) -> int:
	if _is_locked() or amount <= 0 or not bool(GameState.get_story_value(&"postgame_unlocked")):
		return 0
	var saved := mini(amount, GameState.get_cash())
	if saved <= 0 or not GameState.spend_cash(saved):
		return 0
	GameState.increment_stat(&"family_savings", saved)
	_finish_transaction(KIND_SAVINGS, {"saved": saved, "total": int(GameState.get_stat(&"family_savings"))}, &"savings")
	return saved


## Ends the visit: saves, then lets at most one queued story event through
## (GDD 177.3) to the Story scene, which applies its unlock. A build without
## the Story scene completes the event at once instead.
func leave_market() -> void:
	if _leaving:
		return
	_leaving = true
	if not SaveManager.save_game(&"leave_market"):
		save_failed.emit()
	StoryDirector.evaluate_story_triggers()
	var event_id := StoryDirector.resolve_market_exit_event()
	if event_id != &"":
		if SceneRouter.has_scene(SceneRouter.SCENE_STORY):
			# The Story scene plays it and applies its unlock. Without
			# auto_route the caller decides when (the Market scene, tests).
			market_left.emit(event_id)
			if auto_route:
				StoryDirector.play_event(event_id)
			return
		StoryDirector.complete_event(event_id, true)
		SaveManager.save_game(&"story_event")
	market_left.emit(event_id)
	if auto_route:
		SceneRouter.goto_fishing()


# --- Extras -----------------------------------------------------------------

## Largest amount the player could pay toward the debt right now.
func get_max_debt_payment() -> int:
	return mini(GameState.get_cash(), GameState.get_debt_remaining())


func is_leaving() -> bool:
	return _leaving


# --- Internals --------------------------------------------------------------

func _sell(item_ids: Array[StringName]) -> Dictionary:
	if _is_locked():
		return _empty_sale()
	var sale := _build_sale(item_ids)
	if int(sale["items_sold"]) == 0:
		return sale
	var removed := GameState.clear_bucket_items(item_ids)
	# Pay out exactly what left the Bucket, never what was merely previewed.
	var total := 0
	for item_id: StringName in removed:
		total += int(removed[item_id]) * GameData.get_item_sale_value(item_id)
	var unpaid_sales := GameState.record_unpaid_sale()
	var collector_fee := 0
	if unpaid_sales >= ContentIds.DEBT_FEE_AFTER_SALES:
		# Cap at half the sale so tiny trash-only sales never leave Darto with nothing.
		collector_fee = mini(ContentIds.DEBT_REMINDER_FEE, total / 2)
	var net_total := maxi(total - collector_fee, 0)
	sale["total"] = total
	sale["collector_fee"] = collector_fee
	sale["net_total"] = net_total
	sale["unpaid_sales"] = unpaid_sales
	sale["cash_before"] = GameState.get_cash()
	GameState.add_cash(net_total)
	sale["cash_after"] = GameState.get_cash()
	GameState.increment_stat(&"lifetime_sales", total)
	_finish_transaction(KIND_SELL, sale, &"sale")
	return sale


func _build_sale(item_ids: Array[StringName]) -> Dictionary:
	var sale := _empty_sale()
	for item_id: StringName in item_ids:
		var quantity := GameState.get_bucket_quantity(item_id)
		if quantity <= 0:
			continue
		var is_fish := GameData.is_fish(item_id)
		var unit_value := GameData.get_item_sale_value(item_id)
		var line := {
			"item_id": item_id,
			"name": GameData.get_item_display_name(item_id),
			"category": CATEGORY_FISH if is_fish else CATEGORY_TRASH,
			"quantity": quantity,
			"unit_value": unit_value,
			"base_value": unit_value,
			"multiplier": 1.0,
			"subtotal": quantity * unit_value,
		}
		if is_fish:
			var fish := GameData.get_fish(item_id)
			line["base_value"] = fish.sale_base
			line["multiplier"] = fish.sale_multiplier
		sale["lines"].append(line)
		sale["total"] = int(sale["total"]) + int(line["subtotal"])
		sale["items_sold"] = int(sale["items_sold"]) + quantity
		var category_total := "fish_total" if is_fish else "trash_total"
		sale[category_total] = int(sale[category_total]) + int(line["subtotal"])
	sale["cash_before"] = GameState.get_cash()
	sale["cash_after"] = GameState.get_cash()
	return sale


func _empty_sale() -> Dictionary:
	return {
		"lines": [], "total": 0, "collector_fee": 0, "net_total": 0, "unpaid_sales": 0,
		"items_sold": 0, "fish_total": 0, "trash_total": 0,
		"cash_before": GameState.get_cash(), "cash_after": GameState.get_cash(),
	}


## Transaction order from GDD 171.13: the state is already changed; queue story
## triggers, save, then report.
func _finish_transaction(kind: StringName, result: Dictionary, save_reason: StringName) -> void:
	_locked_until_msec = Time.get_ticks_msec() + TRANSACTION_LOCK_MSEC
	StoryDirector.evaluate_story_triggers()
	if not SaveManager.save_game(save_reason):
		save_failed.emit()
	GameLog.info(&"MARKET", "transaction", {"kind": kind, "cash": GameState.get_cash()})
	transaction_completed.emit(kind, result)


func _is_locked() -> bool:
	return _leaving or (transaction_lock_enabled and Time.get_ticks_msec() < _locked_until_msec)
