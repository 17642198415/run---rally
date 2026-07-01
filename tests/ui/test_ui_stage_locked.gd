extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const STAGE_SELECT: String = "res://scenes/campaign/stage_select.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.setup_campaign_stage_status({
		"stage_01": "unlocked",
		"stage_02": "locked",
		"stage_03": "locked"
	})
	harness.change_scene(STAGE_SELECT)
	await harness.await_idle()

	var stage_list: Node = harness.get_current_scene().find_child("StageList", true, false)
	checks.assert_true(stage_list != null and stage_list.get_child_count() >= 2, "stage list has cards")
	var locked_card: Node = stage_list.get_child(1)
	checks.assert_true(not _has_button(locked_card), "locked stage_02 has no enter button")
	harness.assert_current_scene(STAGE_SELECT, "locked stage_02 stays on stage select")

	quit(checks.finish())

func _has_button(node: Node) -> bool:
	if node is Button:
		return true
	for child in node.get_children():
		if _has_button(child):
			return true
	return false
