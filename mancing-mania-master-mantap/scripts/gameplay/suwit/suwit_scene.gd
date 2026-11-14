extends Node
## Root of suwit.tscn: the rules, the table, the HUD and the shared exit.
## Keys 1, 2, 3 and C, or the four buttons, drive it (GDD Section 66).

const TUTORIAL_ID := &"suwit_seen"
const MAX_TIME_STEP_SEC := 0.1
const RESULT_DELAY_SEC := 1.6
const MOVE_ACTIONS: Dictionary = {&"suwit_rock": &"rock", &"suwit_scissors": &"scissors", &"suwit_paper": &"paper"}
const DEFAULT_FISH := &"catfish_bruiser"

@onready var _controller: SuwitController = $SuwitController
@onready var _world: SuwitWorld = $World
@onready var _hud: SuwitHud = $SuwitCanvas
@onready var _pause: PauseOverlay = $PauseOverlay

var _result_overlay: DuelResultOverlay
var _dialog: ModalDialog
var _fish: FishData
var _resolving: bool = false
var _leaving: bool = false


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
	_controller.round_started.connect(func(_index: int) -> void: _world.show_round_start())
	_controller.tell_shown.connect(_on_tell)
	_controller.round_resolved.connect(_on_round_resolved)
	_controller.duel_finished.connect(_on_duel_finished)
	_hud.move_pressed.connect(_controller.choose_move)
	_hud.charm_pressed.connect(_use_charm)
	_hud.pause_pressed.connect(_open_pause)
	_pause.quit_requested.connect(_quit_to_menu)
	AudioManager.set_ambience_state(&"lake")
	AudioManager.set_music_state(&"suwit")
	_world.setup(_fish.id)
	_controller.start_duel(_fish.id, RNGService.next_duel_seed())
	_hud.show_banner(_fish.display_name.to_upper(), TextDb.t(&"suwit.intro.subtitle"), 1.6)


func _process(delta: float) -> void:
	if _leaving or _resolving:
		return
	GameState.add_play_time(minf(delta, MAX_TIME_STEP_SEC))
	if InputManager.consume_action_once(InputActions.PAUSE):
		_open_pause()
		return
	for action: StringName in MOVE_ACTIONS:
		if InputManager.consume_action_once(action):
			_controller.choose_move(MOVE_ACTIONS[action])
	if InputManager.consume_action_once(&"suwit_charm"):
		_use_charm()
	if DebugService.is_auto_duel_enabled():
		_play_bot()
	_hud.refresh(_controller.get_snapshot())


func _notification(what: int) -> void:
	if not is_node_ready() or _leaving or _resolving:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_pause.open(true)


func _open_pause() -> void:
	if not _resolving and not _leaving:
		_pause.open()


func _use_charm() -> void:
	if _controller.use_charm():
		AudioManager.play_ui(&"ui_click")


## The QA bot answers the tell once it appears.
func _play_bot() -> void:
	var snapshot := _controller.get_snapshot()
	if snapshot["player_move"] == &"" and snapshot["tell"] != &"":
		for move: StringName in SuwitController.MOVES:
			if SuwitController.BEATS[move] == snapshot["tell"]:
				_controller.choose_move(move)


func _on_tell(_move: StringName) -> void:
	var truthful: bool = _controller.get_snapshot()["tell"] == _controller.debug_get_hidden_move()
	_world.show_tell(truthful)
	if not GameState.is_tutorial_seen(TUTORIAL_ID):
		_hud.show_banner("", TextDb.t(&"suwit.tutorial"), 1.8)


func _on_round_resolved(outcome: Dictionary) -> void:
	_world.show_reveal(outcome)
	var title := TextDb.t(StringName("suwit.outcome.%s" % outcome["outcome"]))
	var body := TextDb.t(&"suwit.panic_pick") if outcome["panic"] else ""
	_hud.show_banner(title, body, SuwitController.REVEAL_SEC)
	AudioManager.play_ui(&"ui_click")


func _on_duel_finished(result: Dictionary) -> void:
	_resolving = true
	_hud.refresh(_controller.get_snapshot())
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
