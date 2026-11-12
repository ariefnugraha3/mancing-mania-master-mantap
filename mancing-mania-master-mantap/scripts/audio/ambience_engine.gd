class_name AmbienceEngine
extends Node
## Procedural ambience beds (GDD 108, 175.13, 175.14). Nothing is loaded from
## disk: each layer is synthesized from noise and sine tones.
##
## Continuous layers (water, wind) are rendered once into short seamless loops
## and then cost nothing to play. Rendering is spread over many frames with a
## small time budget, so entering the lake never causes a hitch. Bird calls are
## separate one-shots on an irregular timer, which keeps the bed from ever
## sounding like a short loop.

const STATE_SILENCE := &"silence"
const STATE_LAKE := &"lake"

## Loops are rendered below the output rate: ambience has no fine detail, and
## it keeps the render cost and memory small.
const LOOP_RATE := 16000
const CROSSFADE_SEC := 0.6
const FRAME_BUDGET_MSEC := 3
const FADE_SEC := 1.6
const BIRD_GAP_SEC := Vector2(5.0, 12.0)
const BIRD_VARIANTS := 4

## layer id -> [seconds, base volume dB]
const LAKE_LAYERS: Dictionary = {
	&"water": [6.0, -17.0],
	&"wind": [8.0, -21.0],
}

var _state: StringName = STATE_SILENCE
var _players: Dictionary[StringName, AudioStreamPlayer] = {}
var _base_db: Dictionary[StringName, float] = {}
var _jobs: Array[Dictionary] = []
var _bird_streams: Array[AudioStreamWAV] = []
var _bird_player: AudioStreamPlayer
var _bird_left: float = 0.0
var _duck_db: float = 0.0
var _duck_left: float = 0.0
var _level: float = 0.0
var _clock: float = 0.0
var _paused: bool = false
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_random.randomize()
	_bird_player = _make_player("BirdVoice")


func _process(delta: float) -> void:
	_render_some()
	if _paused:
		return
	_clock += delta
	var active := _state != STATE_SILENCE
	_level = move_toward(_level, 1.0 if active else 0.0, delta / FADE_SEC)
	if _duck_left > 0.0:
		_duck_left -= delta
	var duck := _duck_db if _duck_left > 0.0 else 0.0

	for layer: StringName in _players:
		var player := _players[layer]
		if _level <= 0.0:
			if player.playing:
				player.stop()
			continue
		if not player.playing and player.stream != null:
			player.play()
		# Slow swells: wind comes in gusts, water barely changes.
		var swell := sin(_clock * 0.23 + float(layer.hash() % 7)) * (3.5 if layer == &"wind" else 1.0)
		player.volume_db = _base_db[layer] + linear_to_db(maxf(_level, 0.001)) + swell - duck

	if active and not _bird_streams.is_empty():
		_bird_left -= delta
		if _bird_left <= 0.0:
			_bird_left = _random.randf_range(BIRD_GAP_SEC.x, BIRD_GAP_SEC.y)
			_bird_player.stream = _bird_streams[_random.randi() % _bird_streams.size()]
			_bird_player.volume_db = _random.randf_range(-26.0, -19.0) - duck
			_bird_player.pitch_scale = _random.randf_range(0.92, 1.1)
			_bird_player.play()


func set_state(state: StringName) -> void:
	if state == _state:
		return
	_state = state
	if state == STATE_LAKE and _players.is_empty():
		for layer: StringName in LAKE_LAYERS:
			var spec: Array = LAKE_LAYERS[layer]
			_players[layer] = _make_player("%sLoop" % String(layer).capitalize())
			_base_db[layer] = spec[1]
			_queue_loop(layer, spec[0])
		for variant: int in BIRD_VARIANTS:
			_bird_streams.append(SfxRenderer.to_stream(_render_bird_phrase(variant), LOOP_RATE))
		_bird_left = _random.randf_range(2.0, 6.0)


func get_state() -> StringName:
	return _state


func duck(amount_db: float, seconds: float) -> void:
	_duck_db = maxf(amount_db, 0.0)
	_duck_left = maxf(seconds, 0.0)


func set_paused(paused: bool) -> void:
	_paused = paused
	for layer: StringName in _players:
		_players[layer].stream_paused = paused
	_bird_player.stream_paused = paused


## True while a loop is still being synthesized.
func is_rendering() -> bool:
	return not _jobs.is_empty()


func get_voice_count() -> int:
	var voices := 1 if _bird_player.playing else 0
	for layer: StringName in _players:
		if _players[layer].playing:
			voices += 1
	return voices


# --- Rendering --------------------------------------------------------------

func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Ambience"
	add_child(player)
	return player


func _queue_loop(layer: StringName, seconds: float) -> void:
	var total := int((seconds + CROSSFADE_SEC) * LOOP_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	var noise := RandomNumberGenerator.new()
	noise.seed = SynthDsp.stable_hash(String(layer))
	_jobs.append({
		"layer": layer, "samples": samples, "index": 0, "seconds": seconds, "noise": noise,
		"low": 0.0, "high": 0.0,
	})


## Synthesizes pending loops for a few milliseconds, then yields the frame.
func _render_some() -> void:
	if _jobs.is_empty():
		return
	var deadline := Time.get_ticks_msec() + FRAME_BUDGET_MSEC
	var job: Dictionary = _jobs[0]
	var samples: PackedFloat32Array = job["samples"]
	var noise: RandomNumberGenerator = job["noise"]
	var index: int = job["index"]
	var low: float = job["low"]
	var high: float = job["high"]
	var is_wind: bool = job["layer"] == &"wind"
	var total := samples.size()

	while index < total:
		var time_sec := float(index) / float(LOOP_RATE)
		var white := noise.randf_range(-1.0, 1.0)
		if is_wind:
			# Low, breathy noise whose brightness drifts slowly.
			var cutoff := 0.035 + 0.02 * sin(time_sec * 0.9) + 0.012 * sin(time_sec * 2.3)
			low += cutoff * (white - low)
			high += 0.004 * (low - high)
			samples[index] = (low - high) * 2.4
		else:
			# Soft lapping: band-limited noise with gentle amplitude ripples.
			low += 0.22 * (white - low)
			high += 0.03 * (low - high)
			var lap := 0.55 + 0.25 * sin(time_sec * 2.1) + 0.2 * sin(time_sec * 5.3 + 1.0)
			samples[index] = (low - high) * lap * 1.5
		index += 1
		if index % 512 == 0 and Time.get_ticks_msec() >= deadline:
			break

	job["index"] = index
	job["low"] = low
	job["high"] = high
	if index >= total:
		_jobs.pop_front()
		_finish_loop(job["layer"], samples, float(job["seconds"]))


## Blends the tail into the head so the loop point is inaudible.
func _finish_loop(layer: StringName, samples: PackedFloat32Array, seconds: float) -> void:
	var length := int(seconds * LOOP_RATE)
	var fade := samples.size() - length
	for index: int in fade:
		var blend := float(index) / float(fade)
		samples[index] = samples[index] * blend + samples[length + index] * (1.0 - blend)
	samples.resize(length)
	var stream := SfxRenderer.to_stream(samples, LOOP_RATE)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = length
	_players[layer].stream = stream


## A short phrase of chirps: sine tones with quick pitch sweeps. The variants
## differ in pitch, count and rhythm, like a few different birds.
func _render_bird_phrase(variant: int) -> PackedFloat32Array:
	var shape := RandomNumberGenerator.new()
	shape.seed = 7001 + variant * 131
	var chirps := shape.randi_range(2, 5)
	var gap := shape.randf_range(0.09, 0.2)
	var chirp_sec := shape.randf_range(0.05, 0.11)
	var base_pitch := shape.randf_range(2300.0, 3900.0)
	var sweep := shape.randf_range(-700.0, 900.0)
	var total := int((float(chirps) * (chirp_sec + gap) + 0.05) * LOOP_RATE)
	var samples := PackedFloat32Array()
	samples.resize(total)
	for chirp: int in chirps:
		var start := int(float(chirp) * (chirp_sec + gap) * LOOP_RATE)
		var count := int(chirp_sec * LOOP_RATE)
		var pitch := base_pitch * shape.randf_range(0.94, 1.08)
		var phase := 0.0
		for index: int in count:
			var progress := float(index) / float(count)
			phase += TAU * (pitch + sweep * progress) / float(LOOP_RATE)
			samples[start + index] = sin(phase) * sin(progress * PI) * 0.6
	return samples
