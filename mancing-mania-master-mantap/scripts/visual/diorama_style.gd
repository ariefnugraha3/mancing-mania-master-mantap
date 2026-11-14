class_name DioramaStyle
extends RefCounted
## The one source of the warm diorama look (VISUAL_STYLE_GUIDE.md, GDD 99-103).
##
## Palette, camera profile, light rig, fake-shadow and motion numbers live here
## so the runtime scenes and the asset generators can never drift apart. The
## values are the guide's; colours marked "derived" are this game's own
## additions, picked from the guide's rules (warm, pastel greens and blues).

# --- Palette (guide 5.2) -----------------------------------------------------

const SUN_GOLD := Color("ffe3a8")        # sunlight and ambient
const LAMP_WARM := Color("ffaa44")       # interior warming lamps
const VANILLA := Color("f5e6ca")         # screen background
const FLOUR := Color("fffbf5")           # cloth, apron, paper
const CRUST := Color("d9822b")           # golden crust
const CARAMEL := Color("8c4a1e")
const COCOA := Color("5a2e12")           # dark lines, old wood
const BUTTER := Color("fce38a")
const CUSTARD := Color("f9d371")
const PINE := Color("c99a62")            # varnished pine
const TERRACOTTA := Color("c4693d")      # terracotta tile
const STRAWBERRY := Color("ffb7b2")
const MINT := Color("b5ead7")
const PERIWINKLE := Color("c7ceea")
const BLUSH := Color("ff9aa2")           # character cheeks
const GOLD := Color("f5b301")            # accent gold
const SHADOW := Color(75.0 / 255.0, 45.0 / 255.0, 27.0 / 255.0, 0.30)

# Derived for the lake (warm pastel greens and blues only).
const GRASS := Color("a3cc94")
const GRASS_LIGHT := Color("b6d49e")
const GRASS_DEEP := Color("86b884")
const LEAF := Color("94c48c")
const LEAF_LIGHT := Color("afd39a")
const LEAF_DEEP := Color("74a97c")
const SAND := Color("eedcbc")
const SOIL := Color("cfa57a")
const SOIL_DEEP := Color("a8774e")
const WATER_SHALLOW := Color("acdcdf")
const WATER := Color("93cdd6")
const WATER_DEEP := Color("7dbbcc")
const WATER_LINE := Color("eef8f6")
const STONE := Color("d6cab6")
const STONE_DEEP := Color("b9aa92")
const ROAD := Color("cbbfae")
const REED := Color("a9c88a")
const BARK := Color("9c6b45")
const INK := Color("3b2a20")             # eyes and small face lines
const EYE_SHINE := Color("fffbf5")

## How far the surroundings are pulled toward the background, so the
## playable diorama stays the centre of attention (guide 5.2, 7).
const SURROUNDING_MUTE := 0.22

# --- Camera (guide 2) --------------------------------------------------------

const CAMERA_YAW_DEG := 45.0
const CAMERA_PITCH_DEG := 35.0
const CAMERA_DISTANCE := 30.0
const CAMERA_NEAR := 0.05
const CAMERA_FAR := 200.0
## Visible world width in metres (KEEP_WIDTH). 6.8 is the default; scenes may
## frame between ZOOM_MIN and ZOOM_MAX in ZOOM_STEP steps.
const WIDTH_DEFAULT := 6.8
const ZOOM_MIN := 5.6
const ZOOM_MAX := 11.0
const ZOOM_STEP := 0.6
## A crossfade to the background colour replaces any camera travel.
const CROSSFADE_SEC := 0.20

# --- World scale (guide 3) ---------------------------------------------------

const TILE := 0.5
const CHARACTER_HEIGHT := 0.90
const COUNTER_TOP := 0.42
const CHEST_LINE := 0.44
const WALL_THICKNESS := 0.10
const LOW_WALL := 0.16
const ZONE_DIVIDER := 0.62
const WALL_HEIGHTS: Array[float] = [1.80, 2.00, 2.05, 2.30, 2.50]
const WINDOW_WIDTH := 0.78

# --- Light rig (guide 6.1) ---------------------------------------------------

const AMBIENT_ENERGY := 0.55
const TONEMAP_WHITE := 1.2
const SUN_ENERGY := 0.95
const SUN_ROTATION_DEG := Vector3(-52.0, -135.0, 0.0)
const LAMP_ENERGY := 0.55
## One interior lamp per this many square metres of floor (at least one).
const LAMP_FLOOR_AREA := 9.0
const LAMP_HEIGHT_RATIO := 0.9

# --- Fake shadows (guide 6.2) ------------------------------------------------

const CHARACTER_SHADOW_RADIUS := 0.20
const CHARACTER_SHADOW_SEGMENTS := 14
const CHARACTER_SHADOW_ALPHA := 0.30
const CHARACTER_SHADOW_Y := 0.004
const FURNITURE_SHADOW_SEGMENTS := 24
const FURNITURE_SHADOW_ALPHA := 0.42
const FURNITURE_SHADOW_SCALE := 1.5
const FURNITURE_SHADOW_Y := 0.006

# --- Procedural motion (guide 10) --------------------------------------------

const BREATH_RAD_PER_SEC := 1.35
const BREATH_BOB := 0.012
const BREATH_ARM_SWING := 0.05
const SQUASH_AMOUNT := 0.12
const SQUASH_SEC := 0.32

# --- Materials (guide 5.1) ---------------------------------------------------

const ROUGHNESS := 0.85
const ROUGHNESS_ROUND := 0.9


## The standard material of the guide, word for word. Every opaque surface in
## the game uses one of a handful of shared instances of it.
static func material(tint: Color = Color.WHITE, rough: float = ROUGHNESS, metal: float = 0.0, emis: Color = Color.BLACK) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	made.albedo_color = tint
	made.roughness = rough
	made.metallic = metal
	made.metallic_specular = 0.5
	made.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	made.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	made.cull_mode = BaseMaterial3D.CULL_BACK
	made.vertex_color_use_as_albedo = true
	made.vertex_color_is_srgb = true
	made.emission_enabled = emis != Color.BLACK
	if made.emission_enabled:
		made.emission = emis
	return made


## Thin glass, ripples and fake shadows: unshaded and transparent, never a
## lit transparent material (the slowest shader to compile in a browser).
static func unshaded_transparent(tint: Color = Color.WHITE, use_vertex_color: bool = true) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	made.albedo_color = tint
	made.cull_mode = BaseMaterial3D.CULL_DISABLED
	made.vertex_color_use_as_albedo = use_vertex_color
	made.vertex_color_is_srgb = true
	return made


## A surrounding colour pulled toward the background (guide 5.2).
static func muted(tint: Color, amount: float = SURROUNDING_MUTE) -> Color:
	var grey := tint.get_luminance()
	return tint.lerp(Color(grey, grey, grey), amount * 0.35).lerp(VANILLA, amount)


## Where the camera sits relative to what it looks at (guide 2.2).
static func camera_offset() -> Vector3:
	var yaw := deg_to_rad(CAMERA_YAW_DEG)
	var pitch := deg_to_rad(CAMERA_PITCH_DEG)
	return Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch)) * CAMERA_DISTANCE


## Screen-right as a world direction on the floor (guide 2.2).
static func screen_right() -> Vector3:
	return Vector3(-1.0, 0.0, 1.0).normalized()


## Screen-up (into the picture) as a world direction on the floor.
static func screen_in() -> Vector3:
	return Vector3(1.0, 0.0, 1.0).normalized()


## Snaps a requested frame width onto the guide's zoom steps
## (5.6, 6.2, 6.8 ... 11.0).
static func clamp_width(width: float) -> float:
	var stepped := ZOOM_MIN + roundf((width - ZOOM_MIN) / ZOOM_STEP) * ZOOM_STEP
	return clampf(stepped, ZOOM_MIN, ZOOM_MAX)


# --- Time of day (guide 6.3) ---------------------------------------------------

## Keyframes: hour, sun colour, sun energy, sun elevation (deg), ambient
## colour, ambient energy, interior lamp energy, background.
const DAYLIGHT: Array = [
	[5.0, Color("ffb98a"), 0.34, 24.0, Color("e8c3bd"), 0.46, 0.95, Color("e3cdbb")],
	[8.0, Color("ffecd0"), 0.92, 48.0, Color("fcead2"), 0.56, 0.55, Color("f6e8cf")],
	[12.0, Color("ffeed4"), 0.97, 58.0, Color("ffecd2"), 0.57, 0.50, Color("f7e9d0")],
	[15.0, Color("ffe3a8"), 0.95, 52.0, Color("ffe3a8"), 0.55, 0.55, Color("f5e6ca")],
	[17.6, Color("ffb276"), 0.64, 28.0, Color("f4c9a8"), 0.48, 0.80, Color("e9cdb2")],
	[18.0, Color("f89c74"), 0.44, 20.0, Color("dcb6b3"), 0.45, 0.95, Color("dcc0b0")],
]
## The game's Sunday afternoon (GDD 5): the guide's default 15:00 light.
const HOUR_DEFAULT := 15.0
const HOUR_GOLDEN := 17.6
const HOUR_DUSK := 18.0


## The light at `hour`, smoothstepped between keyframes. Only colours,
## energies and the sun's elevation change: materials stay the same.
static func daylight(hour: float) -> Dictionary:
	var first: Array = DAYLIGHT[0]
	var last: Array = DAYLIGHT[DAYLIGHT.size() - 1]
	var from: Array = first
	var to: Array = first
	var weight := 0.0
	if hour >= float(last[0]):
		from = last
		to = last
	elif hour > float(first[0]):
		for index: int in DAYLIGHT.size() - 1:
			var a: Array = DAYLIGHT[index]
			var b: Array = DAYLIGHT[index + 1]
			if hour >= float(a[0]) and hour <= float(b[0]):
				from = a
				to = b
				weight = smoothstep(0.0, 1.0, inverse_lerp(float(a[0]), float(b[0]), hour))
				break
	return {
		"sun_color": (from[1] as Color).lerp(to[1], weight),
		"sun_energy": lerpf(from[2], to[2], weight),
		"sun_elevation": lerpf(from[3], to[3], weight),
		"ambient_color": (from[4] as Color).lerp(to[4], weight),
		"ambient_energy": lerpf(from[5], to[5], weight),
		"lamp_energy": lerpf(from[6], to[6], weight),
		"background": (from[7] as Color).lerp(to[7], weight),
	}


## Applies the light of `hour` to every light rig under `root`. The sun keeps
## its -135 deg heading; only its elevation moves.
static func apply_daylight(root: Node, hour: float) -> void:
	if root == null:
		return
	var light := daylight(hour)
	for node: Node in root.find_children("*", "WorldEnvironment", true, false):
		var environment := (node as WorldEnvironment).environment
		if environment == null:
			continue
		environment = environment.duplicate()
		(node as WorldEnvironment).environment = environment
		environment.background_color = light["background"]
		environment.ambient_light_color = light["ambient_color"]
		environment.ambient_light_energy = light["ambient_energy"]
	for node: Node in root.find_children("*", "DirectionalLight3D", true, false):
		var sun := node as DirectionalLight3D
		sun.light_color = light["sun_color"]
		sun.light_energy = light["sun_energy"]
		sun.rotation_degrees = Vector3(-float(light["sun_elevation"]), SUN_ROTATION_DEG.y, 0.0)
	for node: Node in root.find_children("*", "OmniLight3D", true, false):
		(node as OmniLight3D).light_energy = light["lamp_energy"]
