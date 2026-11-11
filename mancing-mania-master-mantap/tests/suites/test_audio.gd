extends "res://tests/test_suite.gd"
## Procedural audio foundation (GDD 175.2, 175.4, 175.7, 175.17): every declared
## sound synthesizes cleanly, the bus layout exists and volumes follow settings.


func get_suite_name() -> String:
	return "audio"


func before_all() -> void:
	AudioManager.initialize_procedural_audio()


func after_all() -> void:
	for key: String in SaveSchema.VOLUME_KEYS:
		GameState.set_setting(StringName(key), SaveSchema.default_settings()[key])


func test_critical_sfx_render_cleanly() -> bool:
	var mix_rate := AudioManager.get_mix_rate()
	for sfx_id: StringName in AudioManager.CRITICAL_SFX_IDS:
		var preset := AudioManager.get_preset(sfx_id)
		if not check(preset != null, "%s preset exists" % sfx_id):
			continue
		check_eq(preset.id, sfx_id, "%s preset id matches its file" % sfx_id)
		var samples := SfxRenderer.render(preset, mix_rate)
		check(not samples.is_empty(), "%s renders samples" % sfx_id)
		check(not SynthDsp.has_invalid_samples(samples), "%s has no NaN/Inf" % sfx_id)
		var peak := SynthDsp.peak(samples)
		check(peak <= 1.0, "%s peak %.3f stays within full scale" % [sfx_id, peak])
		check(peak >= 0.05, "%s peak %.3f is audible" % [sfx_id, peak])
		var duration := float(samples.size()) / float(mix_rate)
		check(duration > 0.02 and duration < 0.5, "%s lasts %.3f s (a short click)" % [sfx_id, duration])
		check(absf(samples[0]) < 0.01 and absf(samples[samples.size() - 1]) < 0.01, "%s starts and ends near silence" % sfx_id)
	return true


func test_fixed_presets_render_identically() -> bool:
	var preset := AudioManager.get_preset(&"ui_click")
	var first := SfxRenderer.render(preset, 48000)
	var second := SfxRenderer.render(preset, 48000, 12345)
	check_eq(first, second, "a fixed preset ignores the per-play seed")
	check(SfxRenderer.render(AudioManager.get_preset(&"ui_back"), 48000) != first, "different presets sound different")
	return true


func test_stream_conversion() -> bool:
	var samples := SfxRenderer.render(AudioManager.get_preset(&"ui_click"), 48000)
	var stream := SfxRenderer.to_stream(samples, 48000)
	check_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, "16-bit PCM")
	check_eq(stream.mix_rate, 48000, "mix rate")
	check_eq(stream.stereo, false, "mono")
	check_eq(stream.data.size(), samples.size() * 2, "two bytes per sample")

	var cached := AudioManager.get_sfx_stream(&"ui_click")
	check(cached != null, "manager returns a stream")
	check(AudioManager.get_sfx_stream(&"ui_click") == cached, "critical sounds are cached, not re-rendered")
	return true


func test_invalid_presets_fail_safely() -> bool:
	check(SfxRenderer.render(null, 48000).is_empty(), "null preset renders nothing")
	var unknown := AudioPreset.new()
	unknown.id = &"mystery"
	unknown.synth_type = &"theremin"
	check(SfxRenderer.render(unknown, 48000).is_empty(), "unsupported synth type renders nothing")
	check(AudioManager.get_sfx_stream(&"sfx_that_does_not_exist") == null, "missing preset returns null")
	AudioManager.play_ui(&"sfx_that_does_not_exist")
	AudioManager.play_sfx(&"sfx_that_does_not_exist")
	return true


func test_bus_layout() -> bool:
	check_eq(AudioServer.get_bus_name(0), "Master", "bus 0 is Master")
	for bus_id: StringName in AudioManager.CHILD_BUSES:
		var index := AudioServer.get_bus_index(bus_id)
		if check(index > 0, "%s bus exists" % bus_id):
			check_eq(AudioServer.get_bus_send(index), &"Master", "%s sends to Master" % bus_id)
	return true


func test_bus_volume_follows_settings() -> bool:
	var music := AudioServer.get_bus_index(&"Music")
	AudioManager.set_bus_volume(&"Music", 0.5)
	check_near(AudioServer.get_bus_volume_db(music), linear_to_db(0.5), 0.01, "half volume in dB")
	check(not AudioServer.is_bus_mute(music), "audible bus is not muted")
	AudioManager.set_bus_volume(&"Music", 0.0)
	check(AudioServer.is_bus_mute(music), "zero volume mutes the bus")
	AudioManager.set_bus_volume(&"Music", 5.0)
	check_near(AudioServer.get_bus_volume_db(music), 0.0, 0.01, "volume clamps at 100%")

	GameState.set_setting(&"music_volume", 0.2)
	check_near(AudioServer.get_bus_volume_db(music), linear_to_db(0.2), 0.01, "setting change reaches the bus")
	GameState.set_setting(&"ui_volume", 0.6)
	check_near(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"UI")), linear_to_db(0.6), 0.01, "UI bus follows its setting")
	return true


func test_state_surface() -> bool:
	check(AudioManager.is_audio_ready(), "audio is ready outside the browser")
	var states: Array[StringName] = []
	var on_state := func(state_id: StringName) -> void: states.append(state_id)
	AudioManager.music_state_changed.connect(on_state)
	AudioManager.set_music_state(&"test_state_a")
	AudioManager.set_music_state(&"test_state_a")
	AudioManager.stop_music()
	AudioManager.music_state_changed.disconnect(on_state)
	check_eq(states, [&"test_state_a", &"silence"], "state changes are signalled once each")
	check_eq(AudioManager.get_authoritative_song_time_sec(), 0.0, "no song clock while nothing plays")

	AudioManager.apply_rhythm_calibration(900)
	check_eq(AudioManager.get_rhythm_calibration_ms(), 150, "calibration clamps to the schema limit")
	AudioManager.apply_rhythm_calibration(0)

	AudioManager.set_paused(true)
	check(AudioManager.is_paused(), "pause flag set")
	AudioManager.play_ui(&"ui_click")
	AudioManager.set_paused(false)
	check(not AudioManager.is_paused(), "pause flag cleared")
	return true
