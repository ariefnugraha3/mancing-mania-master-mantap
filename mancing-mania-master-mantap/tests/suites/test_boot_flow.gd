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
	if SceneRouter.has_scene(SceneRouter.SCENE_FISHING):
		check(await wait_until(func() -> bool: return _finished_transitions.has(&"fishing"), BOOT_TIMEOUT_SEC), "New Game continues to the lake")
	else:
		check(_dialog().is_open(), "the build explains that the lake is not in this milestone")
		check(not _button("ContinueButton").disabled, "Continue became available")
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
