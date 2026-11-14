class_name SafeAreaRoot
extends Control
## Root for UI that must stay inside the device safe area (GDD 92, 167.8).
## It fills the canvas, then insets itself by the notch, status bar and home
## indicator or gesture bar reported by PlatformService, plus a comfortable
## edge margin. Children simply anchor to it.

## Edge margin on a phone and on a tablet, in canvas points.
@export var margin_phone: int = UiTokens.SPACE_12
@export var margin_tablet: int = UiTokens.SPACE_24


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(apply_safe_area)
	PlatformService.viewport_class_changed.connect(_on_viewport_class_changed)
	PlatformService.safe_area_changed.connect(apply_safe_area)
	apply_safe_area()


func apply_safe_area() -> void:
	var canvas := get_viewport_rect().size
	var safe := Rect2(PlatformService.get_safe_rect())
	var margin := float(get_margin())
	offset_left = safe.position.x + margin
	offset_top = safe.position.y + margin
	offset_right = -(canvas.x - safe.end.x) - margin
	offset_bottom = -(canvas.y - safe.end.y) - margin


func get_margin() -> int:
	return margin_tablet if PlatformService.is_tablet() else margin_phone


func _on_viewport_class_changed(_viewport_class: StringName) -> void:
	apply_safe_area()
