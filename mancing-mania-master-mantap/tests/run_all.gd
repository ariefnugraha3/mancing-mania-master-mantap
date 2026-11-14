extends SceneTree
## Headless test runner (GDD 136):
##
##   godot --headless --path . --import          (once on a fresh checkout)
##   godot --headless --path . --script res://tests/run_all.gd
##   godot --headless --path . --script res://tests/run_all.gd -- --suite=save
##
## The process exit code is 0 only when every test passed, so CI can gate on it.
## Suites are loaded at run time, after the autoloads exist.

const SUITES: Array[String] = [
	"res://tests/suites/test_data.gd",
	"res://tests/suites/test_game_state.gd",
	"res://tests/suites/test_save.gd",
	"res://tests/suites/test_rng.gd",
	"res://tests/suites/test_audio.gd",
	"res://tests/suites/test_services.gd",
	"res://tests/suites/test_fishing.gd",
	"res://tests/suites/test_market.gd",
	"res://tests/suites/test_boxing.gd",
	"res://tests/suites/test_arm_wrestle.gd",
	"res://tests/suites/test_dance.gd",
	"res://tests/suites/test_suwit_wheel.gd",
	"res://tests/suites/test_story.gd",
	"res://tests/suites/test_accessibility.gd",
	"res://tests/suites/test_release.gd",
	"res://tests/suites/test_assets.gd",
	"res://tests/suites/test_boot_flow.gd",
]

## Hard stop for a hung await, so a broken test can never block CI forever.
## The clock restarts for every suite, so adding suites never trips it.
const WATCHDOG_SEC := 600.0

var _elapsed: float = 0.0


func _initialize() -> void:
	_run_all()


func _process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed > WATCHDOG_SEC:
		push_error("[TEST] watchdog: a suite ran longer than %d seconds" % int(WATCHDOG_SEC))
		quit(2)
	return false


func _run_all() -> void:
	# Autoloads enter the tree on the first frame; wait until they are ready.
	await process_frame
	await process_frame

	var filter := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--suite="):
			filter = argument.trim_prefix("--suite=")

	# Tests feed deliberately broken data; keep the expected complaints quiet.
	GameLog.muted = true

	var total_passed := 0
	var total_failed := 0
	var failures := PackedStringArray()
	for path: String in SUITES:
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			total_failed += 1
			failures.append("%s - suite failed to compile" % path)
			continue
		var suite: RefCounted = script.new()
		if filter != "" and suite.get_suite_name() != filter:
			continue
		suite.tree = self
		_elapsed = 0.0
		await suite.run()
		print("[TEST] %-12s %3d passed, %d failed" % [suite.get_suite_name(), suite.passed, suite.failed])
		total_passed += suite.passed
		total_failed += suite.failed
		failures.append_array(suite.failures)

	GameLog.muted = false
	# Every suite removes its own folder; drop the shared parent when it is empty.
	DirAccess.remove_absolute("user://test_tmp")
	for failure: String in failures:
		print("[TEST] FAIL %s" % failure)
	print("[TEST] Results: %d passed, %d failed" % [total_passed, total_failed])
	quit(1 if total_failed > 0 or total_passed == 0 else 0)
