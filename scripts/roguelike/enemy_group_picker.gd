static func pick(
	layer: int,
	is_elite: bool,
	is_boss: bool,
	rng: RandomNumberGenerator,
	pool_extras: Array = []
) -> Dictionary:
	var file_path: String = _resolve_file_path(layer, is_elite, is_boss)
	if file_path.is_empty():
		push_error("EnemyGroupPicker: No file mapping for layer=%d is_elite=%s is_boss=%s" % [layer, str(is_elite), str(is_boss)])
		return _empty_group()
	if not FileAccess.file_exists(file_path):
		push_error("EnemyGroupPicker: File not found: %s" % file_path)
		return _empty_group()

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("EnemyGroupPicker: Cannot open %s" % file_path)
		return _empty_group()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("EnemyGroupPicker: Invalid JSON at %s" % file_path)
		return _empty_group()
	var data: Dictionary = parsed as Dictionary
	var groups: Array = data.get("groups", []) as Array
	if groups.is_empty():
		push_error("EnemyGroupPicker: No groups in %s" % file_path)
		return _empty_group()

	var picked: Dictionary = _pick_weighted(groups, rng)
	if is_boss or layer < 3 or pool_extras.is_empty():
		return picked
	return _inject_pool_extras(picked, pool_extras, rng)

static func inject_pool_extras(
	group: Dictionary,
	pool_extras: Array,
	rng: RandomNumberGenerator
) -> Dictionary:
	if pool_extras.is_empty():
		return group
	return _inject_pool_extras(group, pool_extras, rng)

static func _inject_pool_extras(
	group: Dictionary,
	pool_extras: Array,
	rng: RandomNumberGenerator
) -> Dictionary:
	var enemies: Array = (group.get("enemies", []) as Array).duplicate(true)
	if enemies.is_empty():
		return group.duplicate(true)
	var replace_index: int = rng.randi_range(0, enemies.size() - 1)
	var extra_index: int = rng.randi_range(0, pool_extras.size() - 1)
	var replacement: Dictionary = (enemies[replace_index] as Dictionary).duplicate(true)
	replacement["template"] = String(pool_extras[extra_index])
	enemies[replace_index] = replacement
	var out: Dictionary = group.duplicate(true)
	out["enemies"] = enemies
	return out

static func _resolve_file_path(layer: int, is_elite: bool, is_boss: bool) -> String:
	if is_boss:
		return "res://data/enemy_groups/layer_6_boss.json"
	if is_elite:
		if layer == 3 or layer == 4:
			return "res://data/enemy_groups/layer_3_4_elite.json"
		if layer == 5:
			return "res://data/enemy_groups/layer_5_elite.json"
		return ""
	if layer == 1 or layer == 2:
		return "res://data/enemy_groups/layer_1_2_normal.json"
	if layer == 3 or layer == 4:
		return "res://data/enemy_groups/layer_3_4_normal.json"
	if layer == 5:
		return "res://data/enemy_groups/layer_5_normal.json"
	return ""

static func _pick_weighted(groups: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total: float = 0.0
	for g in groups:
		total += float((g as Dictionary).get("weight", 0))
	if total <= 0.0:
		return (groups[0] as Dictionary).duplicate(true)

	var roll: float = rng.randf_range(0.0, total)
	var cumulative: float = 0.0
	for g in groups:
		cumulative += float((g as Dictionary).get("weight", 0))
		if roll <= cumulative:
			return (g as Dictionary).duplicate(true)
	return (groups[groups.size() - 1] as Dictionary).duplicate(true)

static func _empty_group() -> Dictionary:
	return {
		"map_template": "",
		"enemies": []
	}
