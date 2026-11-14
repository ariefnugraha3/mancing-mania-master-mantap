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
## Teal, grass, sun and crust: the UI palette, one per lane.
const LANE_COLORS: Array[Color] = [
	Color("4f9a91"), Color("7fa65a"), Color("f2b44a"), Color("e0784c"),
]
const LANE_RADIUS := 18
const KEY_CAP_SIZE := Vector2(34.0, 32.0)
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
	var high_contrast := UiTokens.is_high_contrast()
	for lane: int in LANES:
		var rect := get_lane_rect(lane)
		# A rounded lane tinted with its colour, brighter while it flashes.
		var lane_box := UiSkin.rounded(
			Color(LANE_COLORS[lane].lerp(UiTokens.INK_900, 0.62), 0.5 + 0.25 * lane_flash[lane]), LANE_RADIUS)
		# High Contrast: an opaque lane edge as well as its colour (GDD 189.4).
		lane_box.border_color = UiTokens.CREAM_50 if high_contrast else Color(UiTokens.CREAM_50, 0.4)
		lane_box.set_border_width_all(4 if high_contrast else 2)
		draw_style_box(lane_box, rect)
		# Hit target: a soft receptor disc with the lane's shape outlined in it.
		var target := Vector2(rect.get_center().x, hit_y)
		var receptor := minf(rect.size.x * 0.44, NOTE_HEIGHT * 1.15)
		draw_circle(target, receptor, Color(LANE_COLORS[lane], 0.28 + 0.5 * lane_flash[lane]))
		draw_arc(target, receptor, 0.0, TAU, 32, Color(UiTokens.CREAM_50, 0.85), 3.0, true)
		_draw_shape(lane, target, rect.size.x * 0.34, Color(UiTokens.CREAM_50, 0.95), false)
		_draw_key_cap(Vector2(rect.get_center().x, hit_y + 52.0), key_labels[lane])
	# The hit line: a cream rail with a cocoa edge.
	draw_line(Vector2(6.0, hit_y), Vector2(size.x - 6.0, hit_y), UiTokens.INK_900, 7.0, true)
	draw_line(Vector2(6.0, hit_y), Vector2(size.x - 6.0, hit_y), UiTokens.CREAM_50, 3.0, true)

	# The beat pulse beside the hit line (GDD 189.9).
	if beat_pulse and beat_sec > 0.0:
		var phase := fposmod(song_time, beat_sec) / beat_sec
		var radius := lerpf(16.0, 9.0, phase)
		var centre := Vector2(size.x - 14.0, hit_y - 36.0)
		draw_circle(centre, radius + 2.5, Color(UiTokens.INK_900, 1.0 - phase * 0.6))
		draw_circle(centre, radius, Color(UiTokens.SUN_500, 1.0 - phase * 0.6))

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
		var centre := Vector2(rect.get_center().x, y)
		var half := rect.size.x * 0.34
		var shine := minf(half, NOTE_HEIGHT * 0.9)
		# Notes fade in at the top of the lane instead of popping in over its edge.
		var fade := clampf((y - shine) / (shine * 2.0), 0.0, 1.0)
		if fade <= 0.0:
			continue
		# A soft shadow under each note, then the note with a little shine.
		_draw_shape(lane, centre + Vector2(0.0, 4.0), half, Color(UiTokens.INK_900, 0.3 * fade), true, false)
		_draw_shape(lane, centre, half, Color(LANE_COLORS[lane], fade), true)
		draw_circle(centre + Vector2(-shine * 0.32, -shine * 0.32), shine * 0.16, Color(UiTokens.CREAM_50, 0.75 * fade))


## The key for a lane, on a small cream key cap with a lip.
func _draw_key_cap(centre: Vector2, text: String) -> void:
	if text == "":
		return
	var font := UiSkin.bold_font()
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var cap_size := Vector2(maxf(KEY_CAP_SIZE.x, text_width + 16.0), KEY_CAP_SIZE.y)
	var cap := Rect2(centre - cap_size * 0.5, cap_size)
	draw_style_box(UiSkin.button_box(UiTokens.CREAM_50, UiSkin.STATE_NORMAL, 10, 4, Vector2.ZERO), cap)
	draw_string(font, Vector2(cap.position.x, cap.position.y + 21.0), text, HORIZONTAL_ALIGNMENT_CENTER, cap.size.x, 18, UiTokens.INK_900)


## Lane 1 a circle, 2 a diamond, 3 a square, 4 a triangle.
func _draw_shape(lane: int, centre: Vector2, half: float, color: Color, filled: bool, outlined: bool = true) -> void:
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
	if not outlined:
		return
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, Color(UiTokens.INK_900, color.a) if filled else color, 5.0 if UiTokens.is_high_contrast() else 3.0, true)
