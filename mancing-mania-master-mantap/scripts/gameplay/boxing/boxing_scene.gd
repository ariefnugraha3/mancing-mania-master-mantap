extends Node
## Root of boxing.tscn: connects the rules (BoxingController) to what the
## player sees and hears (world, HUD, audio) and to the rest of the game
## (pause, the result commit, the way back to the lake).
##
## Four inputs do everything: dodge left, dodge right, jab, cross. Keyboard
## and touch buttons feed the same input actions, and each press is consumed
## once (GDD 42, 94, 176.1).

const TUTORIAL_ID := &"boxing_seen"
const INTRO_BANNER_SEC := 1.6
const SUDDEN_DEATH_BANNER_SEC := 2.4
## A beat on the finished fight before the result is shown.
const RESULT_DELAY_SEC := 1.4
const MAX_TIME_STEP_SEC := 0.1
const DEFAULT_FISH := &"catfish_bruiser"

@onready var _controller: BoxingController = $BoxingController
@onready var _world: BoxingWorld = $World
@onready var _hud: BoxingHud = $BoxingCanvas
@onready var _pause: PauseOverlay = $PauseOverlay

var _result_overlay: DuelResultOverlay
var _dialog: ModalDialog
var _fish: FishData
var _tutorial: bool = false
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
	# The first duel teaches; losing it only means another try (GDD 176.10).
	_tutorial = not GameState.is_tutorial_seen(TUTORIAL_ID)

	_controller.duel_started.connect(_on_duel_started)
	_controller.telegraph_started.connect(_on_telegraph_started)
	_controller.attack_resolved.connect(_on_attack_resolved)
	_controller.counter_window_changed.connect(_on_counter_window_changed)
	_controller.player_dodged.connect(_on_player_dodged)
	_controller.player_attack_started.connect(_on_player_attack_started)
	_controller.player_attack_landed.connect(_on_player_attack_landed)
	_controller.sudden_death_started.connect(_on_sudden_death_started)
	_controller.duel_finished.connect(_on_duel_finished)
	_hud.pause_pressed.connect(_open_pause)
	_pause.quit_requested.connect(_quit_to_menu)

	# The ring stands on the lake bank, so the lake is what you hear.
	AudioManager.set_ambience_state(&"lake")
	AudioManager.set_music_state(&"boxing")
	_world.setup(_fish.id)
	_start_round()


func _process(delta: float) -> void:
	if _leaving or _resolving:
		return
	GameState.add_play_time(minf(delta, MAX_TIME_STEP_SEC))
	_read_input()
	if DebugService.is_auto_duel_enabled():
		BoxingBot.play(_controller)
	_hud.refresh(_controller.get_snapshot(), delta)


func _notification(what: int) -> void:
	if not is_node_ready() or _leaving or _resolving:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Web tab or desktop window lost focus: the clock stops (GDD 176.4).
			_pause.open(true)
		NOTIFICATION_APPLICATION_PAUSED:
			_pause.open(true)


# --- Round ------------------------------------------------------------------

func _start_round() -> void:
	_resolving = false
	_world.reset()
	_controller.start_duel(_fish.id, RNGService.next_duel_seed())


func _read_input() -> void:
	if InputManager.consume_action_once(InputActions.PAUSE):
		_open_pause()
		return
	if InputManager.consume_action_once(&"box_dodge_left"):
		_controller.request_dodge(BoxingController.DIRECTION_LEFT)
	elif InputManager.consume_action_once(&"box_dodge_right"):
		_controller.request_dodge(BoxingController.DIRECTION_RIGHT)
	elif InputManager.consume_action_once(&"box_jab"):
		_controller.request_attack(BoxingController.ATTACK_JAB)
	elif InputManager.consume_action_once(&"box_cross"):
		_controller.request_attack(BoxingController.ATTACK_CROSS)


## Pause is ignored while the result is being committed (GDD 176.7).
func _open_pause() -> void:
	if not _resolving and not _leaving:
		_pause.open()


# --- Controller events ------------------------------------------------------

func _on_duel_started(snapshot: Dictionary) -> void:
	_hud.setup(_fish, snapshot)
	_hud.show_banner(_fish.get_display_name().to_upper(), TextDb.t(&"boxing.intro.subtitle"), INTRO_BANNER_SEC)
	if _tutorial:
		_hud.show_hint(TextDb.t(&"boxing.tutorial.read"))


func _on_telegraph_started(direction: StringName, variant: int, telegraph_sec: float) -> void:
	_world.show_telegraph(direction, variant, telegraph_sec)
	if _tutorial:
		_hud.show_hint(TextDb.t(&"boxing.tutorial.read"))


func _on_attack_resolved(outcome: StringName, direction: StringName) -> void:
	_world.show_impact(outcome, direction)
	match outcome:
		BoxingController.OUTCOME_HIT:
			AudioManager.play_sfx(&"box_hit_heavy")
		BoxingController.OUTCOME_PERFECT:
			AudioManager.play_sfx(&"box_perfect")
		BoxingController.OUTCOME_DODGED:
			AudioManager.play_sfx(&"box_glove_swing")


func _on_counter_window_changed(open: bool, _perfect: bool) -> void:
	if _tutorial:
		_hud.show_hint(TextDb.t(&"boxing.tutorial.counter" if open else &"boxing.tutorial.read"))


func _on_player_dodged(direction: StringName, answering: bool) -> void:
	_world.show_dodge(direction, answering)
	AudioManager.play_sfx(&"box_dodge", -3.0)


func _on_player_attack_started(attack_id: StringName) -> void:
	_world.show_player_attack(attack_id)
	AudioManager.play_sfx(&"box_glove_swing", -4.0)


func _on_player_attack_landed(attack_id: StringName, _damage: float, blocked: bool) -> void:
	_world.show_player_hit(blocked)
	if blocked:
		AudioManager.play_sfx(&"box_block")
	else:
		AudioManager.play_sfx(&"box_hit_light" if attack_id == BoxingController.ATTACK_JAB else &"box_hit_heavy")


func _on_sudden_death_started() -> void:
	_hud.show_banner(TextDb.t(&"boxing.sudden_death.title"), TextDb.t(&"boxing.sudden_death.body"), SUDDEN_DEATH_BANNER_SEC)


# --- Result -----------------------------------------------------------------

func _on_duel_finished(result: Dictionary) -> void:
	_resolving = true
	_hud.refresh(_controller.get_snapshot(), 0.0)
	_hud.show_hint("")
	_world.show_finish(result["player_won"])
	AudioManager.play_sfx(&"box_ko")
	await get_tree().create_timer(RESULT_DELAY_SEC).timeout
	if _leaving:
		return

	if _tutorial and not result["player_won"]:
		# Nothing is recorded: the lesson simply starts over.
		_result_overlay.show_retry()
		await _result_overlay.continued
		if not _leaving:
			_start_round()
		return

	if result["player_won"]:
		GameState.set_tutorial_seen(TUTORIAL_ID)
		_tutorial = false
	_leaving = true
	await DuelExit.leave(result, _result_overlay, _dialog)


## Walking away mid-fight loses the fish and nothing else.
func _quit_to_menu() -> void:
	_leaving = true
	DuelOutcome.clear_pending_catch()
	get_tree().paused = false
	SceneRouter.goto_main_menu()
