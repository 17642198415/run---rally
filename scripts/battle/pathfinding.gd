extends RefCounted

const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")

const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]

static func get_reachable(grid: RefCounted, start: Vector2i, mov: int, unit_type: String, mover_id: String = "") -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if grid == null or mov <= 0:
		return result
	if not grid.in_bounds(start):
		return result

	var cost_so_far: Dictionary = {}
	cost_so_far[start] = 0
	var frontier: Array[Vector2i] = [start]

	while frontier.size() > 0:
		var current: Vector2i = frontier.pop_front()
		var current_cost: int = int(cost_so_far[current])
		for delta in NEIGHBORS:
			var nxt: Vector2i = current + delta
			if not grid.in_bounds(nxt):
				continue
			if not grid.is_walkable(nxt, unit_type, mover_id):
				continue
			var step_cost: int = 1 + TerrainTypes.get_move_cost_extra(grid.get_terrain(nxt))
			var new_cost: int = current_cost + step_cost
			if new_cost > mov:
				continue
			if cost_so_far.has(nxt) and int(cost_so_far[nxt]) <= new_cost:
				continue
			cost_so_far[nxt] = new_cost
			frontier.append(nxt)

	for cell in cost_so_far.keys():
		var pos: Vector2i = cell
		if pos != start:
			result.append(pos)
	return result

static func find_path(grid: RefCounted, start: Vector2i, goal: Vector2i, mov: int, unit_type: String, mover_id: String = "") -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if grid == null or not grid.in_bounds(start) or not grid.in_bounds(goal):
		return empty
	if start == goal:
		return [start]
	if not grid.is_walkable(goal, unit_type, mover_id):
		return empty

	var cost_so_far: Dictionary = {}
	var came_from: Dictionary = {}
	cost_so_far[start] = 0
	var frontier: Array[Vector2i] = [start]

	while frontier.size() > 0:
		var current: Vector2i = frontier.pop_front()
		var current_cost: int = int(cost_so_far[current])
		for delta in NEIGHBORS:
			var nxt: Vector2i = current + delta
			if not grid.in_bounds(nxt):
				continue
			if not grid.is_walkable(nxt, unit_type, mover_id):
				continue
			var step_cost: int = 1 + TerrainTypes.get_move_cost_extra(grid.get_terrain(nxt))
			var new_cost: int = current_cost + step_cost
			if new_cost > mov:
				continue
			if cost_so_far.has(nxt) and int(cost_so_far[nxt]) <= new_cost:
				continue
			cost_so_far[nxt] = new_cost
			came_from[nxt] = current
			frontier.append(nxt)

	if not cost_so_far.has(goal):
		return empty

	var path: Array[Vector2i] = []
	var node: Vector2i = goal
	while node != start:
		path.push_front(node)
		node = came_from[node]
	path.push_front(start)
	return path
