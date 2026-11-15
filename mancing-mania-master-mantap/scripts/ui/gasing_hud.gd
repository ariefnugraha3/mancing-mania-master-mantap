class_name GasingHud
extends SpotDuelHud
## Spinning Tops HUD (revision 6.7): both tops' spin bars, the aim needle and
## the power bar while throwing, the closing ring during the clashes, and one
## big button (THROW, then HIT) across the bottom.

var _player_bar: ProgressBar
var _fish_bar: ProgressBar
var _player_label: Label
var _fish_label: Label
var _aim: TimingMeter
var _power: TimingMeter
var _ring: ClashRing
var _button: GameButton


func _build() -> void:
	_player_label = _outlined(UiTokens.FONT_SMALL)
	_player_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_fish_label = _outlined(UiTokens.FONT_SMALL)
	_fish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_player_bar = _spin_bar("PlayerSpin", UiTokens.GRASS_500)
	_fish_bar = _spin_bar("FishSpin", UiTokens.TERRACOTTA_500)
	_fish_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN
	_aim = TimingMeter.new()
	_aim.name = "AimMeter"
	_aim.zone_centre = 0.5
	_aim.zone_half = 0.12
	_safe_root.add_child(_aim)
	_power = TimingMeter.new()
	_power.name = "PowerMeter"
	_power.zone_centre = 0.92
	_power.zone_half = 0.08
	_power.perfect_share = 0.0
	_safe_root.add_child(_power)
	_ring = ClashRing.new()
	_ring.name = "ClashRing"
	_safe_root.add_child(_ring)
	_button = _action_button("TapButton", TextDb.t(&"gasing.button.throw"), &"", &"arm_mash")
	_button.add_theme_font_size_override(&"font_size", 44)


func setup(fish: FishData) -> void:
	_fish_label.text = fish.get_display_name().to_upper()
	_aim.caption = TextDb.t(&"gasing.aim")
	_power.caption = TextDb.t(&"gasing.power")


func refresh(snapshot: Dictionary) -> void:
	if not snapshot.has("aim"):
		return
	var state: StringName = snapshot["state"]
	var throwing := state == GasingController.STATE_AIM or state == GasingController.STATE_POWER
	_aim.visible = throwing
	_power.visible = state == GasingController.STATE_POWER
	_aim.value = (float(snapshot["aim"]) + 1.0) * 0.5
	_aim.dimmed = state != GasingController.STATE_AIM
	_power.value = float(snapshot["power"])
	var spinning := state == GasingController.STATE_SPIN or state == GasingController.STATE_LAUNCH or state == &"finished"
	for bar: ProgressBar in [_player_bar, _fish_bar]:
		bar.visible = spinning
		bar.max_value = float(snapshot["spin_max"])
	_player_label.visible = spinning
	_fish_label.visible = spinning
	_player_bar.value = float(snapshot["player_spin"])
	_fish_bar.value = float(snapshot["fish_spin"])
	_player_label.text = "%s  %s" % [TextDb.t(&"boxing.hud.player"), TextDb.tf(&"gasing.spin", {"value": roundi(float(snapshot["player_spin"]))})]
	_ring.visible = bool(snapshot["ring_active"])
	_ring.progress = float(snapshot["ring"])
	_button.text = TextDb.t(&"gasing.button.hit" if spinning else &"gasing.button.throw")
	_button.disabled = not (throwing or state == GasingController.STATE_SPIN)


func get_tap_button() -> GameButton:
	return _button


func get_ring() -> ClashRing:
	return _ring


func _spin_bar(node_name: String, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = node_name
	bar.show_percentage = false
	bar.step = 0.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudChip.style_bar(bar, fill)
	bar.visible = false
	_safe_root.add_child(bar)
	return bar


func _keys_text() -> String:
	return TextDb.tf(&"gasing.keys", {"key": _key(&"arm_mash")})


func _button_height(area: Vector2) -> float:
	return clampf(roundf(area.y * 0.22), 130.0, 200.0)


func _keys_bottom(area: Vector2) -> float:
	return area.y - _button_height(area)


func _arrange(area: Vector2, top: float) -> void:
	var height := _button_height(area)
	var button_top := area.y - height
	_place(_button, Rect2(0.0, button_top, area.x, height))
	# Spin bars along the top, Darto's on the left, the fish's on the right.
	var half := (minf(area.x, 600.0) - UiTokens.SPACE_16) * 0.5
	var left := (area.x - (half * 2.0 + UiTokens.SPACE_16)) * 0.5
	_place(_player_label, Rect2(left, top, half, 24.0))
	_place(_fish_label, Rect2(left + half + UiTokens.SPACE_16, top, half, 24.0))
	_place(_player_bar, Rect2(left, top + 26.0, half, 22.0))
	_place(_fish_bar, Rect2(left + half + UiTokens.SPACE_16, top + 26.0, half, 22.0))
	var width := minf(area.x - UiTokens.SPACE_16 * 2.0, 480.0)
	var meter_left := (area.x - width) * 0.5
	_place(_power, Rect2(meter_left, button_top - 40.0 - 52.0, width, 52.0))
	_place(_aim, Rect2(meter_left, button_top - 40.0 - 52.0 - 84.0, width, 52.0))
	var ring_size := minf(220.0, area.x * 0.55)
	_place(_ring, Rect2((area.x - ring_size) * 0.5, button_top - 40.0 - ring_size, ring_size, ring_size))
