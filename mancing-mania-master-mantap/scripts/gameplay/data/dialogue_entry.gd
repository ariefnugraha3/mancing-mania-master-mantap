class_name DialogueEntry
extends Resource
## One line of on-screen dialogue (GDD 170.9). `text` is English in v1.0.

@export var speaker_id: StringName = &""
@export_multiline var text: String = ""
@export var min_hold_sec: float = 0.0
@export var post_pause_sec: float = 0.4
@export var portrait_expression: StringName = &""
@export var animation_cue: StringName = &""
