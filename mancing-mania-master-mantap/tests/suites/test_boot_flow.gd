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
