class_name PinangHud
extends SpotDuelHud
## Greased Pole HUD (revision 6.7): two climb gauges (Darto left, the fish
## right), the grease bar with its warning, the clock, and LEFT and RIGHT
## buttons across the bottom. The side to tap next is the orange button; the
## other stays pressable, because tapping it is the mistake to learn from.

const LOW_TIME_SEC := 8.0
const GREASE_WARNING := 0.5

var _player_gauge: ClimbGauge
var _fish_gauge: ClimbGauge
var _grease: ProgressBar
var _grease_label: Label
var _warning: Label
var _timer_chip: PanelContainer
var _timer_label: Label
var _timer_urgent: bool = false
var _left: GameButton
var _right: GameButton
var _expected: StringName = &"-"


func _build() -> void:
	_player_gauge = ClimbGauge.new()
	_player_gauge.name = "PlayerGauge"
	_player_gauge.fill = UiTokens.GRASS_500
	_safe_root.add_child(_player_gauge)
	_fish_gauge = ClimbGauge.new()
	_fish_gauge.name = "FishGauge"
	_fish_gauge.fill = UiTokens.TERRACOTTA_500
	_safe_root.add_child(_fish_gauge)
	_grease = ProgressBar.new()
	_grease.name = "Grease"
	_grease.show_percentage = false
	_grease.max_value = 1.0
	_grease.step = 0.0
	_grease.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudChip.style_bar(_grease, UiTokens.SUN_500)
	_safe_root.add_child(_grease)
	# The bar is named, so its job is clear before it ever fills.
	_grease_label = _outlined(UiTokens.FONT_SMALL)
	_grease_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_grease_label.text = TextDb.t(&"pinang.grease_label")
	_warning = _outlined(26, UiTokens.SUN_500)
	_warning.visible = false
	var chip := _make_timer_chip()
	_timer_chip = chip[0]
	_timer_label = chip[1]
	_left = _action_button("LeftButton", TextDb.t(&"pinang.button.left"), IconPainter.ARROW_LEFT, &"box_dodge_left", false)
	_right = _action_button("RightButton", TextDb.t(&"pinang.button.right"), IconPainter.ARROW_RIGHT, &"box_dodge_right", false)


func setup(fish: FishData) -> void:
	_player_gauge.caption = TextDb.t(&"boxing.hud.player")
	_fish_gauge.caption = fish.get_display_name().to_upper()


func refresh(snapshot: Dictionary) -> void:
	if not snapshot.has("height"):
		return
	_player_gauge.value = float(snapshot["height"])
	_fish_gauge.value = float(snapshot["fish_height"])
	var grease := float(snapshot["grease"])
	_grease.value = grease
	_warning.visible = grease >= GREASE_WARNING
	_warning.text = TextDb.t(&"pinang.grease")
	var running: bool = snapshot["state"] == PinangController.STATE_CLIMB
	_timer_label.text = TextDb.tf(&"boxing.hud.timer", {"seconds": ceili(float(snapshot["time_left"]))})
	var urgent := running and float(snapshot["time_left"]) <= LOW_TIME_SEC
	if urgent != _timer_urgent:
		_timer_urgent = urgent
		_timer_chip.add_theme_stylebox_override(&"panel", HudChip.timer_style(urgent))
	var stunned: bool = snapshot["stunned"]
	_left.disabled = not running or stunned
	_right.disabled = not running or stunned
	var expected: StringName = snapshot["expected_side"]
	if expected != _expected:
		_expected = expected
		_left.theme_type_variation = UiTokens.TYPE_CTA_BUTTON if expected == PinangController.LEFT else &""
		_right.theme_type_variation = UiTokens.TYPE_CTA_BUTTON if expected == PinangController.RIGHT else &""


func get_side_button(side: StringName) -> GameButton:
	return _left if side == PinangController.LEFT else _right


func _keys_text() -> String:
	return TextDb.tf(&"pinang.keys", {"left": _key(&"box_dodge_left"), "right": _key(&"box_dodge_right")})


func _button_height(area: Vector2) -> float:
	return clampf(roundf(area.y * 0.22), 130.0, 200.0)


func _keys_bottom(area: Vector2) -> float:
	return area.y - _button_height(area)


func _arrange(area: Vector2, top: float) -> void:
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	_place(_timer_chip, Rect2((area.x - 88.0) * 0.5, 0.0, 88.0, row))
	var height := _button_height(area)
	var gap := float(UiTokens.SPACE_16)
	var half := (area.x - gap) * 0.5
	_place(_left, Rect2(0.0, area.y - height, half, height))
	_place(_right, Rect2(half + gap, area.y - height, half, height))
	# The gauges stand at the screen edges, beside the poles.
	var gauge_top := top
	var gauge_height := maxf(area.y - height - 60.0 - gauge_top - 50.0, 160.0)
	_place(_player_gauge, Rect2(0.0, gauge_top, 64.0, gauge_height))
	_place(_fish_gauge, Rect2(area.x - 64.0, gauge_top, 64.0, gauge_height))
	var grease_width := minf(area.x * 0.5, 260.0)
	var grease_top := area.y - height - 40.0 - 22.0
	_place(_grease, Rect2((area.x - grease_width) * 0.5, grease_top, grease_width, 22.0))
	_place(_grease_label, Rect2(0.0, grease_top - 3.0, (area.x - grease_width) * 0.5 - UiTokens.SPACE_8, 28.0))
	_place(_warning, Rect2(0.0, grease_top - 44.0, area.x, 40.0))
