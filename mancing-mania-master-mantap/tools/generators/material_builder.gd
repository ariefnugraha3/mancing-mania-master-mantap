@tool
extends RefCounted
## Generates the small set of shared materials (GDD 102, 184.10).
## Detail comes from geometry and vertex colour, so almost everything in the
## game renders with `mat_vertex_color`; the rest are special-purpose.

const GeneratorIo := preload("res://tools/generators/generator_io.gd")

const GENERATOR_ID := "material_builder"
const GENERATOR_VERSION := 1

const VERTEX_COLOR := "res://generated/materials/mat_vertex_color.tres"
const FOLIAGE_SWAY := "res://generated/materials/mat_foliage_sway.tres"
const GRASS_SWAY := "res://generated/materials/mat_grass_sway.tres"
const LAKE_WATER := "res://generated/materials/mat_lake_water.tres"
const WATER_SHADOW := "res://generated/materials/mat_water_shadow.tres"
const WATER_RIPPLE := "res://generated/materials/mat_water_ripple.tres"
const FISHING_LINE := "res://generated/materials/mat_fishing_line.tres"

const FOLIAGE_SHADER := "res://shaders/foliage_sway.gdshader"
const WATER_SHADER := "res://shaders/lake_water.gdshader"


func build(manifest: RefCounted) -> PackedStringArray:
	var errors := PackedStringArray()
	var outputs: Dictionary[String, Resource] = {
		VERTEX_COLOR: _vertex_color(),
		FOLIAGE_SWAY: _foliage(0.035, 0.9, 5.0),
		GRASS_SWAY: _foliage(0.06, 1.3, 0.6),
		LAKE_WATER: _lake_water(),
		WATER_SHADOW: _flat_transparent(Color(0.09, 0.13, 0.13, 0.5)),
		WATER_RIPPLE: _flat_transparent(Color(1.0, 0.97, 0.9, 0.7)),
		FISHING_LINE: _flat_transparent(Color(0.97, 0.95, 0.9, 0.85)),
	}
	for path: String in outputs:
		var save_error := GeneratorIo.save_text_resource(outputs[path], path)
		if save_error != OK:
			errors.append("%s: could not save (%s)" % [path.get_file(), error_string(save_error)])
		else:
			manifest.register(path.get_file().get_basename(), GENERATOR_ID, GENERATOR_VERSION, 0, path)
	return errors


## Matte, vertex-coloured surface used by characters, fish, props and terrain.
func _vertex_color() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.metallic = 0.0
	material.metallic_specular = 0.25
	return material


func _foliage(amount: float, speed: float, height: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(FOLIAGE_SHADER)
	material.set_shader_parameter(&"sway_amount", amount)
	material.set_shader_parameter(&"sway_speed", speed)
	material.set_shader_parameter(&"sway_height", height)
	return material


func _lake_water() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(WATER_SHADER)
	return material


## Unshaded see-through colour for fish shadows, ripples and the fishing line.
func _flat_transparent(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = tint
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = false
	return material
