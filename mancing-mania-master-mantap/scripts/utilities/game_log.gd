class_name GameLog
extends RefCounted
## Structured log lines in the GDD 178.4 format:
## [TIME][SYSTEM][LEVEL] message key=value
##
## INFO lines are debug-build only so release builds stay quiet.

## Tests set this to silence lines produced by deliberately broken input.
static var muted: bool = false


static func info(system: StringName, message: String, fields: Dictionary = {}) -> void:
	if muted or not OS.is_debug_build():
		return
	print(_format(system, "INFO", message, fields))


static func warn(system: StringName, message: String, fields: Dictionary = {}) -> void:
	if muted:
		return
	push_warning(_format(system, "WARN", message, fields))


static func error(system: StringName, message: String, fields: Dictionary = {}) -> void:
	if muted:
		return
	push_error(_format(system, "ERROR", message, fields))


static func _format(system: StringName, level: String, message: String, fields: Dictionary) -> String:
	var line := "[%.3f][%s][%s] %s" % [Time.get_ticks_msec() / 1000.0, system, level, message]
	for key: Variant in fields:
		line += " %s=%s" % [key, fields[key]]
	return line
