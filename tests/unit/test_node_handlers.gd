extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const NodeHandlers = preload("res://scripts/roguelike/node_handlers.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.reset()

	_test_rest_path()
	_test_shop_path()
	_test_battle_prepare()
	_test_capture_event_bonus()
	_test_elite_prepare()
	_test_boss_prepare()
	_test_event_data_files()

	gs.reset()
	quit(checks.finish())

func _test_rest_path() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var path: String = NodeHandlers.enter_node("rest", "L2N0", 2, rng)
	checks.assert_equal(path, "res://scenes/roguelike/rest.tscn", "rest returns rest scene.")
	var gs: Node = get_root().get_node("GameState")
	var pending: Dictionary = gs.pending_event_node as Dictionary
	checks.assert_equal(String(pending.get("run_node_id", "")), "L2N0", "pending node id set.")

func _test_shop_path() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var path: String = NodeHandlers.enter_node("shop", "L3N1", 3, rng)
	checks.assert_equal(path, "res://scenes/roguelike/shop.tscn", "shop returns shop scene.")

func _test_battle_prepare() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var path: String = NodeHandlers.enter_node("battle", "L1N1", 1, rng)
	checks.assert_equal(path, "res://scenes/campaign/party_setup.tscn", "battle returns party setup.")
	var ctx: Dictionary = gs.battle_context as Dictionary
	checks.assert_equal(String(ctx.get("run_node_id", "")), "L1N1", "battle context node id.")
	checks.assert_equal((ctx.get("enemies", []) as Array).size() > 0, true, "battle has enemies.")

func _test_capture_event_bonus() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var path: String = NodeHandlers.enter_node("capture_event", "L4N0", 4, rng)
	checks.assert_equal(path, "res://scenes/campaign/party_setup.tscn", "capture returns party setup.")
	var ctx: Dictionary = gs.battle_context as Dictionary
	checks.assert_equal(float(ctx.get("capture_event_bonus", 0.0)), 0.35, "capture bonus set.")

func _test_elite_prepare() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var path: String = NodeHandlers.enter_node("elite", "L3N0", 3, rng)
	checks.assert_equal(path, "res://scenes/campaign/party_setup.tscn", "elite returns party setup.")
	var ctx: Dictionary = gs.battle_context as Dictionary
	checks.assert_equal(bool(ctx.get("is_elite", false)), true, "elite flag set.")
	checks.assert_equal(bool(ctx.get("is_boss", true)), false, "elite is not boss.")

func _test_boss_prepare() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var path: String = NodeHandlers.enter_node("boss", "L6N0", 6, rng)
	checks.assert_equal(path, "res://scenes/campaign/party_setup.tscn", "boss returns party setup.")
	var ctx: Dictionary = gs.battle_context as Dictionary
	checks.assert_equal(bool(ctx.get("is_boss", false)), true, "boss flag set.")

func _test_event_data_files() -> void:
	checks.assert_true(
		FileAccess.file_exists("res://data/enemy_groups/capture_event.json"),
		"capture_event.json exists."
	)
	checks.assert_true(
		FileAccess.file_exists("res://data/route/shop_catalog.json"),
		"shop_catalog.json exists."
	)
	var file := FileAccess.open("res://data/enemy_groups/capture_event.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	checks.assert_equal(typeof(parsed), TYPE_DICTIONARY, "capture_event parses.")
	var groups: Array = (parsed as Dictionary).get("groups", []) as Array
	checks.assert_true(groups.size() > 0, "capture_event has groups.")
	var first: Dictionary = groups[0] as Dictionary
	checks.assert_true((first.get("enemies", []) as Array).size() > 0, "capture group has enemies.")
	checks.assert_true(not String(first.get("map_template", "")).is_empty(), "capture group has map.")
