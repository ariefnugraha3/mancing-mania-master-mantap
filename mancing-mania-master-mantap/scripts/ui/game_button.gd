class_name GameButton
extends Button
## Standard button with the tactile feedback from GDD 167.5: the face sinks
## into its lip (theme), a quick press-in, a tiny overshoot on release and a
## procedural click. A disabled button answers with a dry tap and does nothing
## else. `icon_id` puts a procedural icon (IconPainter) before the text.
##
## Centred text beside a left icon: Godot centres a button's text in the
## space after its icon, which pushes the words right of the middle. When
## the button is wide enough, this script draws the icon itself at the left
## padding instead, so Godot centres the text across the whole button, and
## the button's minimum size does not grow. On a button too narrow for that
## (the text would reach the icon), Godot lays the icon out as before.

@export var click_sfx: StringName = &"ui_click"
@export var min_height: int = UiTokens.TOUCH_TARGET_PREFERRED
## Size of the procedural icon in canvas points. Set it before `icon_id`.
@export var icon_pixels: int = 24
## A procedural icon id (IconPainter), drawn before the text. Empty for none.
@export var icon_id: StringName = &"":
	set(value):
		icon_id = value
		_icon_texture = IconTexture.make(value, icon_pixels) if value != &"" else null
		_drawn_icon = false
		icon = _icon_texture
		if is_inside_tree():
			_queue_icon_layout()

var _tween: Tween
## Side padding asked for with set_side_padding(), or -1 for the theme's.
var _side_padding: float = -1.0
## The icon `icon_id` made (Button.icon is cleared while it is drawn here).
var _icon_texture: Texture2D
## True while this script draws the icon, so the text centres on the button.
var _drawn_icon: bool = false
var _layout_queued: bool = false


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, float(min_height))
	if icon_id != &"" and _icon_texture == null:
		_icon_texture = IconTexture.make(icon_id, icon_pixels)
		icon = _icon_texture
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)
	if _side_padding >= 0.0:
		_apply_side_padding()
	resized.connect(_queue_icon_layout)
	minimum_size_changed.connect(_queue_icon_layout)
	_queue_icon_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED and is_node_ready():
		_queue_icon_layout()
	elif what == NOTIFICATION_SCROLL_BEGIN and is_node_ready():
		# The finger started on this button but dragged the list: the press is
		# cancelled (no button_up follows), so the button rises again here.
		_animate_scale(1.0, UiTokens.RELEASE_SEC, false)


func _draw() -> void:
	if not _drawn_icon or _icon_texture == null:
		return
	var state := _style_state()
	var style := get_theme_stylebox(state)
	var side := _icon_side()
	var top := style.get_margin(SIDE_TOP)
	var bottom := style.get_margin(SIDE_BOTTOM)
	var at := Vector2(style.get_margin(SIDE_LEFT), top + (size.y - top - bottom - side) * 0.5)
	draw_texture_rect(_icon_texture, Rect2(at, Vector2(side, side)), false, get_theme_color(StringName("icon_%s_color" % state)))


## True while the icon is drawn by this script (text centred on the button).
func is_text_centred() -> bool:
	return _drawn_icon


func _queue_icon_layout() -> void:
	if not _layout_queued:
		_layout_queued = true
		_update_icon_layout.call_deferred()


## Chooses who draws the icon: this script (text centred on the whole
## button) when the text clears the icon, Godot (text centred after the
## icon) when it would not.
func _update_icon_layout() -> void:
	_layout_queued = false
	if not is_inside_tree() or _icon_texture == null:
		return
	var draw_here := _has_side_icon() and _centred_text_clears_icon()
	if draw_here == _drawn_icon and (icon == null) == draw_here:
		return
	_drawn_icon = draw_here
	icon = null if draw_here else _icon_texture
	queue_redraw()


## An icon left of centred text: the layout that pulls the text off centre.
func _has_side_icon() -> bool:
	return text != "" and icon_alignment == HORIZONTAL_ALIGNMENT_LEFT 		and vertical_icon_alignment == VERTICAL_ALIGNMENT_CENTER and alignment == HORIZONTAL_ALIGNMENT_CENTER


func _centred_text_clears_icon() -> bool:
	var style := get_theme_stylebox(&"normal")
	var font := get_theme_font(&"font")
	if style == null or font == null:
		return false
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, get_theme_font_size(&"font_size")).x
	var icon_end := style.get_margin(SIDE_LEFT) + _icon_side() + float(get_theme_constant(&"h_separation"))
	return (size.x - text_width) * 0.5 >= icon_end


## The icon's side in points, capped by the theme like Button's own icon.
func _icon_side() -> float:
	var side := float(_icon_texture.get_width())
	var max_width := get_theme_constant(&"icon_max_width")
	return minf(side, float(max_width)) if max_width > 0 else side


## The style (and icon colour) name for the button's current look.
func _style_state() -> String:
	match get_draw_mode():
		DRAW_DISABLED:
			return "disabled"
		DRAW_PRESSED, DRAW_HOVER_PRESSED:
			return "pressed"
		DRAW_HOVER:
			return "hover"
	return "normal"


## Narrows the side padding of every state, so a small thumb button keeps
## room for its caption. It is applied once the button is in the tree, where
## its theme variation (CTA, danger...) is known.
func set_side_padding(points: float) -> void:
	_side_padding = points
	if is_inside_tree():
		_apply_side_padding()


func _apply_side_padding() -> void:
	var points := _side_padding
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		remove_theme_stylebox_override(state)
		var box := get_theme_stylebox(state).duplicate() as StyleBox
		if box == null:
			continue
		box.content_margin_left = points
		box.content_margin_right = points
		add_theme_stylebox_override(state, box)


func _gui_input(event: InputEvent) -> void:
	if disabled and InputActions.is_primary_press(event):
		AudioManager.play_ui(&"ui_disabled")


func _on_button_down() -> void:
	_animate_scale(UiTokens.PRESS_SCALE, UiTokens.PRESS_SEC, false)


func _on_button_up() -> void:
	_animate_scale(1.0, UiTokens.RELEASE_SEC, true)


func _on_pressed() -> void:
	if click_sfx != &"":
		AudioManager.play_ui(click_sfx)


func _animate_scale(target: float, duration: float, overshoot: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if GameState.get_setting(&"reduced_motion"):
		scale = Vector2.ONE
		return
	pivot_offset = size * 0.5
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if overshoot:
		var peak := Vector2.ONE * UiTokens.RELEASE_OVERSHOOT
		_tween.tween_property(self, "scale", peak, duration * 0.5).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "scale", Vector2.ONE * target, duration * 0.5).set_ease(Tween.EASE_IN_OUT)
	else:
		_tween.tween_property(self, "scale", Vector2.ONE * target, duration).set_ease(Tween.EASE_OUT)
