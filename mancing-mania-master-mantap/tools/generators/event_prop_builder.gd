@tool
extends RefCounted
## Generates the props of the small happenings at the fishing spot (revision
## 6.12, GDD 174.5): a kingfisher and a gull that dive for a fish, a frog on a
## lily pad, a dragonfly, a drifting bottle, two kites with the children who
## fly them, and a neighbour who rides past on a motorbike.
##
## They follow the prop rules (VISUAL_STYLE_GUIDE 4, 8): chunky and rounded,
## one warm colour per part. They are drawn a little larger than life, as the
## chibi world draws everything, so they read from the fishing camera. Parts
## that move are their own meshes, named for the scene to animate: a bird's
## WingL and WingR, its Catch, the frog's Throat, the dragonfly's Wings, a
## kite's Tail and a child's Arm.

const SoftMesh := preload("res://tools/generators/soft_mesh.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")
const Kit := preload("res://tools/generators/diorama_kit.gd")
const Style := preload("res://scripts/visual/diorama_style.gd")

const GENERATOR_ID := "event_prop_builder"
const GENERATOR_VERSION := 1
const SCENE_PATH := "res://generated/scenes/props/%s.tscn"

const KINGFISHER := "prop_event_kingfisher"
const GULL := "prop_event_gull"
const FROG := "prop_event_frog"
const LILY_PAD := "prop_event_lily_pad"
const DRAGONFLY := "prop_event_dragonfly"
const BOTTLE := "prop_event_bottle"
const KITE_RED := "prop_event_kite_red"
const KITE_BLUE := "prop_event_kite_blue"
const KID_A := "prop_event_kid_a"
const KID_B := "prop_event_kid_b"
const RIDER := "prop_event_rider"
const DUCK := "prop_event_duck"
const DUCKLING := "prop_event_duckling"
const CAT := "prop_event_cat"
const COLLECTOR := "prop_event_collector"

const DARK := Color("4a3c33")
const CREAM := Color("f6e7c8")
const FADED_RED := Color("cf6a58")
const SKIN := Color("e2b18a")
const SKIN_DARK := Color("cf9f78")
const HAIR := Color("3b2a20")


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var props: Dictionary[String, Callable] = {
		KINGFISHER: _build_kingfisher,
		GULL: _build_gull,
		FROG: _build_frog,
		LILY_PAD: _build_lily_pad,
		DRAGONFLY: _build_dragonfly,
		BOTTLE: _build_bottle,
		KITE_RED: _build_kite.bind(FADED_RED, Style.BUTTER),
		KITE_BLUE: _build_kite.bind(Color("6f9fd0"), CREAM),
		KID_A: _build_kid.bind(Color("e9b44c"), Color("5f7fa8"), SKIN),
		KID_B: _build_kid.bind(Color("7fb38a"), Color("8a6a52"), SKIN_DARK),
		RIDER: _build_rider,
		DUCK: _build_duck.bind(Style.FLOUR, 1.0),
		DUCKLING: _build_duck.bind(Style.BUTTER, 0.55),
		CAT: _build_cat,
		COLLECTOR: _build_collector,
	}
	for prop_id: String in props:
		var root: Node3D = props[prop_id].call()
		root.name = prop_id.to_pascal_case()
		var path := SCENE_PATH % prop_id
		var save_error := GeneratorIo.save_scene(root, path)
		root.free()
		if save_error != OK:
			errors.append("%s: could not save (%s)" % [prop_id, error_string(save_error)])
		else:
			manifest.register(prop_id, GENERATOR_ID, GENERATOR_VERSION, 0, path)
	return errors


func _part(root: Node3D, node_name: String, builder: RefCounted, at: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := Kit.bake(node_name, builder)
	node.position = at
	root.add_child(node)
	return node


# --- Birds ---------------------------------------------------------------------

## A kingfisher: royal blue back, orange belly, a long dark beak.
func _build_kingfisher() -> Node3D:
	return _bird(Color("3f86c4"), Color("e8873f"), Color("2f6fa8"), DARK, 1.0)


## A gull for the sea spots: white with grey wings and a yellow beak.
func _build_gull() -> Node3D:
	return _bird(Style.FLOUR, Color("eeeae2"), Color("a9b0b6"), Color("f2c14e"), 1.35)


## A bird along +X (head first), wings spreading toward -Z and +Z from the
## shoulders. WingL and WingR flap by turning about X; Catch is a little fish
## in the beak, shown after the dive.
func _bird(body_color: Color, belly_color: Color, wing_color: Color, beak_color: Color, size: float) -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	body.color = body_color
	body.sphere(Vector3(0.0, 0.0, 0.0) * size, Vector3(0.12, 0.08, 0.075) * size, 12, 6)
	body.sphere(Vector3(0.11, 0.05, 0.0) * size, Vector3(0.065, 0.062, 0.058) * size, 10, 5)
	body.color = belly_color
	body.sphere(Vector3(0.02, -0.03, 0.0) * size, Vector3(0.085, 0.05, 0.06) * size, 10, 5)
	body.color = beak_color
	body.cone(Vector3(0.165, 0.05, 0.0) * size, Vector3(0.27, 0.04, 0.0) * size, 0.02 * size, 8)
	body.color = DARK
	for z: float in [-0.042, 0.042]:
		body.sphere(Vector3(0.14, 0.07, z) * size, Vector3.ONE * 0.011 * size, 6, 3)
	body.color = wing_color
	body.rounded_slab(Vector3(0.09, 0.016, 0.07) * size, Vector3(-0.14, 0.015, 0.0) * size, 0.008)
	_part(root, "Body", body)
	for side: float in [-1.0, 1.0]:
		var wing := SoftMesh.new()
		wing.color = wing_color
		# Drawn in XY, then laid flat: +Y of the outline points out along Z.
		wing.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(90.0 * side)), Vector3.ZERO)
		var outline := PackedVector2Array()
		for point: Vector2 in [Vector2(0.06, 0.0), Vector2(0.05, 0.08), Vector2(0.0, 0.17), Vector2(-0.05, 0.2),
				Vector2(-0.08, 0.15), Vector2(-0.07, 0.06), Vector2(-0.04, 0.0)]:
			outline.append(point * size)
		wing.puffy_outline(outline, 0.014 * size)
		_part(root, "WingR" if side > 0.0 else "WingL", wing, Vector3(0.0, 0.035, 0.05 * side) * size)
	var catch := SoftMesh.new()
	catch.color = Color("c9d5da")
	catch.capsule(Vector3(0.22, 0.02, 0.0) * size, Vector3(0.32, 0.03, 0.0) * size, 0.016 * size, 0.008 * size, 6, 2)
	catch.color = Color("9fb4bc")
	catch.cone(Vector3(0.31, 0.03, 0.0) * size, Vector3(0.35, 0.05, 0.0) * size, 0.014 * size, 6)
	var catch_node := _part(root, "Catch", catch)
	catch_node.visible = false
	return root


# --- Frog and lily pad -----------------------------------------------------------

## A round green frog facing +X, sitting with its legs folded. The Throat
## swells when it croaks.
func _build_frog() -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	var green := Color("7fb35a")
	body.color = green
	body.sphere(Vector3(0.0, 0.055, 0.0), Vector3(0.085, 0.055, 0.075), 12, 6)
	body.sphere(Vector3(0.06, 0.085, 0.0), Vector3(0.06, 0.045, 0.065), 10, 5)
	for z: float in [-0.04, 0.04]:
		body.color = green
		body.sphere(Vector3(0.07, 0.125, z), Vector3.ONE * 0.026, 8, 4)
		body.color = CREAM
		body.sphere(Vector3(0.088, 0.13, z), Vector3.ONE * 0.016, 6, 3)
		body.color = DARK
		body.sphere(Vector3(0.1, 0.132, z), Vector3.ONE * 0.008, 6, 3)
		body.color = Color("6a9a4b")
		# Folded back legs and little front legs.
		body.sphere(Vector3(-0.045, 0.03, z * 1.7), Vector3(0.06, 0.03, 0.035), 8, 4)
		body.capsule(Vector3(0.05, 0.04, z * 1.2), Vector3(0.08, 0.008, z * 1.4), 0.012, 0.01, 6, 2)
	_part(root, "Body", body)
	var throat := SoftMesh.new()
	throat.color = Color("e9e3a8")
	throat.sphere(Vector3.ZERO, Vector3(0.03, 0.026, 0.04), 8, 4)
	_part(root, "Throat", throat, Vector3(0.095, 0.06, 0.0))
	return root


## A floating lily pad with its notch, and a small pink flower.
func _build_lily_pad() -> Node3D:
	var root := Node3D.new()
	var pad := SoftMesh.new()
	pad.color = Color("8cc07a")
	pad.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0.0, 0.006, 0.0))
	var outline := PackedVector2Array()
	for step: int in 16:
		var angle := deg_to_rad(25.0) + TAU * 0.93 * float(step) / 15.0
		outline.append(Vector2(cos(angle), sin(angle)) * 0.17)
	outline.append(Vector2(0.02, 0.0))
	pad.puffy_outline(outline, 0.012)
	pad.transform = Transform3D.IDENTITY
	pad.color = Style.STRAWBERRY
	for petal: int in 5:
		var angle := TAU * float(petal) / 5.0
		pad.sphere(Vector3(-0.07 + cos(angle) * 0.022, 0.025, 0.05 + sin(angle) * 0.022), Vector3(0.018, 0.012, 0.018), 6, 3)
	pad.color = Style.BUTTER
	pad.sphere(Vector3(-0.07, 0.032, 0.05), Vector3.ONE * 0.012, 6, 3)
	_part(root, "Pad", pad)
	return root


# --- Dragonfly -------------------------------------------------------------------

## A teal dragonfly along +X: a long thin tail, a round head with big eyes,
## and four glassy wings (one mesh, Wings) that buzz.
func _build_dragonfly() -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	body.color = Color("3a9b9a")
	body.capsule(Vector3(-0.2, 0.0, 0.0), Vector3(0.02, 0.0, 0.0), 0.012, 0.02, 8, 2)
	body.sphere(Vector3(0.04, 0.0, 0.0), Vector3(0.035, 0.03, 0.03), 8, 4)
	body.color = Color("2f6f7a")
	for z: float in [-0.022, 0.022]:
		body.sphere(Vector3(0.075, 0.01, z), Vector3.ONE * 0.022, 8, 4)
	_part(root, "Body", body)
	var wings := SoftMesh.new()
	wings.select_surface(MaterialBuilder.SURFACE_GLASS)
	wings.color = Color("eaf6f8")
	for x: float in [0.02, -0.035]:
		for side: float in [-1.0, 1.0]:
			wings.rounded_slab(Vector3(0.045, 0.004, 0.16), Vector3(x, 0.025, 0.09 * side), 0.002)
	_part(root, "Wings", wings)
	return root


# --- Bottle ----------------------------------------------------------------------

## A green glass bottle lying on its side along X, cork at +X, with a rolled
## note inside. It floats with the waterline at y = 0.
func _build_bottle() -> Node3D:
	var root := Node3D.new()
	var bottle := SoftMesh.new()
	var lying := Basis(Vector3.BACK, deg_to_rad(-90.0))
	bottle.color = Style.FLOUR
	bottle.cylinder(Vector3(-0.07, 0.0, 0.0), Vector3(0.05, 0.0, 0.0), 0.02, -1.0, 10)
	bottle.color = Style.PINE
	bottle.cylinder(Vector3(0.16, 0.0, 0.0), Vector3(0.19, 0.0, 0.0), 0.022, 0.024, 10)
	bottle.select_surface(MaterialBuilder.SURFACE_GLASS)
	bottle.color = Color("9fd3a6")
	bottle.lathe(PackedVector2Array([
		Vector2(0.0, -0.1), Vector2(0.05, -0.1), Vector2(0.055, -0.085), Vector2(0.055, 0.05),
		Vector2(0.035, 0.1), Vector2(0.026, 0.13), Vector2(0.028, 0.165), Vector2(0.0, 0.165)]), 14,
		Transform3D(lying, Vector3.ZERO))
	_part(root, "Bottle", bottle)
	return root


# --- Kites and children ---------------------------------------------------------

## A diamond kite facing -X (toward the camera side of the meadow), with two
## sticks and a Tail of bows hanging from its lower tip.
func _build_kite(main: Color, second: Color) -> Node3D:
	var root := Node3D.new()
	var kite := SoftMesh.new()
	kite.color_rule = func(point: Vector3, _base: Color) -> Color:
		return main if (point.y > 0.0) == (point.z > 0.0) else second
	kite.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(90.0)), Vector3.ZERO)
	kite.puffy_outline(PackedVector2Array([Vector2(0.0, 0.3), Vector2(0.2, 0.06), Vector2(0.0, -0.26), Vector2(-0.2, 0.06)]), 0.016)
	kite.color_rule = Callable()
	kite.transform = Transform3D.IDENTITY
	kite.color = Style.PINE
	kite.capsule(Vector3(-0.012, 0.29, 0.0), Vector3(-0.012, -0.25, 0.0), 0.007, -1.0, 6, 2)
	kite.capsule(Vector3(-0.012, 0.06, -0.19), Vector3(-0.012, 0.06, 0.19), 0.007, -1.0, 6, 2)
	_part(root, "Kite", kite)
	var tail := SoftMesh.new()
	tail.color = Style.PINE.lightened(0.3)
	tail.capsule(Vector3(0.0, 0.0, 0.0), Vector3(0.0, -0.42, 0.0), 0.004, -1.0, 4, 2)
	for bow: int in 3:
		tail.color = main if bow % 2 == 0 else second
		var y := -0.12 - 0.13 * float(bow)
		tail.sphere(Vector3(0.0, y, -0.025), Vector3(0.012, 0.016, 0.03), 6, 3)
		tail.sphere(Vector3(0.0, y, 0.025), Vector3(0.012, 0.016, 0.03), 6, 3)
	_part(root, "Tail", tail, Vector3(0.0, -0.26, 0.0))
	return root


## A child, 0.62 m, chibi like the grown-ups (guide 3) and facing +X. The
## right Arm (on -Z) is raised to hold a kite string and can swing.
func _build_kid(shirt: Color, shorts: Color, skin: Color) -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	body.color = skin
	for z: float in [-0.045, 0.045]:
		body.capsule(Vector3(0.0, 0.03, z), Vector3(0.0, 0.17, z), 0.03, 0.033, 8, 2)
	body.color = DARK
	for z: float in [-0.045, 0.045]:
		body.sphere(Vector3(0.015, 0.025, z), Vector3(0.045, 0.026, 0.035), 8, 3)
	body.color = shorts
	body.sphere(Vector3(0.0, 0.2, 0.0), Vector3(0.085, 0.06, 0.1), 10, 5)
	body.color = shirt
	body.capsule(Vector3(0.0, 0.22, 0.0), Vector3(0.0, 0.33, 0.0), 0.09, 0.08, 10, 3)
	body.capsule(Vector3(0.0, 0.31, 0.09), Vector3(0.02, 0.22, 0.12), 0.028, 0.026, 6, 2)
	body.color = skin
	body.sphere(Vector3(0.02, 0.2, 0.125), Vector3.ONE * 0.03, 6, 3)
	body.sphere(Vector3(0.0, 0.47, 0.0), Vector3(0.13, 0.125, 0.125), 12, 6)
	body.color = HAIR
	body.sphere(Vector3(-0.02, 0.52, 0.0), Vector3(0.125, 0.09, 0.13), 12, 5)
	body.color = DARK
	for z: float in [-0.045, 0.045]:
		body.sphere(Vector3(0.115, 0.465, z), Vector3(0.012, 0.018, 0.012), 6, 3)
	body.color = Style.BLUSH
	for z: float in [-0.07, 0.07]:
		body.sphere(Vector3(0.105, 0.43, z), Vector3(0.008, 0.012, 0.02), 6, 3)
	_part(root, "Body", body)
	var arm := SoftMesh.new()
	arm.color = shirt
	arm.capsule(Vector3.ZERO, Vector3(0.03, 0.06, -0.03), 0.028, 0.026, 6, 2)
	arm.color = skin
	arm.capsule(Vector3(0.03, 0.06, -0.03), Vector3(0.06, 0.16, -0.04), 0.024, 0.022, 6, 2)
	arm.sphere(Vector3(0.065, 0.18, -0.04), Vector3.ONE * 0.03, 6, 3)
	_part(root, "Arm", arm, Vector3(0.0, 0.31, -0.09))
	root.add_child(Kit.character_shadow(0.15))
	return root


## A neighbour on Darto's motorbike model, seated: hips at the origin, which
## the scene puts on the seat; facing +X like the bike.
func _build_rider() -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	var shirt := Color("c9785a")
	var trousers := Color("5d6b7a")
	body.color = trousers
	for z: float in [-0.06, 0.06]:
		body.capsule(Vector3(0.0, 0.0, z), Vector3(0.16, 0.0, z * 1.3), 0.045, 0.04, 8, 2)
		body.capsule(Vector3(0.16, 0.0, z * 1.3), Vector3(0.2, -0.16, z * 1.4), 0.04, 0.036, 8, 2)
		body.color = DARK
		body.sphere(Vector3(0.23, -0.18, z * 1.4), Vector3(0.05, 0.028, 0.035), 8, 3)
		body.color = trousers
	body.color = shirt
	body.capsule(Vector3(-0.02, 0.04, 0.0), Vector3(0.02, 0.24, 0.0), 0.1, 0.09, 10, 3)
	for z: float in [-0.1, 0.1]:
		body.capsule(Vector3(0.02, 0.22, z), Vector3(0.22, 0.12, z * 1.6), 0.03, 0.026, 6, 2)
		body.color = SKIN_DARK
		body.sphere(Vector3(0.25, 0.11, z * 1.6), Vector3.ONE * 0.03, 6, 3)
		body.color = shirt
	body.color = SKIN_DARK
	body.sphere(Vector3(0.03, 0.38, 0.0), Vector3(0.12, 0.115, 0.115), 12, 6)
	body.color = DARK
	for z: float in [-0.04, 0.04]:
		body.sphere(Vector3(0.14, 0.38, z), Vector3(0.011, 0.016, 0.011), 6, 3)
	body.color = Color("e0b04a")
	body.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.125, 0.0), Vector2(0.13, 0.04), Vector2(0.1, 0.1), Vector2(0.05, 0.13), Vector2(0.0, 0.138)]), 14,
		Transform3D(Basis.IDENTITY, Vector3(0.02, 0.4, 0.0)))
	_part(root, "Body", body)
	return root


# --- Ducks, the cat and the debt collector (revision 6.12) ---------------------

## A swimming duck along +X, waterline at y = 0: a round body, a raised head
## and an orange bill. The ducklings are the same bird, smaller and yellow.
func _build_duck(feathers: Color, size: float) -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	body.color = feathers
	body.sphere(Vector3(0.0, 0.03, 0.0) * size, Vector3(0.14, 0.075, 0.095) * size, 12, 6)
	body.sphere(Vector3(-0.12, 0.07, 0.0) * size, Vector3(0.05, 0.035, 0.05) * size, 8, 4)
	body.capsule(Vector3(0.08, 0.06, 0.0) * size, Vector3(0.11, 0.15, 0.0) * size, 0.04 * size, 0.038 * size, 8, 2)
	body.sphere(Vector3(0.12, 0.19, 0.0) * size, Vector3(0.06, 0.058, 0.055) * size, 10, 5)
	body.color = Color("f0973f")
	body.sphere(Vector3(0.185, 0.18, 0.0) * size, Vector3(0.045, 0.014, 0.03) * size, 8, 3)
	body.color = DARK
	for z: float in [-0.035, 0.035]:
		body.sphere(Vector3(0.155, 0.205, z) * size, Vector3.ONE * 0.01 * size, 6, 3)
	body.color = feathers.darkened(0.08)
	for z: float in [-0.07, 0.07]:
		body.sphere(Vector3(-0.01, 0.055, z) * size, Vector3(0.09, 0.035, 0.03) * size, 8, 3)
	_part(root, "Body", body)
	return root


## An orange village cat ("kucing oren") facing +X: round body, big head,
## pointed ears, striped back, and a Tail on its own that swishes.
func _build_cat() -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	var orange := Color("e8964a")
	var stripe := Color("c9743a")
	body.color_rule = func(point: Vector3, base: Color) -> Color:
		return stripe if point.y > 0.13 and sin(point.x * 70.0) > 0.45 else base
	body.color = orange
	body.capsule(Vector3(-0.1, 0.12, 0.0), Vector3(0.08, 0.12, 0.0), 0.075, 0.07, 10, 3)
	body.color_rule = Callable()
	for x: float in [-0.08, 0.07]:
		for z: float in [-0.045, 0.045]:
			body.capsule(Vector3(x, 0.1, z), Vector3(x, 0.015, z), 0.025, 0.022, 6, 2)
			body.color = Style.FLOUR
			body.sphere(Vector3(x + 0.008, 0.012, z), Vector3(0.026, 0.014, 0.022), 6, 3)
			body.color = orange
	body.sphere(Vector3(0.14, 0.2, 0.0), Vector3(0.085, 0.078, 0.09), 12, 6)
	body.color = Style.FLOUR
	body.sphere(Vector3(0.205, 0.18, 0.0), Vector3(0.035, 0.03, 0.045), 8, 4)
	body.color = orange
	for z: float in [-0.05, 0.05]:
		body.cone(Vector3(0.13, 0.25, z), Vector3(0.13, 0.32, z * 1.2), 0.03, 6)
	body.color = DARK
	for z: float in [-0.032, 0.032]:
		# Half-closed eyes: the look that judges.
		body.rounded_slab(Vector3(0.008, 0.008, 0.026), Vector3(0.21, 0.215, z), 0.003)
	body.color = Style.STRAWBERRY
	body.sphere(Vector3(0.235, 0.19, 0.0), Vector3(0.01, 0.008, 0.012), 6, 3)
	_part(root, "Body", body)
	var tail := SoftMesh.new()
	tail.color = orange
	tail.capsule(Vector3.ZERO, Vector3(-0.08, 0.1, 0.0), 0.02, 0.018, 6, 2)
	tail.capsule(Vector3(-0.08, 0.1, 0.0), Vector3(-0.07, 0.2, 0.0), 0.018, 0.016, 6, 2)
	tail.color = stripe
	tail.sphere(Vector3(-0.07, 0.205, 0.0), Vector3.ONE * 0.02, 6, 3)
	_part(root, "Tail", tail, Vector3(-0.17, 0.14, 0.0))
	root.add_child(Kit.character_shadow(0.13))
	return root


## CepatCash's debt collector, seated like the neighbour (hips at the origin,
## facing +X): a green company jacket, a cap, and a megaphone raised to the
## mouth in the left hand.
func _build_collector() -> Node3D:
	var root := Node3D.new()
	var body := SoftMesh.new()
	var jacket := Color("3e9a7a")
	var trousers := Color("39424d")
	body.color = trousers
	for z: float in [-0.06, 0.06]:
		body.capsule(Vector3(0.0, 0.0, z), Vector3(0.16, 0.0, z * 1.3), 0.045, 0.04, 8, 2)
		body.capsule(Vector3(0.16, 0.0, z * 1.3), Vector3(0.2, -0.16, z * 1.4), 0.04, 0.036, 8, 2)
		body.color = DARK
		body.sphere(Vector3(0.23, -0.18, z * 1.4), Vector3(0.05, 0.028, 0.035), 8, 3)
		body.color = trousers
	body.color = jacket
	body.capsule(Vector3(-0.02, 0.04, 0.0), Vector3(0.02, 0.24, 0.0), 0.1, 0.09, 10, 3)
	body.capsule(Vector3(0.02, 0.22, 0.1), Vector3(0.22, 0.12, 0.16), 0.03, 0.026, 6, 2)
	body.color = SKIN
	body.sphere(Vector3(0.25, 0.11, 0.16), Vector3.ONE * 0.03, 6, 3)
	body.color = jacket
	body.capsule(Vector3(0.02, 0.22, -0.1), Vector3(0.12, 0.3, -0.06), 0.03, 0.026, 6, 2)
	body.color = SKIN
	body.sphere(Vector3(0.13, 0.32, -0.05), Vector3.ONE * 0.03, 6, 3)
	body.sphere(Vector3(0.03, 0.38, 0.0), Vector3(0.12, 0.115, 0.115), 12, 6)
	body.color = DARK
	for z: float in [-0.04, 0.04]:
		body.sphere(Vector3(0.14, 0.39, z), Vector3(0.011, 0.016, 0.011), 6, 3)
	body.color = jacket.darkened(0.15)
	body.sphere(Vector3(0.02, 0.45, 0.0), Vector3(0.12, 0.06, 0.12), 12, 4)
	body.rounded_slab(Vector3(0.1, 0.015, 0.14), Vector3(0.12, 0.43, 0.0), 0.006)
	body.color = Style.BUTTER
	body.cone(Vector3(0.15, 0.35, -0.03), Vector3(0.3, 0.37, -0.03), 0.06, 10)
	body.color = DARK
	body.capsule(Vector3(0.12, 0.34, -0.03), Vector3(0.16, 0.35, -0.03), 0.018, -1.0, 6, 2)
	_part(root, "Body", body)
	return root
