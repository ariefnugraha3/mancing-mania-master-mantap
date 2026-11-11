class_name OverlayPanel
extends CanvasLayer
## Shared base for modal overlays: a dimmed backdrop that blocks the screen
## behind it and a centred panel that always fits inside the safe area.
##
## The panel has a fixed title, a body that scrolls when it is taller than the
## screen, and a fixed footer for the main buttons. Subclasses fill `content`
## and `footer` in build_content() and call show_overlay()/hide_overlay().

signal closed()

const DIM_COLOR := Color(0.208, 0.184, 0.161, 0.55)
const SCREEN_MARGIN := UiTokens.SPACE_24

## Preferred panel width at the reference resolution; it shrinks on narrow screens.
@export var panel_width: float = 520.0

## Scrollable body.
var content: VBoxContainer
## Fixed row under the body; stays visible while the body scrolls.
var footer: BoxContainer

var _dim: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _scroll: ScrollContainer
var _tween: Tween
var _gameplay_input_was_enabled: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_frame()
	build_content()
	get_viewport().size_changed.connect(fit_to_screen)
	content.minimum_size_changed.connect(fit_to_screen)
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


func set_title(text: String, type_variation: StringName = UiTokens.TYPE_SCREEN_TITLE) -> void:
	_title_label.text = text
	_title_label.theme_type_variation = type_variation
	_title_label.visible = text != ""


func show_overlay() -> void:
	if visible:
		return
	_gameplay_input_was_enabled = InputManager.is_gameplay_input_enabled()
	InputManager.set_gameplay_input_enabled(false)
	visible = true
	fit_to_screen()
	_animate()
	# Wrapped text only knows its height after one layout pass at the final width.
	await get_tree().process_frame
	fit_to_screen()


func hide_overlay() -> void:
	if not visible:
		return
	visible = false
	InputManager.set_gameplay_input_enabled(_gameplay_input_was_enabled)
	closed.emit()


func is_open() -> bool:
	return visible


## Gives keyboard focus to `control` on the next frame, once layout settled.
## Safe when the control or this overlay went away in the meantime.
func focus_later(control: Control) -> void:
	await get_tree().process_frame
	if visible and is_instance_valid(control) and control.is_inside_tree():
		control.grab_focus()


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
	var safe := PlatformService.get_safe_rect()
	_panel.custom_minimum_size.x = minf(panel_width, float(safe.size.x) - SCREEN_MARGIN * 2.0)

	_scroll.custom_minimum_size.y = 0.0
	var chrome_height := _panel.get_combined_minimum_size().y
	var body_room := float(safe.size.y) - SCREEN_MARGIN * 2.0 - chrome_height
	var body_height := content.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = maxf(minf(body_height, body_room), 0.0)


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
	add_child(centre)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	centre.add_child(_panel)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	_panel.add_child(layout)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.visible = false
	layout.add_child(_title_label)

	_scroll = ScrollContainer.new()
	_scroll.name = "Body"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	layout.add_child(_scroll)

	content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	_scroll.add_child(content)

	footer = BoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
	layout.add_child(footer)


func _animate() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_dim.modulate.a = 1.0
	_panel.modulate.a = 1.0
	if GameState.get_setting(&"reduced_motion"):
		return
	_dim.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.set_parallel(true)
	_tween.tween_property(_dim, "modulate:a", 1.0, UiTokens.MODAL_SEC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_panel, "modulate:a", 1.0, UiTokens.MODAL_SEC).set_ease(Tween.EASE_OUT)
