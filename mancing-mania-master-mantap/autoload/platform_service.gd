extends Node
## Platform, viewport-class and safe-area detection (GDD 122, 123, 167.7, 169.7).
##
## The layout mode comes from the window aspect ratio, never from a browser
## user agent. This service also swaps the stretch reference between the
## landscape (1280x720) and portrait (720x1280) baselines, so one project
## serves the itch.io Web build and the portrait Android build.

signal viewport_class_changed(viewport_class: StringName)

const LANDSCAPE_WIDE := &"landscape_wide"
const LANDSCAPE_COMPACT := &"landscape_compact"
const PORTRAIT := &"portrait"

const REFERENCE_LANDSCAPE := Vector2i(1280, 720)
const REFERENCE_PORTRAIT := Vector2i(720, 1280)
const WIDE_ASPECT_MIN := 1.45

var _viewport_class: StringName = LANDSCAPE_WIDE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size_changed.connect(_on_window_size_changed)
	_refresh(false)


func is_web() -> bool:
	return OS.has_feature("web")


func is_android() -> bool:
	return OS.has_feature("android")


func get_viewport_class() -> StringName:
	return _viewport_class


## The area of the canvas that is safe for critical UI, in canvas coordinates.
## Android reports cutouts and gesture areas; elsewhere it is the full canvas.
func get_safe_rect() -> Rect2i:
	var canvas := Rect2i(Vector2i.ZERO, Vector2i(get_window().get_visible_rect().size))
	if not is_android():
		return canvas
	var window_size := get_window().size
	if window_size.x <= 0 or window_size.y <= 0:
		return canvas
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		return canvas
	var scale := Vector2(canvas.size) / Vector2(window_size)
	var position := Vector2i((Vector2(safe.position) * scale).floor())
	var end := Vector2i((Vector2(safe.end) * scale).ceil())
	return Rect2i(position, end - position).intersection(canvas)


## How many physical pixels one reference-resolution pixel covers.
func get_reference_scale() -> float:
	var window_size := Vector2(get_window().size)
	var reference := Vector2(reference_size_for_class(_viewport_class))
	if reference.x <= 0.0 or reference.y <= 0.0:
		return 1.0
	return minf(window_size.x / reference.x, window_size.y / reference.y)


## Manual save export/import is offered on Web, where browser storage can be
## cleared by the player (GDD 117).
func supports_file_import_export() -> bool:
	return is_web()


func request_fullscreen(enable: bool) -> void:
	if is_android():
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enable else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


## Pure classification used by the service and by the layout tests.
static func classify_aspect(width: float, height: float) -> StringName:
	if width <= 0.0 or height <= 0.0:
		return LANDSCAPE_WIDE
	var aspect := width / height
	if aspect >= WIDE_ASPECT_MIN:
		return LANDSCAPE_WIDE
	if aspect >= 1.0:
		return LANDSCAPE_COMPACT
	return PORTRAIT


static func reference_size_for_class(viewport_class: StringName) -> Vector2i:
	return REFERENCE_PORTRAIT if viewport_class == PORTRAIT else REFERENCE_LANDSCAPE


func _on_window_size_changed() -> void:
	_refresh(true)


func _refresh(notify: bool) -> void:
	var window := get_window()
	var size := Vector2(window.size)
	var next_class := classify_aspect(size.x, size.y)
	var reference := reference_size_for_class(next_class)
	if window.content_scale_size != reference:
		window.content_scale_size = reference
	if next_class != _viewport_class:
		_viewport_class = next_class
		if notify:
			viewport_class_changed.emit(_viewport_class)
