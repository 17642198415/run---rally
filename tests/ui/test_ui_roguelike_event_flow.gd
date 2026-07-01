extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const ROUTE_MAP: String = "res://scenes/roguelike/route_map.tscn"
const REST: String = "res://scenes/roguelike/rest.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.setup_run_for_node_type("rest")
	harness.change_scene(ROUTE_MAP)
	await harness.await_idle(5)

	harness.press_route_node_on_current_layer("rest")
	await harness.await_idle()
	harness.assert_current_scene(REST, "rest node opens rest scene")

	harness.press_button(harness.find_button(harness.get_current_scene(), "HealBtn"), "HealBtn")
	await harness.await_idle()
	harness.press_button(harness.find_button(harness.get_current_scene(), "LeaveBtn"), "LeaveBtn")
	await harness.await_idle()
	harness.assert_current_scene(ROUTE_MAP, "rest leave returns to route map")

	quit(checks.finish())
