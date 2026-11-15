class_name DuelOutcome
extends RefCounted
## The one place where a finished duel changes the game (GDD 169.13, 169.14).
## Duel controllers only produce a result; this commits it:
##
##   win  -> the fish goes into the Bucket, the Fish Book and records update;
##   loss -> the fish gets away and the loss is recorded. Nothing else is lost:
##           no cash, no upgrade, no debt progress, no Bucket content (GDD 176.11).
##
## The winner is never recomputed here. Each result is committed once.


## Applies `result` (GDD 169.14) and saves. Returns false when the save failed;
## the state is kept in memory either way.
static func commit(result: Dictionary) -> bool:
	var fish_id: StringName = result.get("fish_id", &"")
	var duel_id: StringName = result.get("duel_id", &"")
	if GameData.get_fish(fish_id) == null or not ContentIds.DUEL_IDS.has(duel_id):
		GameLog.error(&"DUEL", "result rejected", {"fish": fish_id, "duel": duel_id})
		return false

	if bool(result.get("player_won", false)):
		GameState.add_bucket_item(fish_id)
		GameState.record_fish_win(fish_id, _caught_weight(fish_id), duel_id)
		GameState.increment_stat(&"duel_wins")
		GameState.increment_stat(StringName("%s_wins" % duel_id))
		if fish_id == ContentIds.BOSS_FISH_ID:
			GameState.increment_stat(&"don_arowana_defeated")
		if ContentIds.LEGEND_FISH_IDS.has(fish_id):
			GameState.increment_stat(&"legends_defeated")
	else:
		GameState.record_fish_loss(fish_id)
		GameState.increment_stat(&"duel_losses")

	clear_pending_catch()
	return SaveManager.save_game(&"duel_result")


## Forgets the catch that was waiting on a duel, e.g. after quitting to the
## menu mid-fight. The fish is simply gone; nothing is recorded.
static func clear_pending_catch() -> void:
	GameState.current_fish = &""
	GameState.current_duel = &""
	GameState.current_catch = {}


## The weight rolled when this fish was hooked. A duel started without a
## catch (debug tools) falls back to the middle of the species range.
static func _caught_weight(fish_id: StringName) -> float:
	var catch := GameState.current_catch
	if catch.get("fish_id", &"") == fish_id and float(catch.get("weight_kg", 0.0)) > 0.0:
		return float(catch["weight_kg"])
	var fish := GameData.get_fish(fish_id)
	return snappedf((fish.weight_min_kg + fish.weight_max_kg) * 0.5, 0.01)
