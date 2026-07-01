extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const ShopCatalog = preload("res://scripts/roguelike/shop_catalog.gd")
const RunManagerScript = preload("res://scripts/autoload/run_manager.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	_test_same_seed_same_items()
	_test_roll_three_items()
	_test_catalog_has_weights()
	_test_different_seeds_can_differ()
	_test_shop_visit_seed_reproducible()
	_test_apply_add_ball()
	_test_apply_heal_all_pct()
	_test_apply_add_random_reserve()
	_test_try_purchase_insufficient_coins()
	_test_try_purchase_success_deducts_coins()
	_test_try_purchase_refunds_on_apply_failure()
	_test_can_apply_blocks_full_reserve()
	quit(checks.finish())

func _test_same_seed_same_items() -> void:
	var a: Array = ShopCatalog.roll_3(4242)
	var b: Array = ShopCatalog.roll_3(4242)
	checks.assert_equal(a.size(), b.size(), "same seed same count.")
	for i in range(a.size()):
		checks.assert_equal(
			String((a[i] as Dictionary).get("id", "")),
			String((b[i] as Dictionary).get("id", "")),
			"same seed same item id at index %d" % i
		)

func _test_roll_three_items() -> void:
	var items: Array = ShopCatalog.roll_3(99)
	checks.assert_equal(items.size(), 3, "rolls exactly 3 items.")

func _test_catalog_has_weights() -> void:
	var items: Array = ShopCatalog.roll_3(1)
	for entry_v in items:
		var entry: Dictionary = entry_v as Dictionary
		checks.assert_true(int(entry.get("weight", 0)) > 0, "item has positive weight.")
		checks.assert_true(int(entry.get("cost", -1)) >= 0, "item has cost.")

func _test_different_seeds_can_differ() -> void:
	var a: Array = ShopCatalog.roll_3(1)
	var b: Array = ShopCatalog.roll_3(99999)
	var same: bool = true
	if a.size() == b.size():
		for i in range(a.size()):
			if String((a[i] as Dictionary).get("id", "")) != String((b[i] as Dictionary).get("id", "")):
				same = false
				break
	else:
		same = false
	checks.assert_equal(same, false, "different seeds should differ in item order or ids.")

func _test_shop_visit_seed_reproducible() -> void:
	var node_id: String = "L3N2"
	var layer: int = 3
	var run_seed: int = 4242
	var roll_seed: int = run_seed + layer * 1009 + node_id.hash()
	var first: Array = ShopCatalog.roll_3(roll_seed)
	var second: Array = ShopCatalog.roll_3(roll_seed)
	checks.assert_equal(first.size(), second.size(), "visit seed same count.")
	for i in range(first.size()):
		checks.assert_equal(
			String((first[i] as Dictionary).get("id", "")),
			String((second[i] as Dictionary).get("id", "")),
			"visit seed same item at %d" % i
		)

func _make_rm() -> Node:
	var rm: Node = RunManagerScript.new()
	get_root().add_child(rm)
	rm.start_new_run(77)
	return rm

func _hero_max_hp(loader: Node) -> int:
	var hero: Dictionary = loader.get_hero()
	return int((hero.get("stats", {}) as Dictionary).get("hp", 25))

func _test_apply_add_ball() -> void:
	var rm: Node = _make_rm()
	var state: Resource = rm.get_state()
	state.balls = 2
	var item: Dictionary = {"effect_type": "add_ball", "effect_value": 1}
	var ok: bool = ShopCatalog.apply_item(item, state, rm, "L3N1", 25, null)
	checks.assert_equal(ok, true, "add_ball applies.")
	checks.assert_equal(int(state.balls), 3, "balls increased.")
	rm.queue_free()

func _test_apply_heal_all_pct() -> void:
	var rm: Node = _make_rm()
	var state: Resource = rm.get_state()
	state.party = [{
		"unit_id": "P_HERO",
		"template_id": "HERO",
		"hp": 10,
		"max_hp": 20,
		"skill_id": ""
	}]
	var loader: Node = get_root().get_node("DataLoader")
	var item: Dictionary = {"effect_type": "heal_all_pct", "effect_value": 20}
	var ok: bool = ShopCatalog.apply_item(item, state, rm, "L3N1", _hero_max_hp(loader), loader)
	checks.assert_equal(ok, true, "heal_all_pct applies.")
	checks.assert_equal(int((state.party[0] as Dictionary).get("hp", 0)), 14, "party healed 20 percent.")
	rm.queue_free()

func _test_apply_add_random_reserve() -> void:
	var rm: Node = _make_rm()
	var state: Resource = rm.get_state()
	state.seed = 100
	var loader: Node = get_root().get_node("DataLoader")
	var node_id: String = "L3N2"
	var item: Dictionary = {
		"effect_type": "add_random_reserve",
		"templates": ["M01", "M02", "M03", "M04"]
	}
	var before: int = (state.reserve as Array).size()
	var ok: bool = ShopCatalog.apply_item(item, state, rm, node_id, 25, loader)
	checks.assert_equal(ok, true, "add_random_reserve applies.")
	checks.assert_equal((state.reserve as Array).size(), before + 1, "reserve grows by one.")
	var added: Dictionary = (state.reserve as Array)[before] as Dictionary
	var template_id: String = String(added.get("template_id", ""))
	checks.assert_true(
		(["M01", "M02", "M03", "M04"] as Array).has(template_id),
		"recruited template from catalog list."
	)
	rm.queue_free()

func _test_try_purchase_insufficient_coins() -> void:
	var rm: Node = _make_rm()
	var state: Resource = rm.get_state()
	state.coins = 5
	var loader: Node = get_root().get_node("DataLoader")
	var item: Dictionary = {"effect_type": "add_ball", "effect_value": 1, "cost": 15}
	var result: Dictionary = ShopCatalog.try_purchase(item, state, rm, "L3N1", 25, loader)
	checks.assert_equal(bool(result.get("ok", true)), false, "insufficient coins rejected.")
	checks.assert_equal(String(result.get("reason", "")), "insufficient_coins", "insufficient reason.")
	checks.assert_equal(int(state.coins), 5, "coins unchanged on reject.")
	rm.queue_free()

func _test_try_purchase_success_deducts_coins() -> void:
	var rm: Node = _make_rm()
	var state: Resource = rm.get_state()
	state.coins = 20
	state.balls = 1
	var loader: Node = get_root().get_node("DataLoader")
	var item: Dictionary = {
		"id": "ball_pack",
		"effect_type": "add_ball",
		"effect_value": 1,
		"cost": 15
	}
	var result: Dictionary = ShopCatalog.try_purchase(item, state, rm, "L3N1", 25, loader)
	checks.assert_equal(bool(result.get("ok", false)), true, "purchase succeeds.")
	checks.assert_equal(int(state.coins), 5, "coins deducted.")
	checks.assert_equal(int(state.balls), 2, "ball granted.")
	rm.queue_free()

func _test_try_purchase_refunds_on_apply_failure() -> void:
	var rm: Node = _make_rm()
	var state: Resource = rm.get_state()
	state.coins = 30
	var loader: Node = get_root().get_node("DataLoader")
	var item: Dictionary = {
		"effect_type": "add_random_reserve",
		"cost": 25,
		"templates": []
	}
	var result: Dictionary = ShopCatalog.try_purchase(item, state, rm, "L3N1", 25, loader)
	checks.assert_equal(bool(result.get("ok", true)), false, "empty templates fails.")
	checks.assert_equal(String(result.get("reason", "")), "apply_failed", "apply_failed reason.")
	checks.assert_equal(int(state.coins), 30, "coins refunded.")
	rm.queue_free()

func _test_can_apply_blocks_full_reserve() -> void:
	var item: Dictionary = {"effect_type": "add_random_reserve"}
	checks.assert_equal(ShopCatalog.can_apply_item(item, 8), false, "full reserve blocks recruit.")
	checks.assert_equal(ShopCatalog.can_apply_item(item, 7), true, "room for one more recruit.")
