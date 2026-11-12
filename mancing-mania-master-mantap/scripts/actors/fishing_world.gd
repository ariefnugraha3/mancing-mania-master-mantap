class_name FishingWorld
extends Node3D
## Everything you see at the lake: Darto, his rod and line, the float, the fish
## shadow, splashes and the catch reveal (GDD 24-27, 37, 168.4).
##
## The world only shows what FishingController decided. It has no rules of its
## own, so nothing here can change an outcome. The camera is fixed and never
## shakes; line stress is expressed by the rod and the HUD (GDD 36, 173.1).

const HAND_BONE := "hand_r"
## The rod sits in the right hand, angled so the fishing stance points it out
## over the water instead of straight up.
const ROD_GRIP := Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(-60.0)), Vector3(0.0, -0.05, -0.02))
const FLOAT_FLIGHT_SEC := 0.57
const FLOAT_ARC_HEIGHT := 1.5
const LINE_POINTS := 10
const CAMERA_FOV_LANDSCAPE := 50.0
const CAMERA_FOV_PORTRAIT := 62.0
const RIPPLE_COUNT := 4
const RIPPLE_SEC := 1.3
## Where a hooked fish is dragged to by the end of the reel, relative to the bank.
const PULL_SPOT := Vector3(0.3, 0.0, 0.7)
const BANK_OFFSET := Vector3(1.45, 0.16, -0.5)

enum FloatMode { HIDDEN, FLYING, FLOATING, SUNK, REELING }

@onready var _lake_set: Node3D = $LakeSet
@onready var _darto: Node3D = $Darto
@onready var _rig: Node3D = $Darto/Rig
@onready var _rod_socket: Marker3D = $Darto/RodSocket
@onready var _rod: Node3D = $Darto/Rod
@onready var _rod_tip: Marker3D = $Darto/Rod/RodTip
@onready var _animation: AnimationPlayer = $Darto/AnimationPlayer
@onready var _float_root: Node3D = $FloatRoot
@onready var _bite_marker: Label3D = $FloatRoot/BiteMarker
@onready var _shadow_root: Node3D = $FishShadowRoot
@onready var _camera: Camera3D = $FishingCamera
@onready var _effects: Node3D = $FishingEffects
@onready var _bucket: Node3D = $Bucket

var _skeleton: Skeleton3D
var _hand_bone: int = -1
var _float_spot: Vector3
var _darto_spot: Vector3
var _float_mode: FloatMode = FloatMode.HIDDEN
var _float_time: float = 0.0
var _flight_start: Vector3
var _float_dip: float = 0.0
var _reel_ratio: float = 0.0
var _reel_stress: float = 0.0
var _clock: float = 0.0

var _line: MeshInstance3D
var _line_mesh: ImmediateMesh
var _ripples: Array[MeshInstance3D] = []
var _ripple_ages: Array[float] = []
var _next_ripple: int = 0
var _splash_small: CPUParticles3D
var _splash_large: CPUParticles3D
var _shadow_target: Vector3
var _shadow_visible: bool = false
var _catch: Node3D
var _catch_tween: Tween
var _reel_was_held: bool = false


func _ready() -> void:
	var markers := _lake_set.get_node("Markers")
	_darto_spot = (markers.get_node("DartoSpot") as Node3D).position
	_float_spot = (markers.get_node("FloatSpot") as Node3D).position
	_darto.position = _darto_spot
	_bucket.transform = (markers.get_node("BucketSpot") as Node3D).transform

	_skeleton = _rig.get_node("Skeleton3D")
	_hand_bone = _skeleton.find_bone(HAND_BONE)
	var rig_player := _rig.get_node("AnimationPlayer") as AnimationPlayer
	_animation.root_node = NodePath("../Rig")
	_animation.add_animation_library(&"", rig_player.get_animation_library(&""))
	_animation.play(&"idle_fishing")

	_build_line()
	_build_ripples()
	_build_shadow()
	_splash_small = _build_splash(26, 2.2)
	_splash_large = _build_splash(64, 4.2)
	_bite_marker.visible = false
	_float_root.visible = false
	_float_root.position = _float_spot

	PlatformService.viewport_class_changed.connect(_frame_camera)
	_frame_camera(PlatformService.get_viewport_class())


func _process(delta: float) -> void:
	_clock += delta
	_update_rod()
	_update_float(delta)
	_update_line()
	_update_ripples(delta)
	_update_shadow(delta)
	if _bite_marker.visible:
		_bite_marker.scale = Vector3.ONE * (1.0 + 0.12 * sin(_clock * 18.0))


# --- Called by the fishing scene --------------------------------------------

func show_idle() -> void:
	_set_float_mode(FloatMode.HIDDEN)
	_shadow_visible = false
	_bite_marker.visible = false
	var current := _animation.current_animation
	if not _animation.is_playing() or current == &"reel_hold" or current == &"reel_release_relax":
		_animation.play(&"idle_fishing", 0.25)


func show_cast() -> void:
	_clear_catch()
	_animation.play(&"cast_prepare", 0.06)
	_animation.queue(&"cast_forward")
	_animation.queue(&"cast_settle")
	_animation.queue(&"idle_fishing")


func release_float() -> void:
	_flight_start = _rod_tip.global_position
	_float_dip = 0.0
	_set_float_mode(FloatMode.FLYING)


func land_float() -> void:
	_set_float_mode(FloatMode.FLOATING)
	_spawn_ripple(_float_spot)
	_burst(_splash_small, _float_spot)


func show_nibble() -> void:
	_float_dip = -0.035
	_spawn_ripple(_float_spot)


## The shadow drifts in from the side and starts circling the float.
func show_bite_warning() -> void:
	var side := -1.0 if RNGService.cosmetic.randf() < 0.5 else 1.0
	_shadow_root.position = _float_spot + Vector3(2.4 * side, 0.012, -1.6)
	_shadow_target = _float_spot + Vector3(0.25 * side, 0.012, -0.2)
	_shadow_visible = true


func show_bite() -> void:
	_set_float_mode(FloatMode.SUNK)
	_bite_marker.visible = true
	_spawn_ripple(_float_spot)
	_burst(_splash_small, _float_spot)


## Nothing was there: the float hops and settles back, the shadow backs off.
func show_false_strike() -> void:
	_animation.play(&"empty_pull", 0.05)
	_animation.queue(&"idle_fishing")
	_float_dip = 0.06
	_spawn_ripple(_float_spot)
	if _shadow_visible:
		_shadow_target = _shadow_root.position + Vector3(0.0, 0.0, -2.2)
		_shadow_visible = false


func show_strike(is_trash: bool) -> void:
	_bite_marker.visible = false
	_spawn_ripple(_float_spot)
	if is_trash:
		_shadow_visible = false
		return
	_reel_ratio = 0.0
	_reel_stress = 0.0
	_reel_was_held = false
	_set_float_mode(FloatMode.REELING)
	_animation.play(&"reel_hold", 0.1)


## Called every frame while reeling.
func update_reel(reel: ReelSimulation, held: bool) -> void:
	_reel_ratio = reel.get_landing_ratio()
	_reel_stress = reel.get_stress_ratio()
	_shadow_target = _reel_position() + Vector3(0.0, 0.012, -0.25)
	if held != _reel_was_held:
		_reel_was_held = held
		_animation.play(&"reel_hold" if held else &"reel_release_relax", 0.12)
	elif held and reel.get_stress_band() >= 2 and _animation.current_animation == &"reel_hold" and fmod(_clock, 0.9) < 0.02:
		_animation.play(&"line_stress_jerk", 0.05)
		_animation.queue(&"reel_hold")


func show_fish_landed(fish_id: StringName) -> void:
	var origin := _reel_position()
	_set_float_mode(FloatMode.HIDDEN)
	_shadow_visible = false
	_burst(_splash_large, origin)
	_spawn_ripple(origin)
	_animation.play(&"land_fish", 0.08)
	_animation.queue(&"idle_fishing")

	var fish := GameData.get_fish(fish_id)
	if fish == null or fish.model_scene == null:
		return
	_clear_catch()
	_catch = fish.model_scene.instantiate()
	_effects.add_child(_catch)
	_catch.global_position = origin
	# Fish are modelled facing +X; turn it to face Darto once it is on the bank.
	_catch.rotation.y = PI
	var gloves := _catch.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = false
	var player := _catch.get_node("AnimationPlayer") as AnimationPlayer
	player.play(&"fish_hooked_pull")

	var bank := _darto_spot + BANK_OFFSET
	_catch_tween = create_tween()
	_catch_tween.tween_method(_arc_catch.bind(origin, bank, 1.9), 0.0, 1.0, 0.7).set_ease(Tween.EASE_OUT)
	_catch_tween.tween_callback(player.play.bind(&"fish_land_flop"))
	_catch_tween.tween_interval(0.75)
	# The fish gets up, and gloves it had no business owning are simply there.
	_catch_tween.tween_callback(_start_challenge.bind(player, gloves))


func show_trash_landed(item_id: StringName) -> void:
	var origin := _float_spot
	_set_float_mode(FloatMode.HIDDEN)
	_burst(_splash_small, origin)
	_spawn_ripple(origin)
	_animation.play(&"land_fish", 0.08)
	_animation.queue(&"idle_fishing")

	var trash := GameData.get_trash(item_id)
	if trash == null or trash.model_scene == null:
		return
	_clear_catch()
	_catch = trash.model_scene.instantiate()
	_effects.add_child(_catch)
	_catch.global_position = origin
	var bank := _darto_spot + BANK_OFFSET + Vector3(0.0, -0.1, 0.0)
	_catch_tween = create_tween()
	_catch_tween.tween_method(_arc_catch.bind(origin, bank, 2.1), 0.0, 1.0, 0.8).set_ease(Tween.EASE_OUT)


## The catch goes into the bucket and Darto bends to see it in.
func show_catch_to_bucket() -> void:
	_animation.play(&"bucket_add", 0.1)
	_animation.queue(&"idle_fishing")
	if _catch == null:
		return
	if _catch_tween != null and _catch_tween.is_valid():
		_catch_tween.kill()
	var player := _catch.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(&"fish_bucket_defeat"):
		player.play(&"fish_bucket_defeat", 0.1)
	var from := _catch.global_position
	var into := _bucket.global_position + Vector3(0.0, 0.2, 0.0)
	var leaving := _catch
	_catch = null
	_catch_tween = create_tween()
	_catch_tween.tween_method(_arc_node.bind(leaving, from, into, 0.7), 0.0, 1.0, 0.45)
	_catch_tween.parallel().tween_property(leaving, "scale", Vector3.ONE * 0.35, 0.45)
	_catch_tween.tween_callback(leaving.queue_free)


func show_escape(_reason: StringName) -> void:
	var where := _float_root.global_position
	_set_float_mode(FloatMode.HIDDEN)
	_bite_marker.visible = false
	_shadow_target = where + Vector3(0.0, 0.012, -4.0)
	_shadow_visible = false
	_spawn_ripple(where)
	_burst(_splash_small, where)
	_animation.play(&"fish_escape_react", 0.1)
	_animation.queue(&"idle_fishing")


func get_camera() -> Camera3D:
	return _camera


# --- Rod, float and line ----------------------------------------------------

func _update_rod() -> void:
	if _hand_bone < 0:
		return
	var hand := _skeleton.global_transform * _skeleton.get_bone_global_pose(_hand_bone)
	_rod_socket.global_transform = hand
	_rod.global_transform = hand * ROD_GRIP


func _set_float_mode(mode: FloatMode) -> void:
	_float_mode = mode
	_float_time = 0.0
	_float_root.visible = mode != FloatMode.HIDDEN


func _update_float(delta: float) -> void:
	_float_time += delta
	_float_dip = move_toward(_float_dip, 0.0, delta * 0.35)
	match _float_mode:
		FloatMode.FLYING:
			var progress := clampf(_float_time / FLOAT_FLIGHT_SEC, 0.0, 1.0)
			var point := _flight_start.lerp(_float_spot, progress)
			point.y += sin(progress * PI) * FLOAT_ARC_HEIGHT
			_float_root.global_position = point
		FloatMode.FLOATING:
			_float_root.global_position = _float_spot + Vector3(0.0, sin(_clock * 1.7) * 0.012 + _float_dip, 0.0)
		FloatMode.SUNK:
			_float_root.global_position = _float_spot + Vector3(sin(_clock * 31.0) * 0.012, -0.1, 0.0)
		FloatMode.REELING:
			var tremble := _reel_stress * 0.035
			_float_root.global_position = _reel_position() + Vector3(
				sin(_clock * 23.0) * tremble, -0.06 + sin(_clock * 9.0) * 0.02, cos(_clock * 19.0) * tremble)


## Where the hooked fish is right now: it comes in as landing progress grows.
func _reel_position() -> Vector3:
	var near := Vector3(_darto_spot.x + PULL_SPOT.x, 0.0, PULL_SPOT.z)
	return _float_spot.lerp(near, _reel_ratio)


func _build_line() -> void:
	_line_mesh = ImmediateMesh.new()
	_line = MeshInstance3D.new()
	_line.name = "Line"
	_line.mesh = _line_mesh
	_line.material_override = load("res://generated/materials/mat_fishing_line.tres")
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_effects.add_child(_line)


func _update_line() -> void:
	_line_mesh.clear_surfaces()
	if _float_mode == FloatMode.HIDDEN:
		return
	var from := _rod_tip.global_position
	var to := _float_root.global_position + Vector3(0.0, 0.07, 0.0)
	# A waiting line hangs slack; a fighting one is pulled straight.
	var sag := 0.05 if _float_mode == FloatMode.REELING or _float_mode == FloatMode.FLYING else 0.32
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for index: int in LINE_POINTS + 1:
		var along := float(index) / float(LINE_POINTS)
		var point := from.lerp(to, along)
		point.y -= sin(along * PI) * sag
		_line_mesh.surface_add_vertex(_line.to_local(point))
	_line_mesh.surface_end()


# --- Water effects ----------------------------------------------------------

func _build_ripples() -> void:
	var ring := TorusMesh.new()
	ring.inner_radius = 0.43
	ring.outer_radius = 0.5
	ring.rings = 20
	ring.ring_segments = 3
	var base: StandardMaterial3D = load("res://generated/materials/mat_water_ripple.tres")
	for index: int in RIPPLE_COUNT:
		var ripple := MeshInstance3D.new()
		ripple.name = "Ripple%d" % index
		ripple.mesh = ring
		ripple.material_override = base.duplicate()
		ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ripple.visible = false
		# Parented to the effects node: ripples outlive the float being hidden.
		_effects.add_child(ripple)
		_ripples.append(ripple)
		_ripple_ages.append(RIPPLE_SEC)


func _spawn_ripple(at: Vector3) -> void:
	var ripple := _ripples[_next_ripple]
	_ripple_ages[_next_ripple] = 0.0
	_next_ripple = (_next_ripple + 1) % RIPPLE_COUNT
	ripple.global_position = Vector3(at.x, 0.03, at.z)
	ripple.visible = true


func _update_ripples(delta: float) -> void:
	for index: int in RIPPLE_COUNT:
		if not _ripples[index].visible:
			continue
		_ripple_ages[index] += delta
		var progress := _ripple_ages[index] / RIPPLE_SEC
		if progress >= 1.0:
			_ripples[index].visible = false
			continue
		var spread := lerpf(0.25, 1.9, ease(progress, 0.5))
		_ripples[index].scale = Vector3(spread, 0.04, spread)
		var material := _ripples[index].material_override as StandardMaterial3D
		material.albedo_color.a = 0.65 * (1.0 - progress)


func _build_splash(amount: int, speed: float) -> CPUParticles3D:
	var drop := SphereMesh.new()
	drop.radius = 0.022
	drop.height = 0.044
	drop.radial_segments = 4
	drop.rings = 2
	var particles := CPUParticles3D.new()
	particles.mesh = drop
	particles.material_override = load("res://generated/materials/mat_water_ripple.tres")
	particles.amount = amount
	particles.one_shot = true
	particles.emitting = false
	particles.explosiveness = 0.92
	particles.lifetime = 0.75
	particles.direction = Vector3.UP
	particles.spread = 38.0
	particles.initial_velocity_min = speed * 0.55
	particles.initial_velocity_max = speed
	particles.gravity = Vector3(0.0, -9.8, 0.0)
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.5
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_effects.add_child(particles)
	return particles


func _burst(particles: CPUParticles3D, at: Vector3) -> void:
	particles.global_position = Vector3(at.x, 0.03, at.z)
	particles.restart()
	particles.emitting = true


# --- Fish shadow ------------------------------------------------------------

func _build_shadow() -> void:
	var material: Material = load("res://generated/materials/mat_water_shadow.tres")
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.004
	disc.radial_segments = 14
	disc.rings = 1
	for part: Array in [[Vector3(0.0, 0.0, 0.0), Vector3(0.95, 1.0, 0.36)], [Vector3(-0.58, 0.0, 0.0), Vector3(0.42, 1.0, 0.26)]]:
		var piece := MeshInstance3D.new()
		piece.mesh = disc
		piece.material_override = material
		piece.position = part[0]
		piece.scale = part[1]
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_shadow_root.add_child(piece)
	_shadow_root.visible = false
	_shadow_target = _float_spot


func _update_shadow(delta: float) -> void:
	var here := _shadow_root.position
	var to_target := _shadow_target - here
	if _shadow_visible:
		_shadow_root.visible = true
		# Circle the target instead of parking on it.
		var orbit := Vector3(cos(_clock * 1.4), 0.0, sin(_clock * 1.4)) * 0.35
		to_target += orbit
	elif to_target.length() < 0.2:
		_shadow_root.visible = false
		return
	var travel := minf(to_target.length(), 2.6 * delta)
	if to_target.length() > 0.001:
		_shadow_root.position = here + to_target.normalized() * travel
		_shadow_root.rotation.y = lerp_angle(_shadow_root.rotation.y, atan2(-to_target.z, to_target.x), 6.0 * delta)


# --- Catch reveal -----------------------------------------------------------

func _start_challenge(player: AnimationPlayer, gloves: Node3D) -> void:
	if not is_instance_valid(player):
		return
	if gloves != null:
		gloves.visible = true
	player.play(&"fish_challenge", 0.1)


func _arc_catch(progress: float, from: Vector3, to: Vector3, height: float) -> void:
	_arc_node(progress, _catch, from, to, height)


func _arc_node(progress: float, node: Node3D, from: Vector3, to: Vector3, height: float) -> void:
	if not is_instance_valid(node):
		return
	var point := from.lerp(to, progress)
	point.y += sin(progress * PI) * height
	node.global_position = point


func _clear_catch() -> void:
	if _catch_tween != null and _catch_tween.is_valid():
		_catch_tween.kill()
	if is_instance_valid(_catch):
		_catch.queue_free()
	_catch = null


# --- Camera -----------------------------------------------------------------

## The camera is fixed per layout; it only moves when the layout changes.
func _frame_camera(viewport_class: StringName) -> void:
	var portrait := viewport_class == PlatformService.PORTRAIT
	var marker := _lake_set.get_node("Markers/CameraPortrait" if portrait else "Markers/CameraLandscape") as Node3D
	_camera.global_transform = marker.global_transform
	_camera.fov = CAMERA_FOV_PORTRAIT if portrait else CAMERA_FOV_LANDSCAPE
