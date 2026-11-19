class_name ModalDialog
extends OverlayPanel
## Small question/notice dialog used for confirmations and error recovery
## (GDD 85, 86, 176.8, 183.21).
##
##     var choice := await dialog.prompt(title, body, [
##         ModalDialog.option(&"cancel", "CANCEL", &"", true),
##         ModalDialog.option(&"confirm", "RESET", UiTokens.TYPE_DANGER_BUTTON),
##     ])
##
## Buttons lock after the first press, so a double tap cannot answer twice.

signal choice_made(choice: StringName)

var _body_label: Label
var _cancel_choice: StringName = &""
var _answered: bool = true


## Builds one option. `is_cancel` marks the choice that Esc / Android back
## selects; it also receives the initial focus as the safe default.
static func option(id: StringName, text: String, type_variation: StringName = &"", is_cancel: bool = false) -> Dictionary:
	return {"id": id, "text": text, "type": type_variation, "cancel": is_cancel}


func build_content() -> void:
	layer = 60
	_body_label = make_label("")
	content.add_child(_body_label)


## Shows the dialog and waits for the answer. Returns the chosen option id.
func prompt(title: String, body: String, options: Array[Dictionary]) -> StringName:
	set_title(title, UiTokens.TYPE_HEADER)
	_body_label.text = body
	_body_label.visible = body != ""
	_cancel_choice = &""
	_answered = false

	for child: Node in footer.get_children():
		footer.remove_child(child)
		child.queue_free()
	# On a phone the buttons stack full width so long labels never get cut
	# off; a tablet puts two side by side.
	stack_footer = not PlatformService.is_tablet() or options.size() > 2

	var focus_target: GameButton = null
	for entry: Dictionary in options:
		var button := make_button(entry["text"], entry.get("type", &""))
		if entry.get("cancel", false):
			_cancel_choice = entry["id"]
			button.click_sfx = &"ui_back"
			focus_target = button
		button.pressed.connect(_answer.bind(entry["id"]))
		footer.add_child(button)
		if focus_target == null:
			focus_target = button

	show_overlay()
	focus_later(focus_target)
	var choice: StringName = await choice_made
	hide_overlay()
	return choice


func on_cancel() -> void:
	if _cancel_choice != &"":
		AudioManager.play_ui(&"ui_back")
		_answer(_cancel_choice)


func _answer(choice: StringName) -> void:
	if _answered:
		return
	_answered = true
	for child: Node in footer.get_children():
		if child is BaseButton:
			child.disabled = true
	choice_made.emit(choice)
