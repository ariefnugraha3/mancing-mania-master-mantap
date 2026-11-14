class_name ReelHud
extends Control
## The tension minigame read-out (GDD 31-36, 168.4, 189.5).
##
## A vertical track with the moving green zone and the player's marker, a line
## stress gauge beside it and the landing progress underneath. Every piece of
## information has two channels: the zone is a bordered band as well as green,
## and stress is a gauge level, a pulse and a text warning.
##
## Stress shakes this HUD, never the camera. The shake follows the HUD SHAKE
## setting: ON, REDUCED (40%) or OFF.

const TRACK_WIDTH := 56.0
const GAUGE_WIDTH := 14.0
const GAP := 10.0
const LANDING_HEIGHT := 22.0
## Shake amplitude in pixels for stress bands 0-3.
const SHAKE_PIXELS: Array[float] = [0.0, 1.6, 3.4, 6.0]
const REDUCED_SHAKE_FACTOR := 0.4

@onready var _track: Panel = $TensionBar
@onready var _zone: Panel = $GreenZone
@onready var _marker: Control = $PlayerMarker
@onready var _landing: ProgressBar = $LandingProgress
@onready var _warning: Label = $StressWarning

var _stress_gauge: ProgressBar
var _landing_label: Label
var _track_height: float = 320.0
var _marker_value: float = 0.4
var _held: bool = false
var _home: Vector2 = Vector2.ZERO
var _clock: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := UiSkin.well(Color(UiTokens.CREAM_100, 0.94), 18, 0.0)
	track.set_border_width_all(UiTokens.hud_border(3))
	track.border_width_top = UiTokens.hud_border(5)
	track.border_color = UiTokens.EDGE_PAPER
	track.shadow_color = UiTokens.SHADOW
	track.shadow_size = 8
	track.shadow_offset = Vector2(0.0, 3.0)
	_track.add_theme_stylebox_override(&"panel", track)
	var zone := UiSkin.bar_fill(Color(UiTokens.GRASS_500, 0.96))
	zone.set_border_width_all(UiTokens.hud_border(2))
	zone.border_width_bottom = UiTokens.hud_border(4)
	zone.set_corner_radius_all(10)
	_zone.add_theme_stylebox_override(&"panel", zone)
	for node: Control in [_track, _zone, _marker]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marker.draw.connect(_draw_marker)

	_stress_gauge = ProgressBar.new()
	_stress_gauge.name = "StressGauge"
	_stress_gauge.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	_stress_gauge.show_percentage = false
	_stress_gauge.max_value = 1.0
	HudChip.style_bar(_stress_gauge, UiTokens.RED_500, 8)
	_stress_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stress_gauge)

	_landing.max_value = 1.0
	_landing.show_percentage = false
	_landing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_landing_label = Label.new()
	_landing_label.name = "LandingLabel"
	_landing_label.text = TextDb.t(&"fishing.hud.landing")
	_landing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_outlined(_landing_label, UiTokens.FONT_SMALL)
	add_child(_landing_label)

	_warning.text = TextDb.t(&"fishing.prompt.stress")
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_outlined(_warning, UiTokens.FONT_BODY)
	_warning.add_theme_color_override(&"font_color", Color("ffd9c9"))
	_warning.visible = false
	set_track_height(_track_height)
	visible = false


## Lays the pieces out for a track of the given height.
func set_track_height(height: float) -> void:
	_track_height = height
	var track_x := GAUGE_WIDTH + GAP
	var width := track_x + TRACK_WIDTH
	custom_minimum_size = Vector2(width + 40.0, height + 92.0)
	_warning.position = Vector2(-60.0, 0.0)
	_warning.size = Vector2(width + 120.0, 28.0)
	var top := 34.0
	_stress_gauge.position = Vector2(0.0, top)
	_stress_gauge.size = Vector2(GAUGE_WIDTH, height)
	_track.position = Vector2(track_x, top)
	_track.size = Vector2(TRACK_WIDTH, height)
	_landing_label.position = Vector2(-40.0, top + height + 6.0)
	_landing_label.size = Vector2(width + 80.0, 24.0)
	_landing.position = Vector2(-20.0, top + height + 32.0)
	_landing.size = Vector2(width + 40.0, LANDING_HEIGHT)
	_marker.size = Vector2(TRACK_WIDTH + 28.0, 22.0)


## Remembers the resting position that the stress shake moves around.
func set_home(home: Vector2) -> void:
	_home = home
	position = home


func show_reel() -> void:
	visible = true
	_warning.visible = false


func hide_reel() -> void:
	visible = false
	position = _home


func update_reel(reel: ReelSimulation, held: bool, delta: float) -> void:
	_clock += delta
	_held = held
	_marker_value = reel.marker
	var track_x := _track.position.x
	var top := _track.position.y

	var zone_height := maxf(reel.zone_half_width * 2.0 * _track_height, 8.0)
	_zone.position = Vector2(track_x + 4.0, top + (1.0 - reel.zone_center - reel.zone_half_width) * _track_height)
	_zone.size = Vector2(TRACK_WIDTH - 8.0, zone_height)
	_marker.position = Vector2(track_x - 14.0, top + (1.0 - reel.marker) * _track_height - _marker.size.y * 0.5)
	_marker.queue_redraw()

	_landing.value = reel.get_landing_ratio()
	_stress_gauge.value = reel.get_stress_ratio()

	var band := reel.get_stress_band()
	_warning.visible = band >= 2
	if _warning.visible:
		_warning.modulate.a = 0.65 + 0.35 * sin(_clock * 14.0)
	_apply_shake(band)


func _apply_shake(band: int) -> void:
	var amplitude := SHAKE_PIXELS[clampi(band, 0, 3)]
	match str(GameState.get_setting(&"hud_shake")):
		"off":
			amplitude = 0.0
		"reduced":
			amplitude *= REDUCED_SHAKE_FACTOR
	var offset := Vector2(sin(_clock * 61.0), cos(_clock * 47.0)) * amplitude
	position = _home + offset


## A bar across the track with arrowheads on both sides: readable by position
## and shape, whatever the colours look like to the player.
func _draw_marker() -> void:
	var size := _marker.size
	var middle := size.y * 0.5
	var fill := UiTokens.SUN_500 if _held else UiTokens.CREAM_50
	var bar := Rect2(12.0, middle - 5.0, size.x - 24.0, 10.0)
	_marker.draw_style_box(UiSkin.rounded(fill, 7, UiTokens.hud_border(3)), bar.grow(float(UiTokens.hud_border(2))))
	for side: float in [0.0, 1.0]:
		var tip_x := lerpf(12.0, size.x - 12.0, side)
		var back_x := lerpf(0.0, size.x, side)
		var arrow := PackedVector2Array([Vector2(tip_x, middle), Vector2(back_x, middle - 9.0), Vector2(back_x, middle + 9.0)])
		_marker.draw_colored_polygon(arrow, UiTokens.INK_900)


func _style_outlined(label: Label, font_size: int) -> void:
	UiTokens.outline_text(label, font_size, UiTokens.CREAM_50, 7)
