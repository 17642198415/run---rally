extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RouteGenerator = preload("res://scripts/roguelike/route_generator.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	_test_same_seed_identical()
	_test_diff_seeds_different()
	_test_layer_6_always_boss()
	_test_constraint_100_seeds()
	_test_node_id_format()
	quit(checks.finish())

func _test_same_seed_identical() -> void:
	var graph1: Array = RouteGenerator.generate(42)
	var graph2: Array = RouteGenerator.generate(42)
	checks.assert_equal(graph1.size(), 6, "6 layers for seed 42.")
	checks.assert_equal(graph2.size(), 6, "6 layers for seed 42 duplicate.")
	for layer_idx in range(6):
		var l1: Dictionary = graph1[layer_idx] as Dictionary
		var l2: Dictionary = graph2[layer_idx] as Dictionary
		checks.assert_equal(l1.get("layer", -1), l2.get("layer", -1), "layer number match for seed 42.")
		var n1: Array = l1.get("nodes", []) as Array
		var n2: Array = l2.get("nodes", []) as Array
		checks.assert_equal(n1.size(), n2.size(), "node count match for layer %d." % [layer_idx])
		for ni in range(n1.size()):
			var nd1: Dictionary = n1[ni] as Dictionary
			var nd2: Dictionary = n2[ni] as Dictionary
			checks.assert_equal(nd1.get("type", ""), nd2.get("type", ""), "node type match layer %d idx %d." % [layer_idx, ni])

func _test_diff_seeds_different() -> void:
	var different_count: int = 0
	for i in range(50):
		var g1: Array = RouteGenerator.generate(i)
		var g2: Array = RouteGenerator.generate(i + 1000)
		var same: bool = true
		for layer_idx in range(6):
			var l1: Dictionary = g1[layer_idx] as Dictionary
			var l2: Dictionary = g2[layer_idx] as Dictionary
			var n1: Array = l1.get("nodes", []) as Array
			var n2: Array = l2.get("nodes", []) as Array
			if n1.size() != n2.size():
				same = false
				break
			for ni in range(n1.size()):
				var nd1: Dictionary = n1[ni] as Dictionary
				var nd2: Dictionary = n2[ni] as Dictionary
				if nd1.get("type", "") != nd2.get("type", ""):
					same = false
					break
			if not same:
				break
		if not same:
			different_count += 1
	checks.assert_true(different_count >= 45, "At least 45/50 seed pairs differ. Got %d." % [different_count])

func _test_layer_6_always_boss() -> void:
	for s in range(100):
		var graph: Array = RouteGenerator.generate(s)
		var l6: Dictionary = graph[5] as Dictionary
		var nodes: Array = l6.get("nodes", []) as Array
		checks.assert_equal(nodes.size(), 1, "Layer 6 has exactly 1 node. Seed %d." % [s])
		var nd: Dictionary = nodes[0] as Dictionary
		checks.assert_equal(nd.get("type", ""), "boss", "Layer 6 node is boss. Seed %d." % [s])

func _test_constraint_100_seeds() -> void:
	for s in range(100):
		var graph: Array = RouteGenerator.generate(s)
		var l3: Dictionary = graph[2] as Dictionary
		var l5: Dictionary = graph[4] as Dictionary
		var has_elite_or_shop: bool = false
		for nd in (l3.get("nodes", []) as Array):
			var t: String = String((nd as Dictionary).get("type", ""))
			if t == "elite" or t == "shop":
				has_elite_or_shop = true
				break
		if not has_elite_or_shop:
			for nd in (l5.get("nodes", []) as Array):
				var t: String = String((nd as Dictionary).get("type", ""))
				if t == "elite" or t == "shop":
					has_elite_or_shop = true
					break
		checks.assert_true(has_elite_or_shop, "Layer 3 or 5 has elite/shop. Seed %d." % [s])

func _test_node_id_format() -> void:
	var graph: Array = RouteGenerator.generate(77)
	for layer_idx in range(6):
		var l: Dictionary = graph[layer_idx] as Dictionary
		for nd in (l.get("nodes", []) as Array):
			var nid: String = String((nd as Dictionary).get("id", ""))
			var expected_prefix: String = "L%dN" % (layer_idx + 1)
			checks.assert_true(nid.begins_with(expected_prefix), "Node ID starts with layer prefix. Got %s." % [nid])