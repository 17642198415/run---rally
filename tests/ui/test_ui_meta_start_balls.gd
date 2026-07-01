extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const ROUTE_MAP: String = "res://scenes/roguelike/route_map.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.setup_meta_unlocked(["META_BALL"] as Array[String])
	var mm: Node = get_root().get_node("MetaManager")
	checks.assert_equal(int(mm.get_start_balls_bonus()), 1, "META_BALL bonus")

	harness.setup_active_run(77)
	harness.change_scene(ROUTE_MAP)
	await harness.await_idle(5)

	var balls_label: Label = harness.get_current_scene().find_child("BallsLabel", true, false) as Label
	checks.assert_true(balls_label != null, "BallsLabel exists")
	if balls_label != null:
		checks.assert_equal(balls_label.text, "捕获球：4", "R6 META_BALL shows 4 balls")

	quit(checks.finish())
