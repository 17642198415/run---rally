extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RunManagerScript = preload("res://scripts/autoload/run_manager.gd")

const TEST_PATH: String = "user://test_run_manager_persistence.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	var original_path: String = save_mgr.get_save_path()
	save_mgr.set_save_path(TEST_PATH)
	_cleanup()

	_test_start_new_run()
	_test_save_clear_load_round_trip()
	_test_clear()
	_test_legacy_save_compat()

	_cleanup()
	save_mgr.set_save_path(original_path)
	quit(checks.finish())

func _make_rm() -> Node:
	var rm: Node = RunManagerScript.new()
	get_root().add_child(rm)
	return rm

func _test_start_new_run() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(42)
	var state: Resource = rm.get_state()
	checks.assert_true(state != null, "start_new_run sets state.")
	checks.assert_equal(int(state.seed), 42, "seed set correctly.")
	checks.assert_equal(int(state.current_layer), 1, "current_layer 1.")
	checks.assert_equal((state.route_graph as Array).size(), 6, "route_graph has 6 layers.")
	rm.queue_free()

func _test_save_clear_load_round_trip() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(42)
	var orig_dict: Dictionary = rm.get_state().serialize()
	checks.assert_true(rm.save(), "save returns true.")
	rm._state = null
	checks.assert_true(rm.get_state() == null, "in-memory state cleared.")
	checks.assert_true(rm.load_from_meta(), "load_from_meta returns true.")
	var restored: Resource = rm.get_state()
	checks.assert_true(restored != null, "restored state is not null.")
	var restored_dict: Dictionary = restored.serialize()
	checks.assert_equal(restored_dict.get("seed", -1), 42, "restored seed is 42.")
	checks.assert_equal(restored_dict.get("balls", -1), 3, "restored balls is 3.")
	checks.assert_equal(restored_dict, orig_dict, "restored matches original serialize dict.")
	rm.queue_free()

func _test_clear() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(42)
	rm.clear()
	checks.assert_true(rm.get_state() == null, "clear sets state to null.")
	var save_mgr: Node = get_root().get_node("SaveManager")
	var meta: Dictionary = save_mgr.load_meta()
	var run_section: Dictionary = meta.get("run", {}) as Dictionary
	checks.assert_equal(run_section.get("active", true), false, "clear writes run.active=false.")
	rm.queue_free()

func _test_legacy_save_compat() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	save_mgr.save_meta({"bestiary": {}, "stats": {}})
	var rm: Node = _make_rm()
	checks.assert_equal(rm.load_from_meta(), false, "load_from_meta returns false for legacy save.")
	checks.assert_true(rm.get_state() == null, "state is null for legacy save.")
	rm.queue_free()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))