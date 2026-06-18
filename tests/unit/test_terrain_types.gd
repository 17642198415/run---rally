extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	checks.assert_equal(TerrainTypes.PLAIN, 0, "PLAIN constant is 0.")
	checks.assert_equal(TerrainTypes.FOREST, 1, "FOREST constant is 1.")
	checks.assert_equal(TerrainTypes.MOUNT, 2, "MOUNT constant is 2.")
	checks.assert_equal(TerrainTypes.WATER, 3, "WATER constant is 3.")
	checks.assert_equal(TerrainTypes.WALL, 4, "WALL constant is 4.")

	checks.assert_equal(TerrainTypes.get_def_bonus(TerrainTypes.PLAIN), 0, "plain has no def bonus.")
	checks.assert_equal(TerrainTypes.get_def_bonus(TerrainTypes.FOREST), 1, "forest gives +1 def.")
	checks.assert_equal(TerrainTypes.get_def_bonus(TerrainTypes.MOUNT), 1, "mountain gives +1 def.")
	checks.assert_equal(TerrainTypes.get_def_bonus(TerrainTypes.WATER), 0, "water has no def bonus.")
	checks.assert_equal(TerrainTypes.get_def_bonus(TerrainTypes.WALL), 0, "wall has no def bonus.")

	checks.assert_equal(TerrainTypes.get_move_cost_extra(TerrainTypes.PLAIN), 0, "plain has no extra move cost.")
	checks.assert_equal(TerrainTypes.get_move_cost_extra(TerrainTypes.FOREST), 0, "forest has no extra move cost.")
	checks.assert_equal(TerrainTypes.get_move_cost_extra(TerrainTypes.MOUNT), 1, "mountain costs +1 to enter.")
	checks.assert_equal(TerrainTypes.get_move_cost_extra(TerrainTypes.WATER), 0, "water has no extra move cost.")
	checks.assert_equal(TerrainTypes.get_move_cost_extra(TerrainTypes.WALL), 0, "wall has no extra move cost.")

	checks.assert_true(TerrainTypes.is_passable(TerrainTypes.PLAIN, "foot"), "foot can pass plain.")
	checks.assert_true(TerrainTypes.is_passable(TerrainTypes.FOREST, "foot"), "foot can pass forest.")
	checks.assert_true(TerrainTypes.is_passable(TerrainTypes.MOUNT, "foot"), "foot can pass mountain.")
	checks.assert_true(not TerrainTypes.is_passable(TerrainTypes.WATER, "foot"), "foot cannot pass water.")
	checks.assert_true(not TerrainTypes.is_passable(TerrainTypes.WALL, "foot"), "foot cannot pass wall.")

	checks.assert_true(TerrainTypes.is_passable(TerrainTypes.PLAIN, "flying"), "flying can pass plain.")
	checks.assert_true(TerrainTypes.is_passable(TerrainTypes.FOREST, "flying"), "flying can pass forest.")
	checks.assert_true(TerrainTypes.is_passable(TerrainTypes.MOUNT, "flying"), "flying can pass mountain.")
	checks.assert_true(TerrainTypes.is_passable(TerrainTypes.WATER, "flying"), "flying can pass water.")
	checks.assert_true(not TerrainTypes.is_passable(TerrainTypes.WALL, "flying"), "flying cannot pass wall.")

	var color_table: Dictionary = TerrainTypes.COLOR_BY_TERRAIN
	checks.assert_true(color_table.has(TerrainTypes.PLAIN), "color table has PLAIN.")
	checks.assert_true(color_table.has(TerrainTypes.FOREST), "color table has FOREST.")
	checks.assert_true(color_table.has(TerrainTypes.MOUNT), "color table has MOUNT.")
	checks.assert_true(color_table.has(TerrainTypes.WATER), "color table has WATER.")
	checks.assert_true(color_table.has(TerrainTypes.WALL), "color table has WALL.")

	quit(checks.finish())
