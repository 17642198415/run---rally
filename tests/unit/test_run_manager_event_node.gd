extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RunManagerScript = preload("res://scripts/autoload/run_manager.gd")
const RunStateScript = preload("res://scripts/roguelike/run_state.gd")

const TEST_PATH: String = "user://test_run_manager_event_node.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	var original_path: String = save_mgr.get_save_path()
	save_mgr.set_save_path(TEST_PATH)
	_cleanup()

	_test_complete_event_node()
	_test_coin_reward_normal()
	_test_coin_reward_elite()
	_test_boss_awards_no_coins()
	_test_reserve_cap_blocks_capture()
	_test_capture_id_no_collision_after_death()

	_cleanup()
	save_mgr.set_save_path(original_path)
	quit(checks.finish())

func _make_rm() -> Node:
	var rm: Node = RunManagerScript.new()
	get_root().add_child(rm)
	return rm

func _test_complete_event_node() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(11)
	var state: Resource = rm.get_state()
	state.current_layer = 2
	rm.complete_event_node("L2N1")
	checks.assert_true((state.selected_path as Array).has("L2N1"), "event node marked.")
	checks.assert_equal(int(state.current_layer), 3, "layer advanced after event.")
	checks.assert_true(rm.save(), "save after event.")
	rm.queue_free()

func _test_coin_reward_normal() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(3)
	rm.get_state().coins = 5
	var payload: Dictionary = {
		"is_boss": false,
		"is_elite": false,
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
	rm.consume_battle_result("L1N1", "player", payload)
	checks.assert_equal(int(rm.get_state().coins), 13, "normal win awards 8 coins.")
	rm.queue_free()

func _test_coin_reward_elite() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(4)
	rm.get_state().coins = 2
	var payload: Dictionary = {
		"is_boss": false,
		"is_elite": true,
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
	rm.consume_battle_result("L3N0", "player", payload)
	checks.assert_equal(int(rm.get_state().coins), 17, "elite win awards 15 coins.")
	rm.queue_free()

func _test_boss_awards_no_coins() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(8)
	var state: Resource = rm.get_state()
	state.current_layer = 6
	state.coins = 10
	var payload: Dictionary = {
		"is_boss": true,
		"is_elite": false,
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
	rm.consume_battle_result("L6N0", "player", payload)
	checks.assert_equal(int(rm.get_state().coins), 10, "boss win awards no coins.")
	rm.queue_free()

func _test_reserve_cap_blocks_capture() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(12)
	var state: Resource = rm.get_state()
	state.reserve = []
	for i in range(8):
		state.reserve.append({
			"unit_id": "P_M01_%03d" % (i + 1),
			"template_id": "M01",
			"hp": 10,
			"max_hp": 12,
			"skill_id": "SK01"
		})
	checks.assert_equal(bool(rm.add_capture_to_reserve("M02", 6, 12, "SK02")), false, "reserve cap blocks add.")
	checks.assert_equal((state.reserve as Array).size(), 8, "reserve size unchanged.")
	rm.queue_free()

func _test_capture_id_no_collision_after_death() -> void:
	var rm: Node = _make_rm()
	var state: Resource = rm.get_state()
	rm.add_capture_to_reserve("M01", 10, 12, "SK01")
	rm.add_capture_to_reserve("M01", 10, 12, "SK01")
	state.reserve = RunStateScript.remove_reserve_unit(state.reserve as Array, "P_M01_001")
	rm.add_capture_to_reserve("M01", 6, 12, "SK01")
	var ids: Array = []
	for entry_v in state.reserve as Array:
		ids.append(String((entry_v as Dictionary).get("unit_id", "")))
	checks.assert_equal(ids.size(), 2, "two reserve units remain.")
	checks.assert_equal(ids[0] != ids[1], true, "unit ids are unique.")
	checks.assert_true(ids.has("P_M01_002"), "survivor kept.")
	checks.assert_true(ids.has("P_M01_003"), "new capture uses next free id.")
	rm.queue_free()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
