extends RefCounted

static func get_basic_attack_range(unit: RefCounted) -> Dictionary:
	if String(unit.unit_type) == "flying":
		return {"min": 2, "max": 2}
	return {"min": 1, "max": 1}

static func get_attack_targets(grid: RefCounted, origin: Vector2i, min_dist: int, max_dist: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in grid.height:
		for x in grid.width:
			var pos: Vector2i = Vector2i(x, y)
			if pos == origin:
				continue
			var dist: int = absi(pos.x - origin.x) + absi(pos.y - origin.y)
			if dist >= min_dist and dist <= max_dist:
				result.append(pos)
	return result

static func get_skill_range(skill: Dictionary) -> Dictionary:
	var range_value: int = int(skill.get("range", 1))
	if range_value <= 0:
		range_value = 1
	return {"min": 1, "max": range_value}

static func is_in_range(origin: Vector2i, target: Vector2i, min_dist: int, max_dist: int) -> bool:
	var dist: int = absi(target.x - origin.x) + absi(target.y - origin.y)
	return dist >= min_dist and dist <= max_dist
