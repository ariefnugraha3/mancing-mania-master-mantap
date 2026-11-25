class_name CePatCash
extends RefCounted
## The lender's app (GDD 183.16): now and then, while Darto waits at the
## lake, a bureaucratic notification arrives. At most one every 18-35 minutes
## of play, never during a duel or a cutscene, never once the debt is paid.

const MIN_INTERVAL_SEC := 18.0 * 60.0
const MAX_INTERVAL_SEC := 35.0 * 60.0
## Overdue debt brings reminders far more often until Darto pays at the Warung.
const OVERDUE_MIN_INTERVAL_SEC := 3.0 * 60.0
const OVERDUE_MAX_INTERVAL_SEC := 5.0 * 60.0

static var _next_at: float = -1.0
static var _shown: int = 0


## A notification due at `play_time_sec` ({title, body, reply}), or {}.
static func poll(play_time_sec: float) -> Dictionary:
	if GameState.get_debt_remaining() <= 0 or bool(GameState.get_story_value(&"postgame_unlocked")):
		return {}
	var overdue := GameState.is_debt_overdue()
	if _next_at < 0.0:
		_next_at = play_time_sec + interval_for(int(play_time_sec), overdue)
		return {}
	if overdue and _next_at > play_time_sec + OVERDUE_MAX_INTERVAL_SEC:
		_next_at = play_time_sec + interval_for(int(play_time_sec) + _shown, true)
	if play_time_sec < _next_at:
		return {}
	_next_at = play_time_sec + interval_for(int(play_time_sec) + _shown + 1, overdue)
	var notice := notice_for(_shown)
	_shown += 1
	return notice


static func interval_for(seed_value: int, overdue: bool = false) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_value)
	if overdue:
		return rng.randf_range(OVERDUE_MIN_INTERVAL_SEC, OVERDUE_MAX_INTERVAL_SEC)
	return rng.randf_range(MIN_INTERVAL_SEC, MAX_INTERVAL_SEC)


## The n-th notification and Darto's answer (he does not always answer).
static func notice_for(index: int) -> Dictionary:
	var count := maxi(StoryTimelines.get_cepatcash_count(), 1)
	var replies := StoryTimelines.get_cepatcash_darto_count()
	var number := index % count + 1
	var reply := ""
	if replies > 0 and index % 2 == 0:
		reply = TextDb.t(StringName("cepatcash.darto.%d" % ((index / 2) % replies + 1)))
	return {
		"title": TextDb.t(StringName("cepatcash.%d.title" % number)),
		"body": TextDb.t(StringName("cepatcash.%d.body" % number)),
		"reply": reply,
	}


static func reset() -> void:
	_next_at = -1.0
	_shown = 0
