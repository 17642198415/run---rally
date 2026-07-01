extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const BattleUnit = preload("res://scripts/battle/battle_unit.gd")
const CaptureSystem = preload("res://scripts/battle/capture_system.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	_test_compute_rate_monotonic()
	_test_tier_thresholds()
	_test_attempt_success_failure_no_balls()
	_test_clamp_bounds()
	_test_event_bonus_increases_rate()
	_test_capture_event_context_bonus()

	quit(checks.finish())

func _test_compute_rate_monotonic() -> void:
	var fox: RefCounted = BattleUnit.from_template("M01", false, Vector2i(0, 0), "E_M01")
	var rate_full: float = CaptureSystem.compute_rate(fox, 0.0)
	fox.hp = 0
	fox.downed_capturable = true
	var rate_downed: float = CaptureSystem.compute_rate(fox, 0.0)
	checks.assert_true(rate_downed > rate_full, "downed unit yields strictly higher rate than full hp.")

func _test_tier_thresholds() -> void:
	checks.assert_equal(CaptureSystem.tier_for_rate(0.50), CaptureSystem.TIER_HIGH, "0.50 maps to high tier.")
	checks.assert_equal(CaptureSystem.tier_for_rate(0.30), CaptureSystem.TIER_MID, "0.30 maps to mid tier.")
	checks.assert_equal(CaptureSystem.tier_for_rate(0.20), CaptureSystem.TIER_LOW, "0.20 maps to low tier.")
	checks.assert_equal(CaptureSystem.tier_for_rate(0.10), CaptureSystem.TIER_VLOW, "0.10 maps to vlow tier.")
	checks.assert_equal(CaptureSystem.tier_for_rate(0.499), CaptureSystem.TIER_MID, "just below 0.5 stays mid.")

func _test_attempt_success_failure_no_balls() -> void:
	var fox: RefCounted = BattleUnit.from_template("M01", false, Vector2i(0, 0), "E_M01")
	fox.hp = 0
	fox.downed_capturable = true

	var success_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	success_rng.seed = 1
	# 调到稳定低 roll (seed 1 第一发 randf 在多数实现下 < 0.5)，配合 downed M01 base 0.45 -> rate 0.45 命中可观察。
	# 这里通过预热抽掉前几个不利 roll 找到稳定点：
	var stable_roll: float = -1.0
	for i in range(20):
		var rng_probe: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_probe.seed = i + 1
		var v: float = rng_probe.randf()
		if v < 0.30:
			stable_roll = v
			success_rng.seed = i + 1
			break
	checks.assert_true(stable_roll >= 0.0, "found a low-roll seed for success branch.")

	var success_result: Dictionary = CaptureSystem.attempt(fox, 3, 0.0, success_rng)
	checks.assert_true(bool(success_result.get("success", false)), "low roll captures successfully.")
	checks.assert_equal(int(success_result.get("balls_remaining_after", -1)), 2, "ball deducted on success.")

	var fail_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	fail_rng.seed = 0
	var high_seed: int = -1
	for i in range(20):
		var rng_probe2: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_probe2.seed = i + 1
		var v2: float = rng_probe2.randf()
		if v2 > 0.95:
			high_seed = i + 1
			break
	checks.assert_true(high_seed > 0, "found a high-roll seed for failure branch.")
	fail_rng.seed = high_seed
	var fail_result: Dictionary = CaptureSystem.attempt(fox, 3, 0.0, fail_rng)
	checks.assert_true(not bool(fail_result.get("success", false)), "high roll fails capture.")
	checks.assert_equal(int(fail_result.get("balls_remaining_after", -1)), 2, "ball still deducted on failure.")

	var none_result: Dictionary = CaptureSystem.attempt(fox, 0, 0.0, success_rng)
	checks.assert_true(not bool(none_result.get("success", false)), "no balls -> not success.")
	checks.assert_equal(int(none_result.get("balls_remaining_after", -1)), 0, "no balls keeps 0.")
	checks.assert_equal(String(none_result.get("error", "")), "no_balls", "no balls error code returned.")

func _test_clamp_bounds() -> void:
	var fox: RefCounted = BattleUnit.from_template("M01", false, Vector2i(0, 0), "E_M01")
	fox.hp = 0
	fox.downed_capturable = true
	var huge: float = CaptureSystem.compute_rate(fox, 10.0)
	checks.assert_true(huge <= 0.95 + 0.0001, "rate clamped to 0.95 max.")

	fox.base_capture_rate = 0.0
	fox.hp = fox.max_hp
	var tiny: float = CaptureSystem.compute_rate(fox, -1.0)
	checks.assert_true(tiny >= 0.05 - 0.0001, "rate clamped to 0.05 min.")

func _test_event_bonus_increases_rate() -> void:
	var fox: RefCounted = BattleUnit.from_template("M01", false, Vector2i(0, 0), "E_M01")
	fox.hp = fox.max_hp
	var rate_base: float = CaptureSystem.compute_rate(fox, 0.0)
	var rate_event: float = CaptureSystem.compute_rate(fox, 0.35)
	checks.assert_true(rate_event > rate_base, "capture event bonus raises rate.")
	checks.assert_equal(rate_event - rate_base, 0.35, "bonus adds flat 0.35 before clamp.")

func _test_capture_event_context_bonus() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.reset()
	gs.prepare_roguelike_node("L4N0", [], "T_PLAIN", false, false, 0.35)
	var bonus: float = _event_bonus_from_game_state(gs)
	checks.assert_equal(bonus, 0.35, "roguelike context exposes capture_event_bonus.")
	var fox: RefCounted = BattleUnit.from_template("M01", false, Vector2i(0, 0), "E_M01")
	fox.hp = 0
	fox.downed_capturable = true
	var rate: float = CaptureSystem.compute_rate(fox, bonus)
	var rate_default: float = CaptureSystem.compute_rate(fox, 0.0)
	checks.assert_true(rate > rate_default, "context bonus used in rate calculation.")
	gs.reset()

func _event_bonus_from_game_state(gs: Node) -> float:
	if int(gs.current_mode) != int(gs.GameMode.ROGUELIKE):
		return 0.0
	var ctx: Dictionary = gs.battle_context as Dictionary
	if ctx.has("capture_event_bonus"):
		return float(ctx.get("capture_event_bonus", 0.0))
	return 0.0
