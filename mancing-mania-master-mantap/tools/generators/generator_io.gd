extends RefCounted
## File output shared by every asset builder (GDD 184.4).
##
## Generated files must come out byte-identical no matter how the generator is
## launched. Run with `--editor`, Godot stamps a random `uid="uid://..."` into
## the header of each text resource; run without it, no UID is written. The
## outputs live at fixed, manifest-listed paths and are referenced by path, so
## the UID is removed and both launch modes produce the same file.


## Saves a text resource (.tres / .tscn) with a normalized header.
static func save_text_resource(resource: Resource, path: String) -> Error:
	var save_error := ResourceSaver.save(resource, path)
	if save_error != OK:
		return save_error
	var text := FileAccess.get_file_as_string(path)
	var header_end := text.find("\n")
	if header_end < 0:
		return ERR_FILE_CORRUPT
	var header := text.substr(0, header_end)
	var uid_start := header.find(" uid=\"")
	if uid_start < 0:
		return OK
	var uid_end := header.find("\"", uid_start + 6)
	if uid_end < 0:
		return ERR_FILE_CORRUPT
	var clean_header := header.substr(0, uid_start) + header.substr(uid_end + 1)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(clean_header + text.substr(header_end))
	file.close()
	return OK
