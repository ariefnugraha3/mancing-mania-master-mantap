class_name UiTokens
extends RefCounted
## Design tokens for the "Warm Sunday Afternoon" UI (GDD 167).
## The generated Theme and every UI script read colors, spacing and type sizes
## from here, so the look can only be changed in one place.

# Colors (GDD 167.2)
const CREAM_50 := Color("fff7e6")        # light surface
const CREAM_100 := Color("f3e3c2")       # primary panel
const PAPER_200 := Color("e6cc9d")       # secondary panel
const INK_900 := Color("352f29")         # primary text
const INK_700 := Color("5a5046")         # secondary text
const LAKE_500 := Color("557f7a")        # calm accent
const GRASS_500 := Color("778b59")       # success / nature accent
const SUN_500 := Color("e4ae55")         # highlight / reward
const TERRACOTTA_500 := Color("b8654e")  # primary call to action
const RED_500 := Color("a9534d")         # danger / stress
const BLUE_400 := Color("7195a2")        # neutral info

# Spacing (GDD 167.4): the allowed steps on an 8 px base.
const SPACE_4 := 4
const SPACE_8 := 8
const SPACE_12 := 12
const SPACE_16 := 16
const SPACE_24 := 24
const SPACE_32 := 32
const SPACE_48 := 48

const RADIUS_PANEL := 12
const RADIUS_BUTTON := 10
const BORDER_WIDTH := 2

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


## Anchors a control to a layout preset at its full minimum size.
## Godot's own "minimum size" preset mode ignores custom_minimum_size, which
## leaves a larger control hanging off its anchor; sizing first and keeping
## that size puts it exactly where the preset says.
static func anchor_at(control: Control, preset: Control.LayoutPreset) -> void:
	control.reset_size()
	control.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_KEEP_SIZE)


## Light text with a dark outline: readable over any part of the 3D scene.
static func outline_text(label: Label, font_size: int, color: Color = CREAM_50, outline: int = 9) -> void:
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", INK_900)
	label.add_theme_constant_override(&"outline_size", outline)
