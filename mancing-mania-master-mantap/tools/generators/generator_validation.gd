extends RefCounted
## Checks generated outputs against the manifest (GDD 184.15, 191.9):
## every listed file must exist and still match the checksum the generator
## recorded, which catches hand edits and stale output.

const Manifest := preload("res://tools/generators/generator_manifest.gd")

const REQUIRED_FIELDS: Array[String] = ["generator", "generator_version", "seed", "output", "sha256"]


## Returns one message per problem; empty means the generated set is consistent.
static func validate(manifest_path: String = Manifest.MANIFEST_PATH) -> PackedStringArray:
	var errors := PackedStringArray()
	var manifest := Manifest.read(manifest_path)
	if manifest == null:
		errors.append("generator manifest is missing or malformed: %s" % manifest_path)
		return errors

	for asset_id: String in manifest.get_asset_ids():
		var entry: Dictionary = manifest.get_entry(asset_id)
		var complete := true
		for field: String in REQUIRED_FIELDS:
			if not entry.has(field):
				errors.append("%s: manifest entry has no '%s'" % [asset_id, field])
				complete = false
		if not complete:
			continue

		var output := str(entry["output"])
		if not output.begins_with("res://generated/"):
			errors.append("%s: output is outside res://generated/ (%s)" % [asset_id, output])
		if not FileAccess.file_exists(output):
			errors.append("%s: output file is missing (%s)" % [asset_id, output])
			continue
		if FileAccess.get_sha256(output) != str(entry["sha256"]):
			errors.append("%s: output differs from the generated version; re-run the generator (%s)" % [asset_id, output])
	return errors
