extends RefCounted
## Base class for the headless test suites run by tests/run_all.gd.
##
## A test is any method named test_*. It must end with `return true`: a runtime
## error aborts a GDScript function and hands back null, so anything other than
## true is counted as a failure instead of silently passing.

var tree: SceneTree
var passed: int = 0
var failed: int = 0
var failures: PackedStringArray = PackedStringArray()

var _current_test: String = ""
var _current_failed: bool = false


func get_suite_name() -> String:
	return "unnamed"


func before_all() -> void:
	pass


func after_all() -> void:
	pass


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func run() -> void:
	await before_all()
	for method: Dictionary in get_method_list():
		var method_name: String = method["name"]
		if not method_name.begins_with("test_"):
			continue
		_current_test = method_name
		_current_failed = false
		await before_each()
		var result: Variant = await call(method_name)
		await after_each()
		if result != true and not _current_failed:
			_record("did not finish (runtime error?)")
		if _current_failed:
			failed += 1
		else:
			passed += 1
	await after_all()


# --- Assertions -------------------------------------------------------------

func check(condition: bool, label: String) -> bool:
	if not condition:
		_record(label)
	return condition


func check_eq(actual: Variant, expected: Variant, label: String) -> bool:
	var same: bool = typeof(actual) == typeof(expected) and actual == expected
	if not same and _is_number(actual) and _is_number(expected):
		same = is_equal_approx(float(actual), float(expected))
	if not same:
		_record("%s: expected %s, got %s" % [label, var_to_str(expected), var_to_str(actual)])
	return same


func check_near(actual: float, expected: float, tolerance: float, label: String) -> bool:
	var close := absf(actual - expected) <= tolerance
	if not close:
		_record("%s: expected %s +/- %s, got %s" % [label, expected, tolerance, actual])
	return close


## Passes when `messages` is empty; otherwise reports the messages themselves.
func check_empty(messages: PackedStringArray, label: String) -> bool:
	if not messages.is_empty():
		_record("%s: %s" % [label, "; ".join(messages)])
	return messages.is_empty()


## Passes when at least one message contains `fragment`.
func check_contains(messages: PackedStringArray, fragment: String, label: String) -> bool:
	for message: String in messages:
		if message.contains(fragment):
			return true
	_record("%s: no message contains '%s' in [%s]" % [label, fragment, "; ".join(messages)])
	return false


# --- Helpers ----------------------------------------------------------------

## Polls `condition` once per frame until it is true or the time runs out.
func wait_until(condition: Callable, timeout_sec: float = 5.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await tree.process_frame
	return true


## Waits on the wall clock. A SceneTreeTimer started late in a slow frame is
## charged for that whole frame and can fire early, so tests that measure real
## elapsed time must not use one.
func wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame


func wait_frames(count: int) -> void:
	for _index: int in count:
		await tree.process_frame


## Empties and removes a directory tree (used for temporary save folders).
func remove_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return
	for file_name: String in directory.get_files():
		directory.remove(file_name)
	for child: String in directory.get_directories():
		remove_directory(path.path_join(child))
	DirAccess.remove_absolute(path)


func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func read_json(path: String) -> Variant:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data


func _record(message: String) -> void:
	_current_failed = true
	failures.append("%s.%s - %s" % [get_suite_name(), _current_test, message])


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
