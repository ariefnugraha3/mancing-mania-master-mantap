extends Node
## Narrative event queue (GDD 169.9, 177).
##
## Milestone 1 owns the queue itself: what is pending, what was seen, and the
## Market-visit serial, all stored in GameState so they are saved. The parts
## that need StoryEvent data and the Story scene - trigger evaluation, priority
## arbitration at Market exit and playback - are added by the Market and
## Narrative milestones on top of this queue.

signal story_event_started(event_id: StringName)
signal story_event_finished(event_id: StringName, skipped: bool)

const KEY_SEEN := &"seen_events"
const KEY_PENDING := &"pending_events"
const KEY_VISIT_SERIAL := &"market_visit_serial"

var _active_event: StringName = &""


# --- Public API (GDD 169.9) -------------------------------------------------

## Checks every trigger and queues the events that became eligible.
## There are no StoryEvent resources before the Market milestone, so there is
## nothing to evaluate yet.
func evaluate_story_triggers() -> void:
	pass


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
func begin_market_visit() -> void:
	GameState.set_story_value(KEY_VISIT_SERIAL, int(GameState.get_story_value(KEY_VISIT_SERIAL)) + 1)


## Picks the one event to show when the player leaves the Market.
## Arbitration needs StoryEvent priorities, which arrive with the Market
## milestone; until then no event is ever chosen.
func resolve_market_exit_event() -> StringName:
	return &""


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
	if _active_event == &"":
		return
	var event_id := _active_event
	mark_event_seen(event_id)
	story_event_finished.emit(event_id, true)


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
## were already seen. Supersede lists from StoryEvent data join in later.
func supersede_invalid_events() -> void:
	var pending := get_pending_events()
	var kept: Array[StringName] = []
	for event_id: StringName in pending:
		if ContentIds.STORY_EVENT_IDS.has(event_id) and not is_event_seen(event_id):
			kept.append(event_id)
	if kept.size() != pending.size():
		GameState.set_story_events(KEY_PENDING, kept)


# --- Extras -----------------------------------------------------------------

func is_event_seen(event_id: StringName) -> bool:
	return GameState.get_story_events(KEY_SEEN).has(event_id)


func get_active_event() -> StringName:
	return _active_event
