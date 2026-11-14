extends Node
## Main Menu (GDD 84, 85, 167.9, 168.2): Continue, New Game with a two-step
## overwrite confirmation, How To Play and Settings, plus save recovery when
## the save on disk could not be read.

const BUTTON_WIDTH_LANDSCAPE := 300.0
const BUTTON_WIDTH_PORTRAIT := 380.0

@onready var _title_block: VBoxContainer = $MenuCanvas/SafeRoot/TitleBlock
@onready var _title_line_1: Label = $MenuCanvas/SafeRoot/TitleBlock/TitleLine1
@onready var _title_line_2: Label = $MenuCanvas/SafeRoot/TitleBlock/TitleLine2
@onready var _menu_buttons: VBoxContainer = $MenuCanvas/SafeRoot/MenuButtons
@onready var _continue_button: GameButton = $MenuCanvas/SafeRoot/MenuButtons/ContinueButton
@onready var _new_game_button: GameButton = $MenuCanvas/SafeRoot/MenuButtons/NewGameButton
@onready var _how_to_button: GameButton = $MenuCanvas/SafeRoot/MenuButtons/HowToButton
@onready var _settings_button: GameButton = $MenuCanvas/SafeRoot/MenuButtons/SettingsButton
@onready var _credits_button: GameButton = $MenuCanvas/SafeRoot/MenuButtons/CreditsButton
@onready var _version_label: Label = $MenuCanvas/SafeRoot/VersionLabel
@onready var _dialog: ModalDialog = $ConfirmOverlay
@onready var _lake_set: Node3D = $World/LakeSet
@onready var _darto_pose: Node3D = $World/DartoMenuPose
@onready var _camera: Camera3D = $World/MenuCamera

var _settings: SettingsOverlay
var _how_to: HowToOverlay
## Blocks a second action while a dialog or transition from the first is open.
var _busy: bool = false


func _ready() -> void:
	_title_line_1.text = TextDb.t(&"menu.title_line_1")
	_title_line_2.text = TextDb.t(&"menu.title_line_2")
	_continue_button.text = TextDb.t(&"menu.continue")
	_new_game_button.text = TextDb.t(&"menu.new_game")
	_how_to_button.text = TextDb.t(&"menu.how_to_play")
	_settings_button.text = TextDb.t(&"menu.settings")
	_credits_button.text = TextDb.t(&"menu.credits")
	# Credits are written in the narrative milestone; until then the entry is
	# visibly unavailable instead of opening an empty screen.
	_credits_button.disabled = true

	_version_label.text = TextDb.tf(&"menu.version", {"version": SaveSchema.build_version()})
	_version_label.visible = DebugService.is_debug_tools_allowed()
	_version_label.gui_input.connect(_on_version_label_input)
	UiTokens.outline_text(_version_label, UiTokens.FONT_SMALL, UiTokens.CREAM_50, 6)

	_continue_button.pressed.connect(_on_continue_pressed)
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_how_to_button.pressed.connect(_on_how_to_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)

	_settings = SettingsOverlay.new()
	_settings.name = "SettingsOverlay"
	_settings.save_reset.connect(_refresh)
	add_child(_settings)
	_how_to = HowToOverlay.new()
	_how_to.name = "HowToOverlay"
	add_child(_how_to)

	_darto_pose.position = (_lake_set.get_node("Markers/DartoSpot") as Node3D).position
	PlatformService.viewport_class_changed.connect(_apply_layout)
	_apply_layout(PlatformService.get_viewport_class())
	_refresh()

	AudioManager.set_music_state(&"menu")
	AudioManager.set_ambience_state(&"lake")
	_report_failed_boot_load.call_deferred()


# --- Layout -----------------------------------------------------------------

## Landscape keeps the menu on the left so the lake stays the focal point;
## portrait centres the title at the top and the buttons at the bottom.
func _apply_layout(viewport_class: StringName) -> void:
	var portrait := viewport_class == PlatformService.PORTRAIT
	# The lake set carries its own camera marks, so Darto and the water stay
	# clear of the menu in both layouts.
	var camera_mark := _lake_set.get_node("Markers/CameraPortrait" if portrait else "Markers/CameraMenu") as Node3D
	_camera.global_transform = camera_mark.global_transform
	_camera.fov = 62.0 if portrait else 50.0
	var button_width := BUTTON_WIDTH_PORTRAIT if portrait else BUTTON_WIDTH_LANDSCAPE
	for button: Control in _menu_buttons.get_children():
		button.custom_minimum_size.x = button_width

	var title_alignment := HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_title_line_1.horizontal_alignment = title_alignment
	_title_line_2.horizontal_alignment = title_alignment
	# The title sits over the lake scene, so it is light text with an outline.
	UiTokens.outline_text(_title_line_1, UiTokens.FONT_HERO_PORTRAIT if portrait else UiTokens.FONT_HERO, UiTokens.CREAM_50, 12)
	UiTokens.outline_text(
		_title_line_2, UiTokens.FONT_SCREEN_TITLE_PORTRAIT if portrait else UiTokens.FONT_SCREEN_TITLE, Color("f2b79f"), 10)

	# Presets size each block to its content, so they run after the content changed.
	_place.call_deferred(portrait)


func _place(portrait: bool) -> void:
	if portrait:
		UiTokens.anchor_at(_title_block, Control.PRESET_CENTER_TOP)
		UiTokens.anchor_at(_menu_buttons, Control.PRESET_CENTER_BOTTOM)
		UiTokens.anchor_at(_version_label, Control.PRESET_TOP_RIGHT)
	else:
		UiTokens.anchor_at(_title_block, Control.PRESET_TOP_LEFT)
		UiTokens.anchor_at(_menu_buttons, Control.PRESET_BOTTOM_LEFT)
		UiTokens.anchor_at(_version_label, Control.PRESET_BOTTOM_RIGHT)


## Continue leads when there is a save; otherwise New Game does.
func _refresh() -> void:
	var has_save := SaveManager.has_save()
	_continue_button.disabled = not has_save
	_continue_button.theme_type_variation = UiTokens.TYPE_CTA_BUTTON if has_save else &""
	_new_game_button.theme_type_variation = &"" if has_save else UiTokens.TYPE_CTA_BUTTON
	if not InputManager.is_touch_primary():
		_focus_later(_continue_button if has_save else _new_game_button)


## Keyboard players start on the main action. Skipped while a dialog owns the
## focus, and safe if the menu was left before the next frame.
func _focus_later(button: GameButton) -> void:
	await get_tree().process_frame
	if is_inside_tree() and button.is_inside_tree() and not _dialog.is_open():
		button.grab_focus()


# --- Actions ----------------------------------------------------------------

func _on_continue_pressed() -> void:
	if _busy:
		return
	_busy = true
	# Always read the file again: Continue must reflect what is really on disk.
	if SaveManager.load_game():
		DebugService.clear_dev_dirty()
		await _enter_game()
	else:
		await _recover_save()
	_busy = false
	_refresh()


func _on_new_game_pressed() -> void:
	if _busy:
		return
	_busy = true
	if not SaveManager.has_save() or await _confirm_replace_save():
		await _start_new_game()
	_busy = false
	_refresh()


func _on_how_to_pressed() -> void:
	if not _busy:
		_how_to.open()


func _on_settings_pressed() -> void:
	if not _busy:
		_settings.open()


func _on_version_label_input(event: InputEvent) -> void:
	if InputActions.is_primary_press(event):
		DebugService.notify_version_label_tapped()


# --- Flows ------------------------------------------------------------------

## Two separate confirmations, so one stray click can never erase a save.
func _confirm_replace_save() -> bool:
	var cancel := ModalDialog.option(&"cancel", TextDb.t(&"menu.new_game_confirm.cancel"), &"", true)
	var first := await _dialog.prompt(
		TextDb.t(&"menu.new_game_confirm_1.title"),
		TextDb.t(&"menu.new_game_confirm_1.body"),
		[cancel, ModalDialog.option(&"confirm", TextDb.t(&"menu.new_game_confirm_1.confirm"), UiTokens.TYPE_DANGER_BUTTON)])
	if first != &"confirm":
		return false
	var second := await _dialog.prompt(
		TextDb.t(&"menu.new_game_confirm_2.title"),
		TextDb.t(&"menu.new_game_confirm_2.body"),
		[cancel, ModalDialog.option(&"confirm", TextDb.t(&"menu.new_game_confirm_2.confirm"), UiTokens.TYPE_DANGER_BUTTON)])
	return second == &"confirm"


func _start_new_game() -> void:
	GameState.new_game()
	DebugService.clear_dev_dirty()
	while not SaveManager.save_game(&"new_game"):
		var choice := await _dialog.prompt(
			TextDb.t(&"error.save_failed.title"),
			TextDb.t(&"error.save_failed.body"),
			[
				ModalDialog.option(&"continue", TextDb.t(&"error.save_failed.continue"), &"", true),
				ModalDialog.option(&"retry", TextDb.t(&"error.save_failed.retry"), UiTokens.TYPE_CTA_BUTTON),
			])
		if choice != &"retry":
			break
	_refresh()
	await _enter_game()


func _enter_game() -> void:
	SceneRouter.goto_fishing()


## Offers TRY AGAIN / START NEW GAME until the save loads or is replaced
## (GDD 117, 183.21). The unreadable file was already preserved as a backup.
func _recover_save() -> void:
	while true:
		var unsupported := SaveManager.get_last_load_status() == SaveManager.STATUS_UNSUPPORTED
		var prefix := "error.save_unsupported" if unsupported else "error.save_corrupt"
		var choice := await _dialog.prompt(
			TextDb.t(StringName(prefix + ".title")),
			TextDb.t(StringName(prefix + ".body")),
			[
				ModalDialog.option(&"retry", TextDb.t(&"error.save_corrupt.retry")),
				ModalDialog.option(&"new_game", TextDb.t(&"error.save_corrupt.new_game"), UiTokens.TYPE_DANGER_BUTTON),
			])
		if choice == &"new_game":
			await _start_new_game()
			return
		if SaveManager.load_game():
			DebugService.clear_dev_dirty()
			return


func _report_failed_boot_load() -> void:
	var status := SaveManager.get_last_load_status()
	if status != SaveManager.STATUS_CORRUPT and status != SaveManager.STATUS_UNSUPPORTED:
		return
	if _busy:
		return
	_busy = true
	await _recover_save()
	_busy = false
	_refresh()
