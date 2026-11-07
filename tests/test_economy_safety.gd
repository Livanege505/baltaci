extends SceneTree
## Regression tests use an isolated save; no real user save is written.

const SAVE_PATH := "user://test_economy_safety.json"
var _fails := 0
var _checks := 0
var _gs: Node
var _bal: Node


func _initialize() -> void:
	await process_frame
	_gs = root.get_node("GameState")
	_bal = root.get_node("Balance")
	_eq("test autoload starts read-only before a path override", _gs.persist, false)
	_gs.save_path = SAVE_PATH
	_gs.persist = false
	_wipe()
	_test_preview_launches()
	_test_snapshots_and_reset()
	_test_payout_validation()
	_test_unknown_purchase()
	_test_progression_breakpoints()
	_test_read_only_recovery()
	_test_newest_backup()
	_wipe()
	print("TEST_ECONOMY_SAFETY ", "OK (%d checks)" % _checks if _fails == 0 else "FAIL %d of %d checks" % [_fails, _checks])
	quit(1 if _fails else 0)


func _test_preview_launches() -> void:
	for flag in ["--autoshot=preview.png", "--autoshot-buy", "--autoshot-gold", "--autoshot-toast", "--autoplay-seed=7", "--no-save"]:
		_eq("preview launch cannot persist: " + flag, _gs._read_only_launch(PackedStringArray([flag]), PackedStringArray()), true)
	_eq("ordinary game launch can persist", _gs._read_only_launch(PackedStringArray(), PackedStringArray()), false)
	_eq("test script launch is read-only", _gs._read_only_launch(PackedStringArray(), PackedStringArray(["-s", "res://tests/test_economy.gd"])), true)
	_eq("simulator launch is read-only", _gs._read_only_launch(PackedStringArray(), PackedStringArray(["-s", "tools/sim_balance.gd"])), true)


func _test_snapshots_and_reset() -> void:
	_gs.from_dict({"gold": 100, "levels": {"axe_damage": 1}, "flags": {"seen": true}})
	var snapshot: Dictionary = _gs.to_dict()
	snapshot.levels["axe_damage"] = 25
	snapshot.flags["seen"] = false
	_eq("snapshot cannot change upgrade levels", _gs.level_of("axe_damage"), 1)
	_eq("snapshot cannot change story flags", _gs.get_flag("seen"), true)
	var input := {"gold": 7}
	_gs.from_dict(input)
	_eq("loading does not mutate caller dictionary", input.has("save_version"), false)
	_gs.from_dict({"save_version": {"broken": true}, "gold": 8})
	_eq("malformed version does not prevent loading progress", _gs.gold, 8.0)
	_gs.apply_run_result({"kavak": 2}, 2, 2, 4.0)
	_eq("run result exists before reset", _gs.last_run.is_empty(), false)
	_gs.reset()
	_eq("reset clears transient run result", _gs.last_run.is_empty(), true)
	_gs.from_dict({"gold": 77})
	_gs.load_game()
	_eq("missing save restores fresh state", _gs.gold, 0.0)


func _test_payout_validation() -> void:
	# 3 kavak * 2 + 2 cam * 9 = 24; chain 3 gives 10%, rounded to 2; total 26.
	var logs := {"kavak": 3.9, "cam": 2, "ladin": -4, "unknown": 999}
	_gs.from_dict({"gold": 100})
	var result: Dictionary = _gs.apply_run_result(logs, 3, 5, 12.0)
	_eq("invalid logs omitted and fractional logs floored", result.logs, {"kavak": 3, "cam": 2})
	_eq("validated sales", result.sales, 24.0)
	_eq("validated bonus", result.chain_bonus, 2.0)
	_eq("displayed payout equals gold credited", result.gold_after, 126.0)
	logs["kavak"] = 1000
	_eq("result does not alias caller logs", result.logs.kavak, 3)
	var bad: Dictionary = _bal.run_payout({"kavak": NAN, "cam": INF, "ladin": "5"}, 100)
	_eq("malformed counts cannot poison payout", bad.total, 0.0)
	_gs.from_dict({})
	var empty: Dictionary = _gs.apply_run_result({}, 100, -2, NAN)
	_eq("empty run cannot invent a chain", empty.longest_chain, 0)
	_eq("negative felled count normalized", empty.trees_felled, 0)
	_eq("nonfinite duration normalized", empty.duration, 0.0)
	_eq("negative upgrade level cannot discount price", _bal.upgrade_cost("axe_damage", -5), 10.0)


func _test_unknown_purchase() -> void:
	_gs.from_dict({"gold": 10000})
	var before: Dictionary = _gs.to_dict()
	_eq("unknown id cannot be bought", _gs.can_buy("unknown"), false)
	_eq("unknown purchase fails", _gs.buy("unknown"), false)
	_eq("unknown purchase leaves state unchanged", _gs.to_dict(), before)


func _test_progression_breakpoints() -> void:
	# The last damage levels must unlock a concrete new cut/chain threshold.
	var hp: float = _bal.trees.ladin.hp
	var axe_max: int = _bal.get_upgrade("axe_damage").max_level
	_eq("penultimate axe still needs two chops for a ladin", _bal.compute_stat("axe_damage", {"axe_damage": axe_max - 1}) < hp, true)
	_eq("last axe level unlocks a one-chop ladin", _bal.compute_stat("axe_damage", {"axe_damage": axe_max}) >= hp, true)
	var fall_max: int = _bal.get_upgrade("fall_power").max_level
	var height: float = _bal.trees.ladin.height
	_eq("penultimate fall level cannot one-shot another ladin", height * _bal.compute_stat("fall_power", {"fall_power": fall_max - 1}) < hp, true)
	_eq("last fall level unlocks ladin-to-ladin chains", height * _bal.compute_stat("fall_power", {"fall_power": fall_max}) >= hp, true)
	_gs.from_dict({"levels": {"axe_damage": 25, "fall_power": 15}})
	_eq("old maximum axe saves retain every bought level", _gs.level_of("axe_damage"), 25)
	_eq("old maximum fall saves retain every bought level", _gs.level_of("fall_power"), 15)


func _test_read_only_recovery() -> void:
	_write(SAVE_PATH, '{"gold": broken')
	_write(SAVE_PATH + ".bak", '{"gold": 19}')
	_gs.persist = false
	var corrupt := FileAccess.get_file_as_string(SAVE_PATH)
	_gs.load_game()
	_eq("read-only recovery still loads backup in memory", _gs.gold, 19.0)
	_eq("read-only recovery preserves original bytes", FileAccess.get_file_as_string(SAVE_PATH), corrupt)
	_eq("read-only recovery does not move files", FileAccess.file_exists(SAVE_PATH.get_basename() + ".corrupt.json"), false)
	_wipe()


func _test_newest_backup() -> void:
	_write(SAVE_PATH + ".tmp", '{"gold": 3}')
	# Filesystem modified times have one-second precision.
	OS.delay_msec(1100)
	_write(SAVE_PATH + ".bak", '{"gold": 29}')
	_gs.load_game()
	_eq("newer backup beats abandoned older temp", _gs.gold, 29.0)
	_write(SAVE_PATH, '{"gold": 41}')
	_gs.load_game()
	_eq("valid main remains authoritative", _gs.gold, 41.0)


func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()


func _wipe() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH.get_basename() + ".corrupt.json"))


func _eq(label: String, got, expected) -> void:
	_checks += 1
	if got != expected:
		_fails += 1
		print("  FAIL ", label, " got=", got, " expected=", expected)
