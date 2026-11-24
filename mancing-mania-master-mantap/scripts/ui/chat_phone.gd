class_name ChatPhone
extends Control
## The phone in story scenes (GDD 168.3), drawn as the kind of chat app every
## player already reads at a glance: a status bar, a teal header with the
## contact's avatar and name, a doodled wallpaper, message bubbles with tails,
## times and read ticks, and a message bar at the bottom. Calls get a
## full-screen call view with a running timer.
##
## The layout is a familiar chat app's; the look is the game's own (warm
## palette, Fredoka, sticker icons), with no real app's name, logo or colours.
##
## What the story shows maps onto it like this:
##   - a chat line: a bubble in that person's thread (Darto's on the right);
##   - a notification: a message from the CepatCash business account;
##   - a phone line ("TOTAL DEBT: Rp ..."): an account card in the middle;
##   - a call: the call view.
## Showing something from another contact switches threads, the way you
## would leave one chat and open another.

const SCREEN_INSET := 7.0
const OUTER_RADIUS := 34
const SCREEN_RADIUS := 27.0
const STATUS_HEIGHT := 24.0
const HEADER_HEIGHT := 54.0
const INPUT_HEIGHT := 52.0
const CHAT_MARGIN := 14.0
## A bubble is at most this share of the chat's width.
const BUBBLE_SHARE := 0.8

const BODY := Color("3a2a20")
const BODY_RIM := Color("634a3a")
const STATUS := Color("356c65")
const HEADER := Color("3e7d75")
const CALL_TOP := Color("3e7d75")
const CALL_BOTTOM := Color("1f3d39")
const WALLPAPER := Color("efe5d3")
const DOODLE := Color(0.45, 0.33, 0.22, 0.11)
const INCOMING := Color("fffbf3")
const OUTGOING := Color("ddf1c4")
const INFO_CHIP := Color("fbeab9")
const DATE_CHIP := Color(1.0, 0.98, 0.93, 0.94)
const META := Color(0.43, 0.32, 0.25, 0.78)
const READ_TICKS := Color("3f9bc4")
const HEADER_TEXT := UiTokens.CREAM_50
const END_CALL := UiTokens.RED_500

const CEPATCASH := &"cepatcash"
## Avatar look per contact; anyone else gets a periwinkle initial.
const CONTACTS: Dictionary = {
	CEPATCASH: {"color": UiTokens.TERRACOTTA_500, "icon": IconPainter.CASH, "business": true},
	&"rini": {"color": DioramaStyle.STRAWBERRY},
	&"nisa": {"color": DioramaStyle.CUSTARD},
}

var _contact: StringName = &""
## Kind of the last row: "", "date", "info", "in" or "out". A new kind gets a
## little more air above it, and the first bubble of a run gets the tail.
var _last_kind := ""
var _call_seconds := 0.0

var _screen: ScreenMask
var _header: Control
var _avatar: Avatar
var _name_label: Label
var _badge: Glyph
var _subtitle: Label
var _chat: Control
var _list: VBoxContainer
var _input: InputBar
var _call: CallView
var _status: StatusBar


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen = ScreenMask.new()
	_screen.name = "Screen"
	add_child(_screen)
	var wallpaper := Wallpaper.new()
	wallpaper.name = "Wallpaper"
	_screen.add_child(wallpaper)
	wallpaper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_header()
	_chat = Control.new()
	_chat.name = "Chat"
	_chat.clip_contents = true
	_screen.add_child(_chat)
	_list = VBoxContainer.new()
	_list.name = "Messages"
	_list.add_theme_constant_override(&"separation", 3)
	_chat.add_child(_list)
	# The newest message sits at the bottom; older ones scroll off the top.
	_list.anchor_left = 0.0
	_list.anchor_right = 1.0
	_list.anchor_top = 1.0
	_list.anchor_bottom = 1.0
	_list.offset_left = CHAT_MARGIN
	_list.offset_right = -CHAT_MARGIN
	_list.offset_bottom = -8.0
	_list.offset_top = -8.0
	_list.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_input = InputBar.new()
	_input.name = "MessageBar"
	_screen.add_child(_input)
	_call = CallView.new()
	_call.name = "CallView"
	_call.visible = false
	_screen.add_child(_call)
	_status = StatusBar.new()
	_status.name = "StatusBar"
	_screen.add_child(_status)
	_quiet(self)
	resized.connect(_layout)
	_layout()


func _process(delta: float) -> void:
	if _call.visible:
		_call_seconds += delta
		_call.set_seconds(_call_seconds)


# --- What the story shows --------------------------------------------------------

## True while a thread or a call is on screen.
func is_open() -> bool:
	return visible


func get_contact() -> StringName:
	return _contact


## Opens the chat with `contact`, or keeps it if it is already open.
func open_thread(contact: StringName, display_name: String) -> void:
	visible = true
	_call.visible = false
	if contact == _contact:
		return
	_contact = contact
	_last_kind = ""
	_clear_list()
	var look: Dictionary = CONTACTS.get(contact, {})
	_avatar.setup(display_name, look.get("color", UiTokens.BLUE_400), look.get("icon", &""))
	_name_label.text = display_name
	var business := bool(look.get("business", false))
	_badge.visible = business
	_subtitle.text = TextDb.t(&"story.phone.business" if business else &"story.phone.online")
	_start_row("date")
	_add(_date_chip(), false)


## A message bubble. `title` is a bold first line (a business message's heading).
func add_message(text: String, outgoing: bool, title: String = "") -> void:
	var kind := "out" if outgoing else "in"
	var first_of_run := _last_kind != kind
	_start_row(kind)
	_add(_bubble(text, outgoing, title, first_of_run), true)


## An account card in the middle of the chat: "TOTAL DEBT: Rp 2,000,000" shows
## its label small and its amount large.
func add_info(text: String) -> void:
	_start_row("info")
	_add(_info_chip(text), true)


## The call view for `contact`, with a timer that starts at 00:00.
func show_call(contact: StringName, display_name: String) -> void:
	visible = true
	var look: Dictionary = CONTACTS.get(contact, {})
	_call.setup(display_name, look.get("color", UiTokens.BLUE_400), look.get("icon", &""))
	_call_seconds = 0.0
	_call.set_seconds(0.0)
	_call.visible = true


func close() -> void:
	visible = false
	_call.visible = false
	_contact = &""
	_last_kind = ""
	_clear_list()


## Every text on the phone's chat, top to bottom (for tests).
func get_chat_text() -> String:
	var lines := PackedStringArray()
	for label: Node in _list.find_children("*", "Label", true, false):
		lines.append((label as Label).text)
	return "\n".join(lines)


func get_message_count() -> int:
	var count := 0
	for child: Node in _list.get_children():
		if child is Bubble:
			count += 1
	return count


func is_call_visible() -> bool:
	return visible and _call.visible


# --- Building ----------------------------------------------------------------

func _build_header() -> void:
	_header = PanelContainer.new()
	_header.name = "Header"
	var header_style := StyleBoxFlat.new()
	header_style.bg_color = HEADER
	header_style.content_margin_left = 6.0
	header_style.content_margin_right = 8.0
	_header.add_theme_stylebox_override(&"panel", header_style)
	_screen.add_child(_header)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 6)
	_header.add_child(row)
	var back := Glyph.new(&"back", HEADER_TEXT, 22.0)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	_avatar = Avatar.new()
	_avatar.custom_minimum_size = Vector2(36, 36)
	_avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_avatar)
	var names := VBoxContainer.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.add_theme_constant_override(&"separation", -2)
	row.add_child(names)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override(&"separation", 4)
	names.add_child(name_row)
	_name_label = _label(DisplaySettings.text_size(UiTokens.FONT_SMALL + 1), HEADER_TEXT, UiSkin.bold_font())
	name_row.add_child(_name_label)
	_badge = Glyph.new(&"verified", UiTokens.SUN_500, 15.0)
	_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(_badge)
	_subtitle = _label(12, Color(HEADER_TEXT, 0.82))
	names.add_child(_subtitle)
	for kind: StringName in [&"video", &"call", &"dots"]:
		var glyph := Glyph.new(kind, HEADER_TEXT, 20.0 if kind != &"dots" else 16.0)
		glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(glyph)


func _bubble(text: String, outgoing: bool, title: String, tail: bool) -> Bubble:
	var bubble := Bubble.new()
	bubble.name = "Bubble"
	bubble.outgoing = outgoing
	bubble.tail = tail
	bubble.fill = OUTGOING if outgoing else INCOMING
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_END if outgoing else Control.SIZE_SHRINK_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = bubble.fill
	style.set_corner_radius_all(11)
	if tail:
		if outgoing:
			style.corner_radius_top_right = 0
		else:
			style.corner_radius_top_left = 0
	style.border_width_bottom = 2
	style.border_color = bubble.fill.lerp(UiTokens.INK_900, 0.14)
	style.content_margin_left = 10.0
	style.content_margin_right = 9.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 5.0
	style.anti_aliasing = true
	bubble.add_theme_stylebox_override(&"panel", style)

	var max_width := maxf(120.0, (_chat.size.x - CHAT_MARGIN * 2.0) * BUBBLE_SHARE - 19.0)
	var body_size := DisplaySettings.text_size(UiTokens.FONT_SMALL)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 1)
	bubble.add_child(column)
	if title != "":
		var heading := _label(body_size, UiTokens.TERRACOTTA_500.lerp(UiTokens.INK_900, 0.15), UiSkin.bold_font())
		_fit(heading, title, max_width)
		column.add_child(heading)
	var label := _label(body_size, UiTokens.INK_900)
	var text_width := _fit(label, text, max_width)
	var meta := _meta(outgoing)
	# Measured by hand: a label outside the tree has no font to measure with.
	var meta_width := UiSkin.regular_font().get_string_size(TextDb.t(&"story.phone.time"), HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + (19.0 if outgoing else 0.0)
	if not text.contains("\n") and text_width + meta_width + 10.0 <= max_width:
		# Short message: the time sits on the same line, like a real chat.
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 10)
		line.add_child(label)
		meta.size_flags_vertical = Control.SIZE_SHRINK_END
		line.add_child(meta)
		column.add_child(line)
	else:
		column.add_child(label)
		meta.size_flags_horizontal = Control.SIZE_SHRINK_END
		column.add_child(meta)
	return bubble


## Sets the label's text and a width that wraps only when it must.
func _fit(label: Label, text: String, max_width: float) -> float:
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var font: Font = label.get_theme_font(&"font") if label.has_theme_font_override(&"font") else UiSkin.regular_font()
	var font_size := label.get_theme_font_size(&"font_size")
	var width := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 2.0
	label.custom_minimum_size.x = minf(width, max_width)
	return minf(width, max_width)


## The time and, on Darto's messages, two read ticks.
func _meta(outgoing: bool) -> HBoxContainer:
	var meta := HBoxContainer.new()
	meta.add_theme_constant_override(&"separation", 3)
	meta.add_child(_label(11, META, null, TextDb.t(&"story.phone.time")))
	if outgoing:
		var ticks := Glyph.new(&"ticks", READ_TICKS, 16.0)
		ticks.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meta.add_child(ticks)
	return meta


func _info_chip(text: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "InfoCard"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = INFO_CHIP
	style.set_corner_radius_all(12)
	style.border_width_bottom = 2
	style.border_color = INFO_CHIP.lerp(UiTokens.INK_900, 0.16)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 6.0
	style.anti_aliasing = true
	chip.add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", -2)
	chip.add_child(column)
	var split := text.rfind(": ")
	if split > 0:
		var caption := _label(12, UiTokens.INK_700, UiSkin.bold_font(), text.substr(0, split))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		var amount := _label(DisplaySettings.text_size(UiTokens.FONT_BODY + 2), UiTokens.INK_900, UiSkin.bold_font(), text.substr(split + 2))
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(amount)
	else:
		var only := _label(DisplaySettings.text_size(UiTokens.FONT_SMALL), UiTokens.INK_900, UiSkin.bold_font(), text)
		only.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(only)
	return chip


func _date_chip() -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "DateChip"
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = DATE_CHIP
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 2.0
	style.content_margin_bottom = 3.0
	style.anti_aliasing = true
	chip.add_theme_stylebox_override(&"panel", style)
	chip.add_child(_label(11, UiTokens.INK_700, UiSkin.bold_font(), TextDb.t(&"story.phone.today")))
	return chip


func _label(font_size: int, color: Color, font: Font = null, text: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_constant_override(&"line_spacing", 2)
	label.add_theme_font_override(&"font", font if font != null else UiSkin.regular_font())
	return label


## Air above a new row: more between different kinds, a little between cards.
func _start_row(kind: String) -> void:
	var space := 0.0
	if _last_kind != "" and _last_kind != kind:
		space = 7.0
	elif kind == "info" and _last_kind == "info":
		space = 3.0
	if space > 0.0:
		var gap := Control.new()
		gap.name = "Gap"
		gap.custom_minimum_size.y = space
		_add(gap, false)
	_last_kind = kind


## Adds a row to the chat; `pop` makes it pop in unless motion is reduced.
func _add(node: Control, pop: bool) -> void:
	_quiet(node)
	_list.add_child(node)
	if not pop or bool(GameState.get_setting(&"reduced_motion")):
		return
	node.modulate.a = 0.0
	await get_tree().process_frame
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	var anchor_x := node.size.x * 0.5
	if node is Bubble:
		anchor_x = node.size.x if (node as Bubble).outgoing else 0.0
	node.pivot_offset = Vector2(anchor_x, node.size.y * 0.5)
	node.scale = Vector2(0.86, 0.86)
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "modulate:a", 1.0, 0.12)
	tween.tween_property(node, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _clear_list() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()


## The phone never takes a tap: a tap anywhere advances the story.
func _quiet(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		_quiet(child)


func _layout() -> void:
	var screen := Rect2(Vector2(SCREEN_INSET, SCREEN_INSET), size - Vector2(SCREEN_INSET, SCREEN_INSET) * 2.0)
	_screen.position = screen.position
	_screen.size = screen.size
	var width := screen.size.x
	_status.position = Vector2.ZERO
	_status.size = Vector2(width, STATUS_HEIGHT)
	_header.position = Vector2(0.0, STATUS_HEIGHT)
	_header.size = Vector2(width, HEADER_HEIGHT)
	_input.position = Vector2(0.0, screen.size.y - INPUT_HEIGHT)
	_input.size = Vector2(width, INPUT_HEIGHT)
	_chat.position = Vector2(0.0, STATUS_HEIGHT + HEADER_HEIGHT)
	_chat.size = Vector2(width, maxf(0.0, screen.size.y - STATUS_HEIGHT - HEADER_HEIGHT - INPUT_HEIGHT))
	_call.position = Vector2(0.0, STATUS_HEIGHT)
	_call.size = Vector2(width, screen.size.y - STATUS_HEIGHT)
	_screen.queue_redraw()
	queue_redraw()


func _draw() -> void:
	# A soft shadow, the cocoa body with a lighter rim, and two side buttons.
	var body := Rect2(Vector2.ZERO, size)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(UiTokens.INK_900, 0.28)
	shadow.set_corner_radius_all(OUTER_RADIUS)
	shadow.anti_aliasing = true
	draw_style_box(shadow, Rect2(body.position + Vector2(0, 7), body.size))
	draw_rect(Rect2(size.x - 1.0, 70.0, 4.0, 34.0), BODY_RIM)
	draw_rect(Rect2(size.x - 1.0, 116.0, 4.0, 52.0), BODY_RIM)
	var shell := StyleBoxFlat.new()
	shell.bg_color = BODY
	shell.border_color = BODY_RIM
	shell.set_border_width_all(2)
	shell.set_corner_radius_all(OUTER_RADIUS)
	shell.anti_aliasing = true
	draw_style_box(shell, body)


# --- Glyphs ------------------------------------------------------------------

## Draws one of the phone's small line glyphs into `rect` (24-unit grid).
static func draw_glyph(canvas: CanvasItem, kind: StringName, rect: Rect2, color: Color) -> void:
	var unit := minf(rect.size.x, rect.size.y) / 24.0
	var origin := rect.position + (rect.size - Vector2(24, 24) * unit) * 0.5
	canvas.draw_set_transform(origin, 0.0, Vector2(unit, unit))
	match kind:
		&"back":
			canvas.draw_polyline(PackedVector2Array([Vector2(15, 4.5), Vector2(7.5, 12), Vector2(15, 19.5)]), color, 2.8, true)
		&"video":
			_round_box(canvas, Rect2(2, 6.5, 13, 11), 2.6, color)
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(15.5, 12), Vector2(22, 7.5), Vector2(22, 16.5)]), color)
		&"call":
			_handset(canvas, Vector2(12, 12), 0.0, color)
		&"end":
			_handset(canvas, Vector2(12, 13.5), PI * 0.75, color)
		&"dots":
			for y: float in [5.0, 12.0, 19.0]:
				canvas.draw_circle(Vector2(12, y), 2.1, color, true, -1.0, true)
		&"smile":
			canvas.draw_arc(Vector2(12, 12), 8.6, 0.0, TAU, 32, color, 1.8, true)
			canvas.draw_arc(Vector2(12, 12.4), 4.6, 0.35, PI - 0.35, 12, color, 1.8, true)
			canvas.draw_circle(Vector2(9.0, 9.8), 1.25, color, true, -1.0, true)
			canvas.draw_circle(Vector2(15.0, 9.8), 1.25, color, true, -1.0, true)
		&"clip":
			var clip := PackedVector2Array()
			for point: Vector2 in [Vector2(15, 7), Vector2(15, 16)]:
				clip.append(point)
			clip.append_array(_arc_points(Vector2(12, 16), 3.0, 0.0, PI))
			clip.append(Vector2(9, 5.5))
			clip.append_array(_arc_points(Vector2(11, 5.5), 2.0, PI, TAU))
			clip.append(Vector2(13, 14))
			canvas.draw_polyline(clip, color, 1.8, true)
		&"camera":
			canvas.draw_rect(Rect2(3, 7.5, 18, 12.5), color, false, 1.8)
			canvas.draw_rect(Rect2(8.5, 4.8, 7, 2.8), color, true)
			canvas.draw_arc(Vector2(12, 13.8), 3.6, 0.0, TAU, 20, color, 1.8, true)
		&"mic":
			_round_box(canvas, Rect2(9, 3, 6, 12), 3.0, color)
			canvas.draw_arc(Vector2(12, 10.5), 6.2, 0.15, PI - 0.15, 14, color, 2.0, true)
			canvas.draw_line(Vector2(12, 16.8), Vector2(12, 20.5), color, 2.0, true)
			canvas.draw_line(Vector2(8.8, 20.6), Vector2(15.2, 20.6), color, 2.0, true)
		&"speaker":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(3, 9), Vector2(7.5, 9), Vector2(12.5, 4.5), Vector2(12.5, 19.5), Vector2(7.5, 15), Vector2(3, 15)]), color)
			canvas.draw_arc(Vector2(13, 12), 4.2, -0.9, 0.9, 10, color, 2.0, true)
			canvas.draw_arc(Vector2(13, 12), 7.6, -0.9, 0.9, 14, color, 2.0, true)
		&"mute":
			_round_box(canvas, Rect2(9, 3, 6, 12), 3.0, color)
			canvas.draw_arc(Vector2(12, 10.5), 6.2, 0.15, PI - 0.15, 14, color, 2.0, true)
			canvas.draw_line(Vector2(12, 16.8), Vector2(12, 20.5), color, 2.0, true)
			canvas.draw_line(Vector2(4.5, 4), Vector2(19.5, 20), color, 2.2, true)
		&"ticks":
			canvas.draw_polyline(PackedVector2Array([Vector2(1.5, 12.8), Vector2(5.6, 16.8), Vector2(13.6, 7.4)]), color, 2.0, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(9.0, 15.4), Vector2(10.4, 16.8), Vector2(18.4, 7.4)]), color, 2.0, true)
		&"verified":
			canvas.draw_circle(Vector2(12, 12), 10.0, color, true, -1.0, true)
			canvas.draw_polyline(PackedVector2Array([Vector2(7, 12.4), Vector2(10.6, 16), Vector2(17.2, 8.6)]), UiTokens.CREAM_50, 2.8, true)
		&"signal":
			for bar: int in 4:
				var height := 4.0 + 4.0 * float(bar)
				canvas.draw_rect(Rect2(3.0 + 5.0 * float(bar), 20.0 - height, 3.2, height), color)
		&"wifi":
			for ring: int in 3:
				canvas.draw_arc(Vector2(12, 19), 4.5 + 4.6 * float(ring), -PI * 0.78, -PI * 0.22, 12, color, 2.2, true)
			canvas.draw_circle(Vector2(12, 19), 1.6, color, true, -1.0, true)
		&"battery":
			canvas.draw_rect(Rect2(2, 7, 18, 10), color, false, 1.6)
			canvas.draw_rect(Rect2(20.5, 10, 2, 4), color, true)
			# Low battery, about as full as Darto's bank account.
			canvas.draw_rect(Rect2(3.6, 8.6, 4.2, 6.8), UiTokens.TERRACOTTA_500.lerp(Color.WHITE, 0.15), true)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _round_box(canvas: CanvasItem, rect: Rect2, radius: float, color: Color) -> void:
	var points := _rounded_rect_points(rect, radius)
	canvas.draw_colored_polygon(points, color)
	points.append(points[0])
	canvas.draw_polyline(points, color, 1.0, true)


static func _rounded_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var corners := [
		[Vector2(rect.end.x - r, rect.position.y + r), -PI * 0.5],
		[rect.end - Vector2(r, r), 0.0],
		[Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5],
		[rect.position + Vector2(r, r), PI],
	]
	for corner: Array in corners:
		for step: int in 6:
			points.append(corner[0] + Vector2.from_angle(corner[1] + PI * 0.5 * float(step) / 5.0) * r)
	return points


static func _arc_points(centre: Vector2, radius: float, from: float, to: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step: int in 9:
		points.append(centre + Vector2.from_angle(lerpf(from, to, float(step) / 8.0)) * radius)
	return points


## A telephone handset: a thick curved grip with an ear and a mouth piece.
static func _handset(canvas: CanvasItem, centre: Vector2, rotation: float, color: Color) -> void:
	var turn := Transform2D(rotation, centre)
	var grip := PackedVector2Array()
	for point: Vector2 in _arc_points(Vector2(4.0, -4.0), 11.0, PI * 0.52, PI * 0.98):
		grip.append(turn * point)
	canvas.draw_polyline(grip, color, 4.2, true)
	canvas.draw_circle(grip[0], 3.3, color, true, -1.0, true)
	canvas.draw_circle(grip[grip.size() - 1], 3.3, color, true, -1.0, true)


# --- Parts ---------------------------------------------------------------------

## A small chrome glyph in a fixed colour.
class Glyph extends Control:
	var kind: StringName
	var color: Color

	func _init(glyph_kind: StringName = &"", glyph_color: Color = Color.WHITE, side: float = 20.0) -> void:
		kind = glyph_kind
		color = glyph_color
		custom_minimum_size = Vector2(side, side)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		ChatPhone.draw_glyph(self, kind, Rect2(Vector2.ZERO, size), color)


## A round avatar: a sticker icon, or the contact's initial on a colour.
class Avatar extends Control:
	var fill: Color = UiTokens.BLUE_400
	var initial: String = ""
	var icon: StringName = &""

	func setup(display_name: String, colour: Color, icon_id: StringName) -> void:
		fill = colour
		icon = icon_id
		initial = display_name.substr(0, 1).to_upper()
		queue_redraw()

	func _draw() -> void:
		var radius := minf(size.x, size.y) * 0.5
		var centre := size * 0.5
		draw_circle(centre, radius, fill.lerp(UiTokens.INK_900, 0.25), true, -1.0, true)
		draw_circle(centre, radius - maxf(1.5, radius * 0.07), fill, true, -1.0, true)
		if icon != &"":
			IconPainter.paint(get_canvas_item(), icon, Rect2(centre - Vector2(radius, radius) * 0.72, Vector2(radius, radius) * 1.44), Color.WHITE)
			return
		var font := UiSkin.bold_font()
		var font_size := int(radius * 1.05)
		var width := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var baseline := centre.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		draw_string(font, Vector2(centre.x - width * 0.5, baseline), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiTokens.INK_900)


## A message bubble; the first of a run has a tail at its top corner.
class Bubble extends PanelContainer:
	var outgoing := false
	var tail := false
	var fill: Color = Color.WHITE

	func _draw() -> void:
		if not tail:
			return
		var points: PackedVector2Array
		if outgoing:
			points = PackedVector2Array([Vector2(size.x - 1.0, 0.0), Vector2(size.x + 8.0, 0.0), Vector2(size.x - 1.0, 11.0)])
		else:
			points = PackedVector2Array([Vector2(1.0, 0.0), Vector2(-8.0, 0.0), Vector2(1.0, 11.0)])
		draw_colored_polygon(points, fill)
		draw_polyline(PackedVector2Array([points[1], points[2]]), fill, 1.2, true)


## The doodled wallpaper behind the chat: tiny fish, hooks, bubbles and
## stars, always in the same places.
class Wallpaper extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), WALLPAPER)
		var random := RandomNumberGenerator.new()
		random.seed = 1708
		var cell := 46.0
		var rows := int(ceil(size.y / cell)) + 1
		var columns := int(ceil(size.x / cell)) + 1
		for row: int in rows:
			for column: int in columns:
				var centre := Vector2((float(column) + (0.5 if row % 2 == 0 else 0.0)) * cell, float(row) * cell + 18.0)
				centre += Vector2(random.randf_range(-7.0, 7.0), random.randf_range(-7.0, 7.0))
				_doodle(random.randi() % 5, centre, random.randf_range(-0.5, 0.5))

	func _doodle(kind: int, centre: Vector2, angle: float) -> void:
		draw_set_transform(centre, angle, Vector2.ONE)
		match kind:
			0:
				# A fish.
				var body := PackedVector2Array()
				for step: int in 17:
					var t := TAU * float(step) / 16.0
					body.append(Vector2(cos(t) * 8.0, sin(t) * 4.6))
				draw_polyline(body, DOODLE, 1.6, true)
				draw_polyline(PackedVector2Array([Vector2(-7, 0), Vector2(-12.5, -4.5), Vector2(-12.5, 4.5), Vector2(-7, 0)]), DOODLE, 1.6, true)
				draw_circle(Vector2(4, -1), 1.0, DOODLE)
			1:
				# A hook.
				draw_line(Vector2(0, -9), Vector2(0, 3), DOODLE, 1.6, true)
				draw_arc(Vector2(-3.5, 3), 3.5, 0.0, PI, 10, DOODLE, 1.6, true)
				draw_circle(Vector2(0, -9.5), 1.6, DOODLE)
			2:
				# Bubbles.
				draw_arc(Vector2(0, 0), 4.0, 0.0, TAU, 14, DOODLE, 1.5, true)
				draw_arc(Vector2(6, -6), 2.4, 0.0, TAU, 10, DOODLE, 1.4, true)
				draw_arc(Vector2(-5, -8), 1.6, 0.0, TAU, 8, DOODLE, 1.3, true)
			3:
				# A star.
				var star := PackedVector2Array()
				for index: int in 11:
					var a := -PI * 0.5 + PI * 0.2 * float(index)
					star.append(Vector2.from_angle(a) * (6.0 if index % 2 == 0 else 2.8))
				draw_polyline(star, DOODLE, 1.5, true)
			_:
				# A little wave.
				var wave := PackedVector2Array()
				for step: int in 13:
					var x := -9.0 + 1.5 * float(step)
					wave.append(Vector2(x, sin(x * 0.7) * 2.6))
				draw_polyline(wave, DOODLE, 1.6, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The status bar: the clock, signal, wifi and a nearly empty battery.
class StatusBar extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), STATUS)
		var font := UiSkin.bold_font()
		draw_string(font, Vector2(18.0, 17.0), TextDb.t(&"story.phone.clock"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, HEADER_TEXT)
		# The camera punch hole in the middle of the bar.
		draw_circle(Vector2(size.x * 0.5, 12.0), 5.0, BODY, true, -1.0, true)
		var right := size.x - 16.0
		ChatPhone.draw_glyph(self, &"battery", Rect2(right - 22.0, 1.0, 22.0, 22.0), HEADER_TEXT)
		ChatPhone.draw_glyph(self, &"wifi", Rect2(right - 42.0, 3.0, 17.0, 17.0), HEADER_TEXT)
		ChatPhone.draw_glyph(self, &"signal", Rect2(right - 60.0, 3.0, 16.0, 16.0), HEADER_TEXT)


## The bar at the bottom: a rounded message field and a round mic button.
class InputBar extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var button := 38.0
		var field := Rect2(8.0, 7.0, size.x - 16.0 - button - 6.0, size.y - 14.0)
		var box := StyleBoxFlat.new()
		box.bg_color = INCOMING
		box.set_corner_radius_all(int(field.size.y * 0.5))
		box.border_width_bottom = 2
		box.border_color = INCOMING.lerp(UiTokens.INK_900, 0.12)
		box.anti_aliasing = true
		draw_style_box(box, field)
		var glyph_side := 20.0
		var glyph_y := field.position.y + (field.size.y - glyph_side) * 0.5
		ChatPhone.draw_glyph(self, &"smile", Rect2(field.position.x + 8.0, glyph_y, glyph_side, glyph_side), META)
		ChatPhone.draw_glyph(self, &"clip", Rect2(field.end.x - 52.0, glyph_y, glyph_side, glyph_side), META)
		ChatPhone.draw_glyph(self, &"camera", Rect2(field.end.x - 28.0, glyph_y, glyph_side, glyph_side), META)
		var font := UiSkin.regular_font()
		var font_size := 15
		var baseline := field.position.y + (field.size.y + font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
		draw_string(font, Vector2(field.position.x + 34.0, baseline), TextDb.t(&"story.phone.input"), HORIZONTAL_ALIGNMENT_LEFT, field.size.x - 96.0, font_size, META)
		var centre := Vector2(size.x - 8.0 - button * 0.5, size.y * 0.5)
		draw_circle(centre + Vector2(0, 1.5), button * 0.5, HEADER.lerp(UiTokens.INK_900, 0.3), true, -1.0, true)
		draw_circle(centre, button * 0.5, HEADER, true, -1.0, true)
		ChatPhone.draw_glyph(self, &"mic", Rect2(centre - Vector2(10, 10), Vector2(20, 20)), HEADER_TEXT)


## The screen: a rounded rectangle that masks everything on it, so the
## header, wallpaper and call view follow the screen's round corners exactly.
## (Covering square corners with body-coloured wedges instead left their tips
## sticking out past the body's larger outer curve.)
class ScreenMask extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY

	func _draw() -> void:
		var mask := StyleBoxFlat.new()
		mask.bg_color = Color.WHITE
		mask.set_corner_radius_all(int(SCREEN_RADIUS))
		mask.corner_detail = 16
		mask.anti_aliasing = true
		draw_style_box(mask, Rect2(Vector2.ZERO, size))


## The call screen: who is calling, a running timer, a pulsing avatar and
## the call buttons.
class CallView extends Control:
	var _name: Label
	var _timer: Label
	var _kind: Label
	var _avatar: Avatar
	var _clock := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_kind = _make_label(12, Color(HEADER_TEXT, 0.8), UiSkin.bold_font())
		_kind.text = TextDb.t(&"story.phone.call")
		_name = _make_label(DisplaySettings.text_size(UiTokens.FONT_HEADER + 2), HEADER_TEXT, UiSkin.bold_font())
		_timer = _make_label(15, Color(HEADER_TEXT, 0.88), UiSkin.regular_font())
		_avatar = Avatar.new()
		_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_avatar)
		resized.connect(_layout)

	func setup(display_name: String, colour: Color, icon_id: StringName) -> void:
		_name.text = display_name
		_avatar.setup(display_name, colour, icon_id)
		_clock = 0.0

	func set_seconds(seconds: float) -> void:
		var whole := int(seconds)
		_timer.text = "%02d:%02d" % [whole / 60, whole % 60]
		_clock = seconds
		queue_redraw()

	func _make_label(font_size: int, colour: Color, font: Font) -> Label:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.add_theme_font_size_override(&"font_size", font_size)
		label.add_theme_color_override(&"font_color", colour)
		label.add_theme_font_override(&"font", font)
		add_child(label)
		return label

	func _layout() -> void:
		var width := size.x
		_kind.position = Vector2(0, 16)
		_kind.size = Vector2(width, 18)
		_name.position = Vector2(0, 34)
		_name.size = Vector2(width, 34)
		_timer.position = Vector2(0, 70)
		_timer.size = Vector2(width, 22)
		var side := clampf(size.y * 0.3, 64.0, 104.0)
		_avatar.size = Vector2(side, side)
		_avatar.position = Vector2((width - side) * 0.5, _avatar_centre_y() - side * 0.5)
		queue_redraw()

	func _avatar_centre_y() -> float:
		return 104.0 + (size.y - 104.0 - 96.0) * 0.5

	func _draw() -> void:
		var colours := PackedColorArray([CALL_TOP, CALL_TOP, CALL_BOTTOM, CALL_BOTTOM])
		draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]), colours)
		# Two soft rings breathing out from the avatar.
		var centre := Vector2(size.x * 0.5, _avatar_centre_y())
		var radius := _avatar.size.x * 0.5
		var still := bool(GameState.get_setting(&"reduced_motion"))
		for ring: int in 2:
			var phase := 0.5 if still else fposmod(_clock * 0.6 + float(ring) * 0.5, 1.0)
			draw_circle(centre, radius + 6.0 + phase * 22.0, Color(HEADER_TEXT, 0.16 * (1.0 - phase)), true, -1.0, true)
		# The call buttons: speaker, mute and a red hang-up.
		var row_y := size.y - 52.0
		var spots := [[&"speaker", size.x * 0.22, 22.0, Color(HEADER_TEXT, 0.18)],
			[&"mute", size.x * 0.5, 22.0, Color(HEADER_TEXT, 0.18)],
			[&"end", size.x * 0.78, 27.0, END_CALL]]
		for spot: Array in spots:
			var spot_centre := Vector2(float(spot[1]), row_y)
			var spot_radius: float = spot[2]
			if spot[0] == &"end":
				draw_circle(spot_centre + Vector2(0, 2), spot_radius, END_CALL.lerp(UiTokens.INK_900, 0.35), true, -1.0, true)
			draw_circle(spot_centre, spot_radius, spot[3], true, -1.0, true)
			ChatPhone.draw_glyph(self, spot[0], Rect2(spot_centre - Vector2(12, 12), Vector2(24, 24)), HEADER_TEXT)
