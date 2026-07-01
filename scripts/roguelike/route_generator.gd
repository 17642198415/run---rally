static func generate(seed: int, rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.seed = seed
	else:
		rng.seed = seed

	var config: Dictionary = _load_layer_config()
	if config.is_empty():
		push_error("RouteGenerator: Could not load layer_pools.json")
		return _default_graph()

	return _generate_with_config(config, rng)

static func _load_layer_config() -> Dictionary:
	var path := "res://data/route/layer_pools.json"
	if not FileAccess.file_exists(path):
		push_error("RouteGenerator: layer_pools.json not found at %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary

static func _generate_with_config(config: Dictionary, rng: RandomNumberGenerator) -> Array:
	var layers_data: Array = config.get("layers", []) as Array
	if layers_data.size() != 6:
		push_error("RouteGenerator: Expected 6 layers in config, got %d" % layers_data.size())
		return _default_graph()

	const MAX_RETRIES: int = 32
	for attempt in range(MAX_RETRIES + 1):
		var graph: Array = _build_graph(layers_data, rng)
		if attempt < MAX_RETRIES:
			if _check_constraint(graph):
				return graph
		else:
			_graph_force_promote(graph)
			return graph
		rng.seed = rng.seed + 1

	return _default_graph()

static func _build_graph(layers_data: Array, rng: RandomNumberGenerator) -> Array:
	var graph: Array = []
	for layer_idx in range(layers_data.size()):
		var ld: Dictionary = layers_data[layer_idx] as Dictionary
		var pool: Array = ld.get("pool", []) as Array
		var pick_count: int = int(ld.get("pick_count", 1))
		var layer_nodes: Array = _pick_nodes(pool, pick_count, rng, layer_idx + 1)
		graph.append({
			"layer": layer_idx + 1,
			"nodes": layer_nodes
		})
	return graph

static func _pick_nodes(pool: Array, pick_count: int, rng: RandomNumberGenerator, layer_num: int) -> Array:
	var copy: Array = pool.duplicate()
	var picked: Array = []
	var actual_pick: int = mini(pick_count, copy.size())
	for i in range(actual_pick):
		var idx: int = rng.randi_range(0, copy.size() - 1)
		var node_type: String = String(copy[idx])
		copy.remove_at(idx)
		picked.append({
			"id": "L%dN%d" % [layer_num, i],
			"type": node_type
		})
	return picked

static func _check_constraint(graph: Array) -> bool:
	var l3: Dictionary = graph[2] as Dictionary
	var l5: Dictionary = graph[4] as Dictionary
	for nd in (l3.get("nodes", []) as Array):
		var t: String = String((nd as Dictionary).get("type", ""))
		if t == "elite" or t == "shop":
			return true
	for nd in (l5.get("nodes", []) as Array):
		var t: String = String((nd as Dictionary).get("type", ""))
		if t == "elite" or t == "shop":
			return true
	return false

static func _graph_force_promote(graph: Array) -> void:
	push_warning("RouteGenerator: Constraint not met after retries. Force-promoting layer 3 node 0 to elite.")
	var l3: Dictionary = graph[2] as Dictionary
	var nodes: Array = l3.get("nodes", []) as Array
	if nodes.size() > 0:
		(nodes[0] as Dictionary)["type"] = "elite"

static func _default_graph() -> Array:
	var graph: Array = []
	for layer in range(1, 7):
		var node_type: String = "battle" if layer < 6 else "boss"
		graph.append({
			"layer": layer,
			"nodes": [{ "id": "L%dN0" % layer, "type": node_type }]
		})
	return graph