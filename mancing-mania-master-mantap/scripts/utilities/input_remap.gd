class_name InputRemap
extends RefCounted
## Keyboard remapping rules (GDD 189.15), kept apart from the screen so they
## can be tested: tokens, conflicts, swaps and what the player sees.
##
## A binding is a token: "key:<physical keycode>" or "mouse:<button index>".
## Remapping replaces an action's keyboard key and keeps its mouse buttons,
## so a click still casts after the cast key has moved.

## Keys the browser or the OS keeps for itself, and keys that would leave the
## game without a way back (GDD 189.15).
const RESERVED_KEYS: Array[Key] = [KEY_F5, KEY_F11, KEY_F12, KEY_TAB, KEY_META, KEY_CTRL, KEY_ALT, KEY_SHIFT, KEY_CAPSLOCK]


## The tokens an action has right now.
static func tokens_for(action: StringName) -> Array[String]:
	var tokens: Array[String] = []
	if not InputMap.has_action(action):
		return tokens
	for event: InputEvent in InputMap.action_get_events(action):
		var token := token_for_event(event)
		if token != "" and not tokens.has(token):
			tokens.append(token)
	return tokens


## The token for a captured event, or "" when it cannot be a binding (key
## release, echo, modifier combination, reserved key).
static func token_for_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		var code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
		if code == KEY_NONE or RESERVED_KEYS.has(code):
			return ""
		if key_event.ctrl_pressed or key_event.meta_pressed or key_event.alt_pressed:
			return ""
		return "key:%d" % code
	if event is InputEventMouseButton:
		var button := (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_WHEEL_UP or button == MOUSE_BUTTON_WHEEL_DOWN:
			return ""
		return "mouse:%d" % button
	return ""


## The remappable action, other than `action`, that already uses `token`.
static func find_conflict(action: StringName, token: String) -> StringName:
	for other: StringName in InputActions.REMAPPABLE:
		if other != action and tokens_for(other).has(token):
			return other
	return &""


## The remap with `action`'s key replaced by `token`. With `swap_with`, that
## action takes over `action`'s old key so nothing is left unbound.
static func assign(remap: Dictionary, action: StringName, token: String, swap_with: StringName = &"") -> Dictionary:
	var result := remap.duplicate(true)
	var old_tokens := tokens_for(action)
	result[String(action)] = _replace_key(old_tokens, token)
	if swap_with != &"":
		var old_key := ""
		for old_token: String in old_tokens:
			if old_token.begins_with("key:"):
				old_key = old_token
				break
		var other_tokens := tokens_for(swap_with)
		other_tokens.erase(token)
		if old_key != "":
			other_tokens = _replace_key(other_tokens, old_key)
		result[String(swap_with)] = other_tokens
	return result


## Readable name of a token, such as "SPACE" or "MOUSE 1".
static func display_name(token: String) -> String:
	var parts := token.split(":")
	if parts.size() != 2:
		return "-"
	if parts[0] == "key":
		return OS.get_keycode_string(parts[1].to_int() as Key).to_upper()
	return TextDb.tf(&"controls.mouse_button", {"button": parts[1]})


## What the action's button shows: its keys, then its mouse buttons.
static func describe(action: StringName) -> String:
	var names := PackedStringArray()
	for token: String in tokens_for(action):
		names.append(display_name(token))
	return " / ".join(names) if not names.is_empty() else TextDb.t(&"controls.unbound")


static func _replace_key(tokens: Array[String], key_token: String) -> Array[String]:
	var result: Array[String] = [key_token]
	for token: String in tokens:
		if not token.begins_with("key:") and token != key_token:
			result.append(token)
	return result
