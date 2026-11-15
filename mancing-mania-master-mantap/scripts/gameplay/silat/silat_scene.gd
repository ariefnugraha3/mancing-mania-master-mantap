extends SpotDuelScene
## Root of silat.tscn. The four arrows (S D J K, or the buttons) answer the
## fish's sequence.

const ACTIONS: Dictionary[StringName, StringName] = {
	&"dance_lane_1": SilatController.LEFT,
	&"dance_lane_2": SilatController.DOWN,
	&"dance_lane_3": SilatController.UP,
	&"dance_lane_4": SilatController.RIGHT,
}
const BOT_DELAY_SEC := 0.25
const OUTCOME_TEXT: Dictionary[StringName, StringName] = {
	SilatController.OUTCOME_COUNTER: &"silat.counter",
	SilatController.OUTCOME_WRONG: &"silat.wrong",
	SilatController.OUTCOME_SLOW: &"silat.slow",
}

var _silat: SilatController
var _silat_world: SilatWorld
var _bot_wait: float = 0.0


func _connect_duel() -> void:
	_silat = _controller as SilatController
	_silat_world = _world as SilatWorld
	_silat.show_step.connect(_silat_world.show_move)
	_silat.input_checked.connect(_on_input)
	_silat.round_resolved.connect(_on_round)


func _read_input() -> void:
	for action: StringName in ACTIONS:
		if InputManager.consume_action_once(action):
			_silat.press(ACTIONS[action])


## The QA bot answers each move a quarter second apart.
func _play_bot(delta: float) -> void:
	if _silat.get_state() != SilatController.STATE_INPUT:
		_bot_wait = BOT_DELAY_SEC
		return
	_bot_wait -= delta
	if _bot_wait <= 0.0:
		_bot_wait = BOT_DELAY_SEC
		var snapshot := _silat.get_snapshot()
		_silat.press(_silat.debug_get_sequence()[int(snapshot["input_index"])])


func _on_input(move: StringName, correct: bool) -> void:
	_silat_world.show_answer(move, correct)
	AudioManager.play_ui(&"ui_click" if correct else &"ui_back")


func _on_round(outcome: Dictionary) -> void:
	var result: StringName = outcome["outcome"]
	_silat_world.show_round(result)
	_hud.show_banner(TextDb.t(OUTCOME_TEXT[result]), "", SilatController.REVEAL_SEC)
	AudioManager.play_ui(&"ui_sell" if result == SilatController.OUTCOME_COUNTER else &"ui_disabled")
