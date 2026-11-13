extends "res://tests/test_suite.gd"
## BOOT-001 and the Milestone 1 exit gate, run against the real scenes:
## the project boots to the Main Menu, New Game creates a valid save and
## Continue reloads it.

const STORAGE_DIR := "user://test_tmp/boot_flow"
const BOOT_SCENE := "res://scenes/boot/boot.tscn"
const BUTTONS := "MenuCanvas/SafeRoot/MenuButtons/"
const BOOT_TIMEOUT_SEC := 20.0

var _finished_transitions: Array[StringName] = []


func get_suite_name() -> String:
	return "boot"


func before_all() -> void:
	SceneRouter.transition_finished.connect(_on_transition_finished)


func after_all() -> void:
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), BOOT_TIMEOUT_SEC)
	tree.paused = false
	DebugService.clear_forces()
	SceneRouter.transition_finished.disconnect(_on_transition_finished)
	if tree.current_scene != null:
		tree.current_scene.queue_free()
		await wait_frames(2)
	GameState.clear_game()
	DebugService.clear_dev_dirty()
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


func before_each() -> void:
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)
	GameState.clear_game()
	DebugService.clear_dev_dirty()
	DebugService.clear_forces()


# --- Helpers ----------------------------------------------------------------

func _on_transition_finished(scene_id: StringName) -> void:
	_finished_transitions.append(scene_id)


## Runs the real Boot scene and waits until the router reports the Main Menu.
func _boot_to_menu() -> bool:
	# A previous test may still be on its way into another scene.
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), BOOT_TIMEOUT_SEC)
	tree.paused = false
	_finished_transitions.clear()
	tree.change_scene_to_packed(load(BOOT_SCENE))
	var reached := await wait_until(func() -> bool: return _finished_transitions.has(&"main_menu"), BOOT_TIMEOUT_SEC)
	await wait_frames(3)
	return reached and tree.current_scene != null and tree.current_scene.name == &"MainMenu"


func _button(button_name: String) -> BaseButton:
	return tree.current_scene.get_node(BUTTONS + button_name) as BaseButton


func _dialog() -> ModalDialog:
	return tree.current_scene.get_node("ConfirmOverlay") as ModalDialog


func _save_file_is_valid() -> bool:
	var parsed: Variant = read_json(SaveManager.get_save_path())
	return typeof(parsed) == TYPE_DICTIONARY and not SaveManager.validate_save(parsed).is_empty()


# --- Tests ------------------------------------------------------------------

# BOOT-001
func test_boot_reaches_main_menu_without_a_save() -> bool:
	if not check(await _boot_to_menu(), "boot reaches the Main Menu"):
		return true
	check_eq(SceneRouter.get_current_scene_id(), SceneRouter.SCENE_MAIN_MENU, "router reports the main menu")
	check(not SceneRouter.is_transitioning(), "transition finished")
	check(AudioManager.is_audio_ready(), "procedural audio was initialized by Boot")
	check(InputManager.is_gameplay_input_enabled(), "input is enabled again after the transition")
	check(_button("ContinueButton").disabled, "Continue is disabled without a save")
	check(not _button("NewGameButton").disabled, "New Game is available")
	check(not _button("HowToButton").disabled, "How To Play is available")
	check(not _button("SettingsButton").disabled, "Settings is available")
	check(not _dialog().is_open(), "no dialog on a clean boot")
	check(not GameState.has_active_game(), "no game is active yet")
	return true


func test_main_menu_follows_the_scene_blueprint() -> bool:
	if not check(await _boot_to_menu(), "boot reaches the Main Menu"):
		return true
	var menu := tree.current_scene
	for path: String in [
		"World", "World/MenuCamera", "World/MenuLighting",
		"MenuCanvas/SafeRoot/TitleBlock", "MenuCanvas/SafeRoot/MenuButtons",
		BUTTONS + "ContinueButton", BUTTONS + "NewGameButton", BUTTONS + "HowToButton",
		BUTTONS + "SettingsButton", BUTTONS + "CreditsButton",
		"MenuCanvas/SafeRoot/VersionLabel", "ConfirmOverlay", "TransitionLayer",
	]:
		check(menu.has_node(path), "node %s exists (GDD 168.2)" % path)
	var names := PackedStringArray()
	for child: Node in menu.get_node("MenuCanvas/SafeRoot/MenuButtons").get_children():
		names.append(child.name)
	check_eq(names, PackedStringArray(["ContinueButton", "NewGameButton", "HowToButton", "SettingsButton", "CreditsButton"]), "menu order (GDD 84)")
	return true


func test_new_game_creates_a_valid_save() -> bool:
	if not check(await _boot_to_menu(), "boot reaches the Main Menu"):
		return true
	_button("NewGameButton").pressed.emit()
	check(await wait_until(_save_file_is_valid, 5.0), "New Game wrote a valid schema-v5 save")
	check(GameState.has_active_game(), "a game is active")
	check_eq(GameState.get_cash(), 8430, "starting cash")
	check_eq(GameState.get_debt_remaining(), 1800000, "starting debt")
	await wait_frames(3)
	check(await wait_until(func() -> bool: return _finished_transitions.has(&"fishing"), BOOT_TIMEOUT_SEC), "New Game continues to the lake")
	return true


func test_continue_reloads_the_saved_state() -> bool:
	GameState.new_game()
	GameState.add_cash(41570)
	GameState.pay_debt(30000)
	GameState.add_bucket_item(&"snakehead_sergeant", 2)
	check(SaveManager.save_game(&"test"), "prepared a save")
	GameState.clear_game()

	if not check(await _boot_to_menu(), "boot reaches the Main Menu"):
		return true
	check(not _button("ContinueButton").disabled, "Continue is enabled when a save exists")
	check(GameState.has_active_game(), "Boot loaded the save")

	# Prove Continue reads the disk again instead of trusting memory.
	GameState.clear_game()
	_button("ContinueButton").pressed.emit()
	check(await wait_until(GameState.has_active_game, 5.0), "Continue loaded the save")
	check_eq(GameState.get_cash(), 20000, "cash restored")
	check_eq(GameState.get_debt_paid(), 30000, "debt paid restored")
	check_eq(GameState.get_bucket_quantity(&"snakehead_sergeant"), 2, "bucket restored")
	check(await wait_until(func() -> bool: return _finished_transitions.has(&"fishing"), BOOT_TIMEOUT_SEC), "Continue goes on to the lake")
	return true


func test_new_game_over_a_save_needs_two_confirmations() -> bool:
	GameState.new_game()
	GameState.add_cash(500000)
	check(SaveManager.save_game(&"test"), "prepared a save")
	if not check(await _boot_to_menu(), "boot reaches the Main Menu"):
		return true

	_button("NewGameButton").pressed.emit()
	check(await wait_until(_dialog().is_open, 3.0), "first confirmation opens")
	check_eq(GameState.get_cash(), 508430, "nothing is replaced by the first click")
	_dialog().footer.get_child(1).pressed.emit()
	await wait_frames(4)
	check(_dialog().is_open(), "second confirmation opens")
	check_eq(GameState.get_cash(), 508430, "nothing is replaced after one confirmation")

	# Backing out at the second step keeps the save.
	_dialog().footer.get_child(0).pressed.emit()
	await wait_frames(4)
	check(not _dialog().is_open(), "cancel closes the dialog")
	check_eq(read_json(SaveManager.get_save_path())["cash"], 508430, "save on disk is untouched")
	return true


func test_corrupt_save_offers_recovery() -> bool:
	var garbage := "this is not a save file"
	write_text(SaveManager.get_save_path(), garbage)
	if not check(await _boot_to_menu(), "boot reaches the Main Menu even with a corrupt save"):
		return true
	check(await wait_until(_dialog().is_open, 3.0), "recovery dialog opens")
	check_eq(FileAccess.get_file_as_string(SaveManager.get_save_path()), garbage, "corrupt save is not overwritten by booting")
	check_eq(FileAccess.get_file_as_string(SaveManager.get_corrupt_backup_path()), garbage, "corrupt save was preserved as a backup")
	check_eq(_dialog().footer.get_child_count(), 2, "TRY AGAIN and START NEW GAME")

	# TRY AGAIN with the file still broken asks again instead of dead-ending.
	_dialog().footer.get_child(0).pressed.emit()
	await wait_frames(6)
	check(_dialog().is_open(), "recovery dialog returns while the save is still unreadable")

	# START NEW GAME replaces the unreadable save with a valid one.
	_dialog().footer.get_child(1).pressed.emit()
	check(await wait_until(_save_file_is_valid, 5.0), "START NEW GAME wrote a valid save")
	check_eq(FileAccess.get_file_as_string(SaveManager.get_corrupt_backup_path()), garbage, "the backup is still there")
	return true


# --- Fishing scene (Milestone 2 exit gate) ----------------------------------

## New Game from the menu, then wait until the lake is on screen.
func _enter_lake() -> bool:
	if not await _boot_to_menu():
		return false
	_button("NewGameButton").pressed.emit()
	var reached := await wait_until(func() -> bool: return _finished_transitions.has(&"fishing"), BOOT_TIMEOUT_SEC)
	await wait_frames(3)
	return reached and tree.current_scene != null and tree.current_scene.name == &"Fishing"


func test_fishing_scene_follows_the_scene_blueprint() -> bool:
	if not check(await _enter_lake(), "New Game reaches the lake"):
		return true
	var scene := tree.current_scene
	for path: String in [
		"FishingController", "World/LakeSet", "World/Darto/Rig", "World/Darto/RodSocket",
		"World/Darto/Rod/RodTip", "World/Darto/AnimationPlayer", "World/FloatRoot/FloatMesh",
		"World/FloatRoot/RippleEmitter", "World/FloatRoot/BiteMarker", "World/FishShadowRoot",
		"World/FishingCamera", "World/FishingEffects",
		"FishingCanvas/SafeRoot/TopBar/CashWidget", "FishingCanvas/SafeRoot/TopBar/BucketWidget",
		"FishingCanvas/SafeRoot/ContextPrompt", "FishingCanvas/SafeRoot/ReelHUD/TensionBar",
		"FishingCanvas/SafeRoot/ReelHUD/GreenZone", "FishingCanvas/SafeRoot/ReelHUD/PlayerMarker",
		"FishingCanvas/SafeRoot/ReelHUD/LandingProgress", "FishingCanvas/SafeRoot/ReelHUD/StressWarning",
		"FishingCanvas/SafeRoot/ContextActionButton", "FishingCanvas/SafeRoot/MarketButton",
		"FishingCanvas/SafeRoot/PauseButton", "BucketPeekOverlay", "PauseOverlay",
	]:
		check(scene.has_node(path), "node %s exists (GDD 168.4)" % path)

	var controller := scene.get_node("FishingController") as FishingController
	check_eq(controller.get_state(), FishingController.STATE_IDLE, "the lake starts idle")
	check(not (scene.get_node("World/FloatRoot") as Node3D).visible, "no float in the water before a cast")
	check(InputManager.is_gameplay_input_enabled(), "gameplay input is live")
	# The float must not be parented to the rod (GDD 168.4 key path contract).
	check(not scene.get_node("World/Darto/Rod").is_ancestor_of(scene.get_node("World/FloatRoot")), "FloatRoot is not a child of the rod")
	return true


func test_full_catch_in_the_real_scene() -> bool:
	if not check(await _enter_lake(), "New Game reaches the lake"):
		return true
	var scene := tree.current_scene
	var controller := scene.get_node("FishingController") as FishingController
	DebugService.set_fast_wait(true)
	DebugService.set_auto_reel(true)

	# Cast with the real input action, exactly as the keyboard or CAST button does.
	InputManager.press_action(&"fish_cast")
	check(await wait_until(func() -> bool: return controller.get_state() == FishingController.STATE_CASTING, 2.0), "the input action starts a cast")
	InputManager.release_action(&"fish_cast")
	check(await wait_until(func() -> bool: return (scene.get_node("World/FloatRoot") as Node3D).visible, 3.0), "the float leaves the rod")

	check(await wait_until(func() -> bool: return controller.get_state() == FishingController.STATE_STRIKE_WINDOW, 8.0), "a bite arrives")
	check_eq(controller.get_encounter().get("item_id"), &"catfish_bruiser", "the first fish is Bruiser Catfish")
	check((scene.get_node("World/FloatRoot/BiteMarker") as Node3D).visible, "the ! marker shows during the bite")
	InputManager.press_action(&"fish_cast")
	check(await wait_until(func() -> bool: return controller.get_state() == FishingController.STATE_REELING, 2.0), "the same action strikes")
	InputManager.release_action(&"fish_cast")
	check((scene.get_node("FishingCanvas/SafeRoot/ReelHUD") as Control).visible, "the reel read-out appears")

	check(await wait_until(func() -> bool: return controller.get_state() == FishingController.STATE_LANDED, 30.0), "the reel lands the fish")
	check(not (scene.get_node("FishingCanvas/SafeRoot/ReelHUD") as Control).visible, "the reel read-out is gone after landing")
	check_eq(GameState.get_stat(&"fish_landed"), 1, "fish landed stat")

	if SceneRouter.has_scene(SceneRouter.SCENE_WHEEL) or SceneRouter.has_scene(&"boxing"):
		check(await wait_until(SceneRouter.is_transitioning, 10.0), "the catch is routed to its duel")
	else:
		check(await wait_until(func() -> bool: return controller.get_state() == FishingController.STATE_IDLE, 10.0), "back to idle after the reveal")
		check_eq(GameState.get_bucket_quantity(&"catfish_bruiser"), 1, "the catfish is in the bucket")
		check_eq(read_json(SaveManager.get_save_path())["bucket"]["catfish_bruiser"], 1, "and the catch was saved")
	DebugService.clear_forces()
	return true


func test_pause_freezes_the_lake_and_quit_returns_to_menu() -> bool:
	if not check(await _enter_lake(), "New Game reaches the lake"):
		return true
	var scene := tree.current_scene
	var controller := scene.get_node("FishingController") as FishingController
	var pause := scene.get_node("PauseOverlay") as PauseOverlay
	DebugService.set_fast_wait(true)
	InputManager.press_action(&"fish_cast")
	InputManager.release_action(&"fish_cast")
	check(await wait_until(func() -> bool: return controller.get_state() == FishingController.STATE_CASTING, 2.0), "cast started")

	InputManager.press_action(InputActions.PAUSE)
	check(await wait_until(pause.is_open, 2.0), "the pause action opens the pause menu")
	check(tree.paused, "the scene tree is paused")
	var frozen_state := controller.get_state()
	var frozen_time := controller.get_state_time()
	await wait_seconds(0.5)
	check_eq(controller.get_state(), frozen_state, "no state change while paused")
	check_eq(controller.get_state_time(), frozen_time, "no timer runs while paused")

	pause.resume()
	check(not tree.paused, "resume unpauses the tree")
	check(await wait_until(func() -> bool: return controller.get_state_time() > frozen_time or controller.get_state() != frozen_state, 2.0), "time moves again")

	pause.open()
	pause.footer.get_child(0).pressed.emit()
	check(await wait_until(func() -> bool: return _finished_transitions.count(&"main_menu") >= 2, BOOT_TIMEOUT_SEC), "QUIT TO MENU returns to the Main Menu")
	check(not tree.paused, "the tree is not left paused")
	DebugService.clear_forces()
	return true


# FISH-014, FISH-015
func test_stress_shakes_the_hud_by_setting_and_never_the_camera() -> bool:
	if not check(await _enter_lake(), "New Game reaches the lake"):
		return true
	var scene := tree.current_scene
	var reel_hud := scene.get_node("FishingCanvas/SafeRoot/ReelHUD") as ReelHud
	var camera := scene.get_node("World/FishingCamera") as Camera3D
	var camera_before := camera.global_transform
	var reel := ReelSimulation.new()
	reel.setup(GameData.get_fish(&"catfish_bruiser"), 0, 5)
	var home := reel_hud.position

	var peaks: Dictionary = {}
	for mode: String in ["on", "reduced", "off"]:
		GameState.set_setting(&"hud_shake", mode)
		var by_band: Array[float] = []
		for stress: float in [10.0, 55.0, 80.0, 96.0]:
			reel.stress = stress
			var peak := 0.0
			for _frame: int in 40:
				reel_hud.update_reel(reel, true, 0.016)
				peak = maxf(peak, (reel_hud.position - home).length())
			by_band.append(peak)
		peaks[mode] = by_band
	GameState.set_setting(&"hud_shake", "on")
	reel_hud.hide_reel()

	var on: Array = peaks["on"]
	check_eq(on[0], 0.0, "no shake while stress is under 40")
	check(on[1] > 0.0 and on[1] < on[2] and on[2] < on[3], "shake grows through the three stress bands")
	var reduced: Array = peaks["reduced"]
	check(reduced[3] > 0.0 and reduced[3] <= on[3] * 0.45, "REDUCED is about 40% of the full shake")
	var off: Array = peaks["off"]
	check_eq(off[3], 0.0, "OFF removes the shake completely")
	check(camera.global_transform.is_equal_approx(camera_before), "the camera never moves with line stress")
	return true


# --- Market (GDD 168.5, 176.16, 177) ----------------------------------------

const LEDGER := "MarketCanvas/SafeRoot/"


## From the lake, press the Market button and wait until the warung is up.
func _enter_market(bucket: Dictionary = {}) -> bool:
	if not await _enter_lake():
		return false
	for item_id: StringName in bucket:
		GameState.add_bucket_item(item_id, bucket[item_id])
	(tree.current_scene.get_node("FishingCanvas/SafeRoot/MarketButton") as BaseButton).pressed.emit()
	var reached := await wait_until(func() -> bool: return _finished_transitions.has(&"market"), BOOT_TIMEOUT_SEC)
	await wait_frames(3)
	return reached and tree.current_scene != null and tree.current_scene.name == &"Market"


func test_market_scene_follows_the_scene_blueprint() -> bool:
	if not check(await _enter_market(), "the Market button at the lake reaches the Market"):
		return true
	var scene := tree.current_scene
	for path: String in [
		"MarketController", "World/MarketSet", "World/BuYati", "World/DartoMarketPose", "World/MarketCamera",
		LEDGER + "HeaderBar", LEDGER + "TabBar/SellTabButton", LEDGER + "TabBar/UpgradeTabButton",
		LEDGER + "TabBar/DebtTabButton", LEDGER + "TabBar/FishBookTabButton", LEDGER + "TabBar/RecordsTabButton",
		LEDGER + "TabContent/SellPanel", LEDGER + "TabContent/UpgradePanel", LEDGER + "TabContent/DebtPanel",
		LEDGER + "TabContent/FishBookPanel", LEDGER + "TabContent/RecordsPanel", LEDGER + "LeaveMarketButton",
		"ReceiptOverlay", "PauseOverlay",
	]:
		check(scene.has_node(path), "node %s exists (GDD 168.5)" % path)

	var hud := scene.get_node("MarketCanvas") as MarketHud
	check_eq(hud.get_current_tab(), MarketHud.TAB_SELL, "the Market opens on SELL")
	check((scene.get_node(LEDGER + "TabContent/SellPanel") as Control).visible, "the SELL page is showing")
	check(not (scene.get_node(LEDGER + "TabContent/DebtPanel") as Control).visible, "the other pages are closed")
	var expected_order: Array[StringName] = [&"sell", &"upgrades", &"debt", &"fish_book", &"records"]
	check_eq(MarketHud.TAB_ORDER, expected_order, "tab order (GDD 167.9)")
	for index: int in MarketHud.TAB_ORDER.size():
		check_eq(hud.get_tab_button(MarketHud.TAB_ORDER[index]).get_index(), index, "tab %s is in position %d" % [MarketHud.TAB_ORDER[index], index])
	check_eq(scene.get_node(LEDGER + "TabBar").get_child_count(), 5, "five tabs")

	check_eq(AudioManager.get_ambience_state(), &"market", "the warung ambience is on")
	check_eq(int(GameState.get_story_value(StoryDirector.KEY_VISIT_SERIAL)), 1, "entering counts as one Market visit")
	check(StoryDirector.is_event_seen(&"story_first_market"), "the first-visit event is settled")
	var world := scene.get_node("World") as MarketWorld
	check_eq(world.get_bu_yati_clip(), &"market_idle", "Bu Yati idles behind the counter")
	var markers := scene.get_node("World/MarketSet/Markers")
	check((scene.get_node("World/BuYati") as Node3D).position.is_equal_approx((markers.get_node("BuYatiSpot") as Node3D).position), "Bu Yati stands on her marker")
	check((scene.get_node("World/MarketCamera") as Camera3D).current, "the Market camera is live")
	return true


# MKT-001..009 through the real buttons, plus the first-visit tutorial.
func test_market_visit_in_the_real_scene() -> bool:
	if not check(await _enter_market({&"catfish_bruiser": 3, &"trash_sandal": 2}), "reach the Market with a catch"):
		return true
	var scene := tree.current_scene
	var hud := scene.get_node("MarketCanvas") as MarketHud
	var receipt := scene.get_node("ReceiptOverlay") as ReceiptOverlay
	var start_cash := ContentIds.STARTING_CASH
	check_eq(GameState.get_cash(), start_cash, "the catch is not cash yet")
	check_eq(hud.get_hint_text(), TextDb.t(&"market.hint.sell"), "first visit: the hint says to sell")

	hud.sell_panel.get_sell_all_button().pressed.emit()
	check_eq(GameState.get_cash(), start_cash + 55000, "3 catfish and 2 sandals sell for Rp 55,000")
	check_eq(GameState.get_bucket_total_count(), 0, "the Bucket is empty after SELL ALL")
	check(await wait_until(receipt.is_open, 2.0), "the receipt opens")
	check_eq(read_json(SaveManager.get_save_path())["cash"], start_cash + 55000, "the sale was saved at once")
	check(hud.sell_panel.get_sell_all_button().disabled, "nothing left to sell")
	receipt.hide_overlay()
	check_eq(hud.get_hint_text(), TextDb.t(&"market.hint.debt_tab"), "next hint: open the Debt tab")

	await wait_seconds(0.3)
	hud.get_tab_button(MarketHud.TAB_DEBT).pressed.emit()
	check_eq(hud.get_current_tab(), MarketHud.TAB_DEBT, "the Debt tab opens")
	check_eq(hud.get_hint_text(), TextDb.t(&"market.hint.pay"), "next hint: pay Rp 10,000")
	var tutorial_pay := hud.debt_panel.get_pay_button(MarketDebtPanel.TUTORIAL_AMOUNT)
	check(tutorial_pay.visible and not tutorial_pay.disabled, "the tutorial payment is offered")
	check(hud.debt_panel.get_pay_button(100000).disabled, "PAY 100,000 is disabled without the cash")
	check(not hud.debt_panel.get_pay_button(25000).disabled, "PAY 25,000 is affordable")
	tutorial_pay.pressed.emit()
	check_eq(GameState.get_debt_remaining(), 1790000, "debt remaining Rp 1,790,000 (GDD 183.5)")
	check_eq(GameState.get_cash(), start_cash + 45000, "the payment came out of cash")
	check(GameState.is_tutorial_seen(&"market_seen"), "the Market tutorial is done after the first payment")
	check_eq(hud.get_hint_text(), TextDb.t(&"market.hint.upgrades"), "last hint: upgrades are optional")
	check(not tutorial_pay.visible, "the tutorial payment button is gone")

	await wait_seconds(0.3)
	hud.get_tab_button(MarketHud.TAB_UPGRADES).pressed.emit()
	var buy_bait := hud.upgrade_panel.get_buy_button(&"bait")
	var bait_price := GameData.get_upgrade(&"bait").get_price_for_level(0)
	check(not buy_bait.disabled, "bait level 1 is affordable")
	check(buy_bait.text.contains(Money.format_rp(bait_price)), "the button shows the exact price")
	var cash_before := GameState.get_cash()
	buy_bait.pressed.emit()
	check_eq(GameState.get_upgrade_level(&"bait"), 1, "bait is level 1")
	check_eq(GameState.get_cash(), cash_before - bait_price, "the exact price was charged")
	buy_bait.pressed.emit()
	check_eq(GameState.get_upgrade_level(&"bait"), 1, "a double tap does not buy twice")

	(scene.get_node(LEDGER + "LeaveMarketButton") as BaseButton).pressed.emit()
	check(await wait_until(func() -> bool: return _finished_transitions.count(&"fishing") >= 2, BOOT_TIMEOUT_SEC), "LEAVE MARKET returns to the lake")
	var saved: Dictionary = read_json(SaveManager.get_save_path())
	check_eq(saved["cash"], GameState.get_cash(), "cash survived the visit")
	check_eq(saved["debt"]["paid"], 10000, "the payment is in the save")
	check_eq(saved["upgrades"]["bait"], 1, "the upgrade is in the save")
	check_eq(saved["tutorials"]["market_seen"], true, "the tutorial flag is in the save")
	check_eq(AudioManager.get_ambience_state(), &"lake", "back to the lake ambience")
	return true


# STORY-004 / BOOK-001 in the real scene: the event resolves on the way out.
func test_leaving_the_market_announces_the_fish_book() -> bool:
	if not check(await _enter_market(), "reach the Market"):
		return true
	var scene := tree.current_scene
	var hud := scene.get_node("MarketCanvas") as MarketHud
	var controller := scene.get_node("MarketController") as MarketController
	var notice := scene.get_node("NoticeDialog") as ModalDialog
	hud.get_tab_button(MarketHud.TAB_FISH_BOOK).pressed.emit()
	await wait_frames(2)
	check_eq(hud.fish_book_panel.body.get_child_count(), 1, "the Fish Book is closed before the story opens it")

	GameState.debug_set_cash(600000)
	check_eq(controller.pay_debt(600000), 600000, "pay Rp 600,000")
	check(not notice.is_open(), "no story interrupts the visit itself")
	(scene.get_node(LEDGER + "LeaveMarketButton") as BaseButton).pressed.emit()
	check(await wait_until(notice.is_open, 3.0), "leaving shows the Fish Book notice")
	check(bool(GameState.get_story_value(&"fish_book_unlocked")), "the Fish Book is unlocked")
	check(StoryDirector.is_event_seen(&"story_debt_600k"), "the 600k event was this visit's event")
	check(StoryDirector.get_pending_events().has(&"story_debt_300k"), "the smaller milestones wait for another visit")
	check(_finished_transitions.count(&"fishing") < 2, "the lake waits for the notice")
	notice.footer.get_child(0).pressed.emit()
	check(await wait_until(func() -> bool: return _finished_transitions.count(&"fishing") >= 2, BOOT_TIMEOUT_SEC), "then the visit ends at the lake")
	return true


func test_market_pause_and_both_screen_shapes() -> bool:
	if not check(await _enter_market({&"catfish_bruiser": 1}), "reach the Market"):
		return true
	var scene := tree.current_scene
	var pause := scene.get_node("PauseOverlay") as PauseOverlay
	var safe_root := scene.get_node("MarketCanvas/SafeRoot") as Control
	var tabs := scene.get_node(LEDGER + "TabBar") as Control
	var page := scene.get_node(LEDGER + "TabContent") as Control
	var leave := scene.get_node(LEDGER + "LeaveMarketButton") as Control
	var camera := scene.get_node("World/MarketCamera") as Camera3D
	var markers := scene.get_node("World/MarketSet/Markers")

	InputManager.press_action(InputActions.PAUSE)
	check(await wait_until(pause.is_open, 2.0), "the pause action opens the pause menu")
	check(tree.paused, "the Market is paused")
	InputManager.release_action(InputActions.PAUSE)
	pause.resume()
	check(not tree.paused, "resume unpauses the Market")

	var window := tree.root
	var original_size := window.size
	for shape: Array in [[Vector2i(1280, 720), "CameraLandscape"], [Vector2i(720, 1280), "CameraPortrait"]]:
		var size: Vector2i = shape[0]
		window.size = size
		await wait_frames(4)
		var bounds := safe_root.get_global_rect().grow(1.0)
		var label := "%dx%d" % [size.x, size.y]
		check(bounds.encloses(tabs.get_global_rect()), "%s: tabs are inside the safe area" % label)
		check(bounds.encloses(page.get_global_rect()), "%s: the ledger page is inside the safe area" % label)
		check(bounds.encloses(leave.get_global_rect()), "%s: LEAVE MARKET is inside the safe area" % label)
		check(not page.get_global_rect().intersects(leave.get_global_rect()), "%s: LEAVE MARKET is not under the ledger" % label)
		check(tabs.get_global_rect().end.y <= page.get_global_rect().position.y + 3.0, "%s: tabs sit on top of the page" % label)
		check(page.size.y >= 320.0, "%s: the page has room to work in (%d px)" % [label, int(page.size.y)])
		check(camera.transform.is_equal_approx((markers.get_node(shape[1]) as Node3D).transform), "%s: camera uses %s" % [label, shape[1]])
	window.size = original_size
	await wait_frames(3)
	return true


# --- Boxing (GDD 168.7, 94, 176.10, 176.14) ---------------------------------

const RING := "BoxingCanvas/SafeRoot/"


## From the lake, hand a hooked fish to the boxing ring.
func _enter_boxing(fish_id: StringName) -> bool:
	if not await _enter_lake():
		return false
	var fish := GameData.get_fish(fish_id)
	GameState.record_encounter(fish_id)
	GameState.current_fish = fish_id
	GameState.current_duel = &"boxing"
	GameState.current_catch = {"fish_id": fish_id, "weight_kg": fish.weight_min_kg, "is_big_one": false, "seed": 9}
	SceneRouter.goto_duel(&"boxing", fish_id)
	var reached := await wait_until(func() -> bool: return _finished_transitions.has(&"boxing"), BOOT_TIMEOUT_SEC)
	await wait_frames(3)
	return reached and tree.current_scene != null and tree.current_scene.name == &"Boxing"


func test_boxing_scene_follows_the_scene_blueprint() -> bool:
	if not check(await _enter_boxing(&"tilapia_gym_rat"), "a hooked fish reaches the ring"):
		return true
	var scene := tree.current_scene
	for path: String in [
		"BoxingController", "World/BoxingSet", "World/DartoFighter", "World/FishFighter", "World/BoxingCamera",
		RING + "PlayerHP", RING + "FishHP", RING + "RoundTimer", RING + "TelegraphWidget",
		RING + "MobileControls/DodgeLeftButton", RING + "MobileControls/DodgeRightButton",
		RING + "MobileControls/JabButton", RING + "MobileControls/CrossButton", "PauseOverlay",
	]:
		check(scene.has_node(path), "node %s exists (GDD 168.7)" % path)

	var controller := scene.get_node("BoxingController") as BoxingController
	var world := scene.get_node("World") as BoxingWorld
	var hud := scene.get_node("BoxingCanvas") as BoxingHud
	var snapshot := controller.get_snapshot()
	check_eq(snapshot["fish_id"], &"tilapia_gym_rat", "the ring holds the fish that was hooked")
	check_eq(snapshot["fish_max_hp"], 90.0, "Gym-Rat Tilapia has 90 HP")
	check_eq(snapshot["player_max_hp"], 100.0, "Darto has 100 HP without Tonic")
	check((scene.get_node(RING + "FishHP/Name") as Label).text == "GYM-RAT TILAPIA", "the fish is named on its HP bar")
	check(world.get_fish_rig() != null and world.get_fish_rig().get_parent() == scene.get_node("World/FishFighter"), "the fish stands in the ring")
	check((world.get_fish_rig().get_node("AccessoryMeshes/Gloves") as Node3D).visible, "the fish wears its gloves")
	check((scene.get_node("World/DartoFighter/Rig/AccessoryMeshes/BoxingGloves") as Node3D).visible, "Darto wears his gloves")
	check_eq(world.get_fish_clip(), &"box_idle", "the fish starts in its guard")
	check((scene.get_node("World/BoxingCamera") as Camera3D).current, "the boxing camera is live")
	check_eq(hud.get_shown_hp(), Vector2(100.0, 90.0), "both HP bars start full")
	check(InputManager.is_gameplay_input_enabled(), "gameplay input is live")
	check(not GameState.is_tutorial_seen(&"boxing_seen") and hud.get_hint_text() != "", "the first duel shows guidance")
	return true


# Exit gate: a catch at the lake is boxed, won and ends up in the Bucket.
func test_first_catch_is_boxed_and_a_win_fills_the_bucket() -> bool:
	if not check(await _enter_lake(), "New Game reaches the lake"):
		return true
	DebugService.set_fast_wait(true)
	DebugService.set_auto_reel(true)
	DebugService.set_auto_duel(true)
	var fishing := tree.current_scene.get_node("FishingController") as FishingController
	InputManager.press_action(&"fish_cast")
	InputManager.release_action(&"fish_cast")
	check(await wait_until(func() -> bool: return fishing.get_state() == FishingController.STATE_STRIKE_WINDOW, 8.0), "a bite arrives")
	InputManager.press_action(&"fish_cast")
	InputManager.release_action(&"fish_cast")
	check(await wait_until(func() -> bool: return _finished_transitions.has(&"boxing"), 60.0), "the landed fish is taken to the ring")
	await wait_frames(3)
	var scene := tree.current_scene
	if not check(scene != null and scene.name == &"Boxing", "the Boxing scene is up"):
		return true
	var controller := scene.get_node("BoxingController") as BoxingController
	var overlay := scene.get_node("ResultOverlay") as DuelResultOverlay
	check_eq(controller.get_snapshot()["fish_id"], &"catfish_bruiser", "the first fish is Bruiser Catfish, and the first duel is Boxing")
	check_eq(GameState.get_bucket_quantity(&"catfish_bruiser"), 0, "a hooked fish is not in the Bucket yet")

	check(await wait_until(func() -> bool: return controller.get_state() == BoxingController.STATE_FINISHED, 70.0), "the fight ends")
	check(controller.get_result()["player_won"], "the bot beats the catfish")
	check(await wait_until(overlay.is_open, 5.0), "the result is shown")
	check_eq(overlay.get_title_text(), TextDb.t(&"duel.result.win.title"), "YOU WIN")
	check_eq(GameState.get_bucket_quantity(&"catfish_bruiser"), 1, "the catfish is in the Bucket")
	check(GameState.is_tutorial_seen(&"boxing_seen"), "the boxing lesson is done")
	check_eq(GameState.get_stat(&"boxing_wins"), 1, "one boxing win")
	check(GameState.is_fish_discovered(&"catfish_bruiser"), "the Fish Book entry opened")
	var saved: Dictionary = read_json(SaveManager.get_save_path())
	check_eq(saved["bucket"]["catfish_bruiser"], 1, "the result was saved")

	overlay.footer.get_child(0).pressed.emit()
	check(await wait_until(func() -> bool: return _finished_transitions.count(&"fishing") >= 2, BOOT_TIMEOUT_SEC), "CONTINUE returns to the lake")
	check_eq(GameState.current_catch, {}, "no catch is pending any more")
	DebugService.clear_forces()
	return true


# GDD 176.10 and 176.11: the lesson can be lost for free; a real loss costs the fish only.
func test_losing_the_lesson_is_a_retry_and_a_real_loss_costs_only_the_fish() -> bool:
	DebugService.set_forced_result(&"loss")
	if not check(await _enter_boxing(&"catfish_bruiser"), "reach the ring"):
		return true
	var scene := tree.current_scene
	var controller := scene.get_node("BoxingController") as BoxingController
	var overlay := scene.get_node("ResultOverlay") as DuelResultOverlay
	check(await wait_until(overlay.is_open, 8.0), "losing the first duel shows the retry")
	check_eq(overlay.get_title_text(), TextDb.t(&"duel.result.retry.title"), "it is the retry, not a loss")
	check_eq(GameState.get_stat(&"duel_losses"), 0, "nothing was recorded")
	check_eq(GameState.get_fish_book_entry(&"catfish_bruiser")["losses"], 0, "no Fish Book loss")
	check_eq(GameState.current_fish, &"catfish_bruiser", "the fish is still on its stool")

	DebugService.clear_forces()
	overlay.footer.get_child(0).pressed.emit()
	check(await wait_until(func() -> bool: return controller.get_state() == BoxingController.STATE_INTRO or controller.get_state() == BoxingController.STATE_FIGHTING, 3.0), "the duel starts again")
	check_eq(controller.get_snapshot()["player_hp"], 100.0, "with full HP")

	# Past the lesson a loss is a loss: the fish leaves, everything else stays.
	GameState.set_tutorial_seen(&"boxing_seen")
	GameState.add_bucket_item(&"trash_can", 2)
	var cash := GameState.get_cash()
	DebugService.set_forced_result(&"loss")
	GameState.record_encounter(&"carp_golden")
	GameState.current_fish = &"carp_golden"
	GameState.current_catch = {"fish_id": &"carp_golden", "weight_kg": 2.0, "is_big_one": false, "seed": 3}
	SceneRouter.goto_duel(&"boxing", &"carp_golden")
	if not check(await wait_until(func() -> bool: return _finished_transitions.count(&"boxing") >= 2, BOOT_TIMEOUT_SEC), "a second fish reaches the ring"):
		return true
	await wait_frames(3)
	scene = tree.current_scene
	overlay = scene.get_node("ResultOverlay") as DuelResultOverlay
	check(await wait_until(overlay.is_open, 8.0), "the result is shown")
	check_eq(overlay.get_title_text(), TextDb.t(&"duel.result.loss.title"), "THE FISH GOT AWAY")
	check_eq(GameState.get_bucket_quantity(&"carp_golden"), 0, "the carp is gone")
	check_eq(GameState.get_stat(&"duel_losses"), 1, "the loss is recorded")
	check_eq(GameState.get_cash(), cash, "no cash lost")
	overlay.footer.get_child(0).pressed.emit()
	check(await wait_until(func() -> bool: return _finished_transitions.count(&"fishing") >= 2, BOOT_TIMEOUT_SEC), "back to the lake")
	DebugService.clear_forces()
	return true


# BOX-004, BOX-013 and input parity through the real scene.
func test_boxing_inputs_pause_and_both_screen_shapes() -> bool:
	DebugService.set_forced_attack_direction(&"right")
	if not check(await _enter_boxing(&"catfish_bruiser"), "reach the ring"):
		return true
	var scene := tree.current_scene
	var controller := scene.get_node("BoxingController") as BoxingController
	var world := scene.get_node("World") as BoxingWorld
	var hud := scene.get_node("BoxingCanvas") as BoxingHud
	var pause := scene.get_node("PauseOverlay") as PauseOverlay
	var widget := hud.get_widget()

	check(await wait_until(func() -> bool: return controller.get_snapshot()["attack_direction"] != &"", 6.0), "the fish winds up")
	await wait_frames(2)
	check_eq(world.get_fish_clip(), BoxingWorld.get_attack_clip(&"right", int(controller.get_snapshot()["attack_variant"])), "a dodge-right attack plays the mirrored clip")
	check(String(world.get_fish_clip()).ends_with(BoxingWorld.MIRROR_SUFFIX), "which is the mirror of the dodge-left one")
	check_eq(widget.get_shown_direction(), &"right", "the read-out shows the dodge direction")
	check_eq(widget.get_prompt_text(), TextDb.t(&"boxing.prompt.dodge_right"), "and says it in words")

	# A blocked punch during the wind-up must not hide the attack.
	var attack_clip := world.get_fish_clip()
	InputManager.press_action(&"box_jab")
	InputManager.release_action(&"box_jab")
	await wait_seconds(0.2)
	if controller.get_snapshot()["attack_direction"] != &"":
		check_eq(world.get_fish_clip(), attack_clip, "the wind-up keeps playing through a blocked jab")
	check(await wait_until(func() -> bool: return float(controller.get_snapshot()["player_hp"]) < 100.0, 3.0), "punching through the telegraph gets Darto hit")

	# Pause stops the clock; the dodge action answers the next attack.
	InputManager.press_action(InputActions.PAUSE)
	check(await wait_until(pause.is_open, 2.0), "the pause action opens the pause menu")
	InputManager.release_action(InputActions.PAUSE)
	var frozen: float = controller.get_snapshot()["time_left"]
	await wait_seconds(0.4)
	check_eq(controller.get_snapshot()["time_left"], frozen, "the round clock is frozen while paused")
	pause.resume()

	check(await wait_until(func() -> bool: return controller.get_snapshot()["attack_direction"] != &"", 6.0), "the fish winds up again")
	InputManager.press_action(&"box_dodge_right")
	InputManager.release_action(&"box_dodge_right")
	check(await wait_until(func() -> bool: return controller.get_snapshot()["counter_open"], 3.0), "the dodge action opens the counter window")
	await wait_frames(2)
	check(widget.get_prompt_text() == TextDb.t(&"boxing.prompt.counter") or widget.get_prompt_text() == TextDb.t(&"boxing.prompt.perfect"), "the read-out says COUNTER")
	var fish_hp: float = controller.get_snapshot()["fish_hp"]
	InputManager.press_action(&"box_cross")
	InputManager.release_action(&"box_cross")
	check(await wait_until(func() -> bool: return float(controller.get_snapshot()["fish_hp"]) <= fish_hp - 36.0 + 0.001, 2.0), "the cross action lands a counter")

	# BOX-013: four controls, none overlapping, all inside the safe area.
	var safe_root := scene.get_node("BoxingCanvas/SafeRoot") as Control
	var controls: Array[Control] = []
	for button: String in ["DodgeLeftButton", "DodgeRightButton", "JabButton", "CrossButton"]:
		controls.append(scene.get_node(RING + "MobileControls/" + button) as Control)
	var window := tree.root
	var original_size := window.size
	window.size = Vector2i(720, 1280)
	await wait_frames(4)
	check(hud.uses_touch_layout() and (scene.get_node(RING + "MobileControls") as Control).visible, "portrait shows the four touch controls")
	var bounds := safe_root.get_global_rect().grow(1.0)
	var fight_bottom := safe_root.get_global_rect().position.y + safe_root.size.y * BoxingHud.FIGHT_SHARE_PORTRAIT
	for index: int in controls.size():
		var rect := controls[index].get_global_rect()
		check(bounds.encloses(rect), "%s is inside the safe area" % controls[index].name)
		check(rect.position.y >= fight_bottom, "%s stays under the fight (GDD 94)" % controls[index].name)
		check(rect.size.x >= 48.0 and rect.size.y >= 48.0, "%s is a real touch target" % controls[index].name)
		for other: int in range(index + 1, controls.size()):
			check(not rect.intersects(controls[other].get_global_rect()), "%s and %s do not overlap" % [controls[index].name, controls[other].name])
	check(controls[0].get_global_rect().end.x <= controls[2].get_global_rect().position.x, "dodge on the left, punches on the right")
	var widget_rect := widget.get_global_rect()
	check(widget_rect.end.y <= fight_bottom, "the telegraph read-out is in the fight area")
	var camera := scene.get_node("World/BoxingCamera") as Camera3D
	check(camera.transform.is_equal_approx((scene.get_node("World/BoxingSet/Markers/CameraPortrait") as Node3D).transform), "portrait uses its own camera")
	window.size = original_size
	await wait_frames(3)
	DebugService.clear_forces()
	return true


# --- Arm wrestling (GDD 168.8, 95, 176.13) ----------------------------------

const TABLE := "ArmCanvas/SafeRoot/"


## From the lake, hand a hooked fish to any duel scene.
func _enter_duel(duel_id: StringName, fish_id: StringName) -> bool:
	if not await _enter_lake():
		return false
	GameState.set_tutorial_seen(&"boxing_seen")
	var fish := GameData.get_fish(fish_id)
	GameState.record_encounter(fish_id)
	GameState.current_fish = fish_id
	GameState.current_duel = duel_id
	GameState.current_catch = {"fish_id": fish_id, "weight_kg": fish.weight_min_kg, "is_big_one": false, "seed": 9}
	SceneRouter.goto_duel(duel_id, fish_id)
	var reached := await wait_until(func() -> bool: return _finished_transitions.has(duel_id), BOOT_TIMEOUT_SEC)
	await wait_frames(3)
	return reached and tree.current_scene != null


func test_arm_wrestle_scene_follows_the_blueprint_and_plays() -> bool:
	if not check(await _enter_duel(&"arm_wrestle", &"gourami_shady"), "a hooked fish reaches the table"):
		return true
	var scene := tree.current_scene
	check_eq(scene.name, &"ArmWrestle", "the Arm Wrestling scene is up")
	for path: String in [
		"ArmWrestleController", "World/ArmWrestleSet", "World/DartoArmRig", "World/FishArmRig", "World/ArmCamera",
		TABLE + "PositionBar", TABLE + "StaminaBar", TABLE + "RoundTimer", TABLE + "BurstWarning", TABLE + "MashButton",
		"PauseOverlay",
	]:
		check(scene.has_node(path), "node %s exists (GDD 168.8)" % path)
	var controller := scene.get_node("ArmWrestleController") as ArmWrestleController
	var world := scene.get_node("World") as ArmWrestleWorld
	var hud := scene.get_node("ArmCanvas") as ArmWrestleHud
	check_eq(controller.get_snapshot()["fish_id"], &"gourami_shady", "the table holds the fish that was hooked")
	check(await wait_until(func() -> bool: return controller.get_state() == ArmWrestleController.STATE_PULLING, 3.0), "the pull starts")

	# The MASH action and the touch button are the same input.
	var start: float = controller.get_snapshot()["position"]
	for _press: int in 3:
		InputManager.press_action(&"arm_mash")
		await wait_frames(1)
		InputManager.release_action(&"arm_mash")
		await wait_seconds(0.12)
	check(controller.get_snapshot()["stamina"] < 100.0, "the MASH action is accepted")
	var mash := scene.get_node(TABLE + "MashButton") as BaseButton
	var stamina: float = controller.get_snapshot()["stamina"]
	mash.button_down.emit()
	await wait_frames(2)
	mash.button_up.emit()
	check(float(controller.get_snapshot()["stamina"]) < stamina, "the MASH button presses the same action")
	check(world.get_darto_clip() == &"arm_push_hard" or world.get_darto_clip() == &"arm_push_light", "Darto pushes while pressing")
	check(not (world.get_fish_rig_node().get_node("AccessoryMeshes/Gloves") as Node3D).visible, "no gloves at the table")

	# The hands lean the way the bar moves.
	await wait_seconds(1.5)
	var position: float = controller.get_snapshot()["position"]
	check(signf(world.get_shown_lean()) == signf(position) or absf(position) < 1.0, "the arm leans to the side the bar shows")
	var bar := hud.get_position_bar()
	check((bar.get_marker_ratio() < 0.5) == (position > 0.0) or absf(position) < 0.5, "Darto winning moves the marker toward his end")

	# Pause stops the clock.
	InputManager.press_action(InputActions.PAUSE)
	var pause := scene.get_node("PauseOverlay") as PauseOverlay
	check(await wait_until(pause.is_open, 2.0), "the pause action opens the pause menu")
	InputManager.release_action(InputActions.PAUSE)
	var frozen: float = controller.get_snapshot()["time_left"]
	await wait_seconds(0.4)
	check_eq(controller.get_snapshot()["time_left"], frozen, "the round clock is frozen while paused")
	pause.resume()

	# A bot finishes it; the shared result flow takes over.
	DebugService.set_auto_duel(true)
	var overlay := scene.get_node("ResultOverlay") as DuelResultOverlay
	check(await wait_until(overlay.is_open, 40.0), "the match ends and the result is shown")
	check(controller.get_result()["player_won"], "a steady seven taps a second beats the gourami")
	check_eq(GameState.get_bucket_quantity(&"gourami_shady"), 1, "the gourami is in the Bucket")
	check_eq(GameState.get_stat(&"arm_wrestle_wins"), 1, "one arm wrestling win")
	check(GameState.is_tutorial_seen(&"arm_wrestle_seen"), "the arm wrestling hint is done")
	overlay.footer.get_child(0).pressed.emit()
	check(await wait_until(func() -> bool: return _finished_transitions.count(&"fishing") >= 2, BOOT_TIMEOUT_SEC), "CONTINUE returns to the lake")
	DebugService.clear_forces()
	return true


# ARM-012 (automatic part) and GDD Section 95.
func test_arm_wrestle_portrait_layout() -> bool:
	if not check(await _enter_duel(&"arm_wrestle", &"catfish_bruiser"), "reach the table"):
		return true
	var scene := tree.current_scene
	var hud := scene.get_node("ArmCanvas") as ArmWrestleHud
	var safe_root := scene.get_node("ArmCanvas/SafeRoot") as Control
	var window := tree.root
	var original_size := window.size
	window.size = Vector2i(720, 1280)
	await wait_frames(4)
	var area := safe_root.get_global_rect()
	var mash := (scene.get_node(TABLE + "MashButton") as Control).get_global_rect()
	var bar := (scene.get_node(TABLE + "PositionBar") as Control).get_global_rect()
	check(hud.uses_touch_layout() and (scene.get_node(TABLE + "MashButton") as Control).visible, "portrait shows the MASH button")
	check(mash.position.y >= area.position.y + area.size.y * 0.69, "MASH fills the bottom 30%")
	check(mash.size.x >= area.size.x - 2.0 and mash.size.y >= 200.0, "MASH is one large target (%dx%d)" % [int(mash.size.x), int(mash.size.y)])
	check(area.grow(1.0).encloses(mash), "MASH is inside the safe area")
	check(bar.position.y >= area.position.y + area.size.y * 0.55 and bar.end.y <= mash.position.y, "the bars sit in the middle, above MASH")
	check(not bar.intersects(mash), "the bars and MASH do not overlap")
	var camera := scene.get_node("World/ArmCamera") as Camera3D
	check(camera.transform.is_equal_approx((scene.get_node("World/ArmWrestleSet/Markers/CameraPortrait") as Node3D).transform), "portrait uses its own camera")
	window.size = original_size
	await wait_frames(3)
	return true
