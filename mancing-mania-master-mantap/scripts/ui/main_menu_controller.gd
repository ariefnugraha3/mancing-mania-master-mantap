extends Node
## Main Menu (GDD 84, 85, 167.9, 168.2): Continue, New Game with a two-step
## overwrite confirmation, How To Play and Settings, plus save recovery when
## the save on disk could not be read. Android Back here asks before the game
## closes (GDD 135).

## The button column fills a phone's width and stops growing on a tablet.
const BUTTON_COLUMN_MAX_WIDTH := 400.0
## The leading button stands a little taller than the rest.
const LEAD_BUTTON_HEIGHT := 64.0
const BUTTON_HEIGHT := 54.0
const PROLOGUE_EVENT := &"story_prologue_zero"
const PROP_PATH := "res://generated/scenes/props/%s.tscn"
## After the ending: a picnic mat and three glasses beside Darto's spot, in
## screen terms [prop, across, out, yaw] (right of him on the screen).
const ENDING_PROPS: Array[Array] = [
	[&"prop_picnic_mat", 0.95, -0.25, 12.0],
	[&"prop_drink_glass", 0.78, -0.3, 0.0],
	[&"prop_drink_glass", 0.98, -0.1, 0.0],
	[&"prop_drink_glass", 1.16, -0.32, 0.0],
]

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
@onready var _camera: DioramaCamera = $World/MenuCamera

var _settings: SettingsOverlay
var _how_to: HowToOverlay
var _emblem: LogoEmblem
var _ribbon: PanelContainer
var _title_text: VBoxContainer
## Blocks a second action while a dialog or transition from the first is open.
var _busy: bool = false


func _ready() -> void:
	_title_line_1.text = TextDb.t(&"menu.title_line_1")
	# "Catch and Brawl" has no subtitle (revision 6.8); the ribbon waits for one.
	_title_line_2.text = TextDb.t(&"menu.title_line_2") if TextDb.has_key(&"menu.title_line_2") else ""
	_continue_button.text = TextDb.t(&"menu.continue")
	_new_game_button.text = TextDb.t(&"menu.new_game")
	_how_to_button.text = TextDb.t(&"menu.how_to_play")
	_settings_button.text = TextDb.t(&"menu.settings")
	_credits_button.text = TextDb.t(&"menu.credits")
	_credits_button.pressed.connect(_on_credits_pressed)
	_continue_button.icon_id = IconPainter.PLAY
	_new_game_button.icon_id = IconPainter.SPARKLE
	_how_to_button.icon_id = IconPainter.BOOK
	_settings_button.icon_id = IconPainter.GEAR
	_credits_button.icon_id = IconPainter.HEART
	_build_logo()

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
	# A new language redraws the whole menu in it.
	_settings.language_changed.connect(func() -> void: SceneRouter.goto_main_menu())
	add_child(_settings)
	_how_to = HowToOverlay.new()
	_how_to.name = "HowToOverlay"
	add_child(_how_to)

	_darto_pose.transform = (_lake_set.get_node("Markers/DartoSpot") as Node3D).transform
	_camera.frame_marker(_lake_set.get_node("Markers/MenuFocus") as Node3D)
	_dress_for_ending()
	PlatformService.viewport_class_changed.connect(_apply_layout)
	_safe_root().resized.connect(_apply_layout)
	_apply_layout()
	_refresh()

	AudioManager.set_music_state(&"menu")
	AudioManager.set_ambience_state(&"lake")
	_report_failed_boot_load.call_deferred()
	_play_entrance.call_deferred()


# --- Layout -----------------------------------------------------------------

## The portrait menu: the logo at the top, the lake and Darto in the middle,
## and the buttons in one column at the bottom, in thumb reach.
func _apply_layout(_viewport_class: StringName = &"") -> void:
	var area := _safe_root().size
	var column_width := minf(area.x, BUTTON_COLUMN_MAX_WIDTH)
	for button: Control in _menu_buttons.get_children():
		button.custom_minimum_size.x = column_width
	_title_line_1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_line_2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# The logo sits over the lake scene: painted butter letters with a thick
	# cocoa rim and shadow, sized to the screen's width, and the subtitle on a
	# tilted crust ribbon.
	var title_size := int(clampf(area.x * 0.105, 30.0, 52.0))
	UiSkin.sign_text(_title_line_1, title_size, DioramaStyle.BUTTER, 12)
	_fit_title(area.x)
	_title_line_2.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(int(clampf(title_size * 0.5, 17.0, 26.0))))
	# The emblem is an illustration now (revision 6.8): big enough to read.
	_emblem.diameter = clampf(area.x * 0.28, 84.0, 140.0)
	# Presets size each block to its content, so they run after the content changed.
	_place.call_deferred()


func _place() -> void:
	UiTokens.anchor_at(_title_block, Control.PRESET_CENTER_TOP)
	UiTokens.anchor_at(_menu_buttons, Control.PRESET_CENTER_BOTTOM)
	UiTokens.anchor_at(_version_label, Control.PRESET_BOTTOM_RIGHT)
	# The version note sits just above the buttons, out of their way.
	_version_label.position.y = _menu_buttons.position.y - _version_label.size.y - UiTokens.SPACE_4


func _safe_root() -> Control:
	return _menu_buttons.get_parent() as Control


## Continue leads when there is a save; otherwise New Game does.
func _refresh() -> void:
	var has_save := SaveManager.has_save()
	_continue_button.disabled = not has_save
	_continue_button.theme_type_variation = UiTokens.TYPE_CTA_BUTTON if has_save else &""
	_new_game_button.theme_type_variation = &"" if has_save else UiTokens.TYPE_CTA_BUTTON
	for button: GameButton in [_continue_button, _new_game_button, _how_to_button, _settings_button, _credits_button]:
		var leads := button.theme_type_variation == UiTokens.TYPE_CTA_BUTTON
		button.custom_minimum_size.y = LEAD_BUTTON_HEIGHT if leads else BUTTON_HEIGHT
		button.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(UiTokens.FONT_BUTTON + (2 if leads else 0)))
	if not InputManager.is_touch_primary():
		_focus_later(_continue_button if has_save else _new_game_button)


## Keyboard players start on the main action. Skipped while a dialog owns the
## focus, and safe if the menu was left before the next frame.
func _focus_later(button: GameButton) -> void:
	await get_tree().process_frame
	if is_inside_tree() and button.is_inside_tree() and not _dialog.is_open():
		button.grab_focus()


# --- Logo and entrance -------------------------------------------------------

## The title becomes a small logo: the round emblem above the big painted
## title, with the subtitle (if the title has one) on a tilted ribbon under it.
func _build_logo() -> void:
	var row := VBoxContainer.new()
	row.name = "TitleRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_4)
	_title_block.add_child(row)
	_title_block.move_child(row, 0)
	_emblem = LogoEmblem.new()
	_emblem.name = "Emblem"
	_emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_child(_emblem)
	_title_text = VBoxContainer.new()
	_title_text.name = "TitleText"
	_title_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_text.add_theme_constant_override(&"separation", -4)
	_title_text.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_title_text)
	_title_line_1.reparent(_title_text, false)
	_ribbon = PanelContainer.new()
	_ribbon.name = "SubtitleRibbon"
	_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbon.theme_type_variation = UiTokens.TYPE_RIBBON_PANEL
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_text.add_child(_ribbon)
	_title_line_2.reparent(_ribbon, false)
	_title_line_2.theme_type_variation = UiTokens.TYPE_RIBBON_LABEL
	# The ribbon carries a subtitle only when the title has one ("Catch and
	# Brawl" since revision 6.8 is a single line).
	_ribbon.visible = _title_line_2.text != ""
	# Containers reset rotation when they lay out, so the tilt is re-applied.
	_title_text.sort_children.connect(_tilt_ribbon)


## The title stays on one line and never runs past the screen edge, even on
## a narrow phone with large text: the font steps down until it fits.
func _fit_title(width: float) -> void:
	var font := _title_line_1.get_theme_font(&"font")
	var fitted := _title_line_1.get_theme_font_size(&"font_size")
	var room := width - UiTokens.SPACE_24
	while fitted > 20 and font.get_string_size(_title_line_1.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, fitted).x > room:
		fitted -= 2
	_title_line_1.add_theme_font_size_override(&"font_size", fitted)


func _tilt_ribbon() -> void:
	_ribbon.pivot_offset = _ribbon.size * 0.5
	_ribbon.rotation = deg_to_rad(-3.0)


## The logo drops in with a small bounce and the buttons pop in one after
## another. Skipped with Reduced Motion, and in a windowless run.
func _play_entrance() -> void:
	if GameState.get_setting(&"reduced_motion") or DisplayServer.get_name() == "headless":
		return
	var tween := create_tween().set_parallel(true)
	var resting_y := _title_block.position.y
	_title_block.position.y = resting_y - 48.0
	_title_block.modulate.a = 0.0
	tween.tween_property(_title_block, "position:y", resting_y, 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_title_block, "modulate:a", 1.0, 0.3)
	var index := 0
	for button: Control in _menu_buttons.get_children():
		var delay := 0.16 + 0.07 * float(index)
		button.modulate.a = 0.0
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2.ONE * 0.84
		tween.tween_property(button, "modulate:a", 1.0, 0.22).set_delay(delay)
		tween.tween_property(button, "scale", Vector2.ONE, 0.42).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		index += 1


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


func _on_credits_pressed() -> void:
	if not _busy:
		_busy = true
		SceneRouter.goto_credits(true)


func _on_version_label_input(event: InputEvent) -> void:
	if InputActions.is_primary_press(event):
		DebugService.notify_version_label_tapped()


## Android Back with nothing open on the menu (GDD 135): ask before the game
## closes, and save first. Back again keeps playing. A browser tab cannot
## close itself, so the Web build has nothing to ask.
func handle_back() -> void:
	if _busy or PlatformService.is_web():
		return
	_busy = true
	var choice := await _dialog.prompt(
		TextDb.t(&"menu.quit_confirm.title"),
		TextDb.t(&"menu.quit_confirm.body") if GameState.has_active_game() else "",
		[
			ModalDialog.option(&"stay", TextDb.t(&"menu.quit_confirm.stay"), &"", true),
			ModalDialog.option(&"quit", TextDb.t(&"menu.quit_confirm.quit"), UiTokens.TYPE_DANGER_BUTTON),
		])
	if choice == &"quit":
		if GameState.has_active_game():
			SaveManager.save_game(&"quit")
		get_tree().quit()
		return
	_busy = false
	_refresh()


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


## A game that has not seen its prologue starts there (GDD 183.2).
func _enter_game() -> void:
	if not StoryDirector.is_event_seen(PROLOGUE_EVENT) and SceneRouter.has_scene(SceneRouter.SCENE_STORY):
		StoryDirector.play_event(PROLOGUE_EVENT)
	else:
		SceneRouter.goto_fishing()


## After the ending the bench has company: a mat and three glasses
## (GDD 9327: post-ending Main Menu variation).
func _dress_for_ending() -> void:
	if not SaveManager.has_save() or not bool(GameState.get_story_value(&"ending_completed")):
		return
	var spot := (_lake_set.get_node("Markers/DartoSpot") as Node3D).position
	var dressing := Node3D.new()
	dressing.name = "EndingDressing"
	_lake_set.get_parent().add_child(dressing)
	for entry: Array in ENDING_PROPS:
		var prop: Node3D = (load(PROP_PATH % entry[0]) as PackedScene).instantiate()
		dressing.add_child(prop)
		var lift := 0.012 if entry[0] == &"prop_drink_glass" else 0.0
		prop.position = spot + DioramaStyle.screen_right() * float(entry[1]) + DioramaStyle.screen_in() * float(entry[2]) + Vector3(0.0, lift, 0.0)
		prop.rotation.y = deg_to_rad(float(entry[3]))
	# The ending's golden light stays on the lake after it (GDD 157).
	DioramaStyle.apply_daylight(_lake_set, DioramaStyle.HOUR_GOLDEN)


func is_ending_dressed() -> bool:
	return has_node("World/EndingDressing")


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
