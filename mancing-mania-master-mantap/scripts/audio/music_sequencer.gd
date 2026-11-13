class_name MusicSequencer
extends RefCounted
## Builds the note schedules of the procedural music (GDD 175.10, 175.11).
##
## A schedule is a plain dictionary:
##   {bpm, beat_sec, bars, length_sec, loop, events: [{t, voice, hz, len, gain, lane_hint}]}
## Times are in seconds from the start of the schedule. Everything is decided
## from the seed before a note is heard, so the same seed always gives the
## same music, and the Dance chart can be read off the same timeline.

const STYLE_KOPLO := &"koplo"
const STYLE_FISHING := &"fishing"
const STYLE_BOXING := &"boxing"
const STYLE_ARM := &"arm_wrestle"
const STYLE_CLICK := &"click"

## A minor pentatonic scale over two octaves, as MIDI offsets from the key.
const PENTATONIC: Array[int] = [0, 3, 5, 7, 10, 12, 15, 17, 19, 22]
## i - iv - VII - v, as semitones from the key; one chord per bar.
const PROGRESSION: Array[int] = [0, 5, 10, 7]
## Kendang patterns on a 16-step bar: 1 = low "dhut", 2 = high "tak".
const KENDANG_PATTERNS: Array = [
	[0, 0, 2, 0, 0, 1, 0, 2, 0, 0, 2, 0, 0, 1, 2, 0],
	[0, 0, 2, 2, 0, 1, 0, 0, 0, 2, 0, 2, 0, 1, 0, 2],
	[0, 2, 0, 0, 1, 0, 2, 0, 0, 2, 0, 0, 1, 0, 2, 2],
	[0, 0, 2, 0, 1, 0, 0, 2, 0, 0, 2, 0, 1, 0, 2, 0],
]
## Lane hints for the Dance chart: which kind of event suggests which lane.
const LANE_KENDANG_LOW := 0
const LANE_KENDANG_HIGH := 1
const LANE_SNARE := 2
const LANE_MELODY := 3


## The Dance track (GDD 58, 175.10): `bars` bars of 4/4 at `bpm`, a one-bar
## count-in of clicks, then kick, snare, hats, kendang, bass, a pluck melody
## and a chord pad. `extra_bars` are appended for a possible encore.
static func build_koplo(seed: int, bpm: float, bars: int, extra_bars: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var beat := 60.0 / bpm
	var step := beat / 4.0
	var key := 45 + rng.randi_range(0, 7)
	var events: Array = []
	var total_bars := bars + extra_bars

	# Count-in: four clicks, the first one higher.
	for count: int in 4:
		events.append(_event(float(count) * beat, MusicVoices.CLICK, 1760.0 if count == 0 else 1320.0, 0.05, 0.6))

	# A two-bar melody motif, repeated with small changes.
	var motif: Array = []
	var degree := rng.randi_range(2, 5)
	for slot: int in 16:
		if rng.randf() < 0.45:
			motif.append(-1)
			continue
		degree = clampi(degree + rng.randi_range(-2, 2), 0, PENTATONIC.size() - 1)
		motif.append(degree)

	for bar: int in range(1, total_bars):
		var bar_start := float(bar) * beat * 4.0
		var chord := PROGRESSION[(bar - 1) % PROGRESSION.size()]
		var pattern: Array = KENDANG_PATTERNS[rng.randi() % KENDANG_PATTERNS.size()]
		var fill := (bar % 8) == 0
		for s: int in 16:
			var t := bar_start + float(s) * step
			if s % 4 == 0:
				events.append(_event(t, MusicVoices.KICK, 0.0, 0.25, 0.9))
				events.append(_event(t + step * 2.0, MusicVoices.HAT_CLOSED, 0.0, 0.05, 0.55))
			if s == 4 or s == 12:
				events.append(_event(t, MusicVoices.SNARE, 0.0, 0.2, 0.7, LANE_SNARE))
			if s == 14:
				events.append(_event(t, MusicVoices.HAT_OPEN, 0.0, 0.2, 0.4))
			var hit: int = pattern[s]
			if fill and s >= 8:
				hit = 2 if s % 2 == 0 else 1
			if hit == 1:
				events.append(_event(t, MusicVoices.KENDANG_LOW, 92.0, 0.3, 0.8, LANE_KENDANG_LOW))
			elif hit == 2:
				events.append(_event(t, MusicVoices.KENDANG_HIGH, 330.0, 0.12, 0.6, LANE_KENDANG_HIGH))
			# Bass on every eighth: root, with an octave jump on the off-beat.
			if s % 2 == 0:
				var bass_note := key - 12 + chord + (12 if s % 4 == 2 else 0)
				events.append(_event(t, MusicVoices.BASS, MusicVoices.midi_hz(bass_note), step * 1.8, 0.55))
		# Melody: the motif on eighths over this bar's half of it.
		var half := (bar - 1) % 2
		for slot: int in 8:
			var note_degree: int = motif[half * 8 + slot]
			if note_degree < 0:
				continue
			var t := bar_start + float(slot) * step * 2.0
			var midi := key + 12 + PENTATONIC[note_degree] + (0 if bar % 4 != 0 else 2)
			events.append(_event(t, MusicVoices.PLUCK, MusicVoices.midi_hz(midi), step * 3.0, 0.5, LANE_MELODY))
		events.append(_event(bar_start, MusicVoices.PAD, MusicVoices.midi_hz(key + chord), beat * 4.0, 0.6))
		# The comedic accent ends every fourth bar.
		if bar % 4 == 0:
			events.append(_event(bar_start + beat * 3.5, MusicVoices.ACCENT, MusicVoices.midi_hz(key + 24), beat * 0.45, 0.5))

	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	return {
		"style": STYLE_KOPLO, "seed": seed, "bpm": bpm, "beat_sec": beat, "bars": bars,
		"length_sec": float(total_bars) * beat * 4.0, "loop": false, "events": events, "key": key,
	}


## A looping background for a game state (GDD 175.11; Section 115 tones):
## fishing is sparse plucks with long silences, boxing is retro arcade
## percussion, arm wrestling is a comedic heroic beat.
static func build_loop(style: StringName, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var events: Array = []
	var bpm := 0.0
	var bars := 0
	var key := 50 + rng.randi_range(0, 5)
	match style:
		STYLE_FISHING:
			bpm = 72.0
			bars = 12
			var beat := 60.0 / bpm
			for bar: int in bars:
				# Most bars are silent; a few hold a two or three note motif.
				if rng.randf() < 0.55:
					continue
				var degree := rng.randi_range(0, 5)
				for note: int in rng.randi_range(2, 3):
					var t := (float(bar) * 4.0 + float(note) * 1.5 + rng.randf_range(0.0, 0.3)) * beat
					degree = clampi(degree + rng.randi_range(-2, 2), 0, PENTATONIC.size() - 1)
					events.append(_event(t, MusicVoices.PLUCK, MusicVoices.midi_hz(key + 12 + PENTATONIC[degree]), 1.6, 0.35))
				if rng.randf() < 0.35:
					events.append(_event(float(bar) * 4.0 * beat, MusicVoices.PAD, MusicVoices.midi_hz(key), beat * 4.0, 0.35))
		STYLE_BOXING:
			bpm = 150.0
			bars = 8
			var beat := 60.0 / bpm
			var lead: Array[int] = []
			for slot: int in 8:
				lead.append(PENTATONIC[rng.randi_range(0, 6)])
			for bar: int in bars:
				for s: int in 8:
					var t := (float(bar) * 4.0 + float(s) * 0.5) * beat
					if s % 2 == 0:
						events.append(_event(t, MusicVoices.KICK, 0.0, 0.25, 0.8))
					else:
						events.append(_event(t, MusicVoices.HAT_CLOSED, 0.0, 0.05, 0.5))
					if s == 2 or s == 6:
						events.append(_event(t, MusicVoices.SNARE, 0.0, 0.2, 0.6))
					events.append(_event(t, MusicVoices.BASS, MusicVoices.midi_hz(key - 12 + (0 if bar % 4 < 2 else 5)), beat * 0.45, 0.45))
					if bar % 2 == 1 and s % 2 == 0:
						events.append(_event(t, MusicVoices.BLIP, MusicVoices.midi_hz(key + 24 + lead[s]), beat * 0.4, 0.4))
		STYLE_ARM:
			bpm = 112.0
			bars = 8
			var beat := 60.0 / bpm
			for bar: int in bars:
				var chord := [0, 5, 7, 0][bar % 4] as int
				for b: int in 4:
					var t := (float(bar) * 4.0 + float(b)) * beat
					events.append(_event(t, MusicVoices.KICK if b % 2 == 0 else MusicVoices.SNARE, 0.0, 0.22, 0.7))
					events.append(_event(t, MusicVoices.BASS, MusicVoices.midi_hz(key - 12 + chord), beat * 0.9, 0.5))
					events.append(_event(t + beat * 0.5, MusicVoices.HAT_CLOSED, 0.0, 0.05, 0.4))
				# A heroic fanfare figure: up a fifth, then the octave.
				if bar % 2 == 0:
					for n: int in 3:
						var interval := [0, 7, 12][n] as int
						events.append(_event((float(bar) * 4.0 + float(n) * 0.5) * beat, MusicVoices.BLIP,
							MusicVoices.midi_hz(key + 12 + chord + interval), beat * 0.45, 0.4))
				events.append(_event(float(bar) * 4.0 * beat, MusicVoices.PAD, MusicVoices.midi_hz(key + chord), beat * 4.0, 0.5))
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	return {
		"style": style, "seed": seed, "bpm": bpm, "beat_sec": 60.0 / maxf(bpm, 1.0), "bars": bars,
		"length_sec": float(bars) * 4.0 * 60.0 / maxf(bpm, 1.0), "loop": true, "events": events, "key": key,
	}


## A steady click track for rhythm calibration (GDD 189.10).
static func build_click_track(bpm: float, beats: int) -> Dictionary:
	var beat := 60.0 / bpm
	var events: Array = []
	for count: int in beats:
		events.append(_event(float(count) * beat, MusicVoices.CLICK, 1760.0 if count % 4 == 0 else 1320.0, 0.05, 0.8))
	return {
		"style": STYLE_CLICK, "seed": 0, "bpm": bpm, "beat_sec": beat, "bars": ceili(float(beats) / 4.0),
		"length_sec": float(beats) * beat + 0.5, "loop": false, "events": events, "key": 0,
	}


static func _event(t: float, voice: StringName, hz: float, length: float, gain: float, lane_hint: int = -1) -> Dictionary:
	return {"t": t, "voice": voice, "hz": hz, "len": length, "gain": gain, "lane_hint": lane_hint}
