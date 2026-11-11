class_name GameButton
extends Button
## Standard button with the tactile feedback from GDD 167.5: a quick press-in,
## a tiny overshoot on release and a procedural click. A disabled button
## answers with a dry tap and does nothing else.

@export var click_sfx: StringName = &"ui_click"
@export var min_height: int = UiTokens.TOUCH_TARGET_PREFERRED

var _tween: Tween


func _ready() -> void:
	custom_minimum_size.y = maxf(custom_minimum_size.y, float(min_height))
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)


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
