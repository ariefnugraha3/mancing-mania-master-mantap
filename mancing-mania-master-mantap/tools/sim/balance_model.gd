class_name BalanceModel
extends RefCounted
## Balance simulations (GDD 179), run by tools/sim/balance_sim.gd.
##
## Part 1 uses the game's own code (EncounterRoller, WheelController, the
## data tables) on fixed seed ranges, so its numbers are exact for the build.
## Part 2 is an economy model: the time each step takes and the human skill
## profiles are assumptions written below (GDD 179.3 gives the win chances;
## the step times are estimates from the game's timings). Its results show
## where the authoritative numbers lead under those assumptions.

const ENCOUNTER_ROLLS := 100000
const TRASH_ROLLS := 100000
const WHEEL_ROLLS := 100000
const SESSION_RUNS := 25000
const SESSION_MINUTES := 20.0

## Seconds per step (estimates; see docs/balance_report.md).
const CAST_SEC := 1.6
const BITE_REACTION_SEC := 1.6
const REEL_SEC := {"novice": 11.0, "average": 9.0, "skilled": 7.5}
const LANDING_DIALOGUE_SEC := 5.0
const TRASH_LANDING_SEC := 3.0
const WHEEL_SEC := 4.5
const RESULT_SEC := 7.0
const DUEL_SEC := {"boxing": 24.0, "arm_wrestle": 26.0, "dance": 42.0, "suwit": 18.0}
const MARKET_VISIT_SEC := 50.0
const CATCHES_PER_MARKET_VISIT := 6

## GDD 179.3 profile win chances (range midpoints) per tier group.
const PROFILES := {
	"novice": {"early": 0.66, "mid": 0.55, "snakehead": 0.45, "arowana": 0.40, "strike": 0.80, "reel": 0.66},
	"average": {"early": 0.76, "mid": 0.66, "snakehead": 0.59, "arowana": 0.52, "strike": 0.90, "reel": 0.78},
	"skilled": {"early": 0.915, "mid": 0.85, "snakehead": 0.77, "arowana": 0.70, "strike": 0.97, "reel": 0.90},
}
## What one level of an upgrade adds (assumption, within GDD 179.7 intent).
const UPGRADE_WIN_BONUS := 0.03
const ROD_REEL_BONUS := 0.04
const DUEL_UPGRADE := {"boxing": &"tonic", "arm_wrestle": &"tonic", "dance": &"coffee", "suwit": &"charm"}

## Upgrade strategies (GDD 179.1): what the player buys, in order, before paying.
const STRATEGIES := {
	"debt_first": [],
	"balanced": [&"bait", &"rod", &"tonic", &"bait", &"rod"],
	"completionist": [&"bait", &"rod", &"tonic", &"coffee", &"charm", &"bait", &"rod", &"tonic", &"coffee", &"charm", &"bait", &"rod", &"tonic", &"coffee", &"charm"],
}
## The lifetime-debt story milestones (data/story), ending at the whole debt.
const MILESTONES: Array[int] = [100000, 350000, 700000, 1100000, 1500000, 1850000, ContentIds.DEBT_ORIGINAL]

var _runs: int = 10000
## What-if multiplier on every fish's sale value except Don Arowana's; 1.0 is
## the shipped data.
var _value_scale: float = 1.0
var _results: Dictionary = {}


## Runs every simulation and returns the results.
func run(runs: int, value_scale: float = 1.0) -> Dictionary:
	_runs = runs
	_value_scale = value_scale
	_results["fish_value_scale"] = value_scale
	var started := Time.get_ticks_msec()
	_distribution()
	_trash()
	_wheel()
	_economy()
	_results["seconds"] = float(Time.get_ticks_msec() - started) / 1000.0
	return _results


# --- Part 1: the game's own rolls (GDD 179.1, 179.2) --------------------------

func _distribution() -> void:
	var counts := {}
	for seed: int in range(1, ENCOUNTER_ROLLS + 1):
		var item: StringName = EncounterRoller.roll(seed, 0)["item_id"]
		var key := "trash" if GameData.is_trash(item) else String(item)
		counts[key] = int(counts.get(key, 0)) + 1
	var shares := {}
	for key: String in counts:
		shares[key] = 100.0 * float(counts[key]) / float(ENCOUNTER_ROLLS)
	_results["encounter_distribution_pct"] = shares
	print("[SIM] encounters ", shares)


func _trash() -> void:
	var counts := {}
	for seed: int in range(1, TRASH_ROLLS + 1):
		var item := String(EncounterRoller.pick_trash(RNGService.roll_float(&"trash_type", seed)))
		counts[item] = int(counts.get(item, 0)) + 1
	var shares := {}
	for key: String in counts:
		shares[key] = 100.0 * float(counts[key]) / float(TRASH_ROLLS)
	_results["trash_distribution_pct"] = shares


func _wheel() -> void:
	GameState.new_game()
	GameState.set_tutorial_seen(&"wheel_seen")
	var counts := {}
	for seed: int in range(1, WHEEL_ROLLS + 1):
		var duel := String(WheelController.pick_duel(&"catfish_bruiser", seed))
		counts[duel] = int(counts.get(duel, 0)) + 1
	var shares := {}
	for key: String in counts:
		shares[key] = 100.0 * float(counts[key]) / float(WHEEL_ROLLS)
	_results["wheel_distribution_pct"] = shares
	GameState.clear_game()


# --- Part 2: economy model (GDD 179.3-179.8) ----------------------------------

func _economy() -> void:
	var fish_table: Array = []
	for fish: FishData in GameData.get_all_fish():
		# Don Arowana keeps its Rp 300,000: the story quotes it (GDD 40, 179.6).
		var scale := 1.0 if fish.id == ContentIds.BOSS_FISH_ID else _value_scale
		fish_table.append({"id": fish.id, "tier": fish.tier, "chance": fish.conditional_chance, "value": roundi(fish.get_sale_value() * scale)})
	var trash_table: Array = []
	for trash: TrashData in GameData.get_all_trash():
		trash_table.append({"chance": trash.chance, "value": trash.get_sale_value()})
	var prices := {}
	for upgrade: UpgradeData in GameData.get_all_upgrades():
		prices[upgrade.id] = upgrade.prices
	var balance := GameData.get_fishing_balance()
	var context := {"fish": fish_table, "trash": trash_table, "prices": prices, "balance": balance}

	var economy := {}
	for profile: String in PROFILES:
		var sessions := _sessions(profile, context)
		economy["%s_session" % profile] = sessions
		for strategy: String in STRATEGIES:
			economy["%s_%s" % [profile, strategy]] = _progressions(profile, strategy, context, false)
	economy["average_debt_first_no_arowana"] = _progressions("average", "debt_first", context, true)
	_results["economy"] = economy


## 20-minute sessions from a fresh save: encounters, Market visits, earnings.
func _sessions(profile: String, context: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sessions_%s" % profile)
	var encounters: Array[int] = []
	var earnings: Array[float] = []
	for _run_index: int in SESSION_RUNS:
		var state := _new_state()
		var clock := 0.0
		var count := 0
		while clock < SESSION_MINUTES * 60.0:
			clock += _encounter(state, profile, context, rng, false)
			count += 1
		encounters.append(count)
		earnings.append(float(state["earned"]))
	return {
		"runs": SESSION_RUNS,
		"median_encounters": _median_int(encounters),
		"median_earned_per_hour": _median(earnings) * 60.0 / SESSION_MINUTES,
	}


## Full progression runs: hours to each lifetime-debt milestone.
func _progressions(profile: String, strategy: String, context: Dictionary, no_arowana: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("progress_%s_%s_%s" % [profile, strategy, no_arowana])
	var times := {}
	for milestone: int in MILESTONES:
		times[milestone] = []
	var earn_rates: Array[float] = []
	var plan: Array = STRATEGIES[strategy]
	for _run_index: int in _runs:
		var state := _new_state()
		var clock := 0.0
		var catches := 0
		var milestone_index := 0
		var plan_index := 0
		var first_hour_earned := -1.0
		while milestone_index < MILESTONES.size() and clock < 60.0 * 3600.0:
			clock += _encounter(state, profile, context, rng, no_arowana)
			catches += 1
			if first_hour_earned < 0.0 and clock >= 3600.0:
				first_hour_earned = float(state["earned"])
			if catches % CATCHES_PER_MARKET_VISIT != 0:
				continue
			clock += MARKET_VISIT_SEC
			# Buy the next planned upgrade when affordable, then pay the rest.
			while plan_index < plan.size():
				var upgrade: StringName = plan[plan_index]
				var level: int = state["levels"][upgrade]
				var price: int = context["prices"][upgrade][level]
				if state["cash"] < price:
					break
				state["cash"] -= price
				state["levels"][upgrade] = level + 1
				plan_index += 1
			if plan_index >= plan.size() or strategy == "debt_first":
				state["paid"] += state["cash"]
				state["cash"] = 0
			while milestone_index < MILESTONES.size() and state["paid"] >= MILESTONES[milestone_index]:
				times[MILESTONES[milestone_index]].append(clock / 3600.0)
				milestone_index += 1
		if first_hour_earned >= 0.0:
			earn_rates.append(first_hour_earned)
	var summary := {"runs": _runs, "median_first_hour_earned": _median(earn_rates)}
	for milestone: int in MILESTONES:
		summary["hours_to_%dk" % (milestone / 1000)] = _median(times[milestone])
	summary["p10_hours_to_paid"] = _percentile(times[ContentIds.DEBT_ORIGINAL], 0.1)
	summary["p90_hours_to_paid"] = _percentile(times[ContentIds.DEBT_ORIGINAL], 0.9)
	return summary


func _new_state() -> Dictionary:
	return {"cash": 0, "paid": 0, "earned": 0, "levels": {&"bait": 0, &"rod": 0, &"tonic": 0, &"coffee": 0, &"charm": 0}}


## One cast to the end of its outcome. Returns the seconds it took.
func _encounter(state: Dictionary, profile: String, context: Dictionary, rng: RandomNumberGenerator, no_arowana: bool) -> float:
	var skill: Dictionary = PROFILES[profile]
	var balance: FishingBalance = context["balance"]
	var levels: Dictionary = state["levels"]
	var seconds := CAST_SEC + EncounterRoller.wait_time(rng.randf(), levels[&"bait"]) + BITE_REACTION_SEC
	if rng.randf() > float(skill["strike"]):
		return seconds
	if rng.randf() < balance.trash_probability:
		var roll := rng.randf()
		for trash: Dictionary in context["trash"]:
			roll -= float(trash["chance"])
			if roll <= 0.0:
				_earn(state, int(trash["value"]))
				break
		return seconds + REEL_SEC[profile] * 0.5 + TRASH_LANDING_SEC
	var fish: Dictionary = context["fish"][-1]
	var pick := rng.randf()
	for candidate: Dictionary in context["fish"]:
		pick -= float(candidate["chance"])
		if pick <= 0.0:
			fish = candidate
			break
	seconds += REEL_SEC[profile]
	var reel_chance := minf(float(skill["reel"]) + ROD_REEL_BONUS * float(levels[&"rod"]) - 0.03 * float(int(fish["tier"]) - 1), 0.98)
	if rng.randf() > reel_chance:
		return seconds
	var duel: String = DUEL_SEC.keys()[rng.randi_range(0, 3)]
	seconds += LANDING_DIALOGUE_SEC + WHEEL_SEC + float(DUEL_SEC[duel]) + RESULT_SEC
	var tier := int(fish["tier"])
	var win: float = skill["early"] if tier <= 2 else (skill["mid"] if tier == 3 else (skill["snakehead"] if tier == 4 else skill["arowana"]))
	win = minf(win + UPGRADE_WIN_BONUS * float(levels[DUEL_UPGRADE[duel]]), 0.97)
	if rng.randf() <= win and not (no_arowana and tier == 5):
		_earn(state, int(fish["value"]))
	return seconds


func _earn(state: Dictionary, value: int) -> void:
	state["cash"] += value
	state["earned"] += value


func _median(values: Array) -> float:
	return _percentile(values, 0.5)


func _median_int(values: Array[int]) -> float:
	var copy: Array = values.duplicate()
	return _percentile(copy, 0.5)


func _percentile(values: Array, share: float) -> float:
	if values.is_empty():
		return -1.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(share * float(sorted.size() - 1)), 0, sorted.size() - 1)])
