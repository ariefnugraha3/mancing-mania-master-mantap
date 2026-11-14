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


# Market content (GDD 72, 172.8, 174.5, 174.9, 185.15).
func test_market_assets_are_generated() -> bool:
	var manifest := GeneratorManifest.read()
	if not check(manifest != null, "manifest loads"):
		return true
	var ids: PackedStringArray = manifest.get_asset_ids()
	for asset_id: String in [
		"chr_bu_yati", "env_market_set", "prop_market_table", "prop_market_scale", "prop_market_freezer",
		"prop_market_thermos", "prop_market_jar_set", "prop_plastic_chair", "prop_hanging_lamp",
		"prop_market_price_board", "prop_market_fan",
	]:
		check(ids.has(asset_id), "manifest lists %s" % asset_id)

	var bu_yati: Node = (load("res://generated/scenes/characters/chr_bu_yati.tscn") as PackedScene).instantiate()
	check(bu_yati.get_node_or_null("Skeleton3D") is Skeleton3D, "Bu Yati has a skeleton")
	var yati_player := bu_yati.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if check(yati_player != null, "Bu Yati has an AnimationPlayer"):
		for clip: StringName in [&"market_idle", &"weigh_fish", &"cash_count", &"look_darto", &"deadpan_blink"]:
			check(yati_player.has_animation(clip), "Bu Yati clip %s (GDD 172.8)" % clip)
		check_eq(yati_player.get_animation(&"market_idle").loop_mode, Animation.LOOP_LINEAR, "her idle loops")
	bu_yati.free()

	var darto: Node = (load("res://generated/scenes/characters/chr_darto.tscn") as PackedScene).instantiate()
	check((darto.get_node("AnimationPlayer") as AnimationPlayer).has_animation(&"market_idle"), "Darto has a Market idle")
	darto.free()

	var market: Node = (load("res://generated/scenes/environment/env_market_set.tscn") as PackedScene).instantiate()
	for marker: String in ["BuYatiSpot", "DartoSpot", "CameraLandscape", "CameraPortrait"]:
		check(market.get_node_or_null("Markers/%s" % marker) is Marker3D, "Market set marker %s" % marker)
	var props := market.get_node_or_null("Props")
	if check(props != null, "the Market set has its furniture"):
		for prop: String in ["Counter", "Scale", "Freezer", "Thermos", "Jars", "ChairA", "ChairB", "HangingLamp", "PriceBoard", "Fan"]:
			var node := props.get_node_or_null(prop)
			check(node != null and node.scene_file_path.begins_with("res://generated/scenes/props/"), "%s is an instanced generated prop" % prop)
		check(props.get_node_or_null("Fan/Blades") is MeshInstance3D, "the fan blades can turn on their own")
	market.free()
	return true


func test_fish_book_portraits_are_rendered() -> bool:
	var manifest := GeneratorManifest.read()
	for fish: FishData in GameData.get_all_fish():
		var path := "res://generated/textures/fish_book/tex_fishbook_%s.png" % fish.id
		check(manifest != null and manifest.get_outputs().has(path), "%s portrait is a recorded generator output" % fish.id)
		if not check(fish.portrait_texture != null, "%s has a portrait" % fish.id):
			continue
		check_eq(fish.portrait_texture.resource_path, path, "%s uses its own portrait (GDD 174.9)" % fish.id)
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if not check(image != null, "%s portrait file loads" % fish.id):
			continue
		check_eq(image.get_size(), Vector2i(512, 288), "%s portrait size" % fish.id)
		check_eq(image.get_pixel(0, 0).a, 0.0, "%s portrait has a transparent background" % fish.id)
		var opaque := 0
		for y: int in range(0, image.get_height(), 8):
			for x: int in range(0, image.get_width(), 8):
				if image.get_pixel(x, y).a > 0.9:
					opaque += 1
		# The fish fills a good part of the frame, but never all of it.
		check(opaque > 180 and opaque < 1800, "%s is framed in its portrait (%d of 2304 samples)" % [fish.id, opaque])
	return true


# Boxing content (GDD 172.2, 172.6, 174.7, 185.16).
func test_boxing_assets_follow_the_animation_contract() -> bool:
	var manifest := GeneratorManifest.read()
	if not check(manifest != null, "manifest loads"):
		return true
	var ids: PackedStringArray = manifest.get_asset_ids()
	for asset_id: String in ["env_boxing_set", "prop_boxing_corner_stool", "prop_boxing_ropes", "prop_boxing_mat"]:
		check(ids.has(asset_id), "manifest lists %s" % asset_id)

	# Every fish: gloves and the boxing clips of the universal contract.
	var fish_clips: Array[StringName] = [&"box_idle", &"box_block", &"box_hit", &"box_ko"]
	for fish: FishData in GameData.get_all_fish():
		var rig: Node = fish.model_scene.instantiate()
		check(rig.get_node_or_null("AccessoryMeshes/Gloves") is MeshInstance3D, "%s has boxing gloves" % fish.id)
		var player := rig.get_node("AnimationPlayer") as AnimationPlayer
		for clip: StringName in fish_clips:
			check(player.has_animation(clip), "%s clip %s (GDD 172.6)" % [fish.id, clip])
		check_eq(player.get_animation(&"box_idle").loop_mode, Animation.LOOP_LINEAR, "%s guard loops" % fish.id)
		for variant: String in BoxingWorld.ATTACK_VARIANTS:
			for suffix: String in ["", BoxingWorld.MIRROR_SUFFIX]:
				var clip_name := StringName("box_attack_%s%s" % [variant, suffix])
				if not check(player.has_animation(clip_name), "%s clip %s" % [fish.id, clip_name]):
					continue
				var attack := player.get_animation(clip_name)
				check(attack.has_marker(&"telegraph_start") and attack.has_marker(&"impact") and attack.has_marker(&"recovery_end"), "%s %s has the three markers" % [fish.id, clip_name])
				check_eq(attack.get_marker_time(&"telegraph_start"), 0.0, "%s %s telegraph starts the clip" % [fish.id, clip_name])
				check_eq(attack.get_marker_time(&"impact"), BoxingWorld.ATTACK_IMPACT_TIME, "%s %s impact is at the normalized 1.0" % [fish.id, clip_name])
		rig.free()

	# Darto: nine clips whose timing is the combat timing (GDD 172.2).
	var config := GameData.get_boxing_config()
	var darto: Node = (load("res://generated/scenes/characters/chr_darto.tscn") as PackedScene).instantiate()
	var gloves := darto.get_node_or_null("AccessoryMeshes/BoxingGloves") as Node3D
	check(gloves != null and not gloves.visible, "Darto owns gloves and they are off outside the ring")
	var darto_player := darto.get_node("AnimationPlayer") as AnimationPlayer
	var lengths: Dictionary = {
		&"box_dodge_left": BoxingController.DODGE_SEC, &"box_dodge_right": BoxingController.DODGE_SEC,
		&"box_jab": config.jab_startup_sec + config.jab_recovery_sec,
		&"box_cross": config.cross_startup_sec + config.cross_recovery_sec,
		&"box_hit_left": BoxingController.HIT_STUN_SEC, &"box_hit_right": BoxingController.HIT_STUN_SEC,
		&"box_ko": 1.2, &"box_win": 1.1,
	}
	check(darto_player.has_animation(&"box_idle") and darto_player.get_animation(&"box_idle").loop_mode == Animation.LOOP_LINEAR, "Darto's guard loops")
	for clip: StringName in lengths:
		if check(darto_player.has_animation(clip), "Darto clip %s" % clip):
			check_near(darto_player.get_animation(clip).length, lengths[clip], 0.0001, "%s length" % clip)
	check_near(darto_player.get_animation(&"box_jab").get_marker_time(&"hit_frame"), config.jab_startup_sec, 0.0001, "jab hit_frame is the jab startup")
	check_near(darto_player.get_animation(&"box_cross").get_marker_time(&"hit_frame"), config.cross_startup_sec, 0.0001, "cross hit_frame is the cross startup")
	check(darto_player.get_animation(&"box_dodge_left").has_marker(&"lean_peak"), "the dodge marks where the lean is held")
	darto.free()

	var ring: Node = (load("res://generated/scenes/environment/env_boxing_set.tscn") as PackedScene).instantiate()
	for marker: String in ["DartoSpot", "FishSpot", "CameraLandscape", "CameraPortrait"]:
		check(ring.get_node_or_null("Markers/%s" % marker) is Marker3D, "boxing set marker %s" % marker)
	for prop: String in ["Mat", "Ropes", "FishStool"]:
		var node := ring.get_node_or_null("Props/%s" % prop)
		check(node != null and node.scene_file_path.begins_with("res://generated/scenes/props/"), "%s is an instanced generated prop" % prop)
	# The fish stands at Darto's chest height and the two face each other.
	var fish_spot := ring.get_node("Markers/FishSpot") as Node3D
	var darto_spot := ring.get_node("Markers/DartoSpot") as Node3D
	var to_darto := (darto_spot.position - fish_spot.position).slide(Vector3.UP).normalized()
	check(fish_spot.transform.basis.x.dot(to_darto) > 0.99, "the fish's belly faces Darto")
	check((-darto_spot.transform.basis.z).dot(-to_darto) > 0.99, "Darto faces the fish")
	check(fish_spot.position.y > 0.5, "the fish stands on the stool")
	ring.free()
	return true
