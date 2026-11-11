class_name SfxRenderer
extends RefCounted
## Renders short procedural sound effects into memory (GDD 175.2).
## Critical one-shots are rendered once and cached as in-memory AudioStreamWAV,
## so pressing a button never waits for a synthesis block.

const SYNTH_CLICK := &"click"
const SUPPORTED_SYNTH_TYPES: Array[StringName] = [SYNTH_CLICK]
const EDGE_FADE_SEC := 0.0015
const PEAK_LIMIT := 0.98


## Returns mono samples in the -1..1 range, or an empty buffer when the preset
## cannot be rendered. `seed` only matters for presets with seed_mode "varied".
static func render(preset: AudioPreset, mix_rate: int, seed: int = -1) -> PackedFloat32Array:
	if preset == null or mix_rate <= 0:
		return PackedFloat32Array()
	var samples: PackedFloat32Array
	match preset.synth_type:
		SYNTH_CLICK:
			samples = _render_click(preset, mix_rate, seed)
		_:
			GameLog.error(&"AUDIO", "unsupported synth type", {"preset": preset.id, "type": preset.synth_type})
			return PackedFloat32Array()
	SynthDsp.apply_edge_fades(samples, int(EDGE_FADE_SEC * mix_rate))
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


## Wood/plastic UI click (GDD 175.7): a very short low-passed noise impulse
## for the contact, plus a quickly decaying sine for the body.
static func _render_click(preset: AudioPreset, mix_rate: int, seed: int) -> PackedFloat32Array:
	var duration := preset.attack_sec + preset.decay_sec + preset.release_sec
	var count := maxi(int(duration * mix_rate), 1)
	var samples := PackedFloat32Array()
	samples.resize(count)

	var noise := RandomNumberGenerator.new()
	noise.seed = _resolve_seed(preset, seed)
	var pitch := preset.pitch_hz
	if preset.seed_mode == &"varied" and seed >= 0:
		pitch *= noise.randf_range(0.96, 1.04)

	var coefficient := SynthDsp.one_pole_coefficient(preset.filter_cutoff_hz, float(mix_rate))
	var gain := SynthDsp.db_to_gain(preset.base_gain_db)
	var impulse_sec := maxf(preset.decay_sec * 0.22, 0.003)
	var filtered := 0.0
	var phase := 0.0
	var phase_step := TAU * pitch / float(mix_rate)

	for index: int in count:
		var time_sec := float(index) / float(mix_rate)
		var envelope := SynthDsp.adsr(time_sec, preset.attack_sec, preset.decay_sec, preset.sustain, preset.release_sec, 0.0)
		# The decay stage runs to the sustain level; an extra exponential tail keeps
		# zero-sustain clicks from ending in a straight ramp.
		var body_envelope := SynthDsp.exp_decay(time_sec, duration)
		var impulse_envelope := SynthDsp.exp_decay(time_sec, impulse_sec)

		filtered += coefficient * (noise.randf_range(-1.0, 1.0) - filtered)
		var body := sin(phase) * body_envelope
		phase += phase_step

		var mixed := body * (1.0 - preset.noise_amount * 0.5) + filtered * impulse_envelope * preset.noise_amount * 1.6
		var shaped := mixed * maxf(envelope, body_envelope * 0.35)
		samples[index] = SynthDsp.soft_clip(shaped * gain * 1.4) * PEAK_LIMIT
	return samples


static func _resolve_seed(preset: AudioPreset, seed: int) -> int:
	if preset.seed_mode == &"varied" and seed >= 0:
		return seed
	# Fixed presets always use a seed derived from their ID.
	return SynthDsp.stable_hash(String(preset.id))
