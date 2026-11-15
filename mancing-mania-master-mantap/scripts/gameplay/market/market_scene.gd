extends Node
## Root of market.tscn: connects the rules (MarketController) to what the
## player sees and hears (world, ledger, audio) and to the rest of the game
## (pause, story queue, the way back to the lake).
##
## The Market is usable the moment it opens, starts on SELL and is only ever
## left through LEAVE MARKET (GDD 176.16). Leaving is where the story queue
## gets its one event per visit (GDD 177).

const TUTORIAL_ID := &"market_seen"
const UPGRADE_HINT_SEC := 6.0
## Play time is counted in capped steps, like at the lake.
const MAX_TIME_STEP_SEC := 0.1
const FIRST_MARKET_EVENT := &"story_first_market"
## Bu Yati and Darto trade a few words now and then: never on the first
## visit, never when a story event is waiting, at most once a visit.
const BANTER_EVERY_VISITS := 3

@onready var _controller: MarketController = $MarketController
@onready var _world: MarketWorld = $World
@onready var _hud: MarketHud = $MarketCanvas
@onready var _receipt: ReceiptOverlay = $ReceiptOverlay
@onready var _pause: PauseOverlay = $PauseOverlay

var _dialog: ModalDialog
var _leaving: bool = false
var _save_prompt_open: bool = false
var _refresh_queued: bool = false
var _talk: DialogueBox
var _first_visit: bool = false
var _first_sale_spoken: bool = false


func _ready() -> void:
	_dialog = ModalDialog.new()
	_dialog.name = "NoticeDialog"
	add_child(_dialog)
	_talk = DialogueBox.new()
	_talk.name = "DialogueBox"
	add_child(_talk)
	_first_visit = not StoryDirector.is_event_seen(FIRST_MARKET_EVENT)

	# This scene routes after the visit itself, so it can show a notice first.
	_controller.auto_route = false
	_controller.transaction_completed.connect(_on_transaction_completed)
	_controller.save_failed.connect(_on_save_failed)
	_controller.market_left.connect(_on_market_left)

	_hud.leave_pressed.connect(_leave)
	_hud.pause_pressed.connect(_pause.open)
	_hud.tab_changed.connect(_on_tab_changed)
	_hud.sell_panel.sell_all_requested.connect(_controller.sell_all)
	_hud.sell_panel.sell_category_requested.connect(_controller.sell_category)
	_hud.upgrade_panel.upgrade_requested.connect(_controller.purchase_upgrade)
	_hud.upgrade_panel.gear_requested.connect(_controller.purchase_gear)
	_hud.debt_panel.payment_requested.connect(_controller.pay_debt)
	_hud.debt_panel.savings_requested.connect(_controller.deposit_savings)
	_pause.quit_requested.connect(_quit_to_menu)
	# Anything that changes the numbers from outside a transaction (the debug
	# overlay, for one) still reaches the pages.
	GameState.cash_changed.connect(_queue_refresh)
	GameState.debt_changed.connect(_queue_refresh)
	GameState.bucket_changed.connect(_queue_refresh)
	GameState.upgrade_changed.connect(_queue_refresh)
	GameState.locations_changed.connect(_queue_refresh)

	StoryDirector.begin_market_visit()
	AudioManager.set_ambience_state(&"market")
	AudioManager.set_music_state(&"market")
	_refresh()
	_hud.focus_default()
	_open_conversation()


## First visit: Bu Yati's welcome (GDD 183.5). Later visits: sometimes a
## short exchange (GDD 177.10).
func _open_conversation() -> void:
	var lines: Array[Dictionary] = []
	if _first_visit:
		lines = StoryTimelines.to_dialogue(StoryTimelines.get_timeline(FIRST_MARKET_EVENT).get("steps", []))
	else:
		lines = pick_banter(int(GameState.get_story_value(&"market_visit_serial")), StoryDirector.get_pending_events().size())
	if not lines.is_empty():
		_talk.play(lines)


## The banter for this visit, or nothing.
static func pick_banter(visit_serial: int, pending_events: int) -> Array[Dictionary]:
	var banter := StoryTimelines.get_banter()
	if banter.is_empty() or pending_events > 0 or visit_serial < 2 or visit_serial % BANTER_EVERY_VISITS != 0:
		return []
	var exchange: Array = banter[(visit_serial / BANTER_EVERY_VISITS - 1) % banter.size()]
	return StoryTimelines.to_dialogue(exchange)


func _process(delta: float) -> void:
	if _leaving:
		return
	GameState.add_play_time(minf(delta, MAX_TIME_STEP_SEC))
	if _refresh_queued:
		_refresh()
	if InputManager.consume_action_once(InputActions.PAUSE):
		_pause.open()


func _notification(what: int) -> void:
	if not is_node_ready() or _leaving:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Web tab or desktop window lost focus (GDD 176.4).
			_pause.open(true)
		NOTIFICATION_APPLICATION_PAUSED:
			# Android sent the app to the background: save first (GDD 176.5).
			SaveManager.save_game(&"background")
			_pause.open(true)


# --- Showing state ----------------------------------------------------------

func _refresh() -> void:
	_refresh_queued = false
	_hud.sell_panel.show_preview(_controller.get_sell_preview())
	_hud.debt_panel.set_tutorial_offer(not GameState.is_tutorial_seen(TUTORIAL_ID))
	_hud.refresh_pages()
	_update_tutorial_hint()


## First visit only (GDD 183.5): sell, open the Debt tab, make one small
## payment. The hints point the way and never block anything else.
func _update_tutorial_hint() -> void:
	if GameState.is_tutorial_seen(TUTORIAL_ID):
		return
	var hint := ""
	if GameState.get_bucket_total_count() > 0:
		hint = TextDb.t(&"market.hint.sell")
	elif _controller.get_max_debt_payment() >= MarketDebtPanel.TUTORIAL_AMOUNT:
		hint = TextDb.t(&"market.hint.pay" if _hud.get_current_tab() == MarketHud.TAB_DEBT else &"market.hint.debt_tab")
	_hud.show_hint(hint)


func _on_tab_changed(_tab_id: StringName) -> void:
	_refresh()


## Several values can change in one transaction; the pages refresh once, on
## the next frame.
func _queue_refresh(_first: Variant = null, _second: Variant = null) -> void:
	_refresh_queued = true


# --- Transactions -----------------------------------------------------------

func _on_transaction_completed(kind: StringName, result: Dictionary) -> void:
	match kind:
		MarketController.KIND_SELL:
			AudioManager.play_ui(&"ui_sell")
			_world.react_sale()
			_receipt.open(result)
		MarketController.KIND_UPGRADE, MarketController.KIND_GEAR:
			AudioManager.play_ui(&"ui_purchase")
			_world.react_purchase()
		MarketController.KIND_DEBT:
			# One soft ding. No confetti (GDD 183.5).
			AudioManager.play_ui(&"ui_debt_ding")
			_world.react_payment()
		MarketController.KIND_SAVINGS:
			AudioManager.play_ui(&"ui_debt_ding")
			_world.react_payment()
	var first_payment := kind == MarketController.KIND_DEBT and not GameState.is_tutorial_seen(TUTORIAL_ID)
	if _first_visit:
		var timeline := StoryTimelines.get_timeline(FIRST_MARKET_EVENT)
		if kind == MarketController.KIND_SELL and not _first_sale_spoken:
			_first_sale_spoken = true
			_talk.play(StoryTimelines.to_dialogue(timeline.get("after_sale", [])))
		elif first_payment:
			_talk.play(StoryTimelines.to_dialogue(timeline.get("after_payment", [])))
	if first_payment:
		GameState.set_tutorial_seen(TUTORIAL_ID)
		if not SaveManager.save_game(&"tutorial"):
			_on_save_failed()
	_refresh()
	if first_payment:
		_hud.show_hint(TextDb.t(&"market.hint.upgrades"), UPGRADE_HINT_SEC)


## The save after a transaction failed. The game state is kept in memory and
## the player decides whether to retry (GDD 176.8).
func _on_save_failed() -> void:
	if _save_prompt_open:
		return
	_save_prompt_open = true
	while true:
		var choice: StringName = await _dialog.prompt(
			TextDb.t(&"error.save_failed.title"), TextDb.t(&"error.save_failed.body"), [
				ModalDialog.option(&"continue", TextDb.t(&"error.save_failed.continue"), &"", true),
				ModalDialog.option(&"retry", TextDb.t(&"error.save_failed.retry"), UiTokens.TYPE_CTA_BUTTON),
			])
		if choice != &"retry" or SaveManager.save_game(&"retry"):
			break
	_save_prompt_open = false


# --- Leaving ----------------------------------------------------------------

func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	_hud.set_leave_enabled(false)
	_controller.leave_market()


## The visit is over: the Story scene plays this visit's event, if any.
## A build without it announces an unlock with a short notice instead.
func _on_market_left(event_id: StringName) -> void:
	while _save_prompt_open:
		await get_tree().process_frame
	if event_id != &"" and SceneRouter.has_scene(SceneRouter.SCENE_STORY):
		StoryDirector.play_event(event_id)
		return
	var title_key := StringName("story.notice.%s.title" % event_id)
	if event_id != &"" and TextDb.has_key(title_key):
		await _dialog.prompt(TextDb.t(title_key), TextDb.t(StringName("story.notice.%s.body" % event_id)), [
			ModalDialog.option(&"ok", TextDb.t(&"common.ok"), UiTokens.TYPE_CTA_BUTTON, true),
		])
	SceneRouter.goto_fishing()


func _quit_to_menu() -> void:
	_leaving = true
	get_tree().paused = false
	SceneRouter.goto_main_menu()
