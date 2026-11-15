class_name TimingMeter
extends Control
## A horizontal timing bar (revision 6.7): a sliding knob over a green zone
## with a brighter centre. Used by Tug of War (the swinging marker) and by
## Spinning Tops (aim and power). The zone has thick ticks at its ends and a
## striped centre, so it reads without colour (GDD 189.5).

const BAR_HEIGHT := 30.0
const KNOB_SIZE := Vector2(18.0, 48.0)

## Knob position, 0..1 along the bar.
var value: float = 0.0:
	set(next):
		value = next
		queue_redraw()
var zone_centre: float = 0.5:
	set(next):
		zone_centre = next
		queue_redraw()
var zone_half: float = 0.1:
	set(next):
		zone_half = next
		queue_redraw()
## Share of the zone's half width drawn as its centre (0 for none).
var perfect_share: float = 0.35:
	set(next):
		perfect_share = next
		queue_redraw()
## Faded zone: the press is not available right now.
var dimmed: bool = false:
	set(next):
		dimmed = next
		queue_redraw()
## Optional caption above the bar.
var caption: String = "":
	set(next):
		caption = next
		if _caption != null:
			_caption.text = next
			_caption.visible = next != ""

var _caption: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(220.0, KNOB_SIZE.y)
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_caption.offset_top = -30.0
	_caption.offset_bottom = -2.0
	UiTokens.outline_text(_caption, UiTokens.FONT_BUTTON, UiTokens.CREAM_50, 7)
	_caption.text = caption
	_caption.visible = caption != ""
	add_child(_caption)


func _draw() -> void:
	var bar := Rect2(Vector2(0.0, (size.y - BAR_HEIGHT) * 0.5), Vector2(size.x, BAR_HEIGHT))
	var radius := int(BAR_HEIGHT * 0.5)
	var outer := UiSkin.rounded(UiTokens.INK_900, radius + 6)
	outer.shadow_color = UiTokens.SHADOW
	outer.shadow_size = 6
	outer.shadow_offset = Vector2(0.0, 3.0)
	draw_style_box(outer, bar.grow(6.0))
	draw_style_box(UiSkin.rounded(UiTokens.CREAM_50, radius + 3), bar.grow(3.0))
	draw_style_box(UiSkin.rounded(UiTokens.PAPER_200, radius), bar)
	var alpha := 0.45 if dimmed else 1.0
	var from := clampf(zone_centre - zone_half, 0.0, 1.0)
	var to := clampf(zone_centre + zone_half, 0.0, 1.0)
	var zone := Rect2(Vector2(bar.position.x + bar.size.x * from, bar.position.y), Vector2(bar.size.x * (to - from), bar.size.y))
	draw_rect(zone, Color(UiTokens.GRASS_500, alpha))
	if perfect_share > 0.0:
		var inner_half := zone_half * perfect_share
		var inner := Rect2(Vector2(bar.position.x + bar.size.x * (zone_centre - inner_half), bar.position.y), Vector2(bar.size.x * inner_half * 2.0, bar.size.y))
		draw_rect(inner, Color(UiTokens.GRASS_500.lightened(0.35), alpha))
		var x := inner.position.x + 3.0
		while x < inner.end.x - 3.0:
			draw_line(Vector2(x, inner.end.y - 3.0), Vector2(x + 6.0, inner.position.y + 3.0), Color(UiTokens.CREAM_50, 0.7 * alpha), 2.0)
			x += 9.0
	for edge: float in [zone.position.x, zone.end.x]:
		draw_line(Vector2(edge, bar.position.y - 5.0), Vector2(edge, bar.end.y + 5.0), Color(UiTokens.INK_900, alpha), 4.0)
	var knob_x := bar.position.x + bar.size.x * clampf(value, 0.0, 1.0)
	var knob := Rect2(Vector2(knob_x - KNOB_SIZE.x * 0.5, bar.get_center().y - KNOB_SIZE.y * 0.5), KNOB_SIZE)
	var face := UiSkin.rounded(UiTokens.SUN_500, 7, 3)
	face.border_width_bottom = 5
	face.shadow_color = UiTokens.SHADOW
	face.shadow_size = 4
	face.shadow_offset = Vector2(0.0, 2.0)
	draw_style_box(face, knob.grow(2.0))
	draw_line(Vector2(knob_x, knob.position.y + 6.0), Vector2(knob_x, knob.end.y - 6.0), UiTokens.INK_900, 2.0)
