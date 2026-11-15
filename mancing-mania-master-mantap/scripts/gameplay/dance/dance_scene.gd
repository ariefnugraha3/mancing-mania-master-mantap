extends Node
## Root of dance.tscn: prepares the koplo track, starts it once audio can be
## heard, sends lane presses to the rules timed on the song clock, and hands
## the result to the shared duel flow.
##
## The song clock follows the audio, not the frame (GDD 62). After any pause
## the duel restarts from its count-in with the same chart: resuming at an
## unknown offset is not safe (GDD 175.16).

const TUTORIAL_ID := &"dance_seen"
const RESULT_DELAY_SEC := 1.6
const MAX_TIME_STEP_SEC := 0.1
const LANE_ACTIONS: Array[StringName] = [&"dance_lane_1", &"dance_lane_2", &"dance_lane_3", &"dance_lane_4"]
const DEFAULT_FISH := &"catfish_bruiser"

const PHASE_PREPARING := &"preparing"
const PHASE_PLAYING := &"playing"
const PHASE_DONE := &"done"

@onready var _controller: DanceController = $DanceController
@onready var _clock: RhythmClock = $RhythmClock
@onready var _world: DanceWorld = $World
@onready var _hud: DanceHud = $DanceCanvas
@onready var _pause: PauseOverlay = $PauseOverlay

var _result_overlay: DuelResultOverlay
var _dialog: ModalDialog
var _fish: FishData
var _seed: int = 0
var _phase: StringName = PHASE_PREPARING
var _leaving: bool = false
var _music: MusicEngine


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
	_seed = RNGService.next_duel_seed()
	# Opened without Boot (debug tools, probes): build the audio first.
	if AudioManager.get_music_engine() == null:
		AudioManager.initialize_procedural_audio()
	_music = AudioManager.get_music_engine()
	_controller.clock = _clock
	_controller.note_judged.connect(_on_note_judged)
	_controller.fish_note_judged.connect(_on_fish_note_judged)
	_controller.encore_started.connect(_on_encore)
	_controller.duel_finished.connect(_on_duel_finished)
	_hud.lane_pressed.connect(_on_lane)
	_hud.pause_pressed.connect(_open_pause)
	_pause.quit_requested.connect(_quit_to_menu)
	_pause.closed.connect(_on_pause_closed)

	AudioManager.set_ambience_state(&"lake")
	AudioManager.set_music_state(&"dance")
	_prepare()


func _process(delta: float) -> void:
	if _leaving:
		return
	GameState.add_play_time(minf(delta, MAX_TIME_STEP_SEC))
	if InputManager.consume_action_once(InputActions.PAUSE):
		_open_pause()
		return
	match _phase:
		PHASE_PREPARING:
			_hud.show_banner(TextDb.t(&"dance.get_ready"), TextDb.tf(&"dance.loading", {"percent": roundi(_music.get_song_progress() * 100.0)}), 0.2)
			# Audio must be heard before the duel starts (GDD 175.16).
			if _music.is_song_ready() and AudioManager.is_audio_ready():
				_start_song()
		PHASE_PLAYING:
			if DebugService.is_auto_duel_enabled():
				_play_bot()
			_controller.advance(delta)
			_hud.refresh(_controller, _controller.get_snapshot())


## Lane keys are read the moment they arrive, so they are timed when pressed.
func _unhandled_input(event: InputEvent) -> void:
	if _phase != PHASE_PLAYING or not InputManager.is_gameplay_input_enabled() or event.is_echo():
		return
	for lane: int in LANE_ACTIONS.size():
		if event.is_action_pressed(LANE_ACTIONS[lane]):
			get_viewport().set_input_as_handled()
			_on_lane(lane)
			return


func _notification(what: int) -> void:
	if not is_node_ready() or _leaving or _phase == PHASE_DONE:
		return
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_pause.open(true)


# --- Flow -------------------------------------------------------------------

func _prepare() -> void:
	_phase = PHASE_PREPARING
	_controller.start_duel(_fish.id, _seed)
	var chart := _controller.get_chart()
	_world.setup(_fish.id, float(chart["bpm"]))
	_hud.setup(_fish, chart)
	if not _music.is_song_ready() or _music.get_song_schedule().get("seed", -1) != chart["schedule"]["seed"]:
		_music.prepare_song(chart["schedule"])


func _start_song() -> void:
	_phase = PHASE_PLAYING
	_clock.reset()
	_music.play_song(0.0)
	_hud.show_banner(_fish.get_display_name().to_upper(), TextDb.t(&"dance.intro.subtitle"), 1.8)
	if not GameState.is_tutorial_seen(TUTORIAL_ID):
		_hud.show_hint(TextDb.t(&"dance.tutorial.hit"))


## Any pause restarts the duel from its count-in with the same chart.
func _on_pause_closed() -> void:
	if _leaving or _phase != PHASE_PLAYING:
		return
	_music.stop_song()
	_world.reset()
	_prepare()


func _open_pause() -> void:
	if _phase != PHASE_DONE and not _leaving:
		_pause.open()


func _on_lane(lane: int) -> void:
	if _phase != PHASE_PLAYING or not InputManager.is_gameplay_input_enabled():
		return
	_controller.submit_lane(lane, _clock.get_time())


## The QA bot presses each note on time, as the clock reaches it.
func _play_bot() -> void:
	var notes := _controller.get_notes()
	var now := _clock.get_time()
	for index: int in notes.size():
		if _controller.get_player_judgment(index) == &"" and absf(float(notes[index]["time"]) - now) <= 0.03:
			_controller.submit_lane(int(notes[index]["lane"]), now)


# --- Controller events ------------------------------------------------------

func _on_note_judged(_index: int, judgment: StringName, lane: int, _delta_ms: float) -> void:
	_hud.show_judgment(judgment, lane)
	_world.show_player_note(judgment, lane, int(_controller.get_snapshot()["player_combo"]))
	if judgment != DanceController.MISS and not GameState.is_tutorial_seen(TUTORIAL_ID):
		_hud.show_hint("")


func _on_fish_note_judged(_index: int, judgment: StringName, _lane: int) -> void:
	_world.show_fish_note(judgment)


func _on_encore() -> void:
	_hud.show_banner(TextDb.t(&"dance.encore.title"), TextDb.t(&"dance.encore.body"), 2.0)


func _on_duel_finished(result: Dictionary) -> void:
	_phase = PHASE_DONE
	_hud.refresh(_controller, _controller.get_snapshot())
	_world.show_finish(result["player_won"])
	await get_tree().create_timer(RESULT_DELAY_SEC).timeout
	_music.stop_song()
	if _leaving:
		return
	GameState.set_tutorial_seen(TUTORIAL_ID)
	_leaving = true
	await DuelExit.leave(result, _result_overlay, _dialog)


func _quit_to_menu() -> void:
	_leaving = true
	_music.stop_song()
	DuelOutcome.clear_pending_catch()
	get_tree().paused = false
	SceneRouter.goto_main_menu()
