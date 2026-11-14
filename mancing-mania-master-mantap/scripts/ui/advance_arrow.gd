class_name AdvanceArrow
extends Control
## The small bouncing triangle at the corner of a dialogue card: "tap for the
## next line". It holds still with Reduced Motion on.

@export var tint: Color = UiTokens.TERRACOTTA_500

var _clock: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(18.0, 16.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var bounce := 0.0 if bool(GameState.get_setting(&"reduced_motion")) else absf(sin(_clock * 4.0)) * 4.0
	var top := (size.y - 12.0) * 0.5 - 2.0 + bounce
	var centre := size.x * 0.5
	var points := PackedVector2Array([Vector2(centre - 8.0, top), Vector2(centre + 8.0, top), Vector2(centre, top + 11.0)])
	draw_colored_polygon(points, tint)
	var rim := PackedVector2Array(points)
	rim.append(points[0])
	draw_polyline(rim, UiSkin.edge_of(tint), 2.0, true)
