extends "res://tests/test_suite.gd"
## Narrative milestone (GDD 173, 177, 183; QA matrix NAR-001, NAR-002,
## STORY-007, STORY-008, STORY-012): every line and every stage the story
## uses exists, skipping applies what watching would, and the ending runs
## from the last payment through the credits into the post-game, in the real
## scenes.

const STORAGE_DIR := "user://test_tmp/story"
const STORY_SCENE := "res://scenes/story/story.tscn"
const SCENE_TIMEOUT_SEC := 20.0

var _finished_transitions: Array[StringName] = []


func get_suite_name() -> String:
	return "story"


func before_all() -> void:
	SceneRouter.transition_finished.connect(_on_transition_finished)


func after_all() -> void:
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), SCENE_TIMEOUT_SEC)
	DebugService.set_auto_dialogue(false)
	SceneRouter.transition_finished.disconnect(_on_transition_finished)
	if tree.current_scene != null:
		tree.current_scene.queue_free()
		await wait_frames(2)
	CePatCash.reset()
	GameState.clear_game()
	DebugService.clear_dev_dirty()
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


func before_each() -> void:
	await wait_until(func() -> bool: return not SceneRouter.is_transitioning(), SCENE_TIMEOUT_SEC)
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)
	DebugService.clear_dev_dirty()
	DebugService.set_auto_dialogue(false)
	GameState.clear_game()
	GameState.new_game()
	CePatCash.reset()
	_finished_transitions.clear()


func _on_transition_finished(scene_id: StringName) -> void:
	_finished_transitions.append(scene_id)


func _wait_for_scene(scene_id: StringName, count: int = 1) -> bool:
	var reached := await wait_until(func() -> bool: return _finished_transitions.count(scene_id) >= count, SCENE_TIMEOUT_SEC)
	await wait_frames(3)
	return reached


func _story_controller() -> StoryController:
	return tree.current_scene.get_node_or_null("StoryController") as StoryController


# --- Content (NAR-001) ------------------------------------------------------

func test_every_story_line_exists_in_the_text_table() -> bool:
	var keys := StoryTimelines.all_keys()
	check(keys.size() >= 190, "the story has its full script (%d lines)" % keys.size())
	var missing := PackedStringArray()
	for key: String in keys:
		if not TextDb.has_key(StringName(key)) or TextDb.t(StringName(key)).strip_edges() == "":
			missing.append(key)
	check_empty(missing, "every story key has English text")
	return true


# NAR-002
func test_no_placeholder_in_the_story() -> bool:
	var found := PackedStringArray()
	var markers: Array[String] = ["todo", "tbd", "placeholder", "lorem", "xxx", "fixme", "[", "{", "}"]
	var language := TextDb.get_language()
	for each: String in TextDb.LANGUAGES:
		TextDb.set_language(each)
		for key: String in StoryTimelines.all_keys():
			# As shown: a line that quotes the player's numbers has them filled in.
			var text := StoryTimelines.line_text(StringName(key)).to_lower()
			for marker: String in markers:
				if text.contains(marker):
					found.append("%s (%s): %s" % [key, each, text])
	TextDb.set_language(language)
	check_empty(found, "no story line is a placeholder")
	return true


## The family's tally in the epilogue is the player's own: how often the
## catfish won a duel against Darto.
func test_the_epilogue_counts_the_catfish_wins() -> bool:
	GameState.new_game()
	for loss: int in 3:
		GameState.record_fish_loss(&"catfish_bruiser")
	GameState.record_fish_loss(&"tilapia_gym_rat")
	var language := TextDb.get_language()
	for each: String in TextDb.LANGUAGES:
		TextDb.set_language(each)
		var line := StoryTimelines.line_text(&"story.story_final_family.03")
		check(line.contains("3") and not line.contains("4") and not line.contains("{"), "%s: the line quotes the catfish's 3 wins (%s)" % [each, line])
	TextDb.set_language(language)
	var spoken := StoryTimelines.to_dialogue([{"say": "rini", "text": "story.story_final_family.03"}])
	check(spoken[0]["text"].contains("3"), "and so does the dialogue box")
	GameState.new_game()
	check(StoryTimelines.line_text(&"story.story_final_family.03").contains("0"), "a player the catfish never beat hears 0")
	return true


func test_every_story_event_has_a_playable_timeline() -> bool:
	var problems := PackedStringArray()
	for event_id: StringName in ContentIds.STORY_EVENT_IDS:
		var timeline := StoryTimelines.get_timeline(event_id)
		if timeline.is_empty() or (timeline.get("steps", []) as Array).is_empty():
			problems.append("%s has no steps" % event_id)
			continue
		var set_name := str(timeline.get("set", "none"))
		var stage: Node3D = null
		if StoryController.SETS.has(set_name):
			stage = (load(StoryController.SETS[set_name]) as PackedScene).instantiate()
		elif set_name != "none":
			problems.append("%s uses an unknown set %s" % [event_id, set_name])
		var clips_by_actor: Dictionary = {}
		for actor: Dictionary in timeline.get("actors", []):
			var who := str(actor["who"])
			var scene_path: String = StoryController.PEOPLE.get(who, "")
			var model: Node3D = null
			if scene_path != "":
				model = (load(scene_path) as PackedScene).instantiate()
			elif GameData.get_fish(StringName(who)) != null:
				model = GameData.get_fish(StringName(who)).model_scene.instantiate()
			if model == null:
				problems.append("%s: unknown actor %s" % [event_id, who])
				continue
			var player := model.get_node_or_null("AnimationPlayer") as AnimationPlayer
			clips_by_actor[who] = player.get_animation_list() if player != null else PackedStringArray()
			if actor.has("clip") and not clips_by_actor[who].has(str(actor["clip"])):
				problems.append("%s: %s has no clip %s" % [event_id, who, actor["clip"]])
			for key: String in ["marker", "spot"]:
				if actor.has(key) and (stage == null or stage.get_node_or_null("Markers/%s" % actor[key]) == null):
					problems.append("%s: missing marker %s" % [event_id, actor[key]])
			model.free()
		for prop: Dictionary in timeline.get("props", []):
			if not ResourceLoader.exists(StoryController.PROP_PATH % prop["prop"]):
				problems.append("%s: missing prop %s" % [event_id, prop["prop"]])
		var cameras: Dictionary = timeline.get("cameras", {})
		for camera: Dictionary in cameras.values():
			if camera.has("marker") and (stage == null or stage.get_node_or_null("Markers/%s" % camera["marker"]) == null):
				problems.append("%s: missing camera marker %s" % [event_id, camera["marker"]])
		for step: Dictionary in timeline.get("steps", []):
			if step.has("cam") and not cameras.has(str(step["cam"])):
				problems.append("%s: unknown camera %s" % [event_id, step["cam"]])
			if step.has("clip"):
				var who := str(step["clip"])
				if not clips_by_actor.has(who) or not clips_by_actor[who].has(str(step["name"])):
					problems.append("%s: %s cannot play %s" % [event_id, who, step["name"]])
			for key: String in ["say", "show", "hide"]:
				if step.has(key) and key != "say" and not clips_by_actor.has(str(step[key])):
					problems.append("%s: %s is not on stage" % [event_id, step[key]])
			if step.has("say") and StoryTimelines.speaker_name(StringName(step["say"])) == "":
				problems.append("%s: speaker %s has no name" % [event_id, step["say"]])
		if stage != null:
			stage.free()
	check_empty(problems, "every timeline's set, actors, clips, markers and cameras exist")
	return true


func test_first_scenes_carry_the_final_script() -> bool:
	var first_fish := StoryTimelines.to_dialogue(StoryTimelines.get_timeline(&"story_first_fish")["steps"])
	check_eq(first_fish.size(), 7, "the first fish conversation has seven lines")
	check_eq(first_fish[0]["text"], "Put me down.", "the Catfish opens")
	check_eq(first_fish[6]["text"], "Square up.", "and ends it")
	var market := StoryTimelines.get_timeline(&"story_first_market")
	check_eq(StoryTimelines.to_dialogue(market["after_payment"]).size(), 4, "the first payment has its four lines")
	var arowana := FishDialogue.after_duel(ContentIds.BOSS_FISH_ID, true, 1, true)
	check_eq(arowana[arowana.size() - 1]["text"], "That's not a no.", "Arowana's first defeat ends on Darto")
	return true


# --- Skip (STORY-007, NAR-002) ----------------------------------------------

func test_skipping_applies_everything_watching_would() -> bool:
	var scene: Node = (load(STORY_SCENE) as PackedScene).instantiate()
	# Played on its own, outside the router: only the controller is used.
	var controller := scene.get_node("StoryController") as StoryController
	var stage := scene.get_node("StageRoot") as Node3D
	var ui := scene.get_node("StoryCanvas/StoryUI") as StoryUi
	scene.set_script(null)
	tree.root.add_child(scene)
	controller.setup(stage, ui)
	controller.play(&"story_debt_600k")
	await wait_frames(5)
	check(not controller.is_done(), "the call waits for the player")
	check(controller.get_actor("darto") != null, "Darto is on stage")
	var skipped := [false]
	controller.finished.connect(func(_id: StringName, was_skipped: bool) -> void: skipped[0] = was_skipped)
	controller.skip()
	check(controller.is_done(), "holding skip ends the scene")
	check(skipped[0], "and says it was skipped")
	check(StoryDirector.is_event_seen(&"story_debt_600k"), "the event is seen")
	check(bool(GameState.get_story_value(&"fish_book_unlocked")), "its unlock still applies")
	check_eq(GameState.get_story_value(&"chapter"), "chapter_4", "and so does its chapter")
	await wait_frames(3)
	scene.queue_free()
	await wait_frames(2)
	return true


## While a dialogue is up it has the controls: Space or a click advances the
## line and never also presses the focused button or the one under the
## pointer (it did both in the Market). With an overlay open over it, the
## overlay keeps its input.
func test_dialogue_comes_before_buttons() -> bool:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	tree.root.add_child(holder)
	var button := GameButton.new()
	button.text = "SELL ALL"
	button.position = Vector2(40.0, 40.0)
	button.size = Vector2(220.0, 60.0)
	holder.add_child(button)
	var presses: Array[int] = [0]
	button.pressed.connect(func() -> void: presses[0] += 1)
	var box := DialogueBox.new()
	tree.root.add_child(box)
	await wait_frames(2)
	button.grab_focus()
	var lines: Array[Dictionary] = [
		{"speaker": "Bu Yati", "text": "One."}, {"speaker": "Bu Yati", "text": "Two."}, {"speaker": "Bu Yati", "text": "Three."}]
	box.play(lines)
	await wait_frames(2)
	box.advance()
	_send_key(KEY_SPACE)
	await wait_frames(2)
	check_eq(box.get_current_line().get("text", ""), "Two.", "Space advances the dialogue")
	check_eq(presses[0], 0, "and does not press the focused button")
	box.advance()
	_send_click(button.get_global_rect().get_center())
	await wait_frames(2)
	check_eq(box.get_current_line().get("text", ""), "Three.", "a click advances the dialogue")
	check_eq(presses[0], 0, "and does not press the button under it")
	box.skip()
	await wait_frames(1)
	_send_key(KEY_SPACE)
	await wait_frames(2)
	check_eq(presses[0], 1, "once the dialogue is over, Space presses the button again")
	box.queue_free()
	holder.queue_free()
	await wait_frames(1)
	return true


func _send_key(keycode: Key) -> void:
	for pressed: bool in [true, false]:
		var key := InputEventKey.new()
		key.keycode = keycode
		key.physical_keycode = keycode
		key.pressed = pressed
		tree.root.push_input(key)


func _send_click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = at
		click.global_position = at
		click.pressed = pressed
		tree.root.push_input(click)


func test_lines_wait_for_the_player_and_advance_on_tap() -> bool:
	var scene: Node = (load(STORY_SCENE) as PackedScene).instantiate()
	var controller := scene.get_node("StoryController") as StoryController
	var ui := scene.get_node("StoryCanvas/StoryUI") as StoryUi
	scene.set_script(null)
	tree.root.add_child(scene)
	controller.setup(scene.get_node("StageRoot"), ui)
	controller.play(&"story_first_fish")
	check(await wait_until(func() -> bool: return ui.get_line_text() != "", 5.0), "the first line appears")
	check_eq(ui.get_line_text(), "Put me down.", "it is the Catfish's")
	await wait_seconds(0.6)
	check_eq(ui.get_line_text(), "Put me down.", "and stays until the player taps")
	ui.advanced.emit()
	check(await wait_until(func() -> bool: return ui.get_line_text() == "...What?", 3.0), "a tap shows the next line")
	controller.skip()
	await wait_frames(3)
	scene.queue_free()
	await wait_frames(2)
	return true


## The prologue's title shot on the lake road: Darto alone at the lake.
## Rini stays home (she was once re-spawned there, on top of Darto).
func test_prologue_title_shot_leaves_rini_at_home() -> bool:
	var scene: Node = (load(STORY_SCENE) as PackedScene).instantiate()
	var controller := scene.get_node("StoryController") as StoryController
	var ui := scene.get_node("StoryCanvas/StoryUI") as StoryUi
	scene.set_script(null)
	tree.root.add_child(scene)
	controller.setup(scene.get_node("StageRoot"), ui)
	controller.play(&"story_prologue_zero")
	await wait_frames(3)
	check(controller.get_actor("rini") != null, "Rini is at home in the first shot")
	controller._build_lake_road()
	await wait_frames(2)
	check(controller.get_actor("rini") == null, "Rini does not come to the lake")
	var darto := controller.get_actor("darto")
	if check(darto != null, "Darto is at the lake"):
		var lake_spot := scene.get_node("StageRoot").find_child("DartoSpot", true, false) as Node3D
		check(lake_spot != null and darto.global_position.is_equal_approx(lake_spot.global_position), "on his fishing spot")
	controller.skip()
	await wait_frames(3)
	scene.queue_free()
	await wait_frames(2)
	return true


## The story phone is a chat app (GDD 168.3): the prologue opens the CepatCash
## business chat with the balance and debt as account cards and the reminder
## as a message; a chat opens that person's thread with Darto on the right;
## a call shows the call view.
func test_the_phone_is_a_chat_app() -> bool:
	var scene: Node = (load(STORY_SCENE) as PackedScene).instantiate()
	var controller := scene.get_node("StoryController") as StoryController
	var ui := scene.get_node("StoryCanvas/StoryUI") as StoryUi
	scene.set_script(null)
	tree.root.add_child(scene)
	controller.setup(scene.get_node("StageRoot"), ui)
	controller.play(&"story_prologue_zero")
	var phone := ui.get_phone()
	check(await wait_until(func() -> bool: return phone.is_open(), 6.0), "the phone comes out")
	check_eq(phone.get_contact(), ChatPhone.CEPATCASH, "on the CepatCash chat")
	check(phone.get_chat_text().contains("Rp 18,430"), "the balance is an account card")
	ui.advanced.emit()
	check(await wait_until(func() -> bool: return phone.get_chat_text().contains("Rp 1,800,000"), 4.0), "the debt card follows")
	ui.advanced.emit()
	check(await wait_until(func() -> bool: return phone.get_message_count() == 1, 3.0), "the reminder is a message from CepatCash")
	check(phone.get_chat_text().contains("outstandingly disappointed"), "with its text")
	controller.skip()
	await wait_frames(3)
	scene.queue_free()
	await wait_frames(2)

	var chat := ChatPhone.new()
	chat.size = Vector2(340, 460)
	tree.root.add_child(chat)
	await wait_frames(1)
	chat.open_thread(ChatPhone.CEPATCASH, "CepatCash")
	chat.add_message("Thank you.", false, "CEPATCASH")
	chat.open_thread(&"rini", "Rini")
	check_eq(chat.get_message_count(), 0, "another contact opens a fresh thread")
	chat.add_message("How was the lake?", false)
	chat.add_message("Both.", true)
	check_eq(chat.get_message_count(), 2, "two bubbles")
	var sides := PackedStringArray()
	for bubble: Node in chat.find_children("*", "PanelContainer", true, false):
		if bubble is ChatPhone.Bubble:
			sides.append("right" if (bubble as Control).size_flags_horizontal == Control.SIZE_SHRINK_END else "left")
	check_eq(sides, PackedStringArray(["left", "right"]), "Rini on the left, Darto on the right")
	check(chat.get_chat_text().contains(TextDb.t(&"story.phone.time")), "messages carry a time")
	chat.show_call(&"nisa", "Nisa")
	check(chat.is_call_visible(), "a call shows the call view")
	chat.close()
	check(not chat.is_open(), "closing puts the phone away")
	chat.queue_free()
	await wait_frames(1)
	return true


# --- Systems around the story -----------------------------------------------

func test_banter_is_occasional_and_never_beside_an_event() -> bool:
	var market_scene: GDScript = load("res://scripts/gameplay/market/market_scene.gd")
	check(market_scene.pick_banter(1, 0).is_empty(), "never on the first visits")
	check(not market_scene.pick_banter(3, 0).is_empty(), "now and then on later visits")
	check(market_scene.pick_banter(4, 0).is_empty(), "not every visit")
	check(market_scene.pick_banter(3, 1).is_empty(), "never when a story event is waiting")
	var first: Array[Dictionary] = market_scene.pick_banter(3, 0)
	var second: Array[Dictionary] = market_scene.pick_banter(6, 0)
	check(first[0]["text"] != second[0]["text"], "the exchanges take turns")
	return true


func test_cepatcash_keeps_its_distance() -> bool:
	check(CePatCash.poll(10.0).is_empty(), "nothing at the start of a session")
	check(CePatCash.poll(10.0 + CePatCash.MIN_INTERVAL_SEC - 1.0).is_empty(), "nothing within 18 minutes")
	var notice := CePatCash.poll(10.0 + CePatCash.MAX_INTERVAL_SEC + 1.0)
	check(not notice.is_empty(), "one arrives within 35 minutes")
	check(TextDb.has_key(&"cepatcash.1.title") and str(notice["title"]) == TextDb.t(&"cepatcash.1.title"), "the first of the pool")
	check(CePatCash.poll(10.0 + CePatCash.MAX_INTERVAL_SEC + 2.0).is_empty(), "and the next waits again")
	for seed_value: int in [1, 50, 999, 123456]:
		var gap := CePatCash.interval_for(seed_value)
		check(gap >= CePatCash.MIN_INTERVAL_SEC and gap <= CePatCash.MAX_INTERVAL_SEC, "gaps stay within 18-35 minutes")
	CePatCash.reset()
	GameState.debug_set_debt_remaining(0)
	CePatCash.poll(0.0)
	check(CePatCash.poll(CePatCash.MAX_INTERVAL_SEC * 3.0).is_empty(), "silent once the debt is paid")
	return true


# STORY-012
func test_postgame_turns_the_ledger_into_family_savings() -> bool:
	var market := MarketController.new()
	market.auto_route = false
	market.transaction_lock_enabled = false
	GameState.debug_set_cash(80000)
	check_eq(market.deposit_savings(25000), 0, "no savings before the post-game")
	check(not MarketDebtPanel.is_savings_mode(), "the ledger is still the debt")
	GameState.set_story_value(&"postgame_unlocked", true)
	check(MarketDebtPanel.is_savings_mode(), "the post-game turns it into savings")
	check_eq(market.deposit_savings(25000), 25000, "cash goes in")
	check_eq(market.deposit_savings(999999), 55000, "never more than the cash on hand")
	check_eq(GameState.get_cash(), 0, "the cash left the wallet")
	check_eq(int(GameState.get_stat(&"family_savings")), 80000, "and the savings hold it")
	check_eq(market.deposit_savings(1000), 0, "nothing to save from an empty wallet")
	market.free()
	return true


func test_arowana_first_win_never_plays_twice() -> bool:
	GameState.record_encounter(ContentIds.BOSS_FISH_ID)
	GameState.record_fish_win(ContentIds.BOSS_FISH_ID, 5.0, &"boxing")
	# The Result scene shows the exchange and completes the event.
	StoryDirector.complete_event(&"story_arowana_first_win", false)
	StoryDirector.evaluate_story_triggers()
	check(not StoryDirector.get_pending_events().has(&"story_arowana_first_win"), "the Market does not queue it again")
	check(bool(GameState.get_story_value(&"arowana_first_win_seen")), "and later wins use the normal lines")
	return true


# --- Real scenes ------------------------------------------------------------

func test_new_game_opens_with_the_prologue() -> bool:
	SaveManager.delete_save()
	GameState.clear_game()
	tree.change_scene_to_packed(load("res://scenes/menu/main_menu.tscn"))
	await wait_frames(4)
	(tree.current_scene.get_node("MenuCanvas/SafeRoot/MenuButtons/NewGameButton") as BaseButton).pressed.emit()
	if not check(await _wait_for_scene(&"story"), "New Game opens the story"):
		return true
	var controller := _story_controller()
	check_eq(controller.event_id, &"story_prologue_zero", "with the prologue")
	controller.skip()
	check(await _wait_for_scene(&"fishing"), "and the prologue leads to the lake")
	check(StoryDirector.is_event_seen(&"story_prologue_zero"), "the prologue is seen")
	return true


func test_menu_credits_return_to_the_menu() -> bool:
	SceneRouter.goto_credits(true)
	if not check(await _wait_for_scene(&"credits"), "the credits open from the menu"):
		return true
	var credits := tree.current_scene
	check(credits.get_node("CreditsCanvas/SafeRoot/Roll").get_child_count() >= StoryTimelines.get_credits().size(), "every credit line is in the roll")
	# HOLD TO SKIP and its bar sit in the middle of the screen, one above the other.
	await wait_frames(2)
	var safe_root := credits.get_node("CreditsCanvas/SafeRoot") as Control
	var label := credits.get_node("CreditsCanvas/SafeRoot/SkipLabel") as Label
	var bar := credits.get_node("CreditsCanvas/SafeRoot/SkipHoldIndicator") as Control
	var middle := safe_root.size.x * 0.5
	check_near(bar.position.x + bar.size.x * 0.5, middle, 0.5, "the hold bar is centred")
	check_eq(label.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER, "HOLD TO SKIP is centred")
	check_near(label.position.x + label.size.x * 0.5, middle, 0.5, "on the same middle as the bar")
	check(label.position.y + label.size.y <= bar.position.y + 2.0, "the text sits above the bar")
	credits.finish(true)
	check(await _wait_for_scene(&"main_menu"), "and they return to the menu")
	check(not bool(GameState.get_story_value(&"postgame_unlocked")), "without unlocking anything")
	return true


# STORY-008: the last payment, the family, the credits, the post-game.
func test_paying_the_debt_runs_the_ending_into_the_postgame() -> bool:
	StoryDirector.complete_event(&"story_prologue_zero", true)
	GameState.debug_set_debt_remaining(20000)
	GameState.debug_set_cash(20000)
	SceneRouter.goto_market()
	if not check(await _wait_for_scene(&"market"), "reach the Market"):
		return true
	var market := tree.current_scene
	var controller := market.get_node("MarketController") as MarketController
	controller.transaction_lock_enabled = false
	(market.get_node("DialogueBox") as DialogueBox).skip()
	check_eq(controller.pay_debt(20000), 20000, "PAY REMAINING")
	check_eq(GameState.get_debt_remaining(), 0, "the debt is Rp 0")
	check(not GameState.is_fish_discovered(ContentIds.BOSS_FISH_ID), "Don Arowana was never needed")
	(market.get_node("MarketCanvas/SafeRoot/LeaveMarketButton") as BaseButton).pressed.emit()

	check(await _wait_for_scene(&"story"), "leaving plays the story")
	check_eq(_story_controller().event_id, &"story_debt_paid", "the finale outranks every milestone")
	_story_controller().skip()
	check(await _wait_for_scene(&"story", 2), "the family scene follows")
	check_eq(_story_controller().event_id, &"story_final_family", "on the next Sunday")
	check(_story_controller().get_actor("nisa") != null and _story_controller().get_actor("rini") != null, "with Rini and Nisa")
	_story_controller().skip()
	check(await _wait_for_scene(&"credits"), "then the credits roll")
	tree.current_scene.finish(true)
	check(await _wait_for_scene(&"story", 3), "after the credits, the post-game unlock")
	check_eq(_story_controller().event_id, &"story_postgame_unlock", "FREE FISHING MODE UNLOCKED")
	# Revision 6.12: the unlock card sits like every popup card, in the middle
	# of the screen and clear of its sides (it was full width, at 28% height).
	var story_ui := tree.current_scene.get_node("StoryCanvas/StoryUI") as StoryUi
	if check(await wait_until(story_ui.is_unlock_visible, 5.0), "the unlock card shows"):
		await wait_frames(2)
		var card := (story_ui.get_node("UnlockPanel") as Control).get_global_rect()
		var screen := tree.root.get_visible_rect().size
		check_near(card.get_center().x, screen.x * 0.5, 0.5, "the unlock card is centred across the screen")
		check_near(card.get_center().y, screen.y * 0.5, 0.5, "and down it")
		check(card.position.x >= float(OverlayPanel.SCREEN_MARGIN) - 0.5, "clear of the screen's sides")
	_story_controller().skip()
	check(await _wait_for_scene(&"fishing"), "and back to the lake")

	check(bool(GameState.get_story_value(&"ending_completed")), "the ending is recorded")
	check(bool(GameState.get_story_value(&"postgame_unlocked")), "the post-game is open")
	check_eq(GameState.get_story_value(&"chapter"), "postgame", "the story is in its post-game")
	for event_id: StringName in [&"story_debt_paid", &"story_final_family", &"story_postgame_unlock"]:
		check(StoryDirector.is_event_seen(event_id), "%s is seen" % event_id)
	for milestone: StringName in [&"story_debt_100k", &"story_debt_600k", &"story_debt_1650k"]:
		check(StoryDirector.is_event_seen(milestone), "the finale retired %s" % milestone)
	var saved: Variant = read_json(SaveManager.get_save_path())
	check(typeof(saved) == TYPE_DICTIONARY and bool(saved["story"]["postgame_unlocked"]), "the save holds the post-game")

	SceneRouter.goto_main_menu()
	check(await _wait_for_scene(&"main_menu"), "the Main Menu")
	check(tree.current_scene.is_ending_dressed(), "has the family's glasses by the bench")
	return true


## Story chat lines are aliases of the line before them in the text table; the
## player must see the line, never the key it points to.
func test_story_text_aliases_resolve_to_the_line() -> bool:
	var data: Variant = read_json("res://data/story/story_timelines.json")
	if not check(typeof(data) == TYPE_DICTIONARY, "the story timelines load"):
		return true
	var checked := 0
	for timeline_id: String in (data["timelines"] as Dictionary):
		for step: Dictionary in (data["timelines"][timeline_id]["steps"] as Array):
			for field: String in ["text", "phone"]:
				if not step.has(field):
					continue
				var shown := TextDb.t(StringName(step[field]))
				check(not shown.begins_with("story.") and not shown.begins_with("#"), "%s shows its line, not a key" % step[field])
				checked += 1
	check(checked > 50, "every story line was checked")
	check_eq(TextDb.t(&"story.story_debt_300k.02"), TextDb.t(&"story.story_debt_300k.01"), "an alias shows the line it names")
	return true
