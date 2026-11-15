class_name GasingWorld
extends SpotDuelWorld
## The Spinning Tops ring (revision 6.7): a wide woven tray on the estuary
## mud with Darto and the fish on either side. The two wooden tops circle
## the tray; when a ring closes they swing in and collide, then bounce apart.
## A top spins as fast as its spin value says and wobbles as it runs down.

const ORBIT_RADIUS := 0.34
const CLASH_RADIUS := 0.07
const TOP_FLOOR := 0.06
const MAX_TURNS_PER_SEC := 7.0
const ORBIT_TURNS_PER_SEC := 0.18

var _centre: Vector3 = Vector3.ZERO
var _tops: Array[Node3D] = []
var _spins: Array[float] = [0.0, 0.0]
var _spin_max: float = 100.0
var _orbit: float = 0.0
var _closing: float = 1.0
var _in_play: bool = false
var _clock: float = 0.0


func _hud_insets() -> Vector2:
	return Vector2(160.0, 0.44)


func _darto_idle() -> StringName:
	return &"idle_fishing"


func _fish_idle() -> StringName:
	return &"dance_idle"


func _build() -> void:
	_centre = marker("ArenaCentre").position if has_marker("ArenaCentre") else (_darto_base.origin + _fish_base.origin) * 0.5
	for index: int in 2:
		var top := _make_top(UiTokens.GRASS_500 if index == 0 else UiTokens.TERRACOTTA_500)
		top.name = "Top%d" % index
		top.visible = false
		add_child(top)
		_tops.append(top)


func _process(delta: float) -> void:
	_clock += delta
	if not _in_play:
		return
	_orbit += TAU * ORBIT_TURNS_PER_SEC * delta
	var radius := lerpf(CLASH_RADIUS, ORBIT_RADIUS, _closing)
	for index: int in 2:
		var top := _tops[index]
		var angle := _orbit + PI * float(index)
		top.position = _centre + Vector3(cos(angle), 0.0, sin(angle)) * radius + Vector3.UP * TOP_FLOOR
		var share := clampf(_spins[index] / maxf(_spin_max, 1.0), 0.0, 1.0)
		var body := top.get_node("Body") as Node3D
		body.rotation.y += TAU * MAX_TURNS_PER_SEC * share * delta
		# Wobble grows as the spin runs down.
		var wobble := (1.0 - share) * 0.35 if share > 0.0 else 1.2
		top.rotation = Vector3(sin(_clock * 9.0 + float(index)) * wobble, 0.0, cos(_clock * 9.0 + float(index)) * wobble)


## Darto winds up while aiming.
func show_aim() -> void:
	play_darto(&"cast_prepare", 0.1)
	play_fish(&"fish_challenge", 0.1)


func show_throw(player_spin: float, fish_spin: float, spin_max: float) -> void:
	play_darto(&"cast_forward", 0.04)
	_darto_player.queue(&"lean_forward")
	_spin_max = spin_max
	_spins = [player_spin, fish_spin]
	_in_play = true
	_closing = 1.0
	for top: Node3D in _tops:
		top.visible = true
		DioramaMotion.squash(top, 0.2)


func set_spins(player_spin: float, fish_spin: float) -> void:
	_spins = [player_spin, fish_spin]


## `ring` is 1 when the ring appears and 0 at impact.
func set_ring(ring: float, active: bool) -> void:
	var target := clampf(ring, 0.0, 1.0) if active else 1.0
	_closing = lerpf(_closing, target, 0.35)


func show_clash(hit: StringName) -> void:
	_closing = 1.0
	for top: Node3D in _tops:
		DioramaMotion.squash(top, 0.25)
	match hit:
		GasingController.HIT_PERFECT, GasingController.HIT_GOOD:
			play_darto(&"small_laugh" if hit == GasingController.HIT_PERFECT else &"lean_forward", 0.05)
			play_fish(&"dance_miss", 0.05)
		_:
			play_darto(&"fish_escape_react", 0.05)
			play_fish(&"dance_win", 0.05)
	_darto_player.queue(&"lean_forward")
	if _fish_player != null:
		_fish_player.queue(_fish_idle())


func show_end(player_won: bool) -> void:
	super.show_end(player_won)
	# The loser's top topples.
	var loser := _tops[1] if player_won else _tops[0]
	_spins[1 if player_won else 0] = 0.0
	loser.rotation = Vector3(1.2, 0.0, 0.0)


func _make_top(stripe: Color) -> Node3D:
	var top := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	top.add_child(body)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.075
	cone.bottom_radius = 0.008
	cone.height = 0.09
	cone.radial_segments = 16
	var lower := part(cone, DioramaStyle.PINE, "Cone")
	lower.position = Vector3(0.0, 0.045, 0.0)
	body.add_child(lower)
	var band := CylinderMesh.new()
	band.top_radius = 0.078
	band.bottom_radius = 0.078
	band.height = 0.025
	band.radial_segments = 16
	var ring := part(band, stripe, "Band")
	ring.position = Vector3(0.0, 0.1, 0.0)
	body.add_child(ring)
	var cap := SphereMesh.new()
	cap.radius = 0.05
	cap.height = 0.05
	cap.is_hemisphere = true
	var crown := part(cap, DioramaStyle.CARAMEL, "Cap")
	crown.position = Vector3(0.0, 0.112, 0.0)
	body.add_child(crown)
	var mark := BoxMesh.new()
	mark.size = Vector3(0.1, 0.012, 0.018)
	var notch := part(mark, DioramaStyle.FLOUR, "Mark")
	notch.position = Vector3(0.0, 0.114, 0.0)
	body.add_child(notch)
	return top
