class_name HoldAssist
extends RefCounted
## ARM WRESTLING INPUT MODE: HOLD ASSIST (GDD 189.11). Holding the action
## makes 8 pushes a second. Each one goes through the same rules as a press,
## so it costs the same stamina; the manual 10-per-second cap still applies.

const RATE_PER_SEC := 8.0

var _clock: float = 0.0
var _was_held: bool = false


## How many pushes `delta` seconds of holding (or not) make.
func step(held: bool, delta: float) -> int:
	if not held:
		_was_held = false
		_clock = 0.0
		return 0
	var pushes := 0
	if not _was_held:
		# The first push lands on the press itself.
		_was_held = true
		pushes = 1
		_clock = 0.0
	_clock += delta
	var interval := 1.0 / RATE_PER_SEC
	while _clock >= interval:
		_clock -= interval
		pushes += 1
	return pushes


static func is_enabled() -> bool:
	return str(GameState.get_setting(&"arm_input_mode")) == "hold_assist"
