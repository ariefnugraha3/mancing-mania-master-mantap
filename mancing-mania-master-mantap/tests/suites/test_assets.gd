extends "res://tests/test_suite.gd"
## Zero-internet-asset policy and generator provenance (GDD 175.17, 184, 191.9).

const AssetPolicyScan := preload("res://tools/validation/asset_policy_scan.gd")
const GeneratorValidation := preload("res://tools/generators/generator_validation.gd")
const GeneratorManifest := preload("res://tools/generators/generator_manifest.gd")
const UiArtBuilder := preload("res://tools/generators/ui_art_builder.gd")
const GeneratorIo := preload("res://tools/generators/generator_io.gd")

const WORK_DIR := "user://test_tmp/assets"


func get_suite_name() -> String:
	return "assets"


func before_all() -> void:
	remove_directory(WORK_DIR)
	DirAccess.make_dir_recursive_absolute(WORK_DIR.path_join("project/art"))


func after_all() -> void:
	remove_directory(WORK_DIR)


func test_project_has_no_forbidden_assets() -> bool:
	check_empty(AssetPolicyScan.scan(), "asset policy scan of res://")
	return true


func test_policy_scan_catches_every_forbidden_kind() -> bool:
	var root := WORK_DIR.path_join("project")
	for file_name: String in ["theme_song.ogg", "click.WAV", "fancy.ttf", "art/stray.png", "art/model.glb", "art/notes.gd"]:
		write_text(root.path_join(file_name), "x")
	var violations := AssetPolicyScan.scan(root)
	check_eq(violations.size(), 5, "five forbidden files, the script is fine")
	check_contains(violations, "theme_song.ogg", "ogg audio")
	check_contains(violations, "click.WAV", "audio extension check ignores case")
	check_contains(violations, "fancy.ttf", "font file")
	check_contains(violations, "stray.png", "image that no generator produced")
	check_contains(violations, "model.glb", "model that no generator produced")
	return true


func test_generated_outputs_match_the_manifest() -> bool:
	check_empty(GeneratorValidation.validate(), "generator manifest validation")
	var manifest := GeneratorManifest.read()
	if check(manifest != null, "manifest loads"):
		check(manifest.get_asset_ids().has("ui_theme"), "manifest lists the UI theme")
		check(manifest.get_asset_ids().has("ui_app_icon"), "manifest lists the app icon")
		for output: String in manifest.get_outputs():
			check(output.begins_with("res://generated/"), "%s lives under res://generated/" % output)
	return true


func test_tampered_or_missing_output_is_detected() -> bool:
	var document: Dictionary = read_json(GeneratorManifest.MANIFEST_PATH)
	document["assets"]["ui_theme"]["sha256"] = "0000"
	document["assets"]["ghost"] = {
		"generator": "ui_art_builder", "generator_version": 1, "seed": 0,
		"output": "res://generated/ui/ghost.png", "sha256": "abc",
	}
	document["assets"]["outsider"] = {
		"generator": "ui_art_builder", "generator_version": 1, "seed": 0,
		"output": "res://icon.svg", "sha256": "abc",
	}
	document["assets"]["incomplete"] = {"generator": "ui_art_builder"}
	var tampered_path := WORK_DIR.path_join("tampered_manifest.json")
	write_text(tampered_path, JSON.stringify(document))

	var errors := GeneratorValidation.validate(tampered_path)
	check_contains(errors, "ui_theme: output differs", "edited output is detected")
	check_contains(errors, "ghost: output file is missing", "missing output is detected")
	check_contains(errors, "outsider: output is outside res://generated/", "outside output is detected")
	check_contains(errors, "incomplete: manifest entry has no", "incomplete entry is detected")
	check_contains(GeneratorValidation.validate(WORK_DIR.path_join("nope.json")), "missing or malformed", "missing manifest is detected")
	return true


func test_generated_theme_covers_the_ui_states() -> bool:
	var theme := load(UiArtBuilder.THEME_PATH) as Theme
	if not check(theme != null, "generated theme loads"):
		return true
	check_eq(ProjectSettings.get_setting("gui/theme/custom"), UiArtBuilder.THEME_PATH, "project uses the generated theme")
	check_eq(theme.default_font_size, UiTokens.FONT_BODY, "body font size")
	check(theme.default_font == null, "no custom font: the built-in font is the baseline")
	for button_type: StringName in [&"Button", UiTokens.TYPE_CTA_BUTTON, UiTokens.TYPE_DANGER_BUTTON]:
		for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
			check(theme.has_stylebox(state, button_type), "%s has a %s style" % [button_type, state])
	for label_type: StringName in [UiTokens.TYPE_TITLE, UiTokens.TYPE_SCREEN_TITLE, UiTokens.TYPE_HEADER, UiTokens.TYPE_SMALL]:
		check_eq(theme.get_type_variation_base(label_type), &"Label", "%s is a Label variation" % label_type)
	check_eq(theme.get_font_size(&"font_size", UiTokens.TYPE_TITLE), 44, "hero title size (GDD 167.3)")
	check_eq(theme.get_color(&"font_color", &"Label"), UiTokens.INK_900, "text uses ink_900")
	return true


func test_theme_generation_is_repeatable() -> bool:
	var builder := UiArtBuilder.new()
	var first_path := WORK_DIR.path_join("theme_a.tres")
	var second_path := WORK_DIR.path_join("theme_b.tres")
	check_eq(GeneratorIo.save_text_resource(builder.build_theme(), first_path), OK, "first theme saves")
	check_eq(GeneratorIo.save_text_resource(builder.build_theme(), second_path), OK, "second theme saves")
	check_eq(FileAccess.get_sha256(first_path), FileAccess.get_sha256(second_path), "two runs produce identical files")
	check_eq(FileAccess.get_sha256(first_path), FileAccess.get_sha256(UiArtBuilder.THEME_PATH), "a fresh build equals the committed theme")
	return true


func test_generated_headers_carry_no_editor_uid() -> bool:
	# Launching the generator with --editor would stamp a random UID into the
	# header; GeneratorIo strips it so both launch modes write the same bytes.
	var stamped := WORK_DIR.path_join("stamped.tres")
	var body := "

[resource]
default_font_size = 18
"
	write_text(stamped, "[gd_resource type=\"Theme\" format=3 uid=\"uid://abc123\"]" + body)
	var theme := load(stamped) as Theme
	if check(theme != null, "stamped resource loads"):
		check_eq(GeneratorIo.save_text_resource(theme, stamped), OK, "resave succeeds")
		check(not FileAccess.get_file_as_string(stamped).contains("uid="), "header has no uid after saving")
	check(not FileAccess.get_file_as_string(UiArtBuilder.THEME_PATH).split("
")[0].contains("uid="), "committed theme header has no uid")
	return true


func test_app_icon_matches_project_setting() -> bool:
	check_eq(ProjectSettings.get_setting("application/config/icon"), UiArtBuilder.ICON_PATH, "project icon is the generated icon")
	var image := Image.load_from_file(ProjectSettings.globalize_path(UiArtBuilder.ICON_PATH))
	if check(image != null, "icon file loads"):
		check_eq(image.get_size(), Vector2i(512, 512), "icon is 512x512")
		check_eq(image.get_pixel(0, 0).a, 0.0, "corners are transparent")
		check(image.get_pixel(256, 256).a > 0.99, "centre is opaque")
	return true
