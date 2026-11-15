extends SpotDuelScene
## Root of tambang.tscn. PULL (Space, or the big button) in the green zone.

var _tambang: TambangController
var _tambang_world: TambangWorld


func _connect_duel() -> void:
	_tambang = _controller as TambangController
	_tambang_world = _world as TambangWorld
	(_hud as TambangHud).setup(_fish)
	_tambang.pulled.connect(_on_pulled)
	_tambang.slipped.connect(_on_slipped)
	_tambang.heave_started.connect(_tambang_world.show_heave)


func _read_input() -> void:
	if InputManager.consume_action_once(&"arm_mash"):
		_tambang.pull()


## The QA bot pulls when the marker is near the zone's centre.
func _play_bot(_delta: float) -> void:
	var snapshot := _tambang.get_snapshot()
	if snapshot["state"] != TambangController.STATE_PULL or snapshot["zone_spent"] or snapshot["stunned"]:
		return
	if absf(float(snapshot["marker"]) - TambangController.ZONE_CENTRE) <= float(snapshot["zone_half"]) * 0.3:
		_tambang.pull()


func _update_world(snapshot: Dictionary) -> void:
	if snapshot.has("rope"):
		_tambang_world.set_rope(float(snapshot["rope"]))


func _on_pulled(quality: StringName) -> void:
	_tambang_world.show_pull(quality == TambangController.QUALITY_PERFECT)
	_hud.show_banner("", TextDb.t(&"tambang.pull"), 0.5)
	AudioManager.play_ui(&"ui_click")


func _on_slipped() -> void:
	_tambang_world.show_slip()
	_hud.show_banner("", TextDb.t(&"tambang.slip"), 0.6)
	AudioManager.play_ui(&"ui_disabled")
