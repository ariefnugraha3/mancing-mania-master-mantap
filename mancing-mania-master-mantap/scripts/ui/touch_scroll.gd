class_name TouchScroll
extends Node
## Lets a finger scroll a ScrollContainer by dragging anywhere on what it holds
## (revision 6.12).
##
## A ScrollContainer only follows a drag that reaches it, and cards
## (PanelContainer) and buttons stop the touch by default. A Market page full
## of cards could only be dragged in the thin gaps between them. Everything
## inside the scroll area therefore passes the touch on to it, except the
## controls that need the drag themselves (sliders). A button still gets its
## tap: the scroll only takes over after the finger travels DEADZONE points,
## and then cancels the press, so a drag never buys anything.

## Finger travel, in canvas points (about dp), before a touch becomes a
## scroll: Android's own touch slop.
const DEADZONE := 8

var _scroll: ScrollContainer


## Attaches the behaviour to `scroll`, for what it holds now and later.
static func attach(scroll: ScrollContainer) -> TouchScroll:
	var helper := TouchScroll.new()
	helper.name = "TouchScroll"
	helper._scroll = scroll
	scroll.scroll_deadzone = DEADZONE
	scroll.add_child(helper)
	return helper


## True when a touch that lands on `control` should reach the scroll area.
static func should_pass(control: Control) -> bool:
	return control.mouse_filter == Control.MOUSE_FILTER_STOP and not (control is Slider or control is ScrollBar or control is LineEdit or control is TextEdit)


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)
	for node: Node in _scroll.find_children("*", "Control", true, false):
		_pass(node as Control)


func _exit_tree() -> void:
	get_tree().node_added.disconnect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Control and _scroll.is_ancestor_of(node) and _scroll.get_v_scroll_bar() != node and _scroll.get_h_scroll_bar() != node:
		_pass(node as Control)


static func _pass(control: Control) -> void:
	if should_pass(control):
		control.mouse_filter = Control.MOUSE_FILTER_PASS
