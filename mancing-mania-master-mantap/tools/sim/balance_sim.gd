extends SceneTree
## Runs the balance simulations (GDD 179) headless:
##
##   godot --headless --path . --script res://tools/sim/balance_sim.gd -- --out=<file.json> [--runs=10000] [--value-scale=1.0]
##
## --value-scale multiplies every fish's sale value, to try a tuning proposal
## without touching the data.
##
## The model is loaded at run time: this runner compiles before the
## autoloads (RNGService, GameState) exist.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_path := "user://balance_sim.json"
	var runs := 10000
	var value_scale := 1.0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--out="):
			out_path = argument.trim_prefix("--out=")
		elif argument.begins_with("--runs="):
			runs = argument.trim_prefix("--runs=").to_int()
		elif argument.begins_with("--value-scale="):
			value_scale = argument.trim_prefix("--value-scale=").to_float()
	var model: RefCounted = load("res://tools/sim/balance_model.gd").new()
	var results: Dictionary = model.run(runs, value_scale)
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "  ", true))
	file.close()
	print("[SIM] wrote ", out_path, " in ", results["seconds"], " s")
	quit(0)
