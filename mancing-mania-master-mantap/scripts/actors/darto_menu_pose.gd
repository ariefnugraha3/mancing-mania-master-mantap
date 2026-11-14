extends Node3D
## Darto as he appears behind the Main Menu (GDD 84, 168.2): standing at his
## spot by the lake with the rod in hand, small in the frame.

const HAND_BONE := "hand_r"

@onready var _rig: Node3D = $Rig
@onready var _rod: Node3D = $Rod

var _skeleton: Skeleton3D
var _hand_bone: int = -1


func _ready() -> void:
	_skeleton = _rig.get_node("Skeleton3D")
	_hand_bone = _skeleton.find_bone(HAND_BONE)
	(_rig.get_node("AnimationPlayer") as AnimationPlayer).play(&"idle_fishing")


func _process(_delta: float) -> void:
	if _hand_bone >= 0:
		_rod.global_transform = _skeleton.global_transform * _skeleton.get_bone_global_pose(_hand_bone) * FishingWorld.ROD_GRIP
