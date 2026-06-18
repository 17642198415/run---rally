extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const DeployPhase = preload("res://scripts/battle/deploy_phase.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	var grid: RefCounted = _make_grid_with_deploy_zone()
	var stage: Dictionary = {
		"id": "TEST",
		"player_units": [{"template": "HERO", "deploy_index": 0}],
		"enemy_units": [
			{"template": "M01", "spawn": {"x": 8, "y": 4}},
			{"template": "M02", "spawn": {"x": 8, "y": 5}}
		]
	}
	var deploy: RefCounted = DeployPhase.new()
	deploy.setup(stage, grid)

	checks.assert_true(not deploy.can_place_at(Vector2i(5, 5)), "out of deploy zone rejected.")
	checks.assert_true(deploy.can_place_at(Vector2i(0, 4)), "deploy zone cell accepted.")

	var hero: RefCounted = deploy.place_at(Vector2i(0, 4), 0)
	checks.assert_true(hero != null, "HERO placed in zone.")
	checks.assert_true(deploy.can_confirm(), "all templates placed can confirm.")

	checks.assert_true(not deploy.can_place_at(Vector2i(0, 4)), "already occupied deploy cell blocked.")

	var enemies: Array = deploy.spawn_enemies()
	checks.assert_equal(enemies.size(), 2, "two enemies spawned.")
	var e0: RefCounted = enemies[0] as RefCounted
	checks.assert_equal(e0.grid_pos, Vector2i(8, 4), "M01 spawn position.")
	var e1: RefCounted = enemies[1] as RefCounted
	checks.assert_equal(e1.grid_pos, Vector2i(8, 5), "M02 spawn position.")

	# Chapter 6: campaign_setup deploy list comes from GameState.battle_context
	_test_campaign_deploy_list()

	quit(checks.finish())

func _test_campaign_deploy_list() -> void:
	var grid: RefCounted = _make_grid_with_deploy_zone()
	var gs: Node = get_root().get_node("GameState")
	gs.current_mode = gs.GameMode.CAMPAIGN
	gs.battle_context = {
		"deploy_list": [
			{"template_id": "HERO", "unit_id": "P_HERO", "hp": 25, "max_hp": 25},
			{"template_id": "M01", "unit_id": "P_M01_001", "hp": 18, "max_hp": 18}
		]
	}
	var stage: Dictionary = {
		"id": "TEST_CAMPAIGN",
		"player": {"party_source": "campaign_setup"},
		"player_units": [],
		"enemy_units": []
	}
	var deploy: RefCounted = DeployPhase.new()
	deploy.setup(stage, grid)
	checks.assert_equal(deploy.pending_templates.size(), 2, "campaign_setup builds 2 templates from GameState.")

	var hero: RefCounted = deploy.place_at(Vector2i(0, 4), 0)
	checks.assert_true(hero != null, "HERO placed.")
	checks.assert_equal(String(hero.unit_id), "P_HERO", "HERO unit_id from deploy_list preserved.")
	var fox: RefCounted = deploy.place_at(Vector2i(1, 4), 1)
	checks.assert_true(fox != null, "captured M01 placed.")
	checks.assert_equal(String(fox.unit_id), "P_M01_001", "captured unit_id preserved.")
	checks.assert_true(deploy.can_confirm(), "campaign deploy can confirm with both placed.")

	gs.reset()

func _make_grid_with_deploy_zone() -> RefCounted:
	var rows: Array = []
	for y in 10:
		var row: Array = []
		for x in 10:
			row.append(TerrainTypes.PLAIN)
		rows.append(row)
	return Grid.from_template({
		"width": 10,
		"height": 10,
		"terrain": rows,
		"deploy_zones": {
			"player": [Vector2i(0, 4), Vector2i(1, 4)],
			"enemy": [Vector2i(9, 4)]
		}
	})
