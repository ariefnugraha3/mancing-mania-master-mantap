extends RefCounted
## Provenance record for every generated asset (GDD 184.4, 191.9).
## Written to res://generated/manifests/generator_manifest.json; each entry
## names the generator, its version and seed, the output file and its checksum.

const MANIFEST_PATH := "res://generated/manifests/generator_manifest.json"
const SCHEMA := 1

var _assets: Dictionary = {}


## Records one generated output. Call it after the file was written, so the
## checksum covers what is really on disk.
func register(asset_id: String, generator: String, generator_version: int, seed: int, output: String) -> void:
	_assets[asset_id] = {
		"generator": generator,
		"generator_version": generator_version,
		"seed": seed,
		"output": output,
		"sha256": FileAccess.get_sha256(output),
	}


## Carries over the entries another manifest holds for one generator, as long
## as their files still exist. Used to keep reference-sheet records, which are
## produced by a separate (windowed) run.
func adopt(other: RefCounted, generator: String) -> void:
	if other == null:
		return
	for asset_id: String in other.get_asset_ids():
		var entry: Dictionary = other.get_entry(asset_id)
		if str(entry.get("generator", "")) == generator and FileAccess.file_exists(str(entry.get("output", ""))):
			_assets[asset_id] = entry


func get_asset_ids() -> PackedStringArray:
	var ids := PackedStringArray(_assets.keys())
	ids.sort()
	return ids


func get_entry(asset_id: String) -> Dictionary:
	return _assets.get(asset_id, {})


func get_outputs() -> PackedStringArray:
	var outputs := PackedStringArray()
	for asset_id: String in get_asset_ids():
		outputs.append(str(_assets[asset_id].get("output", "")))
	return outputs


## Serializes with sorted keys so re-running the generator on unchanged
## sources leaves the file byte-identical.
func to_json() -> String:
	var assets := {}
	for asset_id: String in get_asset_ids():
		assets[asset_id] = _assets[asset_id]
	var document := {
		"generator_schema": SCHEMA,
		"project_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"assets": assets,
	}
	return JSON.stringify(document, "  ", true) + "\n"


func write(path: String = MANIFEST_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(to_json())
	file.close()
	return true


## Loads a manifest from disk. Returns null when it is missing or malformed.
static func read(path: String = MANIFEST_PATH) -> RefCounted:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	var document: Dictionary = json.data
	if typeof(document.get("assets")) != TYPE_DICTIONARY:
		return null
	var manifest: RefCounted = load("res://tools/generators/generator_manifest.gd").new()
	manifest._assets = document["assets"]
	return manifest
