extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")

const TEMPLATE_PATH := "res://data/map_templates/test_grid.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var grid: Grid = _load_grid()
	if grid == null:
		quit(checks.finish())
		return

	checks.assert_equal(grid.width, 10, "grid width is 10.")
	checks.assert_equal(grid.height, 10, "grid height is 10.")

	checks.assert_equal(grid.get_terrain(Vector2i(0, 0)), TerrainTypes.PLAIN, "(0,0) is PLAIN.")
	checks.assert_equal(grid.get_terrain(Vector2i(1, 1)), TerrainTypes.FOREST, "(1,1) is FOREST.")
	checks.assert_equal(grid.get_terrain(Vector2i(4, 1)), TerrainTypes.MOUNT, "(4,1) is MOUNT.")
	checks.assert_equal(grid.get_terrain(Vector2i(8, 2)), TerrainTypes.WATER, "(8,2) is WATER.")
	checks.assert_equal(grid.get_terrain(Vector2i(3, 3)), TerrainTypes.WALL, "(3,3) is WALL.")

	checks.assert_true(not grid.is_walkable(Vector2i(-1, 0), "foot"), "out of bounds (-1,0) not walkable.")
	checks.assert_true(not grid.is_walkable(Vector2i(0, 10), "foot"), "out of bounds (0,10) not walkable.")
	checks.assert_true(not grid.is_walkable(Vector2i(10, 5), "foot"), "out of bounds (10,5) not walkable.")

	checks.assert_true(grid.is_walkable(Vector2i(0, 0), "foot"), "foot can walk on plain.")
	checks.assert_true(grid.is_walkable(Vector2i(1, 1), "foot"), "foot can walk on forest.")
	checks.assert_true(grid.is_walkable(Vector2i(4, 1), "foot"), "foot can walk on mountain.")

	checks.assert_true(not grid.is_walkable(Vector2i(8, 2), "foot"), "foot cannot walk on water.")
	checks.assert_true(not grid.is_walkable(Vector2i(3, 3), "foot"), "foot cannot walk on wall.")

	checks.assert_true(grid.is_walkable(Vector2i(8, 2), "flying"), "flying can walk on water.")
	checks.assert_true(not grid.is_walkable(Vector2i(3, 3), "flying"), "flying cannot walk on wall.")

	grid.set_occupant(Vector2i(2, 2), "ALLY")
	checks.assert_true(not grid.is_walkable(Vector2i(2, 2), "foot"), "occupied cell blocks others.")
	checks.assert_true(not grid.is_walkable(Vector2i(2, 2), "foot", "OTHER"), "occupied cell blocks other mover id.")
	checks.assert_true(grid.is_walkable(Vector2i(2, 2), "foot", "ALLY"), "mover is not blocked by its own cell.")

	grid.clear_occupant(Vector2i(2, 2))
	checks.assert_true(grid.is_walkable(Vector2i(2, 2), "foot"), "cleared cell is walkable again.")

	var move_cost_plain: int = grid.get_move_cost(Vector2i(0, 0), Vector2i(0, 1), "foot")
	var move_cost_mount: int = grid.get_move_cost(Vector2i(3, 1), Vector2i(4, 1), "foot")
	checks.assert_equal(move_cost_plain, 1, "entering plain costs 1.")
	checks.assert_equal(move_cost_mount, 2, "entering mountain costs 2.")

	var deploy_player: Array = grid.deploy_zones.get("player", [])
	var deploy_enemy: Array = grid.deploy_zones.get("enemy", [])
	checks.assert_true(deploy_player.size() >= 1, "player deploy zone is non-empty.")
	checks.assert_true(deploy_enemy.size() >= 1, "enemy deploy zone is non-empty.")
	checks.assert_true(deploy_player.has(Vector2i(0, 4)), "player deploy zone includes (0,4).")
	checks.assert_true(deploy_enemy.has(Vector2i(9, 4)), "enemy deploy zone includes (9,4).")

	quit(checks.finish())

func _load_grid() -> Grid:
	if not FileAccess.file_exists(TEMPLATE_PATH):
		checks.assert_true(false, "template file %s missing." % TEMPLATE_PATH)
		return null
	var file: FileAccess = FileAccess.open(TEMPLATE_PATH, FileAccess.READ)
	if file == null:
		checks.assert_true(false, "cannot open template file %s." % TEMPLATE_PATH)
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		checks.assert_true(false, "template JSON root is not a dictionary.")
		return null
	return Grid.from_template(parsed)
