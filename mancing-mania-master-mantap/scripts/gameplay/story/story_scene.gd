extends Node
## Root of story.tscn (GDD 168.3): plays the event the router was given and
## sends the player on to where the story goes next (GDD 173.11, 183.2):
##
##   prologue, Market milestones, first fish -> the lake
##   debt paid -> the final family scene -> credits -> post-game unlock -> the lake

const NEXT_EVENT: Dictionary = {
	&"story_debt_paid": &"story_final_family",
}

@onready var _controller: StoryController = $StoryController
@onready var _stage: Node3D = $StageRoot
@onready var _ui: StoryUi = $StoryCanvas/StoryUI


func _ready() -> void:
	_controller.setup(_stage, _ui)
	var event_id: StringName = SceneRouter.get_context().get("event_id", &"")
	if event_id == &"":
		SceneRouter.goto_fishing()
		return
	_controller.finished.connect(_on_finished)
	_controller.play(event_id)


func _on_finished(event_id: StringName, _skipped: bool) -> void:
	if event_id == &"story_postgame_unlock":
		GameState.set_story_value(&"postgame_unlocked", true)
		GameState.set_story_value(&"ending_completed", true)
		GameState.set_story_value(&"chapter", "postgame")
	SaveManager.save_game(&"story")
	var next: StringName = NEXT_EVENT.get(event_id, &"")
	if next != &"":
		StoryDirector.play_event(next)
	elif event_id == &"story_final_family" and SceneRouter.has_scene(SceneRouter.SCENE_CREDITS):
		SceneRouter.goto_credits()
	else:
		SceneRouter.goto_fishing()


func get_controller() -> StoryController:
	return _controller
