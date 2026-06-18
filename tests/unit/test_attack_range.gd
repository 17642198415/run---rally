extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const AttackRange = preload("res://scripts/battle/attack_range.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var foot_unit: RefCounted = _make_unit("foot")
	var fly_unit: RefCounted = _make_unit("flying")

	checks.assert_equal(AttackRange.get_basic_attack_range(foot_unit), {"min": 1, "max": 1}, "foot attacks at range 1.")
	checks.assert_equal(AttackRange.get_basic_attack_range(fly_unit), {"min": 2, "max": 2}, "flying attacks at range 2.")

	checks.assert_equal(AttackRange.get_skill_range({"range": 3}), {"min": 1, "max": 3}, "skill range 3 is 1-3.")
	checks.assert_equal(AttackRange.get_skill_range({"range": 0}), {"min": 1, "max": 1}, "invalid skill range falls back to 1.")
	checks.assert_equal(AttackRange.get_skill_range({}), {"min": 1, "max": 1}, "missing skill range defaults to 1.")

	checks.assert_true(AttackRange.is_in_range(Vector2i(5, 5), Vector2i(6, 5), 1, 1), "(6,5) is in range 1 from (5,5).")
	checks.assert_true(not AttackRange.is_in_range(Vector2i(5, 5), Vector2i(7, 5), 1, 1), "(7,5) is out of range 1 from (5,5).")
	checks.assert_true(AttackRange.is_in_range(Vector2i(5, 5), Vector2i(7, 5), 2, 2), "(7,5) is in range 2 from (5,5).")

	var grid: RefCounted = _make_plain_grid(5)
	var targets: Array[Vector2i] = AttackRange.get_attack_targets(grid, Vector2i(2, 2), 1, 1)
	var target_set: Dictionary = {}
	for cell in targets:
		target_set[cell] = true

	checks.assert_true(not target_set.has(Vector2i(2, 2)), "attack targets exclude origin.")
	checks.assert_true(target_set.has(Vector2i(2, 1)), "orthogonal neighbor at dist 1 is a target.")
	checks.assert_true(target_set.has(Vector2i(3, 2)), "orthogonal neighbor at dist 1 is a target.")
	checks.assert_true(not target_set.has(Vector2i(0, 0)), "corner at dist 4 is not a range-1 target.")

	var fly_targets: Array[Vector2i] = AttackRange.get_attack_targets(grid, Vector2i(2, 2), 2, 2)
	var fly_set: Dictionary = {}
	for cell in fly_targets:
		fly_set[cell] = true
	checks.assert_true(fly_set.has(Vector2i(4, 2)), "dist-2 cell is in flying attack band.")
	checks.assert_true(not fly_set.has(Vector2i(4, 4)), "dist-4 cell is outside flying attack band.")

	quit(checks.finish())

func _make_unit(unit_type: String) -> RefCounted:
	var unit: RefCounted = (load("res://scripts/battle/battle_unit.gd") as GDScript).new()
	unit.unit_type = unit_type
	return unit

func _make_plain_grid(size: int) -> RefCounted:
	var rows: Array = []
	for y in size:
		var row: Array = []
		for x in size:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	return Grid.from_template({"width": size, "height": size, "terrain": rows, "deploy_zones": {}})
