class_name GameButton
extends Button
## Standard button with the tactile feedback from GDD 167.5: the face sinks
## into its lip (theme), a quick press-in, a tiny overshoot on release and a
## procedural click. A disabled button answers with a dry tap and does nothing
## else. `icon_id` puts a procedural icon (IconPainter) before the text.

@export var click_sfx: StringName = &"ui_click"
@export var min_height: int = UiTokens.TOUCH_TARGET_PREFERRED
## Size of the procedural icon in canvas points. Set it before `icon_id`.
@export var icon_pixels: int = 24
## A procedural icon id (IconPainter), drawn before the text. Empty for none.
@export var icon_id: StringName = &"":
	set(value):
		icon_id = value
		icon = IconTexture.make(value, icon_pixels) if value != &"" else null

var _tween: Tween
## Side padding asked for with set_side_padding(), or -1 for the theme's.
var _side_padding: float = -1.0


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, float(min_height))
	if icon_id != &"" and icon == null:
		icon = IconTexture.make(icon_id, icon_pixels)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)
	if _side_padding >= 0.0:
		_apply_side_padding()


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
