extends RefCounted

const TIER_HIGH: String = "high"
const TIER_MID: String = "mid"
const TIER_LOW: String = "low"
const TIER_VLOW: String = "vlow"

const TIER_THRESHOLDS: Dictionary = {
	TIER_HIGH: 0.50,
	TIER_MID: 0.25,
	TIER_LOW: 0.12
}

const RATE_MIN: float = 0.05
const RATE_MAX: float = 0.95

static func compute_rate(unit: RefCounted, event_bonus: float = 0.0) -> float:
	if unit == null:
		return RATE_MIN
	var max_hp: float = float(maxi(1, int(unit.max_hp)))
	var hp_ratio: float = clampf(float(unit.hp) / max_hp, 0.0, 1.0)
	var hp_factor: float = 1.0 - hp_ratio
	var base: float = float(unit.get("base_capture_rate"))
	var rate: float = base * (0.5 + 0.5 * hp_factor) + event_bonus
	return clampf(rate, RATE_MIN, RATE_MAX)

static func tier_for_rate(rate: float) -> String:
	if rate >= TIER_THRESHOLDS[TIER_HIGH]:
		return TIER_HIGH
	if rate >= TIER_THRESHOLDS[TIER_MID]:
		return TIER_MID
	if rate >= TIER_THRESHOLDS[TIER_LOW]:
		return TIER_LOW
	return TIER_VLOW

static func attempt(unit: RefCounted, balls_remaining: int, event_bonus: float, rng: RandomNumberGenerator) -> Dictionary:
	var rate: float = compute_rate(unit, event_bonus)
	var tier: String = tier_for_rate(rate)
	if balls_remaining <= 0:
		return {
			"success": false,
			"rate": rate,
			"tier": tier,
			"balls_remaining_after": 0,
			"error": "no_balls"
		}
	var roll: float = 0.0
	if rng != null:
		roll = rng.randf()
	else:
		roll = randf()
	var success: bool = roll < rate
	return {
		"success": success,
		"rate": rate,
		"tier": tier,
		"balls_remaining_after": balls_remaining - 1
	}
