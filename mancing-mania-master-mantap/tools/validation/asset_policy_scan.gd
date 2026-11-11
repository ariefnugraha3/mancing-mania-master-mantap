extends RefCounted
## Zero-internet-asset gate (GDD 175.17, 184.16).
##
## Walks the project and reports every file that breaks the asset policy:
##   - audio media of any kind (all sound is synthesized from code);
##   - font files (v1.0 uses the engine's built-in font only);
##   - images and 3D models that are not outputs listed in the generator
##     manifest, i.e. anything that did not come out of this repository's
##     own generators.

const Manifest := preload("res://tools/generators/generator_manifest.gd")

const AUDIO_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3", "flac", "aac", "m4a", "opus", "aiff", "wma"]
const FONT_EXTENSIONS: Array[String] = ["ttf", "otf", "woff", "woff2", "fnt", "ttc"]
const IMAGE_EXTENSIONS: Array[String] = ["png", "jpg", "jpeg", "webp", "svg", "bmp", "tga", "gif", "exr", "hdr", "dds", "ktx"]
const MODEL_EXTENSIONS: Array[String] = ["glb", "gltf", "fbx", "obj", "blend", "dae"]

## Build output and engine caches are not source assets.
const SKIPPED_DIRECTORIES: Array[String] = [".godot", ".git", ".import", "build", "export", "android"]


## Returns one message per violation under `root`; empty means the tree is clean.
static func scan(root: String = "res://", manifest_path: String = Manifest.MANIFEST_PATH) -> PackedStringArray:
	var generated := PackedStringArray()
	var manifest := Manifest.read(manifest_path)
	if manifest != null:
		generated = manifest.get_outputs()
	var violations := PackedStringArray()
	_scan_directory(root, generated, violations)
	return violations


static func _scan_directory(path: String, generated: PackedStringArray, violations: PackedStringArray) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		violations.append("cannot open directory: %s" % path)
		return
	directory.include_hidden = true

	for file_name: String in directory.get_files():
		var file_path := path.path_join(file_name)
		var extension := file_name.get_extension().to_lower()
		if AUDIO_EXTENSIONS.has(extension):
			violations.append("audio file is forbidden (all audio is procedural): %s" % file_path)
		elif FONT_EXTENSIONS.has(extension):
			violations.append("font file is forbidden (built-in font only): %s" % file_path)
		elif IMAGE_EXTENSIONS.has(extension) and not generated.has(file_path):
			violations.append("image is not a generator output listed in the manifest: %s" % file_path)
		elif MODEL_EXTENSIONS.has(extension) and not generated.has(file_path):
			violations.append("3D model is not a generator output listed in the manifest: %s" % file_path)

	for child: String in directory.get_directories():
		if not SKIPPED_DIRECTORIES.has(child):
			_scan_directory(path.path_join(child), generated, violations)
