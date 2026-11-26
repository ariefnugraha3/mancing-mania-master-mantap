class_name DuelResultOverlay
extends OverlayPanel
## What a duel came to (GDD 88): YOU WIN and the fish goes into the Bucket, or
## THE FISH GOT AWAY. One button, CONTINUE, waiting for player input. Losing
## costs nothing, so there is nothing else to say.
##
## This stands in until the Result scene is built; it shows a result that was
## already decided and committed, and decides nothing itself.

signal continued()

var _body: Label
var _button: GameButton
var _answered: bool = true


func build_content() -> void:
	layer = 45
	panel_width = 460.0
	_body = make_label("")
	content.add_child(_body)
	_button = make_button("", UiTokens.TYPE_CTA_BUTTON)
	_button.name = "ContinueButton"
	_button.pressed.connect(_continue)
	footer.add_child(_button)


## Shows a committed result (GDD 169.14).
func show_result(result: Dictionary) -> void:
	var fish := GameData.get_fish(result["fish_id"])
	if result["player_won"]:
		_open(TextDb.t(&"duel.result.win.title"),
			TextDb.tf(&"duel.result.win.body", {"fish": fish.get_display_name().to_upper()}),
			TextDb.t(&"duel.result.continue"))
	else:
		# The title is the whole message (GDD 88).
		_open(TextDb.t(&"duel.result.loss.title"), "", TextDb.t(&"duel.result.continue"))


func get_title_text() -> String:
	return _title_label.text


func on_cancel() -> void:
	_continue()


func _open(title: String, body: String, button_text: String) -> void:
	set_title(title)
	_body.text = body
	_body.visible = body != ""
	_button.text = button_text
	_button.disabled = false
	_answered = false
	show_overlay()
	focus_later(_button)


func _continue() -> void:
	if _answered:
		return
	_answered = true
	_button.disabled = true
	hide_overlay()
	continued.emit()
