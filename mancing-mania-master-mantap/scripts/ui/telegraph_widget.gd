class_name TelegraphWidget
extends Control
## The boxing read-out (GDD 46, 47, 176.14, 189.5): which way to dodge, how
## long is left, and when the counter window is open.
##
## Nothing here relies on colour alone. The dodge direction is a chevron, the
## side of the widget it sits on and the words next to it. The Perfect Dodge
## moment is a second chevron and a marked end section on the timing bar.

const BAR_SIZE := Vector2(280.0, 14.0)
const CHEVRON_HEIGHT := 78.0
const OUTLINE := 5.0

enum Mode { HIDDEN, TELEGRAPH, COUNTER }

var _mode: Mode = Mode.HIDDEN
var _direction: StringName = &""
var _ratio: float = 0.0
var _perfect_ratio: float = 0.0
var _emphasis: bool = false
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.name = "Prompt"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_label.offset_bottom = CHEVRON_HEIGHT
	UiTokens.outline_text(_label, 34)
	add_child(_label)
	visible = false


## The fish is winding up. `left_ratio` runs from 1 to 0 at the impact and
## `perfect_ratio` is the share of the telegraph that is the perfect window.
func show_telegraph(direction: StringName, left_ratio: float, perfect_ratio: float, in_perfect_window: bool) -> void:
	_mode = Mode.TELEGRAPH
	_direction = direction
	_ratio = clampf(left_ratio, 0.0, 1.0)
	_perfect_ratio = clampf(perfect_ratio, 0.0, 1.0)
	_emphasis = in_perfect_window
	_label.text = TextDb.t(&"boxing.prompt.dodge_left" if direction == BoxingController.DIRECTION_LEFT else &"boxing.prompt.dodge_right")
	_refresh()


## The counter window is open. `left_ratio` runs from 1 to 0 as it closes.
func show_counter(perfect: bool, left_ratio: float) -> void:
	_mode = Mode.COUNTER
	_ratio = clampf(left_ratio, 0.0, 1.0)
	_emphasis = perfect
	_label.text = TextDb.t(&"boxing.prompt.perfect" if perfect else &"boxing.prompt.counter")
	_refresh()


func clear() -> void:
	if _mode == Mode.HIDDEN:
		return
	_mode = Mode.HIDDEN
	_refresh()


func get_prompt_text() -> String:
	return _label.text if visible else ""


func get_shown_direction() -> StringName:
	return _direction if _mode == Mode.TELEGRAPH else &""


func _refresh() -> void:
	visible = _mode != Mode.HIDDEN
	queue_redraw()


func _draw() -> void:
	if _mode == Mode.HIDDEN:
		return
	var centre_x := size.x * 0.5
	if _mode == Mode.TELEGRAPH:
		var side := -1.0 if _direction == BoxingController.DIRECTION_LEFT else 1.0
		var edge := centre_x + side * (size.x * 0.5 - 46.0)
		_draw_chevron(Vector2(edge, CHEVRON_HEIGHT * 0.5), side)
		if _emphasis:
			# The Perfect Dodge moment adds a second chevron: a change of shape.
			_draw_chevron(Vector2(edge - side * 40.0, CHEVRON_HEIGHT * 0.5), side)

	var bar := Rect2(Vector2(centre_x - BAR_SIZE.x * 0.5, CHEVRON_HEIGHT + 8.0), BAR_SIZE)
	draw_rect(bar.grow(3.0), UiTokens.INK_900)
	draw_rect(bar, UiTokens.CREAM_100)
	var fill := Rect2(bar.position, Vector2(bar.size.x * _ratio, bar.size.y))
	draw_rect(fill, UiTokens.SUN_500 if _emphasis else UiTokens.LAKE_500)
	if _mode == Mode.TELEGRAPH and _perfect_ratio > 0.0:
		# The last part of the bar is the Perfect Dodge window: notched off
		# and hatched, so it reads without its colour.
		var notch := bar.position.x + bar.size.x * _perfect_ratio
		draw_line(Vector2(notch, bar.position.y - 5.0), Vector2(notch, bar.end.y + 5.0), UiTokens.INK_900, 3.0)
		var x := bar.position.x + 4.0
		while x < notch - 2.0:
			draw_line(Vector2(x, bar.end.y), Vector2(x + 5.0, bar.position.y), Color(UiTokens.INK_900, 0.55), 1.5)
			x += 7.0


## A thick chevron pointing along `side` (-1 left, +1 right).
func _draw_chevron(centre: Vector2, side: float) -> void:
	var half := CHEVRON_HEIGHT * 0.5
	var depth := 30.0
	var thickness := 20.0
	var points := PackedVector2Array([
		centre + Vector2(side * depth, 0.0),
		centre + Vector2(-side * 4.0, -half),
		centre + Vector2(-side * (4.0 + thickness), -half),
		centre + Vector2(side * (depth - thickness - 8.0), 0.0),
		centre + Vector2(-side * (4.0 + thickness), half),
		centre + Vector2(-side * 4.0, half),
	])
	var outline := points.duplicate()
	outline.append(points[0])
	draw_colored_polygon(points, UiTokens.SUN_500 if _emphasis else UiTokens.CREAM_50)
	draw_polyline(outline, UiTokens.INK_900, OUTLINE, true)
