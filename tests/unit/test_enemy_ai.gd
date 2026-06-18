extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const EnemyAI = preload("res://scripts/battle/enemy_ai.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	get_root().get_node("DataLoader").load_all()

	var grid: RefCounted = _plain_grid(10)
	var enemy: RefCounted = _make_unit("E1", false, Vector2i(5, 5), 4)
	var weak: RefCounted = _make_unit("P_WEAK", true, Vector2i(6, 5), 4, 5)
	var tough: RefCounted = _make_unit("P_TOUGH", true, Vector2i(5, 6), 4, 20)
	var units: Array = [enemy, weak, tough]

	var attack_action: Dictionary = EnemyAI.decide_action(enemy, grid, units)
	checks.assert_equal(String(attack_action.get("action", "")), "attack", "AI attacks in range.")
	checks.assert_equal(String(attack_action.get("target_unit").unit_id), "P_WEAK", "AI picks lowest HP.")

	enemy.grid_pos = Vector2i(0, 0)
	weak.grid_pos = Vector2i(9, 9)
	tough.grid_pos = Vector2i(8, 8)
	enemy.mov = 4
	var move_action: Dictionary = EnemyAI.decide_action(enemy, grid, units)
	checks.assert_equal(String(move_action.get("action", "")), "move", "AI moves when out of range.")
	var move_cell: Vector2i = move_action.get("target_cell", Vector2i(-1, -1))
	checks.assert_true(move_cell != enemy.grid_pos, "AI picks a different cell.")

	enemy.grid_pos = Vector2i(3, 3)
	enemy.mov = 0
	weak.grid_pos = Vector2i(9, 9)
	tough.grid_pos = Vector2i(8, 8)
	var wait_action: Dictionary = EnemyAI.decide_action(enemy, grid, units)
	checks.assert_equal(String(wait_action.get("action", "")), "wait", "AI waits when stuck.")

	quit(checks.finish())

func _plain_grid(size: int) -> RefCounted:
	var rows: Array = []
	for y in size:
		var row: Array = []
		for x in size:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	return Grid.from_template({"width": size, "height": size, "terrain": rows, "deploy_zones": {}})

func _make_unit(unit_id: String, is_player: bool, pos: Vector2i, mov: int, hp: int = 10) -> RefCounted:
	var unit: RefCounted = (load("res://scripts/battle/battle_unit.gd") as GDScript).new()
	unit.unit_id = unit_id
	unit.is_player = is_player
	unit.grid_pos = pos
	unit.hp = hp
	unit.max_hp = hp
	unit.mov = mov
	unit.unit_type = "foot"
	unit.weapon = "none"
	return unit
