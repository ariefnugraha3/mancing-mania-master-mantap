class_name LogoEmblem
extends Control
## The game's round emblem next to the title (GDD 186.4 identity): a warm sun
## disc with a cocoa rim and the boxing fish of the app icon, drawn from
## polygons and circles. It wiggles gently on the Main Menu unless Reduced
## Motion is on.

@export var diameter: float = 96.0:
	set(value):
		diameter = value
		custom_minimum_size = Vector2(value, value)
		queue_redraw()

var _clock: float = 0.0
var _wiggle: bool = true


func _ready() -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wiggle = not bool(GameState.get_setting(&"reduced_motion"))


func _process(delta: float) -> void:
	if not _wiggle:
		rotation = 0.0
		return
	_clock += delta
	pivot_offset = size * 0.5
	rotation = deg_to_rad(4.0) * sin(_clock * 1.6)


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	# Disc: shadow, cocoa rim, sun face, a lighter inner ring.
	draw_circle(centre + Vector2(0.0, radius * 0.06), radius, Color(UiTokens.INK_900, 0.3))
	draw_circle(centre, radius, UiTokens.INK_900)
	draw_circle(centre, radius * 0.9, UiTokens.SUN_500)
	draw_arc(centre, radius * 0.78, 0.0, TAU, 40, Color(UiTokens.CREAM_50, 0.55), radius * 0.05, true)
	# Two water ripples under the fish.
	var ripple := Color(UiTokens.LAKE_500, 0.9)
	draw_line(centre + Vector2(-radius * 0.5, radius * 0.48), centre + Vector2(radius * 0.05, radius * 0.48), ripple, radius * 0.07, true)
	draw_line(centre + Vector2(radius * 0.15, radius * 0.6), centre + Vector2(radius * 0.5, radius * 0.6), ripple, radius * 0.07, true)

	var scale := radius * 2.3
	var place := Transform2D(deg_to_rad(-22.0), centre + Vector2(-radius * 0.02, -radius * 0.04))
	var body_color := UiTokens.TERRACOTTA_500
	var belly_color := UiTokens.TERRACOTTA_500.lightened(0.3)
	var fin_color := UiSkin.edge_of(UiTokens.TERRACOTTA_500)
	_polygon([Vector2(-0.185, 0.0), Vector2(-0.325, -0.105), Vector2(-0.285, 0.0), Vector2(-0.325, 0.11)], place, scale, fin_color)
	_polygon([Vector2(-0.06, -0.085), Vector2(0.015, -0.165), Vector2(0.105, -0.09)], place, scale, fin_color)
	_polygon([
		Vector2(-0.205, 0.0), Vector2(-0.085, -0.088), Vector2(0.08, -0.098), Vector2(0.20, -0.048),
		Vector2(0.24, 0.01), Vector2(0.19, 0.064), Vector2(0.06, 0.1), Vector2(-0.09, 0.08)], place, scale, body_color)
	_polygon([Vector2(-0.09, 0.08), Vector2(0.06, 0.1), Vector2(0.19, 0.064), Vector2(0.105, 0.024), Vector2(-0.07, 0.026)], place, scale, belly_color)
	# Big bead eye with a shine, and a pink cheek.
	draw_circle(place * (Vector2(0.155, -0.03) * scale), 0.03 * scale, UiTokens.CREAM_50)
	draw_circle(place * (Vector2(0.162, -0.028) * scale), 0.019 * scale, UiTokens.INK_900)
	draw_circle(place * (Vector2(0.156, -0.036) * scale), 0.007 * scale, UiTokens.CREAM_50)
	draw_circle(place * (Vector2(0.14, 0.02) * scale), 0.016 * scale, Color(DioramaStyle.BLUSH, 0.9))
	# The glove: cuff, fist, thumb and a worn highlight.
	_polygon([Vector2(0.045, 0.085), Vector2(0.085, 0.068), Vector2(0.105, 0.112), Vector2(0.066, 0.13)], place, scale, UiTokens.CREAM_50)
	var glove := UiTokens.RED_500
	draw_circle(place * (Vector2(0.142, 0.118) * scale), 0.07 * scale, UiSkin.edge_of(glove))
	draw_circle(place * (Vector2(0.142, 0.118) * scale), 0.062 * scale, glove)
	draw_circle(place * (Vector2(0.192, 0.078) * scale), 0.03 * scale, glove)
	draw_circle(place * (Vector2(0.125, 0.098) * scale), 0.018 * scale, glove.lightened(0.3))


func _polygon(points: Array, place: Transform2D, scale: float, color: Color) -> void:
	var placed := PackedVector2Array()
	for point: Vector2 in points:
		placed.append(place * (point * scale))
	draw_colored_polygon(placed, color)
