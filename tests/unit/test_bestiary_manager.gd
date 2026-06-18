extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const BestiaryManager = preload("res://scripts/managers/bestiary_manager.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var bm: Node = BestiaryManager.new()
	bm.clear()

	checks.assert_true(not bm.is_discovered("M01"), "M01 starts undiscovered.")

	bm.mark_discovered("M01")
	checks.assert_true(bm.is_discovered("M01"), "M01 becomes discovered.")
	checks.assert_true(not bm.is_caught("M01"), "discovered does not imply caught.")

	bm.mark_caught("M02")
	checks.assert_true(bm.is_discovered("M02"), "caught implies discovered.")
	checks.assert_true(bm.is_caught("M02"), "M02 caught state set.")

	var dict: Dictionary = bm.to_dict()
	checks.assert_true(dict.has("M01"), "to_dict contains M01.")
	checks.assert_true(dict.has("M02"), "to_dict contains M02.")
	checks.assert_equal(bool((dict["M01"] as Dictionary).get("caught", false)), false, "M01 caught is false in dict.")
	checks.assert_equal(bool((dict["M02"] as Dictionary).get("caught", false)), true, "M02 caught is true in dict.")

	var bm2: Node = BestiaryManager.new()
	bm2.clear()
	bm2.from_dict(dict)
	checks.assert_true(bm2.is_caught("M02"), "from_dict round-trips caught.")
	checks.assert_true(bm2.is_discovered("M01"), "from_dict round-trips discovered.")

	bm.free()
	bm2.free()
	quit(checks.finish())
