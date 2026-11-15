class_name LogoEmblem
extends Control
## The game's round emblem above the title (GDD 186.4 identity, revision
## 6.8): a vintage badge with a leaping, gloved fish caught on a line over a
## sunset lake. The art is IconPainter.EMBLEM, drawn in the same sticker
## style as every icon. It wiggles gently on the Main Menu unless Reduced
## Motion is on.

@export var diameter: float = 96.0:
	set(value):
		diameter = value
		custom_minimum_size = Vector2(value, value)
		queue_redraw()

var _clock: float = 0.0
var _wiggle: bool = true


func _ready() -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wiggle = not bool(GameState.get_setting(&"reduced_motion"))


func _process(delta: float) -> void:
	if not _wiggle:
		rotation = 0.0
		return
	_clock += delta
	pivot_offset = size * 0.5
	rotation = deg_to_rad(4.0) * sin(_clock * 1.6)


func _draw() -> void:
	var centre := size * 0.5
	var radius := minf(size.x, size.y) * 0.5
	# A soft shadow under the badge, then the sticker itself (IconPainter).
	draw_circle(centre + Vector2(0.0, radius * 0.08), radius * 0.98, Color(UiTokens.INK_900, 0.22))
	IconPainter.paint(get_canvas_item(), IconPainter.EMBLEM, Rect2(Vector2.ZERO, size))
