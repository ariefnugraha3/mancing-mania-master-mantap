class_name RhythmClock
extends Node
## The one clock the Dance duel judges against (GDD 62, 175.10, 176.12).
##
## In the game it reads the song's playback position from the audio output,
## never the render frame time, so 30 and 60 FPS judge the same. Tests drive
## it by hand. Either way it never runs backwards.

const SOURCE_AUDIO := &"audio"
const SOURCE_MANUAL := &"manual"

var source: StringName = SOURCE_AUDIO

var _manual_time: float = 0.0
var _last: float = 0.0


func get_time() -> float:
	var time := _manual_time
	if source == SOURCE_AUDIO:
		time = AudioManager.get_authoritative_song_time_sec()
	_last = maxf(_last, time)
	return _last


## Manual source only: moves the clock forward.
func advance(seconds: float) -> void:
	_manual_time += maxf(seconds, 0.0)


## Manual source only: jumps to `seconds` (never backwards).
func set_time(seconds: float) -> void:
	_manual_time = maxf(_manual_time, seconds)


## Starts over at `seconds`, e.g. when a duel restarts after focus loss.
func reset(seconds: float = 0.0) -> void:
	_manual_time = seconds
	_last = seconds
