extends "res://tests/test_suite.gd"
## Accessibility Bible 2.0 and display settings (GDD 189, 190.1; QA matrix
## A11Y-001..012): what can be checked by the machine is checked here.

const STORAGE_DIR := "user://test_tmp/accessibility"
const TICK := ArmWrestleController.TICK_SEC
const SCENE_TIMEOUT_SEC := 20.0

var _finished_transitions: Array[StringName] = []


func get_suite_name() -> String:
	return "a11y"


func before_all() -> void:
	SceneRouter.transition_finished.connect(_on_transition_finished)


func after_all() -> void:
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), SCENE_TIMEOUT_SEC)
	SceneRouter.transition_finished.disconnect(_on_transition_finished)
	if tree.current_scene != null:
		tree.current_scene.queue_free()
		await wait_frames(2)
	GameState.clear_game()
	DebugService.clear_dev_dirty()
	DisplaySettings.apply_all(tree)
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


func before_each() -> void:
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), SCENE_TIMEOUT_SEC)
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)
	DebugService.clear_dev_dirty()
	GameState.clear_game()
	GameState.new_game()
	DisplaySettings.apply_all(tree)
	_finished_transitions.clear()


func _on_transition_finished(scene_id: StringName) -> void:
	_finished_transitions.append(scene_id)


func _settings() -> SettingsOverlay:
	var overlay := SettingsOverlay.new()
	tree.root.add_child(overlay)
	return overlay


# --- Settings screen (GDD 189.1) -------------------------------------------

func test_every_required_setting_is_on_the_settings_screen() -> bool:
	var overlay := _settings()
	await wait_frames(1)
	for key: StringName in SettingsOverlay.ACCESSIBILITY_OPTIONS:
		check(overlay.get_option_button(key) != null, "%s has a row" % key)
	check(overlay.get_option_button(&"quality_preset") != null, "graphics quality has a row")
	check(overlay.find_child("BeatPulseToggle", true, false) != null, "rhythm beat pulse")
	check(overlay.find_child("CalibrateButton", true, false) != null, "rhythm calibration")
	check(overlay.find_child("ControlsButton", true, false) != null, "keyboard controls (desktop and Web)")
	overlay.queue_free()
	await wait_frames(1)
	return true


func test_option_rows_cycle_and_autosave() -> bool:
	# Settings are written into an existing save (GDD 189.1).
	check(SaveManager.save_game(&"test"), "a save exists")
	var overlay := _settings()
	overlay.open()
	await wait_frames(2)
	var button := overlay.get_option_button(&"text_scale")
	check_eq(button.text, "100%", "text scale starts at 100%")
	button.pressed.emit()
	check_near(float(GameState.get_setting(&"text_scale")), 1.15, 0.001, "one press moves to 115%")
	check_eq(button.text, "115%", "and the button says so")
	for _press: int in 3:
		button.pressed.emit()
	check_near(float(GameState.get_setting(&"text_scale")), 1.0, 0.001, "it wraps back to 100%")
	overlay.get_option_button(&"dialogue_speed").pressed.emit()
	check_eq(GameState.get_setting(&"dialogue_speed"), "relaxed", "NORMAL -> RELAXED")
	var saved_speed := func() -> bool:
		var saved: Variant = read_json(SaveManager.get_save_path())
		return typeof(saved) == TYPE_DICTIONARY and saved["settings"]["dialogue_speed"] == "relaxed"
	check(await wait_until(saved_speed, 3.0), "the change is autosaved")
	overlay.queue_free()
	await wait_frames(1)
	return true


# --- UI and text scale (GDD 189.2, 189.3; A11Y-001, A11Y-002) ---------------

func test_ui_scale_scales_controls_not_the_world() -> bool:
	GameState.set_setting(&"ui_scale", 1.3)
	DisplaySettings.apply_all(tree)
	check_near(tree.root.content_scale_factor, 1.3, 0.001, "controls scale to 130%")
	GameState.set_setting(&"ui_scale", 1.0)
	DisplaySettings.apply_all(tree)
	check_near(tree.root.content_scale_factor, 1.0, 0.001, "and back")
	return true


func test_text_scale_scales_the_theme() -> bool:
	var theme := ThemeDB.get_project_theme()
	var base := theme.get_font_size(&"font_size", &"Button")
	GameState.set_setting(&"text_scale", 1.5)
	DisplaySettings.apply_text_scale()
	check_eq(theme.get_font_size(&"font_size", &"Button"), roundi(base * 1.5), "button text at 150%")
	check_eq(DisplaySettings.text_size(20), 30, "sizes set in code follow")
	GameState.set_setting(&"text_scale", 1.0)
	DisplaySettings.apply_text_scale()
	check_eq(theme.get_font_size(&"font_size", &"Button"), base, "and return exactly")
	return true


# A11Y-001, A11Y-002: the screens with critical buttons at the largest sizes.
func test_largest_scales_keep_critical_buttons_whole() -> bool:
	GameState.set_setting(&"ui_scale", 1.3)
	GameState.set_setting(&"text_scale", 1.5)
	DisplaySettings.apply_all(tree)
	var problems := PackedStringArray()
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(720, 1280)]:
		tree.root.size = size
		for scene_path: String in ["res://scenes/menu/main_menu.tscn", "res://scenes/fishing/fishing.tscn", "res://scenes/market/market.tscn"]:
			tree.change_scene_to_packed(load(scene_path))
			await wait_frames(6)
			var visible_rect := Rect2(Vector2.ZERO, tree.root.get_visible_rect().size)
			for button: Node in tree.current_scene.find_children("*", "Button", true, false):
				var control := button as Button
				if not control.is_visible_in_tree() or control.text == "":
					continue
				var rect := control.get_global_rect()
				if not visible_rect.grow(1.0).encloses(rect):
					problems.append("%s %s: %s is off screen" % [scene_path.get_file(), size, control.name])
				var font := control.get_theme_font(&"font")
				var font_size := control.get_theme_font_size(&"font_size")
				var text_width := font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				if not control.clip_text and text_width > rect.size.x + 1.0 and control.autowrap_mode == TextServer.AUTOWRAP_OFF:
					problems.append("%s %s: %s text is wider than the button" % [scene_path.get_file(), size, control.name])
	check_empty(problems, "critical buttons stay on screen and whole at 130% UI and 150% text")
	tree.root.size = Vector2i(1280, 720)
	GameState.set_setting(&"ui_scale", 1.0)
	GameState.set_setting(&"text_scale", 1.0)
	DisplaySettings.apply_all(tree)
	tree.current_scene.queue_free()
	await wait_frames(2)
	return true


# --- High contrast, shake, flash (A11Y-003, A11Y-004, A11Y-006) -------------

func test_high_contrast_strengthens_the_hud() -> bool:
	var normal := HudChip.make_style()
	GameState.set_setting(&"high_contrast_hud", true)
	var strong := HudChip.make_style()
	check(strong.bg_color.a > normal.bg_color.a, "panels are more opaque")
	check(strong.border_width_left > normal.border_width_left, "borders are thicker")
	check_eq(UiTokens.hud_border(2), 4, "HUD borders gain two pixels")
	var label := Label.new()
	UiTokens.outline_text(label, 20)
	check(label.get_theme_constant(&"outline_size") > 9, "outlined text gets a stronger outline")
	label.free()
	GameState.set_setting(&"high_contrast_hud", false)
	return true


# --- Arm wrestling Hold Assist (A11Y-008) -------------------------------------

func test_hold_assist_makes_eight_pushes_a_second() -> bool:
	var assist := HoldAssist.new()
	var pushes := 0
	for _tick: int in roundi(1.0 / TICK):
		pushes += assist.step(true, TICK)
	check(pushes >= 8 and pushes <= 9, "about eight pushes in a held second (%d)" % pushes)
	check_eq(assist.step(false, TICK), 0, "nothing when released")
	check_eq(assist.step(true, TICK), 1, "a new hold pushes at once")
	return true


func test_hold_assist_beats_every_fish_with_the_same_costs() -> bool:
	for fish: FishData in GameData.get_all_fish():
		var arm := ArmWrestleController.new()
		arm.auto_advance = false
		arm.start_duel(fish.id, 4242 + fish.tier)
		for _tick: int in roundi((ArmWrestleController.INTRO_SEC + TICK) / TICK):
			arm.advance(TICK)
		var assist := HoldAssist.new()
		for _tick: int in roundi(120.0 / TICK):
			if arm.get_state() == ArmWrestleController.STATE_FINISHED:
				break
			for push: int in assist.step(true, TICK):
				arm.request_mash()
			arm.advance(TICK)
		check(arm.get_state() == ArmWrestleController.STATE_FINISHED and arm.get_result()["player_won"], "%s can be beaten by holding" % fish.id)
		arm.free()
	# One assisted push costs what one press costs.
	var costs: Array[float] = []
	for assisted: bool in [false, true]:
		var arm := ArmWrestleController.new()
		arm.auto_advance = false
		arm.start_duel(&"catfish_bruiser", 7)
		for _tick: int in roundi((ArmWrestleController.INTRO_SEC + TICK) / TICK):
			arm.advance(TICK)
		var before := float(arm.get_snapshot()["stamina"])
		if assisted:
			for push: int in HoldAssist.new().step(true, 0.0):
				arm.request_mash()
		else:
			arm.request_mash()
		costs.append(before - float(arm.get_snapshot()["stamina"]))
		arm.free()
	check_near(costs[1], costs[0], 0.0001, "an assisted push costs the same stamina")
	return true


# --- Handedness (A11Y-009) --------------------------------------------------

func test_left_handed_boxing_swaps_the_groups_inside_the_safe_area() -> bool:
	GameState.set_setting(&"mobile_handedness", "left")
	tree.root.size = Vector2i(720, 1280)
	DebugService.set_forced_fish(&"catfish_bruiser")
	GameState.current_catch = {"fish_id": &"catfish_bruiser", "weight_kg": 2.0, "is_big_one": false, "seed": 3}
	SceneRouter.goto_duel(&"boxing", &"catfish_bruiser")
	if not check(await wait_until(func() -> bool: return _finished_transitions.has(&"boxing"), SCENE_TIMEOUT_SEC), "reach boxing"):
		return true
	await wait_frames(4)
	var controls := tree.current_scene.find_child("MobileControls", true, false) as Control
	var dodge_left := controls.get_node("DodgeLeftButton") as Control
	var dodge_right := controls.get_node("DodgeRightButton") as Control
	var jab := controls.get_node("JabButton") as Control
	check(jab.position.x < dodge_left.position.x, "punches move to the left thumb")
	check(dodge_left.position.x < dodge_right.position.x, "DODGE LEFT is still the left one of the pair")
	var safe := Rect2(PlatformService.get_safe_rect())
	for button: Control in [dodge_left, dodge_right, jab]:
		check(safe.grow(1.0).encloses(button.get_global_rect()), "%s stays in the safe area" % button.name)
	GameState.set_setting(&"mobile_handedness", "right")
	tree.root.size = Vector2i(1280, 720)
	DebugService.clear_forces()
	SceneRouter.goto_main_menu()
	await wait_until(func() -> bool: return _finished_transitions.has(&"main_menu"), SCENE_TIMEOUT_SEC)
	return true


# --- Keyboard remapping (A11Y-010) ------------------------------------------

func test_remap_conflicts_swap_or_cancel() -> bool:
	var jab_key := InputRemap.tokens_for(&"box_jab")[0]
	var cross_key := InputRemap.tokens_for(&"box_cross")[0]
	check_eq(InputRemap.find_conflict(&"box_jab", cross_key), &"box_cross", "taking CROSS's key is a conflict")
	check_eq(InputRemap.find_conflict(&"box_jab", "key:%d" % KEY_F1), &"", "a free key is not")
	check_eq(InputRemap.token_for_event(_key(KEY_F5)), "", "browser keys cannot be bound")
	var with_ctrl := _key(KEY_A)
	with_ctrl.ctrl_pressed = true
	check_eq(InputRemap.token_for_event(with_ctrl), "", "nor modifier combinations")

	var swapped := InputRemap.assign({}, &"box_jab", cross_key, &"box_cross")
	GameState.set_setting(&"input_remap", swapped)
	check_eq(InputRemap.tokens_for(&"box_jab")[0], cross_key, "JAB takes the key")
	check_eq(InputRemap.tokens_for(&"box_cross")[0], jab_key, "CROSS takes JAB's old key: nothing is left unbound")

	var cast_tokens := InputRemap.tokens_for(&"fish_cast")
	GameState.set_setting(&"input_remap", InputRemap.assign({}, &"fish_cast", "key:%d" % KEY_F1))
	var after := InputRemap.tokens_for(&"fish_cast")
	check(after.has("key:%d" % KEY_F1), "the cast key moved")
	for token: String in cast_tokens:
		if token.begins_with("mouse:"):
			check(after.has(token), "a click still casts")

	GameState.set_setting(&"input_remap", {})
	check_eq(InputRemap.tokens_for(&"box_jab")[0], jab_key, "RESET TO DEFAULTS restores the keys")
	return true


func test_controls_screen_captures_and_asks_on_conflict() -> bool:
	var overlay := ControlsOverlay.new()
	tree.root.add_child(overlay)
	overlay.open()
	await wait_frames(2)
	var cross_key := InputRemap.tokens_for(&"box_cross")[0]
	(overlay.find_child("Bind_box_jab", true, false) as BaseButton).pressed.emit()
	check_eq(overlay.is_capturing(), &"box_jab", "the row waits for a key")
	overlay.capture(cross_key)
	var dialog := overlay.find_child("ControlsDialog", true, false) as ModalDialog
	check(await wait_until(dialog.is_open, 2.0), "a used key asks before changing anything")
	check_eq(InputRemap.tokens_for(&"box_cross")[0], cross_key, "nothing changed yet")
	dialog.footer.get_child(0).pressed.emit()
	await wait_frames(2)
	check_eq(InputRemap.tokens_for(&"box_cross")[0], cross_key, "CANCEL keeps both keys")
	(overlay.find_child("ResetBindings", true, false) as BaseButton).pressed.emit()
	overlay.queue_free()
	await wait_frames(1)
	return true


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


# --- Dialogue (A11Y-012) and calibration (A11Y-007) --------------------------

func test_instant_dialogue_still_waits_for_the_player() -> bool:
	GameState.set_setting(&"dialogue_speed", "instant")
	var box := DialogueBox.new()
	tree.root.add_child(box)
	box.play([{"speaker": "DARTO", "text": "Square up."}, {"speaker": "DARTO", "text": "Please."}])
	await wait_seconds(0.5)
	check_eq(box.get_current_line().get("text", ""), "Square up.", "the line stays up")
	box.advance()
	check_eq(box.get_current_line().get("text", ""), "Please.", "an explicit advance moves on")
	box.skip()
	box.queue_free()
	GameState.set_setting(&"dialogue_speed", "normal")
	await wait_frames(1)
	return true


func test_relaxed_dialogue_is_slower_than_normal() -> bool:
	check(DialogueBox.CHARS_PER_SEC.has("relaxed"), "RELAXED has its own speed")
	check(float(DialogueBox.CHARS_PER_SEC["relaxed"]) < float(DialogueBox.CHARS_PER_SEC["normal"]), "and it is slower")
	return true


func test_rhythm_calibration_persists_after_reload() -> bool:
	GameState.set_setting(&"rhythm_input_offset_ms", -35)
	GameState.set_setting(&"rhythm_visual_offset_ms", 20)
	check(SaveManager.save_game(&"test"), "saved")
	GameState.clear_game()
	check(SaveManager.load_game(), "loaded")
	check_eq(GameState.get_setting(&"rhythm_input_offset_ms"), -35, "input offset kept")
	check_eq(GameState.get_setting(&"rhythm_visual_offset_ms"), 20, "visual offset kept")
	return true


# --- Graphics quality (GDD 190.1) ---------------------------------------------

func test_quality_presets_change_shadows_and_resolution_only() -> bool:
	tree.change_scene_to_packed(load("res://scenes/fishing/fishing.tscn"))
	await wait_frames(4)
	var suns := tree.current_scene.find_children("*", "DirectionalLight3D", true, false)
	check(not suns.is_empty(), "the lake has a sun")
	GameState.set_setting(&"quality_preset", "low")
	DisplaySettings.apply_all(tree)
	check(not (suns[0] as DirectionalLight3D).shadow_enabled, "LOW turns shadows off")
	check_near(tree.root.scaling_3d_scale, 0.75, 0.001, "and renders 3D at 75%")
	GameState.set_setting(&"quality_preset", "high")
	DisplaySettings.apply_all(tree)
	check((suns[0] as DirectionalLight3D).shadow_enabled, "HIGH has shadows")
	check_eq(tree.root.msaa_3d, Viewport.MSAA_2X, "and anti-aliasing")
	GameState.set_setting(&"quality_preset", "medium")
	DisplaySettings.apply_all(tree)
	check_eq(tree.root.msaa_3d, Viewport.MSAA_DISABLED, "MEDIUM is the default look")
	tree.current_scene.queue_free()
	await wait_frames(2)
	return true
