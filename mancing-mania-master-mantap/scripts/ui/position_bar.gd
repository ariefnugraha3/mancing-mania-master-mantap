class_name PositionBar
extends Control
## The arm wrestling tug-of-war read-out (GDD 50, 189.5): one bar from the
## fish's end to Darto's end with a marker where the hands are.
##
## Darto's end is on the left, the side his arm leans toward when he is
## winning. The ends are labelled with names, the middle has a notch, and the
## Sudden Grip band is marked, so nothing depends on colour.

const BAR_HEIGHT := 26.0
const MARKER_SIZE := Vector2(16.0, 44.0)

var position_value: float = 0.0:
	set(value):
		position_value = value
		queue_redraw()
var range_max: float = 100.0
## Half-width of the band around zero that goes to Sudden Grip at time.
var grip_band: float = 2.0

var _left_label: Label
var _right_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240.0, BAR_HEIGHT + 34.0)
	_left_label = _make_label(HORIZONTAL_ALIGNMENT_LEFT)
	_right_label = _make_label(HORIZONTAL_ALIGNMENT_RIGHT)


func set_names(player_name: String, fish_name: String) -> void:
	_left_label.text = player_name
	_right_label.text = fish_name


## Where the marker is drawn, 0 (Darto's end) to 1 (fish's end).
func get_marker_ratio() -> float:
	return clampf(0.5 - position_value / (range_max * 2.0), 0.0, 1.0)


func _make_label(alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_bottom = 28.0
	UiTokens.outline_text(label, UiTokens.FONT_BUTTON, UiTokens.CREAM_50, 7)
	add_child(label)
	return label


func _draw() -> void:
	var bar := Rect2(Vector2(0.0, size.y - BAR_HEIGHT - 6.0), Vector2(size.x, BAR_HEIGHT))
	var middle := bar.position.x + bar.size.x * 0.5
	var radius := int(BAR_HEIGHT * 0.5)
	# A cocoa outline, a cream rim, then the two halves with rounded ends.
	var outer := UiSkin.rounded(UiTokens.INK_900, radius + 6)
	outer.shadow_color = UiTokens.SHADOW
	outer.shadow_size = 6
	outer.shadow_offset = Vector2(0.0, 3.0)
	draw_style_box(outer, bar.grow(6.0))
	draw_style_box(UiSkin.rounded(UiTokens.CREAM_50, radius + 3), bar.grow(3.0))
	# Darto's half and the fish's half in two tones, plus hatching on the fish's.
	var darto_face := UiSkin.rounded(UiTokens.GRASS_500.lightened(0.15), radius)
	darto_face.corner_radius_top_right = 0
	darto_face.corner_radius_bottom_right = 0
	draw_style_box(darto_face, Rect2(bar.position, Vector2(bar.size.x * 0.5, bar.size.y)))
	var fish_half := Rect2(Vector2(middle, bar.position.y), Vector2(bar.size.x * 0.5, bar.size.y))
	var fish_face := UiSkin.rounded(UiTokens.TERRACOTTA_500.lightened(0.2), radius)
	fish_face.corner_radius_top_left = 0
	fish_face.corner_radius_bottom_left = 0
	draw_style_box(fish_face, fish_half)
	var x := fish_half.position.x + 6.0
	while x < fish_half.end.x - radius - 4.0:
		draw_line(Vector2(x, fish_half.end.y), Vector2(x + 8.0, fish_half.position.y), Color(UiTokens.INK_900, 0.25), 2.0)
		x += 12.0
	# The Sudden Grip band around zero.
	var band := bar.size.x * grip_band / (range_max * 2.0)
	draw_rect(Rect2(Vector2(middle - band, bar.position.y), Vector2(band * 2.0, bar.size.y)), Color(UiTokens.CREAM_50, 0.8))
	draw_line(Vector2(middle, bar.position.y - 6.0), Vector2(middle, bar.end.y + 6.0), UiTokens.INK_900, 3.0)

	var marker_x := bar.position.x + bar.size.x * get_marker_ratio()
	var marker := Rect2(Vector2(marker_x - MARKER_SIZE.x * 0.5, bar.get_center().y - MARKER_SIZE.y * 0.5), MARKER_SIZE)
	var knob := UiSkin.rounded(UiTokens.SUN_500, 7, 3)
	knob.border_width_bottom = 5
	knob.shadow_color = UiTokens.SHADOW
	knob.shadow_size = 4
	knob.shadow_offset = Vector2(0.0, 2.0)
	draw_style_box(knob, marker.grow(2.0))
	draw_line(Vector2(marker_x, marker.position.y + 6.0), Vector2(marker_x, marker.end.y - 6.0), UiTokens.INK_900, 2.0)
