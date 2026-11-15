class_name IconPainter
extends RefCounted
## Procedural UI icons drawn straight into a canvas item (GDD 174.10, 184.11).
## No icon image exists anywhere in the project.
##
## Revision 6.4 ("sticker" icons): every icon is a small full-colour
## illustration in the cozy warung style, built from parts on a 24-unit grid.
## Each part gets, automatically:
##   - a thick cocoa outline around the whole silhouette and a thinner one
##     where it overlaps the parts under it, like a cartoon sticker;
##   - a darker lip along its bottom edge, the same depth language as the
##     lipped buttons;
##   - a soft cream rim of light along its top-left edge.
## The geometry is worked out once per icon with Geometry2D and cached, so
## painting is a replay of plain polygons and lines.
##
## Icons keep their own colours. The colour passed to paint() multiplies them
## (white leaves them as drawn); a faded colour (alpha below 1, a disabled
## button) draws a muted, washed-out version instead of a see-through one.
## UiIcon (a Control), IconTexture (a Texture2D for Button.icon) and MoveIcon
## all paint through here, so an icon looks the same everywhere.

const CASH := &"ui_icon_cash"
const BUCKET := &"ui_icon_bucket"
const MARKET := &"ui_icon_market"
const PAUSE := &"ui_icon_pause"
const WARNING := &"ui_icon_warning"
const ROD := &"ui_icon_rod"
const PLAY := &"ui_icon_play"
const SPARKLE := &"ui_icon_sparkle"
const BOOK := &"ui_icon_book"
const GEAR := &"ui_icon_gear"
const HEART := &"ui_icon_heart"
const BACK := &"ui_icon_back"
const CLOSE := &"ui_icon_close"
const MUSIC := &"ui_icon_music"
const SOUND := &"ui_icon_sound"
const DOOR := &"ui_icon_door"
const CHECK := &"ui_icon_check"
const KEYS := &"ui_icon_keys"
const FISH := &"ui_icon_fish"
const LEDGER := &"ui_icon_ledger"
const ARROW_UP := &"ui_icon_arrow_up"
const TROPHY := &"ui_icon_trophy"
const RETRY := &"ui_icon_retry"
const SHIELD := &"ui_icon_shield"
const ARROW_LEFT := &"ui_icon_arrow_left"
const ARROW_RIGHT := &"ui_icon_arrow_right"
const GLOVE := &"ui_icon_glove"
const HAND := &"ui_icon_hand"
## Suwit hands (MoveIcon).
const ROCK := &"ui_icon_rock"
const SCISSORS := &"ui_icon_scissors"
const PAPER := &"ui_icon_paper"
const ARROW_DOWN := &"ui_icon_arrow_down"
const MAP := &"ui_icon_map"
## The game's round emblem above the title (revision 6.8).
const EMBLEM := &"ui_logo_emblem"

## Every icon, for tests and previews.
const ALL: Array[StringName] = [
	CASH, BUCKET, MARKET, PAUSE, WARNING, ROD, PLAY, SPARKLE, BOOK, GEAR, HEART, BACK, CLOSE, MUSIC,
	SOUND, DOOR, CHECK, KEYS, FISH, LEDGER, ARROW_UP, TROPHY, RETRY, SHIELD, ARROW_LEFT, ARROW_RIGHT,
	GLOVE, HAND, ROCK, SCISSORS, PAPER, ARROW_DOWN, MAP, EMBLEM,
]

# Line weights and depth, in grid units (1/24 of the icon).
const OUTLINE := 1.5      # around the whole silhouette
const INNER := 0.8        # where a part sits on another part
const LIP := 1.3          # darker band under each part
const SHINE_INSET := 1.0  # how far the rim light sits inside the edge
const SHINE_SHIFT := Vector2(0.9, 1.15)
## Width of the anti-aliasing edge drawn around each filled polygon, in
## canvas units (polygons themselves are not anti-aliased).
const EDGE_WIDTH := 0.9

# Icon palette: the UI tokens plus a few diorama colours (VISUAL_STYLE_GUIDE.md).
const INK := UiTokens.INK_900
const CREAM := UiTokens.CREAM_50
const PAPER_CREAM := UiTokens.CREAM_100
const GOLD := UiTokens.SUN_500
const CRUST := UiTokens.TERRACOTTA_500
const RED := UiTokens.RED_500
const TEAL := UiTokens.LAKE_500
const GREEN := UiTokens.GRASS_500
const BLUE := UiTokens.BLUE_400
const STEEL := DioramaStyle.PERIWINKLE
const WOOD := DioramaStyle.PINE
const WOOD_DARK := DioramaStyle.BARK
const PINK := DioramaStyle.BLUSH
const SKIN := Color("e8bd95")
const SLEEVE := UiTokens.LAKE_500
# The emblem's own palette: a sunset over the lake and an orange fish.
const EMBLEM_RING := UiTokens.TERRACOTTA_500
const EMBLEM_STITCH := Color("fff4d6")
const EMBLEM_SKY := Color("ffe5a0")
const EMBLEM_SKY_LIGHT := Color("fff6d8")
const EMBLEM_SUN_CORE := Color("ffd774")
const EMBLEM_WATER := Color("6fb7ae")
const EMBLEM_WATER_DEEP := Color("5ca39b")
const EMBLEM_RIPPLE := Color("dcf2ee")
const EMBLEM_SPLASH := Color("c4e8e2")
const EMBLEM_FISH := Color("f58b48")
const EMBLEM_FIN := Color("d95f3b")
const EMBLEM_BELLY := Color("ffd3a3")
## Where the emblem's fish sits: its own frame (nose toward +X), turned up
## as it leaps.
const EMBLEM_FISH_FRAME := Transform2D(-0.36, Vector2(1.06, 1.06), 0.0, Vector2(11.5, 11.7))

# Geometry2D works on fixed-point coordinates; the grid is scaled up while
# clipping so curves and round joins stay smooth.
const GEOMETRY_SCALE := 32.0

enum { CMD_POLYGON, CMD_LINE }

static var _cache: Dictionary = {}
## Icons whose geometry closed a hole (a gap narrower than the outline, which
## would be filled solid). Tests require this to stay empty.
static var _holes: Dictionary = {}
static var _building: StringName = &""

var _layers: Array[Dictionary] = []


## Paints icon `id` into `rect` of the canvas item `item`. `color` multiplies
## the icon's own colours; alpha below 1 draws it muted (disabled).
static func paint(item: RID, id: StringName, rect: Rect2, color: Color = Color.WHITE) -> void:
	var unit := minf(rect.size.x, rect.size.y) / 24.0
	if unit <= 0.0:
		return
	var origin := rect.position + (rect.size - Vector2(24.0, 24.0) * unit) * 0.5
	var transform := Transform2D(0.0, Vector2(unit, unit), 0.0, origin)
	var muted := color.a < 0.99
	for command: Array in commands_for(id):
		var tone: Color = command[2]
		tone = _muted(tone, color.a) if muted else tone
		tone = Color(tone.r * color.r, tone.g * color.g, tone.b * color.b, tone.a)
		var points: PackedVector2Array = transform * (command[1] as PackedVector2Array)
		if command[0] == CMD_POLYGON:
			# Triangulated once at compile time: a scale and a shift keep the
			# triangles valid, and tiny icons never fail to triangulate.
			RenderingServer.canvas_item_add_triangle_array(item, command[3], points, PackedColorArray([tone]))
			points.append(points[0])
			RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([tone]), EDGE_WIDTH, true)
		else:
			if command[4]:
				points.append(points[0])
			RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([tone]), float(command[3]) * unit, true)


## The cached draw list of an icon. A polygon is [CMD_POLYGON, points, colour,
## triangle indices]; a line is [CMD_LINE, points, colour, width, closed].
static func commands_for(id: StringName) -> Array:
	if not _cache.has(id):
		_building = id
		var builder := IconPainter.new()
		builder._design(id)
		_cache[id] = builder._compile()
		_building = &""
	return _cache[id]


## Icons whose shapes enclosed a hole while being built (see _outers).
static func icons_with_holes() -> PackedStringArray:
	for id: StringName in ALL:
		commands_for(id)
	return PackedStringArray(_holes.keys())


static func _muted(tone: Color, alpha: float) -> Color:
	var grey := tone.get_luminance()
	var washed := Color(grey, grey, grey).lerp(tone, 0.3)
	return washed.lerp(UiTokens.PAPER_200, clampf(1.0 - alpha, 0.0, 1.0) * 0.9)


# --- Icon designs (24-unit grid, y down) ---------------------------------------

func _design(id: StringName) -> void:
	match id:
		PLAY:
			_part(_circle(Vector2(12, 12), 10.0), GOLD, 1.6)
			_part(_rounded(_poly([9.4, 6.6, 17.6, 12, 9.4, 17.4]), 1.6), CREAM, 0.9, false)
		SPARKLE:
			_part(_sparkle(Vector2(10.0, 13.2), 10.2), GOLD, 1.5)
			_part(_sparkle(Vector2(18.9, 5.2), 4.8), DioramaStyle.BUTTER, 0.0)
			_part(_circle(Vector2(19.4, 17.8), 1.8), DioramaStyle.BUTTER, 0.0, false)
		BOOK:
			_design_book()
		GEAR:
			_part(_gear(Vector2(12, 12), 8, 7.8, 10.8), BLUE)
			_part(_circle(Vector2(12, 12), 3.7), GOLD, 0.9)
		HEART:
			_part(_heart(Vector2(12, 12.4), 0.64), RED, 1.6)
			_flat(_ellipse(Vector2(7.6, 7.8), 1.9, 1.3, -0.6), CREAM)
		CHECK:
			_part(_stroke(_poly([4.4, 12.6, 9.8, 18, 19.8, 6.0]), 4.8), GREEN)
		KEYS:
			_design_gamepad()
		MUSIC:
			var note := _rounded(_poly([9.2, 5.2, 21.2, 2.4, 21.2, 6.6, 9.2, 9.2]), 0.6)
			note = _merge(note, _rect(Rect2(9.2, 6, 1.9, 11.4)))
			note = _merge(note, _rect(Rect2(19.3, 4, 1.9, 11.4)))
			note = _merge(note, _ellipse(Vector2(7.0, 17.6), 3.6, 2.8, -0.38))
			note = _merge(note, _ellipse(Vector2(17.6, 15.6), 3.3, 2.7, -0.38))
			_part(note, TEAL)
		SOUND:
			_part(_stroke(_arc(Vector2(12.4, 12), 8.4, -0.82, 0.82), 2.3), TEAL, 0.0, false)
			_part(_stroke(_arc(Vector2(12.4, 12), 4.8, -0.78, 0.78), 2.3), TEAL, 0.0, false)
			_part(_rounded(_poly([2.4, 8.8, 7.2, 8.8, 13, 3.8, 13, 20.2, 7.2, 15.2, 2.4, 15.2]), 1.2), GOLD)
			_line(_poly([7.2, 9.4, 7.2, 14.6]), _shade(GOLD), 1.0)
		DOOR:
			_design_door()
		SHIELD:
			var shield := _shield()
			_part(shield, TEAL, 1.6)
			_flat(_intersect_one(_offset_one(shield, -2.2), _rect(Rect2(12, 0, 12, 24))), _shade(TEAL).lerp(TEAL, 0.4))
			var hole := _merge(_circle(Vector2(12, 10.2), 2.5), _rounded(_poly([10.8, 11, 13.2, 11, 14, 16.4, 10, 16.4]), 0.8))
			_part(hole, CREAM, 0.0, false)
		WARNING:
			_part(_rounded(_poly([12, 2.0, 22.6, 20.8, 1.4, 20.8]), 2.6), GOLD)
			_flat(_rounded(_poly([10.6, 7.6, 13.4, 7.6, 12.8, 14.4, 11.2, 14.4]), 1.0), INK)
			_flat(_circle(Vector2(12, 17.4), 1.6), INK)
		CASH:
			_design_cash()
		BUCKET:
			_design_bucket()
		MARKET:
			_design_market()
		PAUSE:
			_part(_rrect(Rect2(5.4, 4.0, 5.0, 16.0), 2.3), CRUST)
			_part(_rrect(Rect2(13.6, 4.0, 5.0, 16.0), 2.3), CRUST)
		ROD:
			_design_rod()
		FISH:
			_design_fish()
		LEDGER:
			_design_ledger()
		ARROW_UP:
			_part(_rounded(_poly([12, 2.2, 21.4, 11.6, 15.9, 11.6, 15.9, 21.6, 8.1, 21.6, 8.1, 11.6, 2.6, 11.6]), 1.4), GREEN)
		ARROW_DOWN:
			_part(_rounded(_poly([12, 21.8, 2.6, 12.4, 8.1, 12.4, 8.1, 2.4, 15.9, 2.4, 15.9, 12.4, 21.4, 12.4]), 1.4), GREEN)
		MAP:
			_design_map()
		EMBLEM:
			_design_emblem()
		TROPHY:
			_design_trophy()
		RETRY:
			var start := 0.30 * PI
			var finish := 1.80 * PI
			var centre := Vector2(12, 12.6)
			var arrow := _stroke(_arc(centre, 7.0, start, finish), 3.4)
			var end := centre + Vector2.from_angle(finish) * 7.0
			var along := Vector2.from_angle(finish + PI * 0.5)
			var across := Vector2.from_angle(finish)
			var head := _rounded(PackedVector2Array([end + along * 4.4, end - along * 1.0 + across * 4.4, end - along * 1.0 - across * 4.4]), 0.8)
			_part(_merge(arrow, head), TEAL)
		BACK:
			var path := PackedVector2Array([Vector2(8.6, 8.6), Vector2(14.4, 8.6)])
			path.append_array(_arc(Vector2(14.4, 14.0), 5.4, -PI * 0.5, 0.0))
			path.append(Vector2(19.8, 19.8))
			var back := _merge(_stroke(path, 3.8), _rounded(_poly([2.2, 8.6, 10, 2.4, 10, 14.8]), 1.0))
			_part(back, TEAL)
		CLOSE:
			_part(_merge(_stroke(_poly([6, 6, 18, 18]), 4.6), _stroke(_poly([18, 6, 6, 18]), 4.6)), RED)
		ARROW_LEFT:
			_part(_rounded(_poly([1.8, 12, 11.2, 2.8, 11.2, 8.2, 21.8, 8.2, 21.8, 15.8, 11.2, 15.8, 11.2, 21.2]), 1.5), TEAL, 1.6)
		ARROW_RIGHT:
			_part(_rounded(_poly([22.2, 12, 12.8, 21.2, 12.8, 15.8, 2.2, 15.8, 2.2, 8.2, 12.8, 8.2, 12.8, 2.8]), 1.5), TEAL, 1.6)
		GLOVE:
			_design_glove()
		HAND, PAPER:
			_design_paper()
		ROCK:
			_design_rock()
		SCISSORS:
			_design_scissors()


## The game's emblem (revision 6.8), above "CATCH AND BRAWL": a round
## vintage badge. A terracotta ring with cream stitching holds a sunset over
## the lake; a chubby orange fish leaps out of the water with a scowl, a red
## boxing glove up and a fishing line still caught in its lip (the catch and
## the brawl). An impact star flies off the glove and water drops splash
## under its tail. Every part is a sticker part like the icons, so the
## emblem shares their outline, lip and rim of light.
func _design_emblem() -> void:
	var centre := Vector2(12, 12)
	# Badge: the ring, its stitching, and the sky disc inside.
	_part(_circle(centre, 10.6), EMBLEM_RING, 1.1)
	for stitch: int in 20:
		var at := centre + Vector2.from_angle(TAU * float(stitch) / 20.0 - PI * 0.5) * 9.7
		_flat(_ellipse(at, 0.34, 0.34), EMBLEM_STITCH)
	var disc := _circle(centre, 8.75)
	_part(disc, EMBLEM_SKY, 0.0, false)
	# Sunburst behind the sun: every other wedge a lighter cream.
	var burst := Vector2(12, 15.4)
	for wedge: int in 16:
		if wedge % 2 == 1:
			continue
		var from := -PI + PI * float(wedge) / 16.0 - 0.02
		var to := from + PI / 16.0
		var ray := PackedVector2Array([burst, burst + Vector2.from_angle(from) * 14.0, burst + Vector2.from_angle(to) * 14.0])
		_flat(_intersect_one(ray, _offset_one(disc, -0.15)), EMBLEM_SKY_LIGHT)
	_part(_intersect_one(_circle(Vector2(12, 15.6), 5.2), disc), GOLD, 0.0, false)
	_flat(_intersect_one(_circle(Vector2(12, 15.6), 3.7), disc), EMBLEM_SUN_CORE)
	# Water: a wavy surface across the lower part of the disc.
	var water := PackedVector2Array()
	for step: int in 25:
		var x := 1.0 + float(step) * 22.0 / 24.0
		water.append(Vector2(x, 15.55 + 0.32 * sin(x * 1.25)))
	water.append(Vector2(23.0, 24.0))
	water.append(Vector2(1.0, 24.0))
	_part(_intersect_one(water, disc), EMBLEM_WATER, 0.0, false)
	_flat(_intersect_one(_moved(water, Vector2(0.0, 2.4)), disc), EMBLEM_WATER_DEEP)
	for ripple: Array in [[Vector2(4.6, 18.0), 2.2], [Vector2(15.4, 19.0), 2.6], [Vector2(9.0, 20.6), 1.8]]:
		var start: Vector2 = ripple[0]
		_line(PackedVector2Array([start, start + Vector2(float(ripple[1]), 0.0)]), EMBLEM_RIPPLE, 0.45)
	# Splash where the fish broke the surface.
	for drop: Array in [[Vector2(5.0, 13.9), 0.45], [Vector2(6.5, 12.9), 0.6], [Vector2(15.3, 15.1), 0.5], [Vector2(16.7, 14.3), 0.36]]:
		_part(_circle(drop[0], float(drop[1])), EMBLEM_SPLASH, 0.0, false)
	# The fish: tail and fins first, so the body sits on top of them.
	_part(_fish_shape(_rounded(_poly([-3.9, 0.2, -7.1, -2.9, -6.0, 0.1, -7.0, 3.0]), 0.7)), EMBLEM_FIN, 0.9, false)
	_part(_fish_shape(_rounded(_poly([-2.2, -2.7, -0.4, -4.9, 1.8, -4.4, 2.0, -2.6]), 0.6)), EMBLEM_FIN, 0.0, false)
	_part(_fish_shape(_rounded(_poly([-1.6, 2.6, -0.6, 4.3, 0.9, 2.8]), 0.5)), EMBLEM_FIN, 0.0, false)
	var body := _fish_shape(_merge(_ellipse(Vector2(0.2, 0.0), 4.9, 3.25), _ellipse(Vector2(3.4, 0.25), 2.2, 2.35)))
	_part(body, EMBLEM_FISH, 1.0)
	_flat(_intersect_one(body, _fish_shape(_ellipse(Vector2(0.9, 2.65), 4.6, 1.75))), EMBLEM_BELLY)
	# Scales: three soft arcs on the back.
	for scale_at: Vector2 in [Vector2(-1.9, -0.6), Vector2(-0.3, -1.1), Vector2(-1.1, 0.7)]:
		_line(_fish_shape(_arc(scale_at, 0.75, -0.9, 0.9)), _shade(EMBLEM_FISH).lerp(EMBLEM_FISH, 0.35), 0.35)
	_line(_fish_shape(_arc(Vector2(0.4, 0.2), 2.3, -0.95, 0.85)), _shade(EMBLEM_FISH), 0.42)
	# Face: a big bead eye under a cross brow, a blush and a cocky grin.
	_part(_fish_shape(_circle(Vector2(2.85, -0.85), 0.88)), CREAM, 0.0, false)
	_flat(_fish_shape(_circle(Vector2(3.1, -0.78), 0.5)), INK)
	_flat(_fish_shape(_circle(Vector2(2.95, -0.98), 0.18)), CREAM)
	_part(_fish_shape(_stroke(_poly([1.85, -2.05, 3.8, -1.45]), 0.55)), INK, 0.0, false, false, false)
	_flat(_fish_shape(_ellipse(Vector2(2.6, 0.75), 0.8, 0.45)), Color(PINK, 0.85))
	_line(_fish_shape(_curve(Vector2(3.9, 1.05), Vector2(4.5, 1.25), Vector2(5.05, 0.55), 6)), INK, 0.36)
	# The fishing line comes in from the rod beyond the badge, over the
	# fish's head, and ends in its lip with a little hook.
	var lip := _fish_point(Vector2(5.0, 0.4))
	var line := PackedVector2Array([Vector2(3.4, 4.2)])
	line.append_array(_curve(Vector2(3.4, 4.2), Vector2(12.0, 2.6), lip, 14))
	_line(line, INK, 0.38)
	_line(_fish_shape(_arc(Vector2(5.15, 0.8), 0.42, -PI * 0.5, PI * 0.6)), STEEL.darkened(0.25), 0.32)
	# The glove arm: the front fin reaching to the cuff, then the glove.
	# The punch goes out low and forward, under the chin, so the grin and the
	# hooked lip stay in view.
	_part(_fish_shape(_stroke(_poly([0.8, 2.3, 2.9, 3.6]), 1.2)), EMBLEM_FIN, 0.0, false)
	_part(_fish_shape(_rounded(_poly([2.6, 3.0, 3.9, 2.4, 4.6, 3.9, 3.2, 4.6]), 0.4)), CREAM, 0.0, false)
	var glove := _fish_shape(_merge(_circle(Vector2(5.5, 4.1), 1.85), _circle(Vector2(6.75, 2.85), 0.78)))
	_part(glove, RED, 0.9)
	_line(_fish_shape(_arc(Vector2(5.5, 4.1), 1.15, -1.9, -0.5)), _light(RED), 0.4)
	# The hit: an impact star off the glove and two little twinkles.
	_part(_star5(Vector2(20.7, 12.4), 1.55, 0.72), GOLD, 0.0, false)
	_part(_sparkle(Vector2(18.6, 5.9), 1.0), EMBLEM_SKY_LIGHT, 0.0, false)
	_flat(_sparkle(Vector2(5.7, 8.6), 0.7), CREAM)


## Places a point of the fish (its own frame: nose toward +X) on the badge.
static func _fish_point(point: Vector2) -> Vector2:
	return EMBLEM_FISH_FRAME * point


## Places a whole shape of the fish on the badge.
static func _fish_shape(shape: PackedVector2Array) -> PackedVector2Array:
	return EMBLEM_FISH_FRAME * shape


## A folded paper map (three panels) with a winding river and a red pin.
func _design_map() -> void:
	var sheet := _poly([2.0, 5.2, 8.0, 3.2, 16.0, 5.2, 22.0, 3.2, 22.0, 19.0, 16.0, 21.0, 8.0, 19.0, 2.0, 21.0])
	_part(_rounded(sheet, 0.8), PAPER_CREAM, 1.2)
	_flat(_poly([8.0, 3.2, 16.0, 5.2, 16.0, 21.0, 8.0, 19.0]), UiTokens.PAPER_200)
	var river := _curve(Vector2(3.0, 15.6), Vector2(9.0, 9.0), Vector2(13.0, 13.6))
	river.append_array(_curve(Vector2(13.0, 13.6), Vector2(17.0, 18.0), Vector2(21.0, 8.4)))
	_line(river, TEAL, 1.6)
	_line(_poly([8.0, 3.6, 8.0, 18.6]), UiTokens.EDGE_PAPER, 0.7)
	_line(_poly([16.0, 5.6, 16.0, 20.6]), UiTokens.EDGE_PAPER, 0.7)
	var pin := _merge(_circle(Vector2(15.2, 7.6), 3.4), _rounded(_poly([12.4, 9.0, 18.0, 9.0, 15.2, 14.6]), 0.6))
	_part(pin, RED, 1.0)
	_flat(_circle(Vector2(15.2, 7.6), 1.3), CREAM)


func _design_book() -> void:
	_part(_rounded(_poly([1.6, 7.2, 12, 9.0, 22.4, 7.2, 22.4, 19.8, 12, 21.8, 1.6, 19.8]), 1.2), TEAL, 1.2)
	var left := _poly([3.2, 5.4])
	left.append_array(_curve(Vector2(3.2, 5.4), Vector2(7.6, 3.6), Vector2(11.6, 6.6)))
	left.append(Vector2(11.6, 19.8))
	left.append_array(_curve(Vector2(11.6, 19.8), Vector2(7.6, 17.0), Vector2(3.2, 18.4)))
	var right := Transform2D(0.0, Vector2(-1, 1), 0.0, Vector2(24, 0)) * left
	right.reverse()
	_part(left, PAPER_CREAM, 0.0)
	_part(right, PAPER_CREAM, 0.0)
	for row: int in 3:
		var y := 9.6 + float(row) * 3.0
		var short := 2.0 if row == 2 else 0.0
		_line(_poly([5.2, y - 0.5, 9.8, y + 0.3]), UiTokens.EDGE_PAPER, 0.9)
		_line(_poly([14.2, y + 0.3, 18.8 - short, y - 0.5 + short * 0.15]), UiTokens.EDGE_PAPER, 0.9)
	_line(_poly([12, 8.4, 12, 20.4]), UiTokens.EDGE_PAPER, 0.9)
	_part(_poly([15.4, 17.0, 18.0, 16.6, 18.0, 23.0, 16.7, 21.8, 15.4, 23.0]), RED, 0.0, false)


func _design_gamepad() -> void:
	var body := _merge(_rrect(Rect2(2.0, 6.4, 20.0, 10.2), 4.8), _circle(Vector2(6.6, 15.6), 4.3))
	body = _merge(body, _circle(Vector2(17.4, 15.6), 4.3))
	_part(body, BLUE, 1.5)
	var cross := _merge(_rrect(Rect2(4.5, 10.0, 6.0, 2.1), 0.6), _rrect(Rect2(6.45, 8.05, 2.1, 6.0), 0.6))
	_flat(cross, INK)
	_part(_circle(Vector2(16.0, 9.9), 1.45), RED, 0.0, false)
	_part(_circle(Vector2(18.6, 12.5), 1.45), GOLD, 0.0, false)
	_flat(_rrect(Rect2(10.6, 9.4, 2.8, 1.2), 0.6), _shade(BLUE))


func _design_door() -> void:
	_part(_rrect(Rect2(4.0, 2.6, 12.6, 19.0), 1.4), UiTokens.INK_700, 0.0, false)
	var door := _rounded(_poly([4.0, 2.6, 11.8, 1.2, 11.8, 22.8, 4.0, 21.6]), 0.8)
	_part(door, WOOD, 1.0)
	_flat(_rounded(_poly([5.6, 5.0, 10.2, 4.2, 10.2, 10.6, 5.6, 11.0]), 0.6), _shade(WOOD).lerp(WOOD, 0.5))
	_flat(_rounded(_poly([5.6, 13.2, 10.2, 13.0, 10.2, 19.8, 5.6, 19.9]), 0.6), _shade(WOOD).lerp(WOOD, 0.5))
	_part(_circle(Vector2(9.4, 12.2), 1.15), GOLD, 0.0, false)
	_part(_rounded(_poly([13.0, 10.2, 17.0, 10.2, 17.0, 7.0, 22.6, 12, 17.0, 17.0, 17.0, 13.8, 13.0, 13.8]), 0.7), GREEN, 1.0)


func _design_cash() -> void:
	var note := Transform2D(-0.16, Vector2(10.2, 9.6)) * _rrect(Rect2(-8.8, -5.4, 17.6, 10.8), 2.2)
	_part(note, GREEN, 1.2)
	var border := Transform2D(-0.16, Vector2(10.2, 9.6)) * _rrect(Rect2(-6.6, -3.3, 13.2, 6.6), 1.2)
	_line(border, _shade(GREEN), 0.8, true)
	_flat(Transform2D(-0.16, Vector2(10.2, 9.6)) * _circle(Vector2.ZERO, 2.1), GREEN.lerp(Color.WHITE, 0.4))
	_part(_circle(Vector2(16.4, 15.6), 6.0), GOLD, 1.4)
	_line(_circle(Vector2(16.4, 15.6), 3.9), _shade(GOLD), 0.9, true)
	_flat(_rrect(Rect2(15.6, 13.0, 1.6, 5.2), 0.8), _shade(GOLD))


func _design_bucket() -> void:
	_line(_arc(Vector2(12, 10.4), 7.6, PI, TAU), INK, 1.6)
	_part(_rounded(_poly([12.6, 9.8, 11.4, 4.2, 15.0, 6.4, 18.8, 2.8, 17.6, 9.8]), 0.9), CRUST, 0.0)
	var body := _rounded(_poly([4.6, 10.0, 19.4, 10.0, 17.6, 21.6, 6.4, 21.6]), 1.4)
	_part(body, BLUE, 1.4)
	_flat(_intersect_one(body, _rect(Rect2(0, 14.8, 24, 2.0))), _shade(BLUE).lerp(BLUE, 0.35))
	_part(_rrect(Rect2(3.2, 8.2, 17.6, 3.4), 1.7), STEEL, 0.9)


func _design_market() -> void:
	_part(_rrect(Rect2(4.4, 8.8, 2.0, 6.0), 0.6), WOOD_DARK, 0.0, false)
	_part(_rrect(Rect2(17.6, 8.8, 2.0, 6.0), 0.6), WOOD_DARK, 0.0, false)
	_part(_rrect(Rect2(3.2, 13.6, 17.6, 8.2), 1.4), WOOD, 1.3)
	for x: float in [9.0, 15.0]:
		_line(_poly([x, 15.4, x, 20.6]), _shade(WOOD), 0.8)
	_part(_rrect(Rect2(2.2, 12.4, 19.6, 2.6), 1.1), WOOD.lerp(Color.WHITE, 0.25), 0.7, false)
	var awning := _rrect(Rect2(1.6, 3.2, 20.8, 5.8), 1.4)
	for scallop: int in 5:
		awning = _merge(awning, _circle(Vector2(3.68 + 4.16 * float(scallop), 8.8), 2.08))
	_ghost(awning)
	for stripe: int in 5:
		var band := _intersect_one(awning, _rect(Rect2(1.6 + 4.16 * float(stripe), 0, 4.16, 24)))
		_part(band, CRUST if stripe % 2 == 0 else CREAM, 1.2, false, false, false)


func _design_rod() -> void:
	_part(_stroke(_poly([4.0, 20.8, 19.8, 3.6]), 1.8), WOOD_DARK, 0.0, false)
	_part(_stroke(_poly([3.4, 21.4, 7.6, 16.8]), 3.4), CRUST, 0.0)
	_part(_circle(Vector2(9.6, 17.4), 2.5), STEEL, 0.8)
	_flat(_circle(Vector2(9.6, 17.4), 0.9), INK)
	_line(_poly([19.8, 3.6, 19.8, 11.2]), INK, 0.7)
	var bobber := _circle(Vector2(19.8, 13.8), 2.8)
	_ghost(bobber)
	_part(_intersect_one(bobber, _rect(Rect2(0, 0, 24, 13.8))), RED, 0.0, false, false, false)
	_part(_intersect_one(bobber, _rect(Rect2(0, 13.8, 24, 10))), CREAM, 0.0, false, false, false)
	_line(_poly([17.0, 13.8, 22.6, 13.8]), INK, 0.7)


func _design_fish() -> void:
	_part(_rounded(_poly([7.0, 12, 1.6, 6.4, 3.4, 12, 1.6, 17.6]), 1.0), TEAL, 0.0)
	_part(_rounded(_poly([8.4, 8.4, 12.8, 3.6, 16.0, 7.8]), 0.9), _shade(TEAL).lerp(TEAL, 0.5), 0.0, false)
	var body := _ellipse(Vector2(13.2, 12.2), 8.4, 6.2)
	_part(body, TEAL, 1.2)
	_flat(_intersect_one(_offset_one(body, -1.1), _rect(Rect2(0, 14.2, 24, 10))), TEAL.lerp(CREAM, 0.55))
	_line(_arc(Vector2(10.4, 12.2), 4.0, -0.95, 0.95), _shade(TEAL), 0.9)
	_part(_rounded(_poly([12.8, 14.0, 8.6, 14.6, 10.2, 17.6]), 0.9), _shade(TEAL).lerp(TEAL, 0.5), 0.0, false)
	_part(_circle(Vector2(17.4, 10.4), 2.3), CREAM, 0.0, false)
	_flat(_circle(Vector2(17.9, 10.6), 1.2), INK)
	_flat(_circle(Vector2(17.4, 10.0), 0.45), CREAM)
	_flat(_ellipse(Vector2(18.4, 13.9), 1.1, 0.7), PINK)
	_line(_arc(Vector2(19.4, 13.0), 1.4, 0.4, 1.6), _shade(TEAL), 0.8)


func _design_ledger() -> void:
	_part(_rrect(Rect2(3.8, 3.4, 16.4, 19.2), 2.2), WOOD, 1.4)
	_part(_rrect(Rect2(6.0, 6.0, 12.0, 14.6), 1.0), PAPER_CREAM, 0.8, false)
	for row: int in 3:
		var y := 10.0 + float(row) * 3.0
		_line(_poly([8.2, y, 15.8 - (3.0 if row == 2 else 0.0), y]), UiTokens.INK_700, 0.9)
	_line(_poly([8.2, 18.2, 12.4, 18.2]), RED, 1.1)
	_part(_rrect(Rect2(8.2, 1.8, 7.6, 4.0), 1.4), STEEL, 0.8)
	_flat(_rrect(Rect2(10.6, 2.8, 2.8, 1.2), 0.6), INK)


func _design_trophy() -> void:
	_part(_stroke(_arc(Vector2(6.0, 7.6), 3.4, PI * 0.5, PI * 1.5), 2.0), GOLD, 0.0, false)
	_part(_stroke(_arc(Vector2(18.0, 7.6), 3.4, -PI * 0.5, PI * 0.5), 2.0), GOLD, 0.0, false)
	_part(_rrect(Rect2(6.4, 16.6, 11.2, 5.2), 1.4), WOOD_DARK, 1.0)
	_flat(_rrect(Rect2(9.2, 18.2, 5.6, 2.0), 0.6), GOLD)
	_part(_rrect(Rect2(10.6, 12.6, 2.8, 4.6), 0.6), _shade(GOLD).lerp(GOLD, 0.5), 0.0, false)
	var cup := _poly([5.2, 2.8, 18.8, 2.8])
	cup.append_array(_curve(Vector2(18.8, 2.8), Vector2(18.8, 12.8), Vector2(12, 14.0)))
	cup.append_array(_curve(Vector2(12, 14.0), Vector2(5.2, 12.8), Vector2(5.2, 2.8)))
	_part(_rounded(cup, 0.8), GOLD, 1.5)
	_flat(_star5(Vector2(12, 7.6), 3.0, 1.3), CREAM)


## An upright boxing glove: the fist on top, the thumb along its side and a
## cream cuff with a red band below.
func _design_glove() -> void:
	var cuff := _rrect(Rect2(6.0, 15.6, 12.4, 7.0), 1.8)
	_part(cuff, CREAM, 1.1)
	_flat(_intersect_one(cuff, _rect(Rect2(0, 18.0, 24, 1.8))), RED)
	var fist := _merge(_ellipse(Vector2(13.0, 8.8), 7.8, 7.0), _rrect(Rect2(5.8, 8.4, 14.8, 9.0), 3.6))
	_part(fist, RED, 1.6)
	_line(_arc(Vector2(13.4, 9.0), 5.0, -1.2, -0.15), RED.lerp(Color.WHITE, 0.5), 1.3)
	_part(_stroke(_poly([8.2, 15.6, 5.4, 12.6, 6.6, 8.6]), 4.2), RED, 0.8, false)
	_line(_arc(Vector2(13.6, 17.4), 6.0, -2.3, -1.6), _shade(RED), 0.9)


func _design_rock() -> void:
	_part(_rrect(Rect2(7.0, 19.0, 10.0, 4.4), 1.2), SLEEVE, 0.8)
	_part(_rrect(Rect2(5.0, 8.6, 14.0, 12.2), 4.4), SKIN, 1.2)
	for finger: int in 4:
		_part(_rrect(Rect2(5.1 + 3.45 * float(finger), 5.6, 3.6, 7.0), 1.8), SKIN, 0.0, finger == 0)
	_part(_rounded(_poly([4.6, 13.2, 13.0, 11.8, 13.8, 15.2, 5.0, 16.6]), 1.6), SKIN, 0.7, false)


func _design_scissors() -> void:
	_part(_rrect(Rect2(7.0, 19.2, 10.0, 4.2), 1.2), SLEEVE, 0.8)
	_part(_stroke(_poly([10.0, 13.0, 7.2, 3.2]), 3.6), SKIN, 0.0)
	_part(_stroke(_poly([13.6, 13.0, 16.8, 3.2]), 3.6), SKIN, 0.0)
	_part(_rrect(Rect2(5.6, 10.4, 12.8, 10.8), 4.0), SKIN, 1.2, false)
	_part(_rrect(Rect2(13.4, 11.2, 4.4, 4.6), 2.0), SKIN, 0.0, false)
	_part(_rounded(_poly([4.8, 14.0, 12.6, 13.0, 13.2, 16.2, 5.2, 17.4]), 1.6), SKIN, 0.7, false)


func _design_paper() -> void:
	_part(_rrect(Rect2(7.0, 19.4, 10.0, 4.0), 1.2), SLEEVE, 0.8)
	var tips := [Vector2(7.2, 4.6), Vector2(10.5, 3.0), Vector2(13.8, 3.2), Vector2(17.0, 5.2)]
	for index: int in 4:
		var base := Vector2(7.6 + 3.2 * float(index), 12.6)
		_part(_stroke(PackedVector2Array([base, tips[index]]), 3.1), SKIN, 0.0, index == 0)
	_part(_stroke(_poly([7.0, 16.0, 3.0, 10.6]), 3.3), SKIN, 0.0)
	_part(_rrect(Rect2(5.4, 10.4, 13.2, 11.0), 4.2), SKIN, 1.2, false)
	_line(_arc(Vector2(12, 12.4), 3.6, 0.55, 1.6), _shade(SKIN), 0.8)


# --- Layers -------------------------------------------------------------------

## A coloured part: outlined, with a lip of depth `lip` and a rim of light.
func _part(shape: PackedVector2Array, fill: Color, lip: float = LIP, shine: bool = true,
		inner: bool = true, outline: bool = true) -> void:
	if shape.size() < 3:
		return
	_layers.append({"kind": "part", "shape": shape, "fill": fill, "lip": lip, "shine": shine,
		"inner": inner, "outline": outline, "filled": true})


## A plain detail fill: no outline, lip or light.
func _flat(shape: PackedVector2Array, fill: Color) -> void:
	if shape.size() < 3 or fill.a <= 0.0:
		return
	_layers.append({"kind": "part", "shape": shape, "fill": fill, "lip": 0.0, "shine": false,
		"inner": false, "outline": false, "filled": true})


## Only the outlines of a shape whose inside is drawn by other parts.
func _ghost(shape: PackedVector2Array) -> void:
	_layers.append({"kind": "part", "shape": shape, "fill": Color.TRANSPARENT, "lip": 0.0, "shine": false,
		"inner": true, "outline": true, "filled": false})


## A detail line of `width` grid units, drawn as is.
func _line(points: PackedVector2Array, color: Color, width: float, closed: bool = false) -> void:
	_layers.append({"kind": "line", "points": points, "color": color, "width": width, "closed": closed})


func _compile() -> Array:
	var commands: Array = []
	# The whole silhouette first, so every part shares one thick outline.
	for layer: Dictionary in _layers:
		if layer["kind"] == "part" and layer["outline"]:
			for polygon: PackedVector2Array in _offset(layer["shape"], OUTLINE):
				commands.append([CMD_POLYGON, polygon, INK])
	for layer: Dictionary in _layers:
		if layer["kind"] == "line":
			commands.append([CMD_LINE, layer["points"], layer["color"], layer["width"], layer["closed"]])
			continue
		var shape: PackedVector2Array = layer["shape"]
		if layer["inner"]:
			for polygon: PackedVector2Array in _offset(shape, INNER):
				commands.append([CMD_POLYGON, polygon, INK])
		if not layer["filled"]:
			continue
		var fill: Color = layer["fill"]
		commands.append([CMD_POLYGON, shape, fill])
		if layer["lip"] > 0.0:
			for polygon: PackedVector2Array in _clip(shape, _moved(shape, Vector2(0.0, -float(layer["lip"])))):
				commands.append([CMD_POLYGON, polygon, _shade(fill)])
		if layer["shine"]:
			for core: PackedVector2Array in _offset(shape, -SHINE_INSET):
				for polygon: PackedVector2Array in _clip(core, _moved(core, SHINE_SHIFT)):
					commands.append([CMD_POLYGON, polygon, _light(fill)])
	# Triangulate each polygon once; one that cannot be triangulated is dropped.
	var valid: Array = []
	for command: Array in commands:
		if command[0] == CMD_LINE:
			valid.append(command)
			continue
		var points := _clean(command[1])
		var triangles := Geometry2D.triangulate_polygon(points)
		if triangles.size() >= 3:
			valid.append([CMD_POLYGON, points, command[2], triangles])
	return valid


## Drops points that sit on top of their neighbour.
static func _clean(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in points:
		if result.is_empty() or result[result.size() - 1].distance_squared_to(point) > 0.0001:
			result.append(point)
	if result.size() > 1 and result[0].distance_squared_to(result[result.size() - 1]) <= 0.0001:
		result.remove_at(result.size() - 1)
	return result


static func _shade(color: Color) -> Color:
	return color.lerp(INK, 0.22)


static func _light(color: Color) -> Color:
	return color.lerp(Color.WHITE, 0.5)


# --- Shapes -------------------------------------------------------------------

## A polygon from a flat list of coordinates.
static func _poly(coordinates: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(0, coordinates.size() - 1, 2):
		points.append(Vector2(float(coordinates[index]), float(coordinates[index + 1])))
	return points


static func _circle(centre: Vector2, radius: float) -> PackedVector2Array:
	return _ellipse(centre, radius, radius)


static func _ellipse(centre: Vector2, radius_x: float, radius_y: float, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := clampi(int(maxf(radius_x, radius_y) * 7.0), 18, 56)
	var turn := Transform2D(rotation, centre)
	for step: int in steps:
		var angle := TAU * float(step) / float(steps)
		points.append(turn * Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


static func _rect(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


static func _rrect(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points := PackedVector2Array()
	var corners := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI * 0.5],
		[rect.end - Vector2(r, r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
		[rect.position + Vector2(r, r), PI],
	]
	for corner: Array in corners:
		for step: int in 7:
			var angle: float = corner[1] + PI * 0.5 * float(step) / 6.0
			points.append(corner[0] + Vector2.from_angle(angle) * r)
	return points


## Rounds every corner of a simple polygon with a fillet of `radius`.
static func _rounded(points: PackedVector2Array, radius: float, steps: int = 6) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := points.size()
	for index: int in count:
		var corner := points[index]
		var previous := points[(index - 1 + count) % count]
		var following := points[(index + 1) % count]
		var to_previous := previous - corner
		var to_following := following - corner
		var angle := absf(to_previous.angle_to(to_following))
		if angle > PI - 0.02 or angle < 0.02:
			result.append(corner)
			continue
		var reach := minf(radius / tan(angle * 0.5), minf(to_previous.length(), to_following.length()) * 0.5)
		var start := corner + to_previous.normalized() * reach
		var finish := corner + to_following.normalized() * reach
		for step: int in steps + 1:
			var t := float(step) / float(steps)
			result.append(start.lerp(corner, t).lerp(corner.lerp(finish, t), t))
	return result


## Points of a quadratic curve, without its first point.
static func _curve(from: Vector2, control: Vector2, to: Vector2, steps: int = 10) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in range(1, steps + 1):
		var t := float(step) / float(steps)
		points.append(from.lerp(control, t).lerp(control.lerp(to, t), t))
	return points


static func _arc(centre: Vector2, radius: float, from: float, to: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := maxi(8, int(absf(to - from) * radius * 2.0))
	for step: int in steps + 1:
		points.append(centre + Vector2.from_angle(lerpf(from, to, float(step) / float(steps))) * radius)
	return points


## A twinkle: four points joined by inward curves, the tips softened.
static func _sparkle(centre: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in 64:
		var angle := TAU * float(step) / 64.0
		var c := cos(angle)
		var s := sin(angle)
		points.append(centre + Vector2(signf(c) * pow(absf(c), 4.0), signf(s) * pow(absf(s), 4.0)) * radius)
	return _offset_one(_offset_one(points, -0.4), 0.4)


static func _star5(centre: Vector2, outer: float, inner: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in 10:
		var angle := -PI * 0.5 + PI * 0.2 * float(index)
		points.append(centre + Vector2.from_angle(angle) * (outer if index % 2 == 0 else inner))
	return _rounded(points, 0.35, 3)


## The classic plump heart curve, `scale` grid units per curve unit.
static func _heart(centre: Vector2, scale: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in 72:
		var t := TAU * float(step) / 72.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		points.append(centre + Vector2(x, -(y + 2.5)) * scale)
	return points


static func _gear(centre: Vector2, teeth: int, root: float, tip: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var pitch := TAU / float(teeth)
	for tooth: int in teeth:
		var angle := pitch * float(tooth) - PI * 0.5
		for step: int in 3:
			points.append(centre + Vector2.from_angle(angle - pitch * 0.5 + pitch * 0.2 * float(step) / 2.0) * root)
		points.append(centre + Vector2.from_angle(angle - pitch * 0.2) * tip)
		points.append(centre + Vector2.from_angle(angle + pitch * 0.2) * tip)
		for step: int in 3:
			points.append(centre + Vector2.from_angle(angle + pitch * 0.3 + pitch * 0.2 * float(step) / 2.0) * root)
	return _rounded(_clean(points), 1.0, 4)


static func _shield() -> PackedVector2Array:
	var points := PackedVector2Array([Vector2(12, 2.2)])
	points.append_array(_curve(Vector2(12, 2.2), Vector2(16.6, 4.4), Vector2(20.4, 4.6)))
	points.append_array(_curve(Vector2(20.4, 4.6), Vector2(20.8, 15.2), Vector2(12, 22.0)))
	points.append_array(_curve(Vector2(12, 22.0), Vector2(3.2, 15.2), Vector2(3.6, 4.6)))
	points.append_array(_curve(Vector2(3.6, 4.6), Vector2(7.4, 4.4), Vector2(12, 2.2)))
	points.remove_at(points.size() - 1)
	return _rounded(points, 0.8, 4)


# --- Polygon operations (Geometry2D, on a scaled-up grid) -----------------------

static func _moved(shape: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	return Transform2D(0.0, by) * shape


static func _up(shape: PackedVector2Array) -> PackedVector2Array:
	return Transform2D(0.0, Vector2(GEOMETRY_SCALE, GEOMETRY_SCALE), 0.0, Vector2.ZERO) * shape


static func _down(shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var back := Transform2D(0.0, Vector2(1.0 / GEOMETRY_SCALE, 1.0 / GEOMETRY_SCALE), 0.0, Vector2.ZERO)
	for shape: PackedVector2Array in _outers(shapes):
		result.append(back * shape)
	return result


## Clipper returns holes with the opposite winding; keeps the outer outlines.
static func _outers(shapes: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	if shapes.size() < 2:
		return shapes
	var largest := shapes[0]
	var largest_area := 0.0
	for shape: PackedVector2Array in shapes:
		var area := absf(_area(shape))
		if area > largest_area:
			largest_area = area
			largest = shape
	var winding := Geometry2D.is_polygon_clockwise(largest)
	var result: Array[PackedVector2Array] = []
	for shape: PackedVector2Array in shapes:
		if Geometry2D.is_polygon_clockwise(shape) == winding:
			result.append(shape)
		elif _building != &"":
			_holes[_building] = true
	return result


static func _area(shape: PackedVector2Array) -> float:
	var total := 0.0
	for index: int in shape.size():
		total += shape[index].cross(shape[(index + 1) % shape.size()])
	return total * 0.5


static func _largest(shapes: Array[PackedVector2Array]) -> PackedVector2Array:
	var best := PackedVector2Array()
	var best_area := -1.0
	for shape: PackedVector2Array in shapes:
		var area := absf(_area(shape))
		if area > best_area:
			best_area = area
			best = shape
	return best


static func _offset(shape: PackedVector2Array, delta: float) -> Array[PackedVector2Array]:
	return _down(Geometry2D.offset_polygon(_up(shape), delta * GEOMETRY_SCALE, Geometry2D.JOIN_ROUND))


static func _offset_one(shape: PackedVector2Array, delta: float) -> PackedVector2Array:
	return _largest(_offset(shape, delta))


static func _clip(shape: PackedVector2Array, cutter: PackedVector2Array) -> Array[PackedVector2Array]:
	return _down(Geometry2D.clip_polygons(_up(shape), _up(cutter)))


static func _intersect_one(shape: PackedVector2Array, mask: PackedVector2Array) -> PackedVector2Array:
	return _largest(_down(Geometry2D.intersect_polygons(_up(shape), _up(mask))))


static func _merge(a: PackedVector2Array, b: PackedVector2Array) -> PackedVector2Array:
	return _largest(_down(Geometry2D.merge_polygons(_up(a), _up(b))))


## A round-capped stroke along `points`, as a filled shape.
static func _stroke(points: PackedVector2Array, width: float) -> PackedVector2Array:
	var shapes := Geometry2D.offset_polyline(_up(points), width * 0.5 * GEOMETRY_SCALE, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	return _largest(_down(shapes))
