extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")

const TEST_PATH: String = "user://test_save_meta_chapter5.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	var original_path: String = save_mgr.get_save_path()
	save_mgr.set_save_path(TEST_PATH)
	_cleanup()

	var defaults: Dictionary = save_mgr.get_default_save()
	checks.assert_true(defaults.has("bestiary"), "default has bestiary.")
	checks.assert_true(defaults.has("party"), "default has party.")
	checks.assert_true(defaults.has("stats"), "default has stats.")
	checks.assert_true(defaults.has("campaign"), "default has campaign.")
	checks.assert_true(defaults.has("meta"), "default has meta.")
	var party: Dictionary = defaults.get("party", {}) as Dictionary
	checks.assert_true(party.has("reserve"), "default party has reserve.")

	var initial: Dictionary = save_mgr.load_meta()
	checks.assert_true(initial.has("bestiary"), "fresh load returns defaults with bestiary.")
	checks.assert_true((initial.get("party", {}) as Dictionary).has("reserve"), "fresh load fills party.reserve.")

	var data: Dictionary = save_mgr.get_default_save()
	(data["bestiary"] as Dictionary)["M01"] = {"discovered": true, "caught": true}
	(data["party"] as Dictionary)["reserve"] = [{
		"unit_id": "P_M01_001",
		"template_id": "M01",
		"hp": 18,
		"max_hp": 18,
		"skill_id": "S_FIRE_CLAW"
	}]
	checks.assert_true(save_mgr.save_meta(data), "save_meta returns true.")

	var loaded: Dictionary = save_mgr.load_meta()
	checks.assert_true((loaded["bestiary"] as Dictionary).has("M01"), "loaded bestiary contains M01.")
	checks.assert_equal(
		bool(((loaded["bestiary"] as Dictionary)["M01"] as Dictionary).get("caught", false)),
		true,
		"M01 caught persisted."
	)
	var reserve_loaded: Array = (loaded["party"] as Dictionary).get("reserve", []) as Array
	checks.assert_equal(reserve_loaded.size(), 1, "reserve has one entry after round trip.")
	checks.assert_equal(
		String((reserve_loaded[0] as Dictionary).get("template_id", "")),
		"M01",
		"reserve entry template_id preserved."
	)

	var partial: Dictionary = {"bestiary": {"M02": {"discovered": true, "caught": false}}}
	checks.assert_true(save_mgr.save_meta(partial), "save partial data ok.")
	var merged: Dictionary = save_mgr.load_meta()
	checks.assert_true(merged.has("party"), "missing party defaulted in.")
	checks.assert_true((merged.get("party", {}) as Dictionary).has("reserve"), "party.reserve defaulted in.")
	checks.assert_true(merged.has("meta"), "missing meta defaulted in.")
	checks.assert_true((merged.get("meta", {}) as Dictionary).has("unlocked"), "meta.unlocked defaulted in.")

	_cleanup()
	save_mgr.set_save_path(original_path)
	quit(checks.finish())

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
