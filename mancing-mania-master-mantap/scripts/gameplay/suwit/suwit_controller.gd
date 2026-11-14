class_name SuwitController
extends Node
## Suwit rules (GDD 64-68, 169.13, 170.7, 176.15) as a deterministic match.
##
## Each round: a three-second countdown. The fish picks its hidden move the
## moment the countdown starts, shows a tell 1.1 s in (true or false by its
## Tell Truth stat), and the round resolves when the countdown ends. No pick
## in time means PANIC PICK, a random move, never a loss by default. Draws do
## not count and the round is played again. First to two wins.
##
## The Agate Charm shows the fish's real move for 0.8 s. It only informs; it
## never changes the fish's choice.

signal duel_started(snapshot: Dictionary)
signal round_started(round_index: int)
signal tell_shown(move: StringName)
signal charm_used(real_move: StringName)
signal round_resolved(outcome: Dictionary)
signal duel_finished(result: Dictionary)

const DUEL_ID := &"suwit"

const ROCK := &"rock"
const SCISSORS := &"scissors"
const PAPER := &"paper"
const MOVES: Array[StringName] = [ROCK, SCISSORS, PAPER]
## What each move beats.
const BEATS: Dictionary = {ROCK: SCISSORS, SCISSORS: PAPER, PAPER: ROCK}

const STATE_IDLE := &"idle"
const STATE_COUNTDOWN := &"countdown"
const STATE_REVEAL := &"reveal"
const STATE_FINISHED := &"finished"

const OUTCOME_WIN := &"win"
const OUTCOME_LOSS := &"loss"
const OUTCOME_DRAW := &"draw"

const TICK_SEC := 1.0 / 120.0
const MAX_STEP_SEC := 0.1
## How long the result of a round stays up before the next countdown.
const REVEAL_SEC := 1.4
const INTRO_SEC := 1.0

var auto_advance: bool = true

var _config: SuwitConfig
var _fish: FishData
var _seed: int = 0
var _rng := RandomNumberGenerator.new()
var _state: StringName = STATE_IDLE
var _accumulator: float = 0.0
var _elapsed: float = 0.0
var _timer: float = 0.0
var _round: int = 0
var _player_wins: int = 0
var _fish_wins: int = 0
var _fish_move: StringName = &""
var _tell_move: StringName = &""
var _tell_truthful: bool = true
var _tell_shown: bool = false
var _player_move: StringName = &""
var _charges: int = 0
var _charm_left: float = 0.0
var _last: Dictionary = {}
var _history: Array[Dictionary] = []
var _result: Dictionary = {}


func _process(delta: float) -> void:
	if auto_advance:
		advance(delta)


# --- Public API (GDD 169.13) ------------------------------------------------

func start_duel(fish_id: StringName, seed: int) -> void:
	_config = GameData.get_suwit_config()
	_fish = GameData.get_fish(fish_id)
	if _fish == null:
		GameLog.error(&"SUWIT", "unknown fish", {"fish": fish_id})
		return
	_seed = seed
	_rng.seed = seed
	_accumulator = 0.0
	_elapsed = 0.0
	_round = 0
	_player_wins = 0
	_fish_wins = 0
	_history.clear()
	_last = {}
	_result = {}
	# Charges belong to this duel only (GDD Section 68).
	_charges = UpgradeEffects.charm_charges(GameState.get_upgrade_level(&"charm"))
	_state = STATE_REVEAL
	_timer = INTRO_SEC
	GameLog.info(&"SUWIT", "duel", {"fish": fish_id, "seed": seed, "charges": _charges})
	duel_started.emit(get_snapshot())


## Locks in the player's move for this round. The first pick counts.
func choose_move(move_id: StringName) -> void:
	if _state != STATE_COUNTDOWN or _player_move != &"" or not MOVES.has(move_id):
		return
	_player_move = move_id


## Shows the fish's real move for 0.8 s. Returns false when there is no
## charge or no round to look at.
func use_charm() -> bool:
	if _state != STATE_COUNTDOWN or _charges <= 0 or _charm_left > 0.0:
		return false
	_charges -= 1
	_charm_left = _config.charm_reveal_sec
	charm_used.emit(_fish_move)
	return true


func get_snapshot() -> Dictionary:
	var countdown := _state == STATE_COUNTDOWN
	return {
		"state": _state,
		"fish_id": _fish.id if _fish != null else &"",
		"round": _round,
		"player_wins": _player_wins,
		"fish_wins": _fish_wins,
		"wins_required": _config.wins_required if _config != null else 2,
		"countdown_left": _timer if countdown else 0.0,
		"tell": _tell_move if countdown and _tell_shown else &"",
		"player_move": _player_move,
		"charm_charges": _charges,
		"charm_left": _charm_left if countdown else 0.0,
		"charm_move": _fish_move if countdown and _charm_left > 0.0 else &"",
		"last_round": _last.duplicate(),
		"elapsed": _elapsed,
	}


# --- Extras -----------------------------------------------------------------

func get_state() -> StringName:
	return _state


func get_result() -> Dictionary:
	return _result.duplicate(true)


func get_history() -> Array[Dictionary]:
	return _history.duplicate(true)


## The fish's hidden move. Tests read it to check that it is fixed before
## the tell; the game never shows it except through the Charm.
func debug_get_hidden_move() -> StringName:
	return _fish_move if _state == STATE_COUNTDOWN else &""


static func outcome_of(player: StringName, fish: StringName) -> StringName:
	if player == fish:
		return OUTCOME_DRAW
	return OUTCOME_WIN if BEATS[player] == fish else OUTCOME_LOSS


func advance(delta: float) -> void:
	if _state == STATE_IDLE or _state == STATE_FINISHED:
		return
	_accumulator += minf(maxf(delta, 0.0), MAX_STEP_SEC)
	while _accumulator >= TICK_SEC and _state != STATE_FINISHED:
		_accumulator -= TICK_SEC
		_tick(TICK_SEC)


# --- Simulation -------------------------------------------------------------

func _tick(dt: float) -> void:
	_elapsed += dt
	_timer -= dt
	if _state == STATE_COUNTDOWN:
		_charm_left = maxf(_charm_left - dt, 0.0)
		if not _tell_shown and _config.countdown_sec - _timer >= _config.tell_time_from_start_sec:
			_tell_shown = true
			tell_shown.emit(_tell_move)
		if _timer <= 0.0:
			_resolve_round()
	elif _state == STATE_REVEAL and _timer <= 0.0:
		var forced := DebugService.get_forced_result()
		if forced != &"" and _round == 0:
			_finish(forced == &"win")
			return
		_start_round()


## The fish decides at the very start of the countdown (SUWIT-003): its move,
## whether the tell will be true, and which lie it would tell.
func _start_round() -> void:
	_round += 1
	_state = STATE_COUNTDOWN
	_timer = _config.countdown_sec
	_player_move = &""
	_charm_left = 0.0
	_tell_shown = false
	_fish_move = MOVES[_rng.randi() % MOVES.size()]
	_tell_truthful = _rng.randf() < _fish.tell_truth_probability
	var lies: Array[StringName] = MOVES.filter(func(move: StringName) -> bool: return move != _fish_move)
	var lie: StringName = lies[_rng.randi() % lies.size()]
	_tell_move = _fish_move if _tell_truthful else lie
	# Drawn now so a panic pick never shifts the sequence of later rounds.
	var panic_move: StringName = MOVES[_rng.randi() % MOVES.size()]
	_last = {"panic_move": panic_move}
	round_started.emit(_round)


func _resolve_round() -> void:
	var panic := false
	if _player_move == &"":
		# No pick in time: a random pick, not a forfeit (GDD 67, 176.15).
		panic = true
		_player_move = _last.get("panic_move", ROCK)
	var outcome := outcome_of(_player_move, _fish_move)
	if outcome == OUTCOME_WIN:
		_player_wins += 1
	elif outcome == OUTCOME_LOSS:
		_fish_wins += 1
	_last = {
		"round": _round, "player": _player_move, "fish": _fish_move, "tell": _tell_move,
		"tell_truthful": _tell_truthful, "outcome": outcome, "panic": panic,
	}
	_history.append(_last.duplicate())
	_state = STATE_REVEAL
	_timer = REVEAL_SEC
	round_resolved.emit(_last.duplicate())
	if _player_wins >= _config.wins_required or _fish_wins >= _config.wins_required:
		_finish(_player_wins >= _config.wins_required)


func _finish(player_won: bool) -> void:
	_state = STATE_FINISHED
	var draws := 0
	var panics := 0
	var lies := 0
	for entry: Dictionary in _history:
		draws += 1 if entry["outcome"] == OUTCOME_DRAW else 0
		panics += 1 if entry["panic"] else 0
		lies += 0 if entry["tell_truthful"] else 1
	_result = {
		"duel_id": DUEL_ID,
		"fish_id": _fish.id,
		"player_won": player_won,
		"duration_sec": _elapsed,
		"seed": _seed,
		"metrics": {
			"rounds": _history.size(), "player_wins": _player_wins, "fish_wins": _fish_wins,
			"draws": draws, "panic_picks": panics, "lies": lies, "charges_left": _charges,
		},
	}
	GameLog.info(&"SUWIT", "finished", {"won": player_won, "rounds": _history.size()})
	duel_finished.emit(get_result())
