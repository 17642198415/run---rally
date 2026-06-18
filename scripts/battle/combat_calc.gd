extends RefCounted

const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const WeaponTriangle = preload("res://scripts/battle/weapon_triangle.gd")

static func calc_damage(attacker: RefCounted, defender: RefCounted, grid: RefCounted, skill_mult: float = 1.0) -> int:
	var terrain: int = grid.get_terrain(defender.grid_pos)
	var effective_def: int = int(defender.def) + TerrainTypes.get_def_bonus(terrain)
	var base: int = maxi(0, int(attacker.atk) - effective_def)
	var weapon_mult: float = WeaponTriangle.get_multiplier(String(attacker.weapon), String(defender.weapon))
	var raw: float = float(base) * weapon_mult * skill_mult
	return maxi(1, int(raw))
