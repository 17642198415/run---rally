extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const REWARD_PICK: String = "res://scenes/roguelike/reward_pick.tscn"
const ROUTE_MAP: String = "res://scenes/roguelike/route_map.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.setup_active_run(303)
	var rm: Node = get_root().get_node("RunManager")
	rm.consume_battle_result("L3N1", "player", {
		"is_elite": true,
		"is_boss": false,
		"hero_dead": false,
		"balls_remaining": 3,
		"deploy_unit_ids": ["P_HERO"],
		"survivors": [{
			"unit_id": "P_HERO",
			"template_id": "HERO",
			"hp": 20,
			"max_hp": 20,
			"skill_id": ""
		}]
	})
	harness.change_scene(REWARD_PICK)
	await harness.await_idle()

	checks.assert_true(rm.has_pending_rewards(), "pending rewards before pick")
	harness.press_first_reward_card()
	await harness.await_idle()
	checks.assert_equal(rm.get_pending_rewards().size(), 0, "pending cleared after pick")
	harness.assert_current_scene(ROUTE_MAP, "reward pick returns to route map")

	quit(checks.finish())
