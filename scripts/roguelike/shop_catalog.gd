static func roll_3(roll_seed: int, rng: RandomNumberGenerator = null) -> Array:
	var local_rng: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	local_rng.seed = roll_seed
	var catalog: Array = _load_items()
	if catalog.is_empty():
		return []
	var pool: Array = catalog.duplicate()
	var picked: Array = []
	for _i in range(mini(3, pool.size())):
		var index: int = _pick_index(pool, local_rng)
		picked.append((pool[index] as Dictionary).duplicate(true))
		pool.remove_at(index)
	return picked

static func _load_items() -> Array:
	var path: String = "res://data/route/shop_catalog.json"
	if not FileAccess.file_exists(path):
		push_error("ShopCatalog: missing %s" % path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	return (parsed as Dictionary).get("items", []) as Array

static func _pick_index(pool: Array, rng: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for entry_v in pool:
		total += float((entry_v as Dictionary).get("weight", 0))
	if total <= 0.0:
		return 0
	var roll: float = rng.randf_range(0.0, total)
	var cumulative: float = 0.0
	for i in range(pool.size()):
		cumulative += float((pool[i] as Dictionary).get("weight", 0))
		if roll <= cumulative:
			return i
	return pool.size() - 1

static func can_apply_item(item: Dictionary, reserve_size: int) -> bool:
	var effect_type: String = String(item.get("effect_type", ""))
	if effect_type == "add_random_reserve":
		return reserve_size < 8
	return true

static func apply_item(
	item: Dictionary,
	state: Resource,
	rm: Node,
	node_id: String,
	hero_max_hp: int,
	loader: Node
) -> bool:
	var effect_type: String = String(item.get("effect_type", ""))
	match effect_type:
		"add_ball":
			state.balls = int(state.balls) + int(item.get("effect_value", 1))
			return true
		"heal_all_pct":
			var pct: float = float(int(item.get("effect_value", 20))) / 100.0
			state.party = RunState.heal_entries_percent(state.party as Array, pct, hero_max_hp)
			state.reserve = RunState.heal_entries_percent(state.reserve as Array, pct, hero_max_hp)
			return true
		"add_random_reserve":
			var templates: Array = item.get("templates", ["M01"]) as Array
			if templates.is_empty():
				return false
			var rng := RandomNumberGenerator.new()
			rng.seed = int(state.seed) + node_id.hash()
			var template_id: String = String(templates[rng.randi_range(0, templates.size() - 1)])
			if loader == null:
				return false
			var unit: Dictionary = loader.get_unit(template_id)
			var max_hp: int = int((unit.get("stats", {}) as Dictionary).get("hp", 10))
			return rm.add_capture_to_reserve(
				template_id,
				maxi(1, int(max_hp * 0.5)),
				max_hp,
				String(unit.get("skill_id", ""))
			)
	return false

static func try_purchase(
	item: Dictionary,
	state: Resource,
	rm: Node,
	node_id: String,
	hero_max_hp: int,
	loader: Node
) -> Dictionary:
	var cost: int = int(item.get("cost", 0))
	if int(state.coins) < cost:
		return {"ok": false, "reason": "insufficient_coins"}
	var reserve_size: int = (state.reserve as Array).size()
	if not can_apply_item(item, reserve_size):
		return {"ok": false, "reason": "cannot_apply"}
	state.coins = int(state.coins) - cost
	if not apply_item(item, state, rm, node_id, hero_max_hp, loader):
		state.coins = int(state.coins) + cost
		return {"ok": false, "reason": "apply_failed"}
	return {"ok": true, "reason": ""}
