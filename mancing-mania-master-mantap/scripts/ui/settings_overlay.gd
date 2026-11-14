class_name SettingsOverlay
extends OverlayPanel
## Settings screen (GDD 86, 167.9, 189): Audio, Visual, Accessibility,
## Rhythm, Controls and Save. Every change is autosaved through GameState.
## Option rows cycle through their allowed values on each press.

## Emitted after RESET SAVE removed the save, so the caller can refresh.
signal save_reset()

const VOLUME_STEP := 0.05

var _sliders: Dictionary[StringName, HSlider] = {}
var _value_labels: Dictionary[StringName, Label] = {}
var _reset_button: GameButton
var _reset_note: Label
var _close_button: GameButton
var _dialog: ModalDialog
var _refreshing: bool = false
var _beat_pulse: GameButton
var _offset_labels: Dictionary[StringName, Label] = {}
var _calibration: CalibrationOverlay
const OFFSET_STEP_MS := 5
## Option rows (GDD 189.1): setting key -> allowed values, in order.
const ACCESSIBILITY_OPTIONS: Array[StringName] = [
	&"ui_scale", &"text_scale", &"high_contrast_hud", &"hud_shake", &"reduced_motion",
	&"reduced_flash", &"arm_input_mode", &"mobile_handedness", &"dialogue_speed", &"skip_hold_sec",
]

var _option_buttons: Dictionary[StringName, GameButton] = {}
var _controls: ControlsOverlay
var _privacy: PrivacyOverlay


func build_content() -> void:
	layer = 50
	panel_width = 560.0
	set_title(TextDb.t(&"settings.title"))

	content.add_child(make_label(TextDb.t(&"settings.section.audio"), UiTokens.TYPE_HEADER))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override(&"v_separation", UiTokens.SPACE_4)
	content.add_child(grid)
	for key: StringName in [&"master_volume", &"music_volume", &"sfx_volume", &"ambience_volume", &"ui_volume"]:
		_add_volume_row(grid, key)

	content.add_child(make_label(TextDb.t(&"settings.section.visual"), UiTokens.TYPE_HEADER))
	_add_option_row(&"quality_preset")
	if not PlatformService.is_android():
		_add_option_row(&"fullscreen_web")

	content.add_child(make_label(TextDb.t(&"settings.section.accessibility"), UiTokens.TYPE_HEADER))
	for key: StringName in ACCESSIBILITY_OPTIONS:
		_add_option_row(key)

	content.add_child(make_label(TextDb.t(&"settings.section.rhythm"), UiTokens.TYPE_HEADER))
	_beat_pulse = make_button("")
	_beat_pulse.name = "BeatPulseToggle"
	_beat_pulse.pressed.connect(func() -> void:
		GameState.set_setting(&"rhythm_beat_pulse", not bool(GameState.get_setting(&"rhythm_beat_pulse")))
		_refresh())
	content.add_child(_beat_pulse)
	for key: StringName in [&"rhythm_input_offset_ms", &"rhythm_visual_offset_ms"]:
		_add_offset_row(key)
	var calibrate := make_button(TextDb.t(&"settings.rhythm.calibrate"))
	calibrate.name = "CalibrateButton"
	calibrate.pressed.connect(func() -> void: _calibration.open())
	content.add_child(calibrate)

	# Keyboard remapping is for Web and desktop (GDD 189.15).
	if not PlatformService.is_android():
		content.add_child(make_label(TextDb.t(&"settings.section.controls"), UiTokens.TYPE_HEADER))
		var controls := make_button(TextDb.t(&"settings.controls.open"))
		controls.name = "ControlsButton"
		controls.pressed.connect(func() -> void: _controls.open())
		content.add_child(controls)

	# Privacy summary and policy, offline (GDD 187.7).
	content.add_child(make_label(TextDb.t(&"settings.section.privacy"), UiTokens.TYPE_HEADER))
	var privacy := make_button(TextDb.t(&"settings.privacy.open"))
	privacy.name = "PrivacyButton"
	privacy.pressed.connect(func() -> void: _privacy.open())
	content.add_child(privacy)

	content.add_child(make_label(TextDb.t(&"settings.section.save"), UiTokens.TYPE_HEADER))
	# Browser storage can be cleared by the player (GDD 115).
	var web_note := make_label(TextDb.t(&"settings.web_storage_note"), UiTokens.TYPE_SMALL)
	web_note.name = "WebStorageNote"
	web_note.visible = PlatformService.is_web()
	content.add_child(web_note)
	_reset_note = make_label(TextDb.t(&"settings.no_save"), UiTokens.TYPE_SMALL)
	content.add_child(_reset_note)
	_reset_button = make_button(TextDb.t(&"settings.reset_save"), UiTokens.TYPE_DANGER_BUTTON)
	_reset_button.pressed.connect(_on_reset_pressed)
	content.add_child(_reset_button)

	_close_button = make_button(TextDb.t(&"common.close"), UiTokens.TYPE_CTA_BUTTON)
	_close_button.click_sfx = &"ui_back"
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)

	_dialog = ModalDialog.new()
	_dialog.name = "SettingsDialog"
	add_child(_dialog)
	_calibration = CalibrationOverlay.new()
	_calibration.name = "Calibration"
	_calibration.finished.connect(_refresh)
	add_child(_calibration)
	_controls = ControlsOverlay.new()
	_controls.name = "Controls"
	add_child(_controls)
	_privacy = PrivacyOverlay.new()
	_privacy.name = "Privacy"
	add_child(_privacy)


## A setting with a few allowed values: its name and a button that moves to
## the next value.
func _add_option_row(key: StringName) -> void:
	var row := HBoxContainer.new()
	row.name = "Row_%s" % key
	content.add_child(row)
	var name_label := make_label(TextDb.t(StringName("settings.option.%s" % key)))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var button := make_button("")
	button.name = "Option_%s" % key
	button.custom_minimum_size.x = 190.0
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.pressed.connect(func() -> void:
		GameState.set_setting(key, next_value(key, GameState.get_setting(key)))
		if key == &"fullscreen_web":
			PlatformService.request_fullscreen(bool(GameState.get_setting(key)))
		_refresh())
	row.add_child(button)
	_option_buttons[key] = button


## The allowed values of an option setting, in the order the button cycles.
static func options_for(key: StringName) -> Array:
	match key:
		&"hud_shake":
			return SaveSchema.HUD_SHAKE_MODES
		&"ui_scale":
			return SaveSchema.UI_SCALES
		&"text_scale":
			return SaveSchema.TEXT_SCALES
		&"arm_input_mode":
			return SaveSchema.ARM_INPUT_MODES
		&"mobile_handedness":
			return SaveSchema.HANDEDNESS_MODES
		&"dialogue_speed":
			return SaveSchema.DIALOGUE_SPEEDS
		&"skip_hold_sec":
			return SaveSchema.SKIP_HOLD_OPTIONS
		&"quality_preset":
			return SaveSchema.QUALITY_PRESETS
	return [false, true]


static func next_value(key: StringName, current: Variant) -> Variant:
	var options := options_for(key)
	var index := 0
	for i: int in options.size():
		if typeof(options[i]) == TYPE_FLOAT and is_equal_approx(float(options[i]), float(current)):
			index = i
		elif typeof(options[i]) != TYPE_FLOAT and options[i] == current:
			index = i
	return options[(index + 1) % options.size()]


## What an option button reads for a value.
static func option_text(key: StringName, value: Variant) -> String:
	match key:
		&"ui_scale", &"text_scale":
			return "%d%%" % roundi(float(value) * 100.0)
		&"skip_hold_sec":
			return TextDb.tf(&"settings.value.seconds", {"sec": "%.1f" % float(value)})
	if typeof(value) == TYPE_BOOL:
		return TextDb.t(&"settings.value.on" if value else &"settings.value.off")
	return TextDb.t(StringName("settings.value.%s" % value))


func get_option_button(key: StringName) -> GameButton:
	return _option_buttons.get(key)


## An offset in milliseconds with - and + buttons (GDD 189.10).
func _add_offset_row(key: StringName) -> void:
	var row := HBoxContainer.new()
	content.add_child(row)
	var name_label := make_label(TextDb.t(StringName("settings.rhythm.%s" % key)))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	for step: int in [-OFFSET_STEP_MS, OFFSET_STEP_MS]:
		var button := GameButton.new()
		button.text = "-" if step < 0 else "+"
		button.custom_minimum_size.x = UiTokens.TOUCH_TARGET_PREFERRED
		button.pressed.connect(func() -> void:
			GameState.set_setting(key, int(GameState.get_setting(key)) + step)
			_refresh())
		row.add_child(button)
		if step < 0:
			var value := Label.new()
			value.custom_minimum_size.x = 84.0
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			row.add_child(value)
			_offset_labels[key] = value


func open() -> void:
	_refresh()
	show_overlay()
	focus_later(_close_button)


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	hide_overlay()


func _add_volume_row(grid: GridContainer, key: StringName) -> void:
	var name_label := make_label(TextDb.t(StringName("settings.audio.%s" % key)))
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.custom_minimum_size.x = 170.0
	grid.add_child(name_label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = VOLUME_STEP
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(180.0, UiTokens.TOUCH_TARGET_MIN)
	slider.value_changed.connect(_on_volume_changed.bind(key))
	slider.drag_ended.connect(_on_volume_drag_ended)
	grid.add_child(slider)
	_sliders[key] = slider

	var value_label := make_label("")
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size.x = 56.0
	grid.add_child(value_label)
	_value_labels[key] = value_label


func _refresh() -> void:
	_refreshing = true
	for key: StringName in _sliders:
		var value := float(GameState.get_setting(key))
		_sliders[key].value = value
		_value_labels[key].text = _percent(value)
	_refreshing = false
	_beat_pulse.text = TextDb.t(&"settings.rhythm.beat_pulse_on" if GameState.get_setting(&"rhythm_beat_pulse") else &"settings.rhythm.beat_pulse_off")
	for key: StringName in _offset_labels:
		_offset_labels[key].text = TextDb.tf(&"settings.rhythm.ms", {"ms": int(GameState.get_setting(key))})
	for key: StringName in _option_buttons:
		_option_buttons[key].text = option_text(key, GameState.get_setting(key))
	var has_save := SaveManager.has_save()
	_reset_button.disabled = not has_save
	_reset_note.visible = not has_save


func _percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


func _on_volume_changed(value: float, key: StringName) -> void:
	_value_labels[key].text = _percent(value)
	if not _refreshing:
		GameState.set_setting(key, value)


func _on_volume_drag_ended(_value_changed: bool) -> void:
	# A click at the new level lets the player hear what they just set.
	AudioManager.play_ui(&"ui_click")


func _on_reset_pressed() -> void:
	var cancel := ModalDialog.option(&"cancel", TextDb.t(&"common.cancel"), &"", true)
	var confirm := ModalDialog.option(&"confirm", TextDb.t(&"settings.reset_confirm.confirm"), UiTokens.TYPE_DANGER_BUTTON)
	var title := TextDb.t(&"settings.reset_confirm.title")

	if await _dialog.prompt(title, TextDb.t(&"settings.reset_confirm_1.body"), [cancel, confirm]) != &"confirm":
		return
	if await _dialog.prompt(title, TextDb.t(&"settings.reset_confirm_2.body"), [cancel, confirm]) != &"confirm":
		return
	if SaveManager.delete_save():
		GameState.clear_game()
		DebugService.clear_dev_dirty()
		save_reset.emit()
	_refresh()
