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


## GDD 167: the gold focus ring is for keyboard and gamepad players. A menu
## that opens after a tap or a click still has its button focused (Enter
## works) but shows no ring; after a key press it shows the ring.
func test_the_focus_ring_shows_only_for_keyboard_and_gamepad() -> bool:
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	InputManager._input(tap)
	check(not InputManager.is_keyboard_active(), "a click: not a keyboard player")
	var overlay := _settings()
	overlay.open()
	await wait_frames(3)
	var focused := tree.root.gui_get_focus_owner()
	check(focused != null and focused.has_focus(), "the first button has the focus, so Enter works")
	check(focused != null and not focused.has_focus(true), "but no ring is drawn for a tap or a click")
	overlay.hide_overlay()
	await wait_frames(1)

	var key := InputEventKey.new()
	key.keycode = KEY_SHIFT
	key.physical_keycode = KEY_SHIFT
	key.pressed = true
	InputManager._input(key)
	check(InputManager.is_keyboard_active(), "a key press: a keyboard player")
	overlay.open()
	await wait_frames(3)
	focused = tree.root.gui_get_focus_owner()
	check(focused != null and focused.has_focus(true), "now the ring shows")

	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	InputManager._input(tap)
	InputManager._input(pad)
	check(InputManager.is_keyboard_active(), "a gamepad button counts as keyboard navigation too")
	InputManager._input(tap)
	overlay.queue_free()
	await wait_frames(1)
	return true


## Revision 6.12: on a phone the Settings list scrolls under a finger from
## anywhere on it. Only the sliders keep the drag for themselves.
func test_a_finger_scrolls_the_settings_list_from_anywhere() -> bool:
	var overlay := _settings()
	overlay.open()
	await wait_frames(3)
	var scroll := overlay.find_child("Body", true, false) as ScrollContainer
	if not check(scroll != null, "the settings body scrolls"):
		overlay.queue_free()
		return true
	check(scroll.find_child("TouchScroll", false, false) is TouchScroll, "it follows a finger")
	check_eq(scroll.scroll_deadzone, TouchScroll.DEADZONE, "after the touch slop")
	var holding := PackedStringArray()
	for node: Node in scroll.find_children("*", "Control", true, false):
		if TouchScroll.should_pass(node as Control):
			holding.append(str(scroll.get_path_to(node)))
	check_empty(holding, "nothing in the list holds a drag back")
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


func _scroll_parent(control: Control) -> ScrollContainer:
	var node := control.get_parent()
	while node != null:
		if node is ScrollContainer:
			return node
		node = node.get_parent()
	return null


# A11Y-001, A11Y-002: the screens with critical buttons at the largest sizes,
# in every language (Indonesian labels run longer than English ones).
func test_largest_scales_keep_critical_buttons_whole() -> bool:
	GameState.set_setting(&"ui_scale", 1.3)
	GameState.set_setting(&"text_scale", 1.5)
	DisplaySettings.apply_all(tree)
	var problems := PackedStringArray()
	for language: String in TextDb.LANGUAGES:
		GameState.set_setting(&"language", language)
		# A small 9:16 phone, a tall phone and a tablet.
		for size: Vector2i in [Vector2i(720, 1280), Vector2i(1080, 2400), Vector2i(1536, 2048)]:
			tree.root.size = size
			for scene_path: String in ["res://scenes/menu/main_menu.tscn", "res://scenes/fishing/fishing.tscn", "res://scenes/market/market.tscn"]:
				tree.change_scene_to_packed(load(scene_path))
				await wait_frames(6)
				var where := "%s %s %s" % [language, scene_path.get_file(), size]
				var visible_rect := Rect2(Vector2.ZERO, tree.root.get_visible_rect().size)
				for button: Node in tree.current_scene.find_children("*", "Button", true, false):
					var control := button as Button
					if not control.is_visible_in_tree() or control.text == "":
						continue
					var rect := control.get_global_rect()
					# A button inside a scrolling page is reachable when the page
					# itself is on screen (the smallest phone at the largest sizes
					# scrolls the Market buttons with the list).
					var reach := rect
					var scroll := _scroll_parent(control)
					if scroll != null:
						reach = scroll.get_global_rect()
						if rect.size.x > reach.size.x + 1.0:
							problems.append("%s: %s is wider than its page" % [where, control.name])
					if not visible_rect.grow(1.0).encloses(reach):
						problems.append("%s: %s is off screen" % [where, control.name])
					var font := control.get_theme_font(&"font")
					var font_size := control.get_theme_font_size(&"font_size")
					var text_width := font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
					if not control.clip_text and text_width > rect.size.x + 1.0 and control.autowrap_mode == TextServer.AUTOWRAP_OFF:
						problems.append("%s: %s text is wider than the button" % [where, control.name])
	check_empty(problems, "critical buttons stay on screen and whole at 130% UI and 150% text")
	tree.root.size = Vector2i(1280, 720)
	GameState.set_setting(&"language", "auto")
	GameState.set_setting(&"ui_scale", 1.0)
	GameState.set_setting(&"text_scale", 1.0)
	DisplaySettings.apply_all(tree)
	tree.current_scene.queue_free()
	await wait_frames(2)
	return true


## Every popup, built and opened on its own.
func _popups() -> Array[Dictionary]:
	var quit := func(dialog: ModalDialog) -> void:
		dialog.prompt(TextDb.t(&"menu.quit_confirm.title"), TextDb.t(&"menu.quit_confirm.body"), [
			ModalDialog.option(&"stay", TextDb.t(&"menu.quit_confirm.stay"), UiTokens.TYPE_CTA_BUTTON, true),
			ModalDialog.option(&"quit", TextDb.t(&"menu.quit_confirm.quit"), UiTokens.TYPE_DANGER_BUTTON),
		])
	return [
		{"make": SettingsOverlay.new, "open": func(o: SettingsOverlay) -> void: o.open()},
		{"make": ControlsOverlay.new, "open": func(o: ControlsOverlay) -> void: o.open()},
		{"make": PrivacyOverlay.new, "open": func(o: PrivacyOverlay) -> void: o.open()},
		{"make": CalibrationOverlay.new, "open": func(o: CalibrationOverlay) -> void: o.open()},
		{"make": HowToOverlay.new, "open": func(o: HowToOverlay) -> void: o.open()},
		{"make": PauseOverlay.new, "open": func(o: PauseOverlay) -> void: o.open()},
		{"make": TravelOverlay.new, "open": func(o: TravelOverlay) -> void: o.open()},
		{"make": BucketPeekOverlay.new, "open": func(o: BucketPeekOverlay) -> void: o.open()},
		{"make": ReceiptOverlay.new, "open": func(o: ReceiptOverlay) -> void: o.open({"lines": [], "total": 125000, "cash_after": 300000})},
		{"make": DuelResultOverlay.new, "open": func(o: DuelResultOverlay) -> void: o.show_result({"fish_id": &"catfish_bruiser", "player_won": true})},
		{"make": ModalDialog.new, "open": quit},
	]


# Revision 6.12: Settings > Privacy and Settings > Controls put their buttons
# side by side, wider than a phone, and the card slid off the right edge.
# Every popup stays whole on the screen and in its middle, in every language,
# at the default and the largest sizes, with a camera hole above it.
func test_every_popup_sits_whole_in_the_middle_of_the_screen() -> bool:
	# Calibration plays its click track on the music engine.
	AudioManager.initialize_procedural_audio()
	GameState.set_setting(&"reduced_motion", true)
	# A camera hole at the top, nothing at the bottom (an immersive Android).
	PlatformService.set_simulated_insets(Vector4(0.0, 35.0, 0.0, 0.0))
	var problems := PackedStringArray()
	for language: String in TextDb.LANGUAGES:
		GameState.set_setting(&"language", language)
		for largest: bool in [false, true]:
			GameState.set_setting(&"ui_scale", 1.3 if largest else 1.0)
			GameState.set_setting(&"text_scale", 1.5 if largest else 1.0)
			DisplaySettings.apply_all(tree)
			# A tall phone (1220x2712) and a tablet.
			for size: Vector2i in [Vector2i(1220, 2712), Vector2i(1536, 2048)]:
				tree.root.size = size
				await wait_frames(2)
				var canvas := tree.root.get_visible_rect().size
				var safe := Rect2(PlatformService.get_safe_rect())
				for popup: Dictionary in _popups():
					var overlay: OverlayPanel = (popup["make"] as Callable).call()
					tree.root.add_child(overlay)
					(popup["open"] as Callable).call(overlay)
					await wait_frames(4)
					var stack := overlay.get_node("Centre/Stack") as Control
					var card := stack.get_global_rect()
					var where := "%s %s %s %s" % [language, "largest" if largest else "default", size, overlay.get_script().get_global_name()]
					if not safe.grow(1.0).encloses(card):
						problems.append("%s: card %s leaves the safe area %s" % [where, card, safe])
					# Shrinking the whole card is the last resort of the largest
					# sizes; at the default ones everything fits as it is.
					if not largest and stack.scale.x < 0.999:
						problems.append("%s: card shrunk to %.2f to fit" % [where, stack.scale.x])
					if absf(card.get_center().x - canvas.x * 0.5) > 1.0:
						problems.append("%s: card centre x %.1f, screen %.1f" % [where, card.get_center().x, canvas.x * 0.5])
					# A card short enough to sit clear of the hole either way is
					# centred on the screen, not on the lopsided safe area.
					var clear := canvas.y - 2.0 * maxf(safe.position.y, canvas.y - safe.end.y) - 2.0 * float(OverlayPanel.SCREEN_MARGIN_TABLET)
					if card.size.y <= clear and absf(card.get_center().y - canvas.y * 0.5) > 1.0:
						problems.append("%s: card centre y %.1f, screen %.1f" % [where, card.get_center().y, canvas.y * 0.5])
					if overlay is PauseOverlay:
						(overlay as PauseOverlay).resume()
					elif overlay is ModalDialog:
						overlay.on_cancel()
					overlay.queue_free()
					await wait_frames(1)
	check_empty(problems, "every popup is whole on the screen and in its middle")
	PlatformService.set_simulated_insets(Vector4.ZERO)
	tree.root.size = Vector2i(1280, 720)
	tree.paused = false
	GameState.set_setting(&"language", "auto")
	GameState.set_setting(&"ui_scale", 1.0)
	GameState.set_setting(&"text_scale", 1.0)
	GameState.set_setting(&"reduced_motion", false)
	DisplaySettings.apply_all(tree)
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


## Revision 6.12: the dialogue card is one size for every line, with TAP TO
## CONTINUE at its foot. A line too long for it grows it upward, the next one
## brings it back, and a line typing itself out never changes it. The story
## scene's card is placed by the same code.
func test_the_dialogue_card_keeps_one_size() -> bool:
	GameState.set_setting(&"dialogue_speed", "normal")
	var box := DialogueBox.new()
	tree.root.add_child(box)
	await wait_frames(2)
	var panel := box.get(&"_panel") as Control
	var hint := box.get(&"_hint") as Control
	var lines: Array[String] = ["Short.", "And unemployed men don't usually argue with dinner.", "word ".repeat(90).strip_edges(), "Short again."]
	var heights: Array[float] = []
	var bottoms: Array[float] = []
	var gaps: Array[float] = []
	for text: String in lines:
		box.play([{"speaker": "BRUISER CATFISH", "text": text}] as Array[Dictionary])
		await wait_frames(3)
		var typing := panel.size.y
		box.advance()
		await wait_frames(3)
		check_near(panel.size.y, typing, 0.5, "\"%s...\" does not resize the card while it types" % text.left(12))
		heights.append(panel.size.y)
		bottoms.append(panel.get_global_rect().end.y)
		gaps.append(panel.get_global_rect().end.y - hint.get_global_rect().end.y)
		box.skip()
	check_near(heights[0], DialogueBox.CARD_HEIGHT, 0.5, "a short line gets the standard card")
	check_near(heights[1], DialogueBox.CARD_HEIGHT, 0.5, "a two-line line gets the same card")
	check(heights[2] > DialogueBox.CARD_HEIGHT + 20.0, "a very long line grows it (%.0f)" % heights[2])
	check_near(heights[3], DialogueBox.CARD_HEIGHT, 0.5, "and the next short line brings it back")
	for index: int in lines.size():
		check_near(bottoms[index], bottoms[0], 0.5, "the card's foot stays put (line %d)" % index)
		check_near(gaps[index], gaps[0], 0.5, "TAP TO CONTINUE stays at the foot (line %d)" % index)
	box.queue_free()
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

## VISUAL_STYLE_GUIDE 6.1: no shadow maps at any level; MSAA only on desktop
## (revision 6.11). Quality only trades resolution, scatter and anti-aliasing.
func test_quality_presets_change_resolution_and_aa_only() -> bool:
	tree.change_scene_to_packed(load("res://scenes/fishing/fishing.tscn"))
	await wait_frames(4)
	var suns := tree.current_scene.find_children("*", "DirectionalLight3D", true, false)
	check(not suns.is_empty(), "the lake has a sun")
	GameState.set_setting(&"quality_preset", "low")
	DisplaySettings.apply_all(tree)
	check(not (suns[0] as DirectionalLight3D).shadow_enabled, "LOW has no real shadows")
	check_near(tree.root.scaling_3d_scale, 0.75, 0.001, "and renders 3D at 75%")
	check_eq(tree.root.msaa_3d, Viewport.MSAA_DISABLED, "LOW skips anti-aliasing")
	GameState.set_setting(&"quality_preset", "high")
	DisplaySettings.apply_all(tree)
	check(not (suns[0] as DirectionalLight3D).shadow_enabled, "HIGH has no real shadows either: they are fake discs")
	check_eq(tree.root.msaa_3d, Viewport.MSAA_4X, "HIGH uses 4x MSAA on desktop")
	check_eq(DisplaySettings.msaa_for(DisplaySettings.QUALITY["high"]), Viewport.MSAA_4X, "the desktop cap is 4x")
	GameState.set_setting(&"quality_preset", "medium")
	DisplaySettings.apply_all(tree)
	check_eq(tree.root.msaa_3d, Viewport.MSAA_2X, "MEDIUM is the default look with 2x MSAA")
	tree.current_scene.queue_free()
	await wait_frames(2)
	return true


## Revision 6.12: a phone or tablet draws at most 60 frames a second, and the
## 3D world at most the preset's pixels per canvas point; text stays sharp. A
## desktop window keeps the presets as they were.
func test_phones_cap_the_frame_rate_and_the_3d_resolution() -> bool:
	check_eq(DisplaySettings.max_fps_for_device(true), 60, "a phone draws at most 60 frames a second")
	check_eq(DisplaySettings.max_fps_for_device(false), 0, "a desktop is left to its V-Sync")
	DisplaySettings.apply_all(tree)
	check_eq(Engine.max_fps, 0, "and the test runner (a desktop) has no cap")

	var quality := DisplaySettings.QUALITY
	var phone := 1220.0 / 390.0
	check_near(DisplaySettings.scale_3d_for_device(quality["medium"], true, phone), 2.0 / phone, 0.001, "MEDIUM on a 1220 px phone draws the world at 64%")
	check(DisplaySettings.scale_3d_for_device(quality["low"], true, phone) < DisplaySettings.scale_3d_for_device(quality["medium"], true, phone), "LOW is lighter than MEDIUM on a phone")
	check(DisplaySettings.scale_3d_for_device(quality["high"], true, phone) > DisplaySettings.scale_3d_for_device(quality["medium"], true, phone), "and HIGH sharper")
	check_near(DisplaySettings.scale_3d_for_device(quality["medium"], true, 1.5), 1.0, 0.001, "a low-density screen keeps full size")
	check_near(DisplaySettings.scale_3d_for_device(quality["low"], true, 8.0), DisplaySettings.MIN_SCALE_3D, 0.001, "and nothing drops below the floor")
	for preset: String in quality:
		check_near(DisplaySettings.scale_3d_for_device(quality[preset], false, phone), float(quality[preset]["scale_3d"]), 0.001, "a desktop keeps %s as it was" % preset.to_upper())
	return true


## Revision 6.11: with the Compatibility renderer, MSAA on a phone's GPU leaks
## a framebuffer every frame until Android kills the game, so phones and
## tablets never get it, at any preset, and no scene can switch it on.
func test_phones_never_use_msaa() -> bool:
	check_eq(int(ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d.mobile", -1)), 0, "project.godot: msaa_3d.mobile=0")
	check_eq(str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")), "gl_compatibility", "phones use the Compatibility renderer")
	for preset: String in DisplaySettings.QUALITY:
		check_eq(DisplaySettings.msaa_for_device(DisplaySettings.QUALITY[preset], true), Viewport.MSAA_DISABLED, "%s has no MSAA on a phone" % preset.to_upper())
	check_eq(DisplaySettings.msaa_for_device(DisplaySettings.QUALITY["high"], false), Viewport.MSAA_4X, "desktop HIGH keeps 4x")
	check(not DisplaySettings.runs_on_phone(), "the test runner is not a phone")

	# No scene or script that ships sets MSAA on a viewport of its own.
	var offenders := PackedStringArray()
	var folders: Array[String] = ["res://scenes", "res://generated", "res://scripts", "res://autoload"]
	while not folders.is_empty():
		var folder: String = folders.pop_back()
		for sub: String in DirAccess.get_directories_at(folder):
			folders.append(folder.path_join(sub))
		for file_name: String in DirAccess.get_files_at(folder):
			if not (file_name.ends_with(".tscn") or file_name.ends_with(".tres") or file_name.ends_with(".gd")):
				continue
			var path := folder.path_join(file_name)
			if path == "res://scripts/ui/display_settings.gd":
				continue
			var text := FileAccess.get_file_as_string(path)
			if text.contains("msaa_3d = ") or text.contains("msaa_3d=") or text.contains(".msaa_3d ="):
				offenders.append(path)
	check_empty(offenders, "only DisplaySettings sets MSAA")
	return true
