class_name ResultController
extends Node
## Root logic of result.tscn (GDD 88, 168.11, 169.13). It shows a result that
## the duel already decided and committed; it never recomputes the winner.
##
## WIN: YOU WIN, the fish goes into the Bucket. LOSS: THE FISH GOT AWAY, and
## nothing else is lost. The fish speaks, Darto answers, then CONTINUE, which
## presses itself after five seconds without input.

signal continued()

const AUTO_CONTINUE_SEC := 5.0

@onready var _root: Node = get_parent()

var _result: Dictionary = {}
var _left: float = AUTO_CONTINUE_SEC
var _counting: bool = false
var _done: bool = false


# --- Public API (GDD 169.13) ------------------------------------------------

func setup_result(result: Dictionary) -> void:
	_result = result
	_left = AUTO_CONTINUE_SEC
	_counting = false
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


## The countdown starts once the dialogue is done (GDD 167.9: important
## dialogue never advances by itself).
func start_auto_continue() -> void:
	_counting = true


func get_auto_continue_left() -> float:
	return _left


func is_counting() -> bool:
	return _counting


func _process(delta: float) -> void:
	if not _counting or _done:
		return
	_left -= minf(delta, 0.1)
	if _left <= 0.0:
		continue_from_result()
