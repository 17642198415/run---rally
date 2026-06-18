extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const Pathfinding = preload("res://scripts/battle/pathfinding.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	_test_plain_reachable_equals_manhattan()
	_test_mountain_costs_extra()
	_test_walls_and_occupants_blocked()
	_test_flying_traverses_water()
	_test_find_path_connected()
	_test_find_path_unreachable_returns_empty()
	quit(checks.finish())

func _make_plain_grid(size: int = 10) -> Grid:
	var rows: Array = []
	for y in size:
		var row: Array = []
		for x in size:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	return Grid.from_template({
		"width": size,
		"height": size,
		"terrain": rows,
		"deploy_zones": {}
	})

func _make_grid(terrain_2d: Array) -> Grid:
	var height: int = terrain_2d.size()
	var width: int = (terrain_2d[0] as Array).size() if height > 0 else 0
	return Grid.from_template({
		"width": width,
		"height": height,
		"terrain": terrain_2d,
		"deploy_zones": {}
	})

func _test_plain_reachable_equals_manhattan() -> void:
	var grid: Grid = _make_plain_grid(10)
	var start: Vector2i = Vector2i(5, 5)
	var reachable: Array[Vector2i] = Pathfinding.get_reachable(grid, start, 4, "foot")
	var reachable_set: Dictionary = {}
	for cell in reachable:
		reachable_set[cell] = true

	for y in 10:
		for x in 10:
			var pos: Vector2i = Vector2i(x, y)
			if pos == start:
				checks.assert_true(not reachable_set.has(pos), "start (5,5) is not in reachable set.")
				continue
			var dist: int = absi(x - 5) + absi(y - 5)
			if dist <= 4:
				checks.assert_true(reachable_set.has(pos), "(%d,%d) within MOV=4 should be reachable." % [x, y])
			else:
				checks.assert_true(not reachable_set.has(pos), "(%d,%d) beyond MOV=4 should be unreachable." % [x, y])

func _test_mountain_costs_extra() -> void:
	var rows: Array = []
	for y in 5:
		var row: Array = []
		for x in 5:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	rows[0][1] = TerrainTypes.MOUNT
	var grid: Grid = _make_grid(rows)

	var reachable: Array[Vector2i] = Pathfinding.get_reachable(grid, Vector2i(0, 0), 3, "foot")
	var reachable_set: Dictionary = {}
	for cell in reachable:
		reachable_set[cell] = true

	checks.assert_true(reachable_set.has(Vector2i(1, 0)), "(1,0) mountain is reachable when MOV=3 (cost 2).")
	checks.assert_true(reachable_set.has(Vector2i(2, 0)), "(2,0) reachable through mountain (cost 1+2=3).")
	checks.assert_true(not reachable_set.has(Vector2i(3, 0)), "(3,0) unreachable through mountain at MOV=3.")
	checks.assert_true(reachable_set.has(Vector2i(0, 3)), "(0,3) all-plain path stays reachable at MOV=3.")

func _test_walls_and_occupants_blocked() -> void:
	var rows: Array = []
	for y in 5:
		var row: Array = []
		for x in 5:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	rows[0][2] = TerrainTypes.WALL
	var grid: Grid = _make_grid(rows)
	grid.set_occupant(Vector2i(0, 2), "ENEMY")

	var reachable: Array[Vector2i] = Pathfinding.get_reachable(grid, Vector2i(0, 0), 3, "foot")
	var reachable_set: Dictionary = {}
	for cell in reachable:
		reachable_set[cell] = true

	checks.assert_true(not reachable_set.has(Vector2i(2, 0)), "wall cell (2,0) is excluded.")
	checks.assert_true(not reachable_set.has(Vector2i(0, 2)), "enemy-occupied cell (0,2) is excluded.")
	checks.assert_true(reachable_set.has(Vector2i(1, 0)), "(1,0) reachable in front of wall.")

func _test_flying_traverses_water() -> void:
	var rows: Array = []
	for y in 5:
		var row: Array = []
		for x in 5:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	rows[0][1] = TerrainTypes.WATER
	rows[0][2] = TerrainTypes.WATER
	var grid: Grid = _make_grid(rows)

	var foot_reach: Array[Vector2i] = Pathfinding.get_reachable(grid, Vector2i(0, 0), 4, "foot")
	var fly_reach: Array[Vector2i] = Pathfinding.get_reachable(grid, Vector2i(0, 0), 4, "flying")

	var foot_set: Dictionary = {}
	for cell in foot_reach:
		foot_set[cell] = true
	var fly_set: Dictionary = {}
	for cell in fly_reach:
		fly_set[cell] = true

	checks.assert_true(not foot_set.has(Vector2i(1, 0)), "foot cannot enter water (1,0).")
	checks.assert_true(not foot_set.has(Vector2i(2, 0)), "foot cannot enter water (2,0).")
	checks.assert_true(fly_set.has(Vector2i(1, 0)), "flying can enter water (1,0).")
	checks.assert_true(fly_set.has(Vector2i(2, 0)), "flying can enter water (2,0).")

func _test_find_path_connected() -> void:
	var grid: Grid = _make_plain_grid(10)
	var path: Array[Vector2i] = Pathfinding.find_path(grid, Vector2i(0, 0), Vector2i(2, 1), 4, "foot")
	checks.assert_true(path.size() >= 2, "path has at least start and goal.")
	checks.assert_equal(path[0], Vector2i(0, 0), "path starts at start.")
	checks.assert_equal(path[path.size() - 1], Vector2i(2, 1), "path ends at goal.")
	for i in range(1, path.size()):
		var diff: Vector2i = path[i] - path[i - 1]
		var manhattan: int = absi(diff.x) + absi(diff.y)
		checks.assert_equal(manhattan, 1, "consecutive path cells differ by 1 step.")

func _test_find_path_unreachable_returns_empty() -> void:
	var rows: Array = []
	for y in 5:
		var row: Array = []
		for x in 5:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	rows[0][1] = TerrainTypes.WALL
	rows[1][1] = TerrainTypes.WALL
	rows[2][1] = TerrainTypes.WALL
	rows[3][1] = TerrainTypes.WALL
	rows[4][1] = TerrainTypes.WALL
	var grid: Grid = _make_grid(rows)

	var path: Array[Vector2i] = Pathfinding.find_path(grid, Vector2i(0, 0), Vector2i(2, 0), 6, "foot")
	checks.assert_equal(path.size(), 0, "blocked goal returns empty path.")

	var path2: Array[Vector2i] = Pathfinding.find_path(grid, Vector2i(0, 0), Vector2i(0, 4), 2, "foot")
	checks.assert_equal(path2.size(), 0, "out-of-budget goal returns empty path.")
