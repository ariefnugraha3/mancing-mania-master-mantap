class_name DanceHud
extends CanvasLayer
## Dance HUD (GDD 57-63, 167.9, 168.9, 176.12): the four lanes, the hit line,
## both scores, the combo, the last judgment and the beat pulse.
##
## Each lane's lower part is one large touch target (no swipes). A touch
## reports its lane immediately, so it is timed when it happens rather than
## on the next frame.

signal lane_pressed(lane: int)
signal pause_pressed()

## The lanes fill the lower part of the portrait screen, from this share of
## its height down, and stop growing wider on a tablet.
const LANES_TOP_PORTRAIT := 0.42
const LANES_MAX_WIDTH := 560.0
const JUDGMENT_HOLD_SEC := 0.5
const FLASH_DECAY := 6.0

@onready var _safe_root: Control = $SafeRoot
@onready var _lanes: Control = $SafeRoot/LaneContainer
@onready var _hit_line: Control = $SafeRoot/HitLine
@onready var _score: PanelContainer = $SafeRoot/ScoreWidget
@onready var _combo: Label = $SafeRoot/ComboWidget
@onready var _judgment: Label = $SafeRoot/JudgmentLabel
@onready var _beat: Control = $SafeRoot/BeatPulse

var _field: NoteField
var _buttons: Array[Button] = []
var _player_score: Label
var _fish_score: Label
var _pause_button: GameButton
var _banner: Label
var _banner_body: Label
var _banner_left: float = 0.0
var _hint: Label
var _judgment_left: float = 0.0


func _ready() -> void:
	_field = NoteField.new()
	_field.name = "NoteField"
	_field.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lanes.add_child(_field)
	for lane: int in NoteField.LANES:
		var lane_node := _lanes.get_node("Lane%d" % (lane + 1)) as Control
		lane_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var button := Button.new()
		button.name = "Touch"
		button.focus_mode = Control.FOCUS_NONE
		button.flat = true
		button.button_down.connect(_on_lane_down.bind(lane))
		for state: StringName in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		lane_node.add_child(button)
		_buttons.append(button)
	_hit_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_beat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_scores()
	_combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTokens.outline_text(_combo, UiTokens.FONT_HEADER)
	_judgment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_judgment.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiSkin.sign_text(_judgment, 38, DioramaStyle.BUTTER, 12)
	_judgment.visible = false
	_banner = _outlined(40)
	UiSkin.sign_text(_banner, 44, DioramaStyle.BUTTER, 12)
	_banner_body = _outlined(UiTokens.FONT_HEADER)
	_hint = _outlined(UiTokens.FONT_BUTTON)
	for label: Label in [_banner, _banner_body, _hint]:
		label.visible = false
	_pause_button = GameButton.new()
	_pause_button.name = "PauseButton"
	HudChip.make_pause_button(_pause_button)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	_safe_root.add_child(_pause_button)
	_field.key_labels = PackedStringArray([_key(&"dance_lane_1"), _key(&"dance_lane_2"), _key(&"dance_lane_3"), _key(&"dance_lane_4")])
	_safe_root.resized.connect(_layout)
	PlatformService.viewport_class_changed.connect(func(_c: StringName) -> void: _layout())
	_layout.call_deferred()


func _process(delta: float) -> void:
	for lane: int in NoteField.LANES:
		_field.lane_flash[lane] = maxf(_field.lane_flash[lane] - delta * FLASH_DECAY, 0.0)
	if _judgment_left > 0.0:
		_judgment_left -= delta
		if _judgment_left <= 0.0:
			_judgment.visible = false
	if _banner_left > 0.0:
		_banner_left -= delta
		if _banner_left <= 0.0:
			_banner.visible = false
			_banner_body.visible = false


# --- Called by the dance scene ----------------------------------------------

func setup(fish: FishData, chart: Dictionary) -> void:
	(_score.get_node("Row/Fish/Name") as Label).text = fish.get_display_name().to_upper()
	_field.beat_sec = float(chart["beat_sec"])
	_field.beat_pulse = bool(GameState.get_setting(&"rhythm_beat_pulse"))
	show_hint("")


## Redraws from the controller: notes against the song clock, the visual
## calibration offset applied to the drawing only (GDD 189.10).
func refresh(controller: DanceController, snapshot: Dictionary) -> void:
	var notes := controller.get_notes()
	var judgments: Array = []
	for index: int in notes.size():
		judgments.append(controller.get_player_judgment(index))
	_field.notes = notes
	_field.judgments = judgments
	_field.song_time = float(snapshot["song_time"]) + float(GameState.get_setting(&"rhythm_visual_offset_ms")) / 1000.0
	_field.approach_sec = float(snapshot["approach_sec"])
	_field.queue_redraw()
	_player_score.text = Money.group_thousands(int(snapshot["player_score"]))
	_fish_score.text = Money.group_thousands(int(snapshot["fish_score"]))
	var combo := int(snapshot["player_combo"])
	_combo.text = TextDb.tf(&"dance.hud.combo", {"combo": combo}) if combo >= 2 else ""


func show_judgment(judgment: StringName, lane: int) -> void:
	_judgment.text = TextDb.t(StringName("dance.judgment.%s" % judgment))
	_judgment.visible = true
	_judgment_left = JUDGMENT_HOLD_SEC
	# A judgment grows in size rather than flashing (GDD 189.8).
	var scale_from := 1.25 if judgment == DanceController.PERFECT and not GameState.get_setting(&"reduced_motion") else 1.0
	_judgment.pivot_offset = _judgment.size * 0.5
	_judgment.scale = Vector2.ONE * scale_from
	create_tween().tween_property(_judgment, "scale", Vector2.ONE, 0.15)
	if judgment != DanceController.MISS:
		_field.lane_flash[lane] = 1.0


func show_banner(title: String, body: String, seconds: float) -> void:
	_banner.text = title
	_banner.visible = title != ""
	_banner_body.text = body
	_banner_body.visible = body != ""
	_banner_left = seconds


func show_hint(text: String) -> void:
	_hint.text = text
	_hint.visible = text != ""


func get_note_field() -> NoteField:
	return _field


func get_lane_button(lane: int) -> Button:
	return _buttons[lane]


# --- Construction -----------------------------------------------------------

func _build_scores() -> void:
	_score.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var score_style := HudChip.make_style()
	score_style.content_margin_left = UiTokens.SPACE_16
	score_style.content_margin_top = UiTokens.SPACE_4
	score_style.set_corner_radius_all(20)
	_score.add_theme_stylebox_override(&"panel", score_style)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override(&"separation", UiTokens.SPACE_24)
	_score.add_child(row)
	_player_score = _score_column(row, "Player", TextDb.t(&"boxing.hud.player"))
	_fish_score = _score_column(row, "Fish", "")


func _score_column(row: HBoxContainer, node_name: String, title: String) -> Label:
	var column := VBoxContainer.new()
	column.name = node_name
	column.add_theme_constant_override(&"separation", 0)
	row.add_child(column)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = title
	name_label.theme_type_variation = UiTokens.TYPE_SMALL
	name_label.add_theme_font_override(&"font", UiSkin.bold_font())
	column.add_child(name_label)
	var value := Label.new()
	value.name = "Score"
	value.text = "0"
	value.add_theme_font_size_override(&"font_size", UiTokens.FONT_HEADER)
	value.add_theme_font_override(&"font", UiSkin.heavy_font())
	value.add_theme_color_override(&"font_color", UiTokens.LAKE_500.darkened(0.25) if node_name == "Player" else UiTokens.TERRACOTTA_500.darkened(0.2))
	column.add_child(value)
	return value


func _outlined(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTokens.outline_text(label, font_size)
	_safe_root.add_child(label)
	return label


func _key(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null:
			return OS.get_keycode_string(key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return ""


func _on_lane_down(lane: int) -> void:
	lane_pressed.emit(lane)


# --- Layout -----------------------------------------------------------------

func _layout() -> void:
	var area := _safe_root.size
	var row := float(UiTokens.TOUCH_TARGET_PREFERRED)
	UiTokens.anchor_at(_pause_button, Control.PRESET_TOP_RIGHT)
	_score.reset_size()
	_place(_score, Rect2(0.0, 0.0, _score.get_combined_minimum_size().x, _score.get_combined_minimum_size().y))
	var width := minf(area.x, LANES_MAX_WIDTH)
	var top := maxf(roundf(area.y * LANES_TOP_PORTRAIT), row + float(UiTokens.SPACE_48))
	var left := (area.x - width) * 0.5
	var lanes_rect := Rect2(left, top, width, area.y - top)
	_place(_lanes, lanes_rect)
	for lane: int in NoteField.LANES:
		var lane_node := _lanes.get_node("Lane%d" % (lane + 1)) as Control
		var rect := _field.get_lane_rect(lane)
		rect.size.x = (width - NoteField.LANE_GAP * 3.0) / 4.0
		rect.position.x = float(lane) * (rect.size.x + NoteField.LANE_GAP)
		_place(lane_node, Rect2(rect.position.x, 0.0, rect.size.x, lanes_rect.size.y))
		# The touch target is the lower part of the lane, down to the bottom.
		var touch_top := lanes_rect.size.y * 0.45
		_place(_buttons[lane], Rect2(0.0, touch_top, rect.size.x, lanes_rect.size.y - touch_top))
	_place(_hit_line, Rect2(lanes_rect.position.x, lanes_rect.end.y - NoteField.HIT_LINE_FROM_BOTTOM - 2.0, width, 4.0))
	_place(_beat, Rect2(lanes_rect.end.x - 28.0, lanes_rect.end.y - NoteField.HIT_LINE_FROM_BOTTOM - 50.0, 28.0, 28.0))
	_place(_judgment, Rect2(lanes_rect.position.x, lanes_rect.position.y + lanes_rect.size.y * 0.3, width, 48.0))
	_place(_combo, Rect2(lanes_rect.position.x, lanes_rect.position.y + lanes_rect.size.y * 0.3 + 48.0, width, 36.0))
	UiTokens.place_banner(_banner, _banner_body, area.y * 0.1, area.x)
	_place(_hint, Rect2(0.0, top - 68.0, area.x, 64.0))
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM


func _place(control: Control, rect: Rect2) -> void:
	UiTokens.place_at(control, rect)
