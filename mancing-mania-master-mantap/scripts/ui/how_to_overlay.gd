class_name HowToOverlay
extends OverlayPanel
## How To Play (GDD 87): one short tab per system instead of a wall of text.
## The copy is the final text from GDD 183.19. Diagrams and input icons join
## in the art and UI polish milestone.
##
## Revision 6.12: eleven tabs never fit a phone's width, and Godot's tab bar
## only scrolled them with arrows a few points wide. The tab now shows as one
## title between two thumb-sized buttons that go straight to the previous and
## next tab. Every tab is the same size, the tallest page's, so the popup no
## longer jumps from tab to tab.

const TAB_IDS: Array[StringName] = [
	&"fishing", &"travel", &"boxing", &"arm_wrestle", &"dance", &"suwit",
	&"silat", &"tambang", &"gasing", &"pinang", &"market",
]
const BODY_HEIGHT := 300.0
const STEP_BUTTON := Vector2(56.0, 56.0)

var _tabs: TabContainer
var _close_button: GameButton
var _previous: GameButton
var _next: GameButton
var _tab_title: Label
var _pages: Array[VBoxContainer] = []
var _sized_for: float = -1.0


func build_content() -> void:
	layer = 50
	panel_width = 720.0
	set_title(TextDb.t(&"howto.title"))

	var bar := HBoxContainer.new()
	bar.name = "TabStepper"
	bar.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	content.add_child(bar)
	_previous = _step_button(IconPainter.ARROW_LEFT, -1)
	bar.add_child(_previous)
	_tab_title = Label.new()
	_tab_title.name = "TabTitle"
	_tab_title.theme_type_variation = UiTokens.TYPE_SECTION
	_tab_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tab_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# One line, as tall as the buttons, so every tab's popup is the same size;
	# a long title gets a smaller font instead of a second line.
	_tab_title.clip_text = true
	_tab_title.custom_minimum_size = Vector2(0.0, STEP_BUTTON.y)
	_tab_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_title.resized.connect(_fit_title)
	bar.add_child(_tab_title)
	_next = _step_button(IconPainter.ARROW_RIGHT, 1)
	bar.add_child(_next)

	_tabs = TabContainer.new()
	_tabs.tabs_visible = false
	_tabs.custom_minimum_size.y = BODY_HEIGHT
	_tabs.tab_changed.connect(_on_tab_changed)
	content.add_child(_tabs)

	for tab_id: StringName in TAB_IDS:
		var page := VBoxContainer.new()
		page.name = String(tab_id)
		page.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
		_tabs.add_child(page)
		_pages.append(page)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, TextDb.t(StringName("howto.tab.%s" % tab_id)))
		for line: String in TextDb.t(StringName("howto.body.%s" % tab_id)).split("\n"):
			page.add_child(make_label(line))

	_close_button = make_button(TextDb.t(&"common.close"), UiTokens.TYPE_CTA_BUTTON)
	_close_button.click_sfx = &"ui_back"
	_close_button.icon_id = IconPainter.CHECK
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)
	_tabs.resized.connect(_size_to_tallest_page)
	_refresh_stepper()


func open() -> void:
	_tabs.current_tab = 0
	_refresh_stepper()
	show_overlay()
	focus_later(_close_button)
	_size_to_tallest_page.call_deferred()


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	hide_overlay()


func get_tabs() -> TabContainer:
	return _tabs


func get_next_button() -> GameButton:
	return _next


func get_previous_button() -> GameButton:
	return _previous


func get_tab_title() -> String:
	return _tab_title.text


## Every tab as tall as the tallest page at the width the popup has now. The
## pages are measured from their text, since a hidden page has no width to
## wrap in.
func _size_to_tallest_page() -> void:
	var current := _tabs.get_current_tab_control()
	if current == null or current.size.x <= 1.0 or is_equal_approx(current.size.x, _sized_for):
		return
	_sized_for = current.size.x
	var tallest := 0.0
	for page: VBoxContainer in _pages:
		tallest = maxf(tallest, page_height(page, current.size.x))
	var overhead := _tabs.get_combined_minimum_size().y - current.get_combined_minimum_size().y
	_tabs.custom_minimum_size.y = maxf(BODY_HEIGHT, overhead + tallest)


## The height `page` needs at `width`: its wrapped lines and the gaps between.
static func page_height(page: VBoxContainer, width: float) -> float:
	var height := 0.0
	var labels := 0
	for child: Node in page.get_children():
		var label := child as Label
		if label == null:
			continue
		var font := label.get_theme_font(&"font")
		var font_size := label.get_theme_font_size(&"font_size")
		var line := font.get_height(font_size)
		var lines := maxf(roundf(font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size).y / line), 1.0)
		height += lines * (line + float(label.get_theme_constant(&"line_spacing")))
		labels += 1
	return height + float(maxi(labels - 1, 0) * page.get_theme_constant(&"separation"))


func _step_button(icon: StringName, step: int) -> GameButton:
	var button := GameButton.new()
	button.name = "Next" if step > 0 else "Previous"
	button.icon_id = icon
	button.custom_minimum_size = STEP_BUTTON
	button.tooltip_text = TextDb.t(&"howto.next" if step > 0 else &"howto.previous")
	button.pressed.connect(_step.bind(step))
	return button


func _step(step: int) -> void:
	var target := clampi(_tabs.current_tab + step, 0, _tabs.get_tab_count() - 1)
	if target != _tabs.current_tab:
		_tabs.current_tab = target


func _refresh_stepper() -> void:
	var index := _tabs.current_tab
	_tab_title.text = "%s · %d/%d" % [_tabs.get_tab_title(index), index + 1, _tabs.get_tab_count()]
	_previous.disabled = index <= 0
	_next.disabled = index >= _tabs.get_tab_count() - 1
	_fit_title()


## The title's font, from the section size down, until it fits on one line.
func _fit_title() -> void:
	var room := _tab_title.size.x - _tab_title.get_theme_stylebox(&"normal").get_minimum_size().x
	if room <= 1.0:
		return
	_tab_title.remove_theme_font_size_override(&"font_size")
	var font := _tab_title.get_theme_font(&"font")
	var font_size := _tab_title.get_theme_font_size(&"font_size")
	while font_size > 12 and font.get_string_size(_tab_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > room:
		font_size -= 1
	_tab_title.add_theme_font_size_override(&"font_size", font_size)


func _on_tab_changed(_tab: int) -> void:
	_refresh_stepper()
	if visible:
		AudioManager.play_ui(&"ui_click")
