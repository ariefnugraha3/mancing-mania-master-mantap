extends Node
## Root of wheel.tscn (GDD 38, 168.6): the fish that was landed stands on the
## bank, the Wheel of Fate spins to the duel chosen before it moved, and the
## duel scene takes over. After the first Wheel, holding the action for 0.6 s
## skips to the reveal.

const POINTER_SIZE := 28.0
const MAX_TIME_STEP_SEC := 0.1

@onready var _controller: WheelController = $WheelController
@onready var _fish_anchor: Node3D = $World/FishDisplayAnchor
@onready var _camera: Camera3D = $World/WheelCamera
@onready var _safe_root: Control = $WheelCanvas/SafeRoot
@onready var _title: Label = $WheelCanvas/SafeRoot/FishTitle
@onready var _wheel: WheelGraphic = $WheelCanvas/SafeRoot/WheelGraphic
@onready var _pointer: Control = $WheelCanvas/SafeRoot/Pointer
@onready var _result: Label = $WheelCanvas/SafeRoot/ResultLabel
@onready var _skip: ProgressBar = $WheelCanvas/SafeRoot/SkipHoldIndicator

var _fish_id: StringName
var _hold: float = 0.0
var _touch_held: bool = false
var _leaving: bool = false
var _last_segment: int = -1


func _ready() -> void:
	_fish_id = SceneRouter.get_context().get("fish_id", GameState.current_fish)
	if GameData.get_fish(_fish_id) == null:
		_fish_id = &"catfish_bruiser"
	var fish := GameData.get_fish(_fish_id)
	var model: Node3D = fish.model_scene.instantiate()
	_fish_anchor.add_child(model)
	(model.get_node("AnimationPlayer") as AnimationPlayer).play(&"box_idle")
	_title.text = fish.display_name.to_upper()
	UiTokens.outline_text(_title, UiTokens.FONT_SCREEN_TITLE)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTokens.outline_text(_result, 44, UiTokens.SUN_500)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.visible = false
	_pointer.draw.connect(_draw_pointer)
	_skip.show_percentage = false
	_skip.max_value = WheelController.SKIP_HOLD_SEC
	_skip.visible = false
	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(func(_c: StringName) -> void: _layout())
	_layout.call_deferred()
	_controller.wheel_resolved.connect(_on_resolved)
	AudioManager.set_music_state(&"silence")
	var allow_skip := GameState.is_tutorial_seen(&"wheel_seen")
	# The spin comes from the catch's own encounter seed, so the same catch
	# always lands on the same duel.
	var seed := int(GameState.current_catch.get("seed", 0))
	if seed == 0:
		seed = RNGService.next_duel_seed()
	_controller.start_wheel(_fish_id, seed, allow_skip)


func _process(delta: float) -> void:
	if _leaving:
		return
	_wheel.turns = _controller.get_rotation_turns()
	var segment := _controller.get_segment_under_pointer()
	if segment != _last_segment and _controller.get_state() == WheelController.STATE_SPINNING:
		_last_segment = segment
		AudioManager.play_sfx(&"sfx_reel_tick", -10.0)
	var holding := _touch_held or InputManager.get_action_strength_safe(&"fish_cast") > 0.0 or Input.is_action_pressed(InputActions.UI_CONFIRM)
	if GameState.is_tutorial_seen(&"wheel_seen") and _controller.get_state() == WheelController.STATE_SPINNING and holding:
		_hold += minf(delta, MAX_TIME_STEP_SEC)
		_skip.visible = true
		_skip.value = _hold
		if _hold >= WheelController.SKIP_HOLD_SEC:
			_controller.request_skip()
	else:
		_hold = 0.0
		_skip.visible = false
	if _controller.get_state() == WheelController.STATE_REVEAL and not _result.visible:
		_wheel.highlight = _controller.get_segment()
		_result.text = TextDb.tf(&"wheel.result", {"duel": TextDb.t(StringName("duel.%s.upper" % _controller.get_preselected_duel_id()))})
		_result.visible = true
		AudioManager.play_ui(&"ui_purchase")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		_touch_held = event.is_pressed()


func _on_resolved(duel_id: StringName) -> void:
	_leaving = true
	GameState.set_tutorial_seen(&"wheel_seen")
	GameState.current_duel = duel_id
	SceneRouter.goto_duel(duel_id, _fish_id)


func _draw_pointer() -> void:
	var w := _pointer.size
	_pointer.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w.x, 0), Vector2(w.x * 0.5, w.y)]), UiTokens.CREAM_50)
	_pointer.draw_polyline(PackedVector2Array([Vector2(0, 0), Vector2(w.x, 0), Vector2(w.x * 0.5, w.y), Vector2(0, 0)]), UiTokens.INK_900, 3.0, true)


func _layout() -> void:
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var area := _safe_root.size
	var diameter := minf(area.x * (0.9 if portrait else 0.46), area.y * (0.5 if portrait else 0.78))
	var centre := Vector2(area.x * 0.5, area.y * 0.62) if portrait else Vector2(area.x * 0.68, area.y * 0.52)
	_place(_wheel, Rect2(centre - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter))
	_place(_pointer, Rect2(centre.x - POINTER_SIZE * 0.5, centre.y - diameter * 0.5 - POINTER_SIZE * 0.6, POINTER_SIZE, POINTER_SIZE))
	_place(_title, Rect2(0.0, 0.0, area.x, 48.0))
	_place(_result, Rect2(centre.x - 260.0, centre.y + diameter * 0.5 + 8.0, 520.0, 56.0) if not portrait else Rect2(0.0, area.y * 0.25, area.x, 56.0))
	_place(_skip, Rect2(centre.x - 120.0, area.y - 24.0, 240.0, 14.0))
	_camera.fov = 58.0 if portrait else 45.0


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
