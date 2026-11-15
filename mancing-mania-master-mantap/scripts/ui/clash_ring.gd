class_name ClashRing
extends Control
## The Spinning Tops clash cue (revision 6.7): a ring closing in on a fixed
## target circle. Tap as the ring meets the circle. The target is a thick
## dashed circle and the ring a solid one, so the cue reads without colour.

## 1 when the ring appears, 0 at the moment of impact.
var progress: float = 1.0:
	set(next):
		progress = next
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centre := size * 0.5
	var outer := minf(size.x, size.y) * 0.5 - 6.0
	var target := outer * 0.38
	# The target: a cream disc with a dashed cocoa edge.
	draw_circle(centre, target, Color(UiTokens.CREAM_50, 0.55))
	var dashes := 18
	for index: int in dashes:
		var from := TAU * float(index) / float(dashes)
		draw_arc(centre, target, from, from + TAU / float(dashes) * 0.55, 6, UiTokens.INK_900, 5.0, true)
	var radius := lerpf(target, outer, clampf(progress, 0.0, 1.0))
	var close := progress < 0.18
	var tone := UiTokens.SUN_500 if close else UiTokens.CREAM_50
	draw_arc(centre, radius, 0.0, TAU, 64, UiTokens.INK_900, 12.0, true)
	draw_arc(centre, radius, 0.0, TAU, 64, tone, 7.0, true)
