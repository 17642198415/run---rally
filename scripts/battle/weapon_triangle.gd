extends RefCounted

const TRIANGLE: Dictionary = {
	"sword": "axe",
	"axe": "spear",
	"spear": "sword"
}

static func get_multiplier(attacker_weapon: String, defender_weapon: String) -> float:
	if attacker_weapon == "none" or defender_weapon == "none":
		return 1.0
	if attacker_weapon == defender_weapon:
		return 1.0
	if String(TRIANGLE.get(attacker_weapon, "")) == defender_weapon:
		return 1.2
	if String(TRIANGLE.get(defender_weapon, "")) == attacker_weapon:
		return 0.8
	return 1.0
