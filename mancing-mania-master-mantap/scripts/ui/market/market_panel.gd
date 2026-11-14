class_name MarketPanel
extends VBoxContainer
## One page of Bu Yati's ledger (GDD 73, 167.9): a heading, a body that scrolls
## when the page is longer than the panel, and a fixed strip underneath for the
## buttons that act on the page.
##
## The five Market tabs extend this. A page only shows the current state and
## reports what the player asked for; MarketController does the transaction.

const RULE_COLOR := Color(0.353, 0.314, 0.275, 0.3)

## Scrollable part of the page.
var body: VBoxContainer
## Fixed strip under the body; stays visible while the body scrolls.
var actions: VBoxContainer

var _heading: Label
var _scroll: ScrollContainer
## Scrolling column: the body, and the actions when the page is short.
var _column: VBoxContainer
var _actions_scroll: bool = false


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override(&"separation", UiTokens.SPACE_8)

	_heading = make_label("", UiTokens.TYPE_HEADER)
	_heading.name = "Heading"
	add_child(_heading)
	add_child(make_rule())

	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	add_child(_scroll)

	# Room on the right keeps the numbers clear of the scroll bar.
	var padding := MarginContainer.new()
	padding.name = "Padding"
	padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padding.add_theme_constant_override(&"margin_right", UiTokens.SPACE_8)
	_scroll.add_child(padding)

	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	padding.add_child(_column)

	body = VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	_column.add_child(body)

	actions = VBoxContainer.new()
	actions.name = "Actions"
	actions.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	add_child(actions)

	build()
	refresh()


## Subclasses create their fixed controls here.
func build() -> void:
	pass


## Subclasses re-read the game state here. Called whenever it may have changed.
func refresh() -> void:
	pass


## The height this page needs with its action strip fixed under the list,
## leaving `list_room` for at least a line or two of the list.
func fixed_height(list_room: float = 72.0) -> float:
	var separation := float(get_theme_constant(&"separation"))
	return _heading.get_combined_minimum_size().y + 2.0 + list_room 		+ actions.get_combined_minimum_size().y + separation * 3.0


## Moves the action strip into the scrolling page (or back under it), so a
## short page (large text on a small phone) still reaches every button.
func set_actions_scroll(scrolls: bool) -> void:
	if scrolls == _actions_scroll:
		return
	_actions_scroll = scrolls
	actions.reparent(_column if scrolls else self, false)


func set_heading(text: String) -> void:
	_heading.text = text


## Scrolls the page back to its top, e.g. when its tab is opened.
func scroll_to_top() -> void:
	_scroll.scroll_vertical = 0


func make_label(text: String, type_variation: StringName = &"") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if type_variation != &"":
		label.theme_type_variation = type_variation
	return label


## A "name ........ value" ledger row added to `parent`. Returns the value label.
func add_value_row(parent: Container, text: String, type_variation: StringName = &"") -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var name_label := make_label(text, type_variation)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if type_variation != &"":
		value_label.theme_type_variation = type_variation
	row.add_child(value_label)
	return value_label


## A thin ruled line, like the lines of a ledger page.
func make_rule() -> ColorRect:
	var rule := ColorRect.new()
	rule.color = RULE_COLOR
	rule.custom_minimum_size.y = 2.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule


func make_button(text: String, type_variation: StringName = &"") -> GameButton:
	var button := GameButton.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if type_variation != &"":
		button.theme_type_variation = type_variation
	return button


## Narrows a button's side padding so several fit on one row.
func make_compact(button: Button, side_margin: int = UiTokens.SPACE_8) -> void:
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled"]:
		var box := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if box == null:
			continue
		box.content_margin_left = side_margin
		box.content_margin_right = side_margin
		button.add_theme_stylebox_override(state, box)


func clear_children(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
