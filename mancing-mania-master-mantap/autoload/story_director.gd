extends Node
## Narrative event queue and Market-exit arbitration (GDD 169.9, 177).
##
## Events are data (res://data/story/<id>.tres). A trigger that becomes true
## puts its event in the pending queue exactly once. When the player leaves the
## Market, at most one pending event is let through: the one with the highest
## priority. The rest wait for a later visit.
##
## Cutscene playback belongs to the Narrative milestone. Until the Story scene
## exists, an event that is let through completes immediately, so its unlock
## (such as the Fish Book) still happens.

signal story_event_started(event_id: StringName)
signal story_event_finished(event_id: StringName, skipped: bool)

const EVENT_PATH := "res://data/story/%s.tres"
const KEY_SEEN := &"seen_events"
const KEY_PENDING := &"pending_events"
const KEY_VISIT_SERIAL := &"market_visit_serial"
const KEY_LAST_EVENT_VISIT := &"last_market_event_visit_serial"

const TRIGGER_DEBT_PAID := &"lifetime_debt_paid"
const TRIGGER_DEBT_CLEARED := &"debt_cleared"
const TRIGGER_FISH_FIRST_WIN := &"fish_first_win"
const TRIGGER_MARKET_VISIT := &"market_visit"
const TRIGGER_NEW_GAME := &"new_game"
const TRIGGER_FIRST_FISH := &"first_fish_landed"
const TRIGGER_AFTER_EVENT := &"after_event"
const TRIGGER_CREDITS := &"credits_complete"
const TRIGGER_TYPES: Array[StringName] = [
	TRIGGER_DEBT_PAID, TRIGGER_DEBT_CLEARED, TRIGGER_FISH_FIRST_WIN, TRIGGER_MARKET_VISIT,
	TRIGGER_NEW_GAME, TRIGGER_FIRST_FISH, TRIGGER_AFTER_EVENT, TRIGGER_CREDITS,
]

## Story flag set when an event completes.
const UNLOCKS: Dictionary[StringName, StringName] = {
	&"story_debt_600k": &"fish_book_unlocked",
	&"story_arowana_first_win": &"arowana_first_win_seen",
}

## Chapter the story is in once an event has completed (GDD Section 11).
const CHAPTERS: Dictionary[StringName, String] = {
	&"story_first_market": "chapter_1",
	&"story_debt_100k": "chapter_2",
	&"story_debt_300k": "chapter_3",
	&"story_debt_600k": "chapter_4",
	&"story_debt_1400k": "chapter_5",
	&"story_debt_1650k": "chapter_6",
	&"story_debt_paid": "finale",
	&"story_final_family": "epilogue",
}

var _events: Dictionary[StringName, StoryEvent] = {}
var _active_event: StringName = &""


# --- Public API (GDD 169.9) -------------------------------------------------

## Queues every Market event whose trigger is now true. Calling it again does
## nothing new: an event that is pending or seen is never queued twice.
func evaluate_story_triggers() -> void:
	for event_id: StringName in ContentIds.STORY_EVENT_IDS:
		var event := get_event(event_id)
		if event == null or not event.market_event:
			continue
		if is_event_seen(event_id) or get_pending_events().has(event_id):
			continue
		if _is_triggered(event):
			enqueue_event(event_id)


## Queues an event. Unknown, already seen and already queued IDs are refused,
## so the queue can never hold a duplicate (GDD 177.9).
func enqueue_event(event_id: StringName) -> void:
	if not ContentIds.STORY_EVENT_IDS.has(event_id):
		GameLog.error(&"STORY", "refused unknown event", {"event": event_id})
		return
	var pending := get_pending_events()
	if pending.has(event_id) or is_event_seen(event_id):
		return
	pending.append(event_id)
	GameState.set_story_events(KEY_PENDING, pending)


func get_pending_events() -> Array[StringName]:
	return GameState.get_story_events(KEY_PENDING)


## Starts a new Market visit; called when the Fishing -> Market transition ends.
## The first visit is the Market tutorial, so its event counts as seen here.
func begin_market_visit() -> void:
	GameState.set_story_value(KEY_VISIT_SERIAL, int(GameState.get_story_value(KEY_VISIT_SERIAL)) + 1)
	if not is_event_seen(&"story_first_market"):
		complete_event(&"story_first_market", true)


## Picks the one event to show for this Market visit, or &"" when nothing is
## eligible or this visit already had its event (GDD 177.4, 177.5, 177.8).
func resolve_market_exit_event() -> StringName:
	var serial := int(GameState.get_story_value(KEY_VISIT_SERIAL))
	if int(GameState.get_story_value(KEY_LAST_EVENT_VISIT)) == serial:
		return &""

	var pending := get_pending_events()
	var best: StringName = &""
	var best_event: StoryEvent = null
	for event_id: StringName in pending:
		var event := get_event(event_id)
		if event == null or not event.market_event or not _requirements_met(event):
			continue
		if best_event == null or _outranks(event, best_event, pending):
			best = event_id
			best_event = event
	if best == &"":
		return &""
	GameState.set_story_value(KEY_LAST_EVENT_VISIT, serial)
	return best


func play_event(event_id: StringName) -> void:
	if not ContentIds.STORY_EVENT_IDS.has(event_id):
		GameLog.error(&"STORY", "refused unknown event", {"event": event_id})
		return
	if not SceneRouter.has_scene(SceneRouter.SCENE_STORY):
		GameLog.error(&"STORY", "story scene is not available in this build", {"event": event_id})
		return
	_active_event = event_id
	story_event_started.emit(event_id)
	SceneRouter.goto_story(event_id)


func skip_active_event() -> void:
	if _active_event != &"":
		complete_event(_active_event, true)


## Records an event as seen and removes it from the queue.
func mark_event_seen(event_id: StringName) -> void:
	if not ContentIds.STORY_EVENT_IDS.has(event_id):
		GameLog.error(&"STORY", "refused unknown event", {"event": event_id})
		return
	var seen := GameState.get_story_events(KEY_SEEN)
	if not seen.has(event_id):
		seen.append(event_id)
		GameState.set_story_events(KEY_SEEN, seen)
	var pending := get_pending_events()
	if pending.has(event_id):
		pending.erase(event_id)
		GameState.set_story_events(KEY_PENDING, pending)
	if _active_event == event_id:
		_active_event = &""


## Removes queued events that can no longer play: unknown IDs and events that
## were already seen.
func supersede_invalid_events() -> void:
	var pending := get_pending_events()
	var kept: Array[StringName] = []
	for event_id: StringName in pending:
		if ContentIds.STORY_EVENT_IDS.has(event_id) and not is_event_seen(event_id):
			kept.append(event_id)
	if kept.size() != pending.size():
		GameState.set_story_events(KEY_PENDING, kept)


# --- Extras -----------------------------------------------------------------

## Finishes an event whether it was watched or skipped: it becomes seen, its
## unlock and chapter apply, and the events it supersedes are retired so they
## never play afterwards (GDD 177.6, 177.7).
func complete_event(event_id: StringName, skipped: bool) -> void:
	if not ContentIds.STORY_EVENT_IDS.has(event_id):
		GameLog.error(&"STORY", "refused unknown event", {"event": event_id})
		return
	mark_event_seen(event_id)
	if UNLOCKS.has(event_id):
		GameState.set_story_value(UNLOCKS[event_id], true)
	if CHAPTERS.has(event_id):
		GameState.set_story_value(&"chapter", CHAPTERS[event_id])
	var event := get_event(event_id)
	if event != null:
		for obsolete: StringName in event.supersedes:
			if not is_event_seen(obsolete):
				mark_event_seen(obsolete)
	GameLog.info(&"STORY", "event completed", {"event": event_id, "skipped": skipped})
	story_event_finished.emit(event_id, skipped)


func is_event_seen(event_id: StringName) -> bool:
	return GameState.get_story_events(KEY_SEEN).has(event_id)


func get_active_event() -> StringName:
	return _active_event


## The definition of an event, or null when its resource is missing.
func get_event(event_id: StringName) -> StoryEvent:
	if _events.has(event_id):
		return _events[event_id]
	var path := EVENT_PATH % event_id
	if not ResourceLoader.exists(path):
		return null
	var event := load(path) as StoryEvent
	if event != null:
		_events[event_id] = event
	return event


func get_all_events() -> Array[StoryEvent]:
	var events: Array[StoryEvent] = []
	for event_id: StringName in ContentIds.STORY_EVENT_IDS:
		var event := get_event(event_id)
		if event != null:
			events.append(event)
	return events


# --- Internals --------------------------------------------------------------

func _is_triggered(event: StoryEvent) -> bool:
	match event.trigger_type:
		TRIGGER_DEBT_PAID:
			return int(GameState.get_stat(&"lifetime_debt_paid")) >= int(event.trigger_value)
		TRIGGER_DEBT_CLEARED:
			return GameState.has_active_game() and GameState.get_debt_remaining() == 0
		TRIGGER_FISH_FIRST_WIN:
			var entry := GameState.get_fish_book_entry(StringName(str(event.trigger_value)))
			return int(entry.get("wins", 0)) > 0
		TRIGGER_MARKET_VISIT:
			return int(GameState.get_story_value(KEY_VISIT_SERIAL)) >= int(event.trigger_value)
	return false


func _requirements_met(event: StoryEvent) -> bool:
	for required: StringName in event.requires_seen:
		if not is_event_seen(required):
			return false
	return true


## Higher priority wins; then whichever has waited longer; then the ID.
func _outranks(candidate: StoryEvent, current: StoryEvent, pending: Array[StringName]) -> bool:
	if candidate.priority != current.priority:
		return candidate.priority > current.priority
	var candidate_age := pending.find(candidate.id)
	var current_age := pending.find(current.id)
	if candidate_age != current_age:
		return candidate_age < current_age
	return String(candidate.id) < String(current.id)
