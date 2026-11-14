extends Node
## Portrait phone and tablet canvas, form factor and safe area (GDD 122, 123,
## 167.7, 167.8, 169.7).
##
## The game is played upright on phones and tablets, Android and iPhone/iPad.
## Its canvas is measured in device-independent points: a phone shows a canvas
## about 390 points wide, so a 48-point button is a 48 dp / 44 pt touch target
## and 18-point text reads at a phone's body size. A tablet gets a canvas 600
## points wide: more room, and everything a little larger than on a phone.
## Anything wider than a tablet (a desktop window, the Web build in a landscape
## browser, an unfolded foldable) shows the widest tablet canvas with side bars.
##
## The form factor comes from the window's shape, never from a user agent.

signal viewport_class_changed(viewport_class: StringName)
## The safe area moved: a rotation, a resize, or a simulated cutout.
signal safe_area_changed()

const PHONE := &"phone"
const TABLET := &"tablet"

## Canvas of a 9:16 phone; taller phones get a taller canvas of the same width.
const PHONE_CANVAS := Vector2i(390, 694)
## Canvas of a 3:4 tablet; narrower tablets get a taller canvas.
const TABLET_CANVAS := Vector2i(600, 800)
## Width / height from which a screen is a tablet (10-inch Android tablets are
## 0.625, iPads 0.66-0.75, phones 0.45-0.56).
const TABLET_ASPECT_MIN := 0.62
## The widest canvas; wider windows keep this shape with bars at the sides.
const MAX_ASPECT := 0.8

var _form_factor: StringName = PHONE
## Extra insets (left, top, right, bottom) in canvas points, for QA and tests:
## they stand in for a notch and a home indicator on a desktop.
var _simulated_insets: Vector4 = Vector4.ZERO
## Set by tools that lay out a canvas of their own (the landscape store banner).
var _canvas_locked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size_changed.connect(_on_window_size_changed)
	_refresh(false)


func is_web() -> bool:
	return OS.has_feature("web")


func is_android() -> bool:
	return OS.has_feature("android")


func is_ios() -> bool:
	return OS.has_feature("ios")


## A phone or tablet app (not the Web build on a phone's browser).
func is_mobile() -> bool:
	return is_android() or is_ios()


func get_form_factor() -> StringName:
	return _form_factor


func is_tablet() -> bool:
	return _form_factor == TABLET


## The layout class of the canvas: PHONE or TABLET. Both are portrait.
func get_viewport_class() -> StringName:
	return _form_factor


## The area of the canvas that is safe for critical UI, in canvas points: the
## canvas minus the camera cutout, the status bar and the home indicator or
## gesture bar that Android and iOS report, minus any simulated insets.
func get_safe_rect() -> Rect2i:
	var window := get_window()
	var canvas := Rect2(Vector2.ZERO, window.get_visible_rect().size)
	var safe := canvas
	if is_mobile() and window.size.x > 0 and window.size.y > 0:
		var device := DisplayServer.get_display_safe_area()
		if device.size.x > 0 and device.size.y > 0:
			var to_canvas := window.get_final_transform().affine_inverse()
			safe = (to_canvas * Rect2(device)).intersection(canvas)
	safe.position += Vector2(_simulated_insets.x, _simulated_insets.y)
	safe.size -= Vector2(_simulated_insets.x + _simulated_insets.z, _simulated_insets.y + _simulated_insets.w)
	var position := Vector2i(safe.position.ceil())
	var end := Vector2i(safe.end.floor())
	return Rect2i(position, (end - position).max(Vector2i.ONE))


## Simulates a cutout and a home indicator (left, top, right, bottom points).
func set_simulated_insets(insets: Vector4) -> void:
	_simulated_insets = insets.max(Vector4.ZERO)
	safe_area_changed.emit()


func get_simulated_insets() -> Vector4:
	return _simulated_insets


## Stops choosing the canvas on resize, for a tool that sets its own (the
## 1024x500 store banner, GDD 186.5). The game never calls it.
func set_canvas_locked(locked: bool) -> void:
	_canvas_locked = locked
	if not locked:
		_refresh(true)


## How many physical pixels one canvas point covers.
func get_reference_scale() -> float:
	var window_size := Vector2(get_window().size)
	var canvas := Vector2(canvas_size_for(window_size.x, window_size.y))
	if canvas.x <= 0.0 or canvas.y <= 0.0:
		return 1.0
	return minf(window_size.x / canvas.x, window_size.y / canvas.y)


## Manual save export/import is offered on Web, where browser storage can be
## cleared by the player (GDD 117).
func supports_file_import_export() -> bool:
	return is_web()


func request_fullscreen(enable: bool) -> void:
	if is_mobile():
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enable else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


## Pure classification used by the service and by the layout tests.
static func classify_aspect(width: float, height: float) -> StringName:
	if width <= 0.0 or height <= 0.0:
		return PHONE
	return TABLET if width / height >= TABLET_ASPECT_MIN else PHONE


## The canvas a window of this size is laid out on.
static func canvas_size_for(width: float, height: float) -> Vector2i:
	if width <= 0.0 or height <= 0.0:
		return PHONE_CANVAS
	if width / height > MAX_ASPECT:
		return Vector2i(roundi(TABLET_CANVAS.y * MAX_ASPECT), TABLET_CANVAS.y)
	return TABLET_CANVAS if classify_aspect(width, height) == TABLET else PHONE_CANVAS


## Phones and tablets fill the screen; wider windows keep the widest shape.
static func aspect_mode_for(width: float, height: float) -> Window.ContentScaleAspect:
	if width > 0.0 and height > 0.0 and width / height > MAX_ASPECT:
		return Window.CONTENT_SCALE_ASPECT_KEEP
	return Window.CONTENT_SCALE_ASPECT_EXPAND


func _on_window_size_changed() -> void:
	_refresh(true)


func _refresh(notify: bool) -> void:
	var window := get_window()
	var size := Vector2(window.size)
	if _canvas_locked:
		return
	var canvas := canvas_size_for(size.x, size.y)
	if window.content_scale_size != canvas:
		window.content_scale_size = canvas
	var aspect := aspect_mode_for(size.x, size.y)
	if window.content_scale_aspect != aspect:
		window.content_scale_aspect = aspect
	var next := classify_aspect(size.x, size.y)
	if next != _form_factor:
		_form_factor = next
		if notify:
			viewport_class_changed.emit(_form_factor)
	if notify:
		safe_area_changed.emit()
