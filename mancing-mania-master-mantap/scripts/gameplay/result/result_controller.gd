class_name ResultController
extends Node
## Root logic of result.tscn (GDD 88, 168.11, 169.13). It shows a result that
## the duel already decided and committed; it never recomputes the winner.
##
## WIN: YOU WIN, the fish goes into the Bucket. LOSS: THE FISH GOT AWAY, and
## nothing else is lost. The fish speaks, Darto answers, then the player taps
## CONTINUE to return to the lake.

signal continued()

@onready var _root: Node = get_parent()

var _result: Dictionary = {}
var _done: bool = false


# --- Public API (GDD 169.13) ------------------------------------------------

func setup_result(result: Dictionary) -> void:
	_result = result
	_done = false


func continue_from_result() -> void:
	if _done:
		return
	_done = true
	continued.emit()
	SceneRouter.goto_fishing()


# --- Extras -----------------------------------------------------------------

func get_result() -> Dictionary:
	return _result
