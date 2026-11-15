extends Node
## Root of arm_wrestle.tscn: connects the rules (ArmWrestleController) to the
## world, the HUD and the audio, and hands the result to the shared duel flow.
##
## One input does everything: MASH. Keyboard, mouse and the big touch button
## all feed the same `arm_mash` action, and every press goes to the rules,
## which decide whether it counts (GDD 52, 176.13).

const TUTORIAL_ID := &"arm_wrestle_seen"
const INTRO_BANNER_SEC := 1.6
const BANNER_SEC := 2.4
const RESULT_DELAY_SEC := 1.4
const MAX_TIME_STEP_SEC := 0.1
## A press keeps the body in its pushing pose for this long.
const PRESSING_HOLD_SEC := 0.3
## The accepted-press click gets quieter as the rate climbs (GDD 175.9).
const CLICK_QUIET_DB_PER_PRESS := 0.9
const DEFAULT_FISH := &"catfish_bruiser"

@onready var _controller: ArmWrestleController = $ArmWrestleController
@onready var _world: ArmWrestleWorld = $World
@onready var _hud: ArmWrestleHud = $ArmCanvas
@onready var _pause: PauseOverlay = $PauseOverlay

var _result_overlay: DuelResultOverlay
var _dialog: ModalDialog
var _fish: FishData
var _resolving: bool = false
var _leaving: bool = false
var _pressing_left: float = 0.0
var _recent_presses: Array[float] = []
var _clock: float = 0.0
var _creak_left: float = 0.0


func _ready() -> void:
	_result_overlay = DuelResultOverlay.new()
	_result_overlay.name = "ResultOverlay"
	add_child(_result_overlay)
	_dialog = ModalDialog.new()
	_dialog.name = "NoticeDialog"
	add_child(_dialog)

	var fish_id: StringName = SceneRouter.get_context().get("fish_id", GameState.current_fish)
	_fish = GameData.get_fish(fish_id)
	if _fish == null:
		_fish = GameData.get_fish(DEFAULT_FISH)

	_controller.duel_started.connect(_on_duel_started)
	_controller.press_accepted.connect(_on_press_accepted)
	_controller.burst_warning_started.connect(_on_burst_warning)
	_controller.sudden_grip_started.connect(_on_sudden_grip)
	_controller.rematch_started.connect(_on_rematch)
	_controller.duel_finished.connect(_on_duel_finished)
	_hud.pause_pressed.connect(_open_pause)
	_pause.quit_requested.connect(_quit_to_menu)

	AudioManager.set_ambience_state(&"lake")
	AudioManager.set_music_state(&"arm_wrestle")
	_world.setup(_fish.id)
	_hud.setup(_fish)
	_controller.start_duel(_fish.id, RNGService.next_duel_seed())


func _process(delta: float) -> void:
	if _leaving or _resolving:
		return
	_clock += delta
	GameState.add_play_time(minf(delta, MAX_TIME_STEP_SEC))
	_pressing_left = maxf(_pressing_left - delta, 0.0)
	if InputManager.consume_action_once(InputActions.PAUSE):
		_open_pause()
		return
	if HoldAssist.is_enabled():
		InputManager.consume_action_once(&"arm_mash")
		var held := InputManager.get_action_strength_safe(&"arm_mash") > 0.0
		for push: int in _hold_assist.step(held, minf(delta, MAX_TIME_STEP_SEC)):
			_controller.request_mash()
	elif InputManager.consume_action_once(&"arm_mash"):
		_controller.request_mash()
	if DebugService.is_auto_duel_enabled():
		_bot().play(_controller)
	var snapshot := _controller.get_snapshot()
	_hud.refresh(snapshot)
	_world.show_state(snapshot, _pressing_left > 0.0)
	_play_strain(snapshot, delta)


func _notification(what: int) -> void:
	if not is_node_ready() or _leaving or _resolving:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_pause.open(true)


func _open_pause() -> void:
	if not _resolving and not _leaving:
		_pause.open()


var _auto_bot: ArmWrestleBot
var _hold_assist := HoldAssist.new()


func _bot() -> ArmWrestleBot:
	if _auto_bot == null:
		_auto_bot = ArmWrestleBot.new()
	return _auto_bot


# --- Controller events ------------------------------------------------------

func _on_duel_started(_snapshot: Dictionary) -> void:
	_hud.show_banner(_fish.get_display_name().to_upper(), TextDb.t(&"arm.intro.subtitle"), INTRO_BANNER_SEC)
	if not GameState.is_tutorial_seen(TUTORIAL_ID):
		_hud.show_hint(TextDb.t(&"arm.tutorial.hold" if HoldAssist.is_enabled() else &"arm.tutorial.mash"))


func _on_press_accepted(_power: float) -> void:
	_pressing_left = PRESSING_HOLD_SEC
	# Fewer clicks get through, and each one is softer, as the rate climbs.
	_recent_presses.append(_clock)
	while not _recent_presses.is_empty() and _clock - _recent_presses[0] > 1.0:
		_recent_presses.pop_front()
	AudioManager.play_sfx(&"arm_mash_click", -CLICK_QUIET_DB_PER_PRESS * float(_recent_presses.size()))
	if not GameState.is_tutorial_seen(TUTORIAL_ID) and float(_controller.get_snapshot()["stamina_ratio"]) < 0.3:
		_hud.show_hint(TextDb.t(&"arm.tutorial.rest"))


func _on_burst_warning(_seconds: float) -> void:
	AudioManager.play_sfx(&"arm_burst_warning")


func _on_sudden_grip() -> void:
	_hud.show_banner(TextDb.t(&"arm.sudden_grip.title"), TextDb.t(&"arm.sudden_grip.body"), BANNER_SEC)


func _on_rematch() -> void:
	_hud.show_banner(TextDb.t(&"arm.rematch.title"), TextDb.t(&"arm.rematch.body"), BANNER_SEC)


## The table creaks and the hands strain while the hands are under load.
func _play_strain(snapshot: Dictionary, delta: float) -> void:
	_creak_left -= delta
	if _creak_left > 0.0:
		return
	var load := float(snapshot["fish_force"]) / 20.0 + (0.5 if _pressing_left > 0.0 else 0.0)
	_creak_left = lerpf(1.6, 0.6, clampf(load, 0.0, 1.0))
	AudioManager.play_sfx(&"arm_table_creak", -10.0 + 4.0 * clampf(load, 0.0, 1.0), RNGService.cosmetic.randi() & 0xFFFF)
	if _pressing_left > 0.0 or snapshot["bursting"]:
		AudioManager.play_sfx(&"arm_strain", -8.0, RNGService.cosmetic.randi() & 0xFFFF)


# --- Result -----------------------------------------------------------------

func _on_duel_finished(result: Dictionary) -> void:
	_resolving = true
	_hud.refresh(_controller.get_snapshot())
	_hud.show_hint("")
	_world.show_finish(result["player_won"])
	AudioManager.play_sfx(&"arm_win" if result["player_won"] else &"arm_lose")
	await get_tree().create_timer(RESULT_DELAY_SEC).timeout
	if _leaving:
		return
	GameState.set_tutorial_seen(TUTORIAL_ID)
	_leaving = true
	await DuelExit.leave(result, _result_overlay, _dialog)


func _quit_to_menu() -> void:
	_leaving = true
	DuelOutcome.clear_pending_catch()
	get_tree().paused = false
	SceneRouter.goto_main_menu()
