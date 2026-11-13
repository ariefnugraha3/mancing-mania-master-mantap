extends "res://tests/test_suite.gd"
## Platform, input, story-queue, debug and routing services (GDD 122, 123,
## 167.7, 169.4-169.10, 177.9, 178).

const STORAGE_DIR := "user://test_tmp/services"


func get_suite_name() -> String:
	return "services"


func before_all() -> void:
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)


func after_all() -> void:
	DebugService.simulate_release_build = false
	DebugService.clear_forces()
	DebugService.clear_dev_dirty()
	InputManager.set_gameplay_input_enabled(true)
	InputManager.apply_input_remap({})
	GameState.clear_game()
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


func before_each() -> void:
	DebugService.simulate_release_build = false
	DebugService.clear_forces()
	DebugService.clear_dev_dirty()
	InputManager.set_gameplay_input_enabled(true)
	GameState.new_game()


# --- PlatformService --------------------------------------------------------

func test_viewport_classes_follow_aspect_ratio() -> bool:
	check_eq(PlatformService.classify_aspect(1280.0, 720.0), PlatformService.LANDSCAPE_WIDE, "1280x720")
	check_eq(PlatformService.classify_aspect(1920.0, 1080.0), PlatformService.LANDSCAPE_WIDE, "1920x1080")
	check_eq(PlatformService.classify_aspect(1450.0, 1000.0), PlatformService.LANDSCAPE_WIDE, "aspect 1.45 is wide")
	check_eq(PlatformService.classify_aspect(1024.0, 768.0), PlatformService.LANDSCAPE_COMPACT, "1024x768")
	check_eq(PlatformService.classify_aspect(800.0, 800.0), PlatformService.LANDSCAPE_COMPACT, "square")
	check_eq(PlatformService.classify_aspect(720.0, 1280.0), PlatformService.PORTRAIT, "720x1280")
	check_eq(PlatformService.classify_aspect(1080.0, 2400.0), PlatformService.PORTRAIT, "1080x2400")
	check_eq(PlatformService.reference_size_for_class(PlatformService.PORTRAIT), Vector2i(720, 1280), "portrait reference")
	check_eq(PlatformService.reference_size_for_class(PlatformService.LANDSCAPE_WIDE), Vector2i(1280, 720), "landscape reference")
	check_eq(PlatformService.reference_size_for_class(PlatformService.LANDSCAPE_COMPACT), Vector2i(1280, 720), "compact reference")
	return true


func test_platform_queries() -> bool:
	check(not PlatformService.is_web() and not PlatformService.is_android(), "desktop test run is neither web nor android")
	check(not PlatformService.supports_file_import_export(), "save file import/export is a Web feature")
	var safe := PlatformService.get_safe_rect()
	check(safe.size.x > 0 and safe.size.y > 0, "safe rect has an area")
	check(PlatformService.get_reference_scale() > 0.0, "reference scale is positive")
	return true


# --- Formatting -------------------------------------------------------------

func test_money_format() -> bool:
	check_eq(Money.format_rp(0), "Rp 0", "zero")
	check_eq(Money.format_rp(500), "Rp 500", "below a thousand")
	check_eq(Money.format_rp(8430), "Rp 8,430", "starting cash")
	check_eq(Money.format_rp(1800000), "Rp 1,800,000", "debt")
	check_eq(Money.format_rp(1000), "Rp 1,000", "exact thousand")
	check_eq(Money.format_rp(-25000), "Rp -25,000", "negative")
	return true


# --- InputManager -----------------------------------------------------------

func test_action_press_is_consumed_once() -> bool:
	InputManager.press_action(&"fish_cast")
	check_eq(InputManager.get_action_strength_safe(&"fish_cast"), 1.0, "held action reads 1.0")
	check(InputManager.consume_action_once(&"fish_cast"), "first consume succeeds")
	check(not InputManager.consume_action_once(&"fish_cast"), "second consume is refused")
	InputManager.release_action(&"fish_cast")
	check_eq(InputManager.get_action_strength_safe(&"fish_cast"), 0.0, "released action reads 0.0")
	check(not InputManager.consume_action_once(&"not_an_action"), "unknown action is safe")
	check_eq(InputManager.get_action_strength_safe(&"not_an_action"), 0.0, "unknown action strength is 0.0")
	return true


func test_disabled_gameplay_input_blocks_gameplay_only() -> bool:
	InputManager.press_action(&"box_jab")
	InputManager.set_gameplay_input_enabled(false)
	check(not InputManager.consume_action_once(&"box_jab"), "buffered press is dropped when input turns off")
	InputManager.press_action(&"box_jab")
	check(not InputManager.consume_action_once(&"box_jab"), "presses are ignored while off")
	check_eq(InputManager.get_action_strength_safe(&"box_jab"), 0.0, "held state is ignored while off")

	InputManager.press_action(&"pause")
	check(InputManager.consume_action_once(&"pause"), "system actions keep working")

	InputManager.set_gameplay_input_enabled(true)
	check(not InputManager.consume_action_once(&"box_jab"), "nothing fires the moment input comes back")
	InputManager.press_action(&"box_jab")
	check(InputManager.consume_action_once(&"box_jab"), "new presses work again")
	return true


func test_stale_presses_expire() -> bool:
	InputManager.press_action(&"open_bucket")
	await wait_seconds(0.3)
	check(not InputManager.consume_action_once(&"open_bucket"), "a press older than the buffer window is dropped")
	InputManager.release_action(&"open_bucket")
	return true


func test_key_events_reach_actions_through_the_input_map() -> bool:
	var press := InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	Input.parse_input_event(press)
	await wait_frames(3)
	check(InputManager.consume_action_once(&"open_market"), "E triggers open_market")
	check_eq(InputManager.get_device_type(), InputManager.DEVICE_KEYBOARD_MOUSE, "keyboard sets the device type")

	var release := InputEventKey.new()
	release.physical_keycode = KEY_E
	release.pressed = false
	Input.parse_input_event(release)
	await wait_frames(3)
	check_eq(InputManager.get_action_strength_safe(&"open_market"), 0.0, "release clears the held state")
	return true


func test_left_click_and_space_both_cast() -> bool:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await wait_frames(3)
	check(InputManager.consume_action_once(&"fish_cast"), "left click triggers fish_cast")
	check_eq(InputManager.get_action_strength_safe(&"fish_reel"), 1.0, "and holds fish_reel")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	await wait_frames(3)
	check_eq(InputManager.get_action_strength_safe(&"fish_reel"), 0.0, "releasing the button releases the reel")

	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await wait_frames(3)
	check(InputManager.consume_action_once(&"fish_cast"), "Space triggers fish_cast")
	var space_up := InputEventKey.new()
	space_up.physical_keycode = KEY_SPACE
	space_up.pressed = false
	Input.parse_input_event(space_up)
	await wait_frames(3)
	return true


func test_input_remap_applies_and_resets() -> bool:
	InputManager.apply_input_remap({"open_market": ["key:%d" % KEY_M], "launch_rocket": ["key:65"]})
	var events := InputMap.action_get_events(&"open_market")
	check_eq(events.size(), 1, "remap replaces the default binding")
	check(events.size() == 1 and (events[0] as InputEventKey).physical_keycode == KEY_M, "open_market is now M")
	check(not InputMap.has_action(&"launch_rocket"), "unknown actions are never created")

	InputManager.apply_input_remap({})
	events = InputMap.action_get_events(&"open_market")
	check(events.size() == 1 and (events[0] as InputEventKey).physical_keycode == KEY_E, "empty remap restores the default")
	check(SaveSchema.is_valid_binding_token("key:65"), "key token is valid")
	check(SaveSchema.is_valid_binding_token("mouse:1"), "mouse token is valid")
	check(not SaveSchema.is_valid_binding_token("key:0"), "key code 0 is invalid")
	check(not SaveSchema.is_valid_binding_token("pad:3"), "gamepad tokens are not part of v1.0")
	return true


# --- StoryDirector ----------------------------------------------------------

func test_story_queue_rules() -> bool:
	StoryDirector.enqueue_event(&"story_debt_100k")
	StoryDirector.enqueue_event(&"story_debt_100k")
	StoryDirector.enqueue_event(&"story_invented")
	check_eq(StoryDirector.get_pending_events(), [&"story_debt_100k"], "no duplicates, no unknown events")

	StoryDirector.mark_event_seen(&"story_debt_100k")
	check(StoryDirector.is_event_seen(&"story_debt_100k"), "event marked seen")
	check(StoryDirector.get_pending_events().is_empty(), "seen event leaves the queue")
	StoryDirector.enqueue_event(&"story_debt_100k")
	check(StoryDirector.get_pending_events().is_empty(), "a seen event cannot be queued again")

	check_eq(GameState.get_story_value(&"market_visit_serial"), 0, "visit serial starts at 0")
	StoryDirector.begin_market_visit()
	StoryDirector.begin_market_visit()
	check_eq(GameState.get_story_value(&"market_visit_serial"), 2, "each visit increments the serial")
	check_eq(StoryDirector.resolve_market_exit_event(), &"", "an empty queue resolves to no event")
	return true


func test_superseding_cleans_the_queue() -> bool:
	var seen: Array[StringName] = [&"story_debt_300k"]
	var pending: Array[StringName] = [&"story_debt_300k", &"story_debt_600k"]
	GameState.set_story_events(&"seen_events", seen)
	GameState.set_story_events(&"pending_events", pending)
	StoryDirector.supersede_invalid_events()
	check_eq(StoryDirector.get_pending_events(), [&"story_debt_600k"], "already-seen events are removed")
	return true


# --- DebugService -----------------------------------------------------------

func test_debug_tools_in_a_debug_build() -> bool:
	check(DebugService.is_debug_tools_allowed(), "debug tools are allowed in a debug build")
	DebugService.set_forced_fish(&"arowana_don")
	DebugService.set_forced_duel(&"dance")
	DebugService.set_forced_result(&"win")
	check_eq(DebugService.get_forced_fish(), &"arowana_don", "forced fish")
	check_eq(DebugService.get_forced_duel(), &"dance", "forced duel")
	check_eq(DebugService.get_forced_result(), &"win", "forced result")

	DebugService.set_forced_fish(&"megalodon")
	DebugService.set_forced_duel(&"chess")
	DebugService.set_forced_result(&"draw")
	check_eq(DebugService.get_forced_fish(), &"arowana_don", "invalid fish is ignored")
	check_eq(DebugService.get_forced_duel(), &"dance", "invalid duel is ignored")
	check_eq(DebugService.get_forced_result(), &"win", "invalid result is ignored")
	DebugService.clear_forces()
	check_eq(DebugService.get_forced_fish(), &"", "forces cleared")

	check(not DebugService.is_dev_dirty(), "forces alone do not dirty the state")
	DebugService.set_debt_remaining(250000)
	check_eq(GameState.get_debt_remaining(), 250000, "debug debt applied")
	check_eq(GameState.get_debt_paid(), 1550000, "debug debt keeps the invariant")
	DebugService.set_upgrade_level(&"rod", 9)
	check_eq(GameState.get_upgrade_level(&"rod"), 3, "debug upgrade level is clamped")
	check(DebugService.is_dev_dirty(), "state mutations mark DEV DIRTY STATE")

	var repro := DebugService.get_repro_state()
	for field: String in ["build_version=", "engine_version=", "platform=", "scene=", "save_seed=", "encounter_counter=", "duel_counter=", "fish_id=", "duel_id=", "quality=", "viewport="]:
		check(repro.contains(field), "repro state lists %s" % field)
	return true


func test_debug_tools_are_inert_in_release() -> bool:
	DebugService.simulate_release_build = true
	check(not DebugService.is_debug_tools_allowed(), "debug tools are off in release")
	var cash := GameState.get_cash()
	DebugService.set_cash(5000000)
	DebugService.set_debt_remaining(0)
	DebugService.set_upgrade_level(&"bait", 3)
	DebugService.set_forced_fish(&"arowana_don")
	DebugService.set_session_seed(1)
	DebugService.toggle_overlay()
	DebugService.notify_version_label_tapped()
	check_eq(GameState.get_cash(), cash, "cash cheat ignored")
	check_eq(GameState.get_debt_remaining(), 1800000, "debt cheat ignored")
	check_eq(GameState.get_upgrade_level(&"bait"), 0, "upgrade cheat ignored")
	check_eq(DebugService.get_forced_fish(), &"", "forced fish ignored")
	check(not DebugService.is_overlay_open(), "overlay cannot open")
	check(not DebugService.is_dev_dirty(), "nothing is dirty")
	check(not DebugService.save_debug_state(), "explicit debug save is refused")
	return true


# --- SceneRouter ------------------------------------------------------------

func test_router_knows_which_scenes_exist() -> bool:
	check(SceneRouter.has_scene(SceneRouter.SCENE_BOOT), "boot scene exists")
	check(SceneRouter.has_scene(SceneRouter.SCENE_MAIN_MENU), "main menu scene exists")
	check(not SceneRouter.has_scene(&"moon_base"), "unknown scene id is reported missing")
	for scene_id: StringName in SceneRouter.SCENE_PATHS:
		check(String(SceneRouter.SCENE_PATHS[scene_id]).get_file() == "%s.tscn" % scene_id, "%s uses a snake_case file named after its id" % scene_id)

	# Routing to something that is not there must fail loudly but safely.
	SceneRouter.goto_duel(&"chess", &"catfish_bruiser")
	check(not SceneRouter.is_transitioning(), "an invalid route does not start a transition")
	return true
