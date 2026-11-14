class_name AmbientMotion
extends Node
## Low-amplitude life in a set (GDD 172.9): tree crowns and reeds sway, water
## lines drift, a lamp barely swings. Everything is a plain node transform
## driven by sine waves, so no custom shader is needed (VISUAL_STYLE_GUIDE 5.1).
##
## The generator fills the three arrays; each target has a phase of its own,
## so nothing moves in step with anything else (GDD 158).

const MODE_SWAY := "sway"    # rotate back and forth around `axis`
const MODE_BOB := "bob"      # move up and down
const MODE_DRIFT := "drift"  # slide back and forth along `axis`
const MODE_SPIN := "spin"    # keep turning around `axis`
const PARAMS_PER_TARGET := 4

@export var targets: Array[NodePath] = []
@export var modes: PackedStringArray = PackedStringArray()
## Per target: amplitude (radians or metres; turns per second for spin),
## speed (radians per second), phase (radians), axis (0 = X, 1 = Y, 2 = Z).
@export var params: PackedFloat32Array = PackedFloat32Array()

var _nodes: Array[Node3D] = []
var _bases: Array[Transform3D] = []
var _clock: float = 0.0


func _ready() -> void:
	for path: NodePath in targets:
		var node := get_node_or_null(path) as Node3D
		_nodes.append(node)
		_bases.append(node.transform if node != null else Transform3D.IDENTITY)


func _process(delta: float) -> void:
	_clock += delta
	for index: int in _nodes.size():
		var node := _nodes[index]
		if node == null or index >= modes.size():
			continue
		var at := index * PARAMS_PER_TARGET
		if at + 3 >= params.size():
			continue
		var amplitude := params[at]
		var wave := sin(_clock * params[at + 1] + params[at + 2])
		var axis := _axis(int(params[at + 3]))
		var base := _bases[index]
		match modes[index]:
			MODE_SWAY:
				node.transform = Transform3D(base.basis * Basis(axis, amplitude * wave), base.origin)
			MODE_BOB:
				node.transform = Transform3D(base.basis, base.origin + Vector3.UP * amplitude * wave)
			MODE_DRIFT:
				node.transform = Transform3D(base.basis, base.origin + axis * amplitude * wave)
			MODE_SPIN:
				node.transform = Transform3D(base.basis * Basis(axis, fmod(_clock * amplitude * TAU, TAU)), base.origin)


func get_target_count() -> int:
	return targets.size()


static func _axis(index: int) -> Vector3:
	match index:
		0:
			return Vector3.RIGHT
		2:
			return Vector3.BACK
	return Vector3.UP
