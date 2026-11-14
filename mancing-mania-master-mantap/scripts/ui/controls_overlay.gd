class_name ControlsOverlay
extends OverlayPanel
## CONTROLS (GDD 189.15): every remappable action with its current key.
## Pressing a row waits for the next key; a key another action uses asks to
## SWAP or CANCEL. RESET TO DEFAULTS restores the project bindings.

var _rows: Dictionary[StringName, GameButton] = {}
var _capturing: StringName = &""
var _dialog: ModalDialog
var _close_button: GameButton
var _reset_button: GameButton


func build_content() -> void:
	layer = 55
	panel_width = 560.0
	set_title(TextDb.t(&"controls.title"))
	content.add_child(make_label(TextDb.t(&"controls.hint"), UiTokens.TYPE_SMALL))
	for action: StringName in InputActions.REMAPPABLE:
		var row := HBoxContainer.new()
		content.add_child(row)
		var label := make_label(TextDb.t(StringName("controls.action.%s" % action)))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button := make_button("")
		button.name = "Bind_%s" % action
		button.custom_minimum_size.x = 200.0
		button.size_flags_horizontal = Control.SIZE_SHRINK_END
		button.pressed.connect(_begin_capture.bind(action))
		row.add_child(button)
		_rows[action] = button

	_reset_button = make_button(TextDb.t(&"controls.reset"), UiTokens.TYPE_DANGER_BUTTON)
	_reset_button.name = "ResetBindings"
	_reset_button.pressed.connect(_reset)
	footer.add_child(_reset_button)
	_close_button = make_button(TextDb.t(&"common.close"), UiTokens.TYPE_CTA_BUTTON)
	_close_button.click_sfx = &"ui_back"
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)
	_dialog = ModalDialog.new()
	_dialog.name = "ControlsDialog"
	add_child(_dialog)


func open() -> void:
	_capturing = &""
	_refresh()
	show_overlay()
	focus_later(_close_button)


func on_cancel() -> void:
	if _capturing != &"":
		_capturing = &""
		_refresh()
		return
	AudioManager.play_ui(&"ui_back")
	hide_overlay()


func is_capturing() -> StringName:
	return _capturing


func _begin_capture(action: StringName) -> void:
	_capturing = action
	_refresh()
	_rows[action].text = TextDb.t(&"controls.press_key")


func _input(event: InputEvent) -> void:
	if _capturing == &"" or not is_open() or _dialog.is_open():
		return
	if not (event is InputEventKey or event is InputEventMouseButton) or not event.is_pressed() or event.is_echo():
		return
	# A click on the row itself started the capture; it is not the new binding.
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and (event as InputEventKey).physical_keycode == KEY_ESCAPE and _capturing != InputActions.UI_CANCEL and _capturing != InputActions.PAUSE:
		on_cancel()
		return
	var token := InputRemap.token_for_event(event)
	if token == "":
		return
	capture(token)


## Binds the action being captured to `token`, asking first on a conflict.
func capture(token: String) -> void:
	var action := _capturing
	_capturing = &""
	if action == &"":
		return
	var remap: Dictionary = GameState.get_setting(&"input_remap")
	var conflict := InputRemap.find_conflict(action, token)
	if conflict != &"":
		var choice: StringName = await _dialog.prompt(
			TextDb.t(&"controls.conflict.title"),
			TextDb.tf(&"controls.conflict.body", {"key": InputRemap.display_name(token), "action": TextDb.t(StringName("controls.action.%s" % conflict))}),
			[
				ModalDialog.option(&"cancel", TextDb.t(&"common.cancel"), &"", true),
				ModalDialog.option(&"swap", TextDb.t(&"controls.conflict.swap"), UiTokens.TYPE_CTA_BUTTON),
			])
		if choice != &"swap":
			_refresh()
			return
		remap = InputRemap.assign(remap, action, token, conflict)
	else:
		remap = InputRemap.assign(remap, action, token)
	GameState.set_setting(&"input_remap", remap)
	AudioManager.play_ui(&"ui_click")
	_refresh()


func _reset() -> void:
	_capturing = &""
	GameState.set_setting(&"input_remap", {})
	_refresh()


func _refresh() -> void:
	for action: StringName in _rows:
		_rows[action].text = InputRemap.describe(action)
