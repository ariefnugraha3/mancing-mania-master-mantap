@tool
extends RefCounted
## Generates the small set of shared materials (VISUAL_STYLE_GUIDE 5.1,
## GDD 102, 184.10).
##
## Detail comes from geometry and vertex colour, so almost everything renders
## with `mat_vertex_color` (roughness 0.85) or `mat_vertex_color_round` (0.9,
## for spheres and capsules: characters and fish). The rest are the few
## special cases the guide allows: soft metal, things that really glow, and
## unshaded transparent surfaces for glass, ripples, the line and fake shadows.
## No custom shader is used in the 3D world.

const GeneratorIo := preload("res://tools/generators/generator_io.gd")
const SoftMesh := preload("res://tools/generators/soft_mesh.gd")
const Style := preload("res://scripts/visual/diorama_style.gd")

const GENERATOR_ID := "material_builder"
const GENERATOR_VERSION := 2

const VERTEX_COLOR := "res://generated/materials/mat_vertex_color.tres"
const VERTEX_COLOR_ROUND := "res://generated/materials/mat_vertex_color_round.tres"
const METAL := "res://generated/materials/mat_metal_soft.tres"
const GLOW := "res://generated/materials/mat_glow_warm.tres"
const GLASS := "res://generated/materials/mat_glass.tres"
const FAKE_SHADOW := "res://generated/materials/mat_fake_shadow.tres"
const WATER_SHADOW := "res://generated/materials/mat_water_shadow.tres"
const WATER_RIPPLE := "res://generated/materials/mat_water_ripple.tres"
const FISHING_LINE := "res://generated/materials/mat_fishing_line.tres"
## The two shared fake-shadow discs (guide 6.2), unit radius.
const SHADOW_CHARACTER_MESH := "res://generated/meshes/mesh_shadow_character.tres"
const SHADOW_FURNITURE_MESH := "res://generated/meshes/mesh_shadow_furniture.tres"

## Surface keys used by the mesh builders, one per shared material.
const SURFACE_SOLID := "solid"
const SURFACE_ROUND := "round"
const SURFACE_METAL := "metal"
const SURFACE_GLOW := "glow"
const SURFACE_GLASS := "glass"


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var outputs: Dictionary[String, Resource] = {
		VERTEX_COLOR: Style.material(Color.WHITE, Style.ROUGHNESS),
		VERTEX_COLOR_ROUND: Style.material(Color.WHITE, Style.ROUGHNESS_ROUND),
		METAL: Style.material(Color.WHITE, 0.55, 0.45),
		GLOW: Style.material(Color.WHITE, Style.ROUGHNESS, 0.0, Style.LAMP_WARM),
		GLASS: _glass(),
		FAKE_SHADOW: _fake_shadow(),
		WATER_SHADOW: Style.unshaded_transparent(Color(0.33, 0.45, 0.45, 0.42), false),
		WATER_RIPPLE: Style.unshaded_transparent(Color(1.0, 0.98, 0.94, 0.75), false),
		FISHING_LINE: Style.unshaded_transparent(Color(1.0, 0.98, 0.94, 0.9), false),
	}
	for path: String in outputs:
		var save_error := GeneratorIo.save_text_resource(outputs[path], path)
		if save_error != OK:
			errors.append("%s: could not save (%s)" % [path.get_file(), error_string(save_error)])
		else:
			manifest.register(path.get_file().get_basename(), GENERATOR_ID, GENERATOR_VERSION, 0, path)

	# The shadow discs reference the saved shadow material, so they come after.
	var shadow_material: Material = load(FAKE_SHADOW)
	for spec: Array in [
		[SHADOW_CHARACTER_MESH, Style.CHARACTER_SHADOW_SEGMENTS, Style.CHARACTER_SHADOW_ALPHA],
		[SHADOW_FURNITURE_MESH, Style.FURNITURE_SHADOW_SEGMENTS, Style.FURNITURE_SHADOW_ALPHA],
	]:
		var path: String = spec[0]
		var builder := SoftMesh.new()
		var dark := Style.SHADOW
		dark.a = spec[2]
		var clear := dark
		clear.a = 0.0
		builder.disc(Vector3.ZERO, 1.0, spec[1], dark, clear, 2)
		var save_error := GeneratorIo.save_text_resource(builder.commit({SoftMesh.DEFAULT_SURFACE: shadow_material}), path)
		if save_error != OK:
			errors.append("%s: could not save (%s)" % [path.get_file(), error_string(save_error)])
		else:
			manifest.register(path.get_file().get_basename(), GENERATOR_ID, GENERATOR_VERSION, 0, path)
	return errors


## The materials a builder hands to SoftMesh.commit(), by surface key.
static func surface_materials() -> Dictionary:
	return {
		SURFACE_SOLID: load(VERTEX_COLOR),
		SURFACE_ROUND: load(VERTEX_COLOR_ROUND),
		SURFACE_METAL: load(METAL),
		SURFACE_GLOW: load(GLOW),
		SURFACE_GLASS: load(GLASS),
	}


## Thin glass: unshaded, see-through, tinted by vertex colour (guide 5.1).
func _glass() -> StandardMaterial3D:
	var glass := Style.unshaded_transparent(Color(1.0, 1.0, 1.0, 0.38), true)
	glass.cull_mode = BaseMaterial3D.CULL_BACK
	return glass


## A soft dark disc on the floor (guide 6.2); the fade lives in vertex alpha.
func _fake_shadow() -> StandardMaterial3D:
	var shadow := Style.unshaded_transparent(Color.WHITE, true)
	shadow.cull_mode = BaseMaterial3D.CULL_BACK
	shadow.render_priority = -1
	return shadow
