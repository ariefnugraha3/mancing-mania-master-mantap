class_name BoxingController
extends Node
## Tinju Empang rules (GDD Sections 41-49, 169.13, 170.4) as a deterministic
## simulation. The fight is about reading, not mashing:
##
##   the fish winds up (telegraph) -> the player dodges the way it shows ->
##   a counter window opens -> jab or cross lands for multiplied damage.
##
## Time advances in fixed ticks, so a hit window is the same length at any
## frame rate, and every random choice comes from the duel seed. The same seed
## and the same inputs at the same times always give the same fight.
##
## The controller owns no visuals and writes no cash, debt or bucket. It ends
## with a result dictionary (GDD 169.14) that the duel flow commits.

signal duel_started(snapshot: Dictionary)
## The fish starts an attack. `direction` is the way the player must dodge.
signal telegraph_started(direction: StringName, variant: int, telegraph_sec: float)
## The attack reached its impact: &"hit", &"dodged" or &"perfect".
signal attack_resolved(outcome: StringName, direction: StringName)
signal counter_window_changed(open: bool, perfect: bool)
## Darto leans. `answering` is true when the dodge answers a telegraph.
signal player_dodged(direction: StringName, answering: bool)
signal player_attack_started(attack_id: StringName)
signal player_attack_landed(attack_id: StringName, damage: float, blocked: bool)
signal hp_changed(player_hp: float, fish_hp: float)
signal sudden_death_started()
signal duel_finished(result: Dictionary)

const DUEL_ID := &"boxing"

const STATE_IDLE := &"idle"
const STATE_INTRO := &"intro"
const STATE_FIGHTING := &"fighting"
const STATE_SUDDEN_DEATH := &"sudden_death"
const STATE_FINISHED := &"finished"

const FISH_COOLDOWN := &"cooldown"
const FISH_TELEGRAPH := &"telegraph"
## The counter window: the fish is open after a dodged attack.
const FISH_OPEN := &"open"
## The fish resets after an attack that landed.
const FISH_RECOVER := &"recover"

const PLAYER_READY := &"ready"
const PLAYER_DODGING := &"dodging"
const PLAYER_ATTACKING := &"attacking"
const PLAYER_STUNNED := &"stunned"

const DIRECTION_LEFT := &"left"
const DIRECTION_RIGHT := &"right"
const DIRECTIONS: Array[StringName] = [DIRECTION_LEFT, DIRECTION_RIGHT]
const ATTACK_JAB := &"jab"
const ATTACK_CROSS := &"cross"
const OUTCOME_HIT := &"hit"
const OUTCOME_DODGED := &"dodged"
const OUTCOME_PERFECT := &"perfect"

## Every fish has three attack animations (GDD Section 49).
const ATTACK_VARIANTS := 3
const TICK_SEC := 1.0 / 120.0
const MAX_STEP_SEC := 0.1
## The round opens with a short beat before the clock starts.
const INTRO_SEC := 1.2
## Lengths of Darto's dodge and hit animations (GDD 172.2).
const DODGE_SEC := 0.32
const HIT_STUN_SEC := 0.45
## How long the fish takes to reset after landing a hit.
const FISH_RECOVER_SEC := 0.55
const TIE_EPSILON := 0.000001

## The scene turns this off in tests that step the fight by hand.
var auto_advance: bool = true

var _config: BoxingConfig
var _fish: FishData
var _seed: int = 0
var _rng := RandomNumberGenerator.new()
var _state: StringName = STATE_IDLE
var _accumulator: float = 0.0
var _elapsed: float = 0.0
var _intro_left: float = 0.0
var _time_left: float = 0.0
var _freeze_left: float = 0.0

var _player_hp: float = 0.0
var _player_max_hp: float = 0.0
var _fish_hp: float = 0.0
var _fish_max_hp: float = 0.0

var _fish_phase: StringName = FISH_COOLDOWN
var _fish_timer: float = 0.0
var _telegraph_sec: float = 0.0
var _attack_direction: StringName = &""
var _attack_variant: int = 0
var _counter_multiplier: float = 1.0
var _counter_perfect: bool = false

var _player_phase: StringName = PLAYER_READY
var _player_timer: float = 0.0
var _dodge_direction: StringName = &""
var _dodge_answering: bool = false
var _dodge_perfect: bool = false
var _attack_id: StringName = &""
var _attack_landed: bool = false

var _metrics: Dictionary = {}
var _result: Dictionary = {}


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


# --- Public API (GDD 169.13) ------------------------------------------------

func start_duel(fish_id: StringName, seed: int) -> void:
	_config = GameData.get_boxing_config()
	_fish = GameData.get_fish(fish_id)
	if _fish == null:
		GameLog.error(&"BOXING", "unknown fish", {"fish": fish_id})
		return
	_seed = seed
	_rng.seed = seed
	_accumulator = 0.0
	_elapsed = 0.0
	_intro_left = INTRO_SEC
	_time_left = _config.round_time_sec
	_freeze_left = 0.0
	_player_max_hp = UpgradeEffects.tonic_max_hp(GameState.get_upgrade_level(&"tonic"))
	_player_hp = _player_max_hp
	_fish_max_hp = _fish.boxing_hp
	_fish_hp = _fish_max_hp
	_fish_phase = FISH_COOLDOWN
	_fish_timer = 0.0
	_attack_direction = &""
	_counter_multiplier = 1.0
	_counter_perfect = false
	_player_phase = PLAYER_READY
	_player_timer = 0.0
	_result = {}
	_metrics = {
		"dodges": 0, "perfect_dodges": 0, "hits_taken": 0, "counter_hits": 0,
		"blocked_hits": 0, "damage_dealt": 0.0, "damage_taken": 0.0,
		"fish_attacks": 0, "sudden_death": false, "timed_out": false,
	}
	_state = STATE_INTRO
	GameLog.info(&"BOXING", "duel", {"fish": fish_id, "seed": seed, "hp": _player_max_hp})
	duel_started.emit(get_snapshot())


## Leans away. During a telegraph the first dodge is the answer and is held
## until the impact; at any other time it is just a short step.
func request_dodge(direction: StringName) -> void:
	if not _is_live() or _player_phase != PLAYER_READY or not DIRECTIONS.has(direction):
		return
	_player_phase = PLAYER_DODGING
	_dodge_direction = direction
	_dodge_answering = _fish_phase == FISH_TELEGRAPH
	# Perfect Dodge: the input came in the last moment before impact (GDD 47).
	_dodge_perfect = _dodge_answering and _fish_timer <= _config.perfect_dodge_window_sec
	_player_timer = DODGE_SEC
	player_dodged.emit(direction, _dodge_answering)


## Throws a jab or a cross. The punch lands when its startup ends.
func request_attack(attack_id: StringName) -> void:
	if not _is_live() or _player_phase != PLAYER_READY:
		return
	if attack_id != ATTACK_JAB and attack_id != ATTACK_CROSS:
		return
	_player_phase = PLAYER_ATTACKING
	_attack_id = attack_id
	_attack_landed = false
	_player_timer = 0.0
	player_attack_started.emit(attack_id)


func get_snapshot() -> Dictionary:
	var telegraphing := _fish_phase == FISH_TELEGRAPH and _is_live()
	return {
		"state": _state,
		"fish_id": _fish.id if _fish != null else &"",
		"player_hp": _player_hp,
		"player_max_hp": _player_max_hp,
		"fish_hp": _fish_hp,
		"fish_max_hp": _fish_max_hp,
		"time_left": maxf(_time_left, 0.0),
		"elapsed": _elapsed,
		"fish_phase": _fish_phase,
		"attack_direction": _attack_direction if telegraphing else &"",
		"attack_variant": _attack_variant,
		"time_to_impact": _fish_timer if telegraphing else 0.0,
		"telegraph_sec": _telegraph_sec,
		"in_perfect_window": telegraphing and _fish_timer <= _config.perfect_dodge_window_sec,
		"counter_open": _fish_phase == FISH_OPEN and _is_live(),
		"counter_perfect": _counter_perfect,
		"counter_left": _fish_timer if _fish_phase == FISH_OPEN else 0.0,
		"player_phase": _player_phase,
		"sudden_death": _state == STATE_SUDDEN_DEATH,
	}


# --- Extras -----------------------------------------------------------------

func get_state() -> StringName:
	return _state


## The result of a finished duel (GDD 169.14), or an empty dictionary.
func get_result() -> Dictionary:
	return _result.duplicate(true)


## Moves the fight forward. Long frames are capped so a hitch cannot skip a
## whole telegraph, and the rest is cut into fixed ticks.
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
	return _state == STATE_FIGHTING or _state == STATE_SUDDEN_DEATH


func _tick(dt: float) -> void:
	# The 70 ms freeze after a Perfect Dodge holds the whole fight still.
	if _freeze_left > 0.0:
		_freeze_left -= dt
		return
	if _state == STATE_INTRO:
		_intro_left -= dt
		if _intro_left <= 0.0:
			_begin_fight()
		return

	_elapsed += dt
	_tick_player(dt)
	if not _is_live():
		return
	_tick_fish(dt)
	if _state == STATE_FIGHTING:
		_time_left -= dt
		if _time_left <= 0.0:
			_resolve_timeout()


func _begin_fight() -> void:
	_state = STATE_FIGHTING
	var forced := DebugService.get_forced_result()
	if forced != &"":
		_metrics["forced"] = true
		_finish(forced == &"win")
		return
	_start_cooldown()


func _tick_player(dt: float) -> void:
	match _player_phase:
		PLAYER_ATTACKING:
			_player_timer += dt
			var startup := _startup_of(_attack_id)
			if not _attack_landed and _player_timer >= startup:
				_attack_landed = true
				_land_player_attack()
				if not _is_live():
					return
			if _player_timer >= startup + _recovery_of(_attack_id):
				_player_phase = PLAYER_READY
		PLAYER_DODGING:
			# A dodge that answers a telegraph is held until the impact.
			if _dodge_answering and _fish_phase == FISH_TELEGRAPH:
				return
			_player_timer -= dt
			if _player_timer <= 0.0:
				_player_phase = PLAYER_READY
		PLAYER_STUNNED:
			_player_timer -= dt
			if _player_timer <= 0.0:
				_player_phase = PLAYER_READY


func _tick_fish(dt: float) -> void:
	_fish_timer -= dt
	if _fish_timer > 0.0:
		return
	match _fish_phase:
		FISH_COOLDOWN:
			_start_telegraph()
		FISH_TELEGRAPH:
			_resolve_impact()
		FISH_OPEN:
			counter_window_changed.emit(false, _counter_perfect)
			_start_cooldown()
		FISH_RECOVER:
			_start_cooldown()


## The gap before the next attack is never the same twice (GDD Section 49).
func _start_cooldown() -> void:
	_fish_phase = FISH_COOLDOWN
	_attack_direction = &""
	var boss := _fish.tier >= ContentIds.BOSS_TIER
	var shortest := _config.boss_attack_cd_min if boss else _config.normal_attack_cd_min
	var longest := _config.boss_attack_cd_max if boss else _config.normal_attack_cd_max
	_fish_timer = _rng.randf_range(shortest, longest)


## No attack exists without a telegraph: this is the only way one starts.
func _start_telegraph() -> void:
	_fish_phase = FISH_TELEGRAPH
	# Both values are always drawn, so a debug override never shifts the
	# random sequence of the rest of the fight.
	var rolled_direction := DIRECTIONS[_rng.randi() % DIRECTIONS.size()]
	_attack_variant = _rng.randi() % ATTACK_VARIANTS
	var forced := DebugService.get_forced_attack_direction()
	_attack_direction = forced if forced != &"" else rolled_direction
	_telegraph_sec = _fish.boxing_telegraph_sec
	_fish_timer = _telegraph_sec
	_metrics["fish_attacks"] = int(_metrics["fish_attacks"]) + 1
	telegraph_started.emit(_attack_direction, _attack_variant, _telegraph_sec)


func _resolve_impact() -> void:
	var direction := _attack_direction
	var dodged := _player_phase == PLAYER_DODGING and _dodge_answering and _dodge_direction == direction
	if not dodged:
		_hit_player(direction)
		return

	_metrics["dodges"] = int(_metrics["dodges"]) + 1
	_counter_perfect = _dodge_perfect
	if _counter_perfect:
		_metrics["perfect_dodges"] = int(_metrics["perfect_dodges"]) + 1
		_freeze_left = _config.perfect_freeze_sec
	_counter_multiplier = _config.perfect_damage_multiplier if _counter_perfect else _config.normal_damage_multiplier
	_fish_phase = FISH_OPEN
	_fish_timer = _config.perfect_counter_sec if _counter_perfect else _config.normal_counter_sec
	# Darto is free to counter the moment the punch has missed.
	_player_phase = PLAYER_READY
	attack_resolved.emit(OUTCOME_PERFECT if _counter_perfect else OUTCOME_DODGED, direction)
	counter_window_changed.emit(true, _counter_perfect)


## Wrong direction, no dodge, or caught mid-punch: the attack lands.
func _hit_player(direction: StringName) -> void:
	var damage := _fish.boxing_attack
	_player_hp = maxf(_player_hp - damage, 0.0)
	_metrics["hits_taken"] = int(_metrics["hits_taken"]) + 1
	_metrics["damage_taken"] = float(_metrics["damage_taken"]) + damage
	_player_phase = PLAYER_STUNNED
	_player_timer = HIT_STUN_SEC
	_fish_phase = FISH_RECOVER
	_fish_timer = FISH_RECOVER_SEC
	attack_resolved.emit(OUTCOME_HIT, direction)
	hp_changed.emit(_player_hp, _fish_hp)
	if _state == STATE_SUDDEN_DEATH or _player_hp <= 0.0:
		_finish(false)


## Inside a counter window the punch is multiplied; at any other time the
## fish blocks it and only 40% gets through (GDD Sections 45, 47).
func _land_player_attack() -> void:
	var base := _config.jab_damage if _attack_id == ATTACK_JAB else _config.cross_damage
	var blocked := _fish_phase != FISH_OPEN
	var damage := base * (_config.blocked_damage_multiplier if blocked else _counter_multiplier)
	if _state == STATE_SUDDEN_DEATH and blocked:
		# In sudden death only a clean hit counts.
		damage = 0.0
	_fish_hp = maxf(_fish_hp - damage, 0.0)
	_metrics["damage_dealt"] = float(_metrics["damage_dealt"]) + damage
	var counter := "blocked_hits" if blocked else "counter_hits"
	_metrics[counter] = int(_metrics[counter]) + 1
	player_attack_landed.emit(_attack_id, damage, blocked)
	hp_changed.emit(_player_hp, _fish_hp)
	if (_state == STATE_SUDDEN_DEATH and not blocked) or _fish_hp <= 0.0:
		_finish(true)


## Time is up: the higher share of remaining HP wins; an exact tie goes to a
## one-hit sudden death (GDD Section 48).
func _resolve_timeout() -> void:
	_time_left = 0.0
	_metrics["timed_out"] = true
	var player_share := _player_hp / _player_max_hp
	var fish_share := _fish_hp / _fish_max_hp
	if absf(player_share - fish_share) <= TIE_EPSILON:
		_state = STATE_SUDDEN_DEATH
		_metrics["sudden_death"] = true
		sudden_death_started.emit()
		return
	_finish(player_share > fish_share)


func _finish(player_won: bool) -> void:
	if _fish_phase == FISH_OPEN:
		counter_window_changed.emit(false, _counter_perfect)
	_state = STATE_FINISHED
	_metrics["player_hp"] = _player_hp
	_metrics["fish_hp"] = _fish_hp
	_result = {
		"duel_id": DUEL_ID,
		"fish_id": _fish.id,
		"player_won": player_won,
		"duration_sec": _elapsed,
		"seed": _seed,
		"metrics": _metrics.duplicate(true),
	}
	GameLog.info(&"BOXING", "finished", {"won": player_won, "sec": "%.1f" % _elapsed})
	duel_finished.emit(get_result())


func _startup_of(attack_id: StringName) -> float:
	return _config.jab_startup_sec if attack_id == ATTACK_JAB else _config.cross_startup_sec


func _recovery_of(attack_id: StringName) -> float:
	return _config.jab_recovery_sec if attack_id == ATTACK_JAB else _config.cross_recovery_sec
