extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const BattleUnit = preload("res://scripts/battle/battle_unit.gd")
const BattleController = preload("res://scripts/battle/battle_controller.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var grid: RefCounted = _make_plain_grid()
	var attacker: RefCounted = _make_unit(true, 10, 5, Vector2i(0, 0))
	var defender: RefCounted = _make_unit(false, 5, 2, Vector2i(1, 0))
	defender.tags = ["boss"]  # 非野生（boss）才会按 hp<=0 直接移除，野生改为 downed_capturable，由第 5 章接管
	var units: Array = [attacker, defender]

	var damage: int = BattleController.perform_attack(attacker, defender, grid)
	checks.assert_true(damage >= 1, "attack deals damage.")
	checks.assert_true(defender.hp < defender.max_hp, "defender hp reduced.")

	defender.hp = 1
	BattleController.apply_damage(defender, 5)
	checks.assert_true(BattleController.is_dead(defender), "hp <= 0 is dead.")
	var removed: bool = BattleController.remove_dead_unit(units, defender, grid)
	checks.assert_true(removed, "dead unit removed from list.")
	checks.assert_equal(units.size(), 1, "only attacker remains.")

	checks.assert_equal(BattleController.check_victory(units), "player", "all enemies dead is player win.")

	var enemy_only: Array = [_make_unit(false, 5, 2, Vector2i(1, 0))]
	(enemy_only[0] as RefCounted).tags = ["boss"]
	checks.assert_equal(BattleController.check_victory(enemy_only), "enemy", "no player units is enemy win.")

	var both: Array = [
		_make_unit(true, 5, 2, Vector2i(0, 0)),
		_make_unit(false, 5, 2, Vector2i(1, 0))
	]
	(both[1] as RefCounted).tags = ["boss"]
	checks.assert_equal(BattleController.check_victory(both), "none", "both sides alive is none.")

	var skill_user: RefCounted = _make_unit(true, 10, 3, Vector2i(0, 0))
	skill_user.skill_id = "S_FIRE_CLAW"
	var skill_target: RefCounted = _make_unit(false, 5, 2, Vector2i(1, 0))
	var skill: Dictionary = {
		"id": "S_FIRE_CLAW",
		"mult": 1.3,
		"cooldown": 2,
		"range": 1
	}
	var skill_damage: int = BattleController.perform_skill(skill_user, skill_target, grid, skill)
	checks.assert_true(skill_damage >= 1, "skill deals damage.")
	checks.assert_equal(skill_user.skill_cooldown_left, 2, "skill enters cooldown.")
	checks.assert_true(not BattleController.can_use_skill(skill_user), "skill blocked during cooldown.")

	BattleController.tick_cooldown(skill_user)
	checks.assert_equal(skill_user.skill_cooldown_left, 1, "wait ticks cooldown.")
	quit(checks.finish())

func _make_plain_grid() -> RefCounted:
	var rows: Array = []
	for y in 5:
		var row: Array = []
		for x in 5:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	return Grid.from_template({"width": 5, "height": 5, "terrain": rows, "deploy_zones": {}})

func _make_unit(is_player: bool, atk: int, def: int, grid_pos: Vector2i) -> RefCounted:
	var unit: RefCounted = (load("res://scripts/battle/battle_unit.gd") as GDScript).new()
	unit.unit_id = "U_%d_%d" % [grid_pos.x, grid_pos.y]
	unit.template_id = "TEST"
	unit.is_player = is_player
	unit.grid_pos = grid_pos
	unit.atk = atk
	unit.def = def
	unit.weapon = "none"
	unit.unit_type = "foot"
	unit.hp = 20
	unit.max_hp = 20
	unit.mov = 4
	unit.skill_id = ""
	return unit
