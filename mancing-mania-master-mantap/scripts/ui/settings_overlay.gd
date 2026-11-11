class_name SettingsOverlay
extends OverlayPanel
## Settings screen (GDD 86, 167.9). Milestone 1 ships the Audio section and the
## Save section; Visual, Accessibility and Controls are added by the milestone
## that implements those options. Every change is autosaved through GameState.

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

	content.add_child(make_label(TextDb.t(&"settings.section.save"), UiTokens.TYPE_HEADER))
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
