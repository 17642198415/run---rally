extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const EnemyGroupPicker = preload("res://scripts/roguelike/enemy_group_picker.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	_test_normal_layer_returns_valid_group()
	_test_boss_layer_returns_boss_group()
	_test_same_rng_seed_same_result()
	_test_missing_file_returns_empty()
	_test_layer_5_normal_returns_valid_group()
	_test_inject_pool_extras_replaces_enemy()
	_test_t_mix_elite_spawns_not_on_wall()
	quit(checks.finish())

func _test_normal_layer_returns_valid_group() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var group: Dictionary = EnemyGroupPicker.pick(1, false, false, rng)
	checks.assert_true(group.has("map_template"), "group has map_template.")
	var mt: String = String(group.get("map_template", ""))
	checks.assert_true(not mt.is_empty(), "map_template not empty.")
	var enemies: Array = group.get("enemies", []) as Array
	checks.assert_true(enemies.size() >= 1, "at least 1 enemy in group, got %d." % [enemies.size()])

func _test_boss_layer_returns_boss_group() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var group: Dictionary = EnemyGroupPicker.pick(6, false, true, rng)
	var enemies: Array = group.get("enemies", []) as Array
	checks.assert_true(enemies.size() >= 1, "boss group has enemies.")
	checks.assert_equal(String(group.get("map_template", "")), "T_FORT", "boss map is T_FORT.")

func _test_same_rng_seed_same_result() -> void:
	var rng1 := RandomNumberGenerator.new()
	rng1.seed = 42
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 42
	var group1: Dictionary = EnemyGroupPicker.pick(2, false, false, rng1)
	var group2: Dictionary = EnemyGroupPicker.pick(2, false, false, rng2)
	checks.assert_equal(
		String(group1.get("map_template", "")),
		String(group2.get("map_template", "")),
		"same seed yields same map_template."
	)
	var e1: Array = group1.get("enemies", []) as Array
	var e2: Array = group2.get("enemies", []) as Array
	if e1.size() == e2.size() and e1.size() > 0:
		var t1: String = String((e1[0] as Dictionary).get("template", ""))
		var t2: String = String((e2[0] as Dictionary).get("template", ""))
		checks.assert_equal(t1, t2, "same seed yields same first enemy template.")

func _test_missing_file_returns_empty() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var group: Dictionary = EnemyGroupPicker.pick(99, false, false, rng)
	checks.assert_equal(String(group.get("map_template", "")), "", "missing returns empty map_template.")
	checks.assert_equal((group.get("enemies", []) as Array).size(), 0, "missing returns empty enemies.")

func _test_layer_5_normal_returns_valid_group() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	var group: Dictionary = EnemyGroupPicker.pick(5, false, false, rng)
	checks.assert_true(not String(group.get("map_template", "")).is_empty(), "layer 5 normal has map.")
	checks.assert_true((group.get("enemies", []) as Array).size() >= 1, "layer 5 normal has enemies.")

func _test_inject_pool_extras_replaces_enemy() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var group: Dictionary = {
		"map_template": "T_PLAIN",
		"enemies": [{"template": "M01", "spawn": {"x": 7, "y": 3}}]
	}
	var out: Dictionary = EnemyGroupPicker.inject_pool_extras(group, ["M05"], rng)
	var enemies: Array = out.get("enemies", []) as Array
	checks.assert_equal(
		String((enemies[0] as Dictionary).get("template", "")),
		"M05",
		"inject_pool_extras replaces enemy with M05."
	)

func _test_t_mix_elite_spawns_not_on_wall() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()
	var grid: RefCounted = loader.load_stage_map({"map_template": "T_MIX"})
	checks.assert_true(grid != null, "T_MIX loads.")
	var paths: Array[String] = [
		"res://data/enemy_groups/layer_3_4_elite.json",
		"res://data/enemy_groups/layer_5_elite.json"
	]
	for path in paths:
		var file := FileAccess.open(path, FileAccess.READ)
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		var groups: Array = (parsed as Dictionary).get("groups", []) as Array
		for group_v in groups:
			var group: Dictionary = group_v as Dictionary
			if String(group.get("map_template", "")) != "T_MIX":
				continue
			for enemy_v in group.get("enemies", []) as Array:
				var enemy: Dictionary = enemy_v as Dictionary
				var spawn: Dictionary = enemy.get("spawn", {}) as Dictionary
				var pos: Vector2i = Vector2i(int(spawn.get("x", -1)), int(spawn.get("y", -1)))
				var terrain: int = int(grid.get_terrain(pos))
				checks.assert_true(
					terrain != 4,
					"%s spawn %s not on WALL (terrain %d)." % [path, str(pos), terrain]
				)