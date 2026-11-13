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


# --- Fishing sounds and ambience (GDD 175.6, 175.13, 175.17) -----------------

func _rms(samples: PackedFloat32Array) -> float:
	var total := 0.0
	for sample: float in samples:
		total += sample * sample
	return sqrt(total / maxf(float(samples.size()), 1.0))


func test_fishing_sfx_render_cleanly() -> bool:
	var mix_rate := AudioManager.get_mix_rate()
	check_eq(AudioManager.FISHING_SFX_IDS.size(), 9, "nine fishing sounds (GDD 175.6)")
	for sfx_id: StringName in AudioManager.FISHING_SFX_IDS:
		var preset := AudioManager.get_preset(sfx_id)
		if not check(preset != null, "%s preset exists" % sfx_id):
			continue
		check_eq(preset.id, sfx_id, "%s preset id matches its file" % sfx_id)
		check(SfxRenderer.SUPPORTED_SYNTH_TYPES.has(preset.synth_type), "%s uses a supported synth type" % sfx_id)
		var samples := SfxRenderer.render(preset, mix_rate, 7)
		check(not samples.is_empty(), "%s renders samples" % sfx_id)
		check(not SynthDsp.has_invalid_samples(samples), "%s has no NaN/Inf" % sfx_id)
		var peak := SynthDsp.peak(samples)
		check(peak <= 1.0, "%s peak %.3f stays within full scale" % [sfx_id, peak])
		check(peak >= 0.03, "%s peak %.3f is audible" % [sfx_id, peak])
		var duration := float(samples.size()) / float(mix_rate)
		check(duration >= 0.02 and duration <= 1.0, "%s lasts %.3f s" % [sfx_id, duration])
		check(AudioManager.get_sfx_stream(sfx_id) != null, "%s is playable through the manager" % sfx_id)
	return true


func test_real_bite_is_unmistakable_from_a_nibble() -> bool:
	var mix_rate := AudioManager.get_mix_rate()
	var bite := SfxRenderer.render(AudioManager.get_preset(&"sfx_real_bite"), mix_rate)
	var nibble := SfxRenderer.render(AudioManager.get_preset(&"sfx_false_nibble"), mix_rate)
	check(_rms(bite) > _rms(nibble) * 2.5, "the bite is far louder than a nibble")
	check(bite.size() > nibble.size() * 2, "and clearly longer")
	check(AudioManager.get_preset(&"sfx_real_bite").pitch_hz < AudioManager.get_preset(&"sfx_false_nibble").pitch_hz * 0.3, "and much lower in pitch")
	return true


func test_varied_sounds_follow_their_seed() -> bool:
	var preset := AudioManager.get_preset(&"sfx_line_stress")
	check_eq(preset.seed_mode, &"varied", "line stress varies per play")
	var first := SfxRenderer.render(preset, 48000, 11)
	check_eq(SfxRenderer.render(preset, 48000, 11), first, "same seed, same creak")
	check(SfxRenderer.render(preset, 48000, 12) != first, "another seed, another creak")
	check(AudioManager.get_sfx_stream(&"sfx_line_stress", 11) != AudioManager.get_sfx_stream(&"sfx_line_stress", 12), "varied sounds are not served from one cached stream")
	return true


func test_lake_ambience_is_synthesized() -> bool:
	var engine := AudioManager.get_ambience_engine()
	if not check(engine != null, "ambience engine exists after Boot"):
		return true
	AudioManager.set_ambience_state(&"lake")
	check_eq(engine.get_state(), AmbienceEngine.STATE_LAKE, "lake state reached the engine")
	check(await wait_until(func() -> bool: return not engine.is_rendering(), 30.0), "the loops finish rendering in the background")

	for layer: StringName in AmbienceEngine.LAKE_LAYERS:
		var player := engine.get_node_or_null("%sLoop" % String(layer).capitalize()) as AudioStreamPlayer
		if not check(player != null and player.stream != null, "%s layer has a stream" % layer):
			continue
		var stream := player.stream as AudioStreamWAV
		check_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s loops" % layer)
		check_eq(player.bus, &"Ambience", "%s plays on the Ambience bus" % layer)
		var seconds := float(stream.data.size() / 2) / float(stream.mix_rate)
		check_near(seconds, float(AmbienceEngine.LAKE_LAYERS[layer][0]), 0.01, "%s loop length" % layer)
		# The loop must contain real signal, not silence.
		var loudest := 0
		for index: int in range(0, stream.data.size() - 1, 2):
			loudest = maxi(loudest, absi(stream.data.decode_s16(index)))
		check(loudest > 300 and loudest < 32767, "%s has signal without clipping (peak %d)" % [layer, loudest])

	AudioManager.duck_ambience(4.0, 0.2)
	await wait_frames(3)
	AudioManager.set_ambience_state(&"silence")
	check_eq(engine.get_state(), AmbienceEngine.STATE_SILENCE, "ambience can be switched off")
	return true


# Market sounds (GDD 175.7) and the warung ambience (GDD 175.12).
func test_market_sfx_render_cleanly() -> bool:
	var mix_rate := AudioManager.get_mix_rate()
	var expected_ids: Array[StringName] = [&"ui_sell", &"ui_purchase", &"ui_debt_ding"]
	check_eq(AudioManager.MARKET_SFX_IDS, expected_ids, "sale, purchase and debt sounds")
	for sfx_id: StringName in AudioManager.MARKET_SFX_IDS:
		var preset := AudioManager.get_preset(sfx_id)
		if not check(preset != null, "%s preset exists" % sfx_id):
			continue
		check_eq(preset.id, sfx_id, "%s preset id matches its file" % sfx_id)
		check(SfxRenderer.SUPPORTED_SYNTH_TYPES.has(preset.synth_type), "%s uses a supported synth type" % sfx_id)
		var samples := SfxRenderer.render(preset, mix_rate)
		check(not samples.is_empty() and not SynthDsp.has_invalid_samples(samples), "%s renders valid samples" % sfx_id)
		var peak := SynthDsp.peak(samples)
		check(peak >= 0.03 and peak <= 1.0, "%s peak %.3f is audible and within full scale" % [sfx_id, peak])
		check_eq(SfxRenderer.render(preset, mix_rate), samples, "%s always renders the same" % sfx_id)
		check(float(samples.size()) / float(mix_rate) <= 1.2, "%s is short" % sfx_id)
		check(AudioManager.get_sfx_stream(sfx_id) != null, "%s is playable through the manager" % sfx_id)

	# The debt chime is one calm note: it rings longer than the sale ticks and
	# stays quieter than the bite, the loudest cue in the game.
	var ding := SfxRenderer.render(AudioManager.get_preset(&"ui_debt_ding"), mix_rate)
	var sell := SfxRenderer.render(AudioManager.get_preset(&"ui_sell"), mix_rate)
	var bite := SfxRenderer.render(AudioManager.get_preset(&"sfx_real_bite"), mix_rate)
	check(ding.size() > sell.size() * 2, "the chime rings longer than the sale ticks")
	check(SynthDsp.peak(ding) < SynthDsp.peak(bite), "the chime is understated next to the bite")
	# Purchase is two notes: there is clear signal after the second one starts.
	var purchase := SfxRenderer.render(AudioManager.get_preset(&"ui_purchase"), mix_rate)
	@warning_ignore("integer_division")
	var middle := purchase.slice(purchase.size() / 3, purchase.size() * 2 / 3)
	check(_rms(middle) > 0.01, "the second purchase note sounds")
	return true


func test_market_ambience_is_synthesized() -> bool:
	var engine := AudioManager.get_ambience_engine()
	if not check(engine != null, "ambience engine exists after Boot"):
		return true
	AudioManager.set_ambience_state(&"market")
	check_eq(engine.get_state(), AmbienceEngine.STATE_MARKET, "market state reached the engine")
	check(await wait_until(func() -> bool: return not engine.is_rendering(), 60.0), "the loops finish rendering in the background")

	for layer: StringName in AmbienceEngine.MARKET_LAYERS:
		var stream := engine.get_layer_stream(layer)
		if not check(stream != null, "%s layer has a stream" % layer):
			continue
		check_eq(stream.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s loops" % layer)
		@warning_ignore("integer_division")
		var seconds := float(stream.data.size() / 2) / float(stream.mix_rate)
		check_near(seconds, float(AmbienceEngine.MARKET_LAYERS[layer][0]), 0.01, "%s loop length" % layer)
		var loudest := 0
		for index: int in range(0, stream.data.size() - 1, 2):
			loudest = maxi(loudest, absi(stream.data.decode_s16(index)))
		check(loudest > 300 and loudest < 32767, "%s has signal without clipping (peak %d)" % [layer, loudest])

	# The radio stays in the background, far below the UI sounds.
	check(float(AmbienceEngine.MARKET_LAYERS[&"radio"][1]) <= -20.0, "the radio is mixed well under the UI")
	check(AmbienceEngine.MARKET_LAYERS.has(&"wind") and AmbienceEngine.LAKE_LAYERS.has(&"wind"), "the afternoon wind is shared with the lake")
	AudioManager.set_ambience_state(&"silence")
	check_eq(engine.get_state(), AmbienceEngine.STATE_SILENCE, "ambience can be switched off")
	return true


# Boxing sounds (GDD 175.8).
func test_boxing_sfx_render_cleanly() -> bool:
	var mix_rate := AudioManager.get_mix_rate()
	check_eq(AudioManager.BOXING_SFX_IDS.size(), 7, "seven boxing sounds (GDD 175.8)")
	for sfx_id: StringName in AudioManager.BOXING_SFX_IDS:
		var preset := AudioManager.get_preset(sfx_id)
		if not check(preset != null, "%s preset exists" % sfx_id):
			continue
		check_eq(preset.id, sfx_id, "%s preset id matches its file" % sfx_id)
		check(SfxRenderer.SUPPORTED_SYNTH_TYPES.has(preset.synth_type), "%s uses a supported synth type" % sfx_id)
		var samples := SfxRenderer.render(preset, mix_rate)
		check(not samples.is_empty() and not SynthDsp.has_invalid_samples(samples), "%s renders valid samples" % sfx_id)
		var peak := SynthDsp.peak(samples)
		check(peak >= 0.03 and peak <= 1.0, "%s peak %.3f is audible and within full scale" % [sfx_id, peak])
		check(float(samples.size()) / float(mix_rate) <= 1.0, "%s is short" % sfx_id)
		check(AudioManager.get_sfx_stream(sfx_id) != null, "%s is playable through the manager" % sfx_id)

	var heavy := SfxRenderer.render(AudioManager.get_preset(&"box_hit_heavy"), mix_rate)
	var light := SfxRenderer.render(AudioManager.get_preset(&"box_hit_light"), mix_rate)
	var block := SfxRenderer.render(AudioManager.get_preset(&"box_block"), mix_rate)
	check(_rms(heavy) > _rms(light), "a heavy hit carries more than a light one")
	check(_rms(block) < _rms(light), "a blocked punch is the most muted of the three")
	check(AudioManager.get_preset(&"box_hit_heavy").pitch_hz < AudioManager.get_preset(&"box_hit_light").pitch_hz, "and the heavy hit is lower")
	# The knockout is a sequence: sound in each third of the clip.
	var ko := SfxRenderer.render(AudioManager.get_preset(&"box_ko"), mix_rate)
	@warning_ignore("integer_division")
	var third := ko.size() / 3
	for part: int in 3:
		check(_rms(ko.slice(third * part, third * (part + 1))) > 0.01, "knockout tom %d sounds" % (part + 1))
	return true
