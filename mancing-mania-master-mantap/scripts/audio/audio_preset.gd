class_name AudioPreset
extends Resource
## Numeric synthesis parameters for one procedural sound (GDD 170.10).
## This is not an audio file: v1.0 ships no audio media at all.

@export var id: StringName = &""
## Which SfxRenderer recipe interprets the fields below.
@export var synth_type: StringName = &""
@export var base_gain_db: float = 0.0
@export var attack_sec: float = 0.001
@export var decay_sec: float = 0.05
@export_range(0.0, 1.0) var sustain: float = 0.0
@export var release_sec: float = 0.03
@export var pitch_hz: float = 220.0
@export_range(0.0, 1.0) var noise_amount: float = 0.0
@export var filter_cutoff_hz: float = 2000.0
## &"fixed" always renders the same waveform; &"varied" accepts a per-play seed.
@export var seed_mode: StringName = &"fixed"
