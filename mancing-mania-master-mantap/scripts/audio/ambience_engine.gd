class_name AmbienceEngine
extends Node
## Procedural ambience beds (GDD 108, 175.12-175.14). Nothing is loaded from
## disk: each layer is synthesized from noise and sine tones.
##
## Continuous layers (water, wind, the warung radio, the freezer hum) are
## rendered once into short seamless loops and then cost nothing to play.
## Rendering is spread over many frames with a small time budget, so entering
## a place never causes a hitch. Bird calls are separate one-shots on an
## irregular timer, which keeps a bed from ever sounding like a short loop.
##
## Each place is a set of layers. Changing place fades its layers in and the
## others out, and a layer both places share (the afternoon wind) just carries
## on at its new level.

const STATE_SILENCE := &"silence"
const STATE_LAKE := &"lake"
const STATE_MARKET := &"market"
## The four new spots (revision 6.7).
const STATE_RIVER := &"river"
const STATE_RESERVOIR := &"reservoir"
const STATE_ESTUARY := &"estuary"
const STATE_SEA := &"sea"

## Loops are rendered below the output rate: ambience has no fine detail, and
## it keeps the render cost and memory small.
const LOOP_RATE := 16000
const CROSSFADE_SEC := 0.6
const FRAME_BUDGET_MSEC := 3
const FADE_SEC := 1.6
const LEVEL_DB_PER_SEC := 6.0
const BIRD_GAP_SEC := Vector2(5.0, 12.0)
const BIRD_VARIANTS := 4

## layer id -> [seconds, base volume dB]
const LAKE_LAYERS: Dictionary = {
	&"water": [6.0, -17.0],
	&"wind": [8.0, -21.0],
}
## Bu Yati's warung: a small radio, the old freezer and the same afternoon air.
const MARKET_LAYERS: Dictionary = {
	&"radio": [9.6, -25.0],
	&"hum": [4.0, -31.0],
	&"wind": [8.0, -27.0],
}
## Kenanga River: fast water over stones under the same wind.
const RIVER_LAYERS: Dictionary = {
	&"rush": [5.0, -18.0],
	&"wind": [8.0, -23.0],
}
## Melati Reservoir: wide open water, so more wind and quieter lapping.
const RESERVOIR_LAYERS: Dictionary = {
	&"water": [6.0, -21.0],
	&"wind": [8.0, -18.0],
}
## Anggrek Estuary: lapping water and the sea breathing far away.
const ESTUARY_LAYERS: Dictionary = {
	&"water": [6.0, -19.0],
	&"surf": [12.0, -27.0],
	&"wind": [8.0, -22.0],
}
## Mawar Pier: the waves themselves.
const SEA_LAYERS: Dictionary = {
	&"surf": [12.0, -17.0],
	&"wind": [8.0, -19.0],
}
const STATE_LAYERS: Dictionary = {
	STATE_LAKE: LAKE_LAYERS,
	STATE_MARKET: MARKET_LAYERS,
	STATE_RIVER: RIVER_LAYERS,
	STATE_RESERVOIR: RESERVOIR_LAYERS,
	STATE_ESTUARY: ESTUARY_LAYERS,
	STATE_SEA: SEA_LAYERS,
}
## Birds are heard outdoors everywhere, only fainter from under the warung roof.
const BIRD_GAIN_DB: Dictionary = {
	STATE_LAKE: 0.0,
	STATE_MARKET: -6.0,
	STATE_RIVER: -2.0,
	STATE_RESERVOIR: -3.0,
	STATE_ESTUARY: -2.0,
	STATE_SEA: -5.0,
}
## The place the player usually goes next; its loops are rendered in advance
## so they are ready on arrival.
const PREPARE_AFTER: Dictionary = {
	STATE_LAKE: STATE_MARKET,
	STATE_RIVER: STATE_MARKET,
	STATE_RESERVOIR: STATE_MARKET,
	STATE_ESTUARY: STATE_MARKET,
	STATE_SEA: STATE_MARKET,
}
## How far each layer's volume drifts by itself: wind comes in gusts.
const SWELL_DB: Dictionary = {
	&"wind": 3.5,
	&"radio": 1.4,
}

# The warung radio (GDD 175.12): an invented pentatonic tune, never a real one.
const RADIO_STEPS := 32
const RADIO_STEP_SEC := 0.3
const RADIO_SCALE_HZ: Array[float] = [392.0, 440.0, 523.25, 587.33, 659.25, 783.99, 880.0]
const RADIO_SEED := 17091945
## Flutter rates are whole cycles per loop, so the loop point stays seamless.
const RADIO_FLUTTER_FAST_HZ := 7.0 / 9.6
const RADIO_FLUTTER_SLOW_HZ := 1.0 / 9.6
const HUM_HZ := 50.0

## One wave every this many seconds; the surf loop holds a whole number of them.
const SURF_PERIOD_SEC := 6.0

enum LayerKind { WATER, WIND, RADIO, HUM, RUSH, SURF }

const LAYER_KINDS: Dictionary = {
	&"water": LayerKind.WATER,
	&"wind": LayerKind.WIND,
	&"radio": LayerKind.RADIO,
	&"hum": LayerKind.HUM,
	&"rush": LayerKind.RUSH,
	&"surf": LayerKind.SURF,
}

var _state: StringName = STATE_SILENCE
var _players: Dictionary[StringName, AudioStreamPlayer] = {}
var _base_db: Dictionary[StringName, float] = {}
var _levels: Dictionary[StringName, float] = {}
var _jobs: Array[Dictionary] = []
var _bird_streams: Array[AudioStreamWAV] = []
var _bird_player: AudioStreamPlayer
var _bird_left: float = 0.0
var _duck_db: float = 0.0
var _duck_left: float = 0.0
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
	if _duck_left > 0.0:
		_duck_left -= delta
	var duck := _duck_db if _duck_left > 0.0 else 0.0
	var layers: Dictionary = STATE_LAYERS.get(_state, {})

	for layer: StringName in _players:
		var player := _players[layer]
		var wanted := layers.has(layer)
		var level := move_toward(_levels[layer], 1.0 if wanted else 0.0, delta / FADE_SEC)
		_levels[layer] = level
		if wanted:
			_base_db[layer] = move_toward(_base_db[layer], float(layers[layer][1]), delta * LEVEL_DB_PER_SEC)
		if level <= 0.0:
			if player.playing:
				player.stop()
			continue
		if not player.playing and player.stream != null:
			player.play()
		var swell := sin(_clock * 0.23 + float(layer.hash() % 7)) * float(SWELL_DB.get(layer, 1.0))
		player.volume_db = _base_db[layer] + linear_to_db(maxf(level, 0.001)) + swell - duck

	if BIRD_GAIN_DB.has(_state) and not _bird_streams.is_empty():
		_bird_left -= delta
		if _bird_left <= 0.0:
			_bird_left = _random.randf_range(BIRD_GAP_SEC.x, BIRD_GAP_SEC.y)
			_bird_player.stream = _bird_streams[_random.randi() % _bird_streams.size()]
			_bird_player.volume_db = _random.randf_range(-26.0, -19.0) + float(BIRD_GAIN_DB[_state]) - duck
			_bird_player.pitch_scale = _random.randf_range(0.92, 1.1)
			_bird_player.play()


func set_state(state: StringName) -> void:
	if state == _state:
		return
	_state = state
	_prepare(state)
	if PREPARE_AFTER.has(state):
		_prepare(PREPARE_AFTER[state])


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


## The rendered loop of a layer, or null while it is still being synthesized.
func get_layer_stream(layer: StringName) -> AudioStreamWAV:
	if not _players.has(layer):
		return null
	return _players[layer].stream as AudioStreamWAV


# --- Rendering --------------------------------------------------------------

## Creates the players of a place and queues the loops that do not exist yet.
func _prepare(state: StringName) -> void:
	if not STATE_LAYERS.has(state):
		return
	var layers: Dictionary = STATE_LAYERS[state]
	for layer: StringName in layers:
		if _players.has(layer):
			continue
		var spec: Array = layers[layer]
		_players[layer] = _make_player("%sLoop" % String(layer).capitalize())
		_base_db[layer] = spec[1]
		_levels[layer] = 0.0
		_queue_loop(layer, spec[0])
	if _bird_streams.is_empty():
		for variant: int in BIRD_VARIANTS:
			_bird_streams.append(SfxRenderer.to_stream(_render_bird_phrase(variant), LOOP_RATE))
		_bird_left = _random.randf_range(2.0, 6.0)


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
		"layer": layer, "kind": LAYER_KINDS[layer], "samples": samples, "index": 0,
		"seconds": seconds, "noise": noise, "low": 0.0, "high": 0.0,
		"pattern": _make_radio_pattern() if layer == &"radio" else PackedFloat32Array(),
	})


## The radio tune: a seeded walk over a pentatonic scale with a few rests.
## A pitch of 0 is a rest. It is the same tune every run.
func _make_radio_pattern() -> PackedFloat32Array:
	var pattern := PackedFloat32Array()
	pattern.resize(RADIO_STEPS)
	var walk := RandomNumberGenerator.new()
	walk.seed = RADIO_SEED
	var degree := 2
	for step: int in RADIO_STEPS:
		if step > 0 and walk.randf() < 0.28:
			pattern[step] = 0.0
			continue
		degree = clampi(degree + walk.randi_range(-2, 2), 0, RADIO_SCALE_HZ.size() - 1)
		pattern[step] = RADIO_SCALE_HZ[degree]
	return pattern


## Synthesizes pending loops for a few milliseconds, then yields the frame.
func _render_some() -> void:
	if _jobs.is_empty():
		return
	var deadline := Time.get_ticks_msec() + FRAME_BUDGET_MSEC
	var job: Dictionary = _jobs[0]
	var samples: PackedFloat32Array = job["samples"]
	var noise: RandomNumberGenerator = job["noise"]
	var pattern: PackedFloat32Array = job["pattern"]
	var index: int = job["index"]
	var low: float = job["low"]
	var high: float = job["high"]
	var kind: int = job["kind"]
	var total := samples.size()

	while index < total:
		var time_sec := float(index) / float(LOOP_RATE)
		var white := noise.randf_range(-1.0, 1.0)
		if kind == LayerKind.WIND:
			# Low, breathy noise whose brightness drifts slowly.
			var cutoff := 0.035 + 0.02 * sin(time_sec * 0.9) + 0.012 * sin(time_sec * 2.3)
			low += cutoff * (white - low)
			high += 0.004 * (low - high)
			samples[index] = (low - high) * 2.4
		elif kind == LayerKind.WATER:
			# Soft lapping: band-limited noise with gentle amplitude ripples.
			low += 0.22 * (white - low)
			high += 0.03 * (low - high)
			var lap := 0.55 + 0.25 * sin(time_sec * 2.1) + 0.2 * sin(time_sec * 5.3 + 1.0)
			samples[index] = (low - high) * lap * 1.5
		elif kind == LayerKind.RUSH:
			# A river over stones: brighter, busier noise with a quick shimmer.
			low += 0.45 * (white - low)
			high += 0.06 * (low - high)
			var shimmer := 0.8 + 0.12 * sin(time_sec * 7.1) + 0.08 * sin(time_sec * 11.3 + 0.5)
			samples[index] = (low - high) * shimmer * 1.2
		elif kind == LayerKind.SURF:
			# A wave: noise that swells, brightens as it breaks, then hisses away.
			var phase := fposmod(time_sec / SURF_PERIOD_SEC, 1.0)
			var swell := pow(0.5 - 0.5 * cos(TAU * phase), 2.5)
			low += (0.04 + 0.22 * swell) * (white - low)
			high += 0.01 * (low - high)
			samples[index] = (low - high) * (0.2 + swell) * 1.7
		elif kind == LayerKind.RADIO:
			var step_position := time_sec / RADIO_STEP_SEC
			var step := int(step_position) % RADIO_STEPS
			var in_step := (step_position - floorf(step_position)) * RADIO_STEP_SEC
			var voice := 0.0
			var pitch := pattern[step]
			if pitch > 0.0:
				# A plucked note that is let go just before the next one.
				var angle := TAU * pitch * in_step
				voice = (sin(angle) + 0.35 * sin(angle * 2.0) + 0.12 * sin(angle * 3.0)) \
					* exp(-in_step * 7.0) * minf((RADIO_STEP_SEC - in_step) * 100.0, 1.0)
			# A soft tok on the beat and a brushed tick between beats.
			var percussion := 0.0
			if step % 4 == 0:
				percussion = sin(TAU * 150.0 * in_step) * exp(-in_step * 30.0) * 0.9
			elif step % 2 == 1:
				percussion = white * exp(-in_step * 90.0) * 0.35
			var raw := voice * 0.5 + percussion * 0.5 + white * 0.035
			# A small speaker loses both the lows and the highs.
			low += 0.54 * (raw - low)
			high += 0.14 * (low - high)
			var flutter := 1.0 + 0.1 * sin(TAU * RADIO_FLUTTER_FAST_HZ * time_sec) \
				+ 0.16 * sin(TAU * RADIO_FLUTTER_SLOW_HZ * time_sec)
			samples[index] = (low - high) * flutter * 0.75
		else:
			# Freezer compressor: mains hum with a few harmonics over a low rumble.
			low += 0.05 * (white - low)
			var hum := TAU * HUM_HZ * time_sec
			var body := sin(hum) * 0.5 + sin(hum * 2.0) * 0.4 + sin(hum * 3.0) * 0.22 + sin(hum * 4.0) * 0.1
			samples[index] = body * 0.5 * (0.85 + 0.15 * sin(TAU * 0.5 * time_sec)) + low * 0.8
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
	_players[layer].stream = SfxRenderer.to_stream(samples, LOOP_RATE, true)


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
