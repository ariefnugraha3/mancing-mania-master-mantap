class_name FishingEventStage
extends Node3D
## Plays the small happenings at the fishing spot in the world (revision 6.12):
## what FishingEvents picked and FishingEventDirector asked for. Each one is an
## actor with a lifetime and a motion that follows its clock; when the clock
## runs out its nodes are freed. Nothing here touches the fishing itself.
##
## Places are measured from Darto along the screen: `in` away from the camera
## (over the water) and `across` to the right of the screen. The water in
## front of Darto runs from about 1.4 m to 5 m in, at every spot.

signal actor_finished(event_id: StringName)

const PROPS := "res://generated/scenes/props/%s.tscn"
## The water band events may use, and how far they keep from the float.
const WATER_IN := Vector2(1.4, 5.0)
const WATER_ACROSS := Vector2(-2.6, 2.8)
const FLOAT_CLEARANCE := 1.0
## The meadow behind Darto, where the neighbour rides and the children play.
const MEADOW_IN := -3.3
const RAIN_DROPS := 220
## The fishing camera is far off (Darto is about 25 points tall on a phone),
## so the small things are drawn larger than life, as the chibi world does.
const SCALE_FISH := 1.1
const SCALE_KINGFISHER := 2.4
const SCALE_GULL := 1.9
const SCALE_FROG := 1.9
const SCALE_DRAGONFLY := 2.4
const SCALE_SANDAL := 3.6
const SCALE_BOTTLE := 1.8
const SCALE_KITE := 1.6
const SCALE_CHILD := 1.25
const SCALE_DUCK := 2.2
const SCALE_CAT := 2.0
const RAIN_RIPPLES := 10

var _world: FishingWorld
var _darto: Vector3
var _float_spot: Vector3
var _random := RandomNumberGenerator.new()
var _actors: Array[Dictionary] = []
var _rain: CPUParticles3D
var _ripples: Array[MeshInstance3D] = []
var _ripple_ages: Array[float] = []
var _next_ripple: int = 0


func setup(world: FishingWorld, darto_spot: Vector3, float_spot: Vector3) -> void:
	_world = world
	_darto = darto_spot
	_float_spot = float_spot
	_random.seed = RNGService.cosmetic.randi()
	_build_rain()


func _process(delta: float) -> void:
	for actor: Dictionary in _actors.duplicate():
		actor["t"] = float(actor["t"]) + delta
		(actor["update"] as Callable).call(actor, delta)
		if float(actor["t"]) >= float(actor["duration"]):
			_end(actor)
	_update_ripples(delta)


## True while any happening still has something on screen.
func is_busy() -> bool:
	return not _actors.is_empty()


## A bite or a strike takes the stage: whatever sits on the float or waits to
## be tapped leaves now. The rest carries on in the background.
func interrupt() -> void:
	for actor: Dictionary in _actors:
		actor["leaving"] = true


## Ends every happening at once (the scene is leaving).
func clear() -> void:
	for actor: Dictionary in _actors.duplicate():
		_end(actor)


# --- Places ------------------------------------------------------------------

func place(across: float, depth: float, height: float = 0.0) -> Vector3:
	return _darto + DioramaStyle.screen_right() * across + DioramaStyle.screen_in() * depth + Vector3(0.0, height, 0.0) \
		+ Vector3(0.0, _float_spot.y - _darto.y, 0.0)


## A spot on the ground at Darto's height: the bank and the meadow.
func ground_point(across: float, depth: float) -> Vector3:
	return _darto + DioramaStyle.screen_right() * across + DioramaStyle.screen_in() * depth


## A spot on the open water in front of Darto, clear of the float.
func water_point() -> Vector3:
	for attempt: int in 12:
		var point := place(_random.randf_range(WATER_ACROSS.x, WATER_ACROSS.y), _random.randf_range(WATER_IN.x, WATER_IN.y))
		if Vector2(point.x, point.z).distance_to(Vector2(_float_spot.x, _float_spot.z)) >= FLOAT_CLEARANCE:
			return point
	return place(-2.0, 4.0)


static func face_along(node: Node3D, direction: Vector3) -> void:
	# The props look along +X.
	node.rotation.y = atan2(-direction.z, direction.x)


# --- Happenings --------------------------------------------------------------

## A fish of this spot leaps out of the water and dives back in.
func fish_jump(fish: FishData) -> float:
	if fish == null or fish.model_scene == null:
		return 0.0
	var model := fish.model_scene.instantiate() as Node3D
	add_child(model)
	var gloves := model.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = false
	var player := model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(&"fish_hooked_pull"):
		player.play(&"fish_hooked_pull")
	model.scale = Vector3.ONE * SCALE_FISH
	var start := water_point()
	var across := DioramaStyle.screen_right() * (1.0 if _random.randf() < 0.5 else -1.0)
	var finish := start + across * 1.5
	model.visible = false
	_world.splash_at(start, true)
	_world.ripple_at(start)
	AudioManager.play_sfx(&"sfx_large_splash", -9.0)
	var turn := Basis.looking_at(across, Vector3.UP)
	return _add(FishingEvents.FISH_JUMP, [model], 1.25, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"]) / 1.05
		if t >= 1.0:
			if model.visible:
				model.visible = false
				_world.splash_at(finish)
				_world.ripple_at(finish)
				AudioManager.play_sfx(&"sfx_float_plip")
			return
		model.visible = true
		model.position = start.lerp(finish, t) + Vector3(0.0, sin(t * PI) * 1.1 - 0.15, 0.0)
		# Nose up on the way out, nose down on the way in.
		model.basis = (turn * Basis(Vector3.RIGHT, lerpf(0.9, -0.9, t)) * Basis(Vector3.UP, PI * 0.5)).scaled(Vector3.ONE * SCALE_FISH))


## A kingfisher (a gull by the sea) swoops in from the far bank, snatches a
## fish from the water and flies off with it.
func bird_dive(sea: bool) -> float:
	var bird := _prop("prop_event_gull" if sea else "prop_event_kingfisher")
	bird.scale = Vector3.ONE * (SCALE_GULL if sea else SCALE_KINGFISHER)
	var catch := bird.get_node("Catch") as Node3D
	catch.visible = false
	var target := water_point()
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	# In from one side of the screen, low over the water, out the other side.
	var from := target + DioramaStyle.screen_right() * 5.5 * side + DioramaStyle.screen_in() * 1.0 + Vector3(0.0, 1.6, 0.0)
	var to := target - DioramaStyle.screen_right() * 6.0 * side + DioramaStyle.screen_in() * 0.5 + Vector3(0.0, 2.2, 0.0)
	var dive := 1.3
	AudioManager.play_sfx(&"event_gull_call" if sea else &"event_bird_call")
	return _add(FishingEvents.BIRD, [bird], 3.0, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		var wing := 0.0
		if t < dive:
			var along := ease(t / dive, 1.6)
			bird.position = from.lerp(target, along) + Vector3(0.0, 0.05, 0.0)
			face_along(bird, target - from)
			wing = 0.25 + 0.15 * sin(t * 9.0)
		else:
			if not catch.visible:
				catch.visible = true
				_world.splash_at(target)
				_world.ripple_at(target)
				AudioManager.play_sfx(&"sfx_float_plip")
			var along := ease((t - dive) / (3.0 - dive), 0.6)
			bird.position = target.lerp(to, along) + Vector3(0.0, 0.05, 0.0)
			face_along(bird, to - target)
			wing = 0.7 * sin(t * 20.0)
		(bird.get_node("WingL") as Node3D).rotation.x = -wing
		(bird.get_node("WingR") as Node3D).rotation.x = wing)


## A frog on a lily pad near the bank croaks twice and hops into the water.
func frog() -> float:
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	var spot := place(side * _random.randf_range(1.2, 2.3), _random.randf_range(1.45, 1.7))
	var pad := _prop("prop_event_lily_pad")
	var animal := _prop("prop_event_frog")
	var throat := animal.get_node("Throat") as Node3D
	pad.position = spot
	pad.rotation.y = _random.randf() * TAU
	animal.scale = Vector3.ONE * SCALE_FROG
	var toward := (_darto - spot) * Vector3(1.0, 0.0, 1.0)
	face_along(animal, toward)
	var hop := spot - toward.normalized() * 1.2
	return _add(FishingEvents.FROG, [pad, animal], 5.2, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		pad.scale = Vector3.ONE * SCALE_FROG * clampf(minf(t / 0.25, (5.2 - t) / 0.4), 0.0, 1.0)
		if t < 2.9:
			animal.position = spot + Vector3(0.0, 0.02, 0.0)
			animal.scale = Vector3.ONE * SCALE_FROG * clampf(t / 0.25, 0.01, 1.0)
			var croak := 0.0
			for start: float in [0.6, 1.6]:
				if t > start and t < start + 0.5:
					croak = sin((t - start) * PI / 0.5)
			throat.scale = Vector3.ONE * (1.0 + croak * 0.9)
			if not actor.has("croak1") and t > 0.6:
				actor["croak1"] = true
				AudioManager.play_sfx(&"event_frog_croak")
			if not actor.has("croak2") and t > 1.6:
				actor["croak2"] = true
				AudioManager.play_sfx(&"event_frog_croak")
		elif t < 3.35:
			var along := (t - 2.9) / 0.45
			animal.position = spot.lerp(hop, along) + Vector3(0.0, sin(along * PI) * 0.6, 0.0)
		elif animal.visible:
			animal.visible = false
			_world.splash_at(hop)
			_world.ripple_at(hop)
			AudioManager.play_sfx(&"sfx_float_plip"))


## A dragonfly flies in and rests on the float, then buzzes off. It leaves at
## once if a bite comes.
func dragonfly() -> float:
	var fly := _prop("prop_event_dragonfly")
	fly.scale = Vector3.ONE * SCALE_DRAGONFLY
	var wings := fly.get_node("Wings") as Node3D
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	var start := _world.get_float_position() + DioramaStyle.screen_right() * 2.8 * side + Vector3(0.0, 1.4, 0.0)
	var away := _world.get_float_position() - DioramaStyle.screen_right() * 3.0 * side + Vector3(0.0, 2.0, 0.0)
	fly.position = start
	return _add(FishingEvents.DRAGONFLY, [fly], 5.0, func(actor: Dictionary, delta: float) -> void:
		var t := float(actor["t"])
		var perch := _world.get_float_position() + Vector3(0.0, 0.13, 0.0)
		if actor.get("leaving", false) and not actor.has("left_at"):
			actor["left_at"] = t
			actor["left_from"] = fly.position
		var buzzing := true
		if actor.has("left_at"):
			var along := clampf((t - float(actor["left_at"])) / 0.9, 0.0, 1.0)
			fly.position = (actor["left_from"] as Vector3).lerp(away, along)
			face_along(fly, away - fly.position)
			if along >= 1.0:
				actor["duration"] = t
		elif t < 1.2:
			var along := ease(t / 1.2, 0.5)
			fly.position = start.lerp(perch, along) + Vector3(0.0, sin(t * 7.0) * 0.06 * (1.0 - along), 0.0)
			face_along(fly, perch - start)
		elif t < 4.0:
			fly.position = perch
			buzzing = fmod(t, 1.1) < 0.12
		else:
			var along := (t - 4.0) / 1.0
			fly.position = perch.lerp(away, along)
			face_along(fly, away - perch)
		wings.rotation.x = sin(t * 60.0) * 0.35 if buzzing else 0.0
		wings.scale = Vector3.ONE)


## Something floats across the water in front of Darto: a lost sandal far
## out, or a bottle close enough to reach. Returns the drifting node.
func drift(event_id: StringName) -> Node3D:
	var bottle := event_id == FishingEvents.BOTTLE
	var item := _prop("prop_event_bottle" if bottle else "prop_trash_lost_sandal")
	var size := SCALE_BOTTLE if bottle else SCALE_SANDAL
	item.scale = Vector3.ONE * size
	var depth := _random.randf_range(1.6, 1.85) if bottle else _random.randf_range(3.0, 3.8)
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	var from := place(4.2 * side, depth)
	var to := place(-4.4 * side, depth + 0.3)
	var duration := 12.0 if bottle else 11.0
	var spin := _random.randf_range(-0.4, 0.4)
	_add(event_id, [item], duration, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		if actor.has("collected_at"):
			var along := clampf((t - float(actor["collected_at"])) / 0.6, 0.0, 1.0)
			item.position = (actor["collected_from"] as Vector3).lerp(_world.get_bank_spot(), along) + Vector3(0.0, sin(along * PI) * 0.6, 0.0)
			item.scale = Vector3.ONE * size * (1.0 - along * 0.6)
			if along >= 1.0:
				actor["duration"] = t
			return
		item.position = from.lerp(to, t / duration) + Vector3(0.0, sin(t * 2.2) * 0.02 - 0.01, 0.0)
		item.rotation = Vector3(sin(t * 1.7) * 0.12, spin * t, sin(t * 1.3) * 0.08))
	return item


## Darto fishes the bottle out: it flies to the bank and is gone.
func collect(item: Node3D) -> void:
	for actor: Dictionary in _actors:
		if (actor["nodes"] as Array).has(item) and not actor.has("collected_at"):
			actor["collected_at"] = actor["t"]
			actor["collected_from"] = item.position
			_world.splash_at(item.position)
			AudioManager.play_sfx(&"sfx_float_plip")


## A light drizzle: rain over the water and rings on it, for `seconds`.
func drizzle(seconds: float) -> float:
	_rain.global_position = place(0.0, 2.6, 4.5)
	_rain.emitting = true
	AudioManager.play_sfx(&"event_rain")
	return _add(FishingEvents.DRIZZLE, [], seconds, func(actor: Dictionary, delta: float) -> void:
		var t := float(actor["t"])
		if t > seconds - 1.0:
			_rain.emitting = false
		elif not actor.has("second_rain") and t > 6.0:
			actor["second_rain"] = true
			AudioManager.play_sfx(&"event_rain")
		actor["ring_left"] = float(actor.get("ring_left", 0.0)) - delta
		if float(actor["ring_left"]) <= 0.0 and t < seconds - 1.0:
			actor["ring_left"] = 0.12
			_spawn_ripple(place(_random.randf_range(-3.5, 3.5), _random.randf_range(0.9, 5.5))))


## A neighbour rides along the path behind Darto. Returns its length.
func motor_pass() -> float:
	var bike := _prop("prop_motorcycle_darto")
	var rider := _prop("prop_event_rider")
	remove_child(rider)
	bike.add_child(rider)
	rider.position = Vector3(-0.15, 0.42, 0.0)
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	var from := ground_point(6.5 * side, MEADOW_IN)
	var to := ground_point(-6.5 * side, MEADOW_IN - 0.4)
	face_along(bike, to - from)
	var duration := 6.5
	return _add(FishingEvents.MOTOR, [bike], duration, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		bike.position = from.lerp(to, t / duration) + Vector3(0.0, absf(sin(t * 11.0)) * 0.015, 0.0)
		if not actor.has("honk") and t > duration * 0.4:
			actor["honk"] = true
			AudioManager.play_sfx(&"event_horn")
		if not actor.has("honk2") and t > duration * 0.4 + 0.35:
			actor["honk2"] = true
			AudioManager.play_sfx(&"event_horn"))


## Two children walk across the meadow flying kites over the water.
func kites() -> float:
	var duration := 15.0
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	var nodes: Array[Node3D] = []
	var children: Array[Node3D] = []
	var kites_flown: Array[Node3D] = []
	var lines: Array[ImmediateMesh] = []
	for index: int in 2:
		var child := _prop("prop_event_kid_a" if index == 0 else "prop_event_kid_b")
		var kite := _prop("prop_event_kite_red" if index == 0 else "prop_event_kite_blue")
		child.scale = Vector3.ONE * SCALE_CHILD
		kite.scale = Vector3.ONE * SCALE_KITE
		var mesh := ImmediateMesh.new()
		var line := MeshInstance3D.new()
		line.mesh = mesh
		line.material_override = load("res://generated/materials/mat_fishing_line.tres")
		line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(line)
		children.append(child)
		kites_flown.append(kite)
		lines.append(mesh)
		nodes.append_array([child, kite, line])
	var walk_from := 5.5 * side
	var walk_to := -5.5 * side
	return _add(FishingEvents.KITES, nodes, duration, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		for index: int in 2:
			var child := children[index]
			var kite := kites_flown[index]
			var lag := float(index) * 0.9
			var along := clampf((t - lag) / (duration - 1.0), 0.0, 1.0)
			var across := lerpf(walk_from, walk_to, along) + float(index) * 0.7 * side
			var depth := MEADOW_IN - 0.8 - float(index) * 0.5
			child.position = ground_point(across, depth) + Vector3(0.0, absf(sin(t * 7.0 + lag)) * 0.04, 0.0)
			face_along(child, DioramaStyle.screen_right() * -side)
			(child.get_node("Arm") as Node3D).rotation.z = sin(t * 2.0 + lag) * 0.15
			var drift_x := sin(t * 0.8 + lag) * 0.5
			kite.position = place(across + drift_x, depth + 3.2, 2.6 + float(index) * 0.5 + sin(t * 1.3 + lag) * 0.2)
			face_along(kite, -DioramaStyle.screen_in())
			kite.rotation.x = sin(t * 1.6 + lag) * 0.2
			kite.scale = Vector3.ONE * SCALE_KITE
			(kite.get_node("Tail") as Node3D).rotation.x = sin(t * 3.0 + lag) * 0.35
			var hand := (child.get_node("Arm") as Node3D).global_transform * Vector3(0.065, 0.18, -0.04)
			var tip := kite.global_transform * Vector3(0.0, -0.24, 0.0)
			var mesh := lines[index]
			mesh.clear_surfaces()
			mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
			for step: int in 9:
				var point := hand.lerp(tip, float(step) / 8.0)
				point.y -= sin(float(step) / 8.0 * PI) * 0.25
				mesh.surface_add_vertex(point)
			mesh.surface_end())


# --- The comic ones ------------------------------------------------------------

## Lengths the director times its lines to.
const HECKLE_SEC := 7.0
const COLLECTOR_SEC := 12.0
const DUCKS_SEC := 13.0
const CAT_SEC := 11.0


## A fish of this spot pops up near Darto to say something rude, gloats
## (`gloat_at`), and dives back in.
func heckle(fish: FishData, gloat_at: float) -> float:
	if fish == null or fish.model_scene == null:
		return 0.0
	var model := fish.model_scene.instantiate() as Node3D
	add_child(model)
	var gloves := model.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = false
	var player := model.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var spot := water_point()
	for attempt: int in 8:
		spot = place(_random.randf_range(-2.0, 2.2), _random.randf_range(1.6, 2.1))
		if Vector2(spot.x, spot.z).distance_to(Vector2(_float_spot.x, _float_spot.z)) >= 0.9:
			break
	model.scale = Vector3.ONE * SCALE_FISH * 1.7
	# Half toward Darto, half toward the camera, so the face reads.
	var look := ((_darto - spot) * Vector3(1.0, 0.0, 1.0)).normalized() - DioramaStyle.screen_in()
	face_along(model, look)
	_play(player, &"fish_idle_water")
	_world.splash_at(spot)
	_world.ripple_at(spot)
	AudioManager.play_sfx(&"sfx_float_plip")
	return _add(FishingEvents.HECKLE, [model], HECKLE_SEC, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		var dive_at := HECKLE_SEC - 0.8
		var rise := clampf(t / 0.4, 0.0, 1.0)
		var sink := clampf((t - dive_at) / 0.5, 0.0, 1.0)
		model.position = spot + Vector3(0.0, lerpf(-0.5, -0.06, rise) - sink * 0.6 + sin(t * 3.0) * 0.015, 0.0)
		if not actor.has("gloated") and t >= gloat_at:
			actor["gloated"] = true
			_play(player, &"suwit_win")
		if not actor.has("dived") and t >= dive_at:
			actor["dived"] = true
			_play(player, &"fish_escape_jump")
			_world.splash_at(spot, true)
			_world.ripple_at(spot)
			AudioManager.play_sfx(&"sfx_large_splash", -10.0)
		model.visible = sink < 1.0)


## CepatCash's debt collector rides up behind Darto with a megaphone and a
## company sign, stops for a word (`hold` seconds), and rides off.
func collector(hold: float) -> float:
	var bike := _prop("prop_motorcycle_darto")
	var rider := _prop("prop_event_collector")
	remove_child(rider)
	bike.add_child(rider)
	rider.position = Vector3(-0.15, 0.42, 0.0)
	var sign := Label3D.new()
	sign.text = "CEPATCASH"
	sign.font = load(UiTokens.FONT_DISPLAY_FILE) as FontFile
	sign.font_size = 44
	sign.outline_size = 12
	sign.modulate = Color("e9fff4")
	sign.outline_modulate = Color("2f7d61")
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = 0.006
	sign.position = Vector3(-0.42, 0.95, 0.0)
	bike.add_child(sign)
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	# It stops on the path to Darto's left, clear of his own parked motorbike.
	var from := ground_point(6.5 * side, MEADOW_IN + 0.9)
	var stop := ground_point(-1.4, MEADOW_IN + 1.4)
	var to := ground_point(-6.5 * side, MEADOW_IN + 0.6)
	var arrive := 2.2
	var length := arrive + hold + 2.0
	face_along(bike, stop - from)
	return _add(FishingEvents.COLLECTOR, [bike], length, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		if t < arrive:
			bike.position = from.lerp(stop, ease(t / arrive, 0.4))
			bike.position.y += absf(sin(t * 11.0)) * 0.015
		elif t < arrive + hold:
			bike.position = stop
			if not actor.has("honk"):
				actor["honk"] = true
				AudioManager.play_sfx(&"event_horn")
		else:
			var along := ease((t - arrive - hold) / 2.0, 1.8)
			bike.position = stop.lerp(to, along) + Vector3(0.0, absf(sin(t * 11.0)) * 0.015, 0.0)
			face_along(bike, to - stop))


## A mother duck and four ducklings swim across in a line. The last one falls
## behind, panics, and paddles hard to catch up.
func ducks() -> float:
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	var depth := _random.randf_range(3.3, 3.9)
	var from := 4.6 * side
	var to := -4.8 * side
	var birds: Array[Node3D] = []
	for index: int in 5:
		var bird := _prop("prop_event_duck" if index == 0 else "prop_event_duckling")
		bird.scale = Vector3.ONE * SCALE_DUCK
		birds.append(bird)
	return _add(FishingEvents.DUCKS, birds, DUCKS_SEC, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		var lead := lerpf(from, to, t / DUCKS_SEC)
		for index: int in birds.size():
			var gap := 0.0 if index == 0 else 0.55 + 0.42 * float(index - 1)
			if index == birds.size() - 1:
				# Dawdles until halfway, then hurries back into line.
				gap += 1.6 * clampf(t / 5.0, 0.0, 1.0) * (1.0 - clampf((t - 7.8) / 2.4, 0.0, 1.0))
			var across := lead + gap * side
			var hurry := 1.0 if index == birds.size() - 1 and t > 7.8 and t < 10.2 else 0.0
			var bird := birds[index]
			bird.position = place(across, depth + 0.08 * sin(float(index) * 1.7)) + Vector3(0.0, sin(t * (4.0 + hurry * 10.0) + float(index)) * (0.015 + hurry * 0.03), 0.0)
			face_along(bird, DioramaStyle.screen_right() * -side)
		if not actor.has("quack") and t > 1.9:
			actor["quack"] = true
			AudioManager.play_sfx(&"event_duck_quack")
		if not actor.has("panic") and t > 7.8:
			actor["panic"] = true
			AudioManager.play_sfx(&"event_duck_quack", 3.0))


## An orange cat walks up to the bucket, sniffs it, turns to give Darto a
## long look, sits, swishes its tail, and leaves. On the pier it comes along
## the planks.
func cat(on_pier: bool) -> float:
	var animal := _prop("prop_event_cat")
	animal.scale = Vector3.ONE * SCALE_CAT
	var tail := animal.get_node("Tail") as Node3D
	var bucket := _world.get_bucket_position()
	var side := 1.0 if _random.randf() < 0.5 else -1.0
	var start := ground_point(0.0 if on_pier else 2.5 * side, -4.8)
	start.y = bucket.y
	var sniff := bucket + (start - bucket).normalized() * 0.45
	var to_darto := (_darto - sniff) * Vector3(1.0, 0.0, 1.0)
	return _add(FishingEvents.CAT, [animal], CAT_SEC, func(actor: Dictionary, _delta: float) -> void:
		var t := float(actor["t"])
		tail.rotation.x = sin(t * 2.4) * 0.5
		if t < 3.0:
			animal.position = start.lerp(sniff, t / 3.0) + Vector3(0.0, absf(sin(t * 9.0)) * 0.02, 0.0)
			face_along(animal, sniff - start)
		elif t < 4.2:
			animal.position = sniff
			face_along(animal, bucket - sniff)
			animal.rotation.z = sin((t - 3.0) * 14.0) * 0.08
		elif t < 8.0:
			# The look. Turned toward Darto and the camera, sitting back.
			animal.rotation.z = 0.0
			face_along(animal, to_darto.normalized() - DioramaStyle.screen_in() * 0.7)
			animal.rotation.x = 0.0
			animal.position = sniff + Vector3(0.0, -0.01, 0.0)
			if not actor.has("meow") and t > 6.9:
				actor["meow"] = true
				AudioManager.play_sfx(&"event_cat_meow")
		else:
			var along := (t - 8.0) / (CAT_SEC - 8.0)
			animal.position = sniff.lerp(start, along) + Vector3(0.0, absf(sin(t * 9.0)) * 0.02, 0.0)
			face_along(animal, start - sniff))


func _play(player: AnimationPlayer, animation: StringName) -> void:
	if player != null and player.has_animation(animation):
		player.play(animation, 0.15)


# --- Actors ------------------------------------------------------------------

func _prop(prop_id: String) -> Node3D:
	var node := (load(PROPS % prop_id) as PackedScene).instantiate() as Node3D
	add_child(node)
	return node


func _add(event_id: StringName, nodes: Array, duration: float, update: Callable) -> float:
	var actor := {"id": event_id, "nodes": nodes, "t": 0.0, "duration": duration, "update": update}
	_actors.append(actor)
	update.call(actor, 0.0)
	return duration


func _end(actor: Dictionary) -> void:
	_actors.erase(actor)
	for node: Variant in actor["nodes"]:
		if is_instance_valid(node):
			(node as Node).queue_free()
	actor_finished.emit(actor["id"])


# --- Rain --------------------------------------------------------------------

func _build_rain() -> void:
	var drop := BoxMesh.new()
	drop.size = Vector3(0.03, 0.42, 0.03)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.9, 0.95, 1.0, 0.6)
	drop.material = material
	_rain = CPUParticles3D.new()
	_rain.name = "Rain"
	_rain.mesh = drop
	_rain.amount = RAIN_DROPS
	_rain.lifetime = 0.55
	_rain.emitting = false
	_rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_rain.emission_box_extents = Vector3(9.0, 0.1, 9.0)
	_rain.direction = Vector3(0.05, -1.0, 0.0)
	_rain.spread = 2.0
	_rain.gravity = Vector3.ZERO
	_rain.initial_velocity_min = 8.0
	_rain.initial_velocity_max = 9.0
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_rain)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.43
	ring.outer_radius = 0.5
	ring.rings = 16
	ring.ring_segments = 3
	var base: StandardMaterial3D = load("res://generated/materials/mat_water_ripple.tres")
	for index: int in RAIN_RIPPLES:
		var ripple := MeshInstance3D.new()
		ripple.mesh = ring
		ripple.material_override = base.duplicate()
		ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ripple.visible = false
		add_child(ripple)
		_ripples.append(ripple)
		_ripple_ages.append(1.0)


func _spawn_ripple(at: Vector3) -> void:
	var ripple := _ripples[_next_ripple]
	_ripple_ages[_next_ripple] = 0.0
	_next_ripple = (_next_ripple + 1) % _ripples.size()
	ripple.global_position = Vector3(at.x, _float_spot.y + 0.012, at.z)
	ripple.visible = true


func _update_ripples(delta: float) -> void:
	for index: int in _ripples.size():
		if not _ripples[index].visible:
			continue
		_ripple_ages[index] += delta
		var progress := _ripple_ages[index] / 0.8
		if progress >= 1.0:
			_ripples[index].visible = false
			continue
		var spread := lerpf(0.05, 0.4, ease(progress, 0.5))
		_ripples[index].scale = Vector3(spread, 0.04, spread)
		(_ripples[index].material_override as StandardMaterial3D).albedo_color.a = 0.5 * (1.0 - progress)
