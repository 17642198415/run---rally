extends RefCounted

const CombatCalc = preload("res://scripts/battle/combat_calc.gd")

static func perform_attack(attacker: RefCounted, defender: RefCounted, grid: RefCounted) -> int:
	var damage: int = CombatCalc.calc_damage(attacker, defender, grid, 1.0)
	apply_damage(defender, damage)
	return damage

static func perform_skill(attacker: RefCounted, defender: RefCounted, grid: RefCounted, skill: Dictionary) -> int:
	var mult: float = float(skill.get("mult", 1.0))
	var cooldown: int = int(skill.get("cooldown", 0))
	var damage: int = CombatCalc.calc_damage(attacker, defender, grid, mult)
	apply_damage(defender, damage)
	attacker.skill_cooldown_left = cooldown
	return damage

static func apply_damage(target: RefCounted, damage: int) -> void:
	target.hp = maxi(0, int(target.hp) - damage)
	if int(target.hp) <= 0 and target.has_method("is_wild") and target.is_wild():
		target.downed_capturable = true

static func is_dead(unit: RefCounted) -> bool:
	return int(unit.hp) <= 0

static func is_alive(unit: RefCounted) -> bool:
	if unit.has_method("is_alive_for_battle"):
		return unit.is_alive_for_battle()
	return not is_dead(unit)

static func is_capturable_downed(unit: RefCounted) -> bool:
	return bool(unit.get("downed_capturable")) and not unit.is_player

static func can_use_skill(unit: RefCounted) -> bool:
	return int(unit.skill_cooldown_left) <= 0 and not String(unit.skill_id).is_empty()

static func tick_cooldown(unit: RefCounted) -> void:
	if int(unit.skill_cooldown_left) > 0:
		unit.skill_cooldown_left = int(unit.skill_cooldown_left) - 1

static func remove_dead_unit(units: Array, unit: RefCounted, grid: RefCounted) -> bool:
	if int(unit.hp) > 0:
		return false
	if bool(unit.get("downed_capturable")):
		return false
	grid.clear_occupant(unit.grid_pos)
	var idx: int = units.find(unit)
	if idx >= 0:
		units.remove_at(idx)
	return true

static func remove_unit(units: Array, unit: RefCounted, grid: RefCounted) -> void:
	grid.clear_occupant(unit.grid_pos)
	var idx: int = units.find(unit)
	if idx >= 0:
		units.remove_at(idx)

static func check_victory(units: Array) -> String:
	var player_alive: bool = false
	var enemy_alive: bool = false
	for unit in units:
		if not is_alive(unit):
			continue
		if unit.is_player:
			player_alive = true
		else:
			enemy_alive = true
	if player_alive and not enemy_alive:
		return "player"
	if enemy_alive and not player_alive:
		return "enemy"
	return "none"
