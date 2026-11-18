extends "res://tests/test_suite.gd"
## Release contract checks (GDD 135, 186, 187, 191): privacy screen,
## no network code, export presets, versioning and repository hygiene.

const RUNTIME_DIRS: Array[String] = ["res://scripts", "res://autoload", "res://scenes"]
const NETWORK_CLASSES: Array[String] = [
	"HTTPRequest", "HTTPClient", "StreamPeerTCP", "StreamPeerTLS", "WebSocketPeer", "PacketPeerUDP",
	"ENetMultiplayerPeer", "WebRTCPeerConnection", "JavaScriptBridge", "OS.shell_open",
]


func get_suite_name() -> String:
	return "release"


# GDD 187.1, 187.3, 187.9: no endpoint, SDK or network class in runtime code.
func test_runtime_code_has_no_network_access() -> bool:
	var found := PackedStringArray()
	for path: String in _files(RUNTIME_DIRS, ["gd", "tscn"]):
		var text := FileAccess.get_file_as_string(path)
		for name: String in NETWORK_CLASSES:
			if text.contains(name):
				found.append("%s uses %s" % [path, name])
		if text.contains("http://") or text.contains("https://"):
			found.append("%s contains a URL" % path)
	check_empty(found, "runtime code never opens a network connection")
	return true


# GDD 187.7: the summary, the full policy and the licences are in the game.
func test_privacy_screen_is_in_settings() -> bool:
	var settings := SettingsOverlay.new()
	tree.root.add_child(settings)
	await wait_frames(1)
	check(settings.find_child("PrivacyButton", true, false) != null, "Settings has PRIVACY")
	var web_note := settings.find_child("WebStorageNote", true, false) as Label
	check(web_note != null and web_note.text.contains("browser storage"), "the Web build warns that clearing browser storage deletes the save")
	check_eq(web_note.visible, PlatformService.is_web(), "the note shows only on the Web")
	var privacy := settings.find_child("Privacy", true, false) as PrivacyOverlay
	privacy.open()
	await wait_frames(2)
	for line: String in ["NO ACCOUNT REQUIRED", "NO ADS", "NO ANALYTICS", "NO PERSONAL DATA COLLECTION BY THE GAME", "SAVE DATA STAYS ON THIS DEVICE/BROWSER"]:
		check(privacy.get_page_text().contains(line), "summary: %s" % line)
	(privacy.find_child("ReadFullPolicy", true, false) as BaseButton).pressed.emit()
	await wait_frames(2)
	check_eq(privacy.get_page(), &"policy", "READ FULL PRIVACY POLICY opens the policy")
	check(privacy.get_page_text().contains("does not collect, sell, or share personal information"), "the full policy text is shown offline")
	privacy.on_cancel()
	(privacy.find_child("Licenses", true, false) as BaseButton).pressed.emit()
	await wait_frames(2)
	check(privacy.get_page_text().contains("MIT"), "the engine licence is shown")
	# The font licences travel with the fonts (GDD 184.12, 187.8).
	check(privacy.get_page_text().contains("SIL OPEN FONT LICENSE Version 1.1"), "Fredoka's OFL text is shown in full")
	check(privacy.get_page_text().contains("TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION"), "Chewy's Apache License text is shown in full")
	check(privacy.get_page_text().contains("Copyright 2016 The Fredoka Project Authors"), "Fredoka's copyright notice is shown")
	check(privacy.get_page_text().contains("Font Diner, Inc DBA Sideshow"), "Chewy's copyright notice is shown")
	settings.queue_free()
	await wait_frames(1)
	return true


# GDD 135, 186: presets, identity, permissions, what goes into the package.
func test_export_presets_follow_the_release_contract() -> bool:
	var presets := ConfigFile.new()
	if not check_eq(presets.load("res://export_presets.cfg"), OK, "export_presets.cfg exists"):
		return true
	var by_name := {}
	for section: String in presets.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			by_name[presets.get_value(section, "name")] = section
	check(by_name.has("Web") and by_name.has("Android") and by_name.has("iOS"), "Web, Android and iOS presets")
	var web: String = by_name.get("Web", "")
	var android: String = by_name.get("Android", "")
	var ios: String = by_name.get("iOS", "")
	# The game is played upright on phones and tablets (GDD 122, 167.8).
	check_eq(int(ProjectSettings.get_setting("display/window/handheld/orientation")), int(DisplayServer.SCREEN_PORTRAIT), "portrait orientation")
	check_eq(presets.get_value(ios + ".options", "application/bundle_identifier"), "com.catchandbrawl.game", "iOS bundle identifier")
	check_eq(int(presets.get_value(ios + ".options", "application/targeted_device_family")), 2, "iOS targets iPhone and iPad")
	check_eq(presets.get_value(ios, "export_path"), "build/ios/CatchAndBrawl.ipa", "iOS exports an IPA")
	check(presets.get_value(android + ".options", "screen/support_xlarge"), "Android runs on tablets")
	check_eq(int(presets.get_value(web + ".options", "progressive_web_app/orientation")), 2, "the Web app installs in portrait")
	check_eq(presets.get_value(web, "export_path"), "build/web/index.html", "Web exports to build/web/index.html")
	check_eq(presets.get_value(web + ".options", "variant/thread_support"), false, "Web does not depend on threads (GDD 135)")
	check_eq(presets.get_value(android, "export_path"), "build/android/CatchAndBrawl.aab", "Android exports the App Bundle")
	check_eq(presets.get_value(android + ".options", "package/unique_name"), "com.catchandbrawl.game", "application ID")
	check_eq(presets.get_value(android + ".options", "gradle_build/export_format"), 1, "AAB format")
	check(int(presets.get_value(android + ".options", "gradle_build/target_sdk")) >= 36, "target SDK 36 or newer")
	check_eq(int(presets.get_value(android + ".options", "gradle_build/min_sdk")), 24, "minimum SDK 24")
	check(presets.get_value(android + ".options", "architectures/arm64-v8a"), "arm64-v8a")
	# Revision 6.11: low-end phones that run 32-bit Android install it too.
	check(presets.get_value(android + ".options", "architectures/armeabi-v7a"), "armeabi-v7a")
	check(not presets.get_value(android + ".options", "architectures/x86_64") and not presets.get_value(android + ".options", "architectures/x86"), "no x86 in the store build")
	# An APK for quick installs over USB, same package and filters as the AAB.
	check(by_name.has("Android APK (test)"), "an APK preset for testing on a phone")
	var apk: String = by_name.get("Android APK (test)", "")
	if apk != "":
		check_eq(int(presets.get_value(apk + ".options", "gradle_build/export_format")), 0, "it exports an APK")
		check_eq(presets.get_value(apk, "export_path"), "build/android/CatchAndBrawl-test.apk", "into build/android")
		check_eq(presets.get_value(apk + ".options", "package/unique_name"), "com.catchandbrawl.game", "same application ID")
		check_eq(presets.get_value(apk, "exclude_filter"), presets.get_value(android, "exclude_filter"), "same package contents")
	# Signing details never live in the repository; release builds read them
	# from GODOT_ANDROID_KEYSTORE_RELEASE_* environment variables.
	for section: String in presets.get_sections():
		for key: String in presets.get_section_keys(section):
			if key.begins_with("keystore/"):
				check_eq(str(presets.get_value(section, key)), "", "%s %s is empty" % [presets.get_value(section.trim_suffix(".options"), "name", section), key])
	for key: String in presets.get_section_keys(android + ".options"):
		if key.begins_with("permissions/") and key != "permissions/custom_permissions":
			check(not bool(presets.get_value(android + ".options", key)), "no %s" % key)
	check((presets.get_value(android + ".options", "permissions/custom_permissions") as PackedStringArray).is_empty(), "no custom permission")
	for section: String in [web, android, ios]:
		check(str(presets.get_value(section, "include_filter")).contains("data/story/*.json"), "%s packs the story timelines" % presets.get_value(section, "name"))
		check(str(presets.get_value(section, "include_filter")).contains("assets/fonts/*.txt"), "%s packs the font licences" % presets.get_value(section, "name"))
		var excluded := str(presets.get_value(section, "exclude_filter"))
		for folder: String in ["tests/*", "tools/*", "docs/*", "generated/references/*"]:
			check(excluded.contains(folder), "%s leaves out %s" % [presets.get_value(section, "name"), folder])
	return true


# GDD 186.2: Semantic Versioning, and the Android version follows it.
func test_version_is_semantic() -> bool:
	var version := str(ProjectSettings.get_setting("application/config/version"))
	var pattern := RegEx.create_from_string("^\\d+\\.\\d+\\.\\d+(-rc\\.\\d+)?$")
	check(pattern.search(version) != null, "project version %s is MAJOR.MINOR.PATCH[-rc.N]" % version)
	var presets := ConfigFile.new()
	presets.load("res://export_presets.cfg")
	for section: String in presets.get_sections():
		if section.ends_with(".options") and presets.has_section_key(section, "version/name"):
			check_eq(presets.get_value(section, "version/name"), version, "Android versionName matches the project")
		if section.ends_with(".options") and presets.has_section_key(section, "application/short_version"):
			# The App Store takes only MAJOR.MINOR.PATCH.
			check_eq(presets.get_value(section, "application/short_version"), version.get_slice("-", 0), "iOS short version matches the project")
	return true


# GDD 191.6, 191.7: secrets and build output stay out of the repository.
func test_repository_ignores_build_output_and_secrets() -> bool:
	var ignore := FileAccess.get_file_as_string("res://.gitignore")
	for entry: String in [".godot/", "build/web/", "build/android/", "build/ios/", "build/itch/", "*.keystore", "*.jks", "*.p12", "*.mobileprovision", ".env"]:
		check(ignore.contains(entry), ".gitignore covers %s" % entry)
	var keystores := PackedStringArray()
	for path: String in _files(["res://"], ["keystore", "jks"]):
		keystores.append(path)
	check_empty(keystores, "no keystore inside the project")
	return true


func _files(roots: Array[String], extensions: Array) -> PackedStringArray:
	var found := PackedStringArray()
	var pending: Array[String] = roots.duplicate()
	while not pending.is_empty():
		var dir_path: String = pending.pop_back()
		var dir := DirAccess.open(dir_path)
		if dir == null:
			continue
		for sub: String in dir.get_directories():
			if sub.begins_with(".") or sub == "build" or sub == "android":
				continue
			pending.append(dir_path.path_join(sub))
		for file: String in dir.get_files():
			if extensions.has(file.get_extension()):
				found.append(dir_path.path_join(file))
	return found
