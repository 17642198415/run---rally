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
	harness.assert_current_scene(BESTIARY, "bestiary opens")

	var scene: Node = harness.get_current_scene()
	var species_panel: Node = scene.find_child("SpeciesPanel", true, false)
	var unlock_panel: Node = scene.find_child("UnlockPanel", true, false)
	checks.assert_true(species_panel != null and species_panel.visible, "species tab visible")
	checks.assert_true(unlock_panel != null and not unlock_panel.visible, "unlock tab hidden initially")

	harness.press_button(harness.find_button(scene, "UnlockTabBtn"), "UnlockTabBtn")
	await harness.await_idle()
	checks.assert_true(not species_panel.visible, "species hidden after tab switch")
	checks.assert_true(unlock_panel.visible, "unlock visible after tab switch")

	harness.press_button(harness.find_button(scene, "SpeciesTabBtn"), "SpeciesTabBtn")
	await harness.await_idle()
	checks.assert_true(species_panel.visible, "species visible again")
	checks.assert_true(not unlock_panel.visible, "unlock hidden again")

	quit(checks.finish())
