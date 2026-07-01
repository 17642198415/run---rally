extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const BATTLE: String = "res://scenes/battle/battle.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()

	var gs: Node = get_root().get_node("GameState")
	gs.start_campaign_battle("stage_01", [{
		"unit_id": "P_HERO",
		"template_id": "HERO",
		"hp": 0,
		"max_hp": 0
	}])
	harness.change_scene(BATTLE)
	await harness.await_idle(5)

	var scene: Node = harness.get_current_scene()
	checks.assert_true(scene != null, "battle scene loaded")
	checks.assert_true(scene.find_child("GridController", true, false) != null, "GridController exists")
	checks.assert_true(scene.find_child("ActionBar", true, false) != null, "ActionBar HUD exists")
	checks.assert_true(scene.find_child("TurnBanner", true, false) != null, "TurnBanner HUD exists")
	checks.assert_equal(int(gs.current_battle_phase), int(gs.BattlePhase.DEPLOY), "battle starts in DEPLOY")

	quit(checks.finish())
