extends Node
## Input abstraction over the InputMap (GDD 123, 169.6, 176.1).
##
## Actions are tracked from *unhandled* input, so a click that a UI button
## consumed never doubles as a gameplay action such as fish_cast. Touch buttons
## feed the same actions through press_action()/release_action(), which keeps
## keyboard, mouse and touch on one code path.

signal input_device_changed(device_type: StringName)

const DEVICE_KEYBOARD_MOUSE := &"keyboard_mouse"
const DEVICE_TOUCH := &"touch"

## A buffered press older than this is dropped, so a stale tap cannot leak into
## the state that follows a transition (GDD 176.1).
const PRESS_BUFFER_MSEC := 150
## Some Android phones (MIUI / HyperOS) report one press of Back twice, about
## 0.2 s apart, so the second report closed the very question the first one
## opened. A Back this soon after the last one is the same press (revision
## 6.12).
const BACK_REPEAT_MSEC := 600

var _device_type: StringName = DEVICE_KEYBOARD_MOUSE
var _gameplay_enabled: bool = true
var _tracked: Array[StringName] = []
var _held: Dictionary[StringName, bool] = {}
var _pressed_at_msec: Dictionary[StringName, int] = {}
var _default_events: Dictionary[StringName, Array] = {}
var _first_gesture_seen: bool = false
## The last thing the player used was a key, so prompts name keys instead of
## the on-screen buttons (the portrait screen always shows the buttons).
var _keyboard_active: bool = false
var _last_back_msec: int = -BACK_REPEAT_MSEC


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_tracked = InputActions.get_all()
	for action: StringName in InputActions.REMAPPABLE:
		if InputMap.has_action(action):
			_default_events[action] = InputMap.action_get_events(action)
	if DisplayServer.is_touchscreen_available() and OS.has_feature("mobile"):
		_device_type = DEVICE_TOUCH
	GameState.state_replaced.connect(_apply_saved_remap)
	GameState.settings_changed.connect(_on_settings_changed)
	# Android Back never closes the game by itself (GDD 135); project.godot
	# says so too, this keeps it true whatever the settings file holds.
	get_tree().quit_on_go_back = false
	get_window().go_back_requested.connect(_on_go_back_requested, CONNECT_DEFERRED)


func _input(event: InputEvent) -> void:
	_detect_device(event)
	if not _first_gesture_seen and _is_user_gesture(event):
		_first_gesture_seen = true
		AudioManager.request_web_audio_unlock()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	for action: StringName in _tracked:
		if not event.is_action(action):
			continue
		if event.is_pressed():
			_register_press(action)
		else:
			_held[action] = false


# --- Public API (GDD 169.6) -------------------------------------------------

func get_device_type() -> StringName:
	return _device_type


func is_touch_primary() -> bool:
	return _device_type == DEVICE_TOUCH


func is_keyboard_active() -> bool:
	return _keyboard_active


## Turns gameplay actions on or off. Turning them off also forgets anything
## held or buffered, so nothing fires the moment they come back.
func set_gameplay_input_enabled(enabled: bool) -> void:
	_gameplay_enabled = enabled
	if not enabled:
		for action: StringName in InputActions.GAMEPLAY:
			_held[action] = false
			_pressed_at_msec.erase(action)


## 1.0 while the action is held, otherwise 0.0. Unknown or currently disabled
## actions read as 0.0 instead of raising an error.
func get_action_strength_safe(action: StringName) -> float:
	if not _is_available(action):
		return 0.0
	return 1.0 if _held.get(action, false) else 0.0


## True exactly once per press. A second caller in the same frame, or the same
## caller on a later frame, gets false until the action is pressed again.
func consume_action_once(action: StringName) -> bool:
	if not _is_available(action) or not _pressed_at_msec.has(action):
		return false
	var age := Time.get_ticks_msec() - _pressed_at_msec[action]
	_pressed_at_msec.erase(action)
	return age <= PRESS_BUFFER_MSEC


# --- Extras -----------------------------------------------------------------

func is_gameplay_input_enabled() -> bool:
	return _gameplay_enabled


## The system's Back, once per press however often the phone reports it.
func _on_go_back_requested() -> void:
	var now := Time.get_ticks_msec()
	if now - _last_back_msec < BACK_REPEAT_MSEC:
		GameLog.info(&"INPUT", "back reported twice, taken once", {"after_msec": now - _last_back_msec})
		return
	_last_back_msec = now
	handle_back_request()


## Android Back button or back gesture (GDD 135), one step at a time:
## 1. ignored while a scene is loading;
## 2. the topmost overlay, prompt or dialogue line takes it exactly like Esc
##    (cancel), so Back closes the newest thing on screen first;
## 3. a scene with an answer of its own gives it (the Main Menu asks
##    "Quit the game?", credits opened from the menu go back to it);
## 4. anywhere else it presses Pause, which every gameplay scene opens.
## It never closes the game without asking.
func handle_back_request() -> void:
	if SceneRouter.is_transitioning():
		GameLog.info(&"INPUT", "back ignored during a scene change")
		return
	var viewport := get_viewport()
	viewport.push_input(_cancel_event(true))
	var taken := viewport.is_input_handled()
	viewport.push_input(_cancel_event(false))
	var scene := get_tree().current_scene
	var scene_name := String(scene.name) if scene != null else ""
	if taken:
		GameLog.info(&"INPUT", "back closed what was on top", {"scene": scene_name})
		return
	if scene != null and scene.has_method(&"handle_back"):
		GameLog.info(&"INPUT", "back handed to the scene", {"scene": scene_name})
		scene.call(&"handle_back")
		return
	GameLog.info(&"INPUT", "back pressed pause", {"scene": scene_name})
	press_action(InputActions.PAUSE)


## Gives `control` the keyboard focus, so Enter and the arrows work at once,
## but shows the gold focus ring only to a keyboard or gamepad player (GDD
## 167). After a tap or a click the focus is there without a ring.
func give_focus(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree():
		control.grab_focus(not _keyboard_active)


## Entry points for on-screen touch controls.
func press_action(action: StringName) -> void:
	if InputMap.has_action(action):
		_register_press(action)


func release_action(action: StringName) -> void:
	_held[action] = false


## Applies keyboard/mouse overrides in the save format
## { action: ["key:<physical keycode>", "mouse:<button index>"] }.
## Actions without an override go back to their project defaults.
func apply_input_remap(remap: Dictionary) -> void:
	var clean := SaveSchema.normalize_input_remap(remap)
	for action: StringName in _default_events:
		InputMap.action_erase_events(action)
		var events: Array = _default_events[action]
		if clean.has(String(action)):
			events = _events_from_tokens(clean[String(action)])
		for event: InputEvent in events:
			InputMap.action_add_event(action, event)


func get_default_events(action: StringName) -> Array:
	return _default_events.get(action, []).duplicate()


# --- Internals --------------------------------------------------------------

static func _cancel_event(pressed: bool) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = InputActions.UI_CANCEL
	event.pressed = pressed
	return event


func _register_press(action: StringName) -> void:
	if InputActions.GAMEPLAY.has(action) and not _gameplay_enabled:
		return
	_held[action] = true
	_pressed_at_msec[action] = Time.get_ticks_msec()


func _is_available(action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	return _gameplay_enabled or not InputActions.GAMEPLAY.has(action)


func _detect_device(event: InputEvent) -> void:
	var detected := _device_type
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		detected = DEVICE_TOUCH
	elif event is InputEventKey:
		detected = DEVICE_KEYBOARD_MOUSE
	elif event is InputEventMouse and event.device != InputEvent.DEVICE_ID_EMULATION:
		# Mouse events emulated from a touch must not flip the mode back.
		detected = DEVICE_KEYBOARD_MOUSE
	var keyboard := _keyboard_active
	if (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed():
		keyboard = true
	elif event is InputEventScreenTouch or event is InputEventMouseButton:
		keyboard = false
	if detected != _device_type or keyboard != _keyboard_active:
		_device_type = detected
		_keyboard_active = keyboard
		input_device_changed.emit(_device_type)


func _is_user_gesture(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
		return event.is_pressed()
	return false


func _events_from_tokens(tokens: Array) -> Array:
	var events: Array = []
	for token: Variant in tokens:
		var parts := String(token).split(":")
		var code := parts[1].to_int()
		if parts[0] == "key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = code as Key
			events.append(key_event)
		elif parts[0] == "mouse":
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = code as MouseButton
			events.append(mouse_event)
	return events


func _apply_saved_remap() -> void:
	apply_input_remap(GameState.get_setting(&"input_remap"))


func _on_settings_changed(key: StringName) -> void:
	if key == &"input_remap":
		_apply_saved_remap()
