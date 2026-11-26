class_name PauseOverlay
extends OverlayPanel
## Pause menu (GDD 90, 121, 176.4, 176.5). Opening it pauses the scene tree, so
## every gameplay timer, animation and countdown stops; this overlay keeps
## running because overlays process while the tree is paused.

## Emitted when the player confirmed leaving for the Main Menu.
signal quit_requested()

var _resume_button: GameButton
var _music_button: GameButton
var _sound_button: GameButton
var _notice: Label
var _controls: Label
var _settings: SettingsOverlay
var _dialog: ModalDialog
var _busy: bool = false
var _reloading_language: bool = false


func build_content() -> void:
	layer = 40
	panel_width = 440.0
	set_title(TextDb.t(&"pause.title"))

	_notice = make_label(TextDb.t(&"pause.focus_lost"), UiTokens.TYPE_SMALL)
	_notice.visible = false
	content.add_child(_notice)

	_resume_button = make_button(TextDb.t(&"pause.resume"), UiTokens.TYPE_CTA_BUTTON)
	_resume_button.icon_id = IconPainter.PLAY
	_resume_button.pressed.connect(resume)
	content.add_child(_resume_button)

	var controls_button := make_button(TextDb.t(&"pause.controls"))
	controls_button.icon_id = IconPainter.KEYS
	controls_button.pressed.connect(_on_controls_pressed)
	content.add_child(controls_button)
	_controls = make_label(TextDb.t(&"controls.body"), UiTokens.TYPE_SMALL)
	_controls.visible = false
	content.add_child(_controls)

	_music_button = make_button("")
	_music_button.icon_id = IconPainter.MUSIC
	_music_button.pressed.connect(_toggle_volume.bind(&"music_volume"))
	content.add_child(_music_button)
	_sound_button = make_button("")
	_sound_button.icon_id = IconPainter.SOUND
	_sound_button.pressed.connect(_toggle_volume.bind(&"sfx_volume"))
	content.add_child(_sound_button)

	var settings_button := make_button(TextDb.t(&"pause.settings"))
	settings_button.icon_id = IconPainter.GEAR
	settings_button.pressed.connect(_on_settings_pressed)
	content.add_child(settings_button)

	var quit_button := make_button(TextDb.t(&"pause.quit"), UiTokens.TYPE_DANGER_BUTTON)
	quit_button.icon_id = IconPainter.DOOR
	quit_button.pressed.connect(_on_quit_pressed)
	footer.add_child(quit_button)

	_settings = SettingsOverlay.new()
	_settings.name = "PauseSettings"
	_settings.language_changed.connect(_on_language_changed)
	add_child(_settings)
	_dialog = ModalDialog.new()
	_dialog.name = "PauseDialog"
	add_child(_dialog)


## Pauses the game and shows the menu. `focus_lost` adds the note shown after
## the window or app lost focus.
func open(focus_lost: bool = false) -> void:
	if is_open():
		return
	_notice.visible = focus_lost
	_controls.visible = false
	_refresh_toggles()
	get_tree().paused = true
	AudioManager.set_paused(true)
	show_overlay()
	focus_later(_resume_button)


func resume() -> void:
	if not is_open() or _busy:
		return
	hide_overlay()
	AudioManager.set_paused(false)
	get_tree().paused = false


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	resume()


func _on_controls_pressed() -> void:
	_controls.visible = not _controls.visible


func is_reloading_language() -> bool:
	return _reloading_language


func _on_settings_pressed() -> void:
	if not _busy:
		_settings.open()


## Switching language from Pause reloads the active scene with the loading fade
## so every HUD label, panel and prompt updates immediately.
func _on_language_changed() -> void:
	if _busy:
		return
	_busy = true
	_reloading_language = true
	SaveManager.flush_pending_autosave()
	_settings.hide_overlay()
	hide_overlay()
	AudioManager.set_paused(false)
	SceneRouter.reload_current_scene()
	_busy = false


## Music and Sound switch between silent and the default level, and the choice
## is saved like any other setting.
func _toggle_volume(key: StringName) -> void:
	var is_on := float(GameState.get_setting(key)) > 0.0
	GameState.set_setting(key, 0.0 if is_on else SaveSchema.default_settings()[String(key)])
	_refresh_toggles()


func _refresh_toggles() -> void:
	var music_on := float(GameState.get_setting(&"music_volume")) > 0.0
	var sound_on := float(GameState.get_setting(&"sfx_volume")) > 0.0
	_music_button.text = TextDb.t(&"pause.music_on" if music_on else &"pause.music_off")
	_sound_button.text = TextDb.t(&"pause.sound_on" if sound_on else &"pause.sound_off")


func _on_quit_pressed() -> void:
	if _busy:
		return
	_busy = true
	SaveManager.flush_pending_autosave()
	var saved := SaveManager.save_game(&"quit_to_menu")
	if not saved or SaveManager.has_unsaved_changes():
		# Leaving now could lose progress: say so before doing it (GDD 176.8).
		var choice := await _dialog.prompt(
			TextDb.t(&"pause.quit_unsaved.title"),
			TextDb.t(&"pause.quit_unsaved.body"),
			[
				ModalDialog.option(&"stay", TextDb.t(&"common.cancel"), &"", true),
				ModalDialog.option(&"quit", TextDb.t(&"pause.quit_unsaved.confirm"), UiTokens.TYPE_DANGER_BUTTON),
			])
		if choice != &"quit":
			_busy = false
			return
	_busy = false
	hide_overlay()
	AudioManager.set_paused(false)
	quit_requested.emit()
