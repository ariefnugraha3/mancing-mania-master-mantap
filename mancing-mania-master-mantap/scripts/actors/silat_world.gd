class_name SilatWorld
extends SpotDuelWorld
## The Silat stage (revision 6.7): a bamboo platform by the river with
## Darto and the fish face to face. The fish shows each move with a step in
## that direction; Darto answers with the same step, then the counter or the
## hit plays out.

const STEP := 0.09
const STEP_SEC := 0.16

var _jab_toggle: bool = false


func _hud_insets() -> Vector2:
	return Vector2(110.0, 0.40)


func show_move(move: StringName) -> void:
	play_fish(&"box_block", 0.05)
	_step(_fish_anchor, _fish_base, move)
	if _fish != null:
		DioramaMotion.squash(_fish, 0.06)


func show_answer(move: StringName, correct: bool) -> void:
	_step(_darto, _darto_base, move)
	if correct:
		_jab_toggle = not _jab_toggle
		play_darto(&"box_jab" if _jab_toggle else &"box_cross", 0.04)
	else:
		play_darto(&"box_hit_left", 0.04)


func show_round(outcome: StringName) -> void:
	if outcome == SilatController.OUTCOME_COUNTER:
		play_darto(&"box_cross", 0.04)
		play_fish(&"box_hit", 0.04)
		if _fish != null:
			DioramaMotion.squash(_fish, 0.12)
	else:
		play_fish(&"arm_burst", 0.04)
		play_darto(&"box_hit_left", 0.04)
		DioramaMotion.squash(_darto_rig, 0.12)
	queue_idle()


func show_end(player_won: bool) -> void:
	if player_won:
		play_darto(&"box_win")
		play_fish(&"box_ko")
		DioramaMotion.stretch(_darto_rig, 0.1)
	else:
		play_darto(&"box_ko")
		play_fish(&"dance_win")
		if _fish != null:
			DioramaMotion.stretch(_fish, 0.1)


## A quick step in the move's direction and back, in screen terms.
func _step(node: Node3D, base: Transform3D, move: StringName) -> void:
	var offset := Vector3.ZERO
	match move:
		SilatController.LEFT:
			offset = -DioramaStyle.screen_right() * STEP
		SilatController.RIGHT:
			offset = DioramaStyle.screen_right() * STEP
		SilatController.UP:
			offset = Vector3.UP * STEP * 0.8
		SilatController.DOWN:
			offset = Vector3.DOWN * STEP * 0.35
	if DioramaMotion.is_reduced():
		offset *= 0.4
	var tween := node.create_tween()
	tween.tween_property(node, "position", base.origin + offset, STEP_SEC * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position", base.origin, STEP_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
