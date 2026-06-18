extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const BattleUnit = preload("res://scripts/battle/battle_unit.gd")
const CombatCalc = preload("res://scripts/battle/combat_calc.gd")
const WeaponTriangle = preload("res://scripts/battle/weapon_triangle.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var grid: RefCounted = _make_plain_grid()
	var attacker: RefCounted = _make_unit(5, 10, "none", Vector2i(0, 0))
	var defender: RefCounted = _make_unit(20, 15, "none", Vector2i(1, 0))

	checks.assert_equal(CombatCalc.calc_damage(attacker, defender, grid, 1.0), 1, "minimum damage is 1.")

	var forest_grid: RefCounted = _make_grid_with_terrain(Vector2i(1, 0), TerrainTypes.FOREST)
	var plain_damage: int = CombatCalc.calc_damage(attacker, defender, grid, 1.0)
	var forest_damage: int = CombatCalc.calc_damage(attacker, defender, forest_grid, 1.0)
	checks.assert_true(forest_damage <= plain_damage, "forest effective def reduces damage.")

	var skill_damage: int = CombatCalc.calc_damage(attacker, defender, grid, 1.3)
	checks.assert_true(skill_damage >= plain_damage, "skill mult increases damage.")

	var sword_attacker: RefCounted = _make_unit(10, 10, "sword", Vector2i(0, 0))
	var axe_defender: RefCounted = _make_unit(10, 5, "axe", Vector2i(1, 0))
	var neutral_defender: RefCounted = _make_unit(10, 5, "none", Vector2i(1, 0))
	var counter_damage: int = CombatCalc.calc_damage(sword_attacker, axe_defender, grid, 1.0)
	var neutral_damage: int = CombatCalc.calc_damage(sword_attacker, neutral_defender, grid, 1.0)
	checks.assert_true(counter_damage > neutral_damage, "weapon multiplier is applied.")
	checks.assert_equal(
		WeaponTriangle.get_multiplier("sword", "axe"),
		1.2,
		"sanity: sword vs axe multiplier."
	)
	quit(checks.finish())

func _make_plain_grid() -> RefCounted:
	var rows: Array = []
	for y in 5:
		var row: Array = []
		for x in 5:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	return Grid.from_template({"width": 5, "height": 5, "terrain": rows, "deploy_zones": {}})

func _make_grid_with_terrain(pos: Vector2i, terrain: int) -> RefCounted:
	var grid: RefCounted = _make_plain_grid()
	grid.terrain[pos.y][pos.x] = terrain
	return grid

func _make_unit(atk: int, def: int, weapon: String, grid_pos: Vector2i, unit_type: String = "foot") -> RefCounted:
	var unit: RefCounted = (load("res://scripts/battle/battle_unit.gd") as GDScript).new()
	unit.unit_id = "TEST"
	unit.template_id = "TEST"
	unit.is_player = true
	unit.grid_pos = grid_pos
	unit.atk = atk
	unit.def = def
	unit.weapon = weapon
	unit.unit_type = unit_type
	unit.hp = 20
	unit.max_hp = 20
	unit.mov = 4
	unit.skill_id = ""
	return unit
