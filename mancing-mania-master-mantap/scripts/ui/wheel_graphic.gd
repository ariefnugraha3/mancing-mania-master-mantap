class_name WheelGraphic
extends Control
## The painted Wheel of Fate (GDD 38, 167.9): eight segments, two per duel,
## each with its name and its own pattern, in the UI palette. It is a painted
## wooden wheel, not a casino one: a cream rim with wooden pegs, no lights,
## no coin shower.

const DUEL_COLORS: Dictionary = {
	&"boxing": UiTokens.TERRACOTTA_500, &"arm_wrestle": UiTokens.GRASS_500,
	&"dance": UiTokens.SUN_500, &"suwit": UiTokens.LAKE_500,
	&"silat": UiTokens.RED_500, &"tambang": UiTokens.BLUE_400,
	&"gasing": DioramaStyle.CRUST, &"pinang": DioramaStyle.PINE,
}
## Width of the cream rim around the segments.
const RIM := 14.0

## Rotation in turns; segment `i` is under the top pointer at i / 8.
var turns: float = 0.0:
	set(value):
		turns = value
		queue_redraw()
var highlight: int = -1:
	set(value):
		highlight = value
		queue_redraw()
## The segments to paint, clockwise from the top (the spot's wheel).
var segments: Array[StringName] = WheelController.SEGMENTS:
	set(value):
		segments = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - RIM - 4.0
	if radius <= 4.0:
		return
	var count := segments.size()
	var step := TAU / float(count)
	# A soft shadow, a cocoa outline and the cream rim.
	draw_circle(centre + Vector2(0.0, radius * 0.045), radius + RIM + 4.0, Color(UiTokens.INK_900, 0.28))
	draw_circle(centre, radius + RIM + 3.0, UiTokens.INK_900)
	draw_circle(centre, radius + RIM, UiTokens.CREAM_100)
	draw_arc(centre, radius + RIM * 0.5, 0.0, TAU, 64, UiTokens.EDGE_CREAM, 2.0, true)
	draw_circle(centre, radius + 2.0, UiTokens.INK_900)
	for index: int in count:
		var duel: StringName = segments[index]
		# Segment i is centred at i / 8 of a turn clockwise from the top;
		# the wheel as a whole is turned back by `turns`.
		var middle := (float(index) / float(count) - turns) * TAU - PI * 0.5
		var points := PackedVector2Array([centre])
		for arc: int in 13:
			var angle := middle - step * 0.5 + step * float(arc) / 12.0
			points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
		var color: Color = DUEL_COLORS[duel]
		if index == highlight:
			color = color.lightened(0.3)
		draw_colored_polygon(points, color)
		# A lighter band along the outer edge, like paint catching the light.
		var band := PackedVector2Array()
		for arc: int in 13:
			var angle := middle - step * 0.5 + step * float(arc) / 12.0
			band.append(centre + Vector2(cos(angle), sin(angle)) * (radius - 7.0))
		draw_polyline(band, color.lightened(0.22), 8.0, true)
		draw_polyline(points + PackedVector2Array([centre]), UiTokens.INK_900, 3.0, true)
		if index == highlight:
			draw_polyline(points + PackedVector2Array([centre]), UiTokens.CREAM_50, 6.0, true)
		# Pattern by duel, so segments differ by more than colour.
		var mark := centre + Vector2(cos(middle), sin(middle)) * radius * 0.42
		var shape := PackedVector2Array()
		match duel:
			&"boxing":
				for corner: int in 16:
					var turn := TAU * float(corner) / 16.0
					shape.append(mark + Vector2(cos(turn), sin(turn)) * radius * 0.07)
			&"arm_wrestle":
				var half := radius * 0.06
				shape = PackedVector2Array([mark + Vector2(-half, -half), mark + Vector2(half, -half), mark + Vector2(half, half), mark + Vector2(-half, half)])
			&"dance":
				shape = PackedVector2Array([mark + Vector2(0, -1) * radius * 0.08, mark + Vector2(1, 0.8) * radius * 0.07, mark + Vector2(-1, 0.8) * radius * 0.07])
			&"suwit":
				shape = PackedVector2Array([mark + Vector2(0, -1) * radius * 0.08, mark + Vector2(1, 0) * radius * 0.08, mark + Vector2(0, 1) * radius * 0.08, mark + Vector2(-1, 0) * radius * 0.08])
			&"silat":
				# A five-pointed star.
				for corner: int in 10:
					var turn := -PI * 0.5 + PI * 0.2 * float(corner)
					shape.append(mark + Vector2(cos(turn), sin(turn)) * radius * (0.085 if corner % 2 == 0 else 0.036))
			&"tambang":
				# A rope: a long bar.
				var length := radius * 0.09
				var thick := radius * 0.025
				shape = PackedVector2Array([mark + Vector2(-length, -thick), mark + Vector2(length, -thick), mark + Vector2(length, thick), mark + Vector2(-length, thick)])
			&"gasing":
				# A spinning top: a diamond on its point.
				shape = PackedVector2Array([mark + Vector2(0, -0.05) * radius, mark + Vector2(0.075, 0.0) * radius, mark + Vector2(0, 0.09) * radius, mark + Vector2(-0.075, 0.0) * radius])
			&"pinang":
				# A pole: a tall bar.
				var tall := radius * 0.09
				var narrow := radius * 0.022
				shape = PackedVector2Array([mark + Vector2(-narrow, -tall), mark + Vector2(narrow, -tall), mark + Vector2(narrow, tall), mark + Vector2(-narrow, tall)])
		draw_colored_polygon(shape, UiTokens.CREAM_50)
		draw_polyline(shape + PackedVector2Array([shape[0]]), UiTokens.INK_900, 2.5, true)

		var label := TextDb.t(StringName("duel.%s.upper" % duel))
		var font := UiSkin.bold_font()
		# The name shrinks to fit the width of its segment at that radius.
		var text_radius := radius * 0.73
		var room := 2.0 * text_radius * sin(step * 0.5) * 0.86
		var font_size := int(radius * 0.085)
		var width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if width > room and width > 0.0:
			font_size = int(floor(float(font_size) * room / width))
			width = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if font_size < 6:
			# Not laid out yet: nothing readable to draw.
			continue
		var text_at := centre + Vector2(cos(middle), sin(middle)) * text_radius
		draw_set_transform(text_at, middle + PI * 0.5, Vector2.ONE)
		draw_string_outline(font, Vector2(-width * 0.5, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, UiTokens.INK_900)
		draw_string(font, Vector2(-width * 0.5, font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiTokens.CREAM_50)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Wooden pegs on the rim between segments.
	for index: int in count:
		var boundary := (float(index) / float(count) - turns) * TAU - PI * 0.5 + step * 0.5
		var peg := centre + Vector2(cos(boundary), sin(boundary)) * (radius + RIM * 0.5)
		draw_circle(peg, RIM * 0.55, UiTokens.INK_900)
		draw_circle(peg, RIM * 0.38, UiTokens.SUN_500)

	# The hub: a cocoa ring, a cream cap and a small sun boss with a shine.
	draw_circle(centre, radius * 0.16, UiTokens.INK_900)
	draw_circle(centre, radius * 0.135, UiTokens.CREAM_100)
	draw_circle(centre, radius * 0.07, UiTokens.SUN_500)
	draw_arc(centre, radius * 0.07, 0.0, TAU, 24, UiSkin.edge_of(UiTokens.SUN_500), 2.5, true)
	draw_circle(centre + Vector2(-radius * 0.022, -radius * 0.022), radius * 0.018, UiTokens.CREAM_50)
