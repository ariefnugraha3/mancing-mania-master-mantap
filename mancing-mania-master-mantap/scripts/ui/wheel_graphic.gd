class_name WheelGraphic
extends Control
## The painted Wheel of Fate (GDD 38, 167.9): eight segments, two per duel,
## each with its name and its own pattern, on paper colours. It is a painted
## wheel, not a casino one: no lights, no coin shower.

const DUEL_COLORS: Dictionary = {
	&"boxing": Color("b8654e"), &"arm_wrestle": Color("778b59"), &"dance": Color("e4ae55"), &"suwit": Color("557f7a"),
}

## Rotation in turns; segment `i` is under the top pointer at i / 8.
var turns: float = 0.0:
	set(value):
		turns = value
		queue_redraw()
var highlight: int = -1:
	set(value):
		highlight = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 6.0
	var count := WheelController.SEGMENTS.size()
	var step := TAU / float(count)
	draw_circle(centre, radius + 6.0, UiTokens.INK_900)
	for index: int in count:
		var duel: StringName = WheelController.SEGMENTS[index]
		# Segment i is centred at i / 8 of a turn clockwise from the top;
		# the wheel as a whole is turned back by `turns`.
		var middle := (float(index) / float(count) - turns) * TAU - PI * 0.5
		var points := PackedVector2Array([centre])
		for arc: int in 13:
			var angle := middle - step * 0.5 + step * float(arc) / 12.0
			points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
		var color: Color = DUEL_COLORS[duel]
		if index == highlight:
			color = color.lightened(0.25)
		draw_colored_polygon(points, color)
		draw_polyline(points + PackedVector2Array([centre]), UiTokens.INK_900, 3.0, true)
		# Pattern by duel, so segments differ by more than colour.
		var mark := centre + Vector2(cos(middle), sin(middle)) * radius * 0.42
		match duel:
			&"boxing":
				draw_circle(mark, radius * 0.07, UiTokens.CREAM_50)
			&"arm_wrestle":
				draw_rect(Rect2(mark - Vector2.ONE * radius * 0.06, Vector2.ONE * radius * 0.12), UiTokens.CREAM_50)
			&"dance":
				draw_colored_polygon(PackedVector2Array([mark + Vector2(0, -1) * radius * 0.08, mark + Vector2(1, 0.8) * radius * 0.07, mark + Vector2(-1, 0.8) * radius * 0.07]), UiTokens.CREAM_50)
			&"suwit":
				draw_colored_polygon(PackedVector2Array([mark + Vector2(0, -1) * radius * 0.08, mark + Vector2(1, 0) * radius * 0.08, mark + Vector2(0, 1) * radius * 0.08, mark + Vector2(-1, 0) * radius * 0.08]), UiTokens.CREAM_50)
		var text_at := centre + Vector2(cos(middle), sin(middle)) * radius * 0.72
		var label := TextDb.t(StringName("duel.%s.upper" % duel))
		var font := get_theme_default_font()
		var font_size := int(radius * 0.085)
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_set_transform(text_at, middle + PI * 0.5, Vector2.ONE)
		draw_string_outline(font, Vector2(-width * 0.5, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, UiTokens.INK_900)
		draw_string(font, Vector2(-width * 0.5, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiTokens.CREAM_50)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(centre, radius * 0.12, UiTokens.CREAM_100)
	draw_arc(centre, radius * 0.12, 0.0, TAU, 24, UiTokens.INK_900, 3.0)
