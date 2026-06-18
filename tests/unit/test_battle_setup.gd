extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const BattleUnit = preload("res://scripts/battle/battle_unit.gd")
const CombatCalc = preload("res://scripts/battle/combat_calc.gd")
const AttackRange = preload("res://scripts/battle/attack_range.gd")
const Pathfinding = preload("res://scripts/battle/pathfinding.gd")
const BattleController = preload("res://scripts/battle/battle_controller.gd")

const TEMPLATE_PATH: String = "res://data/map_templates/test_grid.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	var grid: RefCounted = _load_grid()
	if grid == null:
		quit(checks.finish())
		return

	var hero: RefCounted = BattleUnit.from_template("HERO", true, Vector2i(0, 4), "P_HERO")
	var fox: RefCounted = BattleUnit.from_template("M01", true, Vector2i(1, 4), "P_M01")
	var turtle: RefCounted = BattleUnit.from_template("M02", false, Vector2i(9, 4), "E_M02")
	var hawk: RefCounted = BattleUnit.from_template("M03", false, Vector2i(8, 3), "E_M03")
	turtle.weapon = "axe"

	var units: Array = [hero, fox, turtle, hawk]
	for unit in units:
		grid.set_occupant(unit.grid_pos, String(unit.unit_id))

	var player_deploy: Array = grid.deploy_zones.get("player", [])
	var enemy_deploy: Array = grid.deploy_zones.get("enemy", [])
	checks.assert_true(player_deploy.has(hero.grid_pos), "hero spawns in player deploy zone.")
	checks.assert_true(player_deploy.has(fox.grid_pos), "fox spawns in player deploy zone.")
	checks.assert_true(enemy_deploy.has(turtle.grid_pos), "turtle spawns in enemy deploy zone.")

	var fox_reach: Array[Vector2i] = Pathfinding.get_reachable(grid, fox.grid_pos, int(fox.mov), String(fox.unit_type), String(fox.unit_id))
	var fox_reach_set: Dictionary = {}
	for cell in fox_reach:
		fox_reach_set[cell] = true
	checks.assert_true(fox_reach_set.has(Vector2i(2, 4)), "M01 can move forward on test map.")
	checks.assert_true(not fox_reach_set.has(Vector2i(3, 3)), "M01 cannot walk through wall at (3,3).")

	var hawk_range: Dictionary = AttackRange.get_basic_attack_range(hawk)
	var hawk_targets: Array[Vector2i] = AttackRange.get_attack_targets(
		grid,
		hawk.grid_pos,
		int(hawk_range.min),
		int(hawk_range.max)
	)
	var hawk_target_set: Dictionary = {}
	for cell in hawk_targets:
		hawk_target_set[cell] = true
	checks.assert_true(hawk_target_set.has(Vector2i(9, 4)), "flying M03 can basic-attack turtle at dist 2.")
	checks.assert_true(not hawk_target_set.has(Vector2i(0, 4)), "flying M03 cannot basic-attack hero at dist 8.")

	var gust: Dictionary = loader.get_skill("S_GUST")
	var gust_range: Dictionary = AttackRange.get_skill_range(gust)
	var gust_targets: Array[Vector2i] = AttackRange.get_attack_targets(
		grid,
		hawk.grid_pos,
		int(gust_range.min),
		int(gust_range.max)
	)
	var gust_set: Dictionary = {}
	for cell in gust_targets:
		gust_set[cell] = true
	checks.assert_true(gust_set.has(Vector2i(6, 3)), "S_GUST range 3 reaches mid-map from hawk position.")

	# 实战数值下 hero atk=8 对 def=7 会被截成 1 点；这里只验证武器克制仍影响公式结果。
	hero.atk = 12
	turtle.weapon = "axe"
	var sword_damage: int = CombatCalc.calc_damage(hero, turtle, grid, 1.0)
	hero.weapon = "none"
	var neutral_damage: int = CombatCalc.calc_damage(hero, turtle, grid, 1.0)
	checks.assert_true(sword_damage > neutral_damage, "sword vs axe deals more than neutral weapon on demo matchup.")

	# 第 5 章：野生敌人被打到 0 hp 应进入 downed_capturable 而不离场。
	var lone_units: Array = []
	var wild_fox: RefCounted = BattleUnit.from_template("M01", false, Vector2i(2, 2), "WILD_M01")
	wild_fox.hp = 1
	wild_fox.max_hp = 18
	lone_units.append(wild_fox)
	grid.set_occupant(wild_fox.grid_pos, String(wild_fox.unit_id))
	BattleController.apply_damage(wild_fox, 999)
	checks.assert_equal(int(wild_fox.hp), 0, "wild M01 reaches 0 hp.")
	checks.assert_true(bool(wild_fox.downed_capturable), "wild M01 enters downed_capturable.")
	checks.assert_true(not BattleController.remove_dead_unit(lone_units, wild_fox, grid), "downed unit not removed.")
	checks.assert_true(lone_units.has(wild_fox), "wild unit still in units list.")
	checks.assert_equal(String(grid.get_occupant(wild_fox.grid_pos)), String(wild_fox.unit_id), "wild unit still occupies its grid cell.")
	checks.assert_true(not BattleController.is_alive(wild_fox), "downed unit is not alive_for_battle.")
	# check_victory 应判玩家胜（该列表里只有这只 downed 野怪 + 没有玩家）→ 添加一名玩家保持判定一致：
	var hero_alive: RefCounted = BattleUnit.from_template("HERO", true, Vector2i(0, 0), "P_HERO_VICTORY")
	lone_units.append(hero_alive)
	checks.assert_equal(String(BattleController.check_victory(lone_units)), "player", "all-downed enemies counts as player victory.")

	quit(checks.finish())

func _load_grid() -> RefCounted:
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
