extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
var checks := Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	var unit_ids: Array[String] = loader.get_all_unit_ids()
	var monster_ids: Array[String] = []
	for uid in unit_ids:
		if String(uid).begins_with("M"):
			monster_ids.append(String(uid))
	checks.assert_equal(monster_ids.size(), 8, "loads exactly 8 monster units (M01-M08).")
	checks.assert_true(monster_ids.has("M01"), "loaded unit ids include M01.")
	checks.assert_true(unit_ids.has("BOSS_MERC"), "campaign BOSS_MERC also loaded.")

	var fire_fox: Dictionary = loader.get_unit("M01")
	checks.assert_equal(fire_fox.get("name"), "火尾狐", "M01 has the expected display name.")
	checks.assert_equal(fire_fox.get("skill_id"), "S_FIRE_CLAW", "M01 references S_FIRE_CLAW.")

	var hero: Dictionary = loader.get_hero()
	checks.assert_equal(hero.get("id"), "HERO", "hero id is HERO.")
	checks.assert_equal(hero.get("skill_id"), "S_INSPIRE", "hero references S_INSPIRE.")

	var expected_skills: Array[String] = [
		"S_FIRE_CLAW",
		"S_ROCK_SHELL",
		"S_GUST",
		"S_INSPIRE",
		"S_AQUA_BITE",
		"S_THUNDER_CHARGE",
		"S_LEAF_SLASH",
		"S_SHADOW_DIVE",
		"S_DRAGON_BREATH",
		"S_BERSERK"
	]
	for skill_id in expected_skills:
		var skill: Dictionary = loader.get_skill(skill_id)
		checks.assert_equal(skill.get("id"), skill_id, "skill %s loads by id." % skill_id)

	for unit_id in unit_ids:
		var unit: Dictionary = loader.get_unit(unit_id)
		var skill_id: String = unit.get("skill_id", "")
		if skill_id.is_empty():
			continue
		checks.assert_true(not loader.get_skill(skill_id).is_empty(), "unit %s references an existing skill." % unit_id)

	quit(checks.finish())
