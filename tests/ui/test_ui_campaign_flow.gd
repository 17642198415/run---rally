extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const MAIN_MENU: String = "res://scenes/main_menu.tscn"
const STAGE_SELECT: String = "res://scenes/campaign/stage_select.tscn"
const PARTY_SETUP: String = "res://scenes/campaign/party_setup.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.change_scene(MAIN_MENU)
	await harness.await_idle()

	harness.press_button(harness.find_button(harness.get_current_scene(), "CampaignBtn"), "CampaignBtn")
	await harness.await_idle()
	harness.assert_current_scene(STAGE_SELECT, "campaign opens stage_select")

	harness.press_stage_card_by_index(harness.get_current_scene(), 0)
	await harness.await_idle()
	harness.assert_current_scene(PARTY_SETUP, "stage_01 opens party_setup")

	harness.press_button(harness.find_button(harness.get_current_scene(), "BackBtn"), "BackBtn")
	await harness.await_idle()
	harness.assert_current_scene(STAGE_SELECT, "back to stage_select")

	harness.press_button(harness.find_button(harness.get_current_scene(), "BackBtn"), "BackBtn")
	await harness.await_idle()
	harness.assert_current_scene(MAIN_MENU, "back to main_menu")

	quit(checks.finish())
