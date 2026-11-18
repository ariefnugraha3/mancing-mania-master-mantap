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
# Revision 6.9: the kampung-band palette of the state music.
const NYLON := &"nylon"
const STRUM_MAJOR := &"strum_major"
const STRUM_MINOR := &"strum_minor"
const SULING := &"suling"
const KEYS := &"keys"
const BELL := &"bell"
const GONG := &"gong"
const PIZZ := &"pizz"
const SHAKER := &"shaker"
const WOODBLOCK := &"woodblock"
const BRASS := &"brass"
const SOMPRET := &"sompret"
const TOM := &"tom"
const CRASH := &"crash"
const PAD_MAJOR := &"pad_major"
const ALL: Array[StringName] = [
	KICK, SNARE, HAT_CLOSED, HAT_OPEN, KENDANG_LOW, KENDANG_HIGH, BASS, PLUCK, PAD, ACCENT, CLICK, BLIP,
	NYLON, STRUM_MAJOR, STRUM_MINOR, SULING, KEYS, BELL, GONG, PIZZ, SHAKER, WOODBLOCK, BRASS, SOMPRET,
	TOM, CRASH, PAD_MAJOR,
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
		NYLON:
			return _nylon(pitch_hz, length_sec, rate, noise)
		STRUM_MAJOR:
			return _strum(pitch_hz, length_sec, false, rate, noise)
		STRUM_MINOR:
			return _strum(pitch_hz, length_sec, true, rate, noise)
		SULING:
			return _suling(pitch_hz, length_sec, rate, noise)
		KEYS:
			return _keys(pitch_hz, length_sec, rate)
		BELL:
			return _bell(pitch_hz, length_sec, rate, noise)
		GONG:
			return _gong(pitch_hz, length_sec, rate)
		PIZZ:
			return _pizz(pitch_hz, length_sec, rate)
		SHAKER:
			return _shaker(rate, noise)
		WOODBLOCK:
			return _woodblock(pitch_hz if pitch_hz > 0.0 else 900.0, rate, noise)
		BRASS:
			return _brass(pitch_hz, length_sec, rate)
		SOMPRET:
			return _sompret(pitch_hz, length_sec, rate)
		TOM:
			return _tom(pitch_hz if pitch_hz > 0.0 else 110.0, rate, noise)
		CRASH:
			return _crash(rate, noise)
		PAD_MAJOR:
			return _pad_major(pitch_hz, length_sec, rate)
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


# --- Revision 6.9 instruments --------------------------------------------------
# A warm, small "kampung band" palette for the state music: nylon guitar,
# ukulele cak-cuk, bamboo flute, soft electric piano, gamelan saron and gong,
# pizzicato bass, shaker, woodblock, the pencak silat sompret, brass, toms
# and a crash. They are written to be cheap: no function call per sample,
# envelopes that multiply instead of calling exp(), partials as damped
# resonators (four at once in a Vector4), a looped breath noise, and notes
# that stop once they have decayed out of hearing.

const _HALF4 := Vector4(0.5, 0.5, 0.5, 0.5)
const _ONE4 := Vector4(1.0, 1.0, 1.0, 1.0)
## Length of the looped breath noise of the suling.
const _BREATH_LOOP := 4096


## A nylon-string guitar: a soft Karplus-Strong string with a little body.
static func _nylon(pitch: float, length_sec: float, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var period := maxi(int(float(rate) / maxf(pitch, 30.0)), 2)
	var line := PackedFloat32Array()
	line.resize(period)
	var smooth := 0.0
	for index: int in period:
		# A thumb, not a pick: the excitation is darker than the pluck's.
		smooth += 0.32 * (noise.randf_range(-1.0, 1.0) - smooth)
		line[index] = smooth * 2.2
	# The guitar body: a damped sine at the note, as a two-pole resonator.
	var w := TAU * pitch / float(rate)
	var r := exp(-3.5 / float(rate))
	var body_a := 2.0 * r * cos(w)
	var body_b := r * r
	var body := 0.22 * r * sin(w)
	var body_prev := 0.0
	var position := 0
	for index: int in samples.size():
		var next := position + 1
		if next == period:
			next = 0
		var value := line[position]
		line[position] = (value + line[next]) * 0.4985
		position = next
		samples[index] = value * 0.55 + body_prev
		var body_next := body_a * body - body_b * body_prev
		body_prev = body
		body = body_next
	_fade(samples, 0.003, 0.05, rate)
	return samples


## A ukulele strum of a triad on `root`: three short bright strings, a few
## milliseconds apart, the "cak" of keroncong.
static func _strum(root: float, length_sec: float, minor: bool, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var ratios: Array[float] = [1.0, 1.189 if minor else 1.26, 1.498]
	for string: int in ratios.size():
		var period := maxi(int(float(rate) / maxf(root * ratios[string], 30.0)), 2)
		var line := PackedFloat32Array()
		line.resize(period)
		for index: int in period:
			line[index] = noise.randf_range(-0.3, 0.3)
		var position := 0
		for index: int in range(int(0.009 * float(string) * float(rate)), samples.size()):
			var next := position + 1
			if next == period:
				next = 0
			var value := line[position]
			line[position] = (value + line[next]) * 0.493
			position = next
			samples[index] += value
	_fade(samples, 0.0, 0.03, rate)
	return samples


## Bamboo flute (suling): a near-sine with a breath of noise, a little scoop
## into the note and a gentle vibrato that grows on long notes.
static func _suling(pitch: float, length_sec: float, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(length_sec + 0.06, rate)
	var breath := _breath_loop(noise)
	var increment := TAU * pitch / float(rate)
	# The vibrato is updated every fourth sample; it moves far slower.
	var vibrato_increment := TAU * 5.3 * 4.0 / float(rate)
	var vibrato_start := 0.18 * float(rate)
	var vibrato_ramp := 0.27 * float(rate)
	var phase := 0.0
	var vibrato_phase := 0.0
	var bend := 1.0
	var scoop := 0.025
	var scoop_decay := exp(-28.0 * 4.0 / float(rate))
	var puff := 1.0
	var puff_decay := exp(-18.0 / float(rate))
	for index: int in samples.size():
		if index & 3 == 0:
			bend = (1.0 - scoop) * (1.0 + 0.0065 * clampf((float(index) - vibrato_start) / vibrato_ramp, 0.0, 1.0) * sin(vibrato_phase))
			vibrato_phase += vibrato_increment
			scoop *= scoop_decay
		phase += increment * bend
		var s := sin(phase)
		var s2 := s * s
		# The fundamental with a soft second and third harmonic.
		samples[index] = (s + 0.16 * (1.0 - 2.0 * s2) + 0.05 * s * (3.0 - 4.0 * s2)) * 0.33 + breath[index & (_BREATH_LOOP - 1)] * (0.06 + 0.21 * puff)
		puff *= puff_decay
	_fade(samples, 0.045, 0.08, rate)
	return samples


## A soft electric piano: two-operator FM whose brightness fades, so a note
## starts with a little bell and settles into a round tone.
static func _keys(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	# A short stab gets a short tail; a held chord rings on a little longer.
	var tail := minf(0.35, 0.1 + length_sec * 0.5)
	var samples := _buffer(length_sec + tail, rate)
	var increment := TAU * pitch / float(rate)
	var phase := 0.0
	var depth := 1.3
	var depth_decay := exp(-5.0 / float(rate))
	var level := 0.38
	var level_decay := exp(-6.9078 / ((length_sec * 1.6 + 0.4) * float(rate)))
	for index: int in samples.size():
		samples[index] = sin(phase + (depth + 0.2) * sin(phase)) * level
		phase += increment
		depth *= depth_decay
		level *= level_decay
	_fade(samples, 0.004, minf(0.25, tail), rate)
	return samples


## A gamelan saron / bonang bar: bright inharmonic partials over a slightly
## detuned twin, so the note shimmers the way bronze does.
static func _bell(pitch: float, length_sec: float, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _resonators(pitch, length_sec, rate, Vector4(1.0, 1.004, 2.76, 5.4), Vector4(1.0, 0.35, 0.32, 0.12), Vector4(1.0, 0.9, 0.35, 0.14), 0.32)
	_fade(samples, 0.002, 0.0, rate)
	# The mallet: a few milliseconds of noise.
	var level := 0.08
	var decay := exp(-600.0 / float(rate))
	for index: int in mini(int(0.012 * float(rate)), samples.size()):
		samples[index] += noise.randf_range(-1.0, 1.0) * level
		level *= decay
	return samples


## A gong ageng: a low beating pair of tones with a long, slow decay.
static func _gong(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _resonators(pitch, length_sec, rate, Vector4(1.0, 1.008, 2.01, 2.98), Vector4(1.0, 0.65, 0.22, 0.12), _ONE4, 0.42)
	_fade(samples, 0.015, 0.0, rate)
	return samples


## Pizzicato bass: a plucked round note with a quick thump. It has died
## away after 0.9 s, so a longer note stops there.
static func _pizz(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(minf(length_sec, 0.95), rate)
	var increment := pitch / float(rate)
	var phase := 0.0
	var thump := 0.03
	var thump_decay := exp(-60.0 / float(rate))
	var level := 0.6
	var level_decay := exp(-6.9078 / (minf(length_sec, 0.9) * float(rate)))
	for index: int in samples.size():
		phase += increment * (1.0 + thump)
		if phase >= 1.0:
			phase -= 1.0
		thump *= thump_decay
		# A triangle bent toward a sine.
		var triangle := 4.0 * absf(phase - 0.5) - 1.0
		samples[index] = triangle * (1.55 - 0.4 * triangle * triangle) * level
		level *= level_decay
	_fade(samples, 0.003, 0.02, rate)
	return samples


## A shaker / kecrek: a short burst of band-limited noise.
static func _shaker(rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(0.11, rate)
	var low := 0.0
	var lower := 0.0
	var level := 0.5
	var decay := exp(-6.9078 / (0.09 * float(rate)))
	for index: int in samples.size():
		low += 0.7 * (noise.randf_range(-1.0, 1.0) - low)
		lower += 0.2 * (low - lower)
		samples[index] = (low - lower) * level
		level *= decay
	_fade(samples, 0.008, 0.0, rate)
	return samples


## A woodblock tick for the suspense parody.
static func _woodblock(pitch: float, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(0.07, rate)
	for index: int in samples.size():
		var t := float(index) / float(rate)
		var tone := sin(TAU * pitch * t) + 0.4 * sin(TAU * pitch * 2.4 * t)
		var click := noise.randf_range(-1.0, 1.0) * exp(-t * 900.0) * 0.4
		samples[index] = (tone * exp(-t * 70.0) + click) * 0.5
	return samples


## A brass section stab: two slightly detuned saws through a filter that
## opens on the attack and closes as the note settles.
static func _brass(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(length_sec + 0.05, rate)
	var increment_a := pitch / float(rate)
	var increment_b := pitch * 1.005 / float(rate)
	var phase_a := 0.0
	var phase_b := 0.0
	var filtered := 0.0
	var coefficient := 0.0
	var sweep := 2600.0
	# The filter is re-tuned every 32 samples; the sweep decays to match.
	var sweep_decay := exp(-7.0 * 32.0 / float(rate))
	var attack := 0.03 * float(rate)
	var swell := 0.25
	var swell_decay := exp(-6.0 / float(rate))
	for index: int in samples.size():
		if index & 31 == 0:
			var cutoff := minf(700.0 + sweep + 900.0 * minf(float(index) / attack, 1.0), float(rate) * 0.45)
			coefficient = 1.0 - exp(-TAU * cutoff / float(rate))
			sweep *= sweep_decay
		phase_a += increment_a
		if phase_a >= 1.0:
			phase_a -= 1.0
		phase_b += increment_b
		if phase_b >= 1.0:
			phase_b -= 1.0
		filtered += coefficient * ((phase_a + phase_b) * 2.0 - 2.0 - filtered)
		samples[index] = filtered * (0.75 + swell) * 0.26
		swell *= swell_decay
	_fade(samples, 0.025, 0.06, rate)
	return samples


## The sompret (pencak silat trumpet): a nasal reed with a wide vibrato.
static func _sompret(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(length_sec + 0.04, rate)
	var increment := pitch / float(rate)
	var coefficient := SynthDsp.one_pole_coefficient(2600.0, float(rate))
	var vibrato_increment := TAU * 6.2 * 4.0 / float(rate)
	var vibrato_start := 0.08 * float(rate)
	var vibrato_ramp := 0.22 * float(rate)
	var vibrato_phase := 0.0
	var bend := 1.0
	var phase := 0.0
	var filtered := 0.0
	for index: int in samples.size():
		if index & 3 == 0:
			bend = 1.0 + 0.011 * clampf((float(index) - vibrato_start) / vibrato_ramp, 0.0, 1.0) * sin(vibrato_phase)
			vibrato_phase += vibrato_increment
		phase += increment * bend
		if phase >= 1.0:
			phase -= 1.0
		var pulse := (1.0 if phase < 0.28 else -0.4) + (phase * 2.0 - 1.0) * 0.4
		filtered += coefficient * (pulse - filtered)
		samples[index] = filtered * 0.22
	_fade(samples, 0.02, 0.05, rate)
	return samples


## A tom / bass drum of the drum band at `pitch`.
static func _tom(pitch: float, rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(0.4, rate)
	var increment := TAU * pitch / float(rate)
	var phase := 0.0
	var bend := 0.7
	var bend_decay := exp(-26.0 / float(rate))
	var level := 0.75
	var level_decay := exp(-6.9078 / (0.38 * float(rate)))
	for index: int in samples.size():
		phase += increment * (1.0 + bend)
		bend *= bend_decay
		samples[index] = sin(phase) * level
		level *= level_decay
	var click := 0.225
	var click_decay := exp(-350.0 / float(rate))
	for index: int in mini(int(0.02 * float(rate)), samples.size()):
		samples[index] += noise.randf_range(-1.0, 1.0) * click
		click *= click_decay
	return samples


## A crash cymbal: bright noise with a long tail.
static func _crash(rate: int, noise: RandomNumberGenerator) -> PackedFloat32Array:
	var samples := _buffer(1.5, rate)
	var low := 0.0
	var level := 0.32
	var decay := exp(-6.9078 / (1.4 * float(rate)))
	for index: int in samples.size():
		var white := noise.randf_range(-1.0, 1.0)
		low += 0.55 * (white - low)
		samples[index] = (white - low) * level
		level *= decay
	_fade(samples, 0.002, 0.0, rate)
	return samples


## A soft major chord (root, major third, fifth and octave): four rounded
## triangles in one Vector4.
static func _pad_major(pitch: float, length_sec: float, rate: int) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var increment := Vector4(1.0, 1.26, 1.498, 2.0) * (pitch / float(rate))
	var weights := Vector4(1.0, 0.8, 0.8, 0.35) * 0.1
	var rounding := _ONE4 * 1.275
	var phase := Vector4.ZERO
	for index: int in samples.size():
		phase += increment
		phase -= phase.floor()
		var triangle := (phase - _HALF4).abs() * 4.0 - _ONE4
		samples[index] = (triangle * (rounding - triangle * triangle * 0.275)).dot(weights)
	_fade(samples, 0.3, 0.4, rate)
	return samples


# --- Helpers --------------------------------------------------------------------

## Four decaying sine partials as two-pole resonators, one per Vector4 lane:
## `ratios` of `pitch`, `weights`, and each lane's -60 dB time as a share of
## `length_sec`. Partials at or above the Nyquist limit are left out.
static func _resonators(pitch: float, length_sec: float, rate: int, ratios: Vector4, weights: Vector4, decays: Vector4, gain: float) -> PackedFloat32Array:
	var samples := _buffer(length_sec, rate)
	var a := Vector4.ZERO
	var b := Vector4.ZERO
	var current := Vector4.ZERO
	for lane: int in 4:
		var hz := pitch * ratios[lane]
		if hz >= float(rate) * 0.45:
			continue
		var w := TAU * hz / float(rate)
		var r := exp(-6.9078 / (maxf(length_sec * decays[lane], 0.01) * float(rate)))
		a[lane] = 2.0 * r * cos(w)
		b[lane] = r * r
		current[lane] = weights[lane] * gain * r * sin(w)
	var previous := Vector4.ZERO
	for index: int in range(1, samples.size()):
		samples[index] = current.x + current.y + current.z + current.w
		var next := a * current - b * previous
		previous = current
		current = next
	return samples


## Linear fades: in over `attack_sec`, out over the last `release_sec`.
static func _fade(samples: PackedFloat32Array, attack_sec: float, release_sec: float, rate: int) -> void:
	var count := samples.size()
	var attack := mini(int(attack_sec * float(rate)), count)
	for index: int in attack:
		samples[index] *= float(index) / float(attack)
	var release := mini(int(release_sec * float(rate)), count)
	for index: int in release:
		samples[count - 1 - index] *= float(index) / float(release)


## A short loop of band-passed noise: the breath of the suling.
static func _breath_loop(noise: RandomNumberGenerator) -> PackedFloat32Array:
	var loop := PackedFloat32Array()
	loop.resize(_BREATH_LOOP)
	var low := 0.0
	var band := 0.0
	# Run the filters twice round so the loop starts settled.
	for _round: int in 2:
		for index: int in _BREATH_LOOP:
			low += 0.35 * (noise.randf_range(-1.0, 1.0) - low)
			band += 0.08 * (low - band)
			loop[index] = low - band
	return loop


static func _buffer(seconds: float, rate: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(maxi(int(seconds * float(rate)), 1))
	return samples
