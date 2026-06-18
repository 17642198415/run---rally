extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const BattleUnit = preload("res://scripts/battle/battle_unit.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	var fox: RefCounted = BattleUnit.from_template("M01", true, Vector2i(1, 4), "P_M01")
	checks.assert_equal(String(fox.unit_id), "P_M01", "custom unit id is preserved.")
	checks.assert_equal(String(fox.template_id), "M01", "template id is M01.")
	checks.assert_equal(String(fox.display_name), "火尾狐", "M01 display name loads from data.")
	checks.assert_equal(int(fox.hp), 18, "M01 hp loads from data.")
	checks.assert_equal(int(fox.atk), 7, "M01 atk loads from data.")
	checks.assert_equal(int(fox.def), 3, "M01 def loads from data.")
	checks.assert_equal(int(fox.mov), 4, "M01 mov loads from data.")
	checks.assert_equal(String(fox.weapon), "none", "M01 weapon loads from data.")
	checks.assert_equal(String(fox.unit_type), "foot", "M01 is foot unit.")
	checks.assert_equal(String(fox.skill_id), "S_FIRE_CLAW", "M01 skill loads from data.")
	checks.assert_true(bool(fox.is_player), "spawned as player unit.")

	var hero: RefCounted = BattleUnit.from_template("HERO", true, Vector2i(0, 4), "P_HERO")
	checks.assert_equal(String(hero.display_name), "旅团新人", "hero display name loads from data.")
	checks.assert_equal(String(hero.weapon), "sword", "hero weapon is sword.")
	checks.assert_equal(int(hero.hp), 25, "hero hp loads from data.")
	checks.assert_equal(String(hero.skill_id), "S_INSPIRE", "hero skill loads from data.")

	var hawk: RefCounted = BattleUnit.from_template("M03", false, Vector2i(8, 3), "E_M03")
	checks.assert_equal(String(hawk.unit_type), "flying", "M03 is flying unit.")
	checks.assert_equal(int(hawk.mov), 5, "M03 mov loads from data.")
	checks.assert_true(not bool(hawk.is_player), "spawned as enemy unit.")

	var auto_id_unit: RefCounted = BattleUnit.from_template("M02", true, Vector2i(2, 2))
	checks.assert_equal(String(auto_id_unit.unit_id), "M02_2_2", "empty unit id uses template_pos fallback.")

	quit(checks.finish())
