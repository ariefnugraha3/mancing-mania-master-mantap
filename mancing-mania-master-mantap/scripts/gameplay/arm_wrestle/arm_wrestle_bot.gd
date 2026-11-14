class_name ArmWrestleBot
extends RefCounted
## Plays Panco Maut at a human tapping rate, for tests and unattended QA runs
## (debug builds only). It presses the one button a player has and reads the
## same snapshot the HUD reads.
##
## The rhythm is the one the game teaches: tap steadily, ease off when the
## stamina bar runs low, and push through a burst.

## Taps per second. Seven is a comfortable, sustainable rate for most people.
var taps_per_sec: float = 7.0
## When to stop for breath, and when to start again (stamina ratio).
var rest_below: float = 0.12
var resume_above: float = 0.7
## Off: tap without ever resting.
var rests: bool = true

var _next_tap_at: float = 0.0
var _resting: bool = false


func play(controller: ArmWrestleController) -> void:
	var snapshot := controller.get_snapshot()
	if not ArmWrestleBot._is_live(snapshot["state"]):
		return
	var ratio: float = snapshot["stamina_ratio"]
	var under_attack: bool = snapshot["bursting"] or snapshot["burst_warning"]
	if rests:
		if ratio < rest_below and not under_attack:
			_resting = true
		elif ratio > resume_above or under_attack:
			_resting = false
	if _resting:
		return
	var now: float = snapshot["elapsed"]
	if now + 0.0001 >= _next_tap_at:
		_next_tap_at = now + 1.0 / taps_per_sec
		controller.request_mash()


static func _is_live(state: StringName) -> bool:
	return state == ArmWrestleController.STATE_PULLING or state == ArmWrestleController.STATE_SUDDEN_GRIP \
		or state == ArmWrestleController.STATE_REMATCH
