class_name SfxRenderer
extends RefCounted
## Renders short procedural sound effects into memory (GDD 175.2, 175.6, 175.7).
##
## Each AudioPreset names a recipe (`synth_type`) and gives it numbers. One-shots
## are rendered once and cached as in-memory AudioStreamWAV, so a sound never
## waits for a synthesis block when it is needed.
##
## How the preset fields are read:
##   pitch_hz           main tone, or the end of a sweep
##   filter_cutoff_hz   brightness of the noise part, or the start of a sweep
##   noise_amount       balance between tone and noise
##   attack / decay / release   the overall shape and length

## Extra samples after the end of every stream made in code (revision 6.11).
## While Android's mixer interpolates it reads a few samples past the end of
## the data or the loop point; without this pad, a long buffer that ends right
## before a protected memory page crashes the audio thread (SIGSEGV in
## AudioTrack). The pad is not part of the sound: loop_end stops before it.
const TAIL_PAD := 16

const SYNTH_CLICK := &"click"
const SYNTH_NOISE_SWEEP := &"noise_sweep"
const SYNTH_DROPLET := &"droplet"
const SYNTH_THUMP := &"thump"
const SYNTH_PLUCK := &"pluck"
const SYNTH_CREAK := &"creak"
const SYNTH_SNAP := &"snap"
const SYNTH_SPLASH := &"splash"
const SYNTH_TWO_NOTE := &"two_note"
const SYNTH_TICK_CLUSTER := &"tick_cluster"
const SYNTH_CHIME := &"chime"
const SYNTH_TOM_SEQUENCE := &"tom_sequence"
const SYNTH_RISING_PULSE := &"rising_pulse"
const SYNTH_FANFARE := &"fanfare"
const SYNTH_TWO_NOTE_DOWN := &"two_note_down"
const SUPPORTED_SYNTH_TYPES: Array[StringName] = [
	SYNTH_CLICK, SYNTH_NOISE_SWEEP, SYNTH_DROPLET, SYNTH_THUMP,
	SYNTH_PLUCK, SYNTH_CREAK, SYNTH_SNAP, SYNTH_SPLASH,
	SYNTH_TWO_NOTE, SYNTH_TICK_CLUSTER, SYNTH_CHIME, SYNTH_TOM_SEQUENCE,
	SYNTH_RISING_PULSE, SYNTH_FANFARE, SYNTH_TWO_NOTE_DOWN,
]
const EDGE_FADE_SEC := 0.0015
const PEAK_LIMIT := 0.98


## Returns mono samples in the -1..1 range, or an empty buffer when the preset
## cannot be rendered. `seed` only matters for presets with seed_mode "varied".
static func render(preset: AudioPreset, mix_rate: int, seed: int = -1) -> PackedFloat32Array:
	if preset == null or mix_rate <= 0:
		return PackedFloat32Array()
	var random := RandomNumberGenerator.new()
	random.seed = _resolve_seed(preset, seed)
	var samples: PackedFloat32Array
	match preset.synth_type:
		SYNTH_CLICK:
			samples = _render_click(preset, mix_rate, random, seed)
		SYNTH_NOISE_SWEEP:
			samples = _render_noise_sweep(preset, mix_rate, random)
		SYNTH_DROPLET:
			samples = _render_droplet(preset, mix_rate, random)
		SYNTH_THUMP:
			samples = _render_thump(preset, mix_rate, random)
		SYNTH_PLUCK:
			samples = _render_pluck(preset, mix_rate, random, 0.0)
		SYNTH_CREAK:
			samples = _render_creak(preset, mix_rate, random)
		SYNTH_SNAP:
			samples = _render_pluck(preset, mix_rate, random, 1.0)
		SYNTH_SPLASH:
			samples = _render_splash(preset, mix_rate, random)
		SYNTH_TWO_NOTE:
			samples = _render_two_note(preset, mix_rate, random)
		SYNTH_TICK_CLUSTER:
			samples = _render_tick_cluster(preset, mix_rate, random)
		SYNTH_CHIME:
			samples = _render_chime(preset, mix_rate, random)
		SYNTH_TOM_SEQUENCE:
			samples = _render_tom_sequence(preset, mix_rate, random)
		SYNTH_RISING_PULSE:
			samples = _render_rising_pulse(preset, mix_rate)
		SYNTH_FANFARE:
			samples = _render_fanfare(preset, mix_rate, random)
		SYNTH_TWO_NOTE_DOWN:
			samples = _render_two_note_down(preset, mix_rate, random)
		_:
			GameLog.error(&"AUDIO", "unsupported synth type", {"preset": preset.id, "type": preset.synth_type})
			return PackedFloat32Array()
	_finish(samples, preset, mix_rate)
	return samples


## Wraps mono samples as an in-memory 16-bit PCM stream. A looping stream
## loops over all of `samples`.
static func to_stream(samples: PackedFloat32Array, mix_rate: int, looping: bool = false) -> AudioStreamWAV:
	var count := samples.size()
	var bytes := PackedByteArray()
	bytes.resize((count + TAIL_PAD) * 2)
	for index: int in count:
		bytes.encode_s16(index * 2, int(clampf(samples[index], -1.0, 1.0) * 32767.0))
	write_tail_pad(bytes, count, looping)
	return make_stream(bytes, mix_rate, count, looping)


## Fills the TAIL_PAD samples after the first `count` 16-bit samples: a loop
## repeats its first samples there, a one-shot gets silence.
static func write_tail_pad(bytes: PackedByteArray, count: int, looping: bool) -> void:
	for pad: int in TAIL_PAD:
		var value := 0
		if looping and count > 0:
			value = bytes.decode_s16((pad % count) * 2)
		bytes.encode_s16((count + pad) * 2, value)


## Wraps 16-bit mono PCM that already ends in its tail pad. `count` is the
## length without the pad; a loop ends there.
static func make_stream(bytes: PackedByteArray, mix_rate: int, count: int, looping: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream


# --- Recipes ----------------------------------------------------------------

## Wood/plastic UI click (GDD 175.7): a very short low-passed noise impulse
## for the contact, plus a quickly decaying sine for the body.
static func _render_click(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator, seed: int) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var pitch := preset.pitch_hz
	if preset.seed_mode == &"varied" and seed >= 0:
		pitch *= random.randf_range(0.96, 1.04)
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var impulse_sec := maxf(preset.decay_sec * 0.22, 0.003)
	var filtered := 0.0
	var phase := 0.0
	var phase_step := TAU * pitch / float(mix_rate)
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var envelope := SynthDsp.adsr(time_sec, preset.attack_sec, preset.decay_sec, preset.sustain, preset.release_sec, 0.0)
		var body_envelope := SynthDsp.exp_decay(time_sec, duration)
		filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
		var body := sin(phase) * body_envelope
		phase += phase_step
		var mixed := body * (1.0 - preset.noise_amount * 0.5) + filtered * SynthDsp.exp_decay(time_sec, impulse_sec) * preset.noise_amount * 1.6
		samples[index] = mixed * maxf(envelope, body_envelope * 0.35) * 1.4
	return samples


## Cast whoosh: a noise burst whose brightness falls from the cutoff to the pitch.
static func _render_noise_sweep(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var low := 0.0
	var floor_filter := 0.0
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var progress := time_sec / duration
		var cutoff := lerpf(preset.filter_cutoff_hz, preset.pitch_hz, progress)
		low += SynthDsp.one_pole_coefficient(cutoff, float(mix_rate)) * (random.randf_range(-1.0, 1.0) - low)
		# Removing the lowest part keeps it airy instead of rumbling.
		floor_filter += SynthDsp.one_pole_coefficient(cutoff * 0.25, float(mix_rate)) * (low - floor_filter)
		var envelope := SynthDsp.adsr(time_sec, preset.attack_sec, preset.decay_sec, preset.sustain, preset.release_sec, 0.0)
		samples[index] = (low - floor_filter) * envelope * 2.6
	return samples


## Water droplet: a sine whose pitch rises quickly, with a small noise tick.
static func _render_droplet(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var filtered := 0.0
	var phase := 0.0
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var progress := time_sec / duration
		phase += TAU * preset.pitch_hz * (1.0 + 0.7 * progress) / float(mix_rate)
		filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
		var tone := sin(phase) * SynthDsp.exp_decay(time_sec, duration)
		var tick := filtered * SynthDsp.exp_decay(time_sec, 0.012) * preset.noise_amount * 1.5
		samples[index] = (tone * (1.0 - preset.noise_amount * 0.4) + tick) * SynthDsp.adsr(
			time_sec, preset.attack_sec, preset.decay_sec, 1.0, preset.release_sec, preset.attack_sec + preset.decay_sec)
	return samples


## Real bite: a low water thump with a falling pitch and a bright click on top.
static func _render_thump(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var filtered := 0.0
	var phase := 0.0
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var progress := time_sec / duration
		phase += TAU * preset.pitch_hz * (1.0 - 0.55 * progress) / float(mix_rate)
		filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
		var body := sin(phase) * SynthDsp.exp_decay(time_sec, duration * 0.8)
		var click := filtered * SynthDsp.exp_decay(time_sec, 0.02) * preset.noise_amount * 2.2
		samples[index] = (body * 1.1 + click) * SynthDsp.adsr(
			time_sec, preset.attack_sec, preset.decay_sec, 1.0, preset.release_sec, preset.attack_sec + preset.decay_sec)
	return samples


## Plucked string (Karplus-Strong): a burst of noise circulating in a delay
## line, losing brightness on every pass. `crack` adds the noise snap of a
## breaking line.
static func _render_pluck(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator, crack: float) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var period := maxi(int(float(mix_rate) / maxf(preset.pitch_hz, 20.0)), 2)
	var line := PackedFloat32Array()
	line.resize(period)
	for index: int in period:
		line[index] = random.randf_range(-1.0, 1.0)
	# More damping per pass for shorter, duller notes.
	var damping := clampf(0.5 - 0.004 / maxf(preset.decay_sec, 0.02), 0.44, 0.4995)
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var filtered := 0.0
	var position := 0
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var next := (position + 1) % period
		var value := line[position]
		line[position] = (value + line[next]) * damping
		position = next
		filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
		var transient := filtered * SynthDsp.exp_decay(time_sec, 0.03 + 0.05 * crack) * (preset.noise_amount + crack * 0.8)
		samples[index] = (value * 0.9 + transient) * SynthDsp.adsr(
			time_sec, preset.attack_sec, preset.decay_sec, 1.0, preset.release_sec, preset.attack_sec + preset.decay_sec)
	return samples


## Line stress creak: a cluster of tiny pitched grains over a rough noise bed.
static func _render_creak(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var grains := random.randi_range(5, 9)
	for grain: int in grains:
		var start := int(random.randf_range(0.0, duration * 0.8) * mix_rate)
		var grain_sec := random.randf_range(0.012, 0.03)
		var pitch := preset.pitch_hz * random.randf_range(0.82, 1.25)
		var count := mini(int(grain_sec * mix_rate), samples.size() - start)
		for index: int in count:
			var time_sec := float(index) / float(mix_rate)
			samples[start + index] += sin(TAU * pitch * time_sec) * SynthDsp.exp_decay(time_sec, grain_sec) * 0.7
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var filtered := 0.0
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
		var envelope := SynthDsp.adsr(time_sec, preset.attack_sec, preset.decay_sec, 0.6, preset.release_sec, duration - preset.release_sec)
		samples[index] = (samples[index] + filtered * preset.noise_amount) * envelope
	return samples


## Large splash: a low burst, a brighter mid burst and a scatter of droplets.
static func _render_splash(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var low := 0.0
	var mid := 0.0
	var mid_floor := 0.0
	var low_coefficient := SynthDsp.one_pole_coefficient(preset.pitch_hz, float(mix_rate))
	var mid_coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var floor_coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz * 0.3, float(mix_rate))
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var white := random.randf_range(-1.0, 1.0)
		low += low_coefficient * (white - low)
		mid += mid_coefficient * (white - mid)
		mid_floor += floor_coefficient * (mid - mid_floor)
		var envelope := SynthDsp.adsr(time_sec, preset.attack_sec, preset.decay_sec, 0.25, preset.release_sec, preset.attack_sec + preset.decay_sec)
		samples[index] = (low * 2.2 * SynthDsp.exp_decay(time_sec, duration * 0.5) + (mid - mid_floor) * 1.8) * envelope

	for drop: int in random.randi_range(5, 8):
		var start := int(random.randf_range(0.05, duration * 0.75) * mix_rate)
		var drop_sec := random.randf_range(0.03, 0.07)
		var pitch := random.randf_range(700.0, 1500.0)
		var count := mini(int(drop_sec * mix_rate), samples.size() - start)
		var phase := 0.0
		for index: int in count:
			var progress := float(index) / float(count)
			phase += TAU * pitch * (1.0 + 0.6 * progress) / float(mix_rate)
			samples[start + index] += sin(phase) * sin(progress * PI) * 0.22 * preset.noise_amount
	return samples


## Purchase (GDD 175.7): two warm plucked notes, the second a third higher.
static func _render_two_note(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	_add_pluck(samples, 0, preset.pitch_hz, preset.decay_sec, mix_rate, random, 0.8)
	_add_pluck(samples, int(duration * 0.3 * mix_rate), preset.pitch_hz * 1.25, preset.decay_sec, mix_rate, random, 0.8)
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var attack := minf(time_sec / maxf(preset.attack_sec, 0.000001), 1.0)
		var release := minf((duration - time_sec) / maxf(preset.release_sec, 0.000001), 1.0)
		samples[index] *= attack * release
	return samples


## One Karplus-Strong note mixed into `samples` from `start`. The string is
## excited with smoothed noise, which makes the pluck round instead of bright.
static func _add_pluck(samples: PackedFloat32Array, start: int, pitch_hz: float, ring_sec: float, mix_rate: int, random: RandomNumberGenerator, gain: float) -> void:
	var period := maxi(int(float(mix_rate) / maxf(pitch_hz, 20.0)), 2)
	var line := PackedFloat32Array()
	line.resize(period)
	var smooth := 0.0
	for index: int in period:
		smooth += 0.35 * (random.randf_range(-1.0, 1.0) - smooth)
		line[index] = smooth * 2.0
	var damping := clampf(0.5 - 0.004 / maxf(ring_sec, 0.02), 0.44, 0.4995)
	var position := 0
	for index: int in range(start, samples.size()):
		var next := (position + 1) % period
		var value := line[position]
		line[position] = (value + line[next]) * damping
		position = next
		samples[index] += value * gain


## Sale (GDD 175.7): a few soft paper-and-coin ticks, close together and
## getting quieter. It is a counted handful, never a slot-machine cascade.
static func _render_tick_cluster(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var intervals: Array[float] = [1.0, 1.26, 0.94, 1.41]
	var start_sec := 0.0
	for tick: int in intervals.size():
		var start := int(start_sec * mix_rate)
		var count := mini(int(0.07 * mix_rate), samples.size() - start)
		var pitch := preset.pitch_hz * intervals[tick]
		var level := 1.0 - 0.14 * float(tick)
		var filtered := 0.0
		for index: int in count:
			var time_sec := float(index) / float(mix_rate)
			filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
			var paper := filtered * SynthDsp.exp_decay(time_sec, 0.014) * preset.noise_amount * 1.8
			var coin := sin(TAU * pitch * time_sec) * SynthDsp.exp_decay(time_sec, 0.05) * (1.0 - preset.noise_amount)
			samples[start + index] += (paper + coin) * level
		start_sec += random.randf_range(0.05, 0.085)
	return samples


## Debt payment (GDD 175.7): one clean, warm chime. A sine with two quieter
## partials that die away sooner, and the faintest strike at the start.
static func _render_chime(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var filtered := 0.0
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var angle := TAU * preset.pitch_hz * time_sec
		var tone := sin(angle) * SynthDsp.exp_decay(time_sec, duration) \
			+ sin(angle * 2.0) * 0.32 * SynthDsp.exp_decay(time_sec, duration * 0.55) \
			+ sin(angle * 3.01) * 0.12 * SynthDsp.exp_decay(time_sec, duration * 0.3)
		filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
		var strike := filtered * SynthDsp.exp_decay(time_sec, 0.008) * preset.noise_amount
		samples[index] = (tone * 0.7 + strike) * minf(time_sec / maxf(preset.attack_sec, 0.000001), 1.0)
	return samples


## Knockout (GDD 175.8): three low toms stepping down, each a sine that drops
## in pitch with a soft stick hit on top. Comic, not violent.
static func _render_tom_sequence(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var steps: Array[float] = [1.0, 0.8, 0.62]
	var spacing := duration * 0.27
	for tom: int in steps.size():
		var start := int(spacing * float(tom) * mix_rate)
		var ring_sec := duration - spacing * float(tom)
		var count := samples.size() - start
		var pitch := preset.pitch_hz * steps[tom]
		var phase := 0.0
		var filtered := 0.0
		for index: int in count:
			var time_sec := float(index) / float(mix_rate)
			# The head tightens back down after the hit: the pitch falls fast.
			phase += TAU * pitch * (1.0 + 0.5 * SynthDsp.exp_decay(time_sec, 0.06)) / float(mix_rate)
			filtered += coefficient * (random.randf_range(-1.0, 1.0) - filtered)
			var body := sin(phase) * SynthDsp.exp_decay(time_sec, minf(ring_sec, 0.34))
			var stick := filtered * SynthDsp.exp_decay(time_sec, 0.012) * preset.noise_amount * 1.6
			samples[start + index] += (body + stick) * 0.75
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		samples[index] *= minf((duration - time_sec) / maxf(preset.release_sec, 0.000001), 1.0)
	return samples


## Burst telegraph (GDD 175.9): a low pulse that rises from pitch_hz to
## filter_cutoff_hz and beats faster as it goes.
static func _render_rising_pulse(preset: AudioPreset, mix_rate: int) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var phase := 0.0
	var beat := 0.0
	for index: int in samples.size():
		var time_sec := float(index) / float(mix_rate)
		var progress := time_sec / duration
		phase += TAU * lerpf(preset.pitch_hz, preset.filter_cutoff_hz, progress) / float(mix_rate)
		beat += TAU * lerpf(5.0, 11.0, progress) / float(mix_rate)
		var pulse := 0.5 + 0.5 * sin(beat)
		var body := sin(phase) + 0.3 * sin(phase * 2.0)
		samples[index] = body * pulse * pulse * minf(time_sec / maxf(preset.attack_sec, 0.000001), 1.0) \
			* minf((duration - time_sec) / maxf(preset.release_sec, 0.000001), 1.0) * 0.8
	return samples


## A short parody fanfare (GDD 175.9): root, fifth, octave, the last one held.
static func _render_fanfare(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	var notes: Array[float] = [1.0, 1.5, 2.0]
	var starts: Array[float] = [0.0, 0.12, 0.24]
	for note: int in notes.size():
		_add_brass(samples, int(starts[note] * duration / 0.85 * mix_rate), preset.pitch_hz * notes[note],
			duration - starts[note], mix_rate, 0.55 if note < 2 else 0.75)
	return samples


## Losing (GDD 175.9): two notes stepping down, a little flat.
static func _render_two_note_down(preset: AudioPreset, mix_rate: int, random: RandomNumberGenerator) -> PackedFloat32Array:
	var duration := _duration(preset)
	var samples := _buffer(duration, mix_rate)
	_add_brass(samples, 0, preset.pitch_hz, duration * 0.45, mix_rate, 0.6)
	_add_brass(samples, int(duration * 0.42 * mix_rate), preset.pitch_hz * 0.75 * 0.985, duration * 0.58, mix_rate, 0.6)
	return samples


## A soft square-ish note with a quick swell and a slow fade.
static func _add_brass(samples: PackedFloat32Array, start: int, pitch_hz: float, length_sec: float, mix_rate: int, gain: float) -> void:
	var count := mini(int(length_sec * mix_rate), samples.size() - start)
	var phase := 0.0
	for index: int in count:
		var time_sec := float(index) / float(mix_rate)
		phase += TAU * pitch_hz / float(mix_rate)
		var tone := sin(phase) + 0.33 * sin(phase * 3.0) + 0.18 * sin(phase * 5.0)
		var envelope := minf(time_sec / 0.02, 1.0) * SynthDsp.exp_decay(time_sec, length_sec * 1.4) \
			* minf((length_sec - time_sec) / 0.03, 1.0)
		samples[start + index] += tone * envelope * gain * 0.6


# --- Shared -----------------------------------------------------------------

static func _duration(preset: AudioPreset) -> float:
	return maxf(preset.attack_sec + preset.decay_sec + preset.release_sec, 0.005)


static func _buffer(duration: float, mix_rate: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(maxi(int(duration * mix_rate), 1))
	return samples


## Applies the preset gain, a soft limiter and short edge fades.
static func _finish(samples: PackedFloat32Array, preset: AudioPreset, mix_rate: int) -> void:
	var gain := SynthDsp.db_to_gain(preset.base_gain_db)
	for index: int in samples.size():
		samples[index] = SynthDsp.soft_clip(samples[index] * gain) * PEAK_LIMIT
	SynthDsp.apply_edge_fades(samples, int(EDGE_FADE_SEC * mix_rate))


static func _resolve_seed(preset: AudioPreset, seed: int) -> int:
	if preset.seed_mode == &"varied" and seed >= 0:
		return seed
	# Fixed presets always use a seed derived from their ID.
	return SynthDsp.stable_hash(String(preset.id))
