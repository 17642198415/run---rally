extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RunStateScript = preload("res://scripts/roguelike/run_state.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	_test_defaults()
	_test_round_trip_serialize()
	_test_mark_node_and_advance()
	_test_deserialize_handles_missing_keys()
	_test_heal_entries_percent()
	_test_full_heal_entries()
	_test_remove_reserve_unit()
	_test_next_reserve_unit_id_skips_gaps()
	quit(checks.finish())

func _test_defaults() -> void:
	var rs: Resource = RunStateScript.new()
	checks.assert_equal(int(rs.seed), 0, "default seed 0.")
	checks.assert_equal(int(rs.current_layer), 1, "default current_layer 1.")
	checks.assert_equal(int(rs.balls), 3, "default balls 3.")
	checks.assert_equal(int(rs.coins), 0, "default coins 0.")
	checks.assert_equal(bool(rs.hero_dead), false, "default hero_dead false.")
	checks.assert_equal((rs.party as Array).size(), 0, "default party empty.")
	checks.assert_equal((rs.reserve as Array).size(), 0, "default reserve empty.")
	checks.assert_equal((rs.route_graph as Array).size(), 0, "default route_graph empty.")
	checks.assert_equal((rs.selected_path as Array).size(), 0, "default selected_path empty.")
	checks.assert_equal((rs.pending_rewards as Array).size(), 0, "default pending_rewards empty.")
	checks.assert_equal(bool(rs.pending_reward_is_boss), false, "default pending_reward_is_boss false.")

func _test_round_trip_serialize() -> void:
	var rs: Resource = RunStateScript.new()
	rs.seed = 42
	rs.current_layer = 3
	rs.balls = 2
	rs.coins = 18
	rs.hero_dead = false
	rs.route_graph = [
		{ "layer": 1, "nodes": [{ "id": "L1N0", "type": "battle" }] },
		{ "layer": 2, "nodes": [{ "id": "L2N0", "type": "rest" }] }
	]
	rs.selected_path = ["L1N0", "L2N0"]
	rs.party = [{ "template_id": "HERO", "hp": 30 }]
	rs.reserve = [{ "template_id": "M01", "hp": 18 }]
	rs.pending_rewards = [{"id": "R_BALL", "name": "补给球"}]
	rs.pending_reward_is_boss = true

	var dict: Dictionary = rs.serialize()
	var rs2: Resource = RunStateScript.deserialize(dict)
	var dict2: Dictionary = rs2.serialize()
	checks.assert_equal(dict, dict2, "serialize-deserialize-serialize is idempotent.")
	checks.assert_equal(int(rs2.seed), 42, "deserialized seed.")
	checks.assert_equal(int(rs2.current_layer), 3, "deserialized current_layer.")
	checks.assert_equal((rs2.selected_path as Array).size(), 2, "deserialized selected_path size.")
	checks.assert_equal((rs2.pending_rewards as Array).size(), 1, "deserialized pending_rewards size.")
	checks.assert_equal(bool(rs2.pending_reward_is_boss), true, "deserialized pending_reward_is_boss.")

func _test_mark_node_and_advance() -> void:
	var rs: Resource = RunStateScript.new()
	rs.route_graph = [
		{ "layer": 1, "nodes": [{ "id": "L1N0", "type": "battle" }, { "id": "L1N1", "type": "rest" }] },
		{ "layer": 2, "nodes": [{ "id": "L2N0", "type": "boss" }] }
	]
	rs.current_layer = 1
	rs.mark_node_completed("L1N0")
	checks.assert_equal((rs.selected_path as Array).size(), 1, "selected_path after one mark.")
	checks.assert_equal(String((rs.selected_path as Array)[0]), "L1N0", "selected_path content.")
	rs.advance_layer()
	checks.assert_equal(int(rs.current_layer), 2, "advance_layer increments layer.")

func _test_deserialize_handles_missing_keys() -> void:
	var rs: Resource = RunStateScript.deserialize({})
	checks.assert_equal(int(rs.seed), 0, "deserialize empty returns defaults seed.")
	checks.assert_equal(int(rs.current_layer), 1, "deserialize empty returns defaults layer.")
	checks.assert_equal(int(rs.balls), 3, "deserialize empty returns defaults balls.")
	checks.assert_equal((rs.pending_rewards as Array).size(), 0, "legacy deserialize pending empty.")
	checks.assert_equal(bool(rs.pending_reward_is_boss), false, "legacy deserialize pending boss false.")

func _test_heal_entries_percent() -> void:
	var party: Array = [{
		"unit_id": "P_HERO",
		"template_id": "HERO",
		"hp": 10,
		"max_hp": 20,
		"skill_id": ""
	}]
	var reserve: Array = [{
		"unit_id": "P_M01_001",
		"template_id": "M01",
		"hp": 6,
		"max_hp": 12,
		"skill_id": "SK01"
	}]
	var healed_party: Array = RunStateScript.heal_entries_percent(party, 0.3, 25)
	var healed_reserve: Array = RunStateScript.heal_entries_percent(reserve, 0.3, 25)
	checks.assert_equal(int((healed_party[0] as Dictionary).get("hp", 0)), 16, "hero heals 30 percent.")
	checks.assert_equal(int((healed_reserve[0] as Dictionary).get("hp", 0)), 9, "reserve heals 30 percent.")

func _test_full_heal_entries() -> void:
	var entries: Array = [{
		"unit_id": "P_M01_001",
		"template_id": "M01",
		"hp": 3,
		"max_hp": 12,
		"skill_id": "SK01"
	}]
	var healed: Array = RunStateScript.full_heal_entries(entries, 25)
	checks.assert_equal(int((healed[0] as Dictionary).get("hp", 0)), 12, "full heal restores max hp.")

func _test_remove_reserve_unit() -> void:
	var reserve: Array = [
		{"unit_id": "P_M01_001", "template_id": "M01", "hp": 5, "max_hp": 12, "skill_id": "SK01"},
		{"unit_id": "P_M02_001", "template_id": "M02", "hp": 8, "max_hp": 10, "skill_id": "SK02"}
	]
	var remaining: Array = RunStateScript.remove_reserve_unit(reserve, "P_M01_001")
	checks.assert_equal(remaining.size(), 1, "one reserve removed.")
	checks.assert_equal(String((remaining[0] as Dictionary).get("unit_id", "")), "P_M02_001", "correct unit kept.")

func _test_next_reserve_unit_id_skips_gaps() -> void:
	var reserve: Array = [
		{"unit_id": "P_M01_002", "template_id": "M01", "hp": 8, "max_hp": 12, "skill_id": "SK01"}
	]
	var party: Array = []
	var next_id: String = RunStateScript.next_reserve_unit_id(reserve, party, "M01")
	checks.assert_equal(next_id, "P_M01_003", "next id skips consumed seq 1.")