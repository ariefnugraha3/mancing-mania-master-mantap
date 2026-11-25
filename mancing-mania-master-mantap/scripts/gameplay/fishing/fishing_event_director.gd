class_name FishingEventDirector
extends Node
## Runs the small happenings at the fishing spot (revision 6.12, GDD 37.5).
## FishingEvents says which one is due; this plays it on the world's
## FishingEventStage, puts its words in the HUD's speech card and hands out
## what a bottle holds.
##
## A happening never gets in the way of the fishing: it only starts while it
## is quiet (Darto idle or waiting, nothing else on screen), and the moment a
## bite comes its words and its tap target go, and anything on the float flies
## off. A bite is never missed because of one.

## Off in the test runner and in QA quick-wait runs, so they never cover what
## a test checks; a test of the happenings turns them back on.
static var enabled: bool = true

## How long one line stays in the speech card.
const LINE_SEC := 2.6
const DRIZZLE_SEC := 14.0
const BOTTLE_SEC := 11.5
## What a bottle holds: money (one of these amounts) or a note.
const BOTTLE_CASH_CHANCE := 0.65
const BOTTLE_CASH: Array[int] = [500, 1000, 1500, 2000]
const BOTTLE_NOTES := 4
## Lines per happening (text keys fishing.event.<id>.<n>).
const DARTO_LINES: Dictionary = {
	FishingEvents.FISH_JUMP: 3, &"bird": 3, &"gull": 3, FishingEvents.FROG: 2, FishingEvents.DRAGONFLY: 3,
	FishingEvents.SANDAL: 3, FishingEvents.DRIZZLE: 3, FishingEvents.DUCKS: 3,
}
## The comic ones: a fish's taunts (.them, then Darto's .darto), the
## collector's visits (.them, .darto, .them2; "free" once the debt is gone),
## and Darto's word to the cat (an empty or a full bucket).
const HECKLES := 4
const COLLECTOR_VISITS := 3
const COLLECTOR_OVERDUE_VISITS := 2
const CAT_LINES := 2
## Exchanges with a neighbour or the children (keys .<n>.them / .<n>.darto).
const EXCHANGES := 3
## The family's texts follow the story: who sends each one, per stage.
const FAMILY: Dictionary = {
	&"early": [&"nisa", &"rini", &"nisa"],
	&"mid": [&"rini", &"nisa", &"rini"],
	&"late": [&"rini", &"nisa", &"rini"],
	&"free": [&"rini", &"nisa", &"rini"],
}

var _events: FishingEvents
var _stage: FishingEventStage
var _hud: FishingHud
var _camera: Camera3D
var _location: StringName
var _random := RandomNumberGenerator.new()
var _interrupted: bool = false
var _bottle: Node3D
var _bottle_open: bool = false
var _bottle_taken: bool = false
## The fishing scene's dialogue box: the family's texts and what a bottle
## holds read there, like a fish's lines. A bite closes it.
var _dialogue: DialogueBox
var _dialogue_ours: bool = false


func setup(world: FishingWorld, hud: FishingHud, dialogue: DialogueBox, location_id: StringName) -> void:
	_stage = world.get_event_stage()
	_hud = hud
	_dialogue = dialogue
	_camera = world.get_camera()
	_location = location_id
	_random.seed = RNGService.cosmetic.randi()
	_events = FishingEvents.new(location_id, _random)
	_hud.event_tapped.connect(_on_tapped)


## Called every frame by the fishing scene. `quiet`: Darto idle or waiting
## with nothing else on screen.
func update(delta: float, quiet: bool, float_in_water: bool) -> void:
	if _bottle_open and is_instance_valid(_bottle):
		_hud.place_event_tap(_camera.unproject_position(_bottle.global_position))
	if not enabled:
		return
	_events.overdue = GameState.is_debt_overdue()
	var next := _events.advance(delta, quiet, float_in_water)
	if next != &"":
		_run(next)


## A bite, a strike or anything else that needs the player: the words and the
## tap target go now.
func interrupt() -> void:
	_interrupted = true
	if _dialogue_ours and _dialogue.is_playing():
		_dialogue.skip()
	_hud.hide_event_caption()
	_close_bottle()
	_stage.interrupt()


func get_events() -> FishingEvents:
	return _events


## Starts `event_id` now, whatever the schedule says (tests, QA).
func start(event_id: StringName) -> void:
	if _events.get_running() == &"":
		_events.force(event_id)
		_run(event_id)


# --- Happenings ----------------------------------------------------------------

func _run(event_id: StringName) -> void:
	_interrupted = false
	GameLog.info(&"EVENT", "happening", {"id": String(event_id), "spot": String(_location)})
	match event_id:
		FishingEvents.FISH_JUMP:
			await _fish_jump()
		FishingEvents.BIRD:
			await _bird()
		FishingEvents.FROG:
			await _frog()
		FishingEvents.DRAGONFLY:
			await _dragonfly()
		FishingEvents.SANDAL:
			await _sandal()
		FishingEvents.BOTTLE:
			await _bottle_drift()
		FishingEvents.FAMILY:
			await _family()
		FishingEvents.DRIZZLE:
			await _drizzle()
		FishingEvents.MOTOR:
			await _exchange(_stage.motor_pass(), 2.0, &"motor", &"neighbour")
		FishingEvents.KITES:
			await _exchange(_stage.kites(), 3.0, &"kites", &"kids")
		FishingEvents.HECKLE:
			await _heckle()
		FishingEvents.COLLECTOR:
			await _collector()
		FishingEvents.DUCKS:
			await _ducks()
		FishingEvents.CAT:
			await _cat()
	if is_inside_tree():
		_events.finish()


func _fish_jump() -> void:
	var pool := GameData.get_location_fish(_location)
	var fish: FishData = pool[_random.randi() % pool.size()] if not pool.is_empty() else null
	var length := _stage.fish_jump(fish)
	await _wait(0.7)
	if _random.randf() < 0.6:
		await _darto(FishingEvents.FISH_JUMP)
	await _wait(maxf(length - 0.7, 0.0))


func _bird() -> void:
	var sea := FishingEvents.is_sea(_location)
	var length := _stage.bird_dive(sea)
	await _wait(1.3)
	await _darto(&"gull" if sea else &"bird")
	await _wait(maxf(length - 1.3 - LINE_SEC, 0.0))


func _frog() -> void:
	var length := _stage.frog()
	await _wait(0.6)
	_say(TextDb.t(&"speaker.frog"), TextDb.t(&"fishing.event.frog.croak"), 1.3)
	await _wait(1.4)
	await _darto(FishingEvents.FROG)
	await _wait(maxf(length - 2.0 - LINE_SEC, 0.0))


func _dragonfly() -> void:
	var length := _stage.dragonfly()
	await _wait(1.3)
	await _darto(FishingEvents.DRAGONFLY)
	await _wait(maxf(length - 1.3 - LINE_SEC, 0.0))


func _sandal() -> void:
	_stage.drift(FishingEvents.SANDAL)
	await _wait(3.0)
	await _darto(FishingEvents.SANDAL)
	await _wait(11.0 - 3.0 - LINE_SEC)


## A bottle drifts past within reach: GRAB IT follows it until it is tapped
## or gone.
func _bottle_drift() -> void:
	_bottle = _stage.drift(FishingEvents.BOTTLE)
	_bottle_open = true
	_bottle_taken = false
	_say(_darto_name(), TextDb.t(&"fishing.event.bottle.spotted"), LINE_SEC)
	var left := BOTTLE_SEC
	while left > 0.0 and _bottle_open and is_inside_tree():
		await get_tree().process_frame
		if is_inside_tree() and not get_tree().paused:
			left -= get_process_delta_time()
	if _bottle_taken:
		await _wait(0.2)
		await _until_read()
		return
	_close_bottle()
	if not _interrupted:
		await _say_and_wait(_darto_name(), TextDb.t(&"fishing.event.bottle.missed"))


func _on_tapped() -> void:
	if not _bottle_open:
		return
	_bottle_taken = true
	_close_bottle()
	_stage.collect(_bottle)
	_hud.hide_event_caption()
	_open_bottle()


## What the bottle held: money (kept, and saved) or a note, read in the
## dialogue box.
func _open_bottle() -> void:
	var title := TextDb.t(&"fishing.event.bottle.title")
	var text := ""
	if _random.randf() < BOTTLE_CASH_CHANCE:
		var amount: int = BOTTLE_CASH[_random.randi() % BOTTLE_CASH.size()]
		GameState.add_cash(amount)
		AudioManager.play_sfx(&"event_coin")
		SaveManager.save_game(&"bottle")
		GameLog.info(&"EVENT", "bottle held money", {"amount": amount})
		text = TextDb.tf(&"fishing.event.bottle.cash", {"amount": Money.format_rp(amount)})
	else:
		AudioManager.play_ui(&"ui_click")
		text = TextDb.t(StringName("fishing.event.bottle.note.%d" % (1 + _random.randi() % BOTTLE_NOTES)))
	_read(title, text)


func _close_bottle() -> void:
	_bottle_open = false
	_hud.hide_event_tap()


## A text from Rini or Nisa, like the CepatCash notices, that follows the story.
func _family() -> void:
	var stage := family_stage()
	var senders: Array = FAMILY[stage]
	var index := _random.randi() % senders.size()
	var sender: StringName = senders[index]
	var title := TextDb.tf(&"fishing.event.family.title", {"name": TextDb.t(StringName("speaker.%s" % sender))})
	AudioManager.play_ui(&"ui_click")
	_read(title, TextDb.t(StringName("fishing.event.family.%s.%d" % [stage, index + 1])))
	await _until_read()


## Where the story is: early, mid (from Rini's "I saw the payment"), late (from
## "You're past halfway") or free (the debt is gone). The thresholds are those
## story events' own, so the family's texts move with the milestones.
static func family_stage() -> StringName:
	if GameState.get_debt_remaining() <= 0:
		return &"free"
	var paid := GameState.get_debt_paid()
	if paid >= _milestone(&"story_debt_1000k", 1_100_000):
		return &"late"
	if paid >= _milestone(&"story_debt_300k", 350_000):
		return &"mid"
	return &"early"


static func _milestone(event_id: StringName, fallback: int) -> int:
	var event := StoryDirector.get_event(event_id)
	return int(event.trigger_value) if event != null else fallback


func _drizzle() -> void:
	_stage.drizzle(DRIZZLE_SEC)
	_hud.set_gloom(0.16, 1.6)
	await _wait(2.5)
	await _darto(FishingEvents.DRIZZLE)
	await _wait(DRIZZLE_SEC - 2.5 - LINE_SEC - 1.5)
	_hud.set_gloom(0.0, 1.5)
	await _wait(1.5)


## The neighbour or the children call out, and Darto answers.
func _exchange(length: float, delay: float, event_key: StringName, speaker: StringName) -> void:
	var line := 1 + _random.randi() % EXCHANGES
	await _wait(delay)
	await _say_and_wait(TextDb.t(StringName("speaker.%s" % speaker)), TextDb.t(StringName("fishing.event.%s.%d.them" % [event_key, line])))
	await _say_and_wait(_darto_name(), TextDb.t(StringName("fishing.event.%s.%d.darto" % [event_key, line])))
	await _wait(maxf(length - delay - LINE_SEC * 2.0, 0.0))


# --- The comic ones ----------------------------------------------------------

## A fish of this spot pops up to mock the bait; Darto answers; it gloats and
## dives.
func _heckle() -> void:
	var pool := GameData.get_location_fish(_location)
	if pool.is_empty():
		return
	var fish: FishData = pool[_random.randi() % pool.size()]
	var line := 1 + _random.randi() % HECKLES
	var length := _stage.heckle(fish, 0.5 + LINE_SEC * 2.0 - 0.4)
	await _wait(0.5)
	await _say_and_wait(FishDialogue.speaker_name(fish.id), TextDb.t(StringName("fishing.event.heckle.%d.them" % line)))
	await _say_and_wait(_darto_name(), TextDb.t(StringName("fishing.event.heckle.%d.darto" % line)))
	await _wait(maxf(length - 0.5 - LINE_SEC * 2.0, 0.0))


## CepatCash's collector stops behind Darto. Once the debt is gone he offers
## a new loan instead; while Darto is overdue he blasts his megaphone louder.
func _collector() -> void:
	var visit := "free"
	if GameState.get_debt_remaining() > 0:
		if GameState.is_debt_overdue():
			visit = "overdue.%d" % (1 + _random.randi() % COLLECTOR_OVERDUE_VISITS)
		else:
			visit = str(1 + _random.randi() % COLLECTOR_VISITS)
	var length := _stage.collector(LINE_SEC * 3.0 + 0.4)
	var collector := TextDb.t(&"speaker.collector")
	await _wait(2.2)
	await _say_and_wait(collector, TextDb.t(StringName("fishing.event.collector.%s.them" % visit)))
	await _say_and_wait(_darto_name(), TextDb.t(StringName("fishing.event.collector.%s.darto" % visit)))
	await _say_and_wait(collector, TextDb.t(StringName("fishing.event.collector.%s.them2" % visit)))
	await _wait(maxf(length - 2.2 - LINE_SEC * 3.0, 0.0))


## The ducks parade past; the last duckling panics.
func _ducks() -> void:
	var length := _stage.ducks()
	var duck := TextDb.t(&"speaker.duck")
	await _wait(2.0)
	await _say_and_wait(duck, TextDb.t(&"fishing.event.ducks.quack"))
	await _darto(FishingEvents.DUCKS)
	await _wait(0.6)
	await _say_and_wait(duck, TextDb.t(&"fishing.event.ducks.late"))
	await _wait(maxf(length - 2.6 - LINE_SEC * 3.0, 0.0))


## The cat looks into the bucket, then at Darto.
func _cat() -> void:
	var length := _stage.cat(_location == &"mawar")
	await _wait(4.3)
	var kind := "full" if GameState.get_bucket_total_count() > 0 else "empty"
	await _say_and_wait(_darto_name(), TextDb.t(StringName("fishing.event.cat.%s.%d" % [kind, 1 + _random.randi() % CAT_LINES])))
	_say(TextDb.t(&"speaker.cat"), TextDb.t(&"fishing.event.cat.meow"), LINE_SEC)
	await _wait(maxf(length - 4.3 - LINE_SEC, 0.0))


# --- Words -------------------------------------------------------------------

## A text-only happening in the dialogue box, with TAP TO CONTINUE.
func _read(title: String, text: String) -> void:
	if _interrupted or _dialogue.is_playing():
		return
	_dialogue_ours = true
	_dialogue.play([{"speaker": title, "text": text}] as Array[Dictionary])


## Until the player taps it away, or a bite closes it.
func _until_read() -> void:
	while _dialogue_ours and _dialogue.is_playing() and is_inside_tree():
		await get_tree().process_frame
	_dialogue_ours = false


func _darto(pool: StringName) -> void:
	var count := int(DARTO_LINES.get(pool, 0))
	if count <= 0:
		return
	var key := StringName("fishing.event.%s.%d" % [pool, 1 + _random.randi() % count])
	await _say_and_wait(_darto_name(), TextDb.t(key))


func _say(speaker: String, text: String, seconds: float) -> void:
	if not _interrupted:
		_hud.show_event_caption(speaker, text, seconds)


func _say_and_wait(speaker: String, text: String) -> void:
	_say(speaker, text, LINE_SEC)
	await _wait(LINE_SEC)


func _darto_name() -> String:
	return TextDb.t(&"speaker.darto")


## Waits game time: a paused game pauses the happening too.
func _wait(seconds: float) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		return
	await get_tree().create_timer(seconds, false).timeout
