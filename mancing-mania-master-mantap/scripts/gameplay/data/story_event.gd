class_name StoryEvent
extends Resource
## A narrative event definition (GDD 170.8). Stored at res://data/story/<event_id>.tres.
## A higher priority is chosen first by Market-exit arbitration (GDD 177).

@export var id: StringName = &""
@export var priority: int = 0
@export var trigger_type: StringName = &""
@export var trigger_value: Variant
@export var once: bool = true
@export var market_event: bool = true
@export var skippable: bool = true
@export var supersedes: Array[StringName] = []
@export var requires_seen: Array[StringName] = []
@export var blocks_until_seen: Array[StringName] = []
@export var timeline_id: StringName = &""
