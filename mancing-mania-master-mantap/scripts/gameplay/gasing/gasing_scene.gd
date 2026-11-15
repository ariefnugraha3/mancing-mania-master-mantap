extends SpotDuelScene
## Root of gasing.tscn. One button (Space, or the big button): aim, power,
## then a hit each time the ring closes.

const HIT_TEXT: Dictionary[StringName, StringName] = {
	GasingController.HIT_PERFECT: &"gasing.perfect",
	GasingController.HIT_GOOD: &"gasing.good",
	GasingController.HIT_EARLY: &"gasing.early",
	GasingController.HIT_MISS: &"gasing.miss",
}

var _gasing: GasingController
var _gasing_world: GasingWorld
var _aim_shown: bool = false


func _connect_duel() -> void:
	_gasing = _controller as GasingController
	_gasing_world = _world as GasingWorld
	(_hud as GasingHud).setup(_fish)
	_gasing.thrown.connect(_on_thrown)
	_gasing.ring_started.connect(func() -> void: _hud.show_banner("", TextDb.t(&"gasing.clash"), 0.5))
	_gasing.clash_resolved.connect(_on_clash)


func _read_input() -> void:
	if InputManager.consume_action_once(&"arm_mash"):
		_gasing.tap()


## The QA bot locks a straight aim and a strong throw, then taps on impact.
func _play_bot(_delta: float) -> void:
	var snapshot := _gasing.get_snapshot()
	match snapshot["state"]:
		GasingController.STATE_AIM:
			if absf(float(snapshot["aim"])) < 0.08:
				_gasing.tap()
		GasingController.STATE_POWER:
			if float(snapshot["power"]) > 0.93:
				_gasing.tap()
		GasingController.STATE_SPIN:
			if snapshot["ring_active"] and absf(float(snapshot["impact_in"])) <= 0.03:
				_gasing.tap()


func _update_world(snapshot: Dictionary) -> void:
	if not snapshot.has("aim"):
		return
	if snapshot["state"] == GasingController.STATE_AIM and not _aim_shown:
		_aim_shown = true
		_gasing_world.show_aim()
	_gasing_world.set_spins(float(snapshot["player_spin"]), float(snapshot["fish_spin"]))
	_gasing_world.set_ring(float(snapshot["ring"]), bool(snapshot["ring_active"]))


func _on_thrown(player_spin: float, fish_spin: float) -> void:
	_gasing_world.show_throw(player_spin, fish_spin, GasingController.SPIN_MIN + GasingController.SPIN_RANGE)
	AudioManager.play_ui(&"ui_click")


func _on_clash(outcome: Dictionary) -> void:
	var hit: StringName = outcome["hit"]
	_gasing_world.show_clash(hit)
	_hud.show_banner(TextDb.t(HIT_TEXT[hit]), "", 0.9)
	var landed := hit == GasingController.HIT_PERFECT or hit == GasingController.HIT_GOOD
	AudioManager.play_ui(&"ui_sell" if landed else &"ui_disabled")
