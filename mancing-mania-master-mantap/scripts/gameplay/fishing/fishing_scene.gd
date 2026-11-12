extends Node
## Root of fishing.tscn: connects the rules (FishingController) to what the
## player sees and hears (world, HUD, audio) and to the rest of the game
## (pause, bucket peek, Market).
##
## One contextual input does everything at the lake: it casts when idle,
## strikes while a bite is on, and reels while held (GDD 91, 93). Each press is
## consumed once, so the tap that casts can never also count as a strike.

const REEL_TICK_INTERVAL_SEC := 0.16
const STRESS_SOUND_INTERVAL_SEC := 0.55

@onready var _controller: FishingController = $FishingController
@onready var _world: FishingWorld = $World
@onready var _hud: FishingHud = $FishingCanvas
@onready var _bucket_peek: BucketPeekOverlay = $BucketPeekOverlay
@onready var _pause: PauseOverlay = $PauseOverlay

var _reel_tick_left: float = 0.0
var _stress_sound_left: float = 0.0
var _leaving: bool = false


func _ready() -> void:
	_controller.fishing_state_changed.connect(_on_state_changed)
	_controller.float_released.connect(_on_float_released)
	_controller.float_landed.connect(_on_float_landed)
	_controller.nibbled.connect(_on_nibbled)
	_controller.bite_started.connect(_on_bite_started)
	_controller.false_strike.connect(_on_false_strike)
	_controller.strike_succeeded.connect(_on_strike_succeeded)
	_controller.fish_landed.connect(_on_fish_landed)
	_controller.trash_caught.connect(_on_trash_caught)
	_controller.fishing_failed.connect(_on_fishing_failed)
	_controller.catch_resolved.connect(_on_catch_resolved)

	_hud.pause_pressed.connect(_pause.open)
	_hud.bucket_pressed.connect(_open_bucket)
	_hud.market_pressed.connect(_go_to_market)
	_hud.set_market_available(SceneRouter.has_scene(SceneRouter.SCENE_MARKET))
	_pause.quit_requested.connect(_quit_to_menu)

	AudioManager.set_ambience_state(&"lake")
	AudioManager.set_music_state(&"fishing")


func _process(delta: float) -> void:
	if _leaving:
		return
	_read_input()
	var state := _controller.get_state()
	if state == FishingController.STATE_STRIKE_WINDOW:
		_hud.set_strike_ratio(_controller.get_strike_window_ratio())
	elif state == FishingController.STATE_REELING:
		var reel := _controller.get_reel()
		var held := InputManager.get_action_strength_safe(&"fish_reel") > 0.0
		if DebugService.is_auto_reel_enabled():
			held = reel.marker < reel.zone_center
		_controller.set_reel_held(held)
		_world.update_reel(reel, held)
		_hud.update_reel(reel, held, delta)
		_play_reel_sounds(reel, held, delta)


func _notification(what: int) -> void:
	if not is_node_ready() or _leaving:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Web tab or desktop window lost focus: stop everything (GDD 176.4).
			_pause.open(true)
		NOTIFICATION_APPLICATION_PAUSED:
			# Android sent the app to the background: save first (GDD 176.5).
			SaveManager.save_game(&"background")
			_pause.open(true)


# --- Input ------------------------------------------------------------------

func _read_input() -> void:
	if InputManager.consume_action_once(InputActions.PAUSE):
		_pause.open()
		return
	if InputManager.consume_action_once(&"open_bucket"):
		_open_bucket()
		return
	if InputManager.consume_action_once(&"open_market"):
		_go_to_market()
		return
	if InputManager.consume_action_once(&"fish_cast"):
		match _controller.get_state():
			FishingController.STATE_IDLE:
				_controller.start_cast()
			FishingController.STATE_WAITING, FishingController.STATE_BITE_WARNING, FishingController.STATE_STRIKE_WINDOW:
				_controller.attempt_strike()


func _open_bucket() -> void:
	if not GameState.is_tutorial_seen(&"market_seen") and GameState.get_bucket_total_count() > 0:
		_hud.show_hint(TextDb.t(&"fishing.bucket.tutorial"), 3.5)
	_bucket_peek.open()


func _go_to_market() -> void:
	if _leaving or _controller.get_state() != FishingController.STATE_IDLE:
		return
	if not SceneRouter.has_scene(SceneRouter.SCENE_MARKET):
		return
	_leaving = true
	SceneRouter.goto_market()


func _quit_to_menu() -> void:
	_leaving = true
	_controller.cancel_to_idle()
	get_tree().paused = false
	SceneRouter.goto_main_menu()


# --- Controller events ------------------------------------------------------

func _on_state_changed(state: StringName) -> void:
	_hud.set_state(state)
	match state:
		FishingController.STATE_IDLE:
			_world.show_idle()
		FishingController.STATE_CASTING:
			_world.show_cast()
		FishingController.STATE_BITE_WARNING:
			_world.show_bite_warning()


func _on_float_released() -> void:
	_world.release_float()
	AudioManager.play_sfx(&"sfx_cast_whoosh")


func _on_float_landed() -> void:
	_world.land_float()
	AudioManager.play_sfx(&"sfx_float_plip")


func _on_nibbled() -> void:
	_world.show_nibble()
	AudioManager.play_sfx(&"sfx_false_nibble")
	if not GameState.is_tutorial_seen(&"fishing_seen"):
		_hud.show_hint(TextDb.t(&"fishing.prompt.nibble"), 2.4)


func _on_bite_started(_strike_window_sec: float) -> void:
	_world.show_bite()
	# The bite cue must never be buried under the ambience (GDD 111, 175.5).
	AudioManager.duck_ambience(4.0, 0.45)
	AudioManager.play_sfx(&"sfx_real_bite")


func _on_false_strike() -> void:
	_world.show_false_strike()
	AudioManager.play_sfx(&"sfx_false_nibble")
	_hud.show_hint(TextDb.t(&"fishing.prompt.false_strike"), 1.4)


func _on_strike_succeeded(encounter: Dictionary) -> void:
	_world.show_strike(encounter["kind"] == EncounterRoller.KIND_TRASH)
	AudioManager.play_sfx(&"sfx_strike_success")
	_reel_tick_left = 0.0
	_stress_sound_left = 0.0


func _on_fish_landed(fish_id: StringName, weight_kg: float) -> void:
	_world.show_fish_landed(fish_id)
	AudioManager.play_sfx(&"sfx_large_splash")
	var encounter := _controller.get_encounter()
	var subtitle := TextDb.t(StringName("fish.%s.subtitle" % fish_id))
	subtitle += "   " + TextDb.tf(&"fishing.result.weight", {"weight": "%.2f" % weight_kg})
	if encounter.get("is_big_one", false):
		subtitle += "   " + TextDb.t(&"fishing.result.big_one")
	# Fish introduction sting (GDD Section 37).
	_hud.show_banner(GameData.get_item_display_name(fish_id).to_upper(), subtitle, FishingController.FISH_REVEAL_SEC + 1.2)


func _on_trash_caught(item_id: StringName) -> void:
	_world.show_trash_landed(item_id)
	AudioManager.play_sfx(&"sfx_float_plip")
	_hud.show_banner(
		GameData.get_item_display_name(item_id).to_upper(),
		TextDb.t(&"fishing.result.trash.body"),
		FishingController.TRASH_REVEAL_SEC + 1.0)


func _on_fishing_failed(reason: StringName) -> void:
	_world.show_escape(reason)
	if reason == FishingController.REASON_LINE_BREAK:
		AudioManager.play_sfx(&"sfx_line_break")
		_hud.show_banner(TextDb.t(&"fishing.result.line_break.title"), TextDb.t(&"fishing.result.line_break.body"), FishingController.ESCAPE_HOLD_SEC)
	else:
		AudioManager.play_sfx(&"sfx_float_plip")
		_hud.show_banner(TextDb.t(&"fishing.result.missed.title"), TextDb.t(&"fishing.result.missed.body"), FishingController.ESCAPE_HOLD_SEC)


func _on_catch_resolved(outcome: Dictionary) -> void:
	match outcome["outcome"]:
		FishingController.OUTCOME_BUCKET:
			_world.show_catch_to_bucket()
			AudioManager.play_ui(&"ui_click")
		FishingController.OUTCOME_BUCKET_NO_DUEL:
			_world.show_catch_to_bucket()
			AudioManager.play_ui(&"ui_click")
			_hud.show_hint(TextDb.t(&"fishing.result.no_duel"), 3.0)
		FishingController.OUTCOME_DUEL:
			_leaving = true


# --- Audio ------------------------------------------------------------------

## Reel clicks are rate-limited so holding the reel never sounds like a machine
## gun, and line creaks get denser as the stress band rises (GDD 175.6).
func _play_reel_sounds(reel: ReelSimulation, held: bool, delta: float) -> void:
	_reel_tick_left -= delta
	_stress_sound_left -= delta
	if held and _reel_tick_left <= 0.0:
		_reel_tick_left = REEL_TICK_INTERVAL_SEC
		AudioManager.play_sfx(&"sfx_reel_tick", -6.0)
	var band := reel.get_stress_band()
	if band >= 1 and _stress_sound_left <= 0.0:
		_stress_sound_left = STRESS_SOUND_INTERVAL_SEC / float(band)
		AudioManager.play_sfx(&"sfx_line_stress", -9.0 + 3.0 * float(band), RNGService.cosmetic.randi() & 0xFFFF)
