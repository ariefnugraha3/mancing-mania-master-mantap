class_name NoteField
extends Control
## The four falling-note lanes (GDD 57, 59, 62, 176.12, 189.5, 189.9).
##
## Notes are drawn from the song clock: a note reaches the hit line exactly
## at its time, and Black Coffee only changes how long it is visible before
## that. Every lane has its own shape as well as its own colour, so lanes
## never depend on colour alone.

const LANES := 4
const HIT_LINE_FROM_BOTTOM := 96.0
const NOTE_HEIGHT := 26.0
const LANE_GAP := 8.0
const LANE_COLORS: Array[Color] = [
	Color("557f7a"), Color("778b59"), Color("e4ae55"), Color("b8654e"),
]
## How long a judged note lingers, fading, at the hit line.
const HIT_FADE_SEC := 0.18

var notes: Array = []
var judgments: Array = []
var song_time: float = 0.0
var approach_sec: float = 1.25
var beat_sec: float = 0.5
var beat_pulse: bool = true
var key_labels: PackedStringArray = PackedStringArray(["S", "D", "J", "K"])
var lane_flash: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0])


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_hit_line_y() -> float:
	return size.y - HIT_LINE_FROM_BOTTOM


func get_lane_rect(lane: int) -> Rect2:
	var width := (size.x - LANE_GAP * float(LANES - 1)) / float(LANES)
	return Rect2(float(lane) * (width + LANE_GAP), 0.0, width, size.y)


## Where note `index` is drawn right now, or -1 when it is not on screen.
func get_note_y(index: int) -> float:
	var time_to_hit := float(notes[index]["time"]) - song_time
	if time_to_hit > approach_sec:
		return -1.0
	return get_hit_line_y() - (time_to_hit / approach_sec) * get_hit_line_y()


func _draw() -> void:
	var hit_y := get_hit_line_y()
	for lane: int in LANES:
		var rect := get_lane_rect(lane)
		draw_rect(rect, Color(UiTokens.INK_900, 0.5 + 0.25 * lane_flash[lane]))
		# High Contrast: an opaque lane edge as well as its colour (GDD 189.4).
		if UiTokens.is_high_contrast():
			draw_rect(rect, UiTokens.CREAM_50, false, 4.0)
		else:
			draw_rect(rect, Color(LANE_COLORS[lane], 0.5), false, 2.0)
		# Hit target: the lane's shape, outlined, on the hit line.
		_draw_shape(lane, Vector2(rect.get_center().x, hit_y), rect.size.x * 0.34, Color(UiTokens.CREAM_50, 0.9), false)
		var label_pos := Vector2(rect.position.x, hit_y + 40.0)
		draw_string(get_theme_default_font(), label_pos, key_labels[lane], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 22, UiTokens.CREAM_50)
	draw_line(Vector2(0.0, hit_y), Vector2(size.x, hit_y), UiTokens.CREAM_50, 3.0)

	# The beat pulse beside the hit line (GDD 189.9).
	if beat_pulse and beat_sec > 0.0:
		var phase := fposmod(song_time, beat_sec) / beat_sec
		var radius := lerpf(16.0, 9.0, phase)
		draw_circle(Vector2(size.x - 14.0, hit_y - 36.0), radius, Color(UiTokens.SUN_500, 1.0 - phase * 0.6))

	for index: int in notes.size():
		var judgment: StringName = judgments[index] if index < judgments.size() else &""
		var lane := int(notes[index]["lane"])
		var rect := get_lane_rect(lane)
		if judgment != &"":
			var since := song_time - float(notes[index]["time"])
			if judgment == DanceController.MISS or since > HIT_FADE_SEC or since < -0.3:
				continue
			_draw_shape(lane, Vector2(rect.get_center().x, hit_y), rect.size.x * 0.4 * (1.0 + since * 2.0),
				Color(LANE_COLORS[lane], 1.0 - since / HIT_FADE_SEC), true)
			continue
		var y := get_note_y(index)
		if y < 0.0 or y > size.y:
			continue
		_draw_shape(lane, Vector2(rect.get_center().x, y), rect.size.x * 0.34, LANE_COLORS[lane], true)


## Lane 1 a circle, 2 a diamond, 3 a square, 4 a triangle.
func _draw_shape(lane: int, centre: Vector2, half: float, color: Color, filled: bool) -> void:
	half = minf(half, NOTE_HEIGHT * 0.9)
	var points := PackedVector2Array()
	match lane:
		0:
			for step: int in 16:
				var angle := TAU * float(step) / 16.0
				points.append(centre + Vector2(cos(angle), sin(angle)) * half)
		1:
			points = PackedVector2Array([centre + Vector2(0, -half), centre + Vector2(half, 0), centre + Vector2(0, half), centre + Vector2(-half, 0)])
		2:
			points = PackedVector2Array([centre + Vector2(-half, -half * 0.8), centre + Vector2(half, -half * 0.8), centre + Vector2(half, half * 0.8), centre + Vector2(-half, half * 0.8)])
		_:
			points = PackedVector2Array([centre + Vector2(0, -half), centre + Vector2(half, half * 0.8), centre + Vector2(-half, half * 0.8)])
	if filled:
		draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, UiTokens.INK_900 if filled else color, 5.0 if UiTokens.is_high_contrast() else 3.0, true)
