class_name IconPainter
extends RefCounted
## Procedural UI icons drawn straight into a canvas item (GDD 174.10, 184.11).
## No icon image exists anywhere in the project: every icon is a few rounded
## strokes and shapes on a 24-unit grid, scaled to the rect it is drawn in.
## UiIcon (a Control) and IconTexture (a Texture2D for Button.icon) both paint
## through here, so an icon looks the same in a chip and on a button.

const STROKE := 2.6

const CASH := &"ui_icon_cash"
const BUCKET := &"ui_icon_bucket"
const MARKET := &"ui_icon_market"
const PAUSE := &"ui_icon_pause"
const WARNING := &"ui_icon_warning"
const ROD := &"ui_icon_rod"
const PLAY := &"ui_icon_play"
const SPARKLE := &"ui_icon_sparkle"
const BOOK := &"ui_icon_book"
const GEAR := &"ui_icon_gear"
const HEART := &"ui_icon_heart"
const BACK := &"ui_icon_back"
const CLOSE := &"ui_icon_close"
const MUSIC := &"ui_icon_music"
const SOUND := &"ui_icon_sound"
const DOOR := &"ui_icon_door"
const CHECK := &"ui_icon_check"
const KEYS := &"ui_icon_keys"
const FISH := &"ui_icon_fish"
const LEDGER := &"ui_icon_ledger"
const ARROW_UP := &"ui_icon_arrow_up"
const TROPHY := &"ui_icon_trophy"
const RETRY := &"ui_icon_retry"
const SHIELD := &"ui_icon_shield"
const ARROW_LEFT := &"ui_icon_arrow_left"
const ARROW_RIGHT := &"ui_icon_arrow_right"
const GLOVE := &"ui_icon_glove"
const HAND := &"ui_icon_hand"

var _item: RID
var _color: Color


## Paints icon `id` into `rect` of the canvas item `item` in `color`.
static func paint(item: RID, id: StringName, rect: Rect2, color: Color) -> void:
	var painter := IconPainter.new()
	painter._item = item
	painter._color = color
	var unit := minf(rect.size.x, rect.size.y) / 24.0
	var origin := rect.position + (rect.size - Vector2(24.0, 24.0) * unit) * 0.5
	RenderingServer.canvas_item_add_set_transform(item, Transform2D(0.0, Vector2(unit, unit), 0.0, origin))
	painter._draw(id)
	RenderingServer.canvas_item_add_set_transform(item, Transform2D.IDENTITY)


func _draw(id: StringName) -> void:
	match id:
		CASH:
			_round_rect(Rect2(2.5, 6, 19, 12), 2.5)
			_ring(Vector2(12, 12), 3.0)
			_dot(Vector2(6, 12), 1.1)
			_dot(Vector2(18, 12), 1.1)
		BUCKET:
			_fill(PackedVector2Array([Vector2(4, 10), Vector2(20, 10), Vector2(17.5, 21), Vector2(6.5, 21)]))
			_arc(Vector2(12, 10), 7.5, PI, TAU)
		MARKET:
			_fill(PackedVector2Array([Vector2(2, 10), Vector2(12, 3), Vector2(22, 10)]))
			_line(Vector2(5, 10), Vector2(5, 21))
			_line(Vector2(19, 10), Vector2(19, 21))
			_fill(PackedVector2Array([Vector2(5, 15), Vector2(19, 15), Vector2(19, 18), Vector2(5, 18)]))
		PAUSE:
			_line(Vector2(8.5, 6), Vector2(8.5, 18), 4.2)
			_line(Vector2(15.5, 6), Vector2(15.5, 18), 4.2)
		WARNING:
			_polyline(_closed(PackedVector2Array([Vector2(12, 3), Vector2(21.5, 20.5), Vector2(2.5, 20.5)])), 2.8)
			_line(Vector2(12, 9.5), Vector2(12, 14.5), 3.0)
			_dot(Vector2(12, 17.6), 1.7)
		ROD:
			_line(Vector2(3, 21), Vector2(19, 4))
			_line(Vector2(19, 4), Vector2(19, 13), 1.4)
			_dot(Vector2(19, 15.5), 2.6)
		PLAY:
			_fill(PackedVector2Array([Vector2(7, 4.5), Vector2(19.5, 12), Vector2(7, 19.5)]))
			_polyline(PackedVector2Array([Vector2(7, 4.5), Vector2(19.5, 12), Vector2(7, 19.5), Vector2(7, 4.5)]), 2.4)
		SPARKLE:
			_star(Vector2(10.5, 13), 8.0, 2.4)
			_star(Vector2(19, 5.5), 3.6, 1.1)
		BOOK:
			_fill(PackedVector2Array([Vector2(2.5, 5.5), Vector2(11, 7), Vector2(11, 20), Vector2(2.5, 18.5)]))
			_fill(PackedVector2Array([Vector2(13, 7), Vector2(21.5, 5.5), Vector2(21.5, 18.5), Vector2(13, 20)]))
		GEAR:
			for tooth: int in 8:
				var angle := TAU * float(tooth) / 8.0
				_line(Vector2(12, 12) + Vector2(cos(angle), sin(angle)) * 7.0, Vector2(12, 12) + Vector2(cos(angle), sin(angle)) * 10.0, 3.6)
			_ring(Vector2(12, 12), 6.0, 3.4)
			_dot(Vector2(12, 12), 1.6)
		HEART:
			_dot(Vector2(8.2, 9.2), 4.6)
			_dot(Vector2(15.8, 9.2), 4.6)
			_fill(PackedVector2Array([Vector2(3.8, 11.2), Vector2(20.2, 11.2), Vector2(12, 20.5)]))
		ARROW_LEFT:
			_fill(PackedVector2Array([Vector2(2.5, 12), Vector2(11.5, 3.5), Vector2(11.5, 8.5), Vector2(21.5, 8.5),
				Vector2(21.5, 15.5), Vector2(11.5, 15.5), Vector2(11.5, 20.5)]))
		ARROW_RIGHT:
			_fill(PackedVector2Array([Vector2(21.5, 12), Vector2(12.5, 20.5), Vector2(12.5, 15.5), Vector2(2.5, 15.5),
				Vector2(2.5, 8.5), Vector2(12.5, 8.5), Vector2(12.5, 3.5)]))
		GLOVE:
			# A boxing glove: round fist, thumb, and a cuff.
			_dot(Vector2(13, 10), 7.6)
			_dot(Vector2(5.8, 12.5), 3.4)
			_fill(PackedVector2Array([Vector2(7, 15.5), Vector2(19, 15.5), Vector2(18, 22), Vector2(8, 22)]))
		HAND:
			# An open hand pushing: palm and four short fingers.
			_fill(PackedVector2Array([Vector2(5, 11), Vector2(19, 11), Vector2(18, 21), Vector2(6.5, 21)]))
			for finger: int in 4:
				_line(Vector2(6.8 + 3.5 * float(finger), 11.5), Vector2(6.8 + 3.5 * float(finger), 4.5), 3.0)
		BACK:
			_polyline(PackedVector2Array([Vector2(11, 5), Vector2(4, 12), Vector2(11, 19)]))
			_line(Vector2(5, 12), Vector2(20, 12))
		CLOSE:
			_line(Vector2(6, 6), Vector2(18, 18), 3.2)
			_line(Vector2(18, 6), Vector2(6, 18), 3.2)
		MUSIC:
			_line(Vector2(9, 17), Vector2(9, 5))
			_line(Vector2(19, 15), Vector2(19, 3.5))
			_line(Vector2(9, 5), Vector2(19, 3.5), 3.2)
			_dot(Vector2(6.5, 17.5), 3.2)
			_dot(Vector2(16.5, 15.5), 3.2)
		SOUND:
			_fill(PackedVector2Array([Vector2(3, 9), Vector2(7, 9), Vector2(12, 4.5), Vector2(12, 19.5), Vector2(7, 15), Vector2(3, 15)]))
			_arc(Vector2(13, 12), 4.0, -0.9, 0.9)
			_arc(Vector2(13, 12), 7.5, -0.9, 0.9)
		DOOR:
			_polyline(PackedVector2Array([Vector2(13, 3.5), Vector2(5, 3.5), Vector2(5, 20.5), Vector2(13, 20.5)]))
			_line(Vector2(10, 12), Vector2(21, 12))
			_polyline(PackedVector2Array([Vector2(17, 8), Vector2(21, 12), Vector2(17, 16)]))
		CHECK:
			_polyline(PackedVector2Array([Vector2(4.5, 12.5), Vector2(10, 18), Vector2(19.5, 6)]), 3.4)
		KEYS:
			_round_rect(Rect2(2, 6, 20, 13), 2.5)
			for key: Vector2 in [Vector2(6.5, 10), Vector2(10.5, 10), Vector2(14.5, 10), Vector2(18, 10)]:
				_dot(key, 0.9)
			_line(Vector2(8, 15), Vector2(16, 15), 1.8)
		FISH:
			_fill(PackedVector2Array([Vector2(3, 12), Vector2(8, 7.5), Vector2(15, 7), Vector2(19.5, 10), Vector2(20.5, 12), Vector2(19.5, 14), Vector2(15, 17), Vector2(8, 16.5)]))
			_fill(PackedVector2Array([Vector2(5, 12), Vector2(1, 7.5), Vector2(1, 16.5)]))
		LEDGER:
			_round_rect(Rect2(4.5, 3, 15, 18), 2.0)
			_line(Vector2(8, 8.5), Vector2(16, 8.5), 1.8)
			_line(Vector2(8, 12.5), Vector2(16, 12.5), 1.8)
			_line(Vector2(8, 16.5), Vector2(13, 16.5), 1.8)
		ARROW_UP:
			_polyline(PackedVector2Array([Vector2(5.5, 11), Vector2(12, 4.5), Vector2(18.5, 11)]), 3.0)
			_line(Vector2(12, 5.5), Vector2(12, 19.5), 3.0)
		TROPHY:
			_fill(PackedVector2Array([Vector2(6, 3.5), Vector2(18, 3.5), Vector2(17, 11), Vector2(12, 14.5), Vector2(7, 11)]))
			_arc(Vector2(6, 7.5), 3.2, PI * 0.5, PI * 1.5)
			_arc(Vector2(18, 7.5), 3.2, -PI * 0.5, PI * 0.5)
			_line(Vector2(12, 14), Vector2(12, 18))
			_line(Vector2(7.5, 20), Vector2(16.5, 20), 3.0)
		RETRY:
			_arc(Vector2(12, 12), 7.0, -PI * 0.15, PI * 1.55)
			_fill(PackedVector2Array([Vector2(15.5, 2.5), Vector2(20.5, 6.5), Vector2(14.5, 8.5)]))
		SHIELD:
			_fill(PackedVector2Array([Vector2(12, 2.5), Vector2(20, 5.5), Vector2(19, 13), Vector2(12, 21.5), Vector2(5, 13), Vector2(4, 5.5)]))


# --- Shapes (24-unit grid) ----------------------------------------------------

func _line(from: Vector2, to: Vector2, width: float = STROKE) -> void:
	RenderingServer.canvas_item_add_line(_item, from, to, _color, width, true)
	_dot(from, width * 0.5)
	_dot(to, width * 0.5)


func _polyline(points: PackedVector2Array, width: float = STROKE) -> void:
	RenderingServer.canvas_item_add_polyline(_item, points, PackedColorArray([_color]), width, true)
	for point: Vector2 in points:
		_dot(point, width * 0.5)


func _dot(centre: Vector2, radius: float) -> void:
	RenderingServer.canvas_item_add_circle(_item, centre, radius, _color, true)


func _circle(centre: Vector2, radius: float, color: Color) -> void:
	if color.a > 0.0:
		RenderingServer.canvas_item_add_circle(_item, centre, radius, color, true)


func _fill(points: PackedVector2Array) -> void:
	RenderingServer.canvas_item_add_polygon(_item, points, PackedColorArray([_color]))
	_polyline(_closed(points), 1.4)


func _arc(centre: Vector2, radius: float, from: float, to: float, width: float = STROKE) -> void:
	var points := PackedVector2Array()
	var steps := 16
	for step: int in steps + 1:
		var angle := lerpf(from, to, float(step) / float(steps))
		points.append(centre + Vector2(cos(angle), sin(angle)) * radius)
	_polyline(points, width)


func _ring(centre: Vector2, radius: float, width: float = STROKE) -> void:
	_arc(centre, radius, 0.0, TAU, width)


func _round_rect(rect: Rect2, radius: float) -> void:
	var points := PackedVector2Array()
	var corners := [
		[rect.position + Vector2(rect.size.x - radius, radius), -PI * 0.5],
		[rect.end - Vector2(radius, radius), 0.0],
		[Vector2(rect.position.x + radius, rect.end.y - radius), PI * 0.5],
		[rect.position + Vector2(radius, radius), PI],
	]
	for corner: Array in corners:
		for step: int in 5:
			var angle: float = corner[1] + PI * 0.5 * float(step) / 4.0
			points.append(corner[0] + Vector2(cos(angle), sin(angle)) * radius)
	_polyline(_closed(points), STROKE)


## A soft four-pointed star.
func _star(centre: Vector2, outer: float, inner: float) -> void:
	var points := PackedVector2Array()
	for index: int in 8:
		var angle := -PI * 0.5 + PI * 0.25 * float(index)
		points.append(centre + Vector2(cos(angle), sin(angle)) * (outer if index % 2 == 0 else inner))
	_fill(points)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed
