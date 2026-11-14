class_name ScatterField
extends MultiMeshInstance3D
## Draws many copies of one small mesh (grass, reeds) in a single draw call
## (GDD 101, 127, 174.6).
##
## The generator stores only the cluster mesh and the placements; the MultiMesh
## itself is assembled when the node enters the scene. A MultiMesh keeps its
## instance data on the graphics device, so it cannot be written by the
## headless asset generator.

const FLOATS_PER_INSTANCE := 12

@export var cluster_mesh: Mesh
## Twelve numbers per instance: the three rows of its 3x4 transform.
@export var placements: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	if cluster_mesh == null or placements.size() < FLOATS_PER_INSTANCE:
		multimesh = null
		return
	var field := MultiMesh.new()
	field.transform_format = MultiMesh.TRANSFORM_3D
	field.mesh = cluster_mesh
	field.instance_count = placements.size() / FLOATS_PER_INSTANCE
	field.buffer = placements
	multimesh = field


func get_instance_count() -> int:
	return placements.size() / FLOATS_PER_INSTANCE


## Packs a transform in the row order MultiMesh expects.
static func pack_transform(target: PackedFloat32Array, transform: Transform3D) -> void:
	var basis := transform.basis
	var origin := transform.origin
	target.append_array(PackedFloat32Array([
		basis.x.x, basis.y.x, basis.z.x, origin.x,
		basis.x.y, basis.y.y, basis.z.y, origin.y,
		basis.x.z, basis.y.z, basis.z.z, origin.z,
	]))
