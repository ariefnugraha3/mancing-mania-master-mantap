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

const SYNTH_CLICK := &"click"
const SYNTH_NOISE_SWEEP := &"noise_sweep"
const SYNTH_DROPLET := &"droplet"
const SYNTH_THUMP := &"thump"
const SYNTH_PLUCK := &"pluck"
const SYNTH_CREAK := &"creak"
const SYNTH_SNAP := &"snap"
const SYNTH_SPLASH := &"splash"
const SUPPORTED_SYNTH_TYPES: Array[StringName] = [
	SYNTH_CLICK, SYNTH_NOISE_SWEEP, SYNTH_DROPLET, SYNTH_THUMP,
	SYNTH_PLUCK, SYNTH_CREAK, SYNTH_SNAP, SYNTH_SPLASH,
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
		_:
			GameLog.error(&"AUDIO", "unsupported synth type", {"preset": preset.id, "type": preset.synth_type})
			return PackedFloat32Array()
	_finish(samples, preset, mix_rate)
	return samples


## Wraps mono samples as an in-memory 16-bit PCM stream.
static func to_stream(samples: PackedFloat32Array, mix_rate: int) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index: int in samples.size():
		bytes.encode_s16(index * 2, int(clampf(samples[index], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = bytes
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
