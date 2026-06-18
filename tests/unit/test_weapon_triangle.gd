extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const WeaponTriangle = preload("res://scripts/battle/weapon_triangle.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	checks.assert_equal(WeaponTriangle.get_multiplier("sword", "axe"), 1.2, "sword counters axe.")
	checks.assert_equal(WeaponTriangle.get_multiplier("axe", "sword"), 0.8, "axe is weak to sword.")
	checks.assert_equal(WeaponTriangle.get_multiplier("axe", "spear"), 1.2, "axe counters spear.")
	checks.assert_equal(WeaponTriangle.get_multiplier("spear", "axe"), 0.8, "spear is weak to axe.")
	checks.assert_equal(WeaponTriangle.get_multiplier("spear", "sword"), 1.2, "spear counters sword.")
	checks.assert_equal(WeaponTriangle.get_multiplier("sword", "spear"), 0.8, "sword is weak to spear.")
	checks.assert_equal(WeaponTriangle.get_multiplier("none", "sword"), 1.0, "none attacker is neutral.")
	checks.assert_equal(WeaponTriangle.get_multiplier("sword", "none"), 1.0, "none defender is neutral.")
	checks.assert_equal(WeaponTriangle.get_multiplier("sword", "sword"), 1.0, "same weapon is neutral.")
	quit(checks.finish())
