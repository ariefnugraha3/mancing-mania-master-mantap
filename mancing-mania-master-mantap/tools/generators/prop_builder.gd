@tool
extends RefCounted
## Generates the fishing props (GDD 174.5, 174.8): rod, float, bucket and the
## three trash catches. Later milestones add the home, market and duel props.

const MeshBuilder := preload("res://tools/generators/mesh_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const MaterialBuilder := preload("res://tools/generators/material_builder.gd")

const GENERATOR_ID := "prop_builder"
const GENERATOR_VERSION := 1
const SCENE_PATH := "res://generated/scenes/props/%s.tscn"

const ROD := "prop_fishing_rod_basic"
const FLOAT := "prop_float_basic"
const BUCKET := "prop_bucket_blue"
const TRASH_SANDAL := "prop_trash_lost_sandal"
const TRASH_CAN := "prop_trash_rusty_can"
const TRASH_TYRE := "prop_trash_ancient_tyre"

## The rod is modelled along -Z from the grip at the origin.
const ROD_LENGTH := 2.5


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var props: Dictionary[String, Callable] = {
		ROD: _build_rod,
		FLOAT: _build_float,
		BUCKET: _build_bucket,
		TRASH_SANDAL: _build_sandal,
		TRASH_CAN: _build_can,
		TRASH_TYRE: _build_tyre,
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


func _wrap(builder: RefCounted) -> Node3D:
	var root := Node3D.new()
	var instance := MeshInstance3D.new()
	instance.name = "Mesh"
	instance.mesh = builder.commit()
	instance.material_override = load(MaterialBuilder.VERTEX_COLOR)
	root.add_child(instance)
	return root


## An old two-piece rod: cork grip, small reel, dark tapered blank, line guides.
func _build_rod() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = Color("3a2f27")
	builder.tube(Vector3(0, 0, 0.16), Vector3(0, 0, 0.12), 0.019, 0.021, 7)
	builder.color = Color("b08a5c")
	builder.tube(Vector3(0, 0, 0.12), Vector3(0, 0, -0.20), 0.021, 0.018, 7)
	builder.color = Color("3a2f27")
	builder.tube(Vector3(0, 0, -0.20), Vector3(0, 0, -0.26), 0.019, 0.013, 7)

	# Reel under the grip.
	builder.color = Color("59544c")
	builder.tube(Vector3(0, -0.02, -0.11), Vector3(0, -0.062, -0.11), 0.010, 0.010, 5)
	builder.tube(Vector3(-0.028, -0.085, -0.11), Vector3(0.028, -0.085, -0.11), 0.034, 0.034, 9)
	builder.color = Color("2a2622")
	builder.tube(Vector3(0.028, -0.085, -0.11), Vector3(0.062, -0.085, -0.11), 0.007, 0.007, 5)
	builder.tube(Vector3(0.062, -0.085, -0.11), Vector3(0.062, -0.125, -0.11), 0.009, 0.009, 5)

	# Blank in three tapering pieces, with a faded band at the joint.
	builder.color = Color("3d4038")
	builder.tube(Vector3(0, 0, -0.26), Vector3(0, 0, -1.15), 0.0125, 0.0085, 6)
	builder.color = Color("9b5a44")
	builder.tube(Vector3(0, 0, -1.15), Vector3(0, 0, -1.21), 0.0095, 0.0092, 6)
	builder.color = Color("3d4038")
	builder.tube(Vector3(0, 0, -1.21), Vector3(0, 0, -1.95), 0.0082, 0.0048, 6)
	builder.tube(Vector3(0, 0, -1.95), Vector3(0, 0, -ROD_LENGTH), 0.0048, 0.0022, 5)

	builder.color = Color("8d8a80")
	for guide: float in [-0.62, -1.05, -1.48, -1.86, -2.2]:
		builder.tube(Vector3(0, -0.006, guide), Vector3(0, -0.028, guide), 0.003, 0.003, 4)
		builder.tube(Vector3(0, -0.03, guide - 0.004), Vector3(0, -0.03, guide + 0.004), 0.011, 0.011, 6)

	var root := _wrap(builder)
	var tip := Marker3D.new()
	tip.name = "RodTip"
	tip.position = Vector3(0, 0, -ROD_LENGTH)
	root.add_child(tip)
	return root


## Classic bobber: red top, white belly, thin antenna. The origin sits on the
## waterline, so placing it at water height floats it correctly.
func _build_float() -> Node3D:
	var builder := MeshBuilder.new()
	var segments := 8
	var white := Color("f3ecd9")
	var red := Color("b9473c")
	var profile: Array = [
		[-0.085, 0.004, white], [-0.05, 0.022, white], [-0.012, 0.034, white],
		[0.0, 0.036, red], [0.03, 0.03, red], [0.058, 0.012, red], [0.07, 0.005, red],
	]
	for index: int in profile.size() - 1:
		var lower: Array = profile[index]
		var upper: Array = profile[index + 1]
		builder.color = upper[2]
		builder.tube(Vector3(0, lower[0], 0), Vector3(0, upper[0], 0), lower[1], upper[1], segments, index == 0)
	builder.color = Color("2a2622")
	builder.tube(Vector3(0, 0.07, 0), Vector3(0, 0.15, 0), 0.004, 0.003, 5)
	builder.color = red
	builder.blob(Vector3(0, 0.158, 0), Vector3.ONE * 0.011, 6, 3)
	return _wrap(builder)


## Faded blue plastic bucket with a wire handle resting to one side.
func _build_bucket() -> Node3D:
	var builder := MeshBuilder.new()
	var blue := Color("4f7fa3")
	var segments := 12
	var bottom := 0.115
	var top := 0.155
	var height := 0.27
	var wall := 0.012

	builder.color = blue
	builder.tube(Vector3(0, 0, 0), Vector3(0, height, 0), bottom, top, segments, true)
	# Dark interior disc slightly below the rim reads as an open bucket.
	builder.color = blue.darkened(0.45)
	builder.tube(Vector3(0, height - 0.035, 0), Vector3(0, height + 0.002, 0), top - wall * 2.2, top - wall, segments, true)
	builder.color = blue.lightened(0.12)
	builder.tube(Vector3(0, height - 0.012, 0), Vector3(0, height + 0.006, 0), top + 0.008, top + 0.008, segments, true)

	builder.color = Color("8d8a80")
	var previous := Vector3(-top - 0.004, height - 0.02, 0)
	for step: int in range(1, 9):
		var angle := PI * float(step) / 8.0
		var point := Vector3(-cos(angle) * (top + 0.004), height - 0.02 + sin(angle) * 0.05, sin(angle) * (top + 0.02))
		builder.tube(previous, point, 0.004, 0.004, 4, false)
		previous = point
	return _wrap(builder)


## A single rubber sandal that has clearly seen things.
func _build_sandal() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color = Color("3f6a8a")
	var sole := PackedVector2Array([
		Vector2(-0.045, -0.12), Vector2(0.04, -0.125), Vector2(0.055, -0.03), Vector2(0.05, 0.08),
		Vector2(0.02, 0.13), Vector2(-0.03, 0.125), Vector2(-0.055, 0.05), Vector2(-0.05, -0.05)])
	builder.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-90.0)), Vector3(0, 0.011, 0))
	builder.slab(sole, 0.022)
	builder.transform = Transform3D.IDENTITY
	builder.color = Color("d9cdb4")
	builder.tube(Vector3(0, 0.022, -0.085), Vector3(-0.05, 0.05, 0.0), 0.007, 0.007, 5)
	builder.tube(Vector3(0, 0.022, -0.085), Vector3(0.05, 0.05, 0.0), 0.007, 0.007, 5)
	builder.tube(Vector3(-0.05, 0.05, 0.0), Vector3(-0.045, 0.02, 0.03), 0.007, 0.007, 5)
	builder.tube(Vector3(0.05, 0.05, 0.0), Vector3(0.045, 0.02, 0.03), 0.007, 0.007, 5)
	return _wrap(builder)


## A dented tin can, mostly rust.
func _build_can() -> Node3D:
	var builder := MeshBuilder.new()
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		return base.lerp(Color("7a4a2f"), 0.55 if sin(point.y * 70.0 + point.x * 40.0) > 0.1 else 0.0)
	builder.color = Color("a39a8c")
	builder.tube(Vector3(0, 0, 0), Vector3(0.012, 0.11, 0), 0.036, 0.034, 9, true)
	builder.color_rule = Callable()
	builder.color = Color("6d665c")
	builder.tube(Vector3(0.012, 0.108, 0), Vector3(0.013, 0.114, 0), 0.036, 0.036, 9, true)
	builder.color = Color("3a342e")
	builder.tube(Vector3(0.012, 0.106, 0), Vector3(0.013, 0.116, 0), 0.026, 0.026, 9, true)
	return _wrap(builder)


## An old motorcycle tyre, lying flat.
func _build_tyre() -> Node3D:
	var builder := MeshBuilder.new()
	var outer := 0.29
	var tube_radius := 0.06
	var around := 16
	var across := 7
	var rings: Array = []
	for step: int in around + 1:
		var angle := TAU * float(step) / float(around)
		var centre := Vector3(cos(angle), 0.0, sin(angle)) * (outer - tube_radius)
		var outward := Vector3(cos(angle), 0.0, sin(angle)) * tube_radius
		rings.append(builder.ring(centre + Vector3(0, tube_radius, 0), outward, Vector3(0, tube_radius, 0), across, 2.6))
	builder.color_rule = func(point: Vector3, base: Color) -> Color:
		var angle := atan2(point.z, point.x)
		return base.lightened(0.08) if sin(angle * 22.0) > 0.2 else base
	builder.color = Color("2b2a28")
	builder.loft(rings, false, false)
	builder.color_rule = Callable()
	return _wrap(builder)
