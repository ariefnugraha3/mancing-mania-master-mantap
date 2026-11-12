class_name UiIcon
extends Control
## Procedural UI icons drawn from lines, arcs and polygons (GDD 174.10, 184.11).
## No icon image exists anywhere in the project: each icon is a few draw calls
## in the theme's ink colour, so it scales cleanly with the UI.

const ICON_CASH := &"ui_icon_cash"
const ICON_BUCKET := &"ui_icon_bucket"
const ICON_MARKET := &"ui_icon_market"
const ICON_PAUSE := &"ui_icon_pause"
const ICON_WARNING := &"ui_icon_warning"
const ICON_ROD := &"ui_icon_rod"

@export var icon_id: StringName = ICON_CASH:
	set(value):
		icon_id = value
		queue_redraw()
@export var tint: Color = UiTokens.INK_900:
	set(value):
		tint = value
		queue_redraw()
@export var icon_size: float = 28.0:
	set(value):
		icon_size = value
		custom_minimum_size = Vector2(value, value)
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# Icons are designed on a 24-unit grid and scaled to the control.
	var unit := minf(size.x, size.y) / 24.0
	var origin := (size - Vector2(24.0, 24.0) * unit) * 0.5
	draw_set_transform(origin, 0.0, Vector2(unit, unit))
	match icon_id:
		ICON_CASH:
			_draw_cash()
		ICON_BUCKET:
			_draw_bucket()
		ICON_MARKET:
			_draw_market()
		ICON_PAUSE:
			_draw_pause()
		ICON_WARNING:
			_draw_warning()
		ICON_ROD:
			_draw_rod()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Banknote: a rectangle with a circle in the middle.
func _draw_cash() -> void:
	draw_rect(Rect2(2, 6, 20, 12), tint, false, 2.0)
	draw_arc(Vector2(12, 12), 3.2, 0.0, TAU, 20, tint, 2.0)
	draw_line(Vector2(5, 9), Vector2(5, 15), tint, 1.5)
	draw_line(Vector2(19, 9), Vector2(19, 15), tint, 1.5)


## Bucket: a trapezoid with a handle arc.
func _draw_bucket() -> void:
	var body := PackedVector2Array([Vector2(4, 10), Vector2(20, 10), Vector2(17.5, 21), Vector2(6.5, 21)])
	draw_colored_polygon(body, tint)
	draw_arc(Vector2(12, 10), 8.0, PI, TAU, 18, tint, 2.0)


## Warung: a pitched roof over two posts and a counter.
func _draw_market() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(2, 10), Vector2(12, 3), Vector2(22, 10)]), tint)
	draw_line(Vector2(5, 10), Vector2(5, 21), tint, 2.0)
	draw_line(Vector2(19, 10), Vector2(19, 21), tint, 2.0)
	draw_rect(Rect2(5, 15, 14, 3), tint)


func _draw_pause() -> void:
	draw_rect(Rect2(6, 4, 4.5, 16), tint)
	draw_rect(Rect2(13.5, 4, 4.5, 16), tint)


## Warning triangle with an exclamation mark cut out in the panel colour.
func _draw_warning() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(12, 2), Vector2(22.5, 21), Vector2(1.5, 21)]), tint)
	draw_rect(Rect2(11, 8.5, 2, 7), UiTokens.CREAM_50)
	draw_rect(Rect2(11, 17, 2, 2), UiTokens.CREAM_50)


## Rod: a diagonal blank with a line and a float.
func _draw_rod() -> void:
	draw_line(Vector2(3, 21), Vector2(19, 4), tint, 2.0)
	draw_line(Vector2(19, 4), Vector2(19, 14), tint, 1.0)
	draw_circle(Vector2(19, 16), 2.4, tint)
