@tool
extends RefCounted
## Builds the soft, rounded, vertex-coloured geometry of the diorama look
## (VISUAL_STYLE_GUIDE 4.1, 4.3; GDD 184.5).
##
## Every primitive is smooth-shaded with the guide's segment counts: sphere
## 12 x 6, cylinder 10, capsule 10 x 4, torus 12 x 8, a 44-triangle rounded
## slab, and a lathe that keeps profile folds sharper than 40 degrees. Each
## part takes the current `color`, so a whole model bakes into one mesh per
## material (the guide's MeshBake): pick the target with `select_surface`.
##
## Triangles are wound from their vertex normals, so a part can never come
## out inside-out. With skinning enabled every vertex is bound rigidly to one
## bone or blended along a spine, the same way rig_builder clips expect.

const EPSILON := 0.0000001
const SPHERE_SEGMENTS := 12
const SPHERE_RINGS := 6
const CYLINDER_SEGMENTS := 10
const CAPSULE_SEGMENTS := 10
const CAPSULE_RINGS := 4
const TORUS_RINGS := 12
const TORUS_SEGMENTS := 8
const LATHE_MAX_SEGMENTS := 32
const CREASE_DEG := 40.0
const DEFAULT_SURFACE := "solid"

## Colour of the parts added next.
var color: Color = Color.WHITE
## Optional per-vertex colour rule: func(model_position: Vector3, base: Color) -> Color.
var color_rule: Callable = Callable()
## Placement of the parts added next (model space).
var transform: Transform3D = Transform3D.IDENTITY:
	set(value):
		transform = value
		var determinant := value.basis.determinant()
		_normal_basis = value.basis.inverse().transposed() if absf(determinant) > EPSILON else Basis.IDENTITY


class Surface:
	extends RefCounted
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()


var _normal_basis: Basis = Basis.IDENTITY
var _surfaces: Dictionary = {}
var _order: PackedStringArray = PackedStringArray()
var _surface: Surface

var _skinned: bool = false
var _rigid_bone: int = 0
var _spine_bones := PackedInt32Array()
var _spine_stops := PackedFloat32Array()
var _spine_axis: Vector3 = Vector3.RIGHT


func _init() -> void:
	select_surface(DEFAULT_SURFACE)


## Sends the parts added next to the surface `key` (one surface per material).
func select_surface(key: String) -> void:
	if not _surfaces.has(key):
		_surfaces[key] = Surface.new()
		_order.append(key)
	_surface = _surfaces[key]


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

## Ellipsoid (heads, round bread, knobs). 12 x 6 gives 120 triangles.
## `jitter` wobbles the radius per vertex for bushes and stones.
func sphere(centre: Vector3, radii: Vector3, segments: int = SPHERE_SEGMENTS, rings: int = SPHERE_RINGS, jitter: float = 0.0, jitter_seed: int = 0) -> void:
	var noise := RandomNumberGenerator.new()
	noise.seed = jitter_seed
	var north := _vertex(centre + Vector3(0.0, radii.y, 0.0), Vector3.UP)
	var south := _vertex(centre - Vector3(0.0, radii.y, 0.0), Vector3.DOWN)
	var rows: Array[PackedInt32Array] = []
	for ring: int in range(1, rings):
		var latitude := PI * 0.5 - PI * float(ring) / float(rings)
		var row := PackedInt32Array()
		for segment: int in segments:
			var longitude := TAU * float(segment) / float(segments)
			var unit := Vector3(cos(longitude) * cos(latitude), sin(latitude), sin(longitude) * cos(latitude))
			var wobble := 1.0 + (noise.randf_range(-jitter, jitter) if jitter > 0.0 else 0.0)
			var normal := Vector3(unit.x / maxf(radii.x, EPSILON), unit.y / maxf(radii.y, EPSILON), unit.z / maxf(radii.z, EPSILON))
			row.append(_vertex(centre + unit * radii * wobble, normal))
		rows.append(row)
	for segment: int in segments:
		var next := (segment + 1) % segments
		_tri(north, rows[0][segment], rows[0][next])
		_tri(south, rows[rows.size() - 1][next], rows[rows.size() - 1][segment])
	for index: int in rows.size() - 1:
		_strip(rows[index], rows[index + 1], true)


## A profile spun around the Y axis of `frame` (bowls, domes, bells, bodies).
## `profile` is (radius, height) from bottom to top; a radius of 0 closes the
## end. Folds under `crease_deg` are smoothed, sharper ones stay crisp.
func lathe(profile: PackedVector2Array, segments: int = 16, frame: Transform3D = Transform3D.IDENTITY, crease_deg: float = CREASE_DEG) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in profile:
		if points.is_empty() or points[points.size() - 1].distance_to(point) > 0.00001:
			points.append(Vector2(maxf(point.x, 0.0), point.y))
	if points.size() < 2:
		return
	segments = clampi(segments, 3, LATHE_MAX_SEGMENTS)
	var count := points.size()
	var directions: Array[Vector2] = []
	var segment_normals: Array[Vector2] = []
	for index: int in count - 1:
		var direction := (points[index + 1] - points[index]).normalized()
		directions.append(direction)
		segment_normals.append(Vector2(direction.y, -direction.x))

	var frame_normals := frame.basis.inverse().transposed()
	var start_rings: Array = []
	var end_rings: Array = []
	for index: int in count:
		var end_normal: Vector2
		var start_normal: Vector2
		var shared := true
		if index == 0:
			start_normal = segment_normals[0]
			end_normal = start_normal
		elif index == count - 1:
			end_normal = segment_normals[index - 1]
			start_normal = end_normal
		else:
			var turn := absf(rad_to_deg(directions[index - 1].angle_to(directions[index])))
			if turn < crease_deg:
				start_normal = (segment_normals[index - 1] + segment_normals[index]).normalized()
				end_normal = start_normal
			else:
				end_normal = segment_normals[index - 1]
				start_normal = segment_normals[index]
				shared = false
		var start_ring := _lathe_ring(points[index], start_normal, segments, frame, frame_normals)
		start_rings.append(start_ring)
		end_rings.append(start_ring if shared else _lathe_ring(points[index], end_normal, segments, frame, frame_normals))

	for index: int in count - 1:
		var lower: PackedInt32Array = start_rings[index]
		var upper: PackedInt32Array = end_rings[index + 1]
		if lower.size() == 1 and upper.size() == 1:
			continue
		if lower.size() == 1:
			for segment: int in segments:
				_tri(lower[0], upper[segment], upper[(segment + 1) % segments])
		elif upper.size() == 1:
			for segment: int in segments:
				_tri(upper[0], lower[(segment + 1) % segments], lower[segment])
		else:
			_strip(lower, upper, true)


## Pill between two points (limbs, bodies, baguettes). 10 x 4 is ~160 triangles.
func capsule(from: Vector3, to: Vector3, radius_from: float, radius_to: float = -1.0, segments: int = CAPSULE_SEGMENTS, rings: int = CAPSULE_RINGS) -> void:
	if radius_to < 0.0:
		radius_to = radius_from
	var axis := to - from
	var length := axis.length()
	if length < EPSILON:
		sphere(from, Vector3.ONE * radius_from, segments, rings * 2)
		return
	var profile := PackedVector2Array()
	for step: int in rings + 1:
		var angle := -PI * 0.5 + PI * 0.5 * float(step) / float(rings)
		profile.append(Vector2(cos(angle) * radius_from, sin(angle) * radius_from))
	for step: int in rings + 1:
		var angle := PI * 0.5 * float(step) / float(rings)
		profile.append(Vector2(cos(angle) * radius_to, length + sin(angle) * radius_to))
	lathe(profile, segments, _frame_along(from, axis / length))


## Straight or tapered rod with flat ends (table legs, poles, posts).
func cylinder(from: Vector3, to: Vector3, radius_from: float, radius_to: float = -1.0, segments: int = CYLINDER_SEGMENTS, cap_from: bool = true, cap_to: bool = true) -> void:
	if radius_to < 0.0:
		radius_to = radius_from
	var axis := to - from
	var length := axis.length()
	if length < EPSILON:
		return
	var profile := PackedVector2Array()
	if cap_from:
		profile.append(Vector2(0.0, 0.0))
	profile.append(Vector2(radius_from, 0.0))
	profile.append(Vector2(radius_to, length))
	if cap_to:
		profile.append(Vector2(0.0, length))
	lathe(profile, segments, _frame_along(from, axis / length))


func cone(base: Vector3, tip: Vector3, radius: float, segments: int = CYLINDER_SEGMENTS) -> void:
	var axis := tip - base
	var length := axis.length()
	if length < EPSILON:
		return
	lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(radius, 0.0), Vector2(0.0, length)]), segments, _frame_along(base, axis / length))


## Ring (rims, handles, tyres, a smiling mouth when `arc` is less than TAU).
func torus(centre: Vector3, axis: Vector3, major: float, minor: float, rings: int = TORUS_RINGS, segments: int = TORUS_SEGMENTS, arc_from: float = 0.0, arc_to: float = TAU) -> void:
	var basis := _basis_for_axis(axis.normalized())
	var closed := is_equal_approx(arc_to - arc_from, TAU)
	var columns := rings if closed else rings + 1
	var rows: Array[PackedInt32Array] = []
	for column: int in columns:
		var u := lerpf(arc_from, arc_to, float(column) / float(rings))
		var row := PackedInt32Array()
		for segment: int in segments:
			var v := TAU * float(segment) / float(segments)
			var normal := Vector3(cos(v) * cos(u), sin(v), cos(v) * sin(u))
			var point := Vector3((major + minor * cos(v)) * cos(u), minor * sin(v), (major + minor * cos(v)) * sin(u))
			row.append(_vertex(centre + basis * point, basis * normal))
		rows.append(row)
	for column: int in rows.size() - 1:
		_strip(rows[column], rows[column + 1], true)
	if closed:
		_strip(rows[rows.size() - 1], rows[0], true)
	else:
		# Round the two open ends.
		for end: float in [arc_from, arc_to]:
			sphere(centre + basis * Vector3(major * cos(end), 0.0, major * sin(end)), Vector3.ONE * minor, 8, 4)


## A box with all twelve edges trimmed by `bevel` (guide 4.1): flat faces,
## softened edge bands and corners, 44 triangles. The backbone of furniture.
func rounded_slab(size: Vector3, centre: Vector3 = Vector3.ZERO, bevel: float = 0.02) -> void:
	var half := size * 0.5
	bevel = minf(bevel, 0.9 * minf(half.x, minf(half.y, half.z)))
	var inner := half - Vector3.ONE * bevel
	# 24 vertices: one per (face, corner). Each carries its face's normal, so
	# faces stay flat while bands and corners blend between them.
	var ids: Dictionary = {}
	for axis: int in 3:
		for sign_value: float in [-1.0, 1.0]:
			var normal := Vector3.ZERO
			normal[axis] = sign_value
			var other_u := (axis + 1) % 3
			var other_v := (axis + 2) % 3
			for su: float in [-1.0, 1.0]:
				for sv: float in [-1.0, 1.0]:
					var point := centre
					point[axis] += sign_value * half[axis]
					point[other_u] += su * inner[other_u]
					point[other_v] += sv * inner[other_v]
					var signs := Vector3.ZERO
					signs[axis] = sign_value
					signs[other_u] = su
					signs[other_v] = sv
					ids[_slab_key(axis, signs)] = _vertex(point, normal)
	# Faces.
	for axis: int in 3:
		var other_u := (axis + 1) % 3
		var other_v := (axis + 2) % 3
		for sign_value: float in [-1.0, 1.0]:
			var corners: Array[int] = []
			for pair: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var signs := Vector3.ZERO
				signs[axis] = sign_value
				signs[other_u] = pair.x
				signs[other_v] = pair.y
				corners.append(ids[_slab_key(axis, signs)])
			_quad(corners[0], corners[1], corners[2], corners[3])
	# Edge bands: between face A (axis a) and face B (axis b) along axis c.
	for a: int in 3:
		for b: int in range(a + 1, 3):
			var c := 3 - a - b
			for sa: float in [-1.0, 1.0]:
				for sb: float in [-1.0, 1.0]:
					var low := Vector3.ZERO
					low[a] = sa
					low[b] = sb
					low[c] = -1.0
					var high := low
					high[c] = 1.0
					_quad(ids[_slab_key(a, low)], ids[_slab_key(a, high)], ids[_slab_key(b, high)], ids[_slab_key(b, low)])
	# Corners.
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				var signs := Vector3(sx, sy, sz)
				_tri(ids[_slab_key(0, signs)], ids[_slab_key(1, signs)], ids[_slab_key(2, signs)])


## A flat outline (XY plane) given thickness along Z with a soft, rounded rim:
## fins, signs, leaves, sandal soles. Never paper-thin (guide 4.2).
func puffy_outline(outline: PackedVector2Array, thickness: float, z_centre: float = 0.0) -> void:
	var count := outline.size()
	if count < 3:
		return
	var area := 0.0
	for index: int in count:
		var a := outline[index]
		var b := outline[(index + 1) % count]
		area += a.x * b.y - b.x * a.y
	var winding := 1.0 if area > 0.0 else -1.0
	var outward := PackedVector2Array()
	for index: int in count:
		var previous := outline[(index - 1 + count) % count]
		var here := outline[index]
		var next := outline[(index + 1) % count]
		var edge_in := (here - previous).normalized()
		var edge_out := (next - here).normalized()
		var normal_in := Vector2(edge_in.y, -edge_in.x) * winding
		var normal_out := Vector2(edge_out.y, -edge_out.x) * winding
		outward.append((normal_in + normal_out).normalized())
	var half := thickness * 0.5
	var rim := half * 0.9
	# Five rings round the rim from the front face to the back face.
	var ring_specs: Array = [[1.0, 1.0, 0.0], [0.72, 0.3, 0.7], [0.0, 0.0, 1.0], [-0.72, 0.3, 0.7], [-1.0, 1.0, 0.0]]
	var rings: Array[PackedInt32Array] = []
	for spec: Array in ring_specs:
		var row := PackedInt32Array()
		var z_side: float = spec[0]
		var inset: float = spec[1]
		var spread: float = spec[2]
		for index: int in count:
			var flat := outline[index] - outward[index] * rim * inset
			var normal := Vector3(outward[index].x * spread, outward[index].y * spread, z_side * (1.0 - spread * 0.3))
			row.append(_vertex(Vector3(flat.x, flat.y, z_centre + half * z_side), normal))
		rings.append(row)
	for index: int in rings.size() - 1:
		_strip(rings[index], rings[index + 1], true)
	var caps := Geometry2D.triangulate_polygon(_inset(outline, outward, rim))
	for face: int in 2:
		var row := rings[0] if face == 0 else rings[rings.size() - 1]
		for index: int in range(0, caps.size(), 3):
			_tri(row[caps[index]], row[caps[index + 1]], row[caps[index + 2]])


## Flat horizontal disc whose colour fades from `inner` to `outer`, ignoring
## `color` (fake shadows, water patches, rugs).
func disc(centre: Vector3, radius: float, segments: int, inner: Color, outer: Color, rings: int = 1) -> void:
	var middle := _vertex_colored(centre, Vector3.UP, inner)
	var previous := PackedInt32Array()
	for ring: int in range(1, rings + 1):
		var row := PackedInt32Array()
		var fraction := float(ring) / float(rings)
		for segment: int in segments:
			var angle := TAU * float(segment) / float(segments)
			var point := centre + Vector3(cos(angle), 0.0, sin(angle)) * radius * fraction
			row.append(_vertex_colored(point, Vector3.UP, inner.lerp(outer, fraction)))
		if ring == 1:
			for segment: int in segments:
				_tri(middle, row[segment], row[(segment + 1) % segments])
		else:
			_strip(previous, row, true)
		previous = row


## A flat quad with one normal (floor tiles, wall panels, curtain squares).
func flat_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (c - a).cross(b - a)
	if normal.length_squared() < EPSILON:
		return
	normal = normal.normalized()
	_quad(_vertex(a, normal), _vertex(b, normal), _vertex(c, normal), _vertex(d, normal))


## Smooth open surface over a grid of points (terrain, banks, cloth).
## Normals are oriented toward `up_hint`.
func grid(rows: Array, up_hint: Vector3 = Vector3.UP) -> void:
	var height := rows.size()
	if height < 2:
		return
	var width := (rows[0] as PackedVector3Array).size()
	var ids: Array[PackedInt32Array] = []
	for row_index: int in height:
		var row: PackedVector3Array = rows[row_index]
		var id_row := PackedInt32Array()
		for column: int in width:
			var left := row[maxi(column - 1, 0)]
			var right := row[mini(column + 1, width - 1)]
			var up_row: PackedVector3Array = rows[maxi(row_index - 1, 0)]
			var down_row: PackedVector3Array = rows[mini(row_index + 1, height - 1)]
			var normal := (right - left).cross(down_row[column] - up_row[column])
			if normal.dot(up_hint) < 0.0:
				normal = -normal
			id_row.append(_vertex(row[column], normal if normal.length_squared() > EPSILON else up_hint))
		ids.append(id_row)
	for row_index: int in height - 1:
		_strip(ids[row_index], ids[row_index + 1], false)


## Smooth skin over closed rings with the same point count (fish bodies).
## Optional poles close the ends; normals point away from each ring's centre.
func loft(rings: Array, start_pole: Variant = null, end_pole: Variant = null) -> void:
	var count := rings.size()
	if count < 2:
		return
	var points := (rings[0] as PackedVector3Array).size()
	var centres: Array[Vector3] = []
	for ring: PackedVector3Array in rings:
		centres.append(_centroid(ring))
	var ids: Array[PackedInt32Array] = []
	for index: int in count:
		var ring: PackedVector3Array = rings[index]
		var before: PackedVector3Array = rings[maxi(index - 1, 0)]
		var after: PackedVector3Array = rings[mini(index + 1, count - 1)]
		var row := PackedInt32Array()
		for point: int in points:
			var around := ring[(point + 1) % points] - ring[(point - 1 + points) % points]
			var along := after[point] - before[point]
			var normal := around.cross(along)
			if normal.dot(ring[point] - centres[index]) < 0.0:
				normal = -normal
			if normal.length_squared() < EPSILON:
				normal = ring[point] - centres[index]
			row.append(_vertex(ring[point], normal))
		ids.append(row)
	for index: int in count - 1:
		_strip(ids[index], ids[index + 1], true)
	if start_pole != null:
		var pole := _vertex(start_pole, (start_pole as Vector3) - centres[0])
		for point: int in points:
			_tri(pole, ids[0][(point + 1) % points], ids[0][point])
	if end_pole != null:
		var pole := _vertex(end_pole, (end_pole as Vector3) - centres[count - 1])
		for point: int in points:
			_tri(pole, ids[count - 1][point], ids[count - 1][(point + 1) % points])


## A closed loop of points on a superellipse; `squareness` 2 is an ellipse.
func ring(centre: Vector3, half_u: Vector3, half_v: Vector3, segments: int, squareness: float = 2.0) -> PackedVector3Array:
	var points := PackedVector3Array()
	var exponent := 2.0 / maxf(squareness, 0.1)
	for index: int in segments:
		var angle := TAU * float(index) / float(segments)
		var cu := cos(angle)
		var su := sin(angle)
		points.append(centre + half_u * signf(cu) * pow(absf(cu), exponent) + half_v * signf(su) * pow(absf(su), exponent))
	return points


# --- Output -----------------------------------------------------------------

func get_triangle_count() -> int:
	var total := 0
	for key: String in _order:
		total += (_surfaces[key] as Surface).indices.size() / 3
	return total


func is_empty() -> bool:
	return get_triangle_count() == 0


## One surface per material key, in the order they were first selected.
func commit(materials: Dictionary = {}) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for key: String in _order:
		var surface: Surface = _surfaces[key]
		if surface.indices.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = surface.vertices
		arrays[Mesh.ARRAY_NORMAL] = surface.normals
		arrays[Mesh.ARRAY_COLOR] = surface.colors
		arrays[Mesh.ARRAY_INDEX] = surface.indices
		if _skinned:
			arrays[Mesh.ARRAY_BONES] = surface.bones
			arrays[Mesh.ARRAY_WEIGHTS] = surface.weights
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var index := mesh.get_surface_count() - 1
		mesh.surface_set_name(index, key)
		if materials.has(key):
			mesh.surface_set_material(index, materials[key])
	return mesh


# --- Internals --------------------------------------------------------------

func _vertex(point: Vector3, normal: Vector3) -> int:
	var placed := transform * point
	return _push(placed, normal, color_rule.call(placed, color) if color_rule.is_valid() else color)


func _vertex_colored(point: Vector3, normal: Vector3, tint: Color) -> int:
	return _push(transform * point, normal, tint)


func _push(placed: Vector3, normal: Vector3, tint: Color) -> int:
	var turned := _normal_basis * normal
	turned = turned.normalized() if turned.length_squared() > EPSILON else Vector3.UP
	_surface.vertices.append(placed)
	_surface.normals.append(turned)
	_surface.colors.append(tint)
	if _skinned:
		_append_skin(placed)
	return _surface.vertices.size() - 1


## Adds a triangle wound so its face agrees with its vertex normals.
func _tri(a: int, b: int, c: int) -> void:
	var vertices := _surface.vertices
	var face := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
	if face.length_squared() < 1e-18:
		return
	var reference := _surface.normals[a] + _surface.normals[b] + _surface.normals[c]
	if face.dot(reference) < 0.0:
		_surface.indices.append_array(PackedInt32Array([a, c, b]))
	else:
		_surface.indices.append_array(PackedInt32Array([a, b, c]))


func _quad(a: int, b: int, c: int, d: int) -> void:
	_tri(a, b, c)
	_tri(a, c, d)


func _strip(lower: PackedInt32Array, upper: PackedInt32Array, closed: bool) -> void:
	var count := mini(lower.size(), upper.size())
	var last := count if closed else count - 1
	for index: int in last:
		var next := (index + 1) % count
		_quad(lower[index], lower[next], upper[next], upper[index])


func _lathe_ring(point: Vector2, normal: Vector2, segments: int, frame: Transform3D, frame_normals: Basis) -> PackedInt32Array:
	if point.x < 0.00001:
		var pole_normal := Vector3(0.0, signf(normal.y) if absf(normal.y) > 0.001 else 1.0, 0.0)
		return PackedInt32Array([_vertex(frame * Vector3(0.0, point.y, 0.0), frame_normals * pole_normal)])
	var row := PackedInt32Array()
	for segment: int in segments:
		var angle := TAU * float(segment) / float(segments)
		var c := cos(angle)
		var s := sin(angle)
		row.append(_vertex(frame * Vector3(point.x * c, point.y, point.x * s), frame_normals * Vector3(normal.x * c, normal.y, normal.x * s)))
	return row


func _slab_key(axis: int, signs: Vector3) -> String:
	return "%d:%d:%d:%d" % [axis, int(signs.x), int(signs.y), int(signs.z)]


func _inset(outline: PackedVector2Array, outward: PackedVector2Array, distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index: int in outline.size():
		result.append(outline[index] - outward[index] * distance)
	return result


func _append_skin(point: Vector3) -> void:
	if _spine_bones.is_empty():
		_surface.bones.append_array(PackedInt32Array([_rigid_bone, 0, 0, 0]))
		_surface.weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		return
	var along := point.dot(_spine_axis)
	var last := _spine_stops.size() - 1
	if along <= _spine_stops[0]:
		_surface.bones.append_array(PackedInt32Array([_spine_bones[0], 0, 0, 0]))
		_surface.weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		return
	if along >= _spine_stops[last]:
		_surface.bones.append_array(PackedInt32Array([_spine_bones[last], 0, 0, 0]))
		_surface.weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
		return
	for index: int in last:
		if along <= _spine_stops[index + 1]:
			var blend := inverse_lerp(_spine_stops[index], _spine_stops[index + 1], along)
			_surface.bones.append_array(PackedInt32Array([_spine_bones[index], _spine_bones[index + 1], 0, 0]))
			_surface.weights.append_array(PackedFloat32Array([1.0 - blend, blend, 0.0, 0.0]))
			return


func _centroid(points: PackedVector3Array) -> Vector3:
	var total := Vector3.ZERO
	for point: Vector3 in points:
		total += point
	return total / float(maxi(points.size(), 1))


## A frame whose origin is `origin` and whose Y axis is `axis` (unit length).
func _frame_along(origin: Vector3, axis: Vector3) -> Transform3D:
	return Transform3D(_basis_for_axis(axis), origin)


func _basis_for_axis(axis: Vector3) -> Basis:
	var helper := Vector3.FORWARD if absf(axis.dot(Vector3.FORWARD)) < 0.95 else Vector3.RIGHT
	var x := axis.cross(helper).normalized()
	var z := x.cross(axis).normalized()
	return Basis(x, axis, z)
