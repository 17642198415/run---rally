extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.reset()

	_test_prepare_roguelike_node()
	_test_prepare_capture_event_bonus()
	_test_start_roguelike_battle()

	gs.reset()
	quit(checks.finish())

func _test_prepare_roguelike_node() -> void:
	var gs: Node = get_root().get_node("GameState")
	var enemies: Array = [{"template": "M01", "spawn": {"x": 7, "y": 3}}]
	gs.prepare_roguelike_node("L2N1", enemies, "T_PLAIN", false, false)
	checks.assert_equal(int(gs.current_mode), int(gs.GameMode.ROGUELIKE), "prepare sets ROGUELIKE mode.")
	var ctx: Dictionary = gs.battle_context as Dictionary
	checks.assert_equal(String(ctx.get("run_node_id", "")), "L2N1", "run_node_id set.")
	checks.assert_equal(String(ctx.get("map_template", "")), "T_PLAIN", "map_template set.")
	checks.assert_equal(bool(ctx.get("is_elite", true)), false, "is_elite set.")
	checks.assert_equal(bool(ctx.get("is_boss", true)), false, "is_boss set.")
	checks.assert_equal((ctx.get("enemies", []) as Array).size(), 1, "enemies set.")
	checks.assert_equal(ctx.has("deploy_list"), false, "prepare does not set deploy_list.")
	checks.assert_equal(
		String(gs.return_scene_path),
		"res://scenes/roguelike/route_map.tscn",
		"return_scene_path is route map."
	)

func _test_prepare_capture_event_bonus() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.prepare_roguelike_node("L4N0", [], "T_PLAIN", false, false, 0.35)
	var ctx: Dictionary = gs.battle_context as Dictionary
	checks.assert_equal(float(ctx.get("capture_event_bonus", 0.0)), 0.35, "capture bonus in context.")

func _test_start_roguelike_battle() -> void:
	var gs: Node = get_root().get_node("GameState")
	var enemies: Array = [{"template": "M02", "spawn": {"x": 8, "y": 4}}]
	var deploy_list: Array = [{
		"template_id": "HERO",
		"unit_id": "P_HERO",
		"hp": 20,
		"max_hp": 20
	}]
	gs.start_roguelike_battle("L3N2", enemies, "T_FOREST", true, false, deploy_list)
	checks.assert_equal(int(gs.current_mode), int(gs.GameMode.ROGUELIKE), "start sets ROGUELIKE mode.")
	var ctx: Dictionary = gs.battle_context as Dictionary
	checks.assert_equal(String(ctx.get("run_node_id", "")), "L3N2", "run_node_id set.")
	checks.assert_equal(String(ctx.get("map_template", "")), "T_FOREST", "map_template set.")
	checks.assert_equal(bool(ctx.get("is_elite", false)), true, "is_elite true.")
	checks.assert_equal(bool(ctx.get("is_boss", true)), false, "is_boss false.")
	checks.assert_equal((ctx.get("deploy_list", []) as Array).size(), 1, "deploy_list set.")
	checks.assert_equal(
		String(gs.return_scene_path),
		"res://scenes/roguelike/route_map.tscn",
		"return_scene_path is route map."
	)
