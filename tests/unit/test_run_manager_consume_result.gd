extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RunManagerScript = preload("res://scripts/autoload/run_manager.gd")

const TEST_PATH: String = "user://test_run_manager_consume.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	var original_path: String = save_mgr.get_save_path()
	save_mgr.set_save_path(TEST_PATH)
	_cleanup()

	_test_normal_win_marks_node()
	_test_hero_death_ends_run()
	_test_boss_win_ends_run()
	_test_reserve_hp_sync()

	_cleanup()
	save_mgr.set_save_path(original_path)
	quit(checks.finish())

func _make_rm() -> Node:
	var rm: Node = RunManagerScript.new()
	get_root().add_child(rm)
	return rm

func _test_normal_win_marks_node() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(99)
	var payload: Dictionary = {
		"is_boss": false,
		"hero_dead": false,
		"balls_remaining": 2,
		"deploy_unit_ids": ["P_HERO"],
		"survivors": [{
			"unit_id": "P_HERO",
			"template_id": "HERO",
			"hp": 18,
			"max_hp": 20,
			"skill_id": ""
		}]
	}
	var outcome: Dictionary = rm.consume_battle_result("L1N1", "player", payload)
	checks.assert_equal(bool(outcome.get("run_ended", true)), false, "normal win does not end run.")
	checks.assert_equal(bool(outcome.get("victory", true)), false, "normal win is not victory.")
	var state: Resource = rm.get_state()
	checks.assert_true((state.selected_path as Array).has("L1N1"), "node marked completed.")
	checks.assert_equal(int(state.current_layer), 2, "layer advanced.")
	checks.assert_equal(int(state.balls), 2, "balls synced.")
	rm.queue_free()

func _test_hero_death_ends_run() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(7)
	var payload: Dictionary = {
		"is_boss": false,
		"hero_dead": true,
		"balls_remaining": 0,
		"deploy_unit_ids": ["P_HERO"],
		"survivors": []
	}
	var outcome: Dictionary = rm.consume_battle_result("L1N1", "enemy", payload)
	checks.assert_equal(bool(outcome.get("run_ended", false)), true, "hero death ends run.")
	checks.assert_equal(bool(outcome.get("victory", true)), false, "hero death is not victory.")
	checks.assert_equal(bool(rm.get_state().hero_dead), true, "hero_dead set.")
	rm.queue_free()

func _test_boss_win_ends_run() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(5)
	var state: Resource = rm.get_state()
	state.current_layer = 6
	var payload: Dictionary = {
		"is_boss": true,
		"hero_dead": false,
		"balls_remaining": 1,
		"deploy_unit_ids": ["P_HERO"],
		"survivors": [{
			"unit_id": "P_HERO",
			"template_id": "HERO",
			"hp": 20,
			"max_hp": 20,
			"skill_id": ""
		}]
	}
	var outcome: Dictionary = rm.consume_battle_result("L6N1", "player", payload)
	checks.assert_equal(bool(outcome.get("run_ended", false)), true, "boss win ends run.")
	checks.assert_equal(bool(outcome.get("victory", false)), true, "boss win is victory.")
	rm.queue_free()

func _test_reserve_hp_sync() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(3)
	var state: Resource = rm.get_state()
	state.reserve = [{
		"unit_id": "P_M01_001",
		"template_id": "M01",
		"hp": 10,
		"max_hp": 12,
		"skill_id": "SK01"
	}, {
		"unit_id": "P_M02_001",
		"template_id": "M02",
		"hp": 8,
		"max_hp": 10,
		"skill_id": "SK02"
	}]
	var payload: Dictionary = {
		"is_boss": false,
		"hero_dead": false,
		"balls_remaining": 3,
		"deploy_unit_ids": ["P_HERO", "P_M01_001"],
		"survivors": [
			{
				"unit_id": "P_HERO",
				"template_id": "HERO",
				"hp": 15,
				"max_hp": 20,
				"skill_id": ""
			},
			{
				"unit_id": "P_M01_001",
				"template_id": "M01",
				"hp": 5,
				"max_hp": 12,
				"skill_id": "SK01"
			}
		]
	}
	rm.consume_battle_result("L1N2", "player", payload)
	var reserve: Array = state.reserve as Array
	checks.assert_equal(reserve.size(), 2, "dead deploy removed, bench kept.")
	var m01_hp: int = -1
	var m02_hp: int = -1
	for entry_v in reserve:
		var entry: Dictionary = entry_v as Dictionary
		if String(entry.get("unit_id", "")) == "P_M01_001":
			m01_hp = int(entry.get("hp", -1))
		if String(entry.get("unit_id", "")) == "P_M02_001":
			m02_hp = int(entry.get("hp", -1))
	checks.assert_equal(m01_hp, 5, "deploy survivor hp updated.")
	checks.assert_equal(m02_hp, 8, "non-deploy reserve unchanged.")
	rm.queue_free()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
