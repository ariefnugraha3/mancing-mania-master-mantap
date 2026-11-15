extends SpotDuelScene
## Root of pinang.tscn. LEFT and RIGHT in turn (A and D, or the buttons).

const BOT_INTERVAL_SEC := 0.2

var _pinang: PinangController
var _pinang_world: PinangWorld
var _bot_wait: float = 0.0
var _bot_side: StringName = PinangController.LEFT


func _connect_duel() -> void:
	_pinang = _controller as PinangController
	_pinang_world = _world as PinangWorld
	(_hud as PinangHud).setup(_fish)
	_pinang.climbed.connect(func(_height: float) -> void: _pinang_world.show_climb())
	_pinang.player_slipped.connect(_on_slipped)
	_pinang.fish_climbed.connect(func(_height: float) -> void: _pinang_world.show_fish_climb())
	_pinang.fish_slipped.connect(_pinang_world.show_fish_slip)


func _read_input() -> void:
	if InputManager.consume_action_once(&"box_dodge_left"):
		_pinang.press(PinangController.LEFT)
	if InputManager.consume_action_once(&"box_dodge_right"):
		_pinang.press(PinangController.RIGHT)


## The QA bot climbs at a steady rhythm.
func _play_bot(delta: float) -> void:
	if _pinang.get_state() != PinangController.STATE_CLIMB:
		return
	_bot_wait -= delta
	if _bot_wait <= 0.0:
		_bot_wait = BOT_INTERVAL_SEC
		var expected := _pinang.get_expected_side()
		_bot_side = expected if expected != &"" else _bot_side
		_pinang.press(_bot_side)


func _update_world(snapshot: Dictionary) -> void:
	if snapshot.has("height"):
		_pinang_world.set_heights(float(snapshot["height"]), float(snapshot["fish_height"]))


func _on_slipped(reason: StringName) -> void:
	_pinang_world.show_slip()
	var body := TextDb.t(&"pinang.grease") if reason == PinangController.SLIP_GREASE else ""
	_hud.show_banner(TextDb.t(&"pinang.slip"), body, 0.8)
	AudioManager.play_ui(&"ui_disabled")
