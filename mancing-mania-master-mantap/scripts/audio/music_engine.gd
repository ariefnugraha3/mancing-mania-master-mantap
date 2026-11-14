class_name MusicEngine
extends Node
## Procedural music playback (GDD 175.2, 175.10, 175.11, 169.5).
##
## Two kinds of music:
##   - state loops (fishing, boxing, arm wrestling, menu): rendered once per
##     state in the background, then looped, with a short fade between states;
##   - songs (the Dance track): a whole schedule rendered before the duel and
##     played once. Its playback position is the authoritative song clock.
##
## Silence is a valid music state (GDD 175.11).

const STATE_SILENCE := &"silence"
## Which loop each music state plays; states not listed are silent.
const STATE_STYLES: Dictionary = {
	&"menu": MusicSequencer.STYLE_FISHING,
	&"fishing": MusicSequencer.STYLE_FISHING,
	&"boxing": MusicSequencer.STYLE_BOXING,
	&"arm_wrestle": MusicSequencer.STYLE_ARM,
}
## Fixed seeds keep each state's loop the same every session.
const STATE_SEEDS: Dictionary = {
	MusicSequencer.STYLE_FISHING: 31337,
	MusicSequencer.STYLE_BOXING: 4242,
	MusicSequencer.STYLE_ARM: 1717,
}
const LOOP_DB := -9.0
const SONG_DB := -4.0
const FADE_SEC := 0.8
const FRAME_BUDGET_MSEC := 4

var _state: StringName = STATE_SILENCE
var _loop_player: AudioStreamPlayer
var _song_player: AudioStreamPlayer
var _loop_streams: Dictionary = {}
var _loop_jobs: Dictionary = {}
var _song_renderer: MusicRenderer
var _song_ready: bool = false
var _song_schedule: Dictionary = {}
var _level: float = 0.0
var _paused: bool = false
var _last_song_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_loop_player = _make_player("LoopVoice")
	_song_player = _make_player("SongVoice")
	_song_player.volume_db = SONG_DB


func _process(delta: float) -> void:
	_render_some()
	if _paused:
		return
	var wanted := _wanted_loop_style()
	var stream: AudioStreamWAV = _loop_streams.get(wanted)
	# Fade out when the loop must change or stop, then swap and fade in.
	if _loop_player.stream != stream:
		_level = move_toward(_level, 0.0, delta / FADE_SEC)
		if _level <= 0.0:
			_loop_player.stop()
			_loop_player.stream = stream
			if stream != null:
				_loop_player.play()
	elif stream != null:
		_level = move_toward(_level, 1.0, delta / FADE_SEC)
		if not _loop_player.playing:
			_loop_player.play()
	_loop_player.volume_db = LOOP_DB + linear_to_db(maxf(_level, 0.001))


# --- State loops ------------------------------------------------------------

func set_state(state: StringName) -> void:
	_state = state
	var style: StringName = STATE_STYLES.get(state, &"")
	if style != &"" and not _loop_streams.has(style) and not _loop_jobs.has(style):
		var renderer := MusicRenderer.new()
		renderer.start(MusicSequencer.build_loop(style, STATE_SEEDS[style]))
		_loop_jobs[style] = renderer


func get_state() -> StringName:
	return _state


func is_rendering() -> bool:
	return not _loop_jobs.is_empty() or (_song_renderer != null and not _song_ready)


func get_loop_stream(state: StringName) -> AudioStreamWAV:
	return _loop_streams.get(STATE_STYLES.get(state, &""))


# --- Songs ------------------------------------------------------------------

## Starts rendering a song in the background. Poll is_song_ready().
func prepare_song(schedule: Dictionary) -> void:
	stop_song()
	_song_schedule = schedule
	_song_ready = false
	_song_renderer = MusicRenderer.new()
	_song_renderer.start(schedule)


func is_song_ready() -> bool:
	return _song_ready


func get_song_progress() -> float:
	return 1.0 if _song_ready else (_song_renderer.get_progress() if _song_renderer != null else 0.0)


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

## A song owns the music while it plays; the state loop steps aside.
func _wanted_loop_style() -> StringName:
	if _song_player.playing:
		return &""
	return STATE_STYLES.get(_state, &"")


func _render_some() -> void:
	var deadline := Time.get_ticks_msec() + FRAME_BUDGET_MSEC
	if _song_renderer != null and not _song_ready:
		if _song_renderer.step(FRAME_BUDGET_MSEC):
			_song_player.stream = _song_renderer.get_stream()
			_song_ready = true
		return
	for style: StringName in _loop_jobs.keys():
		var renderer: MusicRenderer = _loop_jobs[style]
		if renderer.step(maxi(deadline - Time.get_ticks_msec(), 1)):
			_loop_streams[style] = renderer.get_stream()
			_loop_jobs.erase(style)
		return


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Music"
	add_child(player)
	return player
