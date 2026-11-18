class_name MusicRenderer
extends RefCounted
## Turns a MusicSequencer schedule into an in-memory AudioStreamWAV.
##
## Each distinct note is synthesized once and cached; the schedule is then
## mixed note by note. All the work, including the final normalize and
## 16-bit encode, is cut into small chunks that stop at a time budget, so a
## whole track can be prepared while the game runs without a hitch (GDD
## 175.15: no synthesis allocation per sample frame at play time). The
## renderer touches no scene, so MusicEngine may also run it on a worker
## thread; the stream itself is made on the caller's thread.

## Music has no detail above 11 kHz worth the cost on Web and Android.
const RATE := 22050
const PEAK_TARGET := 0.85
## Notes may ring this long past the end of a piece unless the schedule
## says otherwise ("tail_sec"). A loop folds the tail back onto its start; a
## piece that plays once keeps it.
const TAIL_SEC := 2.0
## Samples handled between two looks at the clock.
const CHUNK := 4096

enum Phase { MIX, WRAP, PEAK, ENCODE, DONE }

var _schedule: Dictionary = {}
var _samples := PackedFloat32Array()
var _bytes := PackedByteArray()
var _cache: Dictionary = {}
var _phase: Phase = Phase.DONE
var _next_event: int = 0
## How far into the current note the mix has got.
var _note_offset: int = 0
var _cursor: int = 0
var _peak: float = 0.0
var _gain: float = 1.0
var _cancelled: bool = false
var _stream: AudioStreamWAV


func start(schedule: Dictionary) -> void:
	_schedule = schedule
	_samples = PackedFloat32Array()
	var tail: float = schedule.get("tail_sec", TAIL_SEC)
	_samples.resize(maxi(int(float(schedule["length_sec"]) * RATE) + int(tail * RATE), 1))
	_bytes = PackedByteArray()
	_cache.clear()
	_phase = Phase.MIX
	_next_event = 0
	_note_offset = 0
	_cursor = 0
	_peak = 0.0
	_gain = 1.0
	_cancelled = false
	_stream = null


## Works until `budget_msec` is used up. Returns true when finished.
func step(budget_msec: int) -> bool:
	var deadline := Time.get_ticks_msec() + maxi(budget_msec, 1)
	while _phase != Phase.DONE:
		if _cancelled:
			_phase = Phase.DONE
			break
		_advance()
		if Time.get_ticks_msec() >= deadline:
			break
	return _phase == Phase.DONE


## Renders everything at once (tests, tools).
func render_all() -> AudioStreamWAV:
	run()
	return get_stream()


## Renders all the samples without making the stream: the body of a worker
## thread task. Call get_stream() afterwards on the main thread.
func run() -> void:
	while not step(1000):
		pass


## Asks a render in progress to stop at its next chunk.
func cancel() -> void:
	_cancelled = true


func is_done() -> bool:
	return _phase == Phase.DONE


func is_cancelled() -> bool:
	return _cancelled


func get_progress() -> float:
	if _phase == Phase.DONE:
		return 1.0
	var count: int = (_schedule.get("events", []) as Array).size()
	var mixed := 1.0 if count == 0 else float(_next_event) / float(count)
	return mixed * 0.9 if _phase == Phase.MIX else 0.9 + 0.1 * float(_cursor) / float(maxi(_samples.size(), 1))


## The finished stream, made on first call (on the caller's thread).
func get_stream() -> AudioStreamWAV:
	if _stream == null and _phase == Phase.DONE and not _cancelled:
		_stream = SfxRenderer.make_stream(_bytes, RATE, _samples.size(), _schedule.get("loop", false))
		_bytes = PackedByteArray()
	return _stream


func get_samples() -> PackedFloat32Array:
	return _samples


func get_schedule() -> Dictionary:
	return _schedule


## One chunk of the current phase.
func _advance() -> void:
	match _phase:
		Phase.MIX:
			_mix_chunk()
		Phase.WRAP:
			_wrap_chunk()
		Phase.PEAK:
			_peak_chunk()
		Phase.ENCODE:
			_encode_chunk()


func _mix_chunk() -> void:
	var events: Array = _schedule["events"]
	if _next_event >= events.size():
		_cache.clear()
		_cursor = 0
		_phase = Phase.WRAP if _schedule.get("loop", false) else Phase.PEAK
		return
	var event: Dictionary = events[_next_event]
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
	var stop := mini(_note_offset + CHUNK, count)
	for index: int in range(_note_offset, stop):
		_samples[start + index] += note[index] * gain
	if stop >= count:
		_next_event += 1
		_note_offset = 0
	else:
		_note_offset = stop


## Notes that ring past the loop point continue at its start, so the loop
## is seamless.
func _wrap_chunk() -> void:
	var loop_end := maxi(int(float(_schedule["length_sec"]) * RATE), 1)
	var from := loop_end + _cursor
	var stop := mini(from + CHUNK, _samples.size())
	for index: int in range(from, stop):
		_samples[index - loop_end] += _samples[index]
	_cursor = stop - loop_end
	if stop >= _samples.size():
		_samples.resize(loop_end)
		_cursor = 0
		_phase = Phase.PEAK


func _peak_chunk() -> void:
	var stop := mini(_cursor + CHUNK, _samples.size())
	var peak := _peak
	for index: int in range(_cursor, stop):
		peak = maxf(peak, absf(_samples[index]))
	_peak = peak
	_cursor = stop
	if stop >= _samples.size():
		_gain = PEAK_TARGET / _peak if _peak > PEAK_TARGET else 1.0
		_bytes.resize((_samples.size() + SfxRenderer.TAIL_PAD) * 2)
		_cursor = 0
		_phase = Phase.ENCODE


## Normalizes, soft-clips and writes 16-bit samples, then the tail pad that
## keeps Android's mixer inside the buffer (SfxRenderer.TAIL_PAD).
func _encode_chunk() -> void:
	var stop := mini(_cursor + CHUNK, _samples.size())
	for index: int in range(_cursor, stop):
		var value := SynthDsp.soft_clip(_samples[index] * _gain)
		_samples[index] = value
		_bytes.encode_s16(index * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	_cursor = stop
	if stop >= _samples.size():
		SfxRenderer.write_tail_pad(_bytes, _samples.size(), _schedule.get("loop", false))
		_phase = Phase.DONE
