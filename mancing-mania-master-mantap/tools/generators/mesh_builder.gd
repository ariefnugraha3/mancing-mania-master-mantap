@tool
extends RefCounted
## Builds flat-shaded, vertex-coloured low-poly geometry from code (GDD 184.5).
##
## Every face gets its own vertices and one normal, which gives the faceted
## modern low-poly look without any texture. Shapes are star-convex around a
## reference point, so each triangle is wound to face away from that point and
## no shape can come out inside-out.
##
## With skinning enabled every vertex is bound either rigidly to one bone or
## blended between neighbouring bones along a spine, so one mesh can carry a
## whole character.

const EPSILON := 0.0000001

## Colour applied to the faces added next.
var color: Color = Color.WHITE
## Placement applied to every point added next (model space).
var transform: Transform3D = Transform3D.IDENTITY
## Optional per-vertex colour rule: func(model_position: Vector3, base: Color) -> Color.
var color_rule: Callable = Callable()

var _vertices := PackedVector3Array()
var _normals := PackedVector3Array()
var _colors := PackedColorArray()
var _bones := PackedInt32Array()
var _weights := PackedFloat32Array()

var _skinned: bool = false
var _rigid_bone: int = 0
var _spine_bones := PackedInt32Array()
var _spine_stops := PackedFloat32Array()
var _spine_axis: Vector3 = Vector3.RIGHT


# --- Skinning ---------------------------------------------------------------

func enable_skinning() -> void:
	_skinned = true


## Binds the following geometry rigidly to one bone.
func set_bone(bone_index: int) -> void:
	_rigid_bone = bone_index
	_spine_bones = PackedInt32Array()


## Blends the following geometry between bones placed along `axis`.
## `stops[i]` is where `bones[i]` has full influence, in ascending order.
func set_spine(bones: PackedInt32Array, stops: PackedFloat32Array, axis: Vector3) -> void:
	_spine_bones = bones
	_spine_stops = stops
	_spine_axis = axis.normalized()


# --- Primitives -------------------------------------------------------------

## Adds one triangle facing away from `away_from`.
func triangle(a: Vector3, b: Vector3, c: Vector3, away_from: Vector3) -> void:
	_emit(transform * a, transform * b, transform * c, transform * away_from)


## Adds a flat four-sided face (corners in order around the face).
func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, away_from: Vector3) -> void:
	var wa := transform * a
	var wb := transform * b
	var wc := transform * c
	var wd := transform * d
	var reference := transform * away_from
	# One shared normal keeps a slightly bent quad looking like a single facet.
	var normal := (wc - wa).cross(wd - wb)
	if normal.length_squared() < EPSILON:
		return
	var centre := (wa + wb + wc + wd) * 0.25
	if normal.dot(centre - reference) < 0.0:
		normal = -normal
	normal = normal.normalized()
	_emit(wa, wb, wc, reference, normal)
	_emit(wa, wc, wd, reference, normal)


## A triangle visible from both sides (leaves, blades of grass).
func double_sided_triangle(a: Vector3, b: Vector3, c: Vector3) -> void:
	var wa := transform * a
	var wb := transform * b
	var wc := transform * c
	var normal := (wc - wa).cross(wb - wa)
	if normal.length_squared() < EPSILON:
		return
	var centre := (wa + wb + wc) / 3.0
	_emit(wa, wb, wc, centre - normal)
	_emit(wa, wb, wc, centre + normal)


## Axis-aligned box centred on `centre`.
func box(size: Vector3, centre: Vector3 = Vector3.ZERO) -> void:
	var h := size * 0.5
	var bottom := PackedVector3Array([
		centre + Vector3(-h.x, -h.y, -h.z), centre + Vector3(h.x, -h.y, -h.z),
		centre + Vector3(h.x, -h.y, h.z), centre + Vector3(-h.x, -h.y, h.z)])
	var top := PackedVector3Array([
		centre + Vector3(-h.x, h.y, -h.z), centre + Vector3(h.x, h.y, -h.z),
		centre + Vector3(h.x, h.y, h.z), centre + Vector3(-h.x, h.y, h.z)])
	loft([bottom, top], true, true)


## A closed loop of points on a superellipse. `squareness` 2 is an ellipse;
## higher values approach a rounded rectangle.
func ring(centre: Vector3, half_u: Vector3, half_v: Vector3, segments: int, squareness: float = 2.0) -> PackedVector3Array:
	var points := PackedVector3Array()
	var exponent := 2.0 / maxf(squareness, 0.1)
	for index: int in segments:
		var angle := TAU * float(index) / float(segments)
		var cu := cos(angle)
		var su := sin(angle)
		var u := signf(cu) * pow(absf(cu), exponent)
		var v := signf(su) * pow(absf(su), exponent)
		points.append(centre + half_u * u + half_v * v)
	return points


## Skins a surface over a sequence of rings with the same point count.
func loft(rings: Array, cap_start: bool = true, cap_end: bool = true) -> void:
	if rings.size() < 2:
		return
	var overall := Vector3.ZERO
	var centres: Array[Vector3] = []
	for ring_points: PackedVector3Array in rings:
		var centre := _centroid(ring_points)
		centres.append(centre)
		overall += centre
	overall /= float(rings.size())

	for index: int in rings.size() - 1:
		var lower: PackedVector3Array = rings[index]
		var upper: PackedVector3Array = rings[index + 1]
		var inside := (centres[index] + centres[index + 1]) * 0.5
		var count := lower.size()
		for point: int in count:
			var next := (point + 1) % count
			quad(lower[point], lower[next], upper[next], upper[point], inside)

	if cap_start:
		_cap(rings[0], centres[0], overall)
	if cap_end:
		_cap(rings[rings.size() - 1], centres[rings.size() - 1], overall)


## Straight tapered tube between two points (trunks, limbs, poles).
func tube(from: Vector3, to: Vector3, radius_from: float, radius_to: float, segments: int = 6, capped: bool = true) -> void:
	var axis := to - from
	if axis.length_squared() < EPSILON:
		return
	var basis := _basis_for_axis(axis.normalized())
	var first := ring(from, basis.x * radius_from, basis.z * radius_from, segments)
	var last := ring(to, basis.x * radius_to, basis.z * radius_to, segments)
	loft([first, last], capped, capped)


## Faceted ellipsoid (foliage clumps, heads, stones).
func blob(centre: Vector3, radii: Vector3, segments: int = 7, bands: int = 4, jitter: float = 0.0, jitter_seed: int = 0) -> void:
	var noise := RandomNumberGenerator.new()
	noise.seed = jitter_seed
	var rings: Array = []
	for band: int in range(1, bands):
		var latitude := PI * float(band) / float(bands) - PI * 0.5
		var radius := cos(latitude)
		var height := sin(latitude)
		var points := PackedVector3Array()
		for segment: int in segments:
			var angle := TAU * (float(segment) + 0.5 * float(band % 2)) / float(segments)
			var wobble := 1.0 + noise.randf_range(-jitter, jitter)
			points.append(centre + Vector3(cos(angle) * radius * radii.x, height * radii.y, sin(angle) * radius * radii.z) * wobble)
		rings.append(points)
	loft(rings, false, false)
	# Close the poles with fans that meet in a point.
	var bottom: PackedVector3Array = rings[0]
	var top: PackedVector3Array = rings[rings.size() - 1]
	var south := centre - Vector3(0.0, radii.y, 0.0)
	var north := centre + Vector3(0.0, radii.y, 0.0)
	for point: int in segments:
		var next := (point + 1) % segments
		triangle(bottom[point], bottom[next], south, centre)
		triangle(top[point], top[next], north, centre)


## Extrudes a flat outline into a thin slab (fins, brims, signs).
## `outline` is in the XY plane; the slab is `thickness` deep along Z.
func slab(outline: PackedVector2Array, thickness: float, z_centre: float = 0.0) -> void:
	if outline.size() < 3:
		return
	var front := PackedVector3Array()
	var back := PackedVector3Array()
	for point: Vector2 in outline:
		front.append(Vector3(point.x, point.y, z_centre + thickness * 0.5))
		back.append(Vector3(point.x, point.y, z_centre - thickness * 0.5))
	var middle := (_centroid(front) + _centroid(back)) * 0.5
	var indices := Geometry2D.triangulate_polygon(outline)
	for index: int in range(0, indices.size(), 3):
		triangle(front[indices[index]], front[indices[index + 1]], front[indices[index + 2]], middle)
		triangle(back[indices[index]], back[indices[index + 1]], back[indices[index + 2]], middle)
	for point: int in outline.size():
		var next := (point + 1) % outline.size()
		quad(back[point], back[next], front[next], front[point], middle)


# --- Output -----------------------------------------------------------------

func get_triangle_count() -> int:
	return _vertices.size() / 3


func is_empty() -> bool:
	return _vertices.is_empty()


func commit() -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_COLOR] = _colors
	if _skinned:
		arrays[Mesh.ARRAY_BONES] = _bones
		arrays[Mesh.ARRAY_WEIGHTS] = _weights
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# --- Internals --------------------------------------------------------------

## Points are already in model space here.
func _emit(a: Vector3, b: Vector3, c: Vector3, reference: Vector3, shared_normal: Vector3 = Vector3.ZERO) -> void:
	# Godot front faces wind clockwise: the outward normal is (c - a) x (b - a).
	var normal := (c - a).cross(b - a)
	if normal.length_squared() < EPSILON:
		return
	var centre := (a + b + c) / 3.0
	if normal.dot(centre - reference) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	normal = shared_normal if shared_normal != Vector3.ZERO else normal.normalized()
	for point: Vector3 in [a, b, c]:
		_vertices.append(point)
		_normals.append(normal)
		_colors.append(color_rule.call(point, color) if color_rule.is_valid() else color)
		if _skinned:
			_append_skin(point)


func _append_skin(point: Vector3) -> void:
	if _spine_bones.is_empty():
		_bones.append_array(PackedInt32Array([_rigid_bone, 0, 0, 0]))
		_weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		return
	var along := point.dot(_spine_axis)
	var last := _spine_stops.size() - 1
	if along <= _spine_stops[0]:
		_bones.append_array(PackedInt32Array([_spine_bones[0], 0, 0, 0]))
		_weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		return
	if along >= _spine_stops[last]:
		_bones.append_array(PackedInt32Array([_spine_bones[last], 0, 0, 0]))
		_weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		return
	for index: int in last:
		if along <= _spine_stops[index + 1]:
			var blend := inverse_lerp(_spine_stops[index], _spine_stops[index + 1], along)
			_bones.append_array(PackedInt32Array([_spine_bones[index], _spine_bones[index + 1], 0, 0]))
			_weights.append_array(PackedFloat32Array([1.0 - blend, blend, 0.0, 0.0]))
			return


func _cap(points: PackedVector3Array, centre: Vector3, away_from: Vector3) -> void:
	for point: int in points.size():
		var next := (point + 1) % points.size()
		triangle(points[point], points[next], centre, away_from)


func _centroid(points: PackedVector3Array) -> Vector3:
	var total := Vector3.ZERO
	for point: Vector3 in points:
		total += point
	return total / float(maxi(points.size(), 1))


## A basis whose Y axis is `axis`.
func _basis_for_axis(axis: Vector3) -> Basis:
	var helper := Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var x := helper.cross(axis).normalized()
	var z := axis.cross(x).normalized()
	return Basis(x, axis, z)
