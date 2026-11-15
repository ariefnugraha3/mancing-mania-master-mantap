class_name HowToOverlay
extends OverlayPanel
## How To Play (GDD 87): one short tab per system instead of a wall of text.
## The copy is the final text from GDD 183.19. Diagrams and input icons join
## in the art and UI polish milestone.

const TAB_IDS: Array[StringName] = [
	&"fishing", &"travel", &"boxing", &"arm_wrestle", &"dance", &"suwit",
	&"silat", &"tambang", &"gasing", &"pinang", &"market",
]
const BODY_HEIGHT := 300.0

var _tabs: TabContainer
var _close_button: GameButton


func build_content() -> void:
	layer = 50
	panel_width = 720.0
	set_title(TextDb.t(&"howto.title"))

	_tabs = TabContainer.new()
	_tabs.custom_minimum_size.y = BODY_HEIGHT
	_tabs.tab_changed.connect(_on_tab_changed)
	content.add_child(_tabs)

	for tab_id: StringName in TAB_IDS:
		var page := VBoxContainer.new()
		page.name = String(tab_id)
		page.add_theme_constant_override(&"separation", UiTokens.SPACE_12)
		_tabs.add_child(page)
		_tabs.set_tab_title(_tabs.get_tab_count() - 1, TextDb.t(StringName("howto.tab.%s" % tab_id)))
		for line: String in TextDb.t(StringName("howto.body.%s" % tab_id)).split("\n"):
			page.add_child(make_label(line))

	_close_button = make_button(TextDb.t(&"common.close"), UiTokens.TYPE_CTA_BUTTON)
	_close_button.click_sfx = &"ui_back"
	_close_button.icon_id = IconPainter.CHECK
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)


func open() -> void:
	_tabs.current_tab = 0
	show_overlay()
	focus_later(_close_button)


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	hide_overlay()


func _on_tab_changed(_tab: int) -> void:
	if visible:
		AudioManager.play_ui(&"ui_click")
