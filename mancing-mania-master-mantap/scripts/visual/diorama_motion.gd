class_name DioramaMotion
extends RefCounted
## Squash and stretch for reactions (VISUAL_STYLE_GUIDE 10): a quick change
## of shape that springs back to the original size with a slight overshoot
## (TRANS_BACK), so things feel soft and bouncy like dough. Large motion is
## skipped when the player turns on Reduced Motion.

const META_BASE := &"diorama_motion_base"
const META_TWEEN := &"diorama_motion_tween"


## Flattens `node` for a moment (a landing, a press, a purchase).
static func squash(node: Node3D, amount: float = DioramaStyle.SQUASH_AMOUNT, seconds: float = DioramaStyle.SQUASH_SEC) -> void:
	_bounce(node, Vector3(1.0 + amount, 1.0 - amount, 1.0 + amount), seconds)


## Stretches `node` upward for a moment (happy, surprised, a jump start).
static func stretch(node: Node3D, amount: float = DioramaStyle.SQUASH_AMOUNT, seconds: float = DioramaStyle.SQUASH_SEC) -> void:
	_bounce(node, Vector3(1.0 - amount * 0.6, 1.0 + amount, 1.0 - amount * 0.6), seconds)


## Puts a node back to its resting size at once.
static func settle(node: Node3D) -> void:
	if node == null or not node.has_meta(META_BASE):
		return
	_kill(node)
	node.scale = node.get_meta(META_BASE)


static func is_reduced() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var state := tree.root.get_node_or_null("GameState")
	return state != null and bool(state.get_setting(&"reduced_motion"))


static func _bounce(node: Node3D, factor: Vector3, seconds: float) -> void:
	if node == null or not node.is_inside_tree() or is_reduced():
		return
	if not node.has_meta(META_BASE):
		node.set_meta(META_BASE, node.scale)
	var base: Vector3 = node.get_meta(META_BASE)
	_kill(node)
	node.scale = base * factor
	var tween := node.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", base, seconds)
	node.set_meta(META_TWEEN, tween)


static func _kill(node: Node3D) -> void:
	if not node.has_meta(META_TWEEN):
		return
	var previous: Variant = node.get_meta(META_TWEEN)
	if previous is Tween and (previous as Tween).is_valid():
		(previous as Tween).kill()
