class_name MusicRenderer
extends RefCounted
## Turns a MusicSequencer schedule into an in-memory AudioStreamWAV.
##
## Each distinct note is synthesized once and cached; the schedule is then
## mixed note by note. The work is cut into small steps with a time budget,
## so a whole Dance track can be prepared during the "get ready" moment
## without a hitch (GDD 175.15: no synthesis allocation per sample frame at
## play time).

## Music has no detail above 11 kHz worth the cost on Web and Android.
const RATE := 22050
const PEAK_TARGET := 0.85

var _schedule: Dictionary = {}
var _samples := PackedFloat32Array()
var _cache: Dictionary = {}
var _next_event: int = 0
var _done: bool = false
var _stream: AudioStreamWAV


func start(schedule: Dictionary) -> void:
	_schedule = schedule
	_samples = PackedFloat32Array()
	_samples.resize(maxi(int(float(schedule["length_sec"]) * RATE) + RATE / 2, 1))
	_next_event = 0
	_done = false
	_stream = null


## Mixes notes until `budget_msec` is used up. Returns true when finished.
func step(budget_msec: int) -> bool:
	if _done:
		return true
	var deadline := Time.get_ticks_msec() + maxi(budget_msec, 1)
	var events: Array = _schedule["events"]
	while _next_event < events.size():
		_mix(events[_next_event])
		_next_event += 1
		if Time.get_ticks_msec() >= deadline:
			return false
	_finish()
	return true


## Renders everything at once (tests, tools).
func render_all() -> AudioStreamWAV:
	while not step(1000):
		pass
	return _stream


func is_done() -> bool:
	return _done


func get_progress() -> float:
	var count: int = (_schedule.get("events", []) as Array).size()
	return 1.0 if count == 0 else float(_next_event) / float(count)


func get_stream() -> AudioStreamWAV:
	return _stream


func get_samples() -> PackedFloat32Array:
	return _samples


func _mix(event: Dictionary) -> void:
	var key := "%s|%.2f|%.3f" % [event["voice"], event["hz"], event["len"]]
	var note: PackedFloat32Array
	if _cache.has(key):
		note = _cache[key]
	else:
		note = MusicVoices.render(event["voice"], event["hz"], event["len"], RATE)
		_cache[key] = note
	var start := int(float(event["t"]) * RATE)
	var gain: float = event["gain"]
	var count := mini(note.size(), _samples.size() - start)
	for index: int in count:
		_samples[start + index] += note[index] * gain


func _finish() -> void:
	var looping: bool = _schedule.get("loop", false)
	if looping:
		# Notes that ring past the loop point continue at its start, so the
		# loop is seamless.
		var loop_end := maxi(int(float(_schedule["length_sec"]) * RATE), 1)
		for index: int in range(loop_end, _samples.size()):
			_samples[index - loop_end] += _samples[index]
		_samples.resize(loop_end)
	var peak := SynthDsp.peak(_samples)
	var gain := PEAK_TARGET / peak if peak > PEAK_TARGET else 1.0
	for index: int in _samples.size():
		_samples[index] = SynthDsp.soft_clip(_samples[index] * gain)
	_stream = SfxRenderer.to_stream(_samples, RATE)
	if looping:
		_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_stream.loop_begin = 0
		_stream.loop_end = _samples.size()
	_done = true
	_cache.clear()
