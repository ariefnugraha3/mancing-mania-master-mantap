extends Node
## Save, load, validation and migration of user://save_v5.json
## (GDD 115-118, 169.3, 171, 176.8).
##
## Writes go to a temporary file that is verified and then renamed over the
## real save, so an interrupted write leaves the previous save untouched.
## A save that cannot be read is copied to the corrupt-backup path and is
## never overwritten until the player explicitly starts a new game.

signal save_started()
signal save_finished(success: bool)
signal load_finished(success: bool)
signal save_error(message: String)

const SAVE_FILE := "save_v5.json"
const TEMP_FILE := "save_v5.json.tmp"
const CORRUPT_BACKUP_FILE := "save_v5_corrupt_backup.json"
const BACKUP_FILE_PATTERN := "save_v5_backup_%s.json"
const DEFAULT_STORAGE_DIR := "user://"
const SETTINGS_AUTOSAVE_DELAY_SEC := 0.4

const STATUS_OK := &"ok"
const STATUS_MISSING := &"missing"
const STATUS_CORRUPT := &"corrupt"
const STATUS_UNSUPPORTED := &"unsupported_version"

## Explicit save from the debug overlay; the only reason allowed to write while
## the state carries debug mutations (GDD 178.3).
const REASON_DEBUG_STATE := &"debug_state"

## Schema migrations keyed by the version they upgrade *from*. Schema 5 is the
## first version this codebase ever wrote, so there is nothing to migrate yet;
## versions 1-4 belonged to pre-production documents and are not supported.
var _migrations: Dictionary[int, Callable] = {}

var _storage_dir: String = DEFAULT_STORAGE_DIR
var _last_load_status: StringName = STATUS_MISSING
var _has_unsaved_changes: bool = false
var _settings_timer: Timer

## Test hooks (GDD QA SAVE-008): stop a save right after the temp file exists,
## or make the write itself fail.
var simulate_interrupted_write: bool = false
var simulate_write_failure: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_settings_timer = Timer.new()
	_settings_timer.one_shot = true
	_settings_timer.wait_time = SETTINGS_AUTOSAVE_DELAY_SEC
	_settings_timer.timeout.connect(_on_settings_timer_timeout)
	add_child(_settings_timer)
	GameState.settings_changed.connect(_on_settings_changed)


# --- Public API (GDD 169.3) -------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(get_save_path()) or FileAccess.file_exists(_temp_path())


## Loads the save into GameState. On failure GameState is left untouched and
## get_last_load_status() says why.
func load_game() -> bool:
	_recover_interrupted_write()
	if not FileAccess.file_exists(get_save_path()):
		return _finish_load(STATUS_MISSING)

	var parsed: Variant = _read_json_file(get_save_path())
	if typeof(parsed) != TYPE_DICTIONARY:
		_preserve_corrupt_file()
		return _finish_load(STATUS_CORRUPT)

	var raw: Dictionary = parsed
	var version := SaveSchema.read_version(raw)
	if version <= 0:
		_preserve_corrupt_file()
		return _finish_load(STATUS_CORRUPT)
	if version != SaveSchema.VERSION:
		if not _can_migrate(version):
			# Keep a copy: the player may choose to start over on top of it.
			create_backup(&"unsupported_version")
			return _finish_load(STATUS_UNSUPPORTED)
		create_backup(&"pre_migration")
		raw = migrate_save(raw)
		if raw.is_empty():
			return _finish_load(STATUS_UNSUPPORTED)

	var normalized := validate_save(raw)
	if normalized.is_empty():
		_preserve_corrupt_file()
		return _finish_load(STATUS_CORRUPT)

	var repairs := SaveSchema.last_repairs.duplicate()
	GameState.apply_loaded_save(normalized)
	if not repairs.is_empty() or version != SaveSchema.VERSION:
		# Rewriting is destructive for the fields that were repaired: back up first.
		GameLog.warn(&"SAVE", "save was repaired on load", {"repairs": repairs.size(), "first": repairs[0] if not repairs.is_empty() else "migration"})
		create_backup(&"pre_repair")
		save_game(&"repair")
	return _finish_load(STATUS_OK)


func save_game(reason: StringName = &"manual") -> bool:
	if reason != REASON_DEBUG_STATE and DebugService.is_dev_dirty():
		# Debug mutations are never persisted implicitly (GDD 178.3).
		GameLog.info(&"SAVE", "skipped while DEV DIRTY STATE", {"reason": reason})
		return true

	save_started.emit()
	var data := GameState.export_save_state()
	data["last_played_at_utc"] = SaveSchema.utc_timestamp()
	data["system"] = SaveSchema.default_system()

	var failure := _write_atomically(JSON.stringify(data, "\t"))
	if failure != "":
		_has_unsaved_changes = true
		GameLog.warn(&"SAVE", "save failed", {"reason": reason, "cause": failure})
		save_error.emit(TextDb.t(&"error.save_failed.body"))
		save_finished.emit(false)
		return false

	_has_unsaved_changes = false
	GameLog.info(&"SAVE", "saved", {"reason": reason})
	save_finished.emit(true)
	return true


## Removes the save and any leftover temp file. Backups are kept on purpose.
func delete_save() -> bool:
	_settings_timer.stop()
	var ok := true
	for path: String in [get_save_path(), _temp_path()]:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			ok = false
	_has_unsaved_changes = false
	if ok:
		_last_load_status = STATUS_MISSING
	return ok


## Copies the current save file to save_v5_backup_<tag>.json.
func create_backup(tag: StringName) -> bool:
	if not FileAccess.file_exists(get_save_path()):
		return false
	return _copy_file(get_save_path(), _storage_dir.path_join(BACKUP_FILE_PATTERN % tag))


## Returns the normalized save, or an empty dictionary if it is unrecoverable.
func validate_save(data: Dictionary) -> Dictionary:
	return SaveSchema.normalize(data)


## Upgrades `data` to the current schema one version at a time. Returns an
## empty dictionary when its version is not supported.
func migrate_save(data: Dictionary) -> Dictionary:
	var current := data.duplicate(true)
	var version := SaveSchema.read_version(current)
	if version <= 0 or version > SaveSchema.VERSION:
		return {}
	while version < SaveSchema.VERSION:
		if not _migrations.has(version):
			return {}
		current = _migrations[version].call(current)
		var next_version := SaveSchema.read_version(current)
		if next_version <= version:
			GameLog.error(&"SAVE", "migration did not advance the version", {"from": version})
			return {}
		version = next_version
	return current


func export_save_json() -> String:
	var data := GameState.export_save_state()
	data["last_played_at_utc"] = SaveSchema.utc_timestamp()
	data["system"] = SaveSchema.default_system()
	return JSON.stringify(data, "\t")


## Replaces the current game with an exported save. The existing save is backed
## up first; invalid text changes nothing and returns false.
func import_save_json(json_text: String) -> bool:
	var parsed: Variant = _parse_json(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var migrated := migrate_save(parsed)
	if migrated.is_empty():
		return false
	var normalized := validate_save(migrated)
	if normalized.is_empty():
		return false
	create_backup(&"pre_import")
	GameState.apply_loaded_save(normalized)
	return save_game(&"import")


# --- Extras used by Boot, the menu and tests --------------------------------

func get_last_load_status() -> StringName:
	return _last_load_status


func has_unsaved_changes() -> bool:
	return _has_unsaved_changes


func get_save_path() -> String:
	return _storage_dir.path_join(SAVE_FILE)


func get_corrupt_backup_path() -> String:
	return _storage_dir.path_join(CORRUPT_BACKUP_FILE)


## Points the manager at another folder. Tests use this to work on an isolated
## temp save; passing nothing restores user://.
func configure_storage(directory: String = DEFAULT_STORAGE_DIR) -> void:
	_settings_timer.stop()
	_storage_dir = directory
	_last_load_status = STATUS_MISSING
	_has_unsaved_changes = false
	if not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)


## Writes any pending debounced settings change right now.
func flush_pending_autosave() -> void:
	if not _settings_timer.is_stopped():
		_settings_timer.stop()
		_on_settings_timer_timeout()


# --- Internals --------------------------------------------------------------

func _finish_load(status: StringName) -> bool:
	_last_load_status = status
	var success := status == STATUS_OK
	if not success and status != STATUS_MISSING:
		GameLog.warn(&"SAVE", "load failed", {"status": status})
	load_finished.emit(success)
	return success


func _can_migrate(version: int) -> bool:
	if version > SaveSchema.VERSION:
		return false
	for step: int in range(version, SaveSchema.VERSION):
		if not _migrations.has(step):
			return false
	return true


func _temp_path() -> String:
	return _storage_dir.path_join(TEMP_FILE)


## Returns "" on success or a short cause on failure.
func _write_atomically(text: String) -> String:
	if simulate_write_failure:
		return "simulated write failure"
	var temp_path := _temp_path()
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return "cannot open temp file (%s)" % error_string(FileAccess.get_open_error())
	file.store_string(text)
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return "write error (%s)" % error_string(write_error)

	# Never replace a good save with a file that does not read back.
	if typeof(_read_json_file(temp_path)) != TYPE_DICTIONARY:
		DirAccess.remove_absolute(temp_path)
		return "temp file failed verification"
	if simulate_interrupted_write:
		return "simulated interruption before replace"

	var rename_error := DirAccess.rename_absolute(temp_path, get_save_path())
	if rename_error != OK:
		return "cannot replace save (%s)" % error_string(rename_error)
	return ""


## If a write was cut off after the temp file was complete but before it
## replaced the save, the temp file is the newest valid state: promote it.
## A leftover temp next to an existing save is stale and is discarded.
func _recover_interrupted_write() -> void:
	var temp_path := _temp_path()
	if not FileAccess.file_exists(temp_path):
		return
	if FileAccess.file_exists(get_save_path()):
		DirAccess.remove_absolute(temp_path)
		return
	if typeof(_read_json_file(temp_path)) == TYPE_DICTIONARY:
		DirAccess.rename_absolute(temp_path, get_save_path())
		GameLog.warn(&"SAVE", "recovered save from an interrupted write")
	else:
		DirAccess.remove_absolute(temp_path)


func _preserve_corrupt_file() -> void:
	if _copy_file(get_save_path(), get_corrupt_backup_path()):
		GameLog.warn(&"SAVE", "unreadable save preserved", {"backup": get_corrupt_backup_path()})


func _copy_file(from_path: String, to_path: String) -> bool:
	var bytes := FileAccess.get_file_as_bytes(from_path)
	if bytes.is_empty() and FileAccess.get_open_error() != OK:
		return false
	var file := FileAccess.open(to_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	var copy_error := file.get_error()
	file.close()
	return copy_error == OK


func _read_json_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return _parse_json(FileAccess.get_file_as_string(path))


## Parses without the engine error spam that JSON.parse_string() prints.
func _parse_json(text: String) -> Variant:
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	return json.data


func _on_settings_changed(_key: StringName) -> void:
	# Settings live inside the save; with no save yet they stay in memory and
	# are written when New Game creates the file.
	if FileAccess.file_exists(get_save_path()) and GameState.has_active_game():
		_settings_timer.start()


func _on_settings_timer_timeout() -> void:
	save_game(&"settings")
