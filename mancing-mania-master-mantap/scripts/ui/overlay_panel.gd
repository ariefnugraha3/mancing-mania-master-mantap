class_name OverlayPanel
extends CanvasLayer
## Shared base for modal overlays: a warm dimmed backdrop that blocks the
## screen behind it and a centred card that always fits inside the safe area.
##
## The card wears its title on a ribbon that overlaps its top edge, has a body
## that scrolls when it is taller than the screen, and a fixed footer for the
## main buttons. It pops in with a small springy scale (skipped with Reduced
## Motion). Subclasses fill `content` and `footer` in build_content() and call
## show_overlay()/hide_overlay().

signal closed()

const DIM_COLOR := UiTokens.BACKDROP
## Every overlay on screen is in this group, so a dialogue under one knows
## the overlay has the controls.
const OPEN_GROUP := &"open_overlays"
## Gap between the card and the safe area's edges (phone, tablet).
const SCREEN_MARGIN := UiTokens.SPACE_12
const SCREEN_MARGIN_TABLET := UiTokens.SPACE_32
## How far the ribbon reaches down over the card's top edge.
const RIBBON_OVERLAP := 22

## Room kept around the controls of the scrolling body: a button's shadow
## reaches 6 pt to the sides and 9 pt below, its focus ring 6 pt all round.
const SHADOW_ROOM_SIDE := 8
const SHADOW_ROOM_TOP := 8
const SHADOW_ROOM_BOTTOM := 12

## Preferred panel width at the reference resolution; it shrinks on narrow screens.
@export var panel_width: float = 520.0
## The footer's buttons stand one under another. Buttons that would not fit
## side by side are stacked anyway, so the card never grows past the screen.
var stack_footer: bool = false

## Scrollable body.
var content: VBoxContainer
## Fixed row under the body; stays visible while the body scrolls.
var footer: BoxContainer

var _dim: ColorRect
var _centre: CenterContainer
var _stack: VBoxContainer
var _ribbon: PanelContainer
var _panel: PanelContainer
var _title_label: Label
var _scroll: ScrollContainer
var _body_padding: MarginContainer
var _tween: Tween
var _gameplay_input_was_enabled: bool = true
## Under 1 only when the card is still wider than the screen after its
## captions wrapped (the largest UI and text sizes on a small phone): the
## whole card shrinks that much so none of it is cut off.
var _fit_scale: float = 1.0
## The pop-in animation's own scale, on top of _fit_scale.
var _pop: float = 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_frame()
	build_content()
	_apply_overlap()
	get_viewport().size_changed.connect(fit_to_screen)
	PlatformService.safe_area_changed.connect(fit_to_screen)
	content.minimum_size_changed.connect(fit_to_screen)
	# A wrapped caption only knows its height after a layout pass.
	footer.minimum_size_changed.connect(fit_to_screen)
	fit_to_screen()


## Subclasses add their controls to `content` and `footer` here.
func build_content() -> void:
	pass


## Subclasses decide what the cancel action (Esc / Android back) does.
func on_cancel() -> void:
	hide_overlay()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(InputActions.UI_CANCEL) and not event.is_echo():
		get_viewport().set_input_as_handled()
		on_cancel()


## The ribbon title. A header-sized title (small dialogs) gets a smaller ribbon.
func set_title(text: String, type_variation: StringName = UiTokens.TYPE_SCREEN_TITLE) -> void:
	_title_label.text = text
	_title_label.theme_type_variation = UiTokens.TYPE_RIBBON_LABEL
	var small := type_variation == UiTokens.TYPE_HEADER or type_variation == UiTokens.TYPE_SMALL
	_title_label.add_theme_font_size_override(&"font_size", DisplaySettings.text_size(UiTokens.FONT_HEADER - 2 if small else UiTokens.FONT_SCREEN_TITLE - 4))
	_ribbon.visible = text != ""
	_title_label.visible = text != ""
	_apply_overlap()


func show_overlay() -> void:
	if visible:
		return
	_gameplay_input_was_enabled = InputManager.is_gameplay_input_enabled()
	InputManager.set_gameplay_input_enabled(false)
	visible = true
	add_to_group(OPEN_GROUP)
	fit_to_screen()
	_animate()
	# Wrapped text only knows its height after one layout pass at the final width.
	await get_tree().process_frame
	fit_to_screen()


func hide_overlay() -> void:
	if not visible:
		return
	visible = false
	remove_from_group(OPEN_GROUP)
	InputManager.set_gameplay_input_enabled(_gameplay_input_was_enabled)
	closed.emit()


func is_open() -> bool:
	return visible


## Gives keyboard focus to `control` on the next frame, once layout settled.
## The gold ring only shows for a keyboard or gamepad player (GDD 167).
## Safe when the control or this overlay went away in the meantime.
func focus_later(control: Control) -> void:
	await get_tree().process_frame
	if visible and is_instance_valid(control) and control.is_inside_tree():
		InputManager.give_focus(control)


func make_label(text: String, type_variation: StringName = &"") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if type_variation != &"":
		label.theme_type_variation = type_variation
	return label


func make_button(text: String, type_variation: StringName = &"") -> GameButton:
	var button := GameButton.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if type_variation != &"":
		button.theme_type_variation = type_variation
	return button


## Sizes the panel for the current screen: no wider than the safe area, and
## the body scrolls instead of letting the panel grow past the screen height.
func fit_to_screen() -> void:
	if _panel == null:
		return
	var safe := Rect2(PlatformService.get_safe_rect())
	var margin := float(SCREEN_MARGIN_TABLET if PlatformService.is_tablet() else SCREEN_MARGIN)
	_panel.custom_minimum_size.x = minf(panel_width, safe.size.x - margin * 2.0)
	# Inside the card: less its padding and the shadow room of body and footer.
	var inner := _panel.custom_minimum_size.x - _panel.get_theme_stylebox(&"panel").get_minimum_size().x - float(SHADOW_ROOM_SIDE) * 2.0
	_fit_buttons(inner)
	_fit_footer(inner)

	_title_label.custom_minimum_size.x = 0.0
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	var ribbon_room := _panel.custom_minimum_size.x - UiTokens.SPACE_48
	# A long title wraps between words. One word too long for the ribbon stays
	# whole, and the card shrinks to fit instead (_place_card).
	var title_font := _title_label.get_theme_font(&"font")
	var title_size := _title_label.get_theme_font_size(&"font_size")
	if _title_label.get_minimum_size().x > ribbon_room and longest_word_width(title_font, title_size, _title_label.text) <= ribbon_room:
		_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_title_label.custom_minimum_size.x = ribbon_room

	_scroll.custom_minimum_size.y = 0.0
	var chrome_height := _stack.get_combined_minimum_size().y
	var body_room := safe.size.y - margin * 2.0 - chrome_height
	var body_height := _body_padding.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = maxf(minf(body_height, body_room), 0.0)
	_place_card(safe.grow(-margin))


## The card sits in the middle of the screen. A camera hole or a notch makes
## the safe area lopsided (taller at the top than at the bottom), so the card
## is centred on the screen itself and moved only as far as it takes to stay
## inside `room`, the safe area less the margin.
func _place_card(room: Rect2) -> void:
	if _centre == null:
		return
	var canvas := get_viewport().get_visible_rect().size
	var card := _stack.get_combined_minimum_size()
	_fit_scale = minf(1.0, room.size.x / card.x) if card.x > 0.0 else 1.0
	_stack.pivot_offset = card * 0.5
	_set_pop(_pop)
	var half := card * 0.5 * _fit_scale
	var centre := canvas * 0.5
	for axis: int in 2:
		var low := room.position[axis] + half[axis]
		var high := room.end[axis] - half[axis]
		centre[axis] = clampf(centre[axis], low, high) if low <= high else room.get_center()[axis]
	# The widest box around that point that stays on the canvas; the
	# CenterContainer puts the card in its middle.
	var reach := centre.min(canvas - centre).max(Vector2.ZERO)
	_centre.offset_left = centre.x - reach.x
	_centre.offset_top = centre.y - reach.y
	_centre.offset_right = centre.x + reach.x - canvas.x
	_centre.offset_bottom = centre.y + reach.y - canvas.y


## Side by side only when the buttons fit the card: a footer wider than the
## card stretched it past the right edge of a phone (Settings > Controls and
## Settings > Privacy did, with two and three buttons in a row).
func _fit_footer(room: float) -> void:
	var width := 0.0
	var count := 0
	for child: Node in footer.get_children():
		var control := child as Control
		if control != null and control.visible and not control.is_queued_for_deletion():
			width += one_line_width(control as Button) if control is Button else control.get_combined_minimum_size().x
			count += 1
	width += float(maxi(count - 1, 0) * footer.get_theme_constant(&"separation"))
	var stacked := stack_footer or width > room
	if footer.vertical != stacked:
		footer.vertical = stacked


## A caption too long for one line wraps onto a second one instead of making
## the card wider than the screen (long Indonesian captions, 150% text). A
## button in a row shares the row with its neighbours; a caption that fits
## stays on one line.
func _fit_buttons(room: float) -> void:
	# A long body shows a scroll bar beside it, which takes from its width.
	var body_room := room - _scroll.get_v_scroll_bar().get_combined_minimum_size().x
	for node: Node in _panel.find_children("*", "Button", true, false):
		var button := node as Button
		var space := body_room if _scroll.is_ancestor_of(button) else room
		var row := button.get_parent() as HBoxContainer
		if row != null:
			space -= row.get_combined_minimum_size().x - button.get_combined_minimum_size().x
		# Only between words: a word too long for the button stays whole, and
		# the card shrinks to fit instead (_place_card).
		var wrap := one_line_width(button) > space and one_line_width(button, true) <= space
		var mode := TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
		if button.autowrap_mode != mode:
			button.autowrap_mode = mode


## How wide `button` is with its caption on one line, icon and padding
## included; with `longest_word`, with only its longest word.
static func one_line_width(button: Button, longest_word: bool = false) -> float:
	var style := button.get_theme_stylebox(&"normal")
	var font := button.get_theme_font(&"font")
	var width := style.get_minimum_size().x if style != null else 0.0
	if font != null and button.text != "":
		var font_size := button.get_theme_font_size(&"font_size")
		width += longest_word_width(font, font_size, button.text) if longest_word else font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var icon_side := 0.0
	if button.icon != null:
		icon_side = float(button.icon.get_width())
	elif button is GameButton and (button as GameButton).icon_id != &"":
		icon_side = float((button as GameButton).icon_pixels)
	var cap := button.get_theme_constant(&"icon_max_width")
	if cap > 0:
		icon_side = minf(icon_side, float(cap))
	if icon_side > 0.0:
		width += icon_side + float(button.get_theme_constant(&"h_separation"))
	return maxf(width, button.custom_minimum_size.x)


static func longest_word_width(font: Font, font_size: int, text: String) -> float:
	var widest := 0.0
	for word: String in text.split(" ", false):
		widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)
	return widest


func _build_frame() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = DIM_COLOR
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	var centre := CenterContainer.new()
	centre.name = "Centre"
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	# A card that is still too big grows out on both sides alike, never to
	# the right only.
	centre.grow_horizontal = Control.GROW_DIRECTION_BOTH
	centre.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(centre)
	_centre = centre

	# The ribbon and the card share a column; a negative gap lets the ribbon
	# hang over the card's top edge, and it draws on top of it.
	_stack = VBoxContainer.new()
	_stack.name = "Stack"
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(_stack)

	_ribbon = PanelContainer.new()
	_ribbon.name = "Ribbon"
	_ribbon.theme_type_variation = UiTokens.TYPE_RIBBON_PANEL
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ribbon.z_index = 1
	_ribbon.visible = false
	_stack.add_child(_ribbon)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.theme_type_variation = UiTokens.TYPE_RIBBON_LABEL
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.visible = false
	_ribbon.add_child(_title_label)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_stack.add_child(_panel)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	# The body's bottom shadow room already separates it from the footer.
	layout.add_theme_constant_override(&"separation", UiTokens.SPACE_12 - SHADOW_ROOM_BOTTOM + UiTokens.SPACE_4)
	_panel.add_child(layout)

	_scroll = ScrollContainer.new()
	_scroll.name = "Body"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	layout.add_child(_scroll)
	# A finger drags a long body from anywhere on it, buttons included.
	TouchScroll.attach(_scroll)

	# A scroll area clips what it holds to its own rectangle. Buttons cast a
	# shadow (6 pt to the sides, 9 pt below) and draw a focus ring 6 pt
	# outside themselves, so the body keeps that much room around its
	# controls; without it the shadows were cut off square at the edges.
	_body_padding = _shadow_room("BodyPadding")
	_body_padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body_padding)

	content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	_body_padding.add_child(content)

	# The footer gets the same side room, so its buttons line up with the
	# body's.
	var footer_padding := _shadow_room("FooterPadding")
	footer_padding.add_theme_constant_override(&"margin_top", 0)
	footer_padding.add_theme_constant_override(&"margin_bottom", 0)
	layout.add_child(footer_padding)
	footer = BoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	footer_padding.add_child(footer)


## Room for button shadows and focus rings around a clipped area.
static func _shadow_room(node_name: String) -> MarginContainer:
	var room := MarginContainer.new()
	room.name = node_name
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_theme_constant_override(&"margin_left", SHADOW_ROOM_SIDE)
	room.add_theme_constant_override(&"margin_right", SHADOW_ROOM_SIDE)
	room.add_theme_constant_override(&"margin_top", SHADOW_ROOM_TOP)
	room.add_theme_constant_override(&"margin_bottom", SHADOW_ROOM_BOTTOM)
	return room


## The card overlaps the ribbon's lower half only when there is a title.
func _apply_overlap() -> void:
	var card := _panel.get_theme_stylebox(&"panel").duplicate() as StyleBoxFlat
	if card == null:
		return
	var base := UiSkin.card()
	# The body and footer keep shadow room of their own, so the card's own
	# margin gives that much back and the buttons sit where they always did.
	card.content_margin_left = base.content_margin_left - SHADOW_ROOM_SIDE
	card.content_margin_right = base.content_margin_right - SHADOW_ROOM_SIDE
	card.content_margin_top = base.content_margin_top - SHADOW_ROOM_TOP + (float(RIBBON_OVERLAP) - 4.0 if _ribbon.visible else 0.0)
	_panel.add_theme_stylebox_override(&"panel", card)
	_stack.add_theme_constant_override(&"separation", -RIBBON_OVERLAP if _ribbon.visible else 0)


func _set_pop(value: float) -> void:
	_pop = value
	_stack.scale = Vector2.ONE * _pop * _fit_scale


func _animate() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_dim.modulate.a = 1.0
	_stack.modulate.a = 1.0
	_set_pop(1.0)
	if GameState.get_setting(&"reduced_motion"):
		return
	_dim.modulate.a = 0.0
	_stack.modulate.a = 0.0
	_stack.pivot_offset = _stack.get_combined_minimum_size() * 0.5
	_set_pop(0.92)
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(_dim, "modulate:a", 1.0, UiTokens.MODAL_SEC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_stack, "modulate:a", 1.0, UiTokens.MODAL_SEC * 0.7).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_pop, 0.92, 1.0, UiTokens.MODAL_SEC + 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
