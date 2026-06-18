extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TurnManager = preload("res://scripts/battle/turn_manager.gd")
const BattleController = preload("res://scripts/battle/battle_controller.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var tm: RefCounted = TurnManager.new()
	checks.assert_equal(tm.current_phase, TurnManager.TurnPhase.DEPLOY, "starts in DEPLOY.")

	var units: Array = [
		_make_unit("P1", true, Vector2i(0, 4)),
		_make_unit("E1", false, Vector2i(9, 4))
	]
	tm.confirm_deploy(units)
	checks.assert_equal(tm.current_phase, TurnManager.TurnPhase.PLAYER_TURN, "confirm deploy enters player turn.")
	checks.assert_equal(tm.round_number, 1, "round starts at 1.")
	checks.assert_equal(String(tm.active_unit.unit_id), "P1", "first player is active.")

	tm.mark_unit_acted(tm.active_unit)
	checks.assert_equal(tm.active_unit, null, "no more players after single unit acted.")

	tm.end_player_turn()
	checks.assert_equal(tm.current_phase, TurnManager.TurnPhase.ENEMY_TURN, "end turn enters enemy turn.")
	checks.assert_equal(String(tm.active_unit.unit_id), "E1", "first enemy is active.")

	checks.assert_true(not tm.advance_enemy_after_action(), "no more enemies after one acts.")
	tm.finish_enemy_turn(units)
	checks.assert_equal(tm.current_phase, TurnManager.TurnPhase.PLAYER_TURN, "enemy turn done returns to player.")
	checks.assert_equal(tm.round_number, 2, "round increments.")

	units[1] = _make_unit("E1", false, Vector2i(9, 4))
	units[1].hp = 0
	tm.build_queues(units)
	checks.assert_true(tm.check_battle_end(units), "all enemies dead ends battle.")
	checks.assert_equal(tm.current_phase, TurnManager.TurnPhase.BATTLE_END, "victory sets BATTLE_END.")

	quit(checks.finish())

func _make_unit(unit_id: String, is_player: bool, pos: Vector2i) -> RefCounted:
	var unit: RefCounted = (load("res://scripts/battle/battle_unit.gd") as GDScript).new()
	unit.unit_id = unit_id
	unit.is_player = is_player
	unit.grid_pos = pos
	unit.hp = 10
	unit.max_hp = 10
	unit.mov = 4
	unit.unit_type = "foot"
	return unit
