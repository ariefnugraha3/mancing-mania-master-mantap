class_name BucketPeekOverlay
extends OverlayPanel
## Quick look into the Bucket (GDD 70, 71): what is in it and roughly what it
## would sell for. The Bucket has no capacity limit, so this is information
## only; nothing here can be dropped or lost.

var _rows: VBoxContainer
var _estimate: Label
var _close_button: GameButton


func build_content() -> void:
	layer = 45
	panel_width = 420.0
	set_title(TextDb.t(&"bucket.title"))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override(&"separation", UiTokens.SPACE_8)
	content.add_child(_rows)
	_estimate = make_label("", UiTokens.TYPE_SMALL)
	content.add_child(_estimate)
	_close_button = make_button(TextDb.t(&"common.close"), UiTokens.TYPE_CTA_BUTTON)
	_close_button.icon_id = IconPainter.CHECK
	_close_button.click_sfx = &"ui_back"
	_close_button.pressed.connect(hide_overlay)
	footer.add_child(_close_button)


func open() -> void:
	_refresh()
	show_overlay()
	focus_later(_close_button)


func on_cancel() -> void:
	AudioManager.play_ui(&"ui_back")
	hide_overlay()


func _refresh() -> void:
	for child: Node in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()

	var total_value := 0
	for item_id: StringName in ContentIds.get_bucket_item_ids():
		var count := GameState.get_bucket_quantity(item_id)
		if count <= 0:
			continue
		total_value += count * GameData.get_item_sale_value(item_id)
		_rows.add_child(make_label(TextDb.tf(&"bucket.row", {"count": count, "name": GameData.get_item_display_name(item_id)})))

	if _rows.get_child_count() == 0:
		_rows.add_child(make_label(TextDb.t(&"bucket.empty"), UiTokens.TYPE_SMALL))
		_estimate.visible = false
	else:
		_estimate.visible = true
		_estimate.text = TextDb.tf(&"bucket.estimate", {"value": Money.format_rp(total_value)})
