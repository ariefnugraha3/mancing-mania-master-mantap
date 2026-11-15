class_name ClimbGauge
extends Control
## A tall climb gauge for the Greased Pole (revision 6.7): a rounded tube
## that fills from the bottom, with a flag at the top and notches every
## quarter, and the climber's name over it.

const TUBE_WIDTH := 30.0

var value: float = 0.0:
	set(next):
		value = next
		queue_redraw()
var fill: Color = UiTokens.GRASS_500:
	set(next):
		fill = next
		queue_redraw()
var caption: String = "":
	set(next):
		caption = next
		if _label != null:
			_label.text = next

var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(56.0, 160.0)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_label.offset_top = 2.0
	_label.offset_bottom = 48.0
	_label.anchor_top = 1.0
	UiTokens.outline_text(_label, 13, UiTokens.CREAM_50, 5)
	_label.text = caption
	add_child(_label)


func _draw() -> void:
	var tube := Rect2(Vector2((size.x - TUBE_WIDTH) * 0.5, 22.0), Vector2(TUBE_WIDTH, size.y - 22.0))
	var radius := int(TUBE_WIDTH * 0.5)
	var outer := UiSkin.rounded(UiTokens.INK_900, radius + 5)
	outer.shadow_color = UiTokens.SHADOW
	outer.shadow_size = 5
	outer.shadow_offset = Vector2(0.0, 3.0)
	draw_style_box(outer, tube.grow(5.0))
	draw_style_box(UiSkin.rounded(UiTokens.CREAM_50, radius + 2), tube.grow(2.0))
	draw_style_box(UiSkin.rounded(UiTokens.PAPER_200, radius), tube)
	var level := clampf(value, 0.0, 1.0)
	if level > 0.0:
		var height := maxf(tube.size.y * level, TUBE_WIDTH)
		var filled := Rect2(Vector2(tube.position.x, tube.end.y - height), Vector2(tube.size.x, height))
		draw_style_box(UiSkin.rounded(fill, radius), filled)
	for quarter: int in range(1, 4):
		var y := tube.end.y - tube.size.y * float(quarter) * 0.25
		draw_line(Vector2(tube.position.x + 4.0, y), Vector2(tube.end.x - 4.0, y), Color(UiTokens.INK_900, 0.45), 2.0)
	# A little prize flag on top.
	var pole_x := size.x * 0.5
	draw_line(Vector2(pole_x, 0.0), Vector2(pole_x, 20.0), UiTokens.INK_900, 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(pole_x, 1.0), Vector2(pole_x + 16.0, 6.0), Vector2(pole_x, 11.0)]), UiTokens.RED_500)
