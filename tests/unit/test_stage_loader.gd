extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	var stage: Dictionary = loader.get_stage("DEBUG_01")
	checks.assert_equal(String(stage.get("id", "")), "DEBUG_01", "DEBUG_01 stage loads.")
	checks.assert_equal(String(stage.get("map_template", "")), "test_grid", "stage references test_grid.")

	var player_units: Array = stage.get("player_units", [])
	checks.assert_true(player_units.size() >= 1, "stage has player units.")
	var hero_entry: Dictionary = player_units[0] as Dictionary
	checks.assert_equal(String(hero_entry.get("template", "")), "HERO", "player template is HERO.")
	checks.assert_true(not loader.get_hero().is_empty(), "HERO data exists.")

	var enemy_units: Array = stage.get("enemy_units", [])
	for entry_variant in enemy_units:
		var entry: Dictionary = entry_variant as Dictionary
		var template_id: String = String(entry.get("template", ""))
		checks.assert_true(not loader.get_unit(template_id).is_empty(), "enemy template %s exists." % template_id)

	var grid: RefCounted = loader.load_stage_map(stage)
	checks.assert_true(grid != null, "stage map loads.")
	checks.assert_equal(grid.width, 10, "stage map width is 10.")

	# Chapter 6: campaign stages
	for stage_id in ["stage_01", "stage_02", "stage_03"]:
		var st: Dictionary = loader.get_stage(stage_id)
		checks.assert_equal(String(st.get("id", "")), stage_id, "%s stage loads." % stage_id)
		var player_block: Dictionary = st.get("player", {}) as Dictionary
		checks.assert_equal(
			String(player_block.get("party_source", "")),
			"campaign_setup",
			"%s uses campaign_setup party source." % stage_id
		)
		var st_grid: RefCounted = loader.load_stage_map(st)
		checks.assert_true(st_grid != null, "%s map template loads." % stage_id)
		checks.assert_equal(int(st_grid.width), 10, "%s grid width is 10." % stage_id)
		var enemies: Array = st.get("enemy_units", [])
		checks.assert_true(enemies.size() >= 1, "%s has at least one enemy." % stage_id)
		for entry_v in enemies:
			var entry: Dictionary = entry_v as Dictionary
			var tid: String = String(entry.get("template", ""))
			checks.assert_true(not loader.get_unit(tid).is_empty(), "%s enemy template %s loads." % [stage_id, tid])

	var boss: Dictionary = loader.get_unit("BOSS_MERC")
	checks.assert_true(not boss.is_empty(), "BOSS_MERC data loads.")
	var boss_tags: Array = boss.get("tags", []) as Array
	checks.assert_true(boss_tags.has("boss"), "BOSS_MERC has boss tag.")

	quit(checks.finish())
