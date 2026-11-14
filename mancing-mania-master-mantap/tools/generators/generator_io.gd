extends RefCounted
## File output shared by every asset builder (GDD 184.4).
##
## Generated files must come out byte-identical no matter how or when the
## generator runs. Godot's text saver is not deterministic by itself:
##   - launched with `--editor` it stamps random `uid="uid://..."` attributes;
##   - sub-resources and external references get random ID suffixes;
##   - every scene node gets a random `unique_id`.
## After saving, the file is rewritten with the UIDs and node IDs removed and
## every resource ID renumbered in file order, which depends only on content.


## Saves a text resource (.tres / .tscn) in normalized form.
static func save_text_resource(resource: Resource, path: String) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var save_error := ResourceSaver.save(resource, path)
	if save_error != OK:
		return save_error
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		return ERR_FILE_CORRUPT
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(normalize_text(text))
	file.close()
	return OK


## Packs a node tree into a scene file. Every node is owned by `root`, so the
## whole tree is saved.
static func save_scene(root: Node, path: String) -> Error:
	_claim(root, root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error != OK:
		return pack_error
	return save_text_resource(packed, path)


## Removes UIDs and renumbers resource IDs in the order they appear.
static func normalize_text(text: String) -> String:
	var lines := text.split("\n")
	var renames: Dictionary[String, String] = {}
	var ext_count := 0
	var sub_count := 0

	for index: int in lines.size():
		var line := lines[index]
		var is_ext := line.begins_with("[ext_resource ")
		var is_sub := line.begins_with("[sub_resource ")
		if index == 0 or is_ext:
			line = _strip_attribute(line, "uid")
		if line.begins_with("[node "):
			line = _strip_bare_attribute(line, "unique_id")
		if is_ext or is_sub:
			var old_id := _read_attribute(line, "id")
			var new_id := ""
			if is_ext:
				ext_count += 1
				new_id = "ext_%d" % ext_count
				renames["ExtResource(\"%s\")" % old_id] = "ExtResource(\"%s\")" % new_id
			else:
				sub_count += 1
				new_id = "%s_%d" % [_read_attribute(line, "type"), sub_count]
				renames["SubResource(\"%s\")" % old_id] = "SubResource(\"%s\")" % new_id
			line = line.replace("id=\"%s\"" % old_id, "id=\"%s\"" % new_id)
		lines[index] = line

	var normalized := "\n".join(lines)
	for old_reference: String in renames:
		normalized = normalized.replace(old_reference, renames[old_reference])
	return normalized


static func _claim(node: Node, owner: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner
		_claim(child, owner)


static func _read_attribute(line: String, attribute: String) -> String:
	var marker := " %s=\"" % attribute
	var start := line.find(marker)
	if start < 0:
		return ""
	start += marker.length()
	var end := line.find("\"", start)
	return line.substr(start, end - start) if end >= 0 else ""


## Removes an attribute whose value is not quoted, such as unique_id=123.
static func _strip_bare_attribute(line: String, attribute: String) -> String:
	var marker := " %s=" % attribute
	var start := line.find(marker)
	if start < 0:
		return line
	var end := start + marker.length()
	while end < line.length() and line[end] != " " and line[end] != "]":
		end += 1
	return line.substr(0, start) + line.substr(end)


static func _strip_attribute(line: String, attribute: String) -> String:
	var marker := " %s=\"" % attribute
	var start := line.find(marker)
	if start < 0:
		return line
	var end := line.find("\"", start + marker.length())
	if end < 0:
		return line
	return line.substr(0, start) + line.substr(end + 1)
