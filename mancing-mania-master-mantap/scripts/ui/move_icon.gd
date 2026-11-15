class_name MoveIcon
extends Control
## A Suwit move drawn as a big hand sticker (GDD 185.19, 189.5): a fist for
## ROCK, two raised fingers for SCISSORS, an open hand for PAPER. The shape
## carries the meaning; the label under it names it. The hands are IconPainter
## icons, so they share the outline, lip and light of every other icon.

const ICONS: Dictionary = {
	SuwitController.ROCK: IconPainter.ROCK,
	SuwitController.SCISSORS: IconPainter.SCISSORS,
	SuwitController.PAPER: IconPainter.PAPER,
}

@export var move: StringName = &"":
	set(value):
		move = value
		queue_redraw()
## Multiplies the hand's colours; white shows it as drawn.
@export var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()
## A soft teal glow behind the hand, for the move the Charm revealed as real.
@export var highlighted: bool = false:
	set(value):
		highlighted = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if not ICONS.has(move):
		return
	var side := minf(size.x, size.y)
	var rect := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	if highlighted:
		var centre := rect.get_center()
		draw_circle(centre, side * 0.5, Color(UiTokens.LAKE_500, 0.22))
		draw_arc(centre, side * 0.47, 0.0, TAU, 48, Color(UiTokens.LAKE_500, 0.8), maxf(2.0, side * 0.04), true)
	# A little air around the hand so the fingertips never touch a button rim.
	IconPainter.paint(get_canvas_item(), ICONS[move], rect.grow(-side * 0.05), tint)
