class_name UiSkin
extends RefCounted
## The "cozy warung card" look of the UI (GDD 167, revision 6.1), as style
## boxes and fonts built from UiTokens. The generated Theme and every HUD that
## styles a control in code use these, so a chip, a tab and a button always
## share the same rim, lip, corners and shadow.
##
## The shape language follows the diorama world (VISUAL_STYLE_GUIDE.md):
## rounded and soft like dough, one warm colour per surface, and a darker lip
## under anything you can press, so buttons look like small wooden price tags
## you can push in. No gloss, no gradients, no neon (GDD 185.20).

const STATE_NORMAL := "normal"
const STATE_HOVER := "hover"
const STATE_PRESSED := "pressed"
const STATE_DISABLED := "disabled"

static var _bold: FontVariation
static var _heavy: FontVariation


## The rim and lip colour of a surface: tan for light surfaces, a warm darker
## shade of the fill for coloured ones.
static func edge_of(fill: Color) -> Color:
	if fill.get_luminance() > 0.78:
		return UiTokens.EDGE_CREAM
	return fill.lerp(UiTokens.INK_900, 0.42)


## A pressable surface in one interaction state: a rounded face with a rim, a
## thicker lip at the bottom and a soft shadow. A pressed face sinks by
## LIP - LIP_PRESSED (its top edge moves down and its lip gets thinner), and
## the content margins move the label with it.
static func button_box(fill: Color, state: String = STATE_NORMAL, radius: int = UiTokens.RADIUS_BUTTON, lip: int = UiTokens.LIP, padding: Vector2 = Vector2(UiTokens.SPACE_24, 9.0)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	var edge := edge_of(fill)
	var face := fill
	var bottom := lip
	var sink := 0.0
	match state:
		STATE_HOVER:
			face = fill.lightened(0.08)
		STATE_PRESSED:
			face = fill.darkened(0.06)
			bottom = UiTokens.LIP_PRESSED
			sink = float(lip - UiTokens.LIP_PRESSED)
		STATE_DISABLED:
			face = fill.lerp(UiTokens.PAPER_200, 0.6)
			face.a = 0.82
			edge = edge.lerp(UiTokens.PAPER_200, 0.55)
			edge.a = 0.82
			bottom = UiTokens.LIP_PRESSED + 1
			sink = float(lip - bottom)
	box.bg_color = face
	box.border_color = edge
	box.set_border_width_all(UiTokens.BORDER_WIDTH)
	box.border_width_bottom = bottom
	box.set_corner_radius_all(radius)
	box.expand_margin_top = -sink
	box.content_margin_left = padding.x
	box.content_margin_right = padding.x
	box.content_margin_top = padding.y + sink
	box.content_margin_bottom = padding.y + float(bottom)
	if state != STATE_DISABLED:
		box.shadow_color = UiTokens.SHADOW
		box.shadow_size = 3 if state == STATE_PRESSED else 6
		box.shadow_offset = Vector2(0.0, 1.0 if state == STATE_PRESSED else 3.0)
	box.anti_aliasing = true
	return box


## The keyboard/gamepad focus ring: a soft gold outline around the button.
static func focus_box(radius: int = UiTokens.RADIUS_BUTTON) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.border_color = UiTokens.FOCUS_RING
	box.set_border_width_all(4)
	box.set_corner_radius_all(radius + 6)
	box.set_expand_margin_all(6.0)
	box.anti_aliasing = true
	return box


## A card: the warm paper surface of panels and dialogs, with a caramel rim
## and a soft shadow underneath.
static func card(fill: Color = UiTokens.CREAM_100, radius: int = UiTokens.RADIUS_PANEL, margin: float = UiTokens.SPACE_24, rim: int = 4) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge_of(fill).lightened(0.12)
	box.set_border_width_all(rim)
	box.border_width_bottom = rim + 3
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.content_margin_bottom = margin + 3.0
	box.shadow_color = UiTokens.SHADOW
	box.shadow_size = 16
	box.shadow_offset = Vector2(0.0, 7.0)
	box.anti_aliasing = true
	return box


## A sunken well inside a card (lists, bars, tracks): a thicker top rim reads
## as a shadow falling into it.
static func well(fill: Color = UiTokens.PAPER_200, radius: int = 16, margin: float = UiTokens.SPACE_12) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge_of(fill)
	box.set_border_width_all(2)
	box.border_width_top = 4
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	box.anti_aliasing = true
	return box


## A pill (chips, ribbons, tags): rounded ends, a rim and a lip.
static func pill(fill: Color, lip: int = 4, radius: int = UiTokens.RADIUS_CHIP, padding: Vector2 = Vector2(UiTokens.SPACE_16, UiTokens.SPACE_4), rim: int = UiTokens.BORDER_WIDTH) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge_of(fill)
	box.set_border_width_all(rim)
	box.border_width_bottom = rim + lip
	box.set_corner_radius_all(radius)
	box.content_margin_left = padding.x
	box.content_margin_right = padding.x
	box.content_margin_top = padding.y
	box.content_margin_bottom = padding.y + float(lip)
	box.shadow_color = UiTokens.SHADOW
	box.shadow_size = 4
	box.shadow_offset = Vector2(0.0, 2.0)
	box.anti_aliasing = true
	return box


## The title ribbon that sits on top of a card.
static func ribbon(fill: Color = UiTokens.TERRACOTTA_500) -> StyleBoxFlat:
	return pill(fill, 5, 22, Vector2(30.0, 5.0))


## A round badge (icon holders, the pause button face).
static func badge(fill: Color, diameter: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge_of(fill)
	box.set_border_width_all(3)
	box.set_corner_radius_all(int(ceil(diameter * 0.5)) + 2)
	box.set_content_margin_all(0.0)
	box.anti_aliasing = true
	return box


## A folder tab on top of a ledger card. The active tab merges into the card.
static func tab(active: bool, hover: bool, fill_active: Color = UiTokens.CREAM_100) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	var fill := fill_active if active else (UiTokens.PAPER_200.lightened(0.1) if hover else UiTokens.PAPER_200)
	box.bg_color = fill
	box.border_color = edge_of(fill_active).lightened(0.12) if active else edge_of(UiTokens.PAPER_200)
	box.set_border_width_all(UiTokens.BORDER_WIDTH + (1 if active else 0))
	box.border_width_bottom = 0
	box.corner_radius_top_left = 16
	box.corner_radius_top_right = 16
	box.content_margin_left = UiTokens.SPACE_12
	box.content_margin_right = UiTokens.SPACE_12
	box.content_margin_top = 10.0 if active else 12.0
	box.content_margin_bottom = 12.0 if active else 8.0
	# Inactive tabs sit lower, tucked behind the card.
	box.expand_margin_top = 4.0 if active else 0.0
	box.anti_aliasing = true
	return box


## A rounded bar track (HP, stamina, landing progress).
static func bar_background(fill: Color = UiTokens.CREAM_50) -> StyleBoxFlat:
	var box := well(fill, 12, 0.0)
	box.border_color = UiTokens.EDGE_PAPER
	box.border_width_top = 3
	box.border_width_bottom = 3
	return box


## The coloured fill of a bar, with its own darker rim.
static func bar_fill(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge_of(fill)
	box.set_border_width_all(2)
	box.border_width_bottom = 4
	box.set_corner_radius_all(12)
	box.anti_aliasing = true
	return box


## A plain rounded face with an optional rim, for widgets that draw
## themselves (position bar, telegraph bar, reel track).
static func rounded(fill: Color, radius: int, rim: int = 0, rim_color: Color = UiTokens.INK_900) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = rim_color
	box.set_border_width_all(rim)
	box.set_corner_radius_all(radius)
	box.anti_aliasing = true
	return box


## The default font, made bolder for buttons, headers and titles. Built on
## the engine's own font (no font file, GDD 184.12).
static func bold_font() -> FontVariation:
	if _bold == null:
		_bold = make_bold(0.55, 0)
	return _bold


## An even heavier cut for the logo and big titles.
static func heavy_font() -> FontVariation:
	if _heavy == null:
		_heavy = make_bold(0.9, 1)
	return _heavy


static func make_bold(embolden: float, spacing: int) -> FontVariation:
	var font := FontVariation.new()
	font.variation_embolden = embolden
	font.spacing_glyph = spacing
	return font


## Big friendly text over the 3D scene: a filled face, a thick cocoa outline
## and a soft drop shadow, like painted letters on a sign.
static func sign_text(label: Label, font_size: int, fill: Color = UiTokens.CREAM_50, outline: int = 12) -> void:
	label.add_theme_font_override(&"font", heavy_font())
	label.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(font_size))
	label.add_theme_color_override(&"font_color", fill)
	label.add_theme_color_override(&"font_outline_color", UiTokens.INK_900)
	label.add_theme_constant_override(&"outline_size", outline + (4 if UiTokens.is_high_contrast() else 0))
	label.add_theme_color_override(&"font_shadow_color", Color(UiTokens.INK_900, 0.45))
	label.add_theme_constant_override(&"shadow_offset_x", 0)
	label.add_theme_constant_override(&"shadow_offset_y", maxi(3, font_size / 10))
	label.add_theme_constant_override(&"shadow_outline_size", outline)
