extends SceneTree
## Release validator and build manifest (GDD 186.10, 187.9, 196.6-196.8).
##
##   godot --headless --path . --script res://tools/release/release_tool.gd -- --validate
##   godot --headless --path . --script res://tools/release/release_tool.gd -- --manifest=release/build_manifest.json
##
## --validate fails (exit 1) while anything a public release needs is still
## missing: publisher metadata, a privacy contact, the exported packages.
## --manifest writes the SHA-256 of every release artifact with the build's
## inputs (version, engine, commit, generator manifest).

const PUBLISHER_METADATA := "res://release/publisher_metadata.json"
const PUBLISHER_EXAMPLE := "res://release/publisher_metadata.example.json"
const REQUIRED_PUBLISHER_FIELDS: Array[String] = ["publisher_display_name", "publisher_support_email", "privacy_policy_https_url"]
const PLACEHOLDER_MARK := "["
const ARTIFACTS: Array[String] = [
	"build/web/index.html", "build/web/index.js", "build/web/index.wasm", "build/web/index.pck",
	"build/itch/catch-and-brawl-web-%s.zip",
	"build/android/CatchAndBrawl.aab",
	"build/store/google_play/icon_512.png", "build/store/google_play/feature_1024x500.png",
	"build/store/google_play/adaptive_foreground_432.png", "build/store/google_play/adaptive_background_432.png",
	"build/store/google_play/screenshot_01_fishing_1080x1920.png", "build/store/google_play/screenshot_02_fish_duel_1080x1920.png",
	"build/store/google_play/screenshot_03_market_1080x1920.png", "build/store/google_play/screenshot_04_dance_1080x1920.png",
	"build/store/google_play/screenshot_05_fishbook_1080x1920.png",
]


func _initialize() -> void:
	var problems := PackedStringArray()
	var wrote := ""
	for argument: String in OS.get_cmdline_user_args():
		if argument == "--validate":
			problems = validate()
		elif argument.begins_with("--manifest="):
			wrote = write_manifest(argument.trim_prefix("--manifest="))
	if wrote != "":
		print("[RELEASE] manifest ", wrote)
	for problem: String in problems:
		print("[RELEASE] BLOCKED: ", problem)
	if problems.is_empty():
		print("[RELEASE] validation passed")
	quit(1 if not problems.is_empty() else 0)


static func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version"))


## Everything a public release still needs, as readable problems.
static func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if not FileAccess.file_exists(PUBLISHER_METADATA):
		problems.append("release/publisher_metadata.json is missing (copy %s and fill it in)" % PUBLISHER_EXAMPLE.get_file())
	else:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PUBLISHER_METADATA))
		for field: String in REQUIRED_PUBLISHER_FIELDS:
			var value := str((data as Dictionary).get(field, "")) if typeof(data) == TYPE_DICTIONARY else ""
			if value == "" or value.contains(PLACEHOLDER_MARK):
				problems.append("publisher field %s is empty or a placeholder" % field)
	for path: String in ["res://PRIVACY_POLICY.md", "res://release/privacy_policy.html"]:
		if FileAccess.get_file_as_string(path).contains("[PUBLISHER SUPPORT EMAIL]"):
			problems.append("%s still has the support email placeholder" % path.get_file())
	if TextDb.t(&"privacy.policy.contact.body").contains("[PUBLISHER SUPPORT EMAIL]"):
		problems.append("the in-game privacy policy still has the support email placeholder")
	for artifact: String in _artifact_paths():
		if not FileAccess.file_exists("res://" + artifact):
			problems.append("artifact missing: %s" % artifact)
	return problems


static func write_manifest(path: String) -> String:
	var artifacts := {}
	for artifact: String in _artifact_paths():
		var full := "res://" + artifact
		if FileAccess.file_exists(full):
			artifacts[artifact] = {"sha256": FileAccess.get_sha256(full), "bytes": FileAccess.get_file_as_bytes(full).size()}
		else:
			artifacts[artifact] = {"missing": true}
	var commit := ""
	var output: Array = []
	if OS.execute("git", ["rev-parse", "HEAD"], output) == 0 and not output.is_empty():
		commit = str(output[0]).strip_edges()
	var manifest := {
		"product": "Catch and Brawl",
		"version": version(),
		"engine": Engine.get_version_info()["string"],
		"renderer": "gl_compatibility",
		"source_commit": commit,
		"generator_manifest_sha256": FileAccess.get_sha256("res://generated/manifests/generator_manifest.json"),
		"export_presets_sha256": FileAccess.get_sha256("res://export_presets.cfg"),
		"artifacts": artifacts,
	}
	var file := FileAccess.open("res://" + path if not path.begins_with("res://") else path, FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "  ", true) + "\n")
	file.close()
	return path


static func _artifact_paths() -> Array[String]:
	var paths: Array[String] = []
	for artifact: String in ARTIFACTS:
		paths.append(artifact % version() if artifact.contains("%s") else artifact)
	return paths
