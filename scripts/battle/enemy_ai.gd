extends RefCounted

const BattleController = preload("res://scripts/battle/battle_controller.gd")
const AttackRange = preload("res://scripts/battle/attack_range.gd")
const Pathfinding = preload("res://scripts/battle/pathfinding.gd")

static func decide_action(enemy: RefCounted, grid: RefCounted, units: Array, ai_profile: String = "") -> Dictionary:
	if enemy == null or grid == null:
		return {"action": "wait"}

	var skill_action: Dictionary = _try_skill_attack(enemy, grid, units, ai_profile)
	if not skill_action.is_empty():
		return skill_action

	var attack_action: Dictionary = _try_basic_attack(enemy, grid, units)
	if not attack_action.is_empty():
		return attack_action

	var move_action: Dictionary = _try_move_toward_player(enemy, grid, units)
	if not move_action.is_empty():
		return move_action

	return {"action": "wait"}

static func _try_skill_attack(enemy: RefCounted, grid: RefCounted, units: Array, ai_profile: String) -> Dictionary:
	if not BattleController.can_use_skill(enemy):
		return {}
	if ai_profile == "boss_default":
		var max_hp: int = int(enemy.max_hp)
		if max_hp > 0 and float(enemy.hp) / float(max_hp) >= 0.5:
			return {}
	var skill: Dictionary = _get_skill_for_unit(enemy)
	if skill.is_empty():
		return {}
	var skill_range: Dictionary = AttackRange.get_skill_range(skill)
	var cells: Array[Vector2i] = AttackRange.get_attack_targets(
		grid,
		enemy.grid_pos,
		int(skill_range.min),
		int(skill_range.max)
	)
	var target: RefCounted = _pick_lowest_hp_player_on_cells(units, cells, enemy)
	if target == null:
		return {}
	return {"action": "skill", "target_unit": target, "target_cell": target.grid_pos}

static func _try_basic_attack(enemy: RefCounted, grid: RefCounted, units: Array) -> Dictionary:
	var atk_range: Dictionary = AttackRange.get_basic_attack_range(enemy)
	var cells: Array[Vector2i] = AttackRange.get_attack_targets(
		grid,
		enemy.grid_pos,
		int(atk_range.min),
		int(atk_range.max)
	)
	var target: RefCounted = _pick_lowest_hp_player_on_cells(units, cells, enemy)
	if target == null:
		return {}
	return {"action": "attack", "target_unit": target, "target_cell": target.grid_pos}

static func _try_move_toward_player(enemy: RefCounted, grid: RefCounted, units: Array) -> Dictionary:
	var nearest: RefCounted = _nearest_player(enemy, units)
	if nearest == null:
		return {}
	var reachable: Array[Vector2i] = Pathfinding.get_reachable(
		grid,
		enemy.grid_pos,
		int(enemy.mov),
		String(enemy.unit_type),
		String(enemy.unit_id)
	)
	if reachable.is_empty():
		return {}

	var best_cell: Vector2i = enemy.grid_pos
	var best_dist: int = _manhattan(enemy.grid_pos, nearest.grid_pos)
	for cell in reachable:
		var dist: int = _manhattan(cell, nearest.grid_pos)
		if dist < best_dist:
			best_dist = dist
			best_cell = cell
	if best_cell == enemy.grid_pos:
		return {}
	return {"action": "move", "target_cell": best_cell}

static func _pick_lowest_hp_player_on_cells(units: Array, cells: Array[Vector2i], attacker: RefCounted) -> RefCounted:
	var cell_set: Dictionary = {}
	for cell in cells:
		cell_set[cell] = true
	var best: RefCounted = null
	for unit in units:
		if not BattleController.is_alive(unit):
			continue
		if not unit.is_player:
			continue
		if not cell_set.has(unit.grid_pos):
			continue
		if best == null:
			best = unit
			continue
		if int(unit.hp) < int(best.hp):
			best = unit
		elif int(unit.hp) == int(best.hp):
			var dist_new: int = _manhattan(attacker.grid_pos, unit.grid_pos)
			var dist_old: int = _manhattan(attacker.grid_pos, best.grid_pos)
			if dist_new < dist_old:
				best = unit
	return best

static func _nearest_player(enemy: RefCounted, units: Array) -> RefCounted:
	var best: RefCounted = null
	var best_dist: int = 999999
	for unit in units:
		if not BattleController.is_alive(unit):
			continue
		if not unit.is_player:
			continue
		var dist: int = _manhattan(enemy.grid_pos, unit.grid_pos)
		if dist < best_dist:
			best_dist = dist
			best = unit
	return best

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

static func _get_skill_for_unit(unit: RefCounted) -> Dictionary:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return {}
	var loader: Node = tree.root.get_node_or_null("DataLoader")
	if loader == null:
		return {}
	var skill_id: String = String(unit.skill_id)
	if skill_id.is_empty():
		return {}
	return loader.get_skill(skill_id) as Dictionary
