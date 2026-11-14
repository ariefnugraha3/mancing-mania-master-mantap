class_name DioramaCamera
extends Camera3D
## The one camera of the game (VISUAL_STYLE_GUIDE 2, GDD 173.1): orthographic,
## yaw 45 deg, pitch 35 deg, no roll, locked rotation, KEEP_WIDTH.
##
## A scene only says where to look and how wide a slice of the world to show.
## Each set carries a `CameraFocus` marker whose metadata holds the frame width
## for the portrait phone screen; a tablet's wider screen shows a wider slice
## (TABLET_WIDTH_SCALE) so the diorama keeps its share of the screen. The
## camera slides the picture up or down so the diorama sits in the middle of
## the space between the HUD bars (guide 2.4).
##
## The camera never shakes and never travels for routine events. A story beat
## may glide to a closer framing; with Reduced Motion on, it cuts instead.

## Marker metadata: the frame width on a phone, and an optional other point to
## look at on the portrait screen.
const META_WIDTH := &"width_portrait"
const META_FOCUS := &"focus_portrait"
const GLIDE_SEC := 0.6
## A tablet is wider for its height than a phone, so it shows more world.
const TABLET_WIDTH_SCALE := 1.25

var _focus: Vector3 = Vector3.ZERO
var _width: float = DioramaStyle.WIDTH_DEFAULT
## HUD bars (top, bottom) in canvas points.
var _insets: Vector2 = Vector2.ZERO
var _glide: Tween


func _init() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	keep_aspect = Camera3D.KEEP_WIDTH
	size = DioramaStyle.WIDTH_DEFAULT
	near = DioramaStyle.CAMERA_NEAR
	far = DioramaStyle.CAMERA_FAR


func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	keep_aspect = Camera3D.KEEP_WIDTH
	near = DioramaStyle.CAMERA_NEAR
	far = DioramaStyle.CAMERA_FAR
	var platform := get_node_or_null("/root/PlatformService")
	if platform != null:
		platform.viewport_class_changed.connect(_on_layout_changed)
	get_viewport().size_changed.connect(_apply)
	_apply()


# --- Framing ----------------------------------------------------------------

## Looks at `focus` showing `width` metres of the world on a phone.
func frame(focus: Vector3, width: float = DioramaStyle.WIDTH_DEFAULT) -> void:
	_stop_glide()
	_focus = focus
	_width = DioramaStyle.clamp_width(width)
	_apply()


## Frames a set's `CameraFocus` marker (or any marker with width metadata).
func frame_marker(marker: Node3D) -> void:
	if marker == null:
		return
	frame(marker_focus(marker), marker_width(marker))


## Where a focus marker asks the camera to look on the portrait screen.
static func marker_focus(marker: Node3D) -> Vector3:
	if marker.has_meta(META_FOCUS):
		var parent := marker.get_parent() as Node3D
		var local: Vector3 = marker.get_meta(META_FOCUS)
		return parent.global_transform * local if parent != null else local
	return marker.global_position


static func marker_width(marker: Node3D) -> float:
	return float(marker.get_meta(META_WIDTH, DioramaStyle.WIDTH_DEFAULT))


## The HUD bars of the scene (top, bottom): canvas points, or a share of the
## screen height for values up to 1.0 (a bottom sheet that scales with it).
func set_hud_insets(insets: Vector2) -> void:
	_insets = insets
	_apply()


## A soft move to a closer (or wider) framing for an important moment. With
## Reduced Motion on it is a cut.
func glide_to(focus: Vector3, width: float, seconds: float = GLIDE_SEC) -> void:
	_stop_glide()
	var target_width := DioramaStyle.clamp_width(width)
	if seconds <= 0.0 or _reduced_motion() or not is_inside_tree():
		_focus = focus
		_width = target_width
		_apply()
		return
	_glide = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glide.tween_method(_glide_step.bind(_focus, focus, _width, target_width), 0.0, 1.0, seconds)


func get_focus() -> Vector3:
	return _focus


## The world width shown right now, in metres.
func get_frame_width() -> float:
	return _current_width()


## The point on the floor (y = 0) under a screen position (guide 2.4).
func floor_point(screen_position: Vector2) -> Variant:
	var origin := project_ray_origin(screen_position)
	var direction := project_ray_normal(screen_position)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)


# --- Internals --------------------------------------------------------------

func _apply() -> void:
	size = _current_width()
	var offset := DioramaStyle.camera_offset()
	var basis := Basis.looking_at(-offset, Vector3.UP)
	if not is_inside_tree():
		transform = Transform3D(basis, _focus + offset)
		return
	var visible := get_viewport().get_visible_rect().size
	var viewport_width := maxf(visible.x, 1.0)
	var top := _insets.x * visible.y if _insets.x <= 1.0 else _insets.x
	var bottom := _insets.y * visible.y if _insets.y <= 1.0 else _insets.y
	# A taller bottom bar moves the camera down, so the set rises into the
	# middle of the free space (guide 2.4).
	var shift := (bottom - top) * 0.5 * size / viewport_width
	global_transform = Transform3D(basis, _focus + offset - basis.y * shift)


func _glide_step(progress: float, from_focus: Vector3, to_focus: Vector3, from_width: float, to_width: float) -> void:
	_focus = from_focus.lerp(to_focus, progress)
	_width = lerpf(from_width, to_width, progress)
	_apply()


## The phone width, or the wider tablet slice.
func _current_width() -> float:
	if _is_tablet():
		return DioramaStyle.clamp_width(_width * TABLET_WIDTH_SCALE)
	return _width


func _is_tablet() -> bool:
	var platform := get_node_or_null("/root/PlatformService") if is_inside_tree() else null
	return platform != null and platform.is_tablet()


func _reduced_motion() -> bool:
	var state := get_node_or_null("/root/GameState")
	return state != null and bool(state.get_setting(&"reduced_motion"))


func _stop_glide() -> void:
	if _glide != null and _glide.is_valid():
		_glide.kill()
	_glide = null


func _on_layout_changed(_viewport_class: StringName) -> void:
	_apply()
