extends Node
## Credits (GDD 183.14): plain lines rolling up over the dusk lake, the
## lake's ambience under them and no fanfare. Holding confirm or touch skips.
## After the ending they lead to the post-game unlock; from the Main Menu
## they go back there.

const SCROLL_PX_PER_SEC := 46.0
const END_HOLD_SEC := 2.5
const LINE_GAP := {"heading": 18, "sub": 54, "role": 30, "name": 6, "final": 40}
const FONT_SIZES := {"heading": 40, "sub": 20, "role": 16, "name": 26, "final": 22}

@onready var _lake_set: Node3D = $World/LakeSet
@onready var _camera: DioramaCamera = $World/CreditsCamera
@onready var _roll: VBoxContainer = $CreditsCanvas/SafeRoot/Roll
@onready var _safe_root: Control = $CreditsCanvas/SafeRoot
@onready var _skip: ProgressBar = $CreditsCanvas/SafeRoot/SkipHoldIndicator
@onready var _skip_label: Label = $CreditsCanvas/SafeRoot/SkipLabel

var _from_menu: bool = false
var _offset: float = 0.0
var _end_left: float = END_HOLD_SEC
var _hold: float = 0.0
var _touch_held: bool = false
var _done: bool = false


func _ready() -> void:
	_from_menu = bool(SceneRouter.get_context().get("from_menu", false))
	_camera.frame_marker(_lake_set.get_node("Markers/StoryWide") as Node3D)
	# The credits roll over the lake at dusk (guide 6.3, 18:00).
	DioramaStyle.apply_daylight(_lake_set, DioramaStyle.HOUR_DUSK)
	AudioManager.set_music_state(&"silence")
	AudioManager.set_ambience_state(&"lake")
	for line: Dictionary in StoryTimelines.get_credits():
		var kind := str(line["kind"])
		var spacer := Control.new()
		spacer.custom_minimum_size.y = float(LINE_GAP.get(kind, 12))
		_roll.add_child(spacer)
		var label := Label.new()
		label.text = TextDb.t(StringName(line["key"]))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiTokens.outline_text(label, int(FONT_SIZES.get(kind, 22)), UiTokens.SUN_500 if kind == "role" else UiTokens.CREAM_50, 7)
		if kind == "heading":
			UiSkin.sign_text(label, 46, DioramaStyle.BUTTER, 12)
		_roll.add_child(label)
	_skip.show_percentage = false
	_skip.max_value = 1.0
	_skip.visible = false
	_skip_label.text = TextDb.t(&"credits.skip")
	UiTokens.outline_text(_skip_label, UiTokens.FONT_SMALL, UiTokens.CREAM_50, 6)
	_safe_root.resized.connect(_layout)
	_layout.call_deferred()


func _process(delta: float) -> void:
	if _done:
		return
	var step := minf(delta, 0.1)
	if DebugService.is_auto_dialogue_enabled():
		step *= 40.0
	_offset += SCROLL_PX_PER_SEC * step
	_roll.position.y = _safe_root.size.y - _offset
	if _roll.position.y + _roll.size.y < _safe_root.size.y * 0.42:
		_offset -= SCROLL_PX_PER_SEC * step
		_end_left -= step
		if _end_left <= 0.0:
			finish(false)
			return
	var holding := _touch_held or Input.is_action_pressed(InputActions.UI_CONFIRM) or Input.is_action_pressed(InputActions.UI_CANCEL)
	_hold = _hold + delta if holding else 0.0
	var needed := float(GameState.get_setting(&"skip_hold_sec"))
	_skip.visible = _hold > 0.15
	_skip.value = clampf(_hold / maxf(needed, 0.1), 0.0, 1.0)
	if _hold >= needed:
		finish(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		_touch_held = event.is_pressed()


## The roll is over, watched or skipped: the post-game unlock follows.
func finish(skipped: bool) -> void:
	if _done:
		return
	_done = true
	GameLog.info(&"STORY", "credits finished", {"skipped": skipped, "from_menu": _from_menu})
	if _from_menu or not GameState.has_active_game():
		SceneRouter.goto_main_menu()
	else:
		StoryDirector.play_event(&"story_postgame_unlock")


func is_from_menu() -> bool:
	return _from_menu


## Android Back (GDD 135): credits opened from the menu go back to it. After
## the ending the roll plays on; holding still skips it.
func handle_back() -> void:
	if _from_menu:
		finish(true)


func _layout() -> void:
	var area := _safe_root.size
	var width := minf(640.0, area.x - 32.0)
	_roll.size = Vector2(width, 0.0)
	_roll.position.x = (area.x - width) * 0.5
	_skip.size = Vector2(180.0, 10.0)
	_skip.position = Vector2(area.x - 196.0, area.y - 28.0)
	_skip_label.position = Vector2(area.x - 196.0, area.y - 56.0)
	_skip_label.visible = true
