class_name SpotDuelScene
extends Node
## Root of the four spot-duel scenes (revision 6.7). Shared with the first
## four duels' scenes in spirit: the rules (Controller), the staging (World),
## the HUD (Canvas), the pause overlay and the one shared exit (DuelExit).
## Each duel's scene only reads its keys, drives its QA bot and turns the
## controller's events into staging and banners.

const MAX_TIME_STEP_SEC := 0.1
const RESULT_DELAY_SEC := 1.6
const DEFAULT_FISH := &"catfish_bruiser"

@onready var _pause: PauseOverlay = $PauseOverlay

var _controller: DuelControllerBase
var _world: SpotDuelWorld
var _hud: SpotDuelHud
var _result_overlay: DuelResultOverlay
var _dialog: ModalDialog
var _fish: FishData
var _resolving: bool = false
var _leaving: bool = false
var _tutorial_shown: bool = false


func _ready() -> void:
	_controller = $Controller as DuelControllerBase
	_world = $World as SpotDuelWorld
	_hud = $Canvas as SpotDuelHud
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
	_controller.duel_finished.connect(_on_duel_finished)
	_hud.pause_pressed.connect(_open_pause)
	_pause.quit_requested.connect(_quit_to_menu)
	var duel_id := _controller.get_duel_id()
	AudioManager.set_ambience_state(_ambience_for(_fish))
	# Each duel is a music state; MusicEngine maps it to a loop.
	AudioManager.set_music_state(duel_id)
	_world.setup(_fish.id)
	_connect_duel()
	_controller.start_duel(_fish.id, RNGService.next_duel_seed())
	_hud.show_banner(_fish.get_display_name().to_upper(), TextDb.t(StringName("%s.intro.subtitle" % duel_id)), 1.6)


func _process(delta: float) -> void:
	if _leaving or _resolving:
		return
	GameState.add_play_time(minf(delta, MAX_TIME_STEP_SEC))
	if InputManager.consume_action_once(InputActions.PAUSE):
		_open_pause()
		return
	if _controller.is_running() and not _tutorial_shown:
		_tutorial_shown = true
		if not GameState.is_tutorial_seen(_tutorial_id()):
			_hud.show_banner("", TextDb.t(StringName("%s.tutorial" % _controller.get_duel_id())), 2.2)
	_read_input()
	if DebugService.is_auto_duel_enabled():
		_play_bot(delta)
	var snapshot := _controller.get_snapshot()
	_hud.refresh(snapshot)
	_update_world(snapshot)


func _notification(what: int) -> void:
	if not is_node_ready() or _leaving or _resolving:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_pause.open(true)


## The ambience of the spot the fish came from.
static func _ambience_for(fish: FishData) -> StringName:
	var location := GameData.get_location(fish.get_location())
	return location.ambience if location != null else &"lake"


func _tutorial_id() -> StringName:
	return StringName("%s_seen" % _controller.get_duel_id())


func _open_pause() -> void:
	if not _resolving and not _leaving:
		_pause.open()


# --- For subclasses -------------------------------------------------------------

func _connect_duel() -> void:
	pass


func _read_input() -> void:
	pass


func _play_bot(_delta: float) -> void:
	pass


func _update_world(_snapshot: Dictionary) -> void:
	pass


# --- Ending ---------------------------------------------------------------------

func _on_duel_finished(result: Dictionary) -> void:
	_resolving = true
	_hud.refresh(_controller.get_snapshot())
	_world.show_end(bool(result.get("player_won", false)))
	await get_tree().create_timer(RESULT_DELAY_SEC).timeout
	if _leaving:
		return
	GameState.set_tutorial_seen(_tutorial_id())
	_leaving = true
	await DuelExit.leave(result, _result_overlay, _dialog)


func _quit_to_menu() -> void:
	_leaving = true
	DuelOutcome.clear_pending_catch()
	get_tree().paused = false
	SceneRouter.goto_main_menu()
