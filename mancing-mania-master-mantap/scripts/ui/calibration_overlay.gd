class_name CalibrationOverlay
extends OverlayPanel
## Rhythm calibration wizard (GDD 189.10): a steady click track plays, the
## player taps along, the first two taps are warm-up, and the median timing
## error becomes the suggested input offset, clamped to +/-150 ms. The player
## accepts it, resets it, or adjusts by hand in Settings.

signal finished()

const BPM := 100.0
const BEATS := 16
const WARM_UP_TAPS := 2
const MIN_TAPS := 8

var _status: Label
var _result: Label
var _accept: GameButton
var _retry: GameButton
var _close: GameButton
var _beat_times: Array[float] = []
var _taps: Array[float] = []
var _suggested: int = 0
var _running: bool = false
var _music: MusicEngine


func build_content() -> void:
	layer = 55
	panel_width = 480.0
	set_title(TextDb.t(&"calibration.title"))
	content.add_child(make_label(TextDb.t(&"calibration.body")))
	_status = make_label("", UiTokens.TYPE_HEADER)
	content.add_child(_status)
	_result = make_label("", UiTokens.TYPE_SMALL)
	content.add_child(_result)
	footer.vertical = true
	_accept = make_button(TextDb.t(&"calibration.accept"), UiTokens.TYPE_CTA_BUTTON)
	_accept.pressed.connect(_on_accept)
	footer.add_child(_accept)
	_retry = make_button(TextDb.t(&"calibration.retry"))
	_retry.pressed.connect(start)
	footer.add_child(_retry)
	_close = make_button(TextDb.t(&"common.close"))
	_close.click_sfx = &"ui_back"
	_close.pressed.connect(_on_close)
	footer.add_child(_close)


func open() -> void:
	show_overlay()
	start()


func start() -> void:
	_music = AudioManager.get_music_engine()
	var track := MusicSequencer.build_click_track(BPM, BEATS)
	_beat_times.clear()
	for event: Dictionary in track["events"]:
		_beat_times.append(float(event["t"]))
	_taps.clear()
	_suggested = 0
	_running = true
	_accept.disabled = true
	_result.text = ""
	_status.text = TextDb.t(&"calibration.preparing")
	_music.prepare_song(track)


func _process(_delta: float) -> void:
	if not visible or not _running:
		return
	if not _music.is_song_playing():
		if _music.is_song_ready() and _taps.is_empty() and _music.get_song_time() == 0.0:
			_music.play_song(0.0)
			_status.text = TextDb.t(&"calibration.tap")
		elif _music.is_song_ready() and _music.get_song_time() > 0.0:
			_finish()
		return
	_status.text = TextDb.tf(&"calibration.count", {"count": _taps.size(), "total": BEATS})


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not visible or not _running or not _music.is_song_playing():
		return
	var tapped: bool = InputActions.is_primary_press(event) or (event is InputEventKey and event.pressed and not event.is_echo())
	if tapped and not event.is_action_pressed(InputActions.UI_CANCEL):
		_taps.append(_music.get_song_time())
		get_viewport().set_input_as_handled()


## The median error of the taps against their nearest beats, in ms, after the
## warm-up taps, clamped to the allowed offset range. Positive means late.
static func suggest_offset_ms(taps: Array[float], beats: Array[float]) -> int:
	var errors: Array[float] = []
	for index: int in range(WARM_UP_TAPS, taps.size()):
		var nearest := INF
		for beat: float in beats:
			if absf(taps[index] - beat) < absf(nearest):
				nearest = taps[index] - beat
		errors.append(nearest)
	if errors.is_empty():
		return 0
	errors.sort()
	var middle := errors.size() / 2
	var median := errors[middle] if errors.size() % 2 == 1 else (errors[middle - 1] + errors[middle]) * 0.5
	return clampi(roundi(median * 1000.0), -SaveSchema.RHYTHM_OFFSET_LIMIT_MS, SaveSchema.RHYTHM_OFFSET_LIMIT_MS)


func _finish() -> void:
	_running = false
	_music.stop_song()
	if _taps.size() < MIN_TAPS:
		_status.text = TextDb.t(&"calibration.too_few")
		return
	_suggested = suggest_offset_ms(_taps, _beat_times)
	_status.text = TextDb.tf(&"calibration.result", {"ms": _suggested})
	_result.text = TextDb.t(&"calibration.result_body")
	_accept.disabled = false
	focus_later(_accept)


func _on_accept() -> void:
	GameState.set_setting(&"rhythm_input_offset_ms", _suggested)
	_on_close()


func _on_close() -> void:
	_running = false
	if _music != null:
		_music.stop_song()
	hide_overlay()
	finished.emit()


func on_cancel() -> void:
	_on_close()
