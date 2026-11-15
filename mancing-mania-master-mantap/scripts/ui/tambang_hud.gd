class_name TambangHud
extends SpotDuelHud
## Tug of War HUD (revision 6.7): the rope bar (Darto's end left, the fish's
## right, with the flag), the swinging marker over its green zone, the clock,
## the heave warning and one big PULL button across the bottom.

const LOW_TIME_SEC := 8.0

var _rope: PositionBar
var _meter: TimingMeter
var _timer_chip: PanelContainer
var _timer_label: Label
var _timer_urgent: bool = false
var _warning: Label
var _pull: GameButton


func _build() -> void:
	_rope = PositionBar.new()
	_rope.name = "RopeBar"
	_rope.range_max = 1.0
	_rope.grip_band = 0.0
	_safe_root.add_child(_rope)
	_meter = TimingMeter.new()
	_meter.name = "PullMeter"
	_safe_root.add_child(_meter)
	var chip := _make_timer_chip()
	_timer_chip = chip[0]
	_timer_label = chip[1]
	_warning = _outlined(30, UiTokens.SUN_500)
	_warning.visible = false
	_pull = _action_button("PullButton", TextDb.t(&"tambang.button"), &"", &"arm_mash")
	_pull.add_theme_font_size_override(&"font_size", 44)


func setup(fish: FishData) -> void:
	_rope.set_names(TextDb.t(&"boxing.hud.player"), fish.get_display_name().to_upper())


func refresh(snapshot: Dictionary) -> void:
	if not snapshot.has("rope"):
		return
	_rope.position_value = float(snapshot["rope"])
	_meter.value = float(snapshot["marker"])
	_meter.zone_centre = float(snapshot["zone_centre"])
	_meter.zone_half = float(snapshot["zone_half"])
	_meter.perfect_share = TambangController.PERFECT_SHARE
	_meter.dimmed = bool(snapshot["stunned"]) or bool(snapshot["zone_spent"])
	var running: bool = snapshot["state"] == TambangController.STATE_PULL
	_timer_label.text = TextDb.tf(&"boxing.hud.timer", {"seconds": ceili(float(snapshot["time_left"]))})
	var urgent := running and float(snapshot["time_left"]) <= LOW_TIME_SEC
	if urgent != _timer_urgent:
		_timer_urgent = urgent
		_timer_chip.add_theme_stylebox_override(&"panel", HudChip.timer_style(urgent))
	var warning: bool = snapshot["heave_warning"] or snapshot["heaving"]
	_warning.visible = warning
	_warning.text = TextDb.t(&"tambang.heave" if snapshot["heaving"] else &"tambang.heave_warning")
	_pull.disabled = not running


func get_pull_button() -> GameButton:
	return _pull


func get_meter() -> TimingMeter:
	return _meter


func is_warning_visible() -> bool:
	return _warning.visible


func _keys_text() -> String:
	return TextDb.tf(&"tambang.keys", {"key": _key(&"arm_mash")})


func _pull_height(area: Vector2) -> float:
	return clampf(roundf(area.y * 0.24), 140.0, 220.0)


func _keys_bottom(area: Vector2) -> float:
	return area.y - _pull_height(area)


func _arrange(area: Vector2, _top: float) -> void:
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	_place(_timer_chip, Rect2((area.x - 88.0) * 0.5, 0.0, 88.0, row))
	var pull_height := _pull_height(area)
	var pull_top := area.y - pull_height
	_place(_pull, Rect2(0.0, pull_top, area.x, pull_height))
	var bar_width := minf(area.x, 560.0)
	var bar_left := (area.x - bar_width) * 0.5
	var meter_top := pull_top - 40.0 - 56.0
	_place(_meter, Rect2(bar_left, meter_top, bar_width, 56.0))
	_place(_rope, Rect2(bar_left, meter_top - 70.0, bar_width, 60.0))
	_place(_warning, Rect2(0.0, meter_top - 120.0, area.x, 44.0))
