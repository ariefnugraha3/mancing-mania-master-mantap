@tool
extends RefCounted
## Skeleton and animation-clip helpers shared by the character and fish
## builders (GDD 184.6, 184.7, 184.13).
##
## Bones are declared with model-space joint positions and no rest rotation,
## so a pose rotation is simply "how far this joint is turned".


## Builds a Skeleton3D from rows of [bone_name, parent_name, model_position].
## Parents must be listed before their children; the root has parent "".
static func make_skeleton(bones: Array) -> Skeleton3D:
	var skeleton := Skeleton3D.new()
	skeleton.name = "Skeleton3D"
	var model_positions: Dictionary[String, Vector3] = {}
	for row: Array in bones:
		var bone_name: String = row[0]
		var parent_name: String = row[1]
		var position: Vector3 = row[2]
		var index := skeleton.add_bone(bone_name)
		var local := position
		if parent_name != "":
			skeleton.set_bone_parent(index, skeleton.find_bone(parent_name))
			local = position - model_positions[parent_name]
		model_positions[bone_name] = position
		skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, local))
	skeleton.reset_bone_poses()
	return skeleton


## Creates an AnimationPlayer holding `clips` in its default library.
static func make_player(clips: Array) -> AnimationPlayer:
	var library := AnimationLibrary.new()
	for clip: Clip in clips:
		library.add_animation(clip.clip_name, clip.build())
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	player.add_animation_library(&"", library)
	return player


## One animation clip described as keyed joint angles.
class Clip:
	extends RefCounted

	var clip_name: StringName
	var _skeleton: Skeleton3D
	var _animation: Animation
	var _tracks: Dictionary[String, int] = {}

	func _init(skeleton: Skeleton3D, name: StringName, length: float, loop: bool = false) -> void:
		clip_name = name
		_skeleton = skeleton
		_animation = Animation.new()
		_animation.length = length
		_animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE

	## Keys a joint rotation in degrees (X pitch, Y yaw, Z roll).
	func rot(bone: String, time: float, degrees: Vector3) -> Clip:
		var track := _track("rot:" + bone, Animation.TYPE_ROTATION_3D, bone)
		var radians := Vector3(deg_to_rad(degrees.x), deg_to_rad(degrees.y), deg_to_rad(degrees.z))
		_animation.rotation_track_insert_key(track, time, Quaternion.from_euler(radians))
		return self

	## Keys a joint offset from its rest position, in metres.
	func move(bone: String, time: float, offset: Vector3) -> Clip:
		var track := _track("pos:" + bone, Animation.TYPE_POSITION_3D, bone)
		var rest := _skeleton.get_bone_rest(_skeleton.find_bone(bone)).origin
		_animation.position_track_insert_key(track, time, rest + offset)
		return self

	## Keys the same rotation at several times (holds, or loop start/end).
	func hold(bone: String, times: Array, degrees: Vector3) -> Clip:
		for time: float in times:
			rot(bone, time, degrees)
		return self

	## Names a moment in the clip, e.g. `release_float` (GDD 172.1).
	func mark(marker: StringName, time: float) -> Clip:
		_animation.add_marker(marker, time)
		return self

	func build() -> Animation:
		return _animation

	func _track(key: String, type: Animation.TrackType, bone: String) -> int:
		if _tracks.has(key):
			return _tracks[key]
		if _skeleton.find_bone(bone) < 0:
			push_error("rig_builder: clip '%s' keys unknown bone '%s'" % [clip_name, bone])
		var track := _animation.add_track(type)
		_animation.track_set_path(track, NodePath("Skeleton3D:%s" % bone))
		_animation.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		_tracks[key] = track
		return track
