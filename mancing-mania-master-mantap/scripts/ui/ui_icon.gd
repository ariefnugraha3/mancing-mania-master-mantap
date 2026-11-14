class_name UiIcon
extends Control
## A procedural UI icon as a Control (GDD 174.10, 184.11). The drawing lives
## in IconPainter, shared with IconTexture, so the same icon can sit in a chip
## or on a button. No icon image exists anywhere in the project.

const ICON_CASH := &"ui_icon_cash"
const ICON_BUCKET := &"ui_icon_bucket"
const ICON_MARKET := &"ui_icon_market"
const ICON_PAUSE := &"ui_icon_pause"
const ICON_WARNING := &"ui_icon_warning"
const ICON_ROD := &"ui_icon_rod"
const ICON_FISH := &"ui_icon_fish"

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
	IconPainter.paint(get_canvas_item(), icon_id, Rect2(Vector2.ZERO, size), tint)
