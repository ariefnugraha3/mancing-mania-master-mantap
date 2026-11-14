class_name BoxingBot
extends RefCounted
## Plays Tinju Empang the way the game teaches it: wait for the telegraph,
## dodge the way it shows, counter inside the window. Used by unattended QA
## runs (debug builds only) and by the tests that prove every fish can be
## beaten. It reads the same snapshot the HUD reads and presses the same two
## requests a player has, so it cannot do anything a player could not.

## Extra margin before a punch must land, so the bot never throws one that
## the closing window would turn into a blocked hit.
const SAFETY_SEC := 0.03


## Makes at most one request for the current moment of the fight.
## With `perfect` the bot waits for the last 180 ms before it dodges.
static func play(controller: BoxingController, perfect: bool = true) -> void:
	var snapshot := controller.get_snapshot()
	if snapshot["player_phase"] != BoxingController.PLAYER_READY:
		return
	var direction: StringName = snapshot["attack_direction"]
	if direction != &"":
		if not perfect or snapshot["in_perfect_window"]:
			controller.request_dodge(direction)
		return
	if not snapshot["counter_open"]:
		return
	var config := GameData.get_boxing_config()
	var left: float = snapshot["counter_left"]
	if left > config.cross_startup_sec + SAFETY_SEC:
		controller.request_attack(BoxingController.ATTACK_CROSS)
	elif left > config.jab_startup_sec + SAFETY_SEC:
		controller.request_attack(BoxingController.ATTACK_JAB)
