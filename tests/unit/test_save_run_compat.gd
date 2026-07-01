extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")

const TEST_PATH: String = "user://test_save_run_compat.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	var original_path: String = save_mgr.get_save_path()
	save_mgr.set_save_path(TEST_PATH)
	_cleanup()

	# Test 1: Fresh default save has run section
	var defaults: Dictionary = save_mgr.get_default_save()
	checks.assert_true(defaults.has("run"), "default has run.")
	var run_section: Dictionary = defaults.get("run", {}) as Dictionary
	checks.assert_true(run_section.has("active"), "default run has active.")
	checks.assert_equal(run_section.get("active", true), false, "default run.active is false.")
	checks.assert_equal(run_section.get("state", "MISSING"), null, "default run.state is null.")

	# Test 2: Legacy save without run key gets merged
	var legacy_save: Dictionary = {"campaign": {"stage_01": "cleared"}}
	var merged: Dictionary = save_mgr.merge_with_defaults(legacy_save)
	checks.assert_true(merged.has("run"), "merge adds run key.")
	var merged_run: Dictionary = merged.get("run", {}) as Dictionary
	checks.assert_equal(merged_run.get("active", true), false, "merged run.active is false.")
	checks.assert_equal(merged_run.get("state", "MISSING"), null, "merged run.state is null.")
	checks.assert_equal(merged.get("campaign", {}), {"stage_01": "cleared"}, "merge preserves existing data.")

	# Test 3: Stats exists (already pre-existing, just confirm)
	checks.assert_true(defaults.has("stats"), "default has stats.")

	# Test 4: load_meta on a file with partial data includes run
	var partial: Dictionary = {"bestiary": {}}
	save_mgr.save_meta(partial)
	var loaded: Dictionary = save_mgr.load_meta()
	checks.assert_true(loaded.has("run"), "load_meta adds run key for old file.")
	var loaded_run: Dictionary = loaded.get("run", {}) as Dictionary
	checks.assert_equal(loaded_run.get("active", true), false, "loaded run.active is false for old file.")

	_cleanup()
	save_mgr.set_save_path(original_path)
	quit(checks.finish())

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))