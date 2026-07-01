extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RunManagerScript = preload("res://scripts/autoload/run_manager.gd")
const MetaManagerScript = preload("res://scripts/autoload/meta_manager.gd")

const TEST_PATH: String = "user://test_run_manager_meta.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	var mm: Node = get_root().get_node("MetaManager")
	var original_path: String = save_mgr.get_save_path()
	save_mgr.set_save_path(TEST_PATH)
	_cleanup()
	mm.reset()
	mm.load_definitions()

	_test_failed_run_writes_stats()
	_test_boss_win_writes_stats()
	_test_meta_ball_new_run_balls()
	_test_clear_preserves_meta()

	_cleanup()
	save_mgr.set_save_path(original_path)
	quit(checks.finish())

func _make_rm() -> Node:
	var rm: Node = RunManagerScript.new()
	get_root().add_child(rm)
	return rm

func _win_payload(is_boss: bool) -> Dictionary:
	return {
		"is_elite": false,
		"is_boss": is_boss,
		"hero_dead": false,
		"balls_remaining": 3,
		"deploy_unit_ids": ["P_HERO"],
		"survivors": [{
			"unit_id": "P_HERO",
			"template_id": "HERO",
			"hp": 20,
			"max_hp": 20,
			"skill_id": ""
		}]
	}

func _test_failed_run_writes_stats() -> void:
	_cleanup()
	var rm: Node = _make_rm()
	rm.start_new_run(501)
	rm.consume_battle_result("L2N0", "player", {
		"is_elite": false,
		"is_boss": false,
		"hero_dead": true,
		"balls_remaining": 1,
		"deploy_unit_ids": [],
		"survivors": []
	})
	var save_mgr: Node = get_root().get_node("SaveManager")
	var stats: Dictionary = MetaManagerScript.normalize_stats(
		save_mgr.load_meta().get("stats", {}) as Dictionary
	)
	checks.assert_equal(int(stats.get("runs_started", 0)), 1, "failed run increments runs_started.")
	checks.assert_equal(int(stats.get("runs_lost", 0)), 1, "failed run increments runs_lost.")
	rm.queue_free()

func _test_boss_win_writes_stats() -> void:
	_cleanup()
	var rm: Node = _make_rm()
	rm.start_new_run(502)
	rm.consume_battle_result("L6N0", "player", _win_payload(true))
	var save_mgr: Node = get_root().get_node("SaveManager")
	var stats: Dictionary = MetaManagerScript.normalize_stats(
		save_mgr.load_meta().get("stats", {}) as Dictionary
	)
	checks.assert_equal(int(stats.get("runs_won", 0)), 1, "boss win increments runs_won.")
	checks.assert_true(int(stats.get("deepest_layer", 0)) >= 6, "boss win deepest_layer >= 6.")
	rm.queue_free()

func _test_meta_ball_new_run_balls() -> void:
	_cleanup()
	var mm: Node = get_root().get_node("MetaManager")
	mm.set_unlocked(["META_BALL"])
	var rm: Node = _make_rm()
	rm.start_new_run(503)
	var state: Resource = rm.get_state()
	checks.assert_equal(int(state.balls), 4, "META_BALL gives 4 starting balls.")
	rm.queue_free()

func _test_clear_preserves_meta() -> void:
	_cleanup()
	var mm: Node = get_root().get_node("MetaManager")
	mm.set_unlocked(["META_BALL", "META_M05"])
	var save_mgr: Node = get_root().get_node("SaveManager")
	var meta: Dictionary = save_mgr.load_meta()
	meta["meta"] = mm.to_dict()
	save_mgr.save_meta(meta)
	var rm: Node = _make_rm()
	rm.start_new_run(504)
	rm.clear()
	var loaded: Dictionary = (save_mgr.load_meta().get("meta", {}) as Dictionary)
	var unlocked: Array = loaded.get("unlocked", []) as Array
	checks.assert_true(unlocked.has("META_BALL"), "clear keeps META_BALL.")
	checks.assert_true(unlocked.has("META_M05"), "clear keeps META_M05.")
	rm.queue_free()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
