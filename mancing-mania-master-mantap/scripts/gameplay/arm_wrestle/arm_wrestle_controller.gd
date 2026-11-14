class_name ArmWrestleController
extends Node
## Panco Maut rules (GDD Sections 50-56, 169.13, 170.5, 176.13) as a
## deterministic simulation.
##
## Every accepted MASH press pushes the position toward Darto's side by an
## impulse scaled by his stamina band, and costs stamina. Presses above ten a
## second are ignored without penalty. Stamina comes back after a short rest.
## The fish pushes back all the time and, every few seconds, winds up a burst.
##
## Time advances in fixed ticks from the duel seed, so the same seed and the
## same presses at the same times always give the same match.

signal duel_started(snapshot: Dictionary)
signal press_accepted(power: float)
## The fish tightens before a burst (GDD Section 55).
signal burst_warning_started(warning_sec: float)
signal burst_started(duration_sec: float)
signal burst_ended()
signal sudden_grip_started()
signal rematch_started()
signal duel_finished(result: Dictionary)

const DUEL_ID := &"arm_wrestle"

const STATE_IDLE := &"idle"
const STATE_INTRO := &"intro"
const STATE_PULLING := &"pulling"
const STATE_SUDDEN_GRIP := &"sudden_grip"
const STATE_REMATCH := &"rematch"
const STATE_FINISHED := &"finished"

const FISH_PRESSING := &"pressing"
const FISH_WARNING := &"warning"
const FISH_BURST := &"burst"

const TICK_SEC := 1.0 / 120.0
const MAX_STEP_SEC := 0.1
const INTRO_SEC := 1.2
## The press cap is a token bucket: one press per token, ten tokens a second,
## at most this many saved up. Tapping faster than the cap still yields the
## full ten a second instead of every other tap (GDD 176.13).
const PRESS_BURST := 2.0

## The scene turns this off in tests that step the match by hand.
var auto_advance: bool = true

var _config: ArmWrestleConfig
var _fish: FishData
var _seed: int = 0
var _rng := RandomNumberGenerator.new()
var _state: StringName = STATE_IDLE
var _accumulator: float = 0.0
var _elapsed: float = 0.0
var _intro_left: float = 0.0
var _time_left: float = 0.0
var _round_sec: float = 0.0

var _position: float = 0.0
var _stamina: float = 0.0
var _max_stamina: float = 0.0
var _last_press_at: float = -1000.0
var _press_tokens: float = PRESS_BURST

var _fish_phase: StringName = FISH_PRESSING
var _fish_timer: float = 0.0
var _burst_extra: float = 0.0
var _burst_sec: float = 0.0

var _metrics: Dictionary = {}
var _result: Dictionary = {}


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


# --- Public API (GDD 169.13) ------------------------------------------------

func start_duel(fish_id: StringName, seed: int) -> void:
	_config = GameData.get_arm_wrestle_config()
	_fish = GameData.get_fish(fish_id)
	if _fish == null:
		GameLog.error(&"ARM", "unknown fish", {"fish": fish_id})
		return
	_seed = seed
	_rng.seed = seed
	_accumulator = 0.0
	_elapsed = 0.0
	_intro_left = INTRO_SEC
	_round_sec = _config.round_time_sec
	_time_left = _round_sec
	_position = 0.0
	_max_stamina = _config.base_stamina * UpgradeEffects.tonic_stamina_multiplier(GameState.get_upgrade_level(&"tonic"))
	_stamina = _max_stamina
	_last_press_at = -1000.0
	_press_tokens = PRESS_BURST
	_result = {}
	_metrics = {
		"presses": 0, "accepted_presses": 0, "ignored_presses": 0, "bursts": 0,
		"sudden_grip": false, "rematch": false, "timed_out": false, "lowest_stamina": _max_stamina,
	}
	_start_pressing()
	_state = STATE_INTRO
	GameLog.info(&"ARM", "duel", {"fish": fish_id, "seed": seed, "stamina": _max_stamina})
	duel_started.emit(get_snapshot())


## One MASH press. Returns true when it was accepted. Presses faster than the
## cap are ignored; the ignored press costs nothing (GDD 176.13).
func request_mash() -> bool:
	if not _is_live():
		return false
	_metrics["presses"] = int(_metrics["presses"]) + 1
	_last_press_at = _elapsed
	if _press_tokens < 1.0:
		_metrics["ignored_presses"] = int(_metrics["ignored_presses"]) + 1
		return false
	_press_tokens -= 1.0
	var power := power_for(_stamina / _max_stamina)
	_stamina = maxf(_stamina - _config.press_stamina_cost, 0.0)
	_metrics["accepted_presses"] = int(_metrics["accepted_presses"]) + 1
	_metrics["lowest_stamina"] = minf(float(_metrics["lowest_stamina"]), _stamina)
	_move(_config.press_impulse * power)
	press_accepted.emit(power)
	return true


func get_snapshot() -> Dictionary:
	var live := _is_live()
	return {
		"state": _state,
		"fish_id": _fish.id if _fish != null else &"",
		"position": _position,
		"stamina": _stamina,
		"max_stamina": _max_stamina,
		"stamina_ratio": _stamina / _max_stamina if _max_stamina > 0.0 else 0.0,
		"power": power_for(_stamina / _max_stamina) if _max_stamina > 0.0 else 0.0,
		"time_left": maxf(_time_left, 0.0),
		"round_sec": _round_sec,
		"elapsed": _elapsed,
		"fish_phase": _fish_phase if live else FISH_PRESSING,
		"burst_warning": live and _fish_phase == FISH_WARNING,
		"bursting": live and _fish_phase == FISH_BURST,
		"phase_left": _fish_timer,
		"fish_force": fish_force() if live else 0.0,
		"resting": live and _elapsed - _last_press_at >= _config.regen_delay_sec,
		"sudden_grip": _state == STATE_SUDDEN_GRIP,
		"rematch": _state == STATE_REMATCH,
	}


# --- Extras -----------------------------------------------------------------

func get_state() -> StringName:
	return _state


## The result of a finished match (GDD 169.14), or an empty dictionary.
func get_result() -> Dictionary:
	return _result.duplicate(true)


## Share of full push power at a stamina ratio (GDD Section 53).
static func power_for(stamina_ratio: float) -> float:
	if stamina_ratio > 0.6:
		return 1.0
	if stamina_ratio >= 0.3:
		return 0.85
	if stamina_ratio >= 0.1:
		return 0.65
	return 0.42


## The fish's push in position units per second right now.
func fish_force() -> float:
	var force := _fish.arm_strength * _config.fish_pressure_per_strength
	if _fish_phase == FISH_BURST:
		force += _burst_extra
	return force


func advance(delta: float) -> void:
	if not _is_running():
		return
	_accumulator += minf(maxf(delta, 0.0), MAX_STEP_SEC)
	while _accumulator >= TICK_SEC and _is_running():
		_accumulator -= TICK_SEC
		_tick(TICK_SEC)


# --- Simulation -------------------------------------------------------------

func _is_running() -> bool:
	return _state == STATE_INTRO or _is_live()


func _is_live() -> bool:
	return _state == STATE_PULLING or _state == STATE_SUDDEN_GRIP or _state == STATE_REMATCH


func _tick(dt: float) -> void:
	if _state == STATE_INTRO:
		_intro_left -= dt
		if _intro_left <= 0.0:
			_state = STATE_PULLING
			var forced := DebugService.get_forced_result()
			if forced != &"":
				_metrics["forced"] = true
				_finish(forced == &"win")
		return

	_elapsed += dt
	_press_tokens = minf(_press_tokens + _config.max_press_rate_per_sec * dt, PRESS_BURST)
	# Stamina returns only after a short pause in pressing (GDD Section 54).
	if _elapsed - _last_press_at >= _config.regen_delay_sec:
		_stamina = minf(_stamina + _config.regen_per_sec * dt, _max_stamina)
	_tick_fish(dt)
	_move(-fish_force() * dt)
	if not _is_live():
		return
	_time_left -= dt
	if _state == STATE_SUDDEN_GRIP and absf(_position) >= _config.sudden_grip_target:
		_finish(_position > 0.0)
	elif _time_left <= 0.0:
		_resolve_timeout()


func _tick_fish(dt: float) -> void:
	_fish_timer -= dt
	if _fish_timer > 0.0:
		return
	match _fish_phase:
		FISH_PRESSING:
			_fish_phase = FISH_WARNING
			_fish_timer = _config.burst_warning_sec
			burst_warning_started.emit(_fish_timer)
		FISH_WARNING:
			_fish_phase = FISH_BURST
			_burst_sec = _rng.randf_range(_config.burst_min_sec, _config.burst_max_sec)
			_fish_timer = _burst_sec
			# Higher tiers burst harder (GDD Section 55).
			_burst_extra = _fish.arm_strength * _config.fish_pressure_per_strength \
				* (_config.burst_base_multiplier + _config.burst_tier_multiplier * float(_fish.tier))
			_metrics["bursts"] = int(_metrics["bursts"]) + 1
			burst_started.emit(_burst_sec)
		FISH_BURST:
			burst_ended.emit()
			_start_pressing()


func _start_pressing() -> void:
	_fish_phase = FISH_PRESSING
	_fish_timer = _rng.randf_range(_config.burst_cooldown_min_sec, _config.burst_cooldown_max_sec)
	_burst_extra = 0.0


func _move(amount: float) -> void:
	_position = clampf(_position + amount, _config.position_min, _config.position_max)
	if not _is_live():
		return
	if _position >= _config.position_max:
		_finish(true)
	elif _position <= _config.position_min:
		_finish(false)


## Time is up (GDD Section 56): the side the hands lean toward wins. Too close
## to call goes to Sudden Grip; dead level after that is settled without luck.
func _resolve_timeout() -> void:
	_time_left = 0.0
	_metrics["timed_out"] = true
	var near_zero := absf(_position) <= _config.sudden_grip_threshold
	match _state:
		STATE_PULLING:
			if near_zero:
				_state = STATE_SUDDEN_GRIP
				_time_left = _config.sudden_grip_max_sec
				_metrics["sudden_grip"] = true
				sudden_grip_started.emit()
				return
			_finish(_position > 0.0)
		STATE_SUDDEN_GRIP:
			# "Exactly 0.000": the position is compared to three decimals.
			var level := snappedf(_position, 0.001)
			if level != 0.0:
				_finish(level > 0.0)
			elif _fish.tier >= ContentIds.BOSS_TIER and not bool(_metrics["rematch"]):
				_start_rematch()
			else:
				_finish(true)
		STATE_REMATCH:
			# A second dead heat goes to the player: nothing is left to compare.
			_finish(snappedf(_position, 0.001) >= 0.0)


## A dead-level boss match is pulled again for 10 seconds from the middle.
func _start_rematch() -> void:
	_state = STATE_REMATCH
	_metrics["rematch"] = true
	_position = 0.0
	_stamina = _max_stamina
	_round_sec = _config.boss_rematch_sec
	_time_left = _round_sec
	_start_pressing()
	rematch_started.emit()


func _finish(player_won: bool) -> void:
	_state = STATE_FINISHED
	_metrics["position"] = _position
	_metrics["stamina"] = _stamina
	_result = {
		"duel_id": DUEL_ID,
		"fish_id": _fish.id,
		"player_won": player_won,
		"duration_sec": _elapsed,
		"seed": _seed,
		"metrics": _metrics.duplicate(true),
	}
	GameLog.info(&"ARM", "finished", {"won": player_won, "sec": "%.1f" % _elapsed, "position": "%.1f" % _position})
	duel_finished.emit(get_result())


# --- Test hooks -------------------------------------------------------------

## Puts the match at an exact position, for the tiebreak tests.
func debug_set_position(value: float) -> void:
	_position = value
