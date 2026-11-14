class_name StoryController
extends Node
## Plays one story event (GDD 168.3, 173, 183): builds its stage, runs its
## steps one by one, and finishes it through StoryDirector.
##
## Lines wait for the player; pauses are silence that the comedy needs
## (GDD 159, 183.1). Holding the skip action finishes the event at once with
## every state change, unlock and route it would have made (GDD 173.11).

signal finished(event_id: StringName, skipped: bool)

const SETS: Dictionary = {
	"home": "res://generated/scenes/environment/env_home_set.tscn",
	"lake": "res://generated/scenes/environment/env_lake_set.tscn",
	"market": "res://generated/scenes/environment/env_market_set.tscn",
}
const PEOPLE: Dictionary = {
	"darto": "res://generated/scenes/characters/chr_darto.tscn",
	"rini": "res://generated/scenes/characters/chr_rini.tscn",
	"nisa": "res://generated/scenes/characters/chr_nisa.tscn",
	"bu_yati": "res://generated/scenes/characters/chr_bu_yati.tscn",
}
const PROP_PATH := "res://generated/scenes/props/%s.tscn"
const TITLE_HOLD_SEC := 3.2
## QA only: how long a line stays up when dialogue advances by itself.
const AUTO_STEP_SEC := 0.5

var event_id: StringName = &""

var _stage_root: Node3D
var _set_anchor: Node3D
var _actors_root: Node3D
var _props_root: Node3D
var _camera: Camera3D
var _ui: StoryUi
var _set: Node3D
var _actors: Dictionary = {}
var _cameras: Dictionary = {}
var _timeline: Dictionary = {}
var _done: bool = false
var _waiting: bool = false
var _skip_hold: float = 0.0
var _touch_held: bool = false


func setup(stage_root: Node3D, ui: StoryUi) -> void:
	_stage_root = stage_root
	_set_anchor = stage_root.get_node("ActiveSetAnchor")
	_actors_root = stage_root.get_node("Actors")
	_props_root = stage_root.get_node("Props")
	_camera = stage_root.get_node("StoryCamera")
	_ui = ui
	_ui.advanced.connect(_on_advanced)


## Runs the event to its end. Await it.
func play(id: StringName) -> void:
	event_id = id
	_timeline = StoryTimelines.get_timeline(id)
	if _timeline.is_empty():
		GameLog.error(&"STORY", "no timeline", {"event": id})
		_finish(true)
		return
	AudioManager.set_music_state(StringName(_timeline.get("music", "silence")))
	AudioManager.set_ambience_state(StringName(_timeline.get("ambience", "silence")))
	_build_stage(str(_timeline.get("set", "none")))
	for step: Dictionary in _timeline.get("steps", []):
		if _done or not is_inside_tree():
			return
		await _run(step)
	# Leaving the scene some other way (quitting to the menu) does not count
	# as watching the event.
	if is_inside_tree():
		_finish(false)


func is_done() -> bool:
	return _done


func get_actor(who: String) -> Node3D:
	return _actors.get(who)


func _process(delta: float) -> void:
	if _done:
		return
	var holding := _touch_held or Input.is_action_pressed(InputActions.UI_CONFIRM) or InputManager.get_action_strength_safe(&"fish_cast") > 0.0
	var needed := float(GameState.get_setting(&"skip_hold_sec"))
	_skip_hold = _skip_hold + delta if holding else 0.0
	_ui.set_skip_progress(_skip_hold / maxf(needed, 0.1) if _skip_hold > 0.15 else 0.0)
	if _skip_hold >= needed:
		skip()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		_touch_held = event.is_pressed()


## Finishes now: the event still applies everything it would have applied.
func skip() -> void:
	if _done:
		return
	_finish(true)


# --- Steps ------------------------------------------------------------------

func _run(step: Dictionary) -> void:
	if step.has("cam"):
		# A cut leaves the phone behind; a message that follows reopens it.
		_ui.close_phone()
		_cut_to(str(step["cam"]))
	elif step.has("say"):
		var who := str(step["say"])
		_ui.show_line(StoryTimelines.speaker_name(StringName(who)), TextDb.t(StringName(step["text"])))
		await _wait_for_advance()
	elif step.has("phone"):
		_ui.show_phone_line(TextDb.t(StringName(step["phone"])))
		await _wait_for_advance()
	elif step.has("chat"):
		var who := str(step["chat"])
		_ui.show_chat(TextDb.t(StringName("speaker.%s" % who)) if who != "darto" else TextDb.t(&"speaker.darto"), TextDb.t(StringName(step["text"])), who == "darto")
		await _wait_for_advance()
	elif step.has("note"):
		var keys: Array = step["note"]
		_ui.show_notification(TextDb.t(StringName(keys[0])), TextDb.t(StringName(keys[1])) if keys.size() > 1 else "")
		AudioManager.play_ui(&"ui_click")
		await _wait_for_advance()
	elif step.has("call"):
		_ui.show_call(TextDb.t(StringName("story.phone.%s" % step["call"])))
	elif step.has("close_phone"):
		_ui.close_phone()
	elif step.has("pause"):
		await _wait(float(step["pause"]))
	elif step.has("clip"):
		_play_clip(str(step["clip"]), StringName(step["name"]))
	elif step.has("show"):
		_set_actor_visible(str(step["show"]), true)
	elif step.has("hide"):
		_set_actor_visible(str(step["hide"]), false)
	elif step.has("sfx"):
		AudioManager.play_sfx(StringName(step["sfx"]))
	elif step.has("title"):
		_ui.show_title(TextDb.t(StringName(step["title"])), TextDb.t(StringName(step["sub"])) if step.has("sub") else "")
		await _wait(TITLE_HOLD_SEC)
		_ui.hide_title()
	elif step.has("unlock"):
		_ui.show_unlock(TextDb.t(StringName(step["unlock"])), TextDb.t(StringName(step["body"])) if step.has("body") else "",
			TextDb.t(StringName(step["button"])) if step.has("button") else TextDb.t(&"story.unlock.continue"))
		AudioManager.play_ui(&"ui_debt_ding")
		await _wait_for_advance()
		_ui.hide_unlock()
	elif step.has("fade"):
		await _ui.fade(str(step["fade"]) == "out")
	elif step.has("cut_black"):
		_ui.set_black(true)
		await _wait(0.6)
	elif step.has("stage"):
		_build_lake_road()
		await _ui.fade(false)
	_ui.clear_line_if(step)


func _wait_for_advance() -> void:
	_waiting = true
	var auto := 0.0
	while _waiting and not _done and is_inside_tree():
		await get_tree().process_frame
		if DebugService.is_auto_dialogue_enabled():
			auto += get_process_delta_time()
			if auto >= AUTO_STEP_SEC:
				_waiting = false
	if is_instance_valid(_ui):
		_ui.hide_line()


func _wait(seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not _done and is_inside_tree():
		await get_tree().process_frame
		left -= get_process_delta_time()


func _on_advanced() -> void:
	_waiting = false


func _finish(skipped: bool) -> void:
	if _done:
		return
	_done = true
	_waiting = false
	StoryDirector.complete_event(event_id, skipped)
	finished.emit(event_id, skipped)


# --- Stage ------------------------------------------------------------------

func _build_stage(set_name: String) -> void:
	for child: Node in _set_anchor.get_children() + _actors_root.get_children() + _props_root.get_children():
		child.queue_free()
	_actors.clear()
	_set = null
	if SETS.has(set_name):
		_set = (load(SETS[set_name]) as PackedScene).instantiate()
		_set_anchor.add_child(_set)
	else:
		_ui.set_black(true)
	_cameras = _timeline.get("cameras", {})
	for actor: Dictionary in _timeline.get("actors", []):
		_spawn_actor(actor)
	for prop: Dictionary in _timeline.get("props", []):
		var node: Node3D = (load(PROP_PATH % prop["prop"]) as PackedScene).instantiate()
		_props_root.add_child(node)
		node.transform = _placement(prop)


## The prologue's second shot: the road past the lake, wide, for the title.
func _build_lake_road() -> void:
	_build_stage("none")
	_ui.set_black(false)
	_set = (load(SETS["lake"]) as PackedScene).instantiate()
	_set_anchor.add_child(_set)
	_camera.transform = (_set.get_node("Markers/CameraMenu") as Node3D).transform
	_camera.fov = 50.0
	AudioManager.set_ambience_state(&"lake")


func _spawn_actor(actor: Dictionary) -> void:
	var who := str(actor["who"])
	var node: Node3D
	if PEOPLE.has(who):
		node = (load(PEOPLE[who]) as PackedScene).instantiate()
	else:
		var fish := GameData.get_fish(StringName(who))
		if fish == null:
			return
		node = fish.model_scene.instantiate()
		var gloves := node.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
		if gloves != null:
			gloves.visible = false
	_actors_root.add_child(node)
	node.transform = _placement(actor)
	if actor.has("scale"):
		node.scale = Vector3.ONE * float(actor["scale"])
	node.visible = not bool(actor.get("hidden", false))
	_actors[who] = node
	if actor.has("clip"):
		_play_clip(who, StringName(actor["clip"]))


## Where something stands: on a set marker, or relative to one ("spot").
func _placement(entry: Dictionary) -> Transform3D:
	if entry.has("marker") and _set != null:
		return (_set.get_node("Markers/%s" % entry["marker"]) as Node3D).transform
	var origin := Vector3.ZERO
	if entry.has("spot") and _set != null:
		origin = (_set.get_node("Markers/%s" % entry["spot"]) as Node3D).position
	var offset: Array = entry.get("offset", [0, 0, 0])
	var yaw := deg_to_rad(float(entry.get("yaw", 0.0)))
	return Transform3D(Basis(Vector3.UP, yaw), origin + Vector3(offset[0], offset[1], offset[2]))


func _cut_to(name: String) -> void:
	var spec: Dictionary = _cameras.get(name, {})
	if spec.is_empty() or _set == null:
		return
	if spec.has("marker"):
		_camera.transform = (_set.get_node("Markers/%s" % spec["marker"]) as Node3D).transform
	else:
		var base := Vector3.ZERO
		var from: Array = spec.get("from", [0, 0, 0])
		var to: Array = spec.get("to", [0, 0, -1])
		if spec.has("offset_from"):
			base = (_set.get_node("Markers/DartoSpot") as Node3D).position
			from = spec["offset_from"]
			to = spec["offset_to"]
		_camera.look_at_from_position(base + Vector3(from[0], from[1], from[2]), base + Vector3(to[0], to[1], to[2]), Vector3.UP)
	_camera.fov = float(spec.get("fov", 45.0))


func _play_clip(who: String, clip: StringName) -> void:
	var actor: Node3D = _actors.get(who)
	if actor == null:
		return
	var player := actor.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null and player.has_animation(clip):
		player.play(clip, 0.2)


func _set_actor_visible(who: String, shown: bool) -> void:
	var actor: Node3D = _actors.get(who)
	if actor != null:
		actor.visible = shown
