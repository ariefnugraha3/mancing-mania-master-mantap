extends SceneTree
## Performance baseline (GDD 190.2, 190.4, 190.6, 190.17). Run windowed so
## the renderer is real:
##
##   godot --path . --script res://tools/perf/perf_probe.gd -- --out=<file.json>
##
## Opens every scene through the router, lets it settle, then samples frame
## time, draw calls, primitives and memory. Ends with the 20x Fishing <->
## Market leak check. Writes JSON; the report is written from it by hand.

const SETTLE_SEC := 2.5
const SAMPLE_SEC := 4.0
const LEAK_ROUNDS := 20

var _results: Dictionary = {}
var _finished: Array[StringName] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var router: Node = root.get_node("SceneRouter")
	var game_state: Node = root.get_node("GameState")
	var story: Node = root.get_node("StoryDirector")
	# Boot normally builds the procedural audio; the probe starts past Boot.
	root.get_node("AudioManager").initialize_procedural_audio()
	router.transition_finished.connect(func(scene_id: StringName) -> void: _finished.append(scene_id))
	root.get_node("SaveManager").configure_storage("user://perf_probe")
	game_state.new_game()
	story.complete_event(&"story_prologue_zero", true)
	story.complete_event(&"story_first_fish", true)
	game_state.current_catch = {"fish_id": &"snakehead_sergeant", "weight_kg": 3.0, "is_big_one": false, "seed": 5}

	var out_path := "user://perf_probe.json"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_path = argument.trim_prefix("--out=")

	for preset: String in ["low", "medium", "high"]:
		game_state.set_setting(&"quality_preset", preset)
		await _measure("fishing_%s" % preset, func() -> void: router.goto_fishing(), &"fishing")
	game_state.set_setting(&"quality_preset", "medium")
	await _measure("main_menu", func() -> void: router.goto_main_menu(), &"main_menu")
	await _measure("market", func() -> void: router.goto_market(), &"market")
	for duel: StringName in [&"boxing", &"arm_wrestle", &"dance", &"suwit"]:
		await _measure(String(duel), func() -> void: router.goto_duel(duel, &"snakehead_sergeant"), duel)
	await _measure("wheel", func() -> void: router.goto_wheel(&"snakehead_sergeant"), &"wheel")
	await _measure("result", func() -> void: router.goto_result({"duel_id": &"boxing", "fish_id": &"snakehead_sergeant", "player_won": true, "duration_sec": 30.0, "seed": 5, "metrics": {}}), &"result")
	await _measure("story_home", func() -> void: router.goto_story(&"story_prologue_zero"), &"story")
	await _measure("story_lake_family", func() -> void: router.goto_story(&"story_final_family"), &"story")
	await _measure("credits", func() -> void: router.goto_credits(true), &"credits")

	# GDD 190.4: twenty round trips must not keep growing memory.
	await _go(func() -> void: router.goto_fishing(), &"fishing")
	await _wait(SETTLE_SEC)
	var baseline := Performance.get_monitor(Performance.MEMORY_STATIC)
	var objects_before := Performance.get_monitor(Performance.OBJECT_COUNT)
	var transitions: Array[float] = []
	for round_index: int in LEAK_ROUNDS:
		var started := Time.get_ticks_msec()
		await _go(func() -> void: router.goto_market(), &"market")
		transitions.append(float(Time.get_ticks_msec() - started) / 1000.0)
		started = Time.get_ticks_msec()
		await _go(func() -> void: router.goto_fishing(), &"fishing")
		transitions.append(float(Time.get_ticks_msec() - started) / 1000.0)
	await _wait(SETTLE_SEC)
	_results["leak_check"] = {
		"rounds": LEAK_ROUNDS,
		"static_memory_mb_before": baseline / 1048576.0,
		"static_memory_mb_after": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"objects_before": objects_before,
		"objects_after": Performance.get_monitor(Performance.OBJECT_COUNT),
		"fishing_market_transition_sec_max": transitions.max(),
		"fishing_market_transition_sec_avg": transitions.reduce(func(a: float, b: float) -> float: return a + b, 0.0) / float(transitions.size()),
	}
	_results["environment"] = {
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
		"window": str(root.size),
		"engine": Engine.get_version_info()["string"],
	}
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_results, "  ", true))
	file.close()
	print("[PERF] wrote ", out_path)
	quit(0)


func _go(route: Callable, scene_id: StringName) -> void:
	var count := _finished.count(scene_id)
	route.call()
	var waited := 0.0
	while _finished.count(scene_id) <= count and waited < 30.0:
		await process_frame
		waited += 1.0 / 60.0


func _wait(seconds: float) -> void:
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - start < int(seconds * 1000.0):
		await process_frame


func _measure(label: String, route: Callable, scene_id: StringName) -> void:
	var started := Time.get_ticks_msec()
	await _go(route, scene_id)
	var transition_sec := float(Time.get_ticks_msec() - started) / 1000.0
	await _wait(SETTLE_SEC)
	var frames := 0
	var worst_ms := 0.0
	var draw_calls := 0.0
	var primitives := 0.0
	var start := Time.get_ticks_usec()
	var last := start
	while Time.get_ticks_usec() - start < int(SAMPLE_SEC * 1000000.0):
		await process_frame
		var now := Time.get_ticks_usec()
		worst_ms = maxf(worst_ms, float(now - last) / 1000.0)
		last = now
		frames += 1
		draw_calls = maxf(draw_calls, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives = maxf(primitives, Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var elapsed := float(Time.get_ticks_usec() - start) / 1000000.0
	_results[label] = {
		"transition_sec": transition_sec,
		"avg_fps": float(frames) / elapsed,
		"worst_frame_ms": worst_ms,
		"max_draw_calls": draw_calls,
		"max_primitives": primitives,
		"static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_memory_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
	}
	print("[PERF] ", label, " ", JSON.stringify(_results[label]))
