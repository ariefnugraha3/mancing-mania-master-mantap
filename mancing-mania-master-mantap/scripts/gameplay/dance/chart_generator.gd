class_name ChartGenerator
extends Node
## Builds the Dance chart and its koplo track from one seed (GDD 58, 175.10).
##
## The chart is read off the music's own timeline: notes sit on kendang, snare
## and melody hits, so every note is something you can hear. The seed is the
## duel seed (save seed + duel counter) mixed with the fish id, so the same
## duel always reproduces the same track and chart (DANCE-003).

const LANES := 4
## Notes per second at the start and the end of the song; it gets busier.
const DENSITY_START := 1.3
const DENSITY_END := 2.4
const ENCORE_NOTES := 4


## Everything the duel needs: tempo, length, the music schedule and the notes.
static func generate(fish_id: StringName, duel_seed: int) -> Dictionary:
	var config := GameData.get_dance_config()
	var seed := chart_seed(fish_id, duel_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var bpm := float(rng.randi_range(config.bpm_min, config.bpm_max))
	var beat := 60.0 / bpm
	var bar_sec := beat * 4.0
	var min_bars := ceili(config.duration_min_sec / bar_sec)
	var max_bars := floori(config.duration_max_sec / bar_sec)
	var bars := rng.randi_range(min_bars, maxi(max_bars, min_bars))
	var duration := float(bars) * bar_sec
	# Two spare bars carry the encore when the duel ends level (GDD 63).
	var schedule := MusicSequencer.build_koplo(seed, bpm, bars, 2)

	var notes: Array = []
	var last_time := -1.0
	var lane_run := 0
	var last_lane := -1
	var first := bar_sec
	var last := duration - beat
	for event: Dictionary in schedule["events"]:
		var hint: int = event["lane_hint"]
		var t: float = event["t"]
		if hint < 0 or t < first - 0.0001 or t > last + 0.0001:
			continue
		# Never closer than an eighth note, so every note can be hit.
		if last_time >= 0.0 and t - last_time < beat * 0.5 - 0.0001:
			continue
		var progress := (t - first) / maxf(last - first, 0.001)
		var density := lerpf(DENSITY_START, DENSITY_END, progress)
		# Candidates come at roughly three per beat; keep the share that
		# gives the wanted density. Snares on 2 and 4 are anchors.
		var keep := density * beat / 2.2
		if hint != MusicSequencer.LANE_SNARE and rng.randf() > keep:
			continue
		var lane := hint
		# Break up long runs in one lane by stepping to a neighbour.
		if lane == last_lane:
			lane_run += 1
			if lane_run >= 2:
				lane = clampi(lane + (1 if rng.randf() < 0.5 else -1), 0, LANES - 1)
				lane_run = 0
		else:
			lane_run = 0
		last_lane = lane
		notes.append({"time": t, "lane": lane})
		last_time = t

	var encore: Array = []
	for index: int in ENCORE_NOTES:
		encore.append({"time": duration + bar_sec * 0.5 + float(index) * beat, "lane": rng.randi() % LANES})

	return {
		"seed": seed, "bpm": bpm, "beat_sec": beat, "bars": bars, "duration_sec": duration,
		"schedule": schedule, "notes": notes, "encore": encore,
	}


static func chart_seed(fish_id: StringName, duel_seed: int) -> int:
	return int((duel_seed ^ SynthDsp.stable_hash(String(fish_id))) & 0x7FFFFFFF)
