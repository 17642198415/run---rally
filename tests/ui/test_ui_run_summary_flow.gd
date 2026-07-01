extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const MAIN_MENU: String = "res://scenes/main_menu.tscn"
const RUN_SUMMARY: String = "res://scenes/roguelike/run_summary.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.setup_run_summary_context(true, false)
	harness.change_scene(RUN_SUMMARY)
	await harness.await_idle()

	var title: Label = harness.get_current_scene().find_child("TitleLabel", true, false) as Label
	checks.assert_true(title != null and "通关" in title.text, "victory summary title")

	harness.press_button(harness.find_button(harness.get_current_scene(), "MenuBtn"), "MenuBtn")
	await harness.await_idle()
	harness.assert_current_scene(MAIN_MENU, "run summary back to main menu")

	var rm: Node = get_root().get_node("RunManager")
	checks.assert_true(rm.get_state() == null, "run cleared after summary menu")

	quit(checks.finish())
