class_name SpotSet
extends RefCounted
## Puts the right fishing spot on stage (revision 6.7). The fishing and result
## scenes are built around Cempaka Lake's set; at another spot that set is
## swapped for the spot's own, which carries the same markers (DartoSpot,
## FloatSpot, BucketSpot, CameraFocus, ResultFocus).


## Replaces `current` (a set already in the tree) with the set of
## `location_id`, keeping its name and place among its siblings. Returns the
## set now on stage: `current` itself for Cempaka Lake or an unknown spot.
static func swap_in(current: Node3D, location_id: StringName) -> Node3D:
	if location_id == ContentIds.START_LOCATION:
		return current
	var location := GameData.get_location(location_id)
	if location == null or location.set_scene == null:
		return current
	var replacement := location.set_scene.instantiate() as Node3D
	if replacement == null:
		return current
	var parent := current.get_parent()
	var index := current.get_index()
	var set_name := current.name
	parent.remove_child(current)
	current.queue_free()
	replacement.name = set_name
	parent.add_child(replacement)
	parent.move_child(replacement, index)
	return replacement
