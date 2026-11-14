extends SceneTree
## Entry point of the zero-internet asset pipeline (GDD 184.2).
##
## Run from the project folder:
##   godot --headless --path . --import
##   godot --headless --path . --script res://tools/generators/generate_all_assets.gd
##   godot --headless --path . --import
##
## The first import registers script classes on a fresh checkout; the last one
## lets the editor import any new image output. Generation
## happens at editor time or in release preparation only; the shipped game just
## loads the files under res://generated/.

const Manifest := preload("res://tools/generators/generator_manifest.gd")
const Validation := preload("res://tools/generators/generator_validation.gd")

## Builders run in this order. Each milestone that needs new generated content
## adds its builder here (meshes, characters, fish, props, environment...).
const BUILDERS: Array[String] = [
	"res://tools/generators/material_builder.gd",
	"res://tools/generators/ui_art_builder.gd",
	"res://tools/generators/prop_builder.gd",
	"res://tools/generators/fish_builder.gd",
	"res://tools/generators/character_builder.gd",
	"res://tools/generators/environment_builder.gd",
]

## Reference sheets need a graphics device and are rendered by a separate run
## (reference_sheet_generator.gd); their manifest records are carried over.
const REFERENCE_GENERATOR := "reference_sheet_generator"


func _initialize() -> void:
	# A script error aborts _generate() and hands back null instead of an exit
	# code; treating that as failure guarantees the process always ends.
	var exit_code: Variant = _generate()
	quit(exit_code if typeof(exit_code) == TYPE_INT else 1)


func _generate() -> int:
	var manifest := Manifest.new()
	manifest.adopt(Manifest.read(), REFERENCE_GENERATOR)
	var errors := PackedStringArray()

	for builder_path: String in BUILDERS:
		var script := load(builder_path) as GDScript
		if script == null or not script.can_instantiate():
			errors.append("builder failed to compile: %s (run --import first?)" % builder_path)
			continue
		var builder: RefCounted = script.new()
		print("[GEN] %s" % builder_path.get_file())
		errors.append_array(builder.build(manifest))

	if not manifest.write():
		errors.append("could not write %s" % Manifest.MANIFEST_PATH)
	errors.append_array(Validation.validate())

	for asset_id: String in manifest.get_asset_ids():
		print("[GEN]   %s -> %s" % [asset_id, manifest.get_entry(asset_id)["output"]])
	for message: String in errors:
		push_error("[GEN] %s" % message)
	print("[GEN] %d assets, %d errors" % [manifest.get_asset_ids().size(), errors.size()])
	return 1 if not errors.is_empty() else 0
