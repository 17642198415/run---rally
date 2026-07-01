extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const MetaManagerScript = preload("res://scripts/autoload/meta_manager.gd")

const TEST_PATH: String = "user://test_meta_manager.json"

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var save_mgr: Node = get_root().get_node("SaveManager")
	var original_path: String = save_mgr.get_save_path()
	save_mgr.set_save_path(TEST_PATH)
	_cleanup()

	var mm: Node = get_root().get_node("MetaManager")
	mm.reset()
	mm.load_definitions()

	_test_load_definitions()
	_test_meta_ball_unlock_by_win()
	_test_meta_ball_unlock_by_layer()
	_test_meta_m05_bestiary()
	_test_pool_extras_and_balls_bonus()
	_test_to_dict_round_trip()

	_cleanup()
	save_mgr.set_save_path(original_path)
	quit(checks.finish())

func _test_load_definitions() -> void:
	var mm: Node = get_root().get_node("MetaManager")
	var defs: Array = mm.get_definitions()
	checks.assert_equal(defs.size(), 3, "meta_unlocks has 3 definitions.")

func _test_meta_ball_unlock_by_win() -> void:
	var mm: Node = get_root().get_node("MetaManager")
	mm.reset()
	var snapshot: Dictionary = {
		"stats": MetaManagerScript.normalize_stats({"runs_won": 1}),
		"bestiary": {}
	}
	var newly: Array = mm.evaluate_unlocks(snapshot)
	checks.assert_equal(newly.size(), 1, "META_BALL unlocks on first win.")
	checks.assert_equal(String(newly[0]), "META_BALL", "new unlock id META_BALL.")
	checks.assert_true(mm.is_unlocked("META_BALL"), "META_BALL is unlocked.")

func _test_meta_ball_unlock_by_layer() -> void:
	var mm: Node = get_root().get_node("MetaManager")
	mm.reset()
	var snapshot: Dictionary = {
		"stats": MetaManagerScript.normalize_stats({"deepest_layer": 5, "runs_won": 0}),
		"bestiary": {}
	}
	var newly: Array = mm.evaluate_unlocks(snapshot)
	checks.assert_true(mm.is_unlocked("META_BALL"), "META_BALL unlocks at layer 5 without win.")

func _test_meta_m05_bestiary() -> void:
	var mm: Node = get_root().get_node("MetaManager")
	mm.reset()
	var snapshot: Dictionary = {
		"stats": MetaManagerScript.normalize_stats({}),
		"bestiary": {"M05": {"discovered": true, "caught": false}}
	}
	mm.evaluate_unlocks(snapshot)
	checks.assert_true(mm.is_unlocked("META_M05"), "META_M05 unlocks when M05 discovered.")

func _test_pool_extras_and_balls_bonus() -> void:
	var mm: Node = get_root().get_node("MetaManager")
	mm.set_unlocked(["META_BALL", "META_M05"])
	checks.assert_equal(mm.get_start_balls_bonus(), 1, "META_BALL gives +1 ball.")
	var extras: Array = mm.get_pool_extras()
	checks.assert_true(extras.has("M05"), "pool extras contains M05.")

func _test_to_dict_round_trip() -> void:
	var mm: Node = get_root().get_node("MetaManager")
	mm.set_unlocked(["META_M08"])
	var data: Dictionary = mm.to_dict()
	var mm2: Node = MetaManagerScript.new()
	mm2.from_dict(data)
	checks.assert_true(mm2.is_unlocked("META_M08"), "to_dict/from_dict preserves unlocks.")
	mm2.free()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
