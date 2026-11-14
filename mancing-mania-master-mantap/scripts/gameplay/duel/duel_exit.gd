class_name DuelExit
extends RefCounted
## How every duel scene ends (GDD 89, 169.14): commit the result once, deal
## with a failed save, then hand over to the Result scene. Builds without the
## Result scene show the small result overlay and go back to the lake.


## Commits `result`, then routes on. Await it; it returns when the scene is
## on its way out.
static func leave(result: Dictionary, overlay: DuelResultOverlay, dialog: ModalDialog) -> void:
	if not DuelOutcome.commit(result):
		await report_save_failure(dialog)
	if SceneRouter.has_scene(SceneRouter.SCENE_RESULT):
		SceneRouter.goto_result(result)
		return
	overlay.show_result(result)
	await overlay.continued
	SceneRouter.goto_fishing()


## The save failed: the state stays in memory and the player decides whether
## to retry (GDD 176.8).
static func report_save_failure(dialog: ModalDialog) -> void:
	while true:
		var choice: StringName = await dialog.prompt(
			TextDb.t(&"error.save_failed.title"), TextDb.t(&"error.save_failed.body"), [
				ModalDialog.option(&"continue", TextDb.t(&"error.save_failed.continue"), &"", true),
				ModalDialog.option(&"retry", TextDb.t(&"error.save_failed.retry"), UiTokens.TYPE_CTA_BUTTON),
			])
		if choice != &"retry" or SaveManager.save_game(&"retry"):
			return
