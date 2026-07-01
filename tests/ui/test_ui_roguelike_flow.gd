extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const MAIN_MENU: String = "res://scenes/main_menu.tscn"
const ROUTE_MAP: String = "res://scenes/roguelike/route_map.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.change_scene(MAIN_MENU)
	await harness.await_idle()

	harness.press_button(harness.find_button(harness.get_current_scene(), "RoguelikeBtn"), "RoguelikeBtn")
	await harness.await_idle(5)
	harness.assert_current_scene(ROUTE_MAP, "roguelike opens route_map")
	checks.assert_true(
		harness.get_current_scene().find_child("RouteLayers", true, false) != null,
		"route_map shows RouteLayers"
	)
	harness.assert_new_run_roster()

	harness.press_button(harness.find_button(harness.get_current_scene(), "BackBtn"), "BackBtn")
	await harness.await_idle()
	harness.assert_current_scene(MAIN_MENU, "route_map back to main_menu")

	quit(checks.finish())
