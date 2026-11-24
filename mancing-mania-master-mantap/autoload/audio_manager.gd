extends Node
## Procedural audio facade (GDD 107, 169.5, 175). It never loads an audio file:
## every sound is synthesized from the numeric presets in res://data/audio/.
##
## Milestone 1 provides the bus layout, volume control, the pre-rendered UI
## clicks and the state/clock surface that later milestones plug their music
## and ambience generators into.

signal audio_unlocked()
signal music_state_changed(state_id: StringName)

const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const BUS_AMBIENCE := &"Ambience"
const BUS_UI := &"UI"
const CHILD_BUSES: Array[StringName] = [BUS_MUSIC, BUS_SFX, BUS_AMBIENCE, BUS_UI]

const PRESET_PATH := "res://data/audio/%s.tres"
## Sounds that must answer input instantly; rendered once during Boot.
const CRITICAL_SFX_IDS: Array[StringName] = [&"ui_click", &"ui_back", &"ui_disabled"]
## Fishing sounds (GDD 175.6). The first use renders and caches each one.
const FISHING_SFX_IDS: Array[StringName] = [
	&"sfx_cast_whoosh", &"sfx_float_plip", &"sfx_false_nibble", &"sfx_real_bite",
	&"sfx_strike_success", &"sfx_reel_tick", &"sfx_line_stress", &"sfx_line_break",
	&"sfx_large_splash",
]
## The small happenings at the fishing spot (revision 6.12): a kingfisher's
## chirp, a gull, a frog, a neighbour's horn, a passing drizzle and the coin
## from a bottle. Splashes reuse the fishing sounds.
const EVENT_SFX_IDS: Array[StringName] = [
	&"event_bird_call", &"event_gull_call", &"event_frog_croak", &"event_horn", &"event_rain", &"event_coin",
	&"event_duck_quack", &"event_cat_meow",
]
## Market sounds (GDD 175.7): sale, purchase and the debt payment chime.
const MARKET_SFX_IDS: Array[StringName] = [&"ui_sell", &"ui_purchase", &"ui_debt_ding"]
## Boxing sounds (GDD 175.8).
const BOXING_SFX_IDS: Array[StringName] = [
	&"box_glove_swing", &"box_hit_light", &"box_hit_heavy", &"box_block",
	&"box_dodge", &"box_perfect", &"box_ko",
]
## Arm wrestling sounds (GDD 175.9).
const ARM_SFX_IDS: Array[StringName] = [
	&"arm_table_creak", &"arm_strain", &"arm_mash_click", &"arm_burst_warning", &"arm_win", &"arm_lose",
]

const UI_VOICES := 4
const SFX_VOICES := 8
const SILENT_LINEAR := 0.0005

## Settings key that drives each bus volume.
const _BUS_SETTINGS: Dictionary[StringName, StringName] = {
	BUS_MASTER: &"master_volume",
	BUS_MUSIC: &"music_volume",
	BUS_SFX: &"sfx_volume",
	BUS_AMBIENCE: &"ambience_volume",
	BUS_UI: &"ui_volume",
}

var _initialized: bool = false
var _unlocked: bool = false
var _paused: bool = false
var _mix_rate: int = 48000
var _stream_cache: Dictionary[StringName, AudioStreamWAV] = {}
var _preset_cache: Dictionary[StringName, AudioPreset] = {}
var _ui_players: Array[AudioStreamPlayer] = []
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_ui_voice: int = 0
var _next_sfx_voice: int = 0
var _music_state: StringName = &"silence"
var _ambience_state: StringName = &"silence"
var _rhythm_offset_ms: int = 0
var _ambience: AmbienceEngine
var _music: MusicEngine


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# --- Public API (GDD 169.5) -------------------------------------------------

## Builds buses and voices and pre-renders the critical sounds. Safe to call
## more than once.
func initialize_procedural_audio() -> void:
	if _initialized:
		return
	_mix_rate = maxi(int(AudioServer.get_mix_rate()), 8000)
	_ensure_buses()
	_ui_players = _make_voices(UI_VOICES, BUS_UI)
	_sfx_players = _make_voices(SFX_VOICES, BUS_SFX)
	_ambience = AmbienceEngine.new()
	_ambience.name = "AmbienceEngine"
	add_child(_ambience)
	_ambience.set_state(_ambience_state)
	_music = MusicEngine.new()
	_music.name = "MusicEngine"
	add_child(_music)
	_music.set_state(_music_state)
	for sfx_id: StringName in CRITICAL_SFX_IDS:
		_get_stream(sfx_id, -1)
	_apply_all_volumes()
	GameState.settings_changed.connect(_on_settings_changed)
	GameState.state_replaced.connect(_apply_all_volumes)
	_initialized = true
	if not OS.has_feature("web"):
		# Only browsers block audio until the first user gesture.
		_set_unlocked()
	GameLog.info(&"AUDIO", "procedural audio ready", {"mix_rate": _mix_rate, "cached": _stream_cache.size()})


func is_audio_ready() -> bool:
	return _initialized and _unlocked


## Called on the first pointer/key press. Browsers resume their audio context
## on that same gesture, so from here on sound can actually be heard.
func request_web_audio_unlock() -> void:
	if _initialized and not _unlocked:
		_set_unlocked()


func play_sfx(sfx_id: StringName, gain_db: float = 0.0, seed: int = -1) -> void:
	_play_on(_sfx_players, sfx_id, gain_db, seed, false)


func play_ui(sfx_id: StringName) -> void:
	_play_on(_ui_players, sfx_id, 0.0, -1, true)


## Switches the ambience bed: &"lake", &"market" or &"silence". The bed fades in
## and out; a state requested before Boot finished is applied afterwards.
func set_ambience_state(state_id: StringName, _seed: int = -1) -> void:
	_ambience_state = state_id
	if _ambience != null:
		_ambience.set_state(state_id)


## Switches the background music. The menu, the water (&"fishing",
## &"result") and each duel (&"boxing", &"arm_wrestle", &"suwit", &"silat",
## &"gasing", &"tambang", &"pinang") have their own piece (revision 6.9);
## any other state (&"market", &"dance", &"silence") is silent, which is a
## valid music state (GDD 175.11). The Dance track is a song, started with
## prepare_song() and play_song().
func set_music_state(state_id: StringName, _seed: int = -1, _bpm_override: float = -1.0) -> void:
	if _music_state == state_id:
		return
	_music_state = state_id
	if _music != null:
		_music.set_state(state_id)
	music_state_changed.emit(_music_state)


## Briefly lowers the ambience so a critical cue such as the bite is never
## masked (GDD 111, 175.5).
func duck_ambience(amount_db: float, seconds: float) -> void:
	if _ambience != null:
		_ambience.duck(amount_db, seconds)


func stop_music(_fade_sec: float = 0.5) -> void:
	set_music_state(&"silence")
	if _music != null:
		_music.stop_song()


func set_bus_volume(bus_id: StringName, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_id)
	if index < 0:
		GameLog.error(&"AUDIO", "unknown bus", {"bus": bus_id})
		return
	var clamped := clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_mute(index, clamped <= SILENT_LINEAR)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(clamped, SILENT_LINEAR)))


## Pauses gameplay audio. UI sounds stay available for the pause menu.
func set_paused(paused: bool) -> void:
	_paused = paused
	for player: AudioStreamPlayer in _sfx_players:
		player.stream_paused = paused
	if _ambience != null:
		_ambience.set_paused(paused)
	if _music != null:
		_music.set_paused(paused)


## Position of the current song on the audio clock (GDD 62). Never runs
## backwards; holds its last value while no song plays.
func get_authoritative_song_time_sec() -> float:
	return _music.get_song_time() if _music != null else 0.0


func get_music_engine() -> MusicEngine:
	return _music


func apply_rhythm_calibration(offset_ms: int) -> void:
	_rhythm_offset_ms = clampi(offset_ms, -SaveSchema.RHYTHM_OFFSET_LIMIT_MS, SaveSchema.RHYTHM_OFFSET_LIMIT_MS)


# --- Extras used by the debug overlay and tests -----------------------------

func is_paused() -> bool:
	return _paused


func get_music_state() -> StringName:
	return _music_state


func get_ambience_state() -> StringName:
	return _ambience_state


func get_ambience_engine() -> AmbienceEngine:
	return _ambience


func get_rhythm_calibration_ms() -> int:
	return _rhythm_offset_ms


func get_mix_rate() -> int:
	return _mix_rate


func get_active_voice_count() -> int:
	var active := 0
	for player: AudioStreamPlayer in _ui_players + _sfx_players:
		if player.playing:
			active += 1
	if _ambience != null:
		active += _ambience.get_voice_count()
	return active


## Renders (or returns the cached) samples-backed stream for a sound.
## Returns null when the preset is missing or cannot be rendered.
func get_sfx_stream(sfx_id: StringName, seed: int = -1) -> AudioStreamWAV:
	return _get_stream(sfx_id, seed)


func get_preset(sfx_id: StringName) -> AudioPreset:
	if _preset_cache.has(sfx_id):
		return _preset_cache[sfx_id]
	var path := PRESET_PATH % sfx_id
	if not ResourceLoader.exists(path):
		GameLog.error(&"AUDIO", "missing audio preset", {"sfx": sfx_id})
		return null
	var preset := load(path) as AudioPreset
	if preset != null:
		_preset_cache[sfx_id] = preset
	return preset


# --- Internals --------------------------------------------------------------

func _set_unlocked() -> void:
	_unlocked = true
	audio_unlocked.emit()


func _play_on(voices: Array[AudioStreamPlayer], sfx_id: StringName, gain_db: float, seed: int, is_ui: bool) -> void:
	if not _initialized or voices.is_empty():
		return
	if _paused and not is_ui:
		return
	var stream := _get_stream(sfx_id, seed)
	if stream == null:
		return
	var voice_index := _next_ui_voice if is_ui else _next_sfx_voice
	var player := voices[voice_index % voices.size()]
	if is_ui:
		_next_ui_voice = (voice_index + 1) % voices.size()
	else:
		_next_sfx_voice = (voice_index + 1) % voices.size()
	player.stream = stream
	player.volume_db = gain_db
	player.play()


func _get_stream(sfx_id: StringName, seed: int) -> AudioStreamWAV:
	var preset := get_preset(sfx_id)
	if preset == null:
		return null
	var varied := preset.seed_mode == &"varied" and seed >= 0
	if not varied and _stream_cache.has(sfx_id):
		return _stream_cache[sfx_id]
	var samples := SfxRenderer.render(preset, _mix_rate, seed)
	if samples.is_empty():
		return null
	var stream := SfxRenderer.to_stream(samples, _mix_rate)
	if not varied:
		_stream_cache[sfx_id] = stream
	return stream


func _make_voices(count: int, bus_id: StringName) -> Array[AudioStreamPlayer]:
	var voices: Array[AudioStreamPlayer] = []
	for index: int in count:
		var player := AudioStreamPlayer.new()
		player.name = "%sVoice%d" % [bus_id, index]
		player.bus = bus_id
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		voices.append(player)
	return voices


## The layout normally comes from default_bus_layout.tres; this guarantees the
## buses also exist if that file is ever missing. A missing bus is appended
## with set_bus_count(): add_bus() can shift the bus order on some export
## platforms and leave the game silent (revision 6.11).
func _ensure_buses() -> void:
	for bus_id: StringName in CHILD_BUSES:
		if AudioServer.get_bus_index(bus_id) >= 0:
			continue
		AudioServer.set_bus_count(AudioServer.bus_count + 1)
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_id)
		AudioServer.set_bus_send(index, BUS_MASTER)


func _apply_all_volumes() -> void:
	for bus_id: StringName in _BUS_SETTINGS:
		_apply_bus_setting(bus_id)
	apply_rhythm_calibration(int(GameState.get_setting(&"rhythm_input_offset_ms")))


func _apply_bus_setting(bus_id: StringName) -> void:
	set_bus_volume(bus_id, float(GameState.get_setting(_BUS_SETTINGS[bus_id])))


func _on_settings_changed(key: StringName) -> void:
	for bus_id: StringName in _BUS_SETTINGS:
		if _BUS_SETTINGS[bus_id] == key:
			_apply_bus_setting(bus_id)
			return
	if key == &"rhythm_input_offset_ms":
		apply_rhythm_calibration(int(GameState.get_setting(key)))
