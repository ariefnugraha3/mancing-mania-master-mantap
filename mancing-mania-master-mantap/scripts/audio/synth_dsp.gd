class_name SynthDsp
extends RefCounted
## Small DSP building blocks shared by the procedural audio code (GDD 175.3).
## Everything here is a pure function over numbers or sample buffers, so the
## same input always renders the same sound.


## Linear attack / decay-to-sustain / release envelope value at `time_sec`.
## `hold_sec` is how long the note stays down before the release begins.
static func adsr(time_sec: float, attack: float, decay: float, sustain: float, release: float, hold_sec: float) -> float:
	if time_sec < 0.0:
		return 0.0
	var gate_end := maxf(hold_sec, attack + decay)
	if time_sec < attack:
		return time_sec / maxf(attack, 0.000001)
	if time_sec < attack + decay:
		var decay_progress := (time_sec - attack) / maxf(decay, 0.000001)
		return lerpf(1.0, sustain, decay_progress)
	if time_sec < gate_end:
		return sustain
	var release_progress := (time_sec - gate_end) / maxf(release, 0.000001)
	return maxf(sustain * (1.0 - release_progress), 0.0)


## Exponential decay that reaches -60 dB after `duration_sec`.
static func exp_decay(time_sec: float, duration_sec: float) -> float:
	if time_sec < 0.0:
		return 0.0
	return exp(-6.9078 * time_sec / maxf(duration_sec, 0.000001))


## Coefficient for a one-pole low-pass filter at `cutoff_hz`.
static func one_pole_coefficient(cutoff_hz: float, mix_rate: float) -> float:
	var clamped := clampf(cutoff_hz, 10.0, mix_rate * 0.45)
	return 1.0 - exp(-TAU * clamped / mix_rate)


## Gentle saturation used instead of hard clipping at the end of a synth chain.
static func soft_clip(sample: float) -> float:
	return tanh(sample)


static func db_to_gain(db: float) -> float:
	return pow(10.0, db / 20.0)


## Largest absolute sample value in a buffer.
static func peak(samples: PackedFloat32Array) -> float:
	var highest := 0.0
	for sample: float in samples:
		highest = maxf(highest, absf(sample))
	return highest


static func has_invalid_samples(samples: PackedFloat32Array) -> bool:
	for sample: float in samples:
		if is_nan(sample) or is_inf(sample):
			return true
	return false


## Short linear fades at both ends so a rendered clip never starts or stops
## on a non-zero sample (which would click).
static func apply_edge_fades(samples: PackedFloat32Array, fade_samples: int) -> void:
	var count := samples.size()
	var fade := mini(fade_samples, count >> 1)
	for index: int in fade:
		var gain := float(index) / float(fade)
		samples[index] *= gain
		samples[count - 1 - index] *= gain


## FNV-1a hash of a string. Unlike the engine's hash() it is guaranteed to stay
## the same across engine versions, so "fixed" sounds never change by accident.
static func stable_hash(text: String) -> int:
	var hash_value := 0x811C9DC5
	for byte: int in text.to_utf8_buffer():
		hash_value = ((hash_value ^ byte) * 0x01000193) & 0xFFFFFFFF
	return hash_value
