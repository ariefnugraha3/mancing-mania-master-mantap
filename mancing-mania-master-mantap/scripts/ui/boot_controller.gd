extends Node
## Boot sequence (GDD 168.1): detect the platform, validate the game data,
## load the save, warm the procedural audio, then hand over to the Main Menu.
##
## In debug and test builds invalid data stops the boot with a readable list
## of problems instead of failing somewhere later in gameplay.

signal boot_failed(errors: PackedStringArray)

const STEP_HOLD_SEC := 0.12
const FADE_IN_SEC := 0.25
const MAX_ERRORS_SHOWN := 8

@onready var _title_line_1: Label = $"../LoadingCanvas/LoadingRoot/LogoBlock/TitleLine1"
@onready var _title_line_2: Label = $"../LoadingCanvas/LoadingRoot/LogoBlock/TitleLine2"
@onready var _status_label: Label = $"../LoadingCanvas/LoadingRoot/StatusLabel"
@onready var _progress_bar: ProgressBar = $"../LoadingCanvas/LoadingRoot/ProgressBar"
@onready var _fade_rect: ColorRect = $"../TransitionLayer/FadeRect"

var validation_errors: PackedStringArray = PackedStringArray()


func _ready() -> void:
	_title_line_1.text = TextDb.t(&"boot.title_line_1")
	_title_line_2.text = TextDb.t(&"boot.title_line_2")
	_status_label.text = ""
	_progress_bar.value = 0.0
	_run.call_deferred()


func _run() -> void:
	var fade := create_tween()
	fade.tween_property(_fade_rect, "color:a", 0.0, FADE_IN_SEC)

	await _step(&"boot.status.platform", 0.15)
	GameLog.info(&"BOOT", "platform", {
		"platform": SaveSchema.current_platform(),
		"viewport_class": PlatformService.get_viewport_class(),
	})

	await _step(&"boot.status.data", 0.4)
	if OS.is_debug_build():
		validation_errors = collect_validation_errors()
		if not validation_errors.is_empty():
			_show_validation_failure()
			return

	await _step(&"boot.status.save", 0.65)
	if SaveManager.has_save():
		# A failed load is reported by the Main Menu, which offers recovery.
		SaveManager.load_game()

	await _step(&"boot.status.audio", 0.85)
	AudioManager.initialize_procedural_audio()

	await _step(&"boot.status.done", 1.0)
	SceneRouter.goto_main_menu()


## Everything Boot checks before the game is allowed to start.
static func collect_validation_errors() -> PackedStringArray:
	var errors := GameData.validate_all()
	errors.append_array(DataValidator.validate_story_events(StoryDirector.get_all_events(), StoryDirector.TRIGGER_TYPES))
	for action: StringName in InputActions.get_all():
		if not InputMap.has_action(action):
			errors.append("input: action '%s' is missing from the InputMap" % action)
		elif InputMap.action_get_events(action).is_empty():
			errors.append("input: action '%s' has no default binding" % action)
	for sfx_id: StringName in AudioManager.CRITICAL_SFX_IDS + AudioManager.FISHING_SFX_IDS + AudioManager.MARKET_SFX_IDS:
		if not ResourceLoader.exists(AudioManager.PRESET_PATH % sfx_id):
			errors.append("audio: preset '%s' is missing" % sfx_id)
	return errors


func _step(status_key: StringName, progress: float) -> void:
	_status_label.text = TextDb.t(status_key)
	var tween := create_tween()
	tween.tween_property(_progress_bar, "value", progress, STEP_HOLD_SEC)
	await tween.finished


func _show_validation_failure() -> void:
	var lines := PackedStringArray([TextDb.t(&"boot.error.title"), TextDb.t(&"boot.error.body"), ""])
	for index: int in mini(validation_errors.size(), MAX_ERRORS_SHOWN):
		lines.append("- " + validation_errors[index])
	if validation_errors.size() > MAX_ERRORS_SHOWN:
		lines.append("(+%d more in the log)" % (validation_errors.size() - MAX_ERRORS_SHOWN))
	_status_label.text = "\n".join(lines)
	_progress_bar.visible = false
	for message: String in validation_errors:
		GameLog.error(&"BOOT", "data validation failed", {"problem": message})
	boot_failed.emit(validation_errors)
