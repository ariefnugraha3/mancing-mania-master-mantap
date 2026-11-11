class_name InputActions
extends RefCounted
## Names of the InputMap actions defined in project.godot (GDD 123, 189.15).
## Gameplay code reads these actions and never raw keycodes.

const UI_CONFIRM := &"ui_confirm"
const UI_CANCEL := &"ui_cancel"
const PAUSE := &"pause"
const DEBUG_TOGGLE_OVERLAY := &"debug_toggle_overlay"

## Actions that stop responding while gameplay input is disabled
## (scene transitions, cutscenes, modal dialogs).
const GAMEPLAY: Array[StringName] = [
	&"fish_cast",
	&"fish_reel",
	&"open_market",
	&"open_bucket",
	&"box_dodge_left",
	&"box_dodge_right",
	&"box_jab",
	&"box_cross",
	&"arm_mash",
	&"dance_lane_1",
	&"dance_lane_2",
	&"dance_lane_3",
	&"dance_lane_4",
	&"suwit_rock",
	&"suwit_scissors",
	&"suwit_paper",
	&"suwit_charm",
]

## Always-available actions.
const SYSTEM: Array[StringName] = [
	UI_CONFIRM,
	UI_CANCEL,
	PAUSE,
]

## Actions a player may rebind (GDD 189.15).
const REMAPPABLE: Array[StringName] = [
	&"fish_cast",
	&"fish_reel",
	&"open_market",
	&"open_bucket",
	&"pause",
	&"box_dodge_left",
	&"box_dodge_right",
	&"box_jab",
	&"box_cross",
	&"arm_mash",
	&"dance_lane_1",
	&"dance_lane_2",
	&"dance_lane_3",
	&"dance_lane_4",
	&"suwit_rock",
	&"suwit_scissors",
	&"suwit_paper",
	&"suwit_charm",
	&"ui_confirm",
	&"ui_cancel",
]


static func get_all() -> Array[StringName]:
	var all: Array[StringName] = []
	all.append_array(GAMEPLAY)
	all.append_array(SYSTEM)
	return all


## True for a left mouse press or a touch press: the "primary tap" on any device.
static func is_primary_press(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	if mouse != null:
		return mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	var touch := event as InputEventScreenTouch
	return touch != null and touch.pressed
