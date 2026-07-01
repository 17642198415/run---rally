extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const MAIN_MENU: String = "res://scenes/main_menu.tscn"
const BESTIARY: String = "res://scenes/campaign/bestiary_view.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.change_scene(MAIN_MENU)
	await harness.await_idle()

	harness.press_button(harness.find_button(harness.get_current_scene(), "BestiaryBtn"), "BestiaryBtn")
	await harness.await_idle()
	harness.assert_current_scene(BESTIARY, "bestiary opens from main menu")

	harness.press_button(harness.find_button(harness.get_current_scene(), "BackBtn"), "BackBtn")
	await harness.await_idle()
	harness.assert_current_scene(MAIN_MENU, "bestiary back to main menu")

	quit(checks.finish())
