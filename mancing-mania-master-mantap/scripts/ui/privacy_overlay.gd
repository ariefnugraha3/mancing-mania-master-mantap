class_name PrivacyOverlay
extends OverlayPanel
## Settings -> PRIVACY (GDD 187.7): the summary first, then the full policy
## and the licence notices of the engine and the two fonts. Everything is in
## the game, so it works offline; nothing here opens a network connection.

const SUMMARY_KEYS: Array[StringName] = [
	&"privacy.summary.1", &"privacy.summary.2", &"privacy.summary.3", &"privacy.summary.4", &"privacy.summary.5",
]
const POLICY_KEYS: Array[StringName] = [
	&"privacy.policy.intro",
	&"privacy.policy.collection.title", &"privacy.policy.collection.body",
	&"privacy.policy.local.title", &"privacy.policy.local.body",
	&"privacy.policy.web.title", &"privacy.policy.web.body",
	&"privacy.policy.export.title", &"privacy.policy.export.body",
	&"privacy.policy.children.title", &"privacy.policy.children.body",
	&"privacy.policy.changes.title", &"privacy.policy.changes.body",
	&"privacy.policy.contact.title", &"privacy.policy.contact.body",
]

var _page: StringName = &"summary"
var _body: VBoxContainer
var _full_button: GameButton
var _licenses_button: GameButton
var _close_button: GameButton


func build_content() -> void:
	layer = 55
	panel_width = 600.0
	set_title(TextDb.t(&"privacy.title"))
	_body = VBoxContainer.new()
	_body.name = "PrivacyText"
	_body.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	content.add_child(_body)
	_full_button = make_button(TextDb.t(&"privacy.read_full"))
	_full_button.name = "ReadFullPolicy"
	_full_button.pressed.connect(func() -> void: show_page(&"policy"))
	footer.add_child(_full_button)
	_licenses_button = make_button(TextDb.t(&"privacy.licenses"))
	_licenses_button.name = "Licenses"
	_licenses_button.pressed.connect(func() -> void: show_page(&"licenses"))
	footer.add_child(_licenses_button)
	_close_button = make_button(TextDb.t(&"common.close"), UiTokens.TYPE_CTA_BUTTON)
	_close_button.icon_id = IconPainter.CHECK
	_close_button.click_sfx = &"ui_back"
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)


func open() -> void:
	show_page(&"summary")
	show_overlay()
	focus_later(_close_button)


func on_cancel() -> void:
	if _page != &"summary":
		show_page(&"summary")
		return
	AudioManager.play_ui(&"ui_back")
	hide_overlay()


func get_page() -> StringName:
	return _page


func get_page_text() -> String:
	var lines := PackedStringArray()
	for child: Node in _body.get_children():
		if child is Label:
			lines.append((child as Label).text)
	return "\n".join(lines)


func show_page(page: StringName) -> void:
	_page = page
	for child: Node in _body.get_children():
		child.queue_free()
	match page:
		&"summary":
			for key: StringName in SUMMARY_KEYS:
				_body.add_child(make_label(TextDb.t(key), UiTokens.TYPE_HEADER))
		&"policy":
			for key: StringName in POLICY_KEYS:
				var title := String(key).ends_with(".title")
				_body.add_child(make_label(TextDb.t(key), UiTokens.TYPE_HEADER if title else &""))
		&"licenses":
			_body.add_child(make_label(TextDb.t(&"privacy.licenses.intro")))
			# Godot's own licence and the notices of the libraries it ships with.
			var engine := make_label(Engine.get_license_text(), UiTokens.TYPE_SMALL)
			_body.add_child(engine)
			var parts := PackedStringArray()
			for component: Dictionary in Engine.get_copyright_info():
				parts.append(str(component.get("name", "")))
			_body.add_child(make_label(TextDb.tf(&"privacy.licenses.components", {"list": ", ".join(parts)}), UiTokens.TYPE_SMALL))
			# The fonts' own licences must travel with them (OFL 1.1, Apache 2.0).
			_body.add_child(make_label(TextDb.t(&"privacy.licenses.fonts")))
			for license_path: String in [UiTokens.FONT_BODY_LICENSE_FILE, UiTokens.FONT_DISPLAY_LICENSE_FILE]:
				_body.add_child(make_label(_reflow(FileAccess.get_file_as_string(license_path)), UiTokens.TYPE_SMALL))
	_full_button.visible = page == &"summary"
	_licenses_button.visible = page == &"summary"
	fit_to_screen.call_deferred()


## Licence files are hard-wrapped at about 75 columns, which turns into ragged
## half lines on a phone. Joins the lines of each paragraph so the label can
## wrap them to the screen; blank lines still separate paragraphs.
static func _reflow(text: String) -> String:
	var paragraphs := PackedStringArray()
	for block: String in text.replace("\r\n", "\n").split("\n\n"):
		var words := PackedStringArray()
		for line: String in block.split("\n"):
			if not line.strip_edges().is_empty():
				words.append(line.strip_edges())
		if not words.is_empty():
			paragraphs.append(" ".join(words))
	return "\n\n".join(paragraphs)
