extends CanvasLayer
## Basic debug overlay (GDD 178.2), created by DebugService in debug builds only.
## Milestone 1 covers the STATE, RNG, PERFORMANCE and PLATFORM read-outs plus the
## core state mutations; the fishing, duel and story tabs are added by the
## milestones that build those systems.

const REFRESH_INTERVAL_SEC := 0.25
const PANEL_WIDTH := 400.0
const TEXT_COLOR := Color(0.93, 0.95, 0.9)
const DIRTY_COLOR := Color(1.0, 0.72, 0.3)

var _readout: Label
var _dirty_label: Label
var _refresh_timer: float = 0.0


func _ready() -> void:
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_refresh()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL_SEC:
		_refresh_timer = 0.0
		_refresh()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.name = "DebugPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.12, 0.9)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override(&"panel", style)
	# Pinned to the right edge at full height; the content scrolls when the
	# read-out is longer than the screen.
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = -PANEL_WIDTH - 12.0
	panel.offset_right = -12.0
	panel.offset_top = 12.0
	panel.offset_bottom = -12.0
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 6)
	scroll.add_child(column)

	var title := Label.new()
	title.text = "DEBUG OVERLAY - DEV BUILD"
	title.add_theme_color_override(&"font_color", TEXT_COLOR)
	title.add_theme_font_size_override(&"font_size", 16)
	column.add_child(title)

	_dirty_label = Label.new()
	_dirty_label.text = "DEV DIRTY STATE - implicit saves are blocked"
	_dirty_label.add_theme_color_override(&"font_color", DIRTY_COLOR)
	_dirty_label.add_theme_font_size_override(&"font_size", 14)
	column.add_child(_dirty_label)

	_readout = Label.new()
	_readout.add_theme_color_override(&"font_color", TEXT_COLOR)
	_readout.add_theme_font_size_override(&"font_size", 14)
	_readout.add_theme_constant_override(&"line_spacing", 0)
	column.add_child(_readout)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override(&"h_separation", 6)
	buttons.add_theme_constant_override(&"v_separation", 6)
	column.add_child(buttons)
	_add_button(buttons, "CASH +50,000", _on_add_cash)
	_add_button(buttons, "DEBT -100,000", _on_reduce_debt)
	_add_button(buttons, "SAVE DEBUG STATE", _on_save_debug_state)
	_add_button(buttons, "COPY REPRO STATE", _on_copy_repro_state)
	_add_button(buttons, "FORCE CATFISH", DebugService.set_forced_fish.bind(&"catfish_bruiser"))
	_add_button(buttons, "FORCE AROWANA", DebugService.set_forced_fish.bind(&"arowana_don"))
	_add_button(buttons, "FORCE TRASH", DebugService.set_forced_fish.bind(&"trash_sandal"))
	_add_button(buttons, "FAST WAIT", _on_toggle_fast_wait)
	_add_button(buttons, "CLEAR FORCES", DebugService.clear_forces)
	_add_button(buttons, "CLOSE (F10)", DebugService.toggle_overlay)


func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override(&"font_size", 13)
	button.pressed.connect(callback)
	parent.add_child(button)


func _refresh() -> void:
	_dirty_label.visible = DebugService.is_dev_dirty()
	var rng := RNGService.get_debug_snapshot()
	var window_size := get_window().size
	var fps := Engine.get_frames_per_second()
	var upgrades := PackedStringArray()
	for upgrade_id: StringName in ContentIds.UPGRADE_IDS:
		upgrades.append("%s %d" % [upgrade_id, GameState.get_upgrade_level(upgrade_id)])

	var lines := PackedStringArray([
		"[STATE]",
		"active game: %s   save file: %s" % [GameState.has_active_game(), SaveManager.has_save()],
		"cash: %s" % Money.format_rp(GameState.get_cash()),
		"debt: %s paid / %s left" % [Money.format_rp(GameState.get_debt_paid()), Money.format_rp(GameState.get_debt_remaining())],
		"bucket items: %d" % GameState.get_bucket_total_count(),
		"upgrades: %s" % ", ".join(upgrades),
		"pending story: %d" % StoryDirector.get_pending_events().size(),
		"forced: fish=%s duel=%s result=%s" % [
			_or_dash(DebugService.get_forced_fish()),
			_or_dash(DebugService.get_forced_duel()),
			_or_dash(DebugService.get_forced_result())],
		"fast wait: %s" % DebugService.is_fast_wait_enabled(),
		"[RNG]",
		"save seed: %d   session seed: %d" % [rng["save_seed"], rng["session_seed"]],
		"encounters: %d   duels: %d" % [rng["encounter_counter"], rng["duel_counter"]],
		"[PERFORMANCE]",
		"fps: %d   frame: %.1f ms" % [fps, 1000.0 / maxf(fps, 1.0)],
		"draw calls: %d   objects: %d" % [
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))],
		"memory: %.1f MB   audio voices: %d" % [
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			AudioManager.get_active_voice_count()],
		"quality: %s" % GameState.get_setting(&"quality_preset"),
		"[PLATFORM]",
		"scene: %s   build: %s" % [SceneRouter.get_current_scene_id(), SaveSchema.build_version()],
		"window: %dx%d   class: %s" % [window_size.x, window_size.y, PlatformService.get_viewport_class()],
		"input: %s   audio ready: %s" % [InputManager.get_device_type(), AudioManager.is_audio_ready()],
	])
	lines.append_array(_fishing_lines())
	_readout.text = "\n".join(lines)


## Internal fishing values while the lake scene is running.
func _fishing_lines() -> PackedStringArray:
	var scene := get_tree().current_scene
	var controller := scene.get_node_or_null("FishingController") as FishingController if scene != null else null
	if controller == null:
		return PackedStringArray()
	var encounter := controller.get_encounter()
	var reel := controller.get_reel()
	return PackedStringArray([
		"[FISHING]",
		"state: %s   t: %.2f" % [controller.get_state(), controller.get_state_time()],
		"encounter: %s  seed: %s" % [encounter.get("item_id", "-"), encounter.get("seed", "-")],
		"marker: %.3f  zone: %.3f +/- %.3f" % [reel.marker, reel.zone_center, reel.zone_half_width],
		"landing: %.1f  stress: %.1f" % [reel.landing, reel.stress],
		"auto reel: %s" % DebugService.is_auto_reel_enabled(),
	])


func _or_dash(value: StringName) -> String:
	return "-" if value == &"" else String(value)


func _on_add_cash() -> void:
	DebugService.set_cash(GameState.get_cash() + 50_000)
	_refresh()


func _on_reduce_debt() -> void:
	DebugService.set_debt_remaining(GameState.get_debt_remaining() - 100_000)
	_refresh()


func _on_save_debug_state() -> void:
	DebugService.save_debug_state()
	_refresh()


func _on_toggle_fast_wait() -> void:
	DebugService.set_fast_wait(not DebugService.is_fast_wait_enabled())
	_refresh()


func _on_copy_repro_state() -> void:
	DisplayServer.clipboard_set(DebugService.get_repro_state())
