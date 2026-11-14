class_name MoveIcon
extends Control
## A Suwit move drawn as a big, simple hand symbol (GDD 185.19, 189.5): a
## fist for ROCK, two raised fingers for SCISSORS, an open hand for PAPER.
## The shape carries the meaning; the label under it names it.

@export var move: StringName = &"":
	set(value):
		move = value
		queue_redraw()
@export var tint: Color = UiTokens.INK_900:
	set(value):
		tint = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if move == &"":
		return
	var unit := minf(size.x, size.y) / 24.0
	draw_set_transform((size - Vector2(24.0, 24.0) * unit) * 0.5, 0.0, Vector2(unit, unit))
	# Palm
	draw_rect(Rect2(6, 12, 12, 9), tint)
	draw_circle(Vector2(12, 21), 6.0, tint)
	match move:
		SuwitController.ROCK:
			for x: float in [6.0, 9.0, 12.0, 15.0]:
				draw_circle(Vector2(x + 1.5, 11.5), 2.0, tint)
		SuwitController.SCISSORS:
			draw_line(Vector2(9, 12), Vector2(6, 2), tint, 3.0)
			draw_line(Vector2(13, 12), Vector2(16, 2), tint, 3.0)
			draw_circle(Vector2(16.5, 12), 2.0, tint)
		SuwitController.PAPER:
			for index: int in 4:
				var x := 7.5 + float(index) * 3.0
				draw_line(Vector2(x, 13), Vector2(x, 3 + absf(float(index) - 1.5)), tint, 2.6)
			draw_line(Vector2(6, 16), Vector2(2, 11), tint, 2.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
