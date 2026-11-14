extends Node
## Debug/dev tooling (GDD 169.10, 178). Everything here is inert in release
## builds: is_debug_tools_allowed() is false, the overlay never exists and every
## mutation returns without touching the game.
##
## Forced fish/duel/result are runtime overrides and are never saved. Mutating
## cash, debt or upgrades marks the state DEV DIRTY, which blocks all implicit
## saves until the tester presses SAVE DEBUG STATE.

const DebugOverlayScript := preload("res://scripts/ui/debug_overlay.gd")

const VERSION_TAPS_TO_OPEN := 5
const VERSION_TAP_WINDOW_MSEC := 3000
const RESULT_IDS: Array[StringName] = [&"win", &"loss"]

## Test hook: behave exactly like a release build.
var simulate_release_build: bool = false

var _forced_fish: StringName = &""
var _forced_duel: StringName = &""
var _forced_result: StringName = &""
var _forced_attack_direction: StringName = &""
var _dev_dirty: bool = false
var _fast_wait: bool = false
var _auto_reel: bool = false
var _auto_duel: bool = false
var _auto_dialogue: bool = false
var _overlay: CanvasLayer
var _version_tap_times: Array[int] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_debug_tools_allowed():
		_run_command_line_tools()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.DEBUG_TOGGLE_OVERLAY) and not event.is_echo():
		toggle_overlay()
		get_viewport().set_input_as_handled()


# --- Public API (GDD 169.10) ------------------------------------------------

func is_debug_tools_allowed() -> bool:
	return OS.is_debug_build() and not simulate_release_build


func set_forced_fish(fish_id: StringName) -> void:
	if is_debug_tools_allowed() and (fish_id == &"" or GameData.is_bucket_item(fish_id)):
		_forced_fish = fish_id


func set_forced_duel(duel_id: StringName) -> void:
	if is_debug_tools_allowed() and (duel_id == &"" or ContentIds.DUEL_IDS.has(duel_id)):
		_forced_duel = duel_id


func set_forced_result(result_id: StringName) -> void:
	if is_debug_tools_allowed() and (result_id == &"" or RESULT_IDS.has(result_id)):
		_forced_result = result_id


func set_cash(value: int) -> void:
	if not is_debug_tools_allowed():
		return
	GameState.debug_set_cash(value)
	_mark_dirty()


func set_debt_remaining(value: int) -> void:
	if not is_debug_tools_allowed():
		return
	GameState.debug_set_debt_remaining(value)
	_mark_dirty()


func set_upgrade_level(upgrade_id: StringName, level: int) -> void:
	if not is_debug_tools_allowed():
		return
	GameState.debug_set_upgrade_level(upgrade_id, level)
	_mark_dirty()


func trigger_story_event(event_id: StringName) -> void:
	if is_debug_tools_allowed():
		StoryDirector.play_event(event_id)


func set_session_seed(seed: int) -> void:
	if not is_debug_tools_allowed():
		return
	RNGService.initialize_session(seed)
	_mark_dirty()


func clear_forces() -> void:
	_forced_fish = &""
	_forced_duel = &""
	_forced_result = &""
	_forced_attack_direction = &""
	_fast_wait = false
	_auto_reel = false
	_auto_duel = false
	_auto_dialogue = false


# --- Extras -----------------------------------------------------------------

func get_forced_fish() -> StringName:
	return _forced_fish if is_debug_tools_allowed() else &""


func get_forced_duel() -> StringName:
	return _forced_duel if is_debug_tools_allowed() else &""


func get_forced_result() -> StringName:
	return _forced_result if is_debug_tools_allowed() else &""


## Shortens every wait for a bite to half a second (GDD 178.2).
func set_fast_wait(enabled: bool) -> void:
	if is_debug_tools_allowed():
		_fast_wait = enabled


func is_fast_wait_enabled() -> bool:
	return _fast_wait and is_debug_tools_allowed()


## Lets a simple bot hold and release the reel, for unattended QA runs.
func set_auto_reel(enabled: bool) -> void:
	if is_debug_tools_allowed():
		_auto_reel = enabled


func is_auto_reel_enabled() -> bool:
	return _auto_reel and is_debug_tools_allowed()


## Lets a bot play the duel, for unattended QA runs.
func set_auto_duel(enabled: bool) -> void:
	if is_debug_tools_allowed():
		_auto_duel = enabled


func is_auto_duel_enabled() -> bool:
	return _auto_duel and is_debug_tools_allowed()


## Lets dialogue advance by itself, for unattended QA runs and tests.
func set_auto_dialogue(enabled: bool) -> void:
	if is_debug_tools_allowed():
		_auto_dialogue = enabled


func is_auto_dialogue_enabled() -> bool:
	return _auto_dialogue and is_debug_tools_allowed()


## Makes every boxing attack come from one side: &"left", &"right" or &""
## for the normal random choice (GDD 178.2).
func set_forced_attack_direction(direction: StringName) -> void:
	if is_debug_tools_allowed() and (direction == &"" or direction == &"left" or direction == &"right"):
		_forced_attack_direction = direction


func get_forced_attack_direction() -> StringName:
	return _forced_attack_direction if is_debug_tools_allowed() else &""


## True while the state carries debug mutations that were not explicitly saved.
func is_dev_dirty() -> bool:
	return _dev_dirty and is_debug_tools_allowed()


## The explicit SAVE DEBUG STATE action (GDD 178.3).
func save_debug_state() -> bool:
	if not is_debug_tools_allowed():
		return false
	_dev_dirty = false
	return SaveManager.save_game(SaveManager.REASON_DEBUG_STATE)


## Forgets the dirty flag without saving, e.g. after a save was reloaded.
func clear_dev_dirty() -> void:
	_dev_dirty = false


func toggle_overlay() -> void:
	if not is_debug_tools_allowed():
		return
	if _overlay == null:
		_overlay = DebugOverlayScript.new()
		add_child(_overlay)
	else:
		_overlay.visible = not _overlay.visible


func is_overlay_open() -> bool:
	return _overlay != null and _overlay.visible


## Android debug builds open the overlay by tapping the version label
## five times within three seconds.
func notify_version_label_tapped() -> void:
	if not is_debug_tools_allowed():
		return
	var now := Time.get_ticks_msec()
	_version_tap_times.append(now)
	while not _version_tap_times.is_empty() and now - _version_tap_times[0] > VERSION_TAP_WINDOW_MSEC:
		_version_tap_times.pop_front()
	if _version_tap_times.size() >= VERSION_TAPS_TO_OPEN:
		_version_tap_times.clear()
		toggle_overlay()


## Text block for bug reports (GDD 178.5). Contains no personal data.
func get_repro_state() -> String:
	var rng := RNGService.get_debug_snapshot()
	var viewport_size := get_window().size
	var lines := PackedStringArray([
		"build_version=%s" % SaveSchema.build_version(),
		"engine_version=%s" % Engine.get_version_info().get("string", ""),
		"platform=%s" % SaveSchema.current_platform(),
		"scene=%s" % SceneRouter.get_current_scene_id(),
		"save_seed=%d" % rng["save_seed"],
		"encounter_counter=%d" % rng["encounter_counter"],
		"duel_counter=%d" % rng["duel_counter"],
		"fish_id=%s" % GameState.current_fish,
		"duel_id=%s" % GameState.current_duel,
		"quality=%s" % GameState.get_setting(&"quality_preset"),
		"viewport=%dx%d" % [viewport_size.x, viewport_size.y],
	])
	return "\n".join(lines)


# --- Internals --------------------------------------------------------------

func _mark_dirty() -> void:
	_dev_dirty = true


## UI QA helpers for debug builds, passed after `--` on the command line.
## Steps run in the order given, once the first scene has finished loading:
##   --mm-press=<node path from the current scene>   press a button
##   --mm-action=<input action>                      tap an input action
##   --mm-hold=<input action>                        press and keep holding
##   --mm-release=<input action>                     release a held action
##   --mm-wait=<seconds>                             wait
##   --mm-force=<fish or trash id>                   force the next catch
##   --mm-fast-wait                                  half-second bite wait
##   --mm-auto-reel                                  a bot plays the reel
##   --mm-auto-duel                                  a bot plays the duel
##   --mm-auto-dialogue                              dialogue advances by itself
##   --mm-duel=<fish id>[:<duel id>]                 start a game if needed and duel that fish
##   --mm-result=<win|loss>                          force the result of the next duel
##   --mm-attack-side=<left|right>                   force the boxing attack direction
##   --mm-upgrade=<upgrade id>:<level>               set an upgrade level
##   --mm-overlay                                    open the debug overlay
##   --mm-goto=<fishing|market>                      start a game if needed and go there
##   --mm-cash=<amount>                              set cash
##   --mm-debt-left=<amount>                         set the remaining debt
##   --mm-bucket=<item id>:<count>                   put a catch in the Bucket
##   --mm-win=<fish id>                              record a duel win against a fish
##   --mm-story=<story value>                        switch a story flag on
##   --mm-event=<story event id>                     start a game if needed and play that story event
##   --mm-seen=<story event id>                      mark a story event as seen
##   --mm-credits                                    roll the credits (as after the ending)
##   --mm-insets=<left>,<top>,<right>,<bottom>       simulate a notch and home indicator (canvas points)
##   --mm-shot=<absolute png path>                   save a screenshot
## The run quits after the last step when it took at least one screenshot.
func _run_command_line_tools() -> void:
	var steps: Array[PackedStringArray] = []
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--mm-"):
			continue
		var parts := argument.trim_prefix("--mm-").split("=", true, 1)
		steps.append(PackedStringArray([parts[0], parts[1] if parts.size() > 1 else ""]))
	if steps.is_empty():
		return

	await SceneRouter.transition_finished
	var took_shot := false
	var failed := false
	for step: PackedStringArray in steps:
		var value := step[1]
		match step[0]:
			"press":
				await get_tree().create_timer(0.45).timeout
				var target := get_tree().current_scene.get_node_or_null(value) as BaseButton
				if target == null:
					GameLog.error(&"DEBUG", "--mm-press target is not a button", {"path": value})
				elif not target.disabled:
					target.pressed.emit()
			"action":
				InputManager.press_action(StringName(value))
				await get_tree().create_timer(0.08).timeout
				InputManager.release_action(StringName(value))
			"hold":
				InputManager.press_action(StringName(value))
			"release":
				InputManager.release_action(StringName(value))
			"wait":
				await get_tree().create_timer(maxf(value.to_float(), 0.05)).timeout
			"insets":
				var sides := value.split_floats(",")
				if sides.size() == 4:
					PlatformService.set_simulated_insets(Vector4(sides[0], sides[1], sides[2], sides[3]))
				else:
					GameLog.error(&"DEBUG", "--mm-insets needs four numbers", {"value": value})
			"force":
				set_forced_fish(StringName(value))
			"fast-wait":
				set_fast_wait(true)
			"auto-reel":
				set_auto_reel(true)
			"auto-duel":
				set_auto_duel(true)
			"auto-dialogue":
				set_auto_dialogue(true)
			"duel":
				if not GameState.has_active_game():
					GameState.new_game()
				_mark_dirty()
				var duel_parts := value.split(":")
				var duel_id := StringName(duel_parts[1]) if duel_parts.size() > 1 else &"boxing"
				var duel_fish := GameData.get_fish(StringName(duel_parts[0]))
				if duel_fish == null:
					GameLog.error(&"DEBUG", "--mm-duel got an unknown fish", {"fish": value})
				else:
					GameState.record_encounter(duel_fish.id)
					GameState.current_fish = duel_fish.id
					GameState.current_duel = duel_id
					GameState.current_catch = {"fish_id": duel_fish.id, "weight_kg": duel_fish.weight_max_kg * 0.7, "is_big_one": false, "seed": 1}
					SceneRouter.goto_duel(duel_id, duel_fish.id)
					await SceneRouter.transition_finished
			"result":
				set_forced_result(StringName(value))
			"attack-side":
				set_forced_attack_direction(StringName(value))
			"upgrade":
				var upgrade := value.split(":")
				set_upgrade_level(StringName(upgrade[0]), upgrade[1].to_int() if upgrade.size() > 1 else 1)
			"overlay":
				toggle_overlay()
			"goto":
				if not GameState.has_active_game():
					GameState.new_game()
					_mark_dirty()
				if value == "market":
					SceneRouter.goto_market()
				else:
					SceneRouter.goto_fishing()
				await SceneRouter.transition_finished
			"cash":
				set_cash(value.to_int())
			"debt-left":
				set_debt_remaining(value.to_int())
			"bucket":
				var item := value.split(":")
				GameState.add_bucket_item(StringName(item[0]), item[1].to_int() if item.size() > 1 else 1)
				_mark_dirty()
			"win":
				GameState.record_encounter(StringName(value))
				GameState.record_fish_win(StringName(value), GameData.get_fish(StringName(value)).weight_max_kg * 0.8, &"boxing")
				_mark_dirty()
			"story":
				GameState.set_story_value(StringName(value), true)
				_mark_dirty()
			"event":
				if not GameState.has_active_game():
					GameState.new_game()
				_mark_dirty()
				StoryDirector.play_event(StringName(value))
				await SceneRouter.transition_finished
			"seen":
				StoryDirector.mark_event_seen(StringName(value))
				_mark_dirty()
			"credits":
				if not GameState.has_active_game():
					GameState.new_game()
				_mark_dirty()
				SceneRouter.goto_credits()
				await SceneRouter.transition_finished
			"shot":
				await RenderingServer.frame_post_draw
				var save_error := get_viewport().get_texture().get_image().save_png(value)
				GameLog.info(&"DEBUG", "screenshot", {"path": value, "error": save_error})
				took_shot = true
				failed = failed or save_error != OK
			_:
				GameLog.error(&"DEBUG", "unknown command line step", {"step": step[0]})
	if took_shot:
		get_tree().quit(1 if failed else 0)
