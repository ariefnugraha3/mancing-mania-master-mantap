extends Node
## Root of result.tscn (GDD 88, 166, 168.11): Darto and the fish on the bank,
## the result in large type, the fish's line and Darto's answer, then
## CONTINUE back to the lake.

const FIRST_BOSS_WIN_KEY := &"arowana_first_win_seen"

@onready var _controller: ResultController = $ResultController
@onready var _darto: Node3D = $World/DartoResultPose
@onready var _fish_anchor: Node3D = $World/FishResultPose
@onready var _camera: DioramaCamera = $World/ResultCamera
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
	# Wrap is switched on before any text goes in: a label without wrap takes
	# its whole one-line width as its minimum size, and a long fish name would
	# then push the line off a narrow phone no matter what size layout gives it.
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.text = TextDb.t(&"duel.result.win.title" if won else &"duel.result.loss.title")
	UiSkin.sign_text(_title, UiTokens.FONT_HERO + 8, DioramaStyle.BUTTER if won else UiTokens.CREAM_50, 14)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.text = TextDb.tf(&"result.detail.win", {"fish": fish.get_display_name().to_upper()}) if won else ""
	UiTokens.outline_text(_detail, UiTokens.FONT_HEADER)
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_continue.text = TextDb.t(&"duel.result.continue")
	_continue.theme_type_variation = UiTokens.TYPE_CTA_BUTTON
	_continue.icon_id = IconPainter.PLAY
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
	if won:
		DioramaMotion.stretch(_darto.get_node("Rig") as Node3D, 0.12)
	var spot := GameData.get_location(GameState.get_current_location())
	AudioManager.set_ambience_state(spot.ambience if spot != null else &"lake")
	AudioManager.set_music_state(&"result")
	AudioManager.play_ui(&"ui_sell" if won else &"ui_back")

	var first_boss_win := won and fish.id == ContentIds.BOSS_FISH_ID and not bool(GameState.get_story_value(FIRST_BOSS_WIN_KEY))
	_dialogue.play(FishDialogue.after_duel(fish.id, won, int(result.get("seed", 0)), first_boss_win))
	await _dialogue.finished
	if not is_inside_tree():
		return
	if first_boss_win:
		# The exchange is the story event (GDD 173.8), so it never plays twice.
		StoryDirector.complete_event(&"story_arowana_first_win", false)
		SaveManager.save_game(&"story")
	_continue.disabled = false
	InputManager.give_focus(_continue)
	_controller.start_auto_continue()


## Darto stands at his fishing spot facing the camera, the bucket on his
## left on screen and the fish on his right, the lake behind (GDD 88).
func _stage_cast() -> void:
	# The result plays out at the spot where the fish was caught.
	var stage := SpotSet.swap_in(get_node("World/ResultStageAnchor") as Node3D, GameState.get_current_location())
	var markers := stage.get_node("Markers")
	var spot := (markers.get_node("DartoSpot") as Node3D).position
	var right := DioramaStyle.screen_right()
	var toward := -DioramaStyle.screen_in()
	_darto.transform = Transform3D(Basis(Vector3.UP, atan2(-toward.x, -toward.z)), spot)
	(get_node("World/Bucket") as Node3D).position = spot - right * 0.42 + toward * 0.05
	_fish_anchor.position = spot + right * 0.5 + toward * 0.05
	# The fish turns three-quarters toward the camera and Darto.
	var look := (toward - right).normalized()
	_fish_anchor.rotation.y = atan2(-look.z, look.x)
	_camera.set_hud_insets(Vector2(110.0, 190.0))
	_camera.frame(spot + Vector3(0.0, 0.35, 0.0) + right * 0.05, 5.6)


func _process(_delta: float) -> void:
	_progress.value = ResultController.AUTO_CONTINUE_SEC - _controller.get_auto_continue_left()
	_progress.visible = _controller.is_counting()


func _layout() -> void:
	var area := _safe_root.size
	# Both lines wrap on a narrow phone instead of running off the screen
	# (wrap is on from _ready). A side margin keeps the outline off the edge,
	# and the detail sits under however many lines the title needed.
	var margin := float(UiTokens.SPACE_16)
	var width := maxf(area.x - margin * 2.0, 1.0)
	# A wrapped label grows to fit its lines; the detail goes under the
	# title's real height.
	_place_wrapped(_title, Vector2(margin, area.y * 0.06), width, 64.0)
	_place_wrapped(_detail, Vector2(margin, _title.position.y + _title.size.y + 4.0), width, 64.0)
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var button_width := minf(400.0, area.x)
	# CONTINUE takes the dialogue box's place once the talking is done.
	var button_y := area.y - UiTokens.TOUCH_TARGET_PREFERRED - 40.0
	_place(_continue, Rect2((area.x - button_width) * 0.5, button_y, button_width, UiTokens.TOUCH_TARGET_PREFERRED))
	_place(_progress, Rect2((area.x - button_width) * 0.5, button_y + UiTokens.TOUCH_TARGET_PREFERRED + 8.0, button_width, 8.0))


## Places a wrapped label: width first, then height. A wrapped label's
## minimum height depends on its width, and a control never gets smaller than
## its minimum, so setting both at once measured the lines at the old width.
func _place_wrapped(label: Label, at: Vector2, width: float, min_height: float) -> void:
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = at
	label.size = Vector2(width, label.size.y)
	# The cached minimum was measured at the old width: measure again.
	label.update_minimum_size()
	label.size = Vector2(width, min_height)


func _place(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
