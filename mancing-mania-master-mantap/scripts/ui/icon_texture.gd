class_name IconTexture
extends Texture2D
## A procedural icon usable anywhere a texture is expected, mostly as
## Button.icon: the button then lays the icon and its text out together,
## centred, and tints the icon with its theme icon colours. The icon is drawn
## in white by IconPainter and the button's modulate gives it its colour.

@export var icon_id: StringName = IconPainter.PLAY
@export var icon_size: int = 24


static func make(id: StringName, pixels: int = 24) -> IconTexture:
	var texture := IconTexture.new()
	texture.icon_id = id
	texture.icon_size = pixels
	return texture


func _get_width() -> int:
	return icon_size


func _get_height() -> int:
	return icon_size


func _has_alpha() -> bool:
	return true


func _is_pixel_opaque(_x: int, _y: int) -> bool:
	return false


func _draw(to_canvas_item: RID, pos: Vector2, modulate: Color, _transpose: bool) -> void:
	IconPainter.paint(to_canvas_item, icon_id, Rect2(pos, Vector2(icon_size, icon_size)), modulate)


func _draw_rect(to_canvas_item: RID, rect: Rect2, _tile: bool, modulate: Color, _transpose: bool) -> void:
	IconPainter.paint(to_canvas_item, icon_id, rect, modulate)


func _draw_rect_region(to_canvas_item: RID, rect: Rect2, _src_rect: Rect2, modulate: Color, _transpose: bool, _clip_uv: bool) -> void:
	IconPainter.paint(to_canvas_item, icon_id, rect, modulate)
