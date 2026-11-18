class_name MusicSequencer
extends RefCounted
## Builds the note schedules of the procedural music (GDD 175.10, 175.11,
## revision 6.9).
##
## A schedule is a plain dictionary:
##   {style, seed, take, bpm, beat_sec, bars, length_sec, loop, rest_sec, key,
##    events: [{t, voice, hz, len, gain, lane_hint}]}
## Times are in seconds from the start of the schedule. Everything is decided
## from the seed before a note is heard, so the same seed always gives the
## same music, and the Dance chart can be read off the same timeline.
##
## Each game state has its own small piece in a warm "kampung band" palette
## (revision 6.9): a keroncong-pop title theme, calm acoustic takes for the
## water with silence between them, arcade boxing, a comic-heroic arm
## wrestle, a sneaky Suwit, pencak silat drums, a playful gamelan for the
## spinning tops, and the 17 August drum band for the village contests.
## Melodies are built from short motifs that repeat and answer each other,
## so they are easy to hum.

const STYLE_KOPLO := &"koplo"
const STYLE_MENU := &"menu"
const STYLE_FISHING := &"fishing"
const STYLE_BOXING := &"boxing"
const STYLE_ARM := &"arm_wrestle"
const STYLE_SUWIT := &"suwit"
const STYLE_SILAT := &"silat"
const STYLE_GAMELAN := &"gamelan"
const STYLE_LOMBA := &"lomba"
const STYLE_CLICK := &"click"
## Every state style build_piece() knows.
const PIECE_STYLES: Array[StringName] = [
	STYLE_MENU, STYLE_FISHING, STYLE_BOXING, STYLE_ARM, STYLE_SUWIT, STYLE_SILAT, STYLE_GAMELAN, STYLE_LOMBA,
]

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

## Five-note scales, as semitones above the key: major and minor
## pentatonic, and the pelog and slendro flavours of the gamelan pieces.
const MAJOR_PENT: Array[int] = [0, 2, 4, 7, 9]
const MINOR_PENT: Array[int] = [0, 3, 5, 7, 10]
const PELOG: Array[int] = [0, 1, 3, 7, 8]
const SLENDRO: Array[int] = [0, 2, 5, 7, 9]

## Rhythms of a two-bar phrase, in eighth notes: [start, length] pairs.
const PHRASE_RHYTHMS: Array = [
	[[0, 2], [2, 1], [3, 1], [4, 2], [6, 2], [8, 6]],
	[[0, 3], [3, 1], [4, 2], [6, 2], [8, 2], [10, 2], [12, 4]],
	[[1, 1], [2, 2], [4, 1], [5, 1], [6, 2], [8, 6]],
	[[0, 2], [2, 2], [4, 4], [8, 1], [9, 1], [10, 2], [12, 4]],
	[[0, 1], [1, 1], [2, 1], [3, 1], [4, 4], [10, 2], [12, 4]],
]
## Slower, roomier rhythms for the calm pieces.
const CALM_RHYTHMS: Array = [
	[[0, 4], [4, 2], [6, 2], [8, 8]],
	[[2, 2], [4, 4], [8, 6]],
	[[0, 3], [3, 1], [4, 4], [10, 6]],
]
## Steps a melody takes between notes (scale degrees), small ones most.
const MELODY_STEPS: Array[int] = [-2, -1, -1, 0, 1, 1, 2, -3, 3]
## Where a melody's home note sits (one octave above its base) and how far
## it may wander, in scale degrees.
const HOME_DEGREE := 5
const LOWEST_DEGREE := 3
const HIGHEST_DEGREE := 9
## The longest melody note; a held note fades before this anyway, and a
## shorter note is cheaper to render.
const MAX_NOTE_SEC := 1.6
## Pencak silat kendang on 16ths: 1 low "dhung", 2 high "tak", 0 rest.
const SILAT_KENDANG: Array = [
	[1, 0, 2, 2, 0, 1, 2, 0, 1, 0, 2, 0, 1, 2, 2, 0],
	[1, 0, 2, 0, 1, 1, 2, 0, 1, 0, 2, 2, 0, 1, 2, 2],
]

## The water: two takes that alternate, with this much quiet between them
## (GDD 175.11: silence is a valid music state).
const FISHING_TAKES := 2
const FISHING_REST_SEC := 30.0


## The Dance track (GDD 58, 175.10): `bars` bars of 4/4 at `bpm`, a one-bar
## count-in of clicks, then kick, snare, hats, kendang, bass, a pluck melody
## and a chord pad. `extra_bars` are appended for a possible encore.
## Revision 6.9 adds a suling doubling the melody, a kecrek (shaker),
## keyboard off-beats and a gong at each section. They take nothing from the
## seeded generator and carry no lane hint, so the chart is unchanged.
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
	var extras := _koplo_band(events, key, beat, total_bars)
	extras.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	return {
		"style": STYLE_KOPLO, "seed": seed, "take": 0, "bpm": bpm, "beat_sec": beat, "bars": bars,
		"length_sec": float(total_bars) * beat * 4.0, "loop": false, "rest_sec": 0.0, "tail_sec": 0.5,
		"events": _merge_by_time(events, extras), "key": key,
	}


## The rest of the koplo band, read off the finished main schedule: a
## suling doubles each melody note, a kecrek plays eighths, the keyboard
## answers on the off-beats and a gong opens every eight bars.
static func _koplo_band(main: Array, key: int, beat: float, total_bars: int) -> Array:
	var extras: Array = []
	for event: Dictionary in main:
		if event["voice"] == MusicVoices.PLUCK:
			extras.append(_event(event["t"], MusicVoices.SULING, event["hz"], event["len"], 0.3))
	for bar: int in range(1, total_bars):
		var bar_start := float(bar) * beat * 4.0
		var chord := PROGRESSION[(bar - 1) % PROGRESSION.size()]
		for s: int in 8:
			extras.append(_event(bar_start + float(s) * beat * 0.5, MusicVoices.SHAKER, 0.0, 0.11, 0.2 if s % 2 == 1 else 0.11))
		# The flat seventh (10) is the one major chord of i - iv - VII - v.
		var third := 4 if chord == 10 else 3
		for b: int in [1, 3]:
			for tone: int in [0, third, 7]:
				extras.append(_event(bar_start + (float(b) + 0.5) * beat, MusicVoices.KEYS, MusicVoices.midi_hz(key + 12 + chord + tone), beat * 0.3, 0.13))
		if bar % 8 == 1 and bar < total_bars - 2:
			extras.append(_event(bar_start, MusicVoices.GONG, 68.0, 2.4, 0.4))
	return extras


## A looping piece for a game state; kept for callers that know one take.
static func build_loop(style: StringName, seed: int) -> Dictionary:
	return build_piece(style, seed, 0)


## How many different takes a style has (the water alternates two).
static func takes(style: StringName) -> int:
	return FISHING_TAKES if style == STYLE_FISHING else 1


## One take of a state piece (revision 6.9). Most styles loop seamlessly;
## the water's takes play once and are followed by `rest_sec` of quiet.
static func build_piece(style: StringName, seed: int, take: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed + take * 7919
	var events: Array = []
	var shape: Dictionary = {}
	match style:
		STYLE_MENU:
			shape = _build_menu(rng, events)
		STYLE_FISHING:
			shape = _build_fishing(rng, events, take)
		STYLE_BOXING:
			shape = _build_boxing(rng, events)
		STYLE_ARM:
			shape = _build_arm(rng, events)
		STYLE_SUWIT:
			shape = _build_suwit(rng, events)
		STYLE_SILAT:
			shape = _build_silat(rng, events)
		STYLE_GAMELAN:
			shape = _build_gamelan(rng, events)
		STYLE_LOMBA:
			shape = _build_lomba(rng, events)
		_:
			shape = {"bpm": 120.0, "bars": 1, "key": 60, "loop": true, "rest_sec": 0.0}
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t"] < b["t"])
	var bpm: float = shape["bpm"]
	return {
		"style": style, "seed": seed, "take": take, "bpm": bpm, "beat_sec": 60.0 / bpm, "bars": shape["bars"],
		"length_sec": float(shape["bars"]) * 4.0 * 60.0 / bpm, "loop": shape["loop"],
		"rest_sec": shape["rest_sec"], "events": events, "key": shape["key"],
	}


## A steady click track for rhythm calibration (GDD 189.10).
static func build_click_track(bpm: float, beats: int) -> Dictionary:
	var beat := 60.0 / bpm
	var events: Array = []
	for count: int in beats:
		events.append(_event(float(count) * beat, MusicVoices.CLICK, 1760.0 if count % 4 == 0 else 1320.0, 0.05, 0.8))
	return {
		"style": STYLE_CLICK, "seed": 0, "take": 0, "bpm": bpm, "beat_sec": beat, "bars": ceili(float(beats) / 4.0),
		"length_sec": float(beats) * beat + 0.5, "loop": false, "rest_sec": 0.0, "tail_sec": 0.5, "events": events, "key": 0,
	}


# --- The state pieces -----------------------------------------------------------

## The title theme (Main Menu): a bright keroncong-pop tune. Guitar and bell
## intro, then a suling melody over guitar, ukulele cak-cuk, bass, kecrek
## and a light kendang; the keys answer in the middle, and a turnaround
## leads back to the top.
static func _build_menu(rng: RandomNumberGenerator, events: Array) -> Dictionary:
	var bpm := 104.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var key := 55
	# I I | I vi IV V I vi V I | IV V iii vi | ii V
	var chords: Array = [
		[0, false], [0, false],
		[0, false], [9, true], [5, false], [7, false], [0, false], [9, true], [7, false], [0, false],
		[5, false], [7, false], [4, true], [9, true],
		[2, true], [7, false],
	]
	var bars := chords.size()
	for bar: int in bars:
		var t := float(bar) * bar_sec
		var chord: Array = chords[bar]
		_guitar_arpeggio(events, t, beat, key, chord, 0.3)
		if bar >= 2:
			_cak_cuk(events, t, beat, key, chord, 0.2)
			_shaker_eighths(events, t, beat, 0.15)
			_light_kendang(events, t, beat, 0.4, bar == bars - 1)
		_walking_bass(events, t, beat, key, chord, chords[(bar + 1) % bars], 0.5)
	# Intro: a little bell motif over the guitar.
	_bell_motif(events, 0.0, beat, key + 24, [0, 4, 7, 4, 9, 7, 4, 2], 0.22)
	# A: the suling sings a phrase, its answer, a contrast and the phrase again.
	_melody_section(rng, events, bar_sec * 2.0, beat, key + 12, chords.slice(2, 10), MusicVoices.SULING, 0.5, PHRASE_RHYTHMS, MAJOR_PENT, true)
	# B: the keys answer.
	_melody_section(rng, events, bar_sec * 10.0, beat, key + 12, chords.slice(10, 14), MusicVoices.KEYS, 0.5, PHRASE_RHYTHMS, MAJOR_PENT, false)
	# Turnaround: bells walk up, a kendang fill and a cheeky accent.
	_bell_motif(events, bar_sec * 14.0, beat, key + 24, [2, 5, 9, 14, 11, 7, 5, 2], 0.2)
	events.append(_event(bar_sec * 15.0 + beat * 3.5, MusicVoices.ACCENT, MusicVoices.midi_hz(key + 31), beat * 0.4, 0.22))
	return {"bpm": bpm, "bars": bars, "key": key, "loop": true, "rest_sec": 0.0}


## A calm take for the water: fingerpicked guitar (or soft keys) with a
## short suling or bell melody that comes and goes. Long notes, no drums,
## and the engine leaves quiet between takes (GDD 175.11).
static func _build_fishing(rng: RandomNumberGenerator, events: Array, take: int) -> Dictionary:
	var bpm := 80.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var second := take % 2 == 1
	var key := 50 if second else 53
	var chords: Array
	if second:
		# IV I IV V | vi iii IV V | IV V I I
		chords = [[5, false], [0, false], [5, false], [7, false], [9, true], [4, true], [5, false], [7, false], [5, false], [7, false], [0, false], [0, false]]
	else:
		# I vi IV V | I iii IV I | vi IV V I
		chords = [[0, false], [9, true], [5, false], [7, false], [0, false], [4, true], [5, false], [0, false], [9, true], [5, false], [7, false], [0, false]]
	var bars := chords.size()
	for bar: int in bars:
		var t := float(bar) * bar_sec
		var chord: Array = chords[bar]
		if second:
			_keys_chord(events, t, beat, key, chord, 0.32)
			if bar % 2 == 1:
				_guitar_arpeggio(events, t + beat * 2.0, beat, key, chord, 0.2, true)
		else:
			_guitar_arpeggio(events, t, beat, key, chord, 0.28)
		if bar < bars - 1:
			events.append(_event(t, MusicVoices.PIZZ, MusicVoices.midi_hz(key - 12 + int(chord[0])), beat * 2.5, 0.42))
	if second:
		_melody_section(rng, events, bar_sec * 2.0, beat, key + 12, chords.slice(2, 6), MusicVoices.BELL, 0.3, CALM_RHYTHMS, MAJOR_PENT, false)
		_melody_section(rng, events, bar_sec * 8.0, beat, key + 12, chords.slice(8, 12), MusicVoices.SULING, 0.4, CALM_RHYTHMS, MAJOR_PENT, true)
	else:
		# The suling enters after four bars of guitar; bells close the take.
		_melody_section(rng, events, bar_sec * 4.0, beat, key + 12, chords.slice(4, 8), MusicVoices.SULING, 0.42, CALM_RHYTHMS, MAJOR_PENT, true)
		_bell_motif(events, bar_sec * 9.0, beat, key + 24, [4, 7, 9, 12], 0.18)
	# The last chord rings out softly.
	var last: Array = chords[bars - 1]
	events.append(_event(float(bars - 1) * bar_sec, MusicVoices.PIZZ, MusicVoices.midi_hz(key - 12 + int(last[0])), beat * 3.5, 0.4))
	events.append(_event(float(bars - 1) * bar_sec, MusicVoices.PAD_MAJOR, MusicVoices.midi_hz(key + int(last[0])), beat * 4.0, 0.38))
	return {"bpm": bpm, "bars": bars, "key": key, "loop": false, "rest_sec": FISHING_REST_SEC}


## Arcade boxing: a punchy kit, an octave-bouncing bass, a catchy two-bar
## chip riff that comes back after a bridge, brass hits and kendang fills.
static func _build_boxing(rng: RandomNumberGenerator, events: Array) -> Dictionary:
	var bpm := 150.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var key := 57
	# i VI VII v
	var roots: Array[int] = [0, 8, 10, 7]
	var riff_a := _riff(rng, 16)
	var riff_b := _riff(rng, 16)
	var bars := 16
	for bar: int in bars:
		var t0 := float(bar) * bar_sec
		var root := roots[bar % 4]
		for s: int in 8:
			var t := t0 + float(s) * beat * 0.5
			if s == 0 or s == 3 or s == 4:
				events.append(_event(t, MusicVoices.KICK, 0.0, 0.25, 0.85))
			if s == 2 or s == 6:
				events.append(_event(t, MusicVoices.SNARE, 0.0, 0.2, 0.62))
			events.append(_event(t, MusicVoices.HAT_CLOSED, 0.0, 0.05, 0.3 if s % 2 == 0 else 0.45))
			var bass_note := key - 12 + root + (12 if s % 2 == 1 else 0)
			events.append(_event(t, MusicVoices.BASS, MusicVoices.midi_hz(bass_note), beat * 0.45, 0.5))
		# The riff (A), a bridge (B) and the riff again.
		var bridge := bar >= 8 and bar < 12
		var riff: Array = riff_b if bridge else riff_a
		for note: Array in riff:
			var slot: int = note[0]
			if (slot >= 8) != (bar % 2 == 1):
				continue
			var t := t0 + float(slot % 8) * beat * 0.5
			var midi := key + 12 + _scale_step(note[1], MINOR_PENT)
			events.append(_event(t, MusicVoices.BLIP, MusicVoices.midi_hz(midi), beat * 0.45 * float(note[2]), 0.34))
		if bar % 4 == 0:
			events.append(_event(t0, MusicVoices.BRASS, MusicVoices.midi_hz(key + root), beat * 0.5, 0.45))
			events.append(_event(t0, MusicVoices.BRASS, MusicVoices.midi_hz(key + root + 7), beat * 0.5, 0.35))
		if bar == 0 or bar == 8:
			events.append(_event(t0, MusicVoices.CRASH, 0.0, 1.5, 0.4))
		if bar % 8 == 7:
			for s: int in 8:
				var high := s % 2 == 0
				events.append(_event(t0 + beat * 2.0 + float(s) * beat * 0.25, MusicVoices.KENDANG_HIGH if high else MusicVoices.KENDANG_LOW, 330.0 if high else 92.0, 0.15, 0.5))
	events.append(_event(float(bars) * bar_sec - beat * 0.5, MusicVoices.ACCENT, MusicVoices.midi_hz(key + 24), beat * 0.45, 0.3))
	return {"bpm": bpm, "bars": bars, "key": key, "loop": true, "rest_sec": 0.0}


## Arm wrestling: a comic-heroic march. Toms and snare rolls, a brass
## fanfare tune over a big major chord, and a cheeky accent at the turn.
static func _build_arm(rng: RandomNumberGenerator, events: Array) -> Dictionary:
	var bpm := 112.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var key := 50
	# I IV V I | I IV V V || IV I V I | IV V I V
	var chords: Array = [
		[0, false], [5, false], [7, false], [0, false], [0, false], [5, false], [7, false], [7, false],
		[5, false], [0, false], [7, false], [0, false], [5, false], [7, false], [0, false], [7, false],
	]
	var bars := chords.size()
	for bar: int in bars:
		var t0 := float(bar) * bar_sec
		var root := int(chords[bar][0])
		for b: int in 4:
			var t := t0 + float(b) * beat
			if b % 2 == 0:
				events.append(_event(t, MusicVoices.TOM, 78.0, 0.4, 0.75))
			else:
				events.append(_event(t, MusicVoices.SNARE, 0.0, 0.2, 0.5))
			events.append(_event(t, MusicVoices.BASS, MusicVoices.midi_hz(key - 12 + root + (7 if b % 2 == 1 else 0)), beat * 0.85, 0.5))
			events.append(_event(t + beat * 0.5, MusicVoices.HAT_CLOSED, 0.0, 0.05, 0.28))
		events.append(_event(t0, MusicVoices.PAD_MAJOR, MusicVoices.midi_hz(key + root), bar_sec, 0.42))
		if bar % 4 == 3:
			# A snare roll that swells into the next phrase.
			for s: int in 8:
				events.append(_event(t0 + beat * 2.0 + float(s) * beat * 0.25, MusicVoices.SNARE, 0.0, 0.2, 0.18 + 0.05 * float(s)))
		if bar == 0 or bar == 8:
			events.append(_event(t0, MusicVoices.CRASH, 0.0, 1.5, 0.38))
	_melody_section(rng, events, 0.0, beat, key + 12, chords.slice(0, 8), MusicVoices.BRASS, 0.55, PHRASE_RHYTHMS, MAJOR_PENT, false)
	_melody_section(rng, events, bar_sec * 8.0, beat, key + 12, chords.slice(8, 16), MusicVoices.BRASS, 0.55, PHRASE_RHYTHMS, MAJOR_PENT, false)
	events.append(_event(float(bars) * bar_sec - beat * 0.75, MusicVoices.ACCENT, MusicVoices.midi_hz(key + 24), beat * 0.6, 0.3))
	return {"bpm": bpm, "bars": bars, "key": key, "loop": true, "rest_sec": 0.0}


## Suwit: a suspense parody. A sneaky pizzicato walk, a tick-tock woodblock,
## minor keys stabs on the off-beats, a creeping keys figure and a bell
## that goes "ding".
static func _build_suwit(_rng: RandomNumberGenerator, events: Array) -> Dictionary:
	var bpm := 96.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var key := 50
	var walk: Array[int] = [0, -1, 3, -1, 5, -1, 6, 7, 0, -1, 3, -1, 5, 3, 2, 1]
	var bars := 8
	for bar: int in bars:
		var t0 := float(bar) * bar_sec
		var lift := 5 if bar % 4 == 2 else 0
		for s: int in 8:
			var step: int = walk[(bar % 2) * 8 + s]
			if step >= 0:
				events.append(_event(t0 + float(s) * beat * 0.5, MusicVoices.PIZZ, MusicVoices.midi_hz(key + step + lift), beat * 0.35, 0.55))
		for b: int in 4:
			events.append(_event(t0 + float(b) * beat, MusicVoices.WOODBLOCK, 900.0 if b % 2 == 0 else 680.0, 0.07, 0.38))
		for b: int in [1, 3]:
			for tone: int in [0, 3, 7]:
				events.append(_event(t0 + (float(b) + 0.5) * beat, MusicVoices.KEYS, MusicVoices.midi_hz(key + 12 + tone + lift), beat * 0.25, 0.15))
		if bar % 4 == 1:
			# A creeping figure on tiptoe: up a semitone and back.
			var creep: Array[int] = [7, 8, 7, 6, 7]
			for index: int in creep.size():
				events.append(_event(t0 + float(index) * beat * 0.5, MusicVoices.KEYS, MusicVoices.midi_hz(key + 24 + creep[index]), beat * 0.4, 0.2))
		if bar % 4 == 3:
			events.append(_event(t0 + beat * 3.0, MusicVoices.BELL, MusicVoices.midi_hz(key + 31), 1.4, 0.28))
	return {"bpm": bpm, "bars": bars, "key": key, "loop": true, "rest_sec": 0.0}


## Silat: pencak silat accompaniment. A busy kendang, a gong and kempul
## that mark the cycle, a bonang ostinato and the sompret's pelog melody.
static func _build_silat(rng: RandomNumberGenerator, events: Array) -> Dictionary:
	var bpm := 120.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var key := 62
	var bars := 8
	for bar: int in bars:
		var t0 := float(bar) * bar_sec
		var pattern: Array = SILAT_KENDANG[bar % 2]
		for s: int in 16:
			var t := t0 + float(s) * beat * 0.25
			var hit: int = pattern[s]
			if bar % 4 == 3 and s >= 12:
				hit = 2
			if hit == 1:
				events.append(_event(t, MusicVoices.KENDANG_LOW, 88.0, 0.3, 0.75))
			elif hit == 2:
				events.append(_event(t, MusicVoices.KENDANG_HIGH, 350.0, 0.12, 0.55))
		for s: int in 8:
			var tone := [0, 7, 3, 7][s % 4] as int
			events.append(_event(t0 + float(s) * beat * 0.5, MusicVoices.BELL, MusicVoices.midi_hz(key + tone), 0.5, 0.15))
		if bar % 4 == 0:
			events.append(_event(t0, MusicVoices.GONG, 65.0, 2.8, 0.65))
		elif bar % 2 == 0:
			events.append(_event(t0, MusicVoices.GONG, 138.0, 1.6, 0.4))
	var chords: Array = [[0, true], [0, true], [8, false], [7, false], [0, true], [0, true], [8, false], [7, false]]
	_melody_section(rng, events, 0.0, beat, key, chords, MusicVoices.SOMPRET, 0.42, PHRASE_RHYTHMS, PELOG, false)
	return {"bpm": bpm, "bars": bars, "key": key, "loop": true, "rest_sec": 0.0}


## Spinning Tops: a playful gamelan. Saron and peking interlock on a
## slendro line, the kendang dances lightly, a kenong rings each bar and the
## gong closes the cycle; a suling sings in the second half.
static func _build_gamelan(rng: RandomNumberGenerator, events: Array) -> Dictionary:
	var bpm := 104.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var key := 60
	var balungan: Array[int] = [2, 1, 2, 3, 2, 1, 0, 4, 3, 4, 3, 1, 2, 1, 0, 0]
	var bars := 8
	for bar: int in bars:
		var t0 := float(bar) * bar_sec
		for b: int in 4:
			var t := t0 + float(b) * beat
			var degree: int = balungan[(bar % 4) * 4 + b]
			events.append(_event(t, MusicVoices.BELL, MusicVoices.midi_hz(key + _scale_step(degree, SLENDRO)), 0.9, 0.32))
			for twice: int in 2:
				events.append(_event(t + (float(twice) * 0.5 + 0.25) * beat, MusicVoices.BELL, MusicVoices.midi_hz(key + 12 + _scale_step(degree, SLENDRO)), 0.4, 0.13))
		events.append(_event(t0, MusicVoices.KENDANG_LOW, 92.0, 0.3, 0.55))
		events.append(_event(t0 + beat * 1.5, MusicVoices.KENDANG_HIGH, 330.0, 0.12, 0.4))
		events.append(_event(t0 + beat * 2.5, MusicVoices.KENDANG_LOW, 92.0, 0.3, 0.4))
		events.append(_event(t0 + beat * 3.0, MusicVoices.KENDANG_HIGH, 330.0, 0.12, 0.45))
		events.append(_event(t0 + beat * 3.0, MusicVoices.BELL, MusicVoices.midi_hz(key - 12 + 7), 1.0, 0.2))
		if bar % 4 == 0:
			events.append(_event(t0, MusicVoices.GONG, 70.0, 2.8, 0.55))
	var chords: Array = [[0, false], [7, false], [9, true], [0, false]]
	_melody_section(rng, events, bar_sec * 4.0, beat, key, chords, MusicVoices.SULING, 0.36, CALM_RHYTHMS, SLENDRO, true)
	return {"bpm": bpm, "bars": bars, "key": key, "loop": true, "rest_sec": 0.0}


## Tug of War and Greased Pole: the 17 August drum band. A marching snare
## with rolls, the bass drum, a glockenspiel tune, brass hits and cymbals.
static func _build_lomba(rng: RandomNumberGenerator, events: Array) -> Dictionary:
	var bpm := 120.0
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var key := 53
	# I IV V I | I IV ii V || IV I V vi | IV V I V
	var chords: Array = [
		[0, false], [5, false], [7, false], [0, false], [0, false], [5, false], [2, true], [7, false],
		[5, false], [0, false], [7, false], [9, true], [5, false], [7, false], [0, false], [7, false],
	]
	var bars := chords.size()
	var march: Array[float] = [0.5, 0.0, 0.25, 0.0, 0.5, 0.0, 0.25, 0.25, 0.5, 0.0, 0.25, 0.0, 0.5, 0.25, 0.25, 0.25]
	for bar: int in bars:
		var t0 := float(bar) * bar_sec
		var root := int(chords[bar][0])
		for s: int in 16:
			var gain := march[s]
			if bar % 4 == 3 and s >= 8:
				gain = 0.2 + 0.04 * float(s - 8)
			if gain > 0.0:
				events.append(_event(t0 + float(s) * beat * 0.25, MusicVoices.SNARE, 0.0, 0.2, gain))
		for b: int in [0, 2]:
			events.append(_event(t0 + float(b) * beat, MusicVoices.TOM, 68.0, 0.4, 0.8))
		for b: int in 4:
			events.append(_event(t0 + float(b) * beat, MusicVoices.BASS, MusicVoices.midi_hz(key - 12 + root + (7 if b % 2 == 1 else 0)), beat * 0.8, 0.45))
		var third := 3 if chords[bar][1] else 4
		events.append(_event(t0, MusicVoices.BRASS, MusicVoices.midi_hz(key + root), beat * 0.6, 0.36))
		events.append(_event(t0, MusicVoices.BRASS, MusicVoices.midi_hz(key + root + third), beat * 0.6, 0.28))
		if bar % 8 == 0:
			events.append(_event(t0, MusicVoices.CRASH, 0.0, 1.5, 0.4))
	_melody_section(rng, events, 0.0, beat, key + 12, chords.slice(0, 8), MusicVoices.BELL, 0.42, PHRASE_RHYTHMS, MAJOR_PENT, false)
	_melody_section(rng, events, bar_sec * 8.0, beat, key + 12, chords.slice(8, 16), MusicVoices.BELL, 0.42, PHRASE_RHYTHMS, MAJOR_PENT, false)
	return {"bpm": bpm, "bars": bars, "key": key, "loop": true, "rest_sec": 0.0}


# --- Shared parts -----------------------------------------------------------------

## Semitones above the key of `degree` in a five-note `scale`, across octaves.
static func _scale_step(degree: int, scale: Array[int]) -> int:
	var size := scale.size()
	return scale[posmod(degree, size)] + 12 * floori(float(degree) / float(size))


## Pitch classes of a chord [root semitones, minor].
static func _chord_classes(chord: Array) -> Array[int]:
	var root := int(chord[0])
	return [posmod(root, 12), posmod(root + (3 if chord[1] else 4), 12), posmod(root + 7, 12)]


## The nearest degree to `degree` that is a chord tone (or `degree` itself).
static func _snap(degree: int, chord: Array, scale: Array[int]) -> int:
	var classes := _chord_classes(chord)
	for offset: int in [0, 1, -1, 2, -2]:
		var candidate: int = degree + offset
		if candidate < LOWEST_DEGREE - 1 or candidate > HIGHEST_DEGREE + 1:
			continue
		if classes.has(posmod(_scale_step(candidate, scale), 12)):
			return candidate
	return degree


## A melody over `chords` (one per bar) in two-bar phrases: a phrase that
## asks, an answer with the same rhythm and shape that comes home, a
## contrasting phrase, and the first phrase again. Notes on strong beats
## are chord tones. `echo` adds a soft dotted-eighth echo, which gives the
## dry synth a sense of space without a reverb.
static func _melody_section(rng: RandomNumberGenerator, events: Array, start: float, beat: float, base_midi: int,
		chords: Array, voice: StringName, gain: float, rhythms: Array, scale: Array[int], echo: bool) -> void:
	var eighth := beat * 0.5
	var first_index := rng.randi() % rhythms.size()
	var other_index := (first_index + 1 + rng.randi() % (rhythms.size() - 1)) % rhythms.size()
	var first_rhythm: Array = rhythms[first_index]
	var motif: Array[int] = []
	for _note: int in first_rhythm.size():
		motif.append(MELODY_STEPS[rng.randi() % MELODY_STEPS.size()])
	var phrases := ceili(float(chords.size()) / 2.0)
	for phrase: int in phrases:
		var contrast := phrase % 4 == 2
		var rhythm: Array = rhythms[other_index] if contrast else first_rhythm
		var degree := HOME_DEGREE + (2 if contrast else 0)
		var answer := phrase % 2 == 1 or phrase == phrases - 1
		for n: int in rhythm.size():
			var slot := int(rhythm[n][0])
			var length := int(rhythm[n][1])
			var bar := phrase * 2 + (1 if slot >= 8 else 0)
			if bar >= chords.size():
				break
			var chord: Array = chords[bar]
			if n > 0:
				var step := MELODY_STEPS[rng.randi() % MELODY_STEPS.size()] if contrast else motif[n]
				degree = clampi(degree + step, LOWEST_DEGREE, HIGHEST_DEGREE)
			if slot % 4 == 0:
				degree = _snap(degree, chord, scale)
			if n == rhythm.size() - 1:
				# An answer comes home; a question stops on another chord tone.
				degree = _snap(HOME_DEGREE, chord, scale) if answer else _snap(degree + 1 if degree == HOME_DEGREE else degree, chord, scale)
			var t := start + float(phrase * 16 + slot) * eighth
			var midi := base_midi + _scale_step(degree, scale)
			var length_sec := minf(float(length) * eighth * 0.92, MAX_NOTE_SEC)
			events.append(_event(t, voice, MusicVoices.midi_hz(midi), length_sec, gain))
			if echo and length >= 2:
				events.append(_event(t + eighth * 1.5, voice, MusicVoices.midi_hz(midi), minf(length_sec, eighth * 1.5), gain * 0.28))


## Fingerpicked nylon guitar over one bar (or half): bass, fifth, octave,
## third, and back down, below the melody's register.
static func _guitar_arpeggio(events: Array, start: float, beat: float, key: int, chord: Array, gain: float, half: bool = false) -> void:
	var root := key - 12 + int(chord[0])
	var third := 3 if chord[1] else 4
	var shape: Array[int] = [0, 7, 12, 12 + third, 19, 12 + third, 12, 7]
	for s: int in (4 if half else 8):
		events.append(_event(start + float(s) * beat * 0.5, MusicVoices.NYLON, MusicVoices.midi_hz(root + shape[s]), 1.2, gain * (1.0 if s == 0 else 0.75)))


## Ukulele "cak" on every off-beat and a lower "cuk" after 2 and 4, the
## lilt of keroncong.
static func _cak_cuk(events: Array, start: float, beat: float, key: int, chord: Array, gain: float) -> void:
	var voice := MusicVoices.STRUM_MINOR if chord[1] else MusicVoices.STRUM_MAJOR
	var root := MusicVoices.midi_hz(key + 12 + int(chord[0]))
	for b: int in 4:
		events.append(_event(start + (float(b) + 0.5) * beat, voice, root, 0.26, gain))
		if b % 2 == 1:
			events.append(_event(start + (float(b) + 0.25) * beat, voice, root * 0.5, 0.2, gain * 0.7))


## Soft electric piano: a chord on 1 and a lighter one on 3.
static func _keys_chord(events: Array, start: float, beat: float, key: int, chord: Array, gain: float) -> void:
	var root := key + int(chord[0])
	for tone: int in [0, 3 if chord[1] else 4, 7, 12]:
		var hz := MusicVoices.midi_hz(root + tone)
		events.append(_event(start, MusicVoices.KEYS, hz, beat * 1.8, gain * 0.55))
		events.append(_event(start + beat * 2.0, MusicVoices.KEYS, hz, beat * 1.8, gain * 0.38))


## Bass: root on 1, fifth on 3, and a chromatic step into the next chord.
static func _walking_bass(events: Array, start: float, beat: float, key: int, chord: Array, next: Array, gain: float) -> void:
	var root := key - 12 + int(chord[0])
	events.append(_event(start, MusicVoices.PIZZ, MusicVoices.midi_hz(root), beat * 1.6, gain))
	events.append(_event(start + beat * 2.0, MusicVoices.PIZZ, MusicVoices.midi_hz(root + 7), beat * 1.2, gain * 0.85))
	events.append(_event(start + beat * 3.5, MusicVoices.PIZZ, MusicVoices.midi_hz(key - 12 + int(next[0]) - 1), beat * 0.45, gain * 0.7))


## Kecrek (shaker) on every eighth, the off-beats a touch louder.
static func _shaker_eighths(events: Array, start: float, beat: float, gain: float) -> void:
	for s: int in 8:
		events.append(_event(start + float(s) * beat * 0.5, MusicVoices.SHAKER, 0.0, 0.11, gain * (1.0 if s % 2 == 1 else 0.6)))


## A light kendang under the title theme, with a fill at the turnaround.
static func _light_kendang(events: Array, start: float, beat: float, gain: float, fill: bool) -> void:
	events.append(_event(start, MusicVoices.KENDANG_LOW, 92.0, 0.3, gain))
	events.append(_event(start + beat * 1.0, MusicVoices.KENDANG_HIGH, 330.0, 0.12, gain * 0.6))
	events.append(_event(start + beat * 1.5, MusicVoices.KENDANG_LOW, 92.0, 0.3, gain * 0.7))
	if fill:
		for s: int in 4:
			var high := s % 2 == 0
			events.append(_event(start + beat * 3.0 + float(s) * beat * 0.25, MusicVoices.KENDANG_HIGH if high else MusicVoices.KENDANG_LOW, 330.0 if high else 92.0, 0.15, gain))
	else:
		events.append(_event(start + beat * 3.0, MusicVoices.KENDANG_HIGH, 330.0, 0.12, gain * 0.6))


## A few bell notes (semitones above `base_midi`) on eighths.
static func _bell_motif(events: Array, start: float, beat: float, base_midi: int, tones: Array, gain: float) -> void:
	for index: int in tones.size():
		events.append(_event(start + float(index) * beat * 0.5, MusicVoices.BELL, MusicVoices.midi_hz(base_midi + int(tones[index])), 1.2, gain))


## A riff over `slots` eighths: [slot, minor pentatonic degree, length in
## eighths] notes, mostly short, with a few gaps.
static func _riff(rng: RandomNumberGenerator, slots: int) -> Array:
	var notes: Array = []
	var degree := rng.randi_range(3, 5)
	var slot := 0
	while slot < slots:
		if slot > 0 and slot % 8 != 0 and rng.randf() < 0.18:
			slot += 1
			continue
		var length := 1 if rng.randf() < 0.7 else 2
		if slot % 8 + length > 8:
			length = 1
		degree = clampi(degree + MELODY_STEPS[rng.randi() % MELODY_STEPS.size()], 0, 7)
		notes.append([slot, degree, length])
		slot += length
	return notes


## Merges two time-sorted event lists. On equal times `main` goes first, so
## the order of the main events, which the Dance chart reads, never changes.
static func _merge_by_time(main: Array, extras: Array) -> Array:
	var merged: Array = []
	merged.resize(main.size() + extras.size())
	var a := 0
	var b := 0
	for index: int in merged.size():
		if b >= extras.size() or (a < main.size() and float(main[a]["t"]) <= float(extras[b]["t"])):
			merged[index] = main[a]
			a += 1
		else:
			merged[index] = extras[b]
			b += 1
	return merged


static func _event(t: float, voice: StringName, hz: float, length: float, gain: float, lane_hint: int = -1) -> Dictionary:
	return {"t": t, "voice": voice, "hz": hz, "len": length, "gain": gain, "lane_hint": lane_hint}
