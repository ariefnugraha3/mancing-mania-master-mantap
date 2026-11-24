extends "res://tests/test_suite.gd"
## SAVE-001..009 and SAVE-012 (GDD 115-118, 171, 180.2). Every test works on an
## isolated temp folder, never on the player's real save.

const STORAGE_DIR := "user://test_tmp/save"

const TOP_LEVEL_KEYS: Array[String] = [
	"version", "created_at_utc", "last_played_at_utc", "cash", "debt", "upgrades",
	"bucket", "fish_book", "stats", "story", "tutorials", "settings", "rng", "system",
	"locations",
]


func get_suite_name() -> String:
	return "save"


func before_each() -> void:
	SaveManager.simulate_interrupted_write = false
	SaveManager.simulate_write_failure = false
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage(STORAGE_DIR)
	GameState.clear_game()
	for key: String in SaveSchema.default_settings():
		GameState.set_setting(StringName(key), SaveSchema.default_settings()[key])
	DebugService.clear_dev_dirty()


func after_all() -> void:
	SaveManager.simulate_interrupted_write = false
	SaveManager.simulate_write_failure = false
	GameState.clear_game()
	DebugService.clear_dev_dirty()
	remove_directory(STORAGE_DIR)
	SaveManager.configure_storage()


# --- Helpers ----------------------------------------------------------------

func _valid_save() -> Dictionary:
	return SaveSchema.make_default(4242)


func _write_save(data: Variant) -> void:
	write_text(SaveManager.get_save_path(), JSON.stringify(data, "\t"))


func _saved_file() -> Dictionary:
	var parsed: Variant = read_json(SaveManager.get_save_path())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _backup_path(tag: String) -> String:
	return STORAGE_DIR.path_join(SaveManager.BACKUP_FILE_PATTERN % tag)


func _sorted_keys(dictionary: Dictionary) -> Array:
	var keys := dictionary.keys()
	keys.sort()
	return keys


## The state without the fields that legitimately change on every save.
func _comparable(state: Dictionary) -> String:
	var copy := state.duplicate(true)
	copy.erase("last_played_at_utc")
	copy.erase("system")
	return JSON.stringify(copy, "", true)


# --- SAVE-001 ---------------------------------------------------------------

func test_new_game_creates_schema_v6_file() -> bool:
	check(not SaveManager.has_save(), "no save before New Game")
	GameState.new_game()
	check(SaveManager.save_game(&"new_game"), "save succeeds")
	check(SaveManager.has_save(), "save exists after New Game")

	var file := _saved_file()
	var expected_keys: Array = TOP_LEVEL_KEYS.duplicate()
	expected_keys.sort()
	check_eq(_sorted_keys(file), expected_keys, "top-level keys")
	check_eq(file.get("version"), 6, "version (revision 6.7)")
	check_eq(file.get("cash"), 10000, "starting cash")
	check_eq(file["debt"], {"original": 2000000.0, "paid": 0.0, "remaining": 2000000.0}, "debt block")
	check_eq(file["upgrades"].size(), 6, "upgrade entries (Big Bucket joined in revision 6.12)")
	check_eq(file["bucket"].size(), 29, "bucket entries (26 fish and 3 trash)")
	check_eq(file["fish_book"].size(), 26, "fish book entries")
	check_eq(file["stats"].size(), 24, "stat entries (revision 6.7 added five)")
	check_eq(file["story"].size(), 9, "story entries")
	check_eq(file["tutorials"].size(), 14, "tutorial entries (revision 6.7 added five)")
	check_eq(file["locations"], {"current": "cempaka", "unlocked": ["cempaka"], "gear": [], "visited": ["cempaka"]}, "locations block")
	check_eq(file["settings"].size(), 22, "setting entries (revision 6.6 added language)")
	check_eq(file["settings"]["language"], "auto", "the language follows the device by default")
	check_eq(_sorted_keys(file["rng"]), ["duel_counter", "encounter_counter", "save_seed"], "rng keys")
	check_eq(file["system"]["schema_version"], 6, "system schema version")
	check_eq(file["system"]["build_version"], SaveSchema.build_version(), "build version")
	check(file["rng"]["save_seed"] > 0, "save seed was generated")
	check(str(file["created_at_utc"]).ends_with("Z") and str(file["created_at_utc"]).contains("T"), "ISO-8601 UTC timestamp")

	var catfish: Dictionary = file["fish_book"]["catfish_bruiser"]
	check_eq(_sorted_keys(catfish), ["best_weight_kg", "discovered", "duel_wins", "encounters", "favourite_duel", "losses", "wins"], "fish book entry keys")
	return true


# --- SAVE-002 ---------------------------------------------------------------

func test_save_then_load_restores_exact_state() -> bool:
	GameState.new_game()
	GameState.add_cash(123456)
	GameState.pay_debt(50000)
	GameState.add_bucket_item(&"catfish_bruiser", 3)
	GameState.add_bucket_item(&"trash_tyre", 2)
	GameState.buy_next_upgrade(&"bait")
	GameState.record_encounter(&"carp_golden")
	GameState.record_fish_win(&"carp_golden", 3.25, &"dance")
	GameState.record_fish_loss(&"arowana_don")
	GameState.increment_stat(&"total_casts", 17)
	GameState.add_play_time(321.5)
	StoryDirector.enqueue_event(&"story_debt_100k")
	StoryDirector.mark_event_seen(&"story_prologue_zero")
	StoryDirector.begin_market_visit()
	GameState.set_tutorial_seen(&"fishing_seen")
	GameState.set_setting(&"music_volume", 0.35)
	GameState.set_setting(&"hud_shake", "reduced")
	GameState.set_setting(&"input_remap", {"open_market": ["key:70"]})
	RNGService.next_encounter_seed()
	RNGService.next_encounter_seed()
	RNGService.next_duel_seed()

	var before := GameState.export_save_state()
	check(SaveManager.save_game(&"test"), "save succeeds")
	GameState.clear_game()
	check_eq(GameState.get_cash(), 10000, "state really was cleared")

	check(SaveManager.load_game(), "load succeeds")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_OK, "load status")
	check_eq(_comparable(GameState.export_save_state()), _comparable(before), "state after load equals state before save")
	check_eq(RNGService.get_persist_state()["encounter_counter"], 2, "encounter counter restored")
	check_eq(RNGService.get_persist_state()["duel_counter"], 1, "duel counter restored")
	check(not FileAccess.file_exists(_backup_path("pre_repair")), "a clean save is not rewritten")
	return true


# --- SAVE-003 ---------------------------------------------------------------

func test_corrupt_json_is_preserved_and_reported() -> bool:
	var garbage := "{ \"version\": 5, \"cash\": 12"
	write_text(SaveManager.get_save_path(), garbage)

	check(not SaveManager.load_game(), "corrupt save does not load")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_CORRUPT, "status is corrupt")
	check(not GameState.has_active_game(), "no game was activated")
	check(FileAccess.file_exists(SaveManager.get_corrupt_backup_path()), "corrupt backup exists")
	check_eq(FileAccess.get_file_as_string(SaveManager.get_corrupt_backup_path()), garbage, "backup holds the original bytes")
	check_eq(FileAccess.get_file_as_string(SaveManager.get_save_path()), garbage, "the corrupt save was not overwritten")
	return true


# Revision 6.11: tmp -> verify -> keep the replaced save as .bak -> rename.
func test_the_replaced_save_is_kept_as_bak() -> bool:
	GameState.new_game()
	check(SaveManager.save_game(&"new_game"), "first save")
	check(not FileAccess.file_exists(SaveManager.get_last_good_path()), "a brand-new game has no .bak")
	var first := _saved_file()
	GameState.add_cash(100)
	check(SaveManager.save_game(&"test"), "second save")
	check_eq(_comparable(read_json(SaveManager.get_last_good_path())), _comparable(first), "the .bak is the save that was replaced")

	# A damaged file is never copied over a good .bak.
	write_text(SaveManager.get_save_path(), "{ \"version\": 6, \"cash\": 1")
	check(SaveManager.save_game(&"test"), "saving over a damaged file still works")
	check_eq(_comparable(read_json(SaveManager.get_last_good_path())), _comparable(first), "and the .bak stays the good one")
	check(not SaveManager.validate_save(_saved_file()).is_empty(), "the save itself is good again")
	return true


func test_an_unreadable_save_falls_back_to_the_bak() -> bool:
	GameState.new_game()
	GameState.add_cash(1234)
	check(SaveManager.save_game(&"test"), "a save")
	var good_cash := GameState.get_cash()
	check(SaveManager.save_game(&"test"), "and another, so the .bak holds it too")
	var garbage := "{ \"version\": 6, \"cash\": 12"
	write_text(SaveManager.get_save_path(), garbage)
	GameState.clear_game()

	check(SaveManager.load_game(), "the game still loads")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_OK, "status is ok")
	check(GameState.has_active_game(), "the game is active")
	check_eq(GameState.get_cash(), good_cash, "with the last good progress")
	check_eq(FileAccess.get_file_as_string(SaveManager.get_corrupt_backup_path()), garbage, "the unreadable file is preserved")
	check(not SaveManager.validate_save(_saved_file()).is_empty(), "the save on disk is good again")
	return true


func test_new_game_and_delete_leave_no_bak() -> bool:
	GameState.new_game()
	SaveManager.save_game(&"test")
	SaveManager.save_game(&"test")
	check(FileAccess.file_exists(SaveManager.get_last_good_path()), "playing keeps a .bak")
	GameState.new_game()
	check(SaveManager.save_game(&"new_game"), "a new game is saved")
	check(not FileAccess.file_exists(SaveManager.get_last_good_path()), "and the old game's .bak is gone")
	SaveManager.save_game(&"test")
	check(FileAccess.file_exists(SaveManager.get_last_good_path()), "the new game gets its own .bak")
	check(SaveManager.delete_save(), "delete")
	check(not FileAccess.file_exists(SaveManager.get_last_good_path()), "deleting the save deletes its .bak too")
	return true


func test_non_object_root_and_bad_version_are_rejected() -> bool:
	_write_save([1, 2, 3])
	check(not SaveManager.load_game(), "array root is rejected")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_CORRUPT, "array root status")

	var no_version := _valid_save()
	no_version.erase("version")
	_write_save(no_version)
	check(not SaveManager.load_game(), "missing version is rejected")

	var zero_version := _valid_save()
	zero_version["version"] = 0
	_write_save(zero_version)
	check(not SaveManager.load_game(), "version 0 is rejected")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_CORRUPT, "version 0 status")
	return true


func test_unsupported_versions_are_left_untouched() -> bool:
	for version: int in [7, 3]:
		var data := _valid_save()
		data["version"] = version
		_write_save(data)
		var original_text := FileAccess.get_file_as_string(SaveManager.get_save_path())
		check(not SaveManager.load_game(), "version %d does not load" % version)
		check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_UNSUPPORTED, "version %d status" % version)
		check_eq(FileAccess.get_file_as_string(SaveManager.get_save_path()), original_text, "version %d file untouched" % version)
		check(FileAccess.file_exists(_backup_path("unsupported_version")), "version %d was backed up" % version)
	return true


# --- SAVE-004 ---------------------------------------------------------------

func test_negative_cash_is_clamped_and_backed_up() -> bool:
	var data := _valid_save()
	data["cash"] = -500
	_write_save(data)

	check(SaveManager.load_game(), "save with negative cash still loads")
	check_eq(GameState.get_cash(), 0, "cash clamped to zero")
	check(FileAccess.file_exists(_backup_path("pre_repair")), "original kept as a backup before rewriting")
	check_eq(read_json(_backup_path("pre_repair"))["cash"], -500, "backup holds the unrepaired value")
	check_eq(_saved_file()["cash"], 0, "rewritten save holds the repaired value")
	return true


# --- SAVE-005 ---------------------------------------------------------------

func test_broken_debt_invariant_is_repaired() -> bool:
	var data := _valid_save()
	data["debt"] = {"original": 2000000, "paid": 300000, "remaining": 999}
	var fixed := SaveManager.validate_save(data)
	check_eq(fixed["debt"], {"original": 2000000, "paid": 300000, "remaining": 1700000}, "remaining recomputed from paid")

	data["debt"] = {"original": 2000000, "paid": -5, "remaining": 1200000}
	fixed = SaveManager.validate_save(data)
	check_eq(fixed["debt"], {"original": 2000000, "paid": 800000, "remaining": 1200000}, "paid recomputed from remaining")

	data["debt"] = {"original": 12, "paid": 400000, "remaining": 1400000}
	fixed = SaveManager.validate_save(data)
	check_eq(fixed["debt"]["original"], 2000000, "original restored")
	check_eq(fixed["stats"]["lifetime_debt_paid"], 400000, "lifetime stat aligned with the ledger")

	data["debt"] = {"original": 2000000, "paid": "lots", "remaining": null}
	data["stats"]["lifetime_debt_paid"] = 250000
	fixed = SaveManager.validate_save(data)
	check_eq(fixed["debt"], {"original": 2000000, "paid": 250000, "remaining": 1750000}, "debt recovered from the lifetime stat")

	data["debt"] = {"original": 2000000, "paid": 9900000, "remaining": -4}
	data["stats"]["lifetime_debt_paid"] = -1
	check(SaveManager.validate_save(data).is_empty(), "debt with no recoverable field rejects the save")

	data.erase("debt")
	data["stats"].erase("lifetime_debt_paid")
	check(SaveManager.validate_save(data).is_empty(), "missing debt block rejects the save")
	return true


## Revision 6.12 raised the debt from Rp 1,800,000 to Rp 2,000,000. A save
## still paying keeps what it paid and owes the new total; a save that had
## cleared the old debt stays cleared, so the ending never owes money again.
func test_saves_from_the_old_debt_follow_the_new_total() -> bool:
	var data := _valid_save()
	data["debt"] = {"original": 1800000, "paid": 500000, "remaining": 1300000}
	data["stats"]["lifetime_debt_paid"] = 500000
	var fixed := SaveManager.validate_save(data)
	check_eq(fixed["debt"], {"original": 2000000, "paid": 500000, "remaining": 1500000}, "a debt in progress keeps what was paid")
	check_eq(fixed["stats"]["lifetime_debt_paid"], 500000, "and its milestones stay where they were")

	data["debt"] = {"original": 1800000, "paid": 1800000, "remaining": 0}
	data["stats"]["lifetime_debt_paid"] = 1800000
	fixed = SaveManager.validate_save(data)
	check_eq(fixed["debt"], {"original": 2000000, "paid": 2000000, "remaining": 0}, "a cleared debt stays cleared")
	check_eq(fixed["stats"]["lifetime_debt_paid"], 2000000, "its lifetime stat follows the ledger")

	data["debt"] = {"original": 1800000, "paid": 1800000, "remaining": "?"}
	fixed = SaveManager.validate_save(data)
	check_eq(fixed["debt"]["remaining"], 0, "the whole old debt paid counts as cleared")
	return true


# --- SAVE-006 ---------------------------------------------------------------

func test_upgrade_levels_are_clamped() -> bool:
	var data := _valid_save()
	data["upgrades"] = {"bait": -2, "rod": 7, "tonic": 2, "coffee": "x", "jetpack": 3}
	var fixed := SaveManager.validate_save(data)
	check_eq(fixed["upgrades"], {"bucket": 0, "bait": 0, "rod": 3, "tonic": 2, "coffee": 0, "charm": 0}, "clamped upgrades")
	return true


func test_negative_counters_are_clamped() -> bool:
	var data := _valid_save()
	data["bucket"]["catfish_bruiser"] = -4
	data["stats"]["total_casts"] = -10
	data["fish_book"]["carp_golden"]["wins"] = -1
	data["rng"]["encounter_counter"] = -9
	var fixed := SaveManager.validate_save(data)
	check_eq(fixed["bucket"]["catfish_bruiser"], 0, "bucket count")
	check_eq(fixed["stats"]["total_casts"], 0, "stat counter")
	check_eq(fixed["fish_book"]["carp_golden"]["wins"], 0, "fish book counter")
	check_eq(fixed["rng"]["encounter_counter"], 0, "rng counter")
	return true


# --- SAVE-007 ---------------------------------------------------------------

func test_unknown_story_events_are_removed() -> bool:
	var data := _valid_save()
	data["story"]["seen_events"] = ["story_prologue_zero", "bogus_event", "story_prologue_zero"]
	data["story"]["pending_events"] = ["story_debt_100k", "story_made_up", "story_debt_100k", 42, "story_prologue_zero"]
	var fixed := SaveManager.validate_save(data)
	check_eq(fixed["story"]["seen_events"], ["story_prologue_zero"], "seen events cleaned")
	check_eq(fixed["story"]["pending_events"], ["story_debt_100k"], "pending events cleaned")

	data["story"]["pending_events"] = "not a list"
	data["story"]["chapter"] = "chapter_99"
	fixed = SaveManager.validate_save(data)
	check_eq(fixed["story"]["pending_events"], [], "non-list pending becomes empty")
	check_eq(fixed["story"]["chapter"], "prologue", "unknown chapter falls back")
	return true


func test_unknown_fields_are_dropped_on_rewrite() -> bool:
	var data := _valid_save()
	data["cheat_mode"] = true
	data["settings"]["secret_volume"] = 11
	var fixed := SaveManager.validate_save(data)
	check(not fixed.has("cheat_mode"), "unknown top-level field dropped")
	check(not fixed["settings"].has("secret_volume"), "unknown setting dropped")
	check(not SaveSchema.last_repairs.is_empty(), "the drop is reported as a repair")
	return true


func test_settings_block_is_normalized() -> bool:
	var data := _valid_save()
	data["settings"]["master_volume"] = 3.0
	data["settings"]["hud_shake"] = "wobble"
	data["settings"]["text_scale"] = 1.45
	data["settings"]["reduced_flash"] = "yes"
	data["settings"]["input_remap"] = {
		"open_market": ["key:70", "key:70", "banana"],
		"self_destruct": ["key:65"],
		"box_jab": "key:65",
	}
	var settings: Dictionary = SaveManager.validate_save(data)["settings"]
	check_eq(settings["master_volume"], 1.0, "volume clamped")
	check_eq(settings["hud_shake"], "on", "invalid enum falls back")
	check_eq(settings["text_scale"], 1.5, "text scale snaps")
	check_eq(settings["reduced_flash"], false, "non-boolean toggle falls back")
	check_eq(settings["input_remap"], {"open_market": ["key:70"]}, "only valid bindings survive")
	return true


## Revision 6.6 added LANGUAGE. A save from before has no such setting: it
## gets the default quietly, because an update is not damage (no repair
## note, so no pre-repair backup and no rewrite on the first launch).
func test_saves_from_before_the_language_setting_load_cleanly() -> bool:
	var data := _valid_save()
	data["settings"].erase("language")
	var fixed := SaveManager.validate_save(data)
	check_eq(fixed["settings"]["language"], "auto", "the missing language follows the device")
	check(SaveSchema.last_repairs.is_empty(), "and it is not reported as a repair")
	data["settings"].erase("hud_shake")
	SaveManager.validate_save(data)
	check(not SaveSchema.last_repairs.is_empty(), "an older setting that is missing still is")
	return true


# --- SAVE-008 ---------------------------------------------------------------

func test_interrupted_write_keeps_previous_save() -> bool:
	GameState.new_game()
	GameState.add_cash(1000)
	check(SaveManager.save_game(&"test"), "first save succeeds")

	SaveManager.simulate_interrupted_write = true
	GameState.add_cash(5000)
	check(not SaveManager.save_game(&"test"), "interrupted save reports failure")
	check(SaveManager.has_unsaved_changes(), "unsaved changes are flagged")
	check_eq(GameState.get_cash(), 16000, "runtime state is kept after a failed save")
	SaveManager.simulate_interrupted_write = false

	GameState.clear_game()
	check(SaveManager.load_game(), "previous save still loads")
	check_eq(GameState.get_cash(), 11000, "previous save was retained")
	check(not FileAccess.file_exists(STORAGE_DIR.path_join(SaveManager.TEMP_FILE)), "stale temp file was removed")
	return true


func test_complete_temp_file_is_promoted_when_save_is_missing() -> bool:
	var data := _valid_save()
	data["cash"] = 77000
	write_text(STORAGE_DIR.path_join(SaveManager.TEMP_FILE), JSON.stringify(data))
	check(SaveManager.has_save(), "a complete temp file counts as a save")
	check(SaveManager.load_game(), "temp file is promoted and loaded")
	check_eq(GameState.get_cash(), 77000, "state came from the temp file")
	check(FileAccess.file_exists(SaveManager.get_save_path()), "temp file became the save")

	GameState.clear_game()
	SaveManager.delete_save()
	write_text(STORAGE_DIR.path_join(SaveManager.TEMP_FILE), "{ truncated")
	check(not SaveManager.load_game(), "a truncated temp file is not a save")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_MISSING, "status is missing, not corrupt")
	return true


func test_write_failure_is_reported_not_hidden() -> bool:
	var messages: Array[String] = []
	var on_error := func(message: String) -> void: messages.append(message)
	SaveManager.save_error.connect(on_error)

	GameState.new_game()
	SaveManager.simulate_write_failure = true
	check(not SaveManager.save_game(&"test"), "failed write returns false")
	check_eq(messages.size(), 1, "save_error emitted once")
	check(messages.size() == 1 and messages[0] == TextDb.t(&"error.save_failed.body"), "player-facing message is the GDD copy")
	check(SaveManager.has_unsaved_changes(), "unsaved changes are flagged")
	check(not SaveManager.has_save(), "nothing was written")

	SaveManager.simulate_write_failure = false
	check(SaveManager.save_game(&"retry"), "retry succeeds")
	check(not SaveManager.has_unsaved_changes(), "flag cleared after a good save")
	SaveManager.save_error.disconnect(on_error)
	return true


# --- SAVE-009 ---------------------------------------------------------------

func test_settings_autosave_and_reload() -> bool:
	GameState.new_game()
	SaveManager.save_game(&"new_game")
	GameState.set_setting(&"sfx_volume", 0.25)
	GameState.set_setting(&"reduced_flash", true)
	SaveManager.flush_pending_autosave()

	GameState.clear_game()
	GameState.set_setting(&"sfx_volume", 0.9)
	GameState.set_setting(&"reduced_flash", false)
	check(SaveManager.load_game(), "reload succeeds")
	check_eq(GameState.get_setting(&"sfx_volume"), 0.25, "volume preserved")
	check_eq(GameState.get_setting(&"reduced_flash"), true, "toggle preserved")

	# Without a flush the debounce timer has to write the change by itself.
	GameState.set_setting(&"music_volume", 0.1)
	var setting_on_disk := func() -> bool:
		return is_equal_approx(float(_saved_file().get("settings", {}).get("music_volume", -1.0)), 0.1)
	check(await wait_until(setting_on_disk, 3.0), "debounced autosave wrote the setting")
	return true


func test_settings_do_not_create_a_save_before_new_game() -> bool:
	GameState.set_setting(&"music_volume", 0.5)
	SaveManager.flush_pending_autosave()
	await wait_frames(2)
	check(not SaveManager.has_save(), "changing settings alone creates no save file")
	return true


# --- Migration, import/export, housekeeping ---------------------------------

func test_migrate_save_contract() -> bool:
	var current := _valid_save()
	check_eq(SaveManager.migrate_save(current).get("version"), 6, "schema 6 passes through")
	check_eq(SaveManager.migrate_save(_schema_5_save()).get("version"), 6, "schema 5 is migrated")
	check(SaveManager.migrate_save({}).is_empty(), "no version is rejected")
	check(SaveManager.migrate_save({"version": 0}).is_empty(), "version 0 is rejected")
	check(SaveManager.migrate_save({"version": 4}).is_empty(), "unsupported old version is rejected")
	check(SaveManager.migrate_save({"version": 9}).is_empty(), "newer version is rejected")
	return true


## A save exactly as the build before revision 6.7 wrote it: six fish, four
## duels, no spots, and a player who already beat Don Arowana twice.
func _schema_5_save() -> Dictionary:
	var data := _valid_save()
	data["version"] = 5
	data["system"]["schema_version"] = 5
	data.erase("locations")
	var old_fish: Array[String] = ["catfish_bruiser", "tilapia_gym_rat", "gourami_shady", "carp_golden", "snakehead_sergeant", "arowana_don"]
	for key: String in (data["fish_book"] as Dictionary).keys():
		if not old_fish.has(key):
			(data["fish_book"] as Dictionary).erase(key)
	for key: String in (data["bucket"] as Dictionary).keys():
		if ContentIds.FISH_IDS.has(StringName(key)) and not old_fish.has(key):
			(data["bucket"] as Dictionary).erase(key)
	for entry: Dictionary in (data["fish_book"] as Dictionary).values():
		for duel: String in ["silat", "tambang", "gasing", "pinang"]:
			(entry["duel_wins"] as Dictionary).erase(duel)
	for key: String in ["silat_wins", "tambang_wins", "gasing_wins", "pinang_wins", "legends_defeated"]:
		(data["stats"] as Dictionary).erase(key)
	for key: String in ["silat_seen", "tambang_seen", "gasing_seen", "pinang_seen", "travel_seen"]:
		(data["tutorials"] as Dictionary).erase(key)
	data["stats"]["don_arowana_defeated"] = 2
	data["fish_book"]["arowana_don"]["wins"] = 2
	data["fish_book"]["arowana_don"]["discovered"] = true
	data["bucket"]["carp_golden"] = 3
	data["cash"] = 123456
	return data


# Revision 6.7: a schema 5 save loads, keeps everything and gains the new parts.
func test_schema_5_save_migrates_to_6() -> bool:
	_write_save(_schema_5_save())
	check(SaveManager.load_game(), "the old save loads")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_OK, "load status")
	check_eq(GameState.get_cash(), 123456, "cash kept")
	check_eq(GameState.get_bucket_quantity(&"carp_golden"), 3, "bucket kept")
	check_eq(int(GameState.get_fish_book_entry(&"arowana_don").get("wins", 0)), 2, "fish book kept")
	check_eq(int(GameState.get_stat(&"legends_defeated")), 2, "Don Arowana counts as a legend already beaten")
	check_eq(GameState.get_current_location(), ContentIds.START_LOCATION, "Darto is at Cempaka Lake")
	check(not GameState.is_location_unlocked(&"kenanga"), "no new spot opens by itself")
	check_eq(GameState.get_fish_book_entry(&"layaran_kapten").get("encounters", -1), 0, "new fish have empty entries")
	check(not GameState.is_tutorial_seen(&"silat_seen"), "new tutorials start unseen")
	check(SaveManager.save_game(&"test"), "saves again")
	check_eq(_saved_file().get("version"), 6, "written back as schema 6")
	return true


# Revision 6.8: the game was renamed, which moves user:// on desktop. A save
# in the folder of the old name is copied once; the old folder is untouched.
func test_save_from_before_the_rename_is_imported_once() -> bool:
	var legacy := ProjectSettings.globalize_path(STORAGE_DIR.path_join("legacy"))
	var target_dir := STORAGE_DIR.path_join("renamed")
	DirAccess.make_dir_recursive_absolute(legacy)
	var data := _valid_save()
	data["cash"] = 77777
	write_text(legacy.path_join(SaveManager.SAVE_FILE), JSON.stringify(data))
	write_text(legacy.path_join(SaveManager.BACKUP_FILE_PATTERN % "pre_migration"), "{}")
	write_text(legacy.path_join("notes.txt"), "not a save")
	check_eq(SaveManager.import_legacy_save(legacy, target_dir), 2, "the save and its backup are copied")
	var target := ProjectSettings.globalize_path(target_dir)
	check(FileAccess.file_exists(target.path_join(SaveManager.SAVE_FILE)), "the save is in the new folder")
	check(not FileAccess.file_exists(target.path_join("notes.txt")), "other files stay behind")
	check(FileAccess.file_exists(legacy.path_join(SaveManager.SAVE_FILE)), "the old folder keeps its save")
	SaveManager.configure_storage(target_dir)
	check(SaveManager.load_game(), "the imported save loads")
	check_eq(GameState.get_cash(), 77777, "with the player's progress")
	data["cash"] = 1
	write_text(legacy.path_join(SaveManager.SAVE_FILE), JSON.stringify(data))
	check_eq(SaveManager.import_legacy_save(legacy, target_dir), 0, "a folder that already has a save is never overwritten")
	SaveManager.configure_storage(STORAGE_DIR)
	return true


func test_export_and_import_round_trip() -> bool:
	GameState.new_game()
	GameState.add_cash(40000)
	GameState.buy_next_upgrade(&"charm")
	SaveManager.save_game(&"test")
	var exported := SaveManager.export_save_json()
	var expected := _comparable(GameState.export_save_state())

	GameState.new_game()
	SaveManager.save_game(&"test")
	check(SaveManager.import_save_json(exported), "valid export imports")
	check_eq(_comparable(GameState.export_save_state()), expected, "imported state matches the export")
	check(FileAccess.file_exists(_backup_path("pre_import")), "previous save backed up before import")

	var before_bad_import := _comparable(GameState.export_save_state())
	check(not SaveManager.import_save_json("definitely not json"), "garbage import fails")
	check(not SaveManager.import_save_json("{\"version\": 5}"), "incomplete save import fails")
	check(not SaveManager.import_save_json("{\"version\": 99, \"cash\": 5}"), "wrong version import fails")
	check_eq(_comparable(GameState.export_save_state()), before_bad_import, "failed imports change nothing")
	return true


func test_delete_save() -> bool:
	GameState.new_game()
	SaveManager.save_game(&"test")
	check(SaveManager.delete_save(), "delete succeeds")
	check(not SaveManager.has_save(), "save is gone")
	check(not SaveManager.load_game(), "nothing to load")
	check_eq(SaveManager.get_last_load_status(), SaveManager.STATUS_MISSING, "status missing")
	return true


func test_debug_mutations_are_not_saved_implicitly() -> bool:
	GameState.new_game()
	SaveManager.save_game(&"new_game")
	DebugService.set_cash(999999)
	check(DebugService.is_dev_dirty(), "debug mutation marks DEV DIRTY STATE")
	check(SaveManager.save_game(&"sale"), "implicit save is skipped without an error")
	check_eq(_saved_file()["cash"], 10000, "file still holds the clean value")

	check(DebugService.save_debug_state(), "explicit SAVE DEBUG STATE succeeds")
	check(not DebugService.is_dev_dirty(), "dirty flag cleared")
	check_eq(_saved_file()["cash"], 999999, "debug state written on explicit request")
	return true


## Revision 6.12: a save from before Big Bucket has no "bucket" upgrade level;
## it loads at level 0 (5 catches), and a bucket already over 5 is kept.
func test_saves_from_before_big_bucket_load_at_level_zero() -> bool:
	var data := SaveSchema.make_default(42)
	var upgrades: Dictionary = data["upgrades"]
	upgrades.erase("bucket")
	data["bucket"]["catfish_bruiser"] = 9
	var normalized := SaveSchema.normalize(data)
	check_eq(int(normalized["upgrades"]["bucket"]), 0, "Big Bucket starts at level 0")
	check_eq(int(normalized["bucket"]["catfish_bruiser"]), 9, "nothing in the bucket is lost")
	return true
