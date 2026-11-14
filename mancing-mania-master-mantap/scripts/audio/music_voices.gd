class_name MusicVoices
extends RefCounted
## The instruments of the procedural music (GDD 175.3, 175.10, 175.11).
##
## Each voice renders one note into a short mono buffer. The sequencer places
## those notes on a timeline and the renderer mixes them, so a voice is
## synthesized once per pitch and length and then reused for every hit.
## Everything is a pure function of its arguments: the same note always
## renders the same samples.

const KICK := &"kick"
const SNARE := &"snare"
const HAT_CLOSED := &"hat_closed"
const HAT_OPEN := &"hat_open"
const KENDANG_LOW := &"kendang_low"
const KENDANG_HIGH := &"kendang_high"
const BASS := &"bass"
const PLUCK := &"pluck"
const PAD := &"pad"
const ACCENT := &"accent"
const CLICK := &"click"
const BLIP := &"blip"
const ALL: Array[StringName] = [
	KICK, SNARE, HAT_CLOSED, HAT_OPEN, KENDANG_LOW, KENDANG_HIGH, BASS, PLUCK, PAD, ACCENT, CLICK, BLIP,
]


## Renders `voice` at `pitch_hz` for about `length_sec` at `rate` samples/s.
static func render(voice: StringName, pitch_hz: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var noise := RandomNumberGenerator.new()
	noise.seed = SynthDsp.stable_hash("%s:%d:%d" % [voice, roundi(pitch_hz * 10.0), roundi(length_sec * 1000.0)])
	match voice:
		KICK:
			return _kick(rate, noise)
		SNARE:
			return _snare(rate, noise)
		HAT_CLOSED:
			return _hat(rate, noise, 0.045)
		HAT_OPEN:
			return _hat(rate, noise, 0.22)
		KENDANG_LOW:
			return _kendang(pitch_hz if pitch_hz > 0.0 else 95.0, 0.3, 1.45, rate, noise)
		KENDANG_HIGH:
			return _kendang(pitch_hz if pitch_hz > 0.0 else 320.0, 0.12, 1.08, rate, noise)
		BASS:
			return _bass(pitch_hz, length_sec, rate)
		PLUCK:
			return _pluck(pitch_hz, length_sec, rate, noise)
		PAD:
			return _pad(pitch_hz, length_sec, rate)
		ACCENT:
			return _accent(pitch_hz, length_sec, rate)
		CLICK:
			return _click(pitch_hz, rate)
		BLIP:
			return _blip(pitch_hz, length_sec, rate)
	return PackedFloat32Array()


## Frequency of a MIDI note number.
static func midi_hz(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


# --- Drums ------------------------------------------------------------------

## Sine with a fast pitch drop plus a short click (GDD 175.10).
static func _kick(rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(0.28, rate)
	var phase := 0.0
	for index: int in samples.size():
		var t := float(index) / float(rate)
		phase += TAU * (48.0 + 110.0 * exp(-t * 32.0)) / float(rate)
		var click := noise.randf_range(-1.0, 1.0) * exp(-t * 400.0) * 0.4
		samples[index] = (sin(phase) * exp(-t * 11.0) + click) * 0.95
	return samples


## Filtered noise with a short body tone.
static func _snare(rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(0.2, rate)
	var low := 0.0
	var phase := 0.0
	for index: int in samples.size():
		var t := float(index) / float(rate)
		var white := noise.randf_range(-1.0, 1.0)
		low += 0.45 * (white - low)
		phase += TAU * 190.0 / float(rate)
		samples[index] = ((white - low) * exp(-t * 22.0) * 0.8 + sin(phase) * exp(-t * 30.0) * 0.5) * 0.7
	return samples


## High-passed noise; `decay_sec` separates closed and open.
static func _hat(rate: int, noise: RandomNumberGenerator, decay_sec: float) -> PackedFloat32Array:
	var samples := _buffer(decay_sec * 1.6, rate)
	var low := 0.0
	for index: int in samples.size():
		var t := float(index) / float(rate)
		var white := noise.randf_range(-1.0, 1.0)
		low += 0.6 * (white - low)
		samples[index] = (white - low) * SynthDsp.exp_decay(t, decay_sec) * 0.45
	return samples


## A resonant drum with a pitch bend: `bend` above 1 bends up into the note,
## which gives the low kendang its "dhut".
static func _kendang(pitch: float, decay_sec: float, bend: float, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(decay_sec * 1.4, rate)
	var phase := 0.0
	for index: int in samples.size():
		var t := float(index) / float(rate)
		var glide := lerpf(1.0, bend, exp(-t * 18.0)) if bend < 1.2 else lerpf(bend, 1.0, exp(-t * 14.0))
		phase += TAU * pitch * glide / float(rate)
		var body := sin(phase) + 0.25 * sin(phase * 2.0)
		var slap := noise.randf_range(-1.0, 1.0) * exp(-t * 300.0) * 0.3
		samples[index] = (body * SynthDsp.exp_decay(t, decay_sec) + slap) * 0.7
	return samples


# --- Tonal ------------------------------------------------------------------

## Triangle and sine together, with a soft attack and a short release.
static func _bass(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(length_sec + 0.03, rate)
	var phase := 0.0
	for index: int in samples.size():
		var t := float(index) / float(rate)
		phase += pitch / float(rate)
		var triangle := 4.0 * absf(fposmod(phase, 1.0) - 0.5) - 1.0
		var tone := triangle * 0.6 + sin(TAU * phase) * 0.5
		var envelope := minf(t / 0.006, 1.0) * minf(maxf(length_sec + 0.03 - t, 0.0) / 0.03, 1.0) * (0.75 + 0.25 * exp(-t * 8.0))
		samples[index] = tone * envelope * 0.55
	return samples


## Karplus-Strong string: a burst of noise in a loop that loses its brightness.
static func _pluck(pitch: float, length_sec: float, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var period := maxi(int(float(rate) / maxf(pitch, 30.0)), 2)
	var line := PackedFloat32Array()
	line.resize(period)
	var smooth := 0.0
	for index: int in period:
		smooth += 0.5 * (noise.randf_range(-1.0, 1.0) - smooth)
		line[index] = smooth * 1.6
	var position := 0
	for index: int in samples.size():
		var next := (position + 1) % period
		var value := line[position]
		line[position] = (value + line[next]) * 0.497
		position = next
		var t := float(index) / float(rate)
		samples[index] = value * 0.5 * minf((length_sec - t) / 0.04, 1.0)
	return samples


## A soft three-voice chord: root, minor third and fifth of `pitch`.
static func _pad(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var ratios: Array[float] = [1.0, 1.189, 1.498]
	for index: int in samples.size():
		var t := float(index) / float(rate)
		var value := 0.0
		for ratio: float in ratios:
			var phase := fposmod(pitch * ratio * t, 1.0)
			value += (4.0 * absf(phase - 0.5) - 1.0) * 0.6 + sin(TAU * pitch * ratio * t) * 0.4
		var envelope := minf(t / 0.25, 1.0) * minf((length_sec - t) / 0.35, 1.0)
		samples[index] = value * envelope * 0.12
	return samples


## The comedic accent: a short note that bends down a fourth.
static func _accent(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var phase := 0.0
	for index: int in samples.size():
		var t := float(index) / float(rate)
		var progress := t / length_sec
		phase += TAU * pitch * lerpf(1.0, 0.75, progress * progress) / float(rate)
		var square := 1.0 if sin(phase) >= 0.0 else -1.0
		samples[index] = (square * 0.3 + sin(phase) * 0.5) * minf(t / 0.01, 1.0) * (1.0 - progress) * 0.5
	return samples


## Metronome tick for the calibration click track and the count-in.
static func _click(pitch: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(0.05, rate)
	for index: int in samples.size():
		var t := float(index) / float(rate)
		samples[index] = sin(TAU * pitch * t) * exp(-t * 90.0) * 0.8
	return samples


## A short square-ish game tone for the arcade loop.
static func _blip(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var phase := 0.0
	for index: int in samples.size():
		var t := float(index) / float(rate)
		phase += pitch / float(rate)
		var pulse := 1.0 if fposmod(phase, 1.0) < 0.35 else -1.0
		samples[index] = pulse * 0.22 * minf(t / 0.004, 1.0) * minf((length_sec - t) / 0.02, 1.0)
	return samples


static func _buffer(seconds: float, rate: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(maxi(int(seconds * float(rate)), 1))
	return samples
