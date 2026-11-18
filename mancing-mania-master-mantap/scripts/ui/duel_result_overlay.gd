class_name DuelResultOverlay
extends OverlayPanel
## What a duel came to (GDD 88): YOU WIN and the fish goes into the Bucket, or
## THE FISH GOT AWAY. One button, CONTINUE, which also presses itself after
## five seconds. Losing costs nothing, so there is nothing else to say.
##
## This stands in until the Result scene is built; it shows a result that was
## already decided and committed, and decides nothing itself.

signal continued()

const AUTO_CONTINUE_SEC := 5.0

var _body: Label
var _button: GameButton
var _progress: ProgressBar
var _left: float = 0.0
var _answered: bool = true


func build_content() -> void:
	layer = 45
	panel_width = 460.0
	_body = make_label("")
	content.add_child(_body)
	_progress = ProgressBar.new()
	_progress.name = "AutoContinueProgress"
	_progress.show_percentage = false
	_progress.max_value = AUTO_CONTINUE_SEC
	_progress.custom_minimum_size.y = 8.0
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_progress)
	_button = make_button("", UiTokens.TYPE_CTA_BUTTON)
	_button.name = "ContinueButton"
	_button.pressed.connect(_continue)
	footer.add_child(_button)


func _process(delta: float) -> void:
	if not visible or _answered:
		return
	_left -= delta
	_progress.value = AUTO_CONTINUE_SEC - _left
	if _left <= 0.0:
		_continue()


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
	_left = AUTO_CONTINUE_SEC
	_progress.value = 0.0
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
