class_name MusicEngine
extends Node
## Procedural music playback (GDD 175.2, 175.10, 175.11, 169.5; revision 6.9).
##
## Two kinds of music:
##   - state pieces (the title theme, the water, each duel): rendered once
##     in the background, then played. Most loop seamlessly; the water plays
##     calm takes with quiet between them, because silence is a valid music
##     state (GDD 175.11). A short fade covers every change of state;
##   - songs (the Dance track, the calibration clicks): a whole schedule
##     rendered before it is needed and played once. Its playback position
##     is the authoritative song clock.
##
## Rendering never holds up a frame. Where the platform has threads it runs
## on the WorkerThreadPool; otherwise (a Web build without threads) it runs
## in slices of a few milliseconds per frame. Only a few pieces are kept in
## memory; one that was dropped is rendered again when it is needed.

const STATE_SILENCE := &"silence"
## Which piece each music state plays; states not listed are silent.
const STATE_STYLES: Dictionary = {
	&"menu": MusicSequencer.STYLE_MENU,
	&"fishing": MusicSequencer.STYLE_FISHING,
	&"result": MusicSequencer.STYLE_FISHING,
	&"boxing": MusicSequencer.STYLE_BOXING,
	&"arm_wrestle": MusicSequencer.STYLE_ARM,
	&"suwit": MusicSequencer.STYLE_SUWIT,
	&"silat": MusicSequencer.STYLE_SILAT,
	&"gasing": MusicSequencer.STYLE_GAMELAN,
	&"tambang": MusicSequencer.STYLE_LOMBA,
	&"pinang": MusicSequencer.STYLE_LOMBA,
}
## Fixed seeds keep each piece the same every session.
const STATE_SEEDS: Dictionary = {
	MusicSequencer.STYLE_MENU: 2026,
	MusicSequencer.STYLE_FISHING: 31337,
	MusicSequencer.STYLE_BOXING: 4242,
	MusicSequencer.STYLE_ARM: 1717,
	MusicSequencer.STYLE_SUWIT: 909,
	MusicSequencer.STYLE_SILAT: 1945,
	MusicSequencer.STYLE_GAMELAN: 1108,
	MusicSequencer.STYLE_LOMBA: 1708,
}
## What to render after a style's own piece, so the next one is ready: the
## title theme is followed by the water.
const PREFETCH: Dictionary = {
	MusicSequencer.STYLE_MENU: [MusicSequencer.STYLE_FISHING],
}
## Evens out how loud the pieces sound (measured RMS while playing), with
## the calm water a little lower under the ambience.
const STYLE_TRIM_DB: Dictionary = {
	MusicSequencer.STYLE_FISHING: -1.0,
	MusicSequencer.STYLE_BOXING: -1.5,
	MusicSequencer.STYLE_ARM: -1.5,
	MusicSequencer.STYLE_SUWIT: 3.0,
	MusicSequencer.STYLE_GAMELAN: 2.0,
	MusicSequencer.STYLE_LOMBA: 1.0,
}
const LOOP_DB := -9.0
const SONG_DB := -4.0
const FADE_SEC := 0.8
## Per-frame slice when rendering on the main thread.
const FRAME_BUDGET_MSEC := 3
## Rendered pieces kept in memory (about 1.5 MB each).
const MAX_PIECES := 5

var _state: StringName = STATE_SILENCE
var _loop_player: AudioStreamPlayer
var _song_player: AudioStreamPlayer
var _use_threads: bool = false
## Rendered pieces by key ("style:take"), and their use order, oldest first.
var _pieces: Dictionary = {}
var _lru: Array[StringName] = []
## Piece keys waiting to render, most urgent first, and which of them are
## needed now rather than prepared ahead.
var _queue: Array[StringName] = []
var _urgent_keys: Array[StringName] = []
var _piece_job: MusicRenderer
var _piece_key: StringName = &""
var _piece_task: int = -1
## False while the piece rendering is only prepared ahead (a prefetch).
var _piece_urgent: bool = false
var _song_job: MusicRenderer
var _song_task: int = -1
## Cancelled worker tasks still finishing their last chunk.
var _orphan_tasks: Array[int] = []
var _song_ready: bool = false
var _song_schedule: Dictionary = {}
## The style the loop player serves, the take each style is on, and the
## quiet left before the next take.
var _active_style: StringName = &""
var _takes: Dictionary = {}
var _rest_left: float = 0.0
var _level: float = 0.0
var _paused: bool = false
var _last_song_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_use_threads = OS.get_processor_count() > 1 and (not OS.has_feature("web") or OS.has_feature("threads"))
	_loop_player = _make_player("LoopVoice")
	_song_player = _make_player("SongVoice")
	_song_player.volume_db = SONG_DB


func _exit_tree() -> void:
	_loop_player.stop()
	_song_player.stop()
	# Worker tasks must be collected before the engine goes away.
	for job: MusicRenderer in [_piece_job, _song_job]:
		if job != null:
			job.cancel()
	for task: int in [_piece_task, _song_task]:
		if task >= 0:
			WorkerThreadPool.wait_for_task_completion(task)
	for task: int in _orphan_tasks:
		WorkerThreadPool.wait_for_task_completion(task)
	_piece_task = -1
	_song_task = -1
	_orphan_tasks.clear()


func _process(delta: float) -> void:
	_service_jobs()
	if _paused:
		return
	var wanted := _wanted_style()
	if wanted != _active_style:
		# Fade out what plays, then hand the player to the new style.
		if _loop_player.playing and _level > 0.0:
			_level = move_toward(_level, 0.0, delta / FADE_SEC)
			_apply_level()
			if _level > 0.0:
				return
		_loop_player.stop()
		_loop_player.stream = null
		_active_style = wanted
		_rest_left = 0.0
		_level = 0.0
	if _active_style == &"":
		return
	if _loop_player.playing:
		_level = move_toward(_level, 1.0, delta / FADE_SEC)
		_apply_level()
		return
	if _loop_player.stream != null:
		# A take that plays once has ended: quiet, then the next take.
		_loop_player.stream = null
		_rest_left = _rest_after(_active_style)
		_takes[_active_style] = (_take_of(_active_style) + 1) % MusicSequencer.takes(_active_style)
		_request(_next_take_key(_active_style), false)
	if _rest_left > 0.0:
		_rest_left -= delta
		return
	var key := _piece_key_of(_active_style, _take_of(_active_style))
	var stream: AudioStreamWAV = _pieces.get(key)
	if stream == null:
		_request(key, true)
		return
	_touch(key)
	_loop_player.stream = stream
	_apply_level()
	_loop_player.play()


# --- State pieces -----------------------------------------------------------

func set_state(state: StringName) -> void:
	_state = state
	var style: StringName = STATE_STYLES.get(state, &"")
	if style == &"":
		return
	_request(_piece_key_of(style, _take_of(style)), true)
	if MusicSequencer.takes(style) > 1:
		_request(_next_take_key(style), false)
	for next_style: StringName in PREFETCH.get(style, []):
		_request(_piece_key_of(next_style, _take_of(next_style)), false)


func get_state() -> StringName:
	return _state


func is_rendering() -> bool:
	return _piece_job != null or not _queue.is_empty() or (_song_job != null and not _song_ready)


## The stream of the take a state's piece is on, once it is rendered.
func get_loop_stream(state: StringName) -> AudioStreamWAV:
	var style: StringName = STATE_STYLES.get(state, &"")
	return _pieces.get(_piece_key_of(style, _take_of(style))) if style != &"" else null


## True while a state piece is heard (or fading out).
func is_piece_playing() -> bool:
	return _loop_player.playing


## True when rendering runs on a worker thread rather than in frame slices.
func uses_threads() -> bool:
	return _use_threads


# --- Songs ------------------------------------------------------------------

## Starts rendering a song in the background. Poll is_song_ready().
func prepare_song(schedule: Dictionary) -> void:
	stop_song()
	_drop_song_job()
	_song_schedule = schedule
	_song_ready = false
	_song_job = MusicRenderer.new()
	_song_job.start(schedule)
	if _use_threads:
		_song_task = WorkerThreadPool.add_task(_song_job.run, true, "Music song")


func is_song_ready() -> bool:
	return _song_ready


func get_song_progress() -> float:
	return 1.0 if _song_ready else (_song_job.get_progress() if _song_job != null else 0.0)


func play_song(from_sec: float = 0.0) -> void:
	if not _song_ready:
		return
	_last_song_time = from_sec
	_song_player.play(from_sec)


func stop_song() -> void:
	_song_player.stop()
	_last_song_time = 0.0


func is_song_playing() -> bool:
	return _song_player.playing


## Where the song is right now, from the audio output itself (GDD 62): the
## playback position plus the time since the last mix, minus the output
## latency. It never runs backwards.
func get_song_time() -> float:
	if not _song_player.playing or _song_player.stream_paused:
		return _last_song_time
	var time := _song_player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	_last_song_time = maxf(_last_song_time, time)
	return _last_song_time


func get_song_schedule() -> Dictionary:
	return _song_schedule


func set_paused(paused: bool) -> void:
	_paused = paused
	_loop_player.stream_paused = paused
	_song_player.stream_paused = paused


# --- Internals --------------------------------------------------------------

## A song owns the music while it plays; the state piece steps aside.
func _wanted_style() -> StringName:
	if _song_player.playing:
		return &""
	return STATE_STYLES.get(_state, &"")


func _apply_level() -> void:
	_loop_player.volume_db = LOOP_DB + float(STYLE_TRIM_DB.get(_active_style, 0.0)) + linear_to_db(maxf(_level, 0.001))


func _take_of(style: StringName) -> int:
	return int(_takes.get(style, 0))


## The quiet after a take that plays once (only the water has takes).
func _rest_after(style: StringName) -> float:
	return MusicSequencer.FISHING_REST_SEC if style == MusicSequencer.STYLE_FISHING else 0.0


func _next_take_key(style: StringName) -> StringName:
	return _piece_key_of(style, (_take_of(style) + 1) % MusicSequencer.takes(style))


static func _piece_key_of(style: StringName, take: int) -> StringName:
	return StringName("%s:%d" % [style, take])


## Asks for a piece to be rendered; `urgent` puts it at the front, and
## stops a prefetch in progress so the piece needed now need not wait.
func _request(key: StringName, urgent: bool) -> void:
	if _pieces.has(key):
		_touch(key)
		return
	if key == _piece_key:
		_piece_urgent = _piece_urgent or urgent
		return
	if urgent and _piece_job != null and not _piece_urgent:
		var paused_key := _piece_key
		_drop_piece_job()
		_queue.push_back(paused_key)
	var queued := _queue.find(key)
	if queued >= 0:
		if not urgent:
			return
		_queue.remove_at(queued)
	if urgent:
		_queue.push_front(key)
		if not _urgent_keys.has(key):
			_urgent_keys.append(key)
	else:
		_queue.push_back(key)


## Moves a piece to the most recently used end.
func _touch(key: StringName) -> void:
	_lru.erase(key)
	_lru.append(key)


## Drops the least recently used pieces beyond MAX_PIECES, never the one
## the player is on or its next take.
func _evict() -> void:
	var keep: Array[StringName] = []
	if _active_style != &"":
		keep.append(_piece_key_of(_active_style, _take_of(_active_style)))
		keep.append(_next_take_key(_active_style))
	var index := 0
	while _pieces.size() > MAX_PIECES and index < _lru.size():
		var key := _lru[index]
		if keep.has(key) or (_loop_player.stream != null and _pieces[key] == _loop_player.stream):
			index += 1
			continue
		_pieces.erase(key)
		_lru.remove_at(index)


func _service_jobs() -> void:
	for task: int in _orphan_tasks.duplicate():
		if WorkerThreadPool.is_task_completed(task):
			WorkerThreadPool.wait_for_task_completion(task)
			_orphan_tasks.erase(task)
	# The song first: a player is waiting for it.
	if _song_job != null:
		if _job_finished(_song_job, _song_task):
			_song_task = -1
			_song_player.stream = _song_job.get_stream()
			_song_ready = true
			_song_job = null
		elif not _use_threads:
			return
	if _piece_job == null and not _queue.is_empty():
		var next_key: StringName = _queue.pop_front()
		_start_piece(next_key, _urgent_keys.has(next_key))
		_urgent_keys.erase(next_key)
	if _piece_job != null and _job_finished(_piece_job, _piece_task):
		_pieces[_piece_key] = _piece_job.get_stream()
		_touch(_piece_key)
		_piece_job = null
		_piece_key = &""
		_piece_task = -1
		_piece_urgent = false
		_evict()


func _start_piece(key: StringName, urgent: bool) -> void:
	var parts := String(key).split(":")
	var style := StringName(parts[0])
	var take := int(parts[1])
	_piece_key = key
	_piece_urgent = urgent
	_piece_job = MusicRenderer.new()
	_piece_job.start(MusicSequencer.build_piece(style, STATE_SEEDS.get(style, 1), take))
	if _use_threads:
		_piece_task = WorkerThreadPool.add_task(_piece_job.run, false, "Music piece")


## True once `job` is done: its worker task has ended, or (without
## threads) this frame's slice finished it.
func _job_finished(job: MusicRenderer, task: int) -> bool:
	if task >= 0:
		if not WorkerThreadPool.is_task_completed(task):
			return false
		WorkerThreadPool.wait_for_task_completion(task)
		return true
	return job.step(FRAME_BUDGET_MSEC)


## Abandons a prefetch still rendering; its worker task is collected later.
func _drop_piece_job() -> void:
	_piece_job.cancel()
	if _piece_task >= 0:
		_orphan_tasks.append(_piece_task)
	_piece_job = null
	_piece_key = &""
	_piece_task = -1
	_piece_urgent = false


## Abandons a song still rendering; its worker task is collected later.
func _drop_song_job() -> void:
	if _song_job == null:
		return
	_song_job.cancel()
	if _song_task >= 0:
		_orphan_tasks.append(_song_task)
	_song_job = null
	_song_task = -1


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Music"
	add_child(player)
	return player
