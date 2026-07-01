extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const ROUTE_MAP: String = "res://scenes/roguelike/route_map.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	harness.setup_active_run(42)
	harness.change_scene(ROUTE_MAP)
	await harness.await_idle(5)

	var rm: Node = get_root().get_node("RunManager")
	var state: Resource = rm.get_state()
	var graph: Array = state.route_graph as Array
	checks.assert_equal(graph.size(), 6, "R1 six layers")
	var graph_nodes: int = _count_graph_nodes(graph)
	checks.assert_true(graph_nodes >= 8, "R1 at least 8 route nodes got %d" % graph_nodes)
	checks.assert_equal(harness.count_route_map_nodes(), graph_nodes, "UI shows all route nodes")
	checks.assert_true(harness.route_map_has_boss_node(), "R1 layer 6 boss node visible")

	quit(checks.finish())

func _count_graph_nodes(graph: Array) -> int:
	var total: int = 0
	for layer_entry_v in graph:
		total += ((layer_entry_v as Dictionary).get("nodes", []) as Array).size()
	return total
