extends Node
## Root of result.tscn (GDD 88, 166, 168.11): Darto and the fish on the bank,
## the result in large type, the fish's line and Darto's answer, then
## CONTINUE back to the lake.

const FIRST_BOSS_WIN_KEY := &"arowana_first_win_seen"

@onready var _controller: ResultController = $ResultController
@onready var _darto: Node3D = $World/DartoResultPose
@onready var _fish_anchor: Node3D = $World/FishResultPose
@onready var _camera: Camera3D = $World/ResultCamera
@onready var _safe_root: Control = $ResultCanvas/SafeRoot
@onready var _title: Label = $ResultCanvas/SafeRoot/ResultTitle
@onready var _detail: Label = $ResultCanvas/SafeRoot/DetailLabel
@onready var _continue: GameButton = $ResultCanvas/SafeRoot/ContinueButton
@onready var _progress: ProgressBar = $ResultCanvas/SafeRoot/AutoContinueProgress

var _dialogue: DialogueBox


func _ready() -> void:
	var result: Dictionary = SceneRouter.get_context().get("result", {})
	if result.is_empty():
		result = {"duel_id": &"boxing", "fish_id": &"catfish_bruiser", "player_won": true, "duration_sec": 0.0, "seed": 0, "metrics": {}}
	_controller.setup_result(result)
	_dialogue = DialogueBox.new()
	_dialogue.name = "DialogueBox"
	add_child(_dialogue)

	var fish := GameData.get_fish(result["fish_id"])
	var won: bool = result["player_won"]
	_title.text = TextDb.t(&"duel.result.win.title" if won else &"duel.result.loss.title")
	UiTokens.outline_text(_title, UiTokens.FONT_HERO, UiTokens.SUN_500 if won else UiTokens.CREAM_50)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.text = TextDb.tf(&"result.detail.win", {"fish": fish.display_name.to_upper()}) if won else ""
	UiTokens.outline_text(_detail, UiTokens.FONT_HEADER)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue.text = TextDb.t(&"duel.result.continue")
	_continue.theme_type_variation = UiTokens.TYPE_CTA_BUTTON
	_continue.pressed.connect(_controller.continue_from_result)
	_continue.disabled = true
	_progress.show_percentage = false
	_progress.max_value = ResultController.AUTO_CONTINUE_SEC
	_safe_root.resized.connect(_layout)
	_layout.call_deferred()

	_stage_cast()
	var model: Node3D = fish.model_scene.instantiate()
	_fish_anchor.add_child(model)
	var gloves := model.get_node_or_null("AccessoryMeshes/Gloves") as Node3D
	if gloves != null:
		gloves.visible = false
	# Win: it slumps toward the bucket. Loss: it leaps back into the lake.
	(model.get_node("AnimationPlayer") as AnimationPlayer).play(&"fish_bucket_defeat" if won else &"fish_escape_jump")
	(_darto.get_node("Rig/AnimationPlayer") as AnimationPlayer).play(&"market_idle")
	AudioManager.set_ambience_state(&"lake")
	AudioManager.set_music_state(&"result")
	AudioManager.play_ui(&"ui_sell" if won else &"ui_back")

	var first_boss_win := won and fish.id == ContentIds.BOSS_FISH_ID and not bool(GameState.get_story_value(FIRST_BOSS_WIN_KEY))
	_dialogue.play(FishDialogue.after_duel(fish.id, won, int(result.get("seed", 0)), first_boss_win))
	await _dialogue.finished
	if not is_inside_tree():
		return
	_continue.disabled = false
	_continue.grab_focus()
	_controller.start_auto_continue()


## Darto stands at his fishing spot facing the camera, the bucket and the
## fish beside him, the lake behind (GDD 88).
func _stage_cast() -> void:
	var markers := get_node("World/ResultStageAnchor/Markers")
	var spot := (markers.get_node("DartoSpot") as Node3D).position
	var bucket := (markers.get_node("BucketSpot") as Node3D).position
	_darto.transform = Transform3D(Basis(Vector3.UP, PI + 0.25), spot)
	(get_node("World/Bucket") as Node3D).position = bucket + Vector3(-0.2, 0.0, 0.1)
	_fish_anchor.position = bucket + Vector3(0.45, 0.02, 0.2)
	_fish_anchor.rotation.y = -PI * 0.5
	_camera.look_at_from_position(spot + Vector3(0.55, 1.45, 3.4), spot + Vector3(0.55, 0.85, 0.0), Vector3.UP)


func _process(_delta: float) -> void:
	_progress.value = ResultController.AUTO_CONTINUE_SEC - _controller.get_auto_continue_left()
	_progress.visible = _controller.is_counting()


func _layout() -> void:
	var portrait := PlatformService.get_viewport_class() == PlatformService.PORTRAIT
	var area := _safe_root.size
	_place(_title, Rect2(0.0, area.y * 0.08, area.x, 64.0))
	_place(_detail, Rect2(0.0, area.y * 0.08 + 68.0, area.x, 40.0))
	var width := minf(360.0, area.x)
	# CONTINUE takes the dialogue box's place once the talking is done.
	var button_y := area.y - UiTokens.TOUCH_TARGET_PREFERRED - 40.0
	_place(_continue, Rect2((area.x - width) * 0.5, button_y, width, UiTokens.TOUCH_TARGET_PREFERRED))
	_place(_progress, Rect2((area.x - width) * 0.5, button_y + UiTokens.TOUCH_TARGET_PREFERRED + 8.0, width, 8.0))
	_camera.fov = 58.0 if portrait else 45.0


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
