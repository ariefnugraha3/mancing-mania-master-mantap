class_name LoadingSpinner
extends Control
## The loading spinner of scene changes (revision 6.12): a ring of cream dots
## with a bright head that runs round, so a change of screen never shows a
## blank dark screen. Drawn in code, no texture.

const DOTS := 10
const TURN_SEC := 0.9
const COLOR := Color(1.0, 0.969, 0.902)

var _clock: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(56.0, 56.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 6.0
	var head := fmod(_clock / TURN_SEC, 1.0) * float(DOTS)
	for index: int in DOTS:
		var angle := TAU * float(index) / float(DOTS) - PI * 0.5
		# The head is brightest and largest; the dots behind it fade.
		var behind := fmod(head - float(index) + float(DOTS), float(DOTS)) / float(DOTS)
		var strength := 1.0 - behind
		draw_circle(centre + Vector2(cos(angle), sin(angle)) * radius, lerpf(2.5, 5.5, strength), Color(COLOR, lerpf(0.18, 1.0, strength)))
