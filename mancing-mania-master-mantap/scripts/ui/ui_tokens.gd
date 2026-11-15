class_name UiTokens
extends RefCounted
## Design tokens for the "Warm Sunday Afternoon" UI (GDD 167).
## The generated Theme and every UI script read colors, spacing and type sizes
## from here, so the look can only be changed in one place.
##
## Revision 6.1 ("cozy warung card" UI): the colours follow the diorama
## palette of VISUAL_STYLE_GUIDE.md (vanilla, flour, crust, caramel, cocoa,
## pastel teal), shapes are rounder and every pressable thing has a soft
## darker lip under it, like a wooden price tag or a toy button.

# Colors (GDD 167.2)
const CREAM_50 := Color("fff9ee")        # light surface (flour)
const CREAM_100 := Color("fcefd6")       # primary panel (vanilla card)
const PAPER_200 := Color("f2d9ae")       # secondary panel (custard paper)
const INK_900 := Color("3f2a1e")         # primary text (cocoa)
const INK_700 := Color("6e5241")         # secondary text
const LAKE_500 := Color("4f9a91")        # calm accent (pastel teal, readable)
const GRASS_500 := Color("7fa65a")       # success / nature accent
const SUN_500 := Color("f2b44a")         # highlight / reward (custard gold)
const TERRACOTTA_500 := Color("e0784c")  # primary call to action (crust)
const RED_500 := Color("cf5b4c")         # danger / stress
const BLUE_400 := Color("7fa6c9")        # neutral info (periwinkle)

# Edges and depth (revision 6.1): the darker rim and lip of each surface.
const EDGE_CREAM := Color("d9ab72")      # rim of cream buttons, chips and cards
const EDGE_PAPER := Color("c8935a")      # rim of paper surfaces and wells
const SHADOW := Color(0.247, 0.165, 0.118, 0.26)
const BACKDROP := Color(0.247, 0.157, 0.098, 0.48)
const FOCUS_RING := SUN_500

# Spacing (GDD 167.4): the allowed steps on an 8 px base.
const SPACE_4 := 4
const SPACE_8 := 8
const SPACE_12 := 12
const SPACE_16 := 16
const SPACE_24 := 24
const SPACE_32 := 32
const SPACE_48 := 48

const RADIUS_PANEL := 24
const RADIUS_BUTTON := 18
const RADIUS_CHIP := 24
const BORDER_WIDTH := 3
## The darker lip under every pressable surface (px); a pressed button sinks
## by the difference between LIP and LIP_PRESSED.
const LIP := 6
const LIP_PRESSED := 2

# Typefaces (GDD 167.3, revision 6.3): two licensed font files shipped with
# their licences (LICENSES.md). Fredoka, round and warm, carries all running
# text; Chewy, a bouncy cartoon face, is the comic voice of big titles and
# painted-sign text.
const FONT_BODY_FILE := "res://assets/fonts/Fredoka-Variable.ttf"
const FONT_DISPLAY_FILE := "res://assets/fonts/Chewy-Regular.ttf"
## The licence that travels with each font file; both are packed into every
## build and shown on the in-game LICENSES page.
const FONT_BODY_LICENSE_FILE := "res://assets/fonts/Fredoka-OFL.txt"
const FONT_DISPLAY_LICENSE_FILE := "res://assets/fonts/Chewy-LICENSE.txt"
## Fredoka is a variable font (weight axis 300-700) whose default instance is
## Light, so every cut names its weight.
const FONT_WEIGHT_REGULAR := 500
const FONT_WEIGHT_BOLD := 600

# Type scale at the reference resolution (GDD 167.3): desktop / portrait.
const FONT_HERO := 44
const FONT_HERO_PORTRAIT := 36
const FONT_SCREEN_TITLE := 32
const FONT_SCREEN_TITLE_PORTRAIT := 28
const FONT_HEADER := 24
const FONT_HEADER_PORTRAIT := 22
const FONT_BODY := 18
const FONT_SMALL := 16
const FONT_BUTTON := 20

# Touch targets (GDD 92, 167.8)
const TOUCH_TARGET_MIN := 48
const TOUCH_TARGET_PREFERRED := 56

# Motion (GDD 167.5, 167.6)
const PRESS_SCALE := 0.97
const PRESS_SEC := 0.08
const RELEASE_OVERSHOOT := 1.02
const RELEASE_SEC := 0.09
const TRANSITION_SEC := 0.2
const MODAL_SEC := 0.24

# Theme type variations produced by the UI generator.
const TYPE_TITLE := &"TitleLabel"
const TYPE_SCREEN_TITLE := &"ScreenTitleLabel"
const TYPE_HEADER := &"HeaderLabel"
const TYPE_SMALL := &"SmallLabel"
const TYPE_CTA_BUTTON := &"CtaButton"
const TYPE_DANGER_BUTTON := &"DangerButton"
## Revision 6.1 variations.
const TYPE_ACCENT_BUTTON := &"AccentButton"
const TYPE_ROUND_BUTTON := &"RoundButton"
const TYPE_RIBBON_PANEL := &"RibbonPanel"
const TYPE_RIBBON_LABEL := &"RibbonLabel"
const TYPE_NAME_TAG := &"NameTagLabel"
const TYPE_SECTION := &"SectionLabel"
const TYPE_CARD_PANEL := &"CardPanel"
const TYPE_WELL_PANEL := &"WellPanel"


## Places a duel banner: the headline may wrap to two lines on a phone, so it
## sits at the bottom of a two-line box and the body line starts under it.
static func place_banner(title: Label, body: Label, top: float, width: float) -> void:
	for label: Label in [title, body]:
		label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		label.size.x = width
		label.position.x = 0.0
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title.position.y = top
	title.size.y = 104.0
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.position.y = top + 108.0
	body.size.y = 72.0


## Anchors a control to a layout preset at its full minimum size.
## Godot's own "minimum size" preset mode ignores custom_minimum_size, which
## leaves a larger control hanging off its anchor; sizing first and keeping
## that size puts it exactly where the preset says.
static func anchor_at(control: Control, preset: Control.LayoutPreset) -> void:
	control.reset_size()
	control.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_KEEP_SIZE)


## High Contrast HUD (GDD 189.4): stronger panels, outlines and borders.
## World art never changes.
static func is_high_contrast() -> bool:
	return bool(GameState.get_setting(&"high_contrast_hud"))


## MOBILE HANDEDNESS (GDD 189.12): left-handed layouts swap the side clusters.
static func is_left_handed() -> bool:
	return str(GameState.get_setting(&"mobile_handedness")) == "left"


## Border width of a HUD element, thicker in High Contrast.
static func hud_border(base: int) -> int:
	return base + 2 if is_high_contrast() else base


## Light text with a cocoa outline for labels drawn over the 3D scene, in the
## bold cut with a soft drop shadow (GDD 167.4).
static func outline_text(label: Label, font_size: int, color: Color = CREAM_50, outline: int = 9) -> void:
	label.add_theme_font_override(&"font", UiSkin.bold_font())
	label.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(font_size))
	if is_high_contrast():
		outline += 4
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", INK_900)
	label.add_theme_constant_override(&"outline_size", outline)
	label.add_theme_color_override(&"font_shadow_color", Color(INK_900, 0.4))
	label.add_theme_constant_override(&"shadow_offset_x", 0)
	label.add_theme_constant_override(&"shadow_offset_y", maxi(2, font_size / 12))
	label.add_theme_constant_override(&"shadow_outline_size", outline)
