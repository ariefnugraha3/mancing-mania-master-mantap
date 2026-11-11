extends Node
## Deterministic gameplay randomness (GDD 129, 169.8).
##
## Every authoritative roll is a pure function of (channel, seed), so a bug can
## be replayed from the seeds printed by the debug overlay. Cosmetic effects use
## the separate `cosmetic` generator and can never shift a gameplay outcome.

const _FNV_OFFSET := 0x811C9DC5
const _FNV_PRIME := 0x01000193
const _MASK_32 := 0xFFFFFFFF

## Non-deterministic generator for visual-only variation.
var cosmetic := RandomNumberGenerator.new()

var _save_seed: int = 1
var _session_seed: int = 0
var _encounter_counter: int = 0
var _duel_counter: int = 0
var _last_encounter_seed: int = 0
var _last_duel_seed: int = 0


func _ready() -> void:
	cosmetic.randomize()
	_session_seed = int(cosmetic.randi())


## Binds the service to a save. Counters restart at zero; a loaded save puts
## them back with restore_counters().
func initialize_session(save_seed: int) -> void:
	_save_seed = SaveSchema.sanitize_seed(save_seed)
	_encounter_counter = 0
	_duel_counter = 0
	_last_encounter_seed = 0
	_last_duel_seed = 0


func restore_counters(encounter_counter: int, duel_counter: int) -> void:
	_encounter_counter = maxi(encounter_counter, 0)
	_duel_counter = maxi(duel_counter, 0)


## Advances the encounter counter and returns the seed for that encounter.
func next_encounter_seed() -> int:
	_encounter_counter += 1
	_last_encounter_seed = _mix(_save_seed, &"encounter", _encounter_counter)
	return _last_encounter_seed


## Advances the duel counter and returns the seed for that duel.
func next_duel_seed() -> int:
	_duel_counter += 1
	_last_duel_seed = _mix(_save_seed, &"duel", _duel_counter)
	return _last_duel_seed


func make_rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


## Uniform value in [0, 1) that depends only on `channel` and `seed`.
func roll_float(channel: StringName, seed: int) -> float:
	return make_rng(_mix(seed, channel, 0)).randf()


## Uniform index in [0, count) that depends only on `channel` and `seed`.
func choose_index(channel: StringName, seed: int, count: int) -> int:
	if count <= 0:
		return -1
	return mini(int(roll_float(channel, seed) * count), count - 1)


func get_save_seed() -> int:
	return _save_seed


func get_session_seed() -> int:
	return _session_seed


func get_persist_state() -> Dictionary:
	return {
		"save_seed": _save_seed,
		"encounter_counter": _encounter_counter,
		"duel_counter": _duel_counter,
	}


func get_debug_snapshot() -> Dictionary:
	return {
		"save_seed": _save_seed,
		"session_seed": _session_seed,
		"encounter_counter": _encounter_counter,
		"duel_counter": _duel_counter,
		"last_encounter_seed": _last_encounter_seed,
		"last_duel_seed": _last_duel_seed,
	}


## Combines a seed, a channel name and a counter into a well-spread 62-bit seed.
## Two FNV-1a passes with different salts supply the low and high halves.
func _mix(seed: int, channel: StringName, counter: int) -> int:
	var text := "%d|%s|%d" % [seed, channel, counter]
	var low := _fnv1a(text, _FNV_OFFSET)
	var high := _fnv1a(text, 0x9747B28C)
	return ((high & 0x3FFFFFFF) << 32) | low


func _fnv1a(text: String, basis: int) -> int:
	var hash_value := basis
	for byte: int in text.to_utf8_buffer():
		hash_value = ((hash_value ^ byte) * _FNV_PRIME) & _MASK_32
	return hash_value
