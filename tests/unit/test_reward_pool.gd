extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RewardPool = preload("res://scripts/roguelike/reward_pool.gd")
const RunStateScript = preload("res://scripts/roguelike/run_state.gd")
const RunManagerScript = preload("res://scripts/autoload/run_manager.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	_test_load_pool()
	_test_pick_three_unique()
	_test_same_seed_same_triple()
	_test_apply_ball()
	_test_apply_heal()
	_test_apply_atk_requires_target()
	_test_apply_rescue()
	_test_boss_bonus_smoke()
	_test_rescue_pool_includes_meta_extra()
	quit(checks.finish())

func _test_load_pool() -> void:
	var pool: Dictionary = RewardPool.load_pool()
	var rewards: Array = pool.get("rewards", []) as Array
	checks.assert_equal(rewards.size(), 7, "reward pool has 7 entries.")
	var bonus: Array = pool.get("boss_weight_bonus", []) as Array
	checks.assert_equal(bonus.size(), 3, "boss_weight_bonus has 3 ids.")

func _test_pick_three_unique() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var picked: Array = RewardPool.pick_three(rng, false)
	checks.assert_equal(picked.size(), 3, "pick_three returns 3 rewards.")
	var ids: Dictionary = {}
	for entry_v in picked:
		var entry: Dictionary = entry_v as Dictionary
		var id: String = String(entry.get("id", ""))
		checks.assert_equal(ids.has(id), false, "reward ids are unique in triple.")
		ids[id] = true

func _test_same_seed_same_triple() -> void:
	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = 777
	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = 777
	var a: Array = RewardPool.pick_three(rng_a, false)
	var b: Array = RewardPool.pick_three(rng_b, false)
	for i in range(a.size()):
		checks.assert_equal(
			String((a[i] as Dictionary).get("id", "")),
			String((b[i] as Dictionary).get("id", "")),
			"same seed same reward id at %d" % i
		)

func _test_apply_ball() -> void:
	var state: Resource = RunStateScript.new()
	state.balls = 3
	var reward: Dictionary = {"id": "R_BALL", "effect": {"balls": 1}}
	var loader: Node = get_root().get_node("DataLoader")
	var ok: bool = RewardPool.apply_reward(state, reward, "", loader)
	checks.assert_equal(ok, true, "R_BALL apply succeeds.")
	checks.assert_equal(int(state.balls), 4, "balls incremented.")

func _test_apply_heal() -> void:
	var state: Resource = RunStateScript.new()
	state.reserve = [{
		"unit_id": "P_M01_001",
		"template_id": "M01",
		"hp": 8,
		"max_hp": 20,
		"skill_id": "S_FIRE_CLAW",
		"atk": 9
	}]
	var reward: Dictionary = {"id": "R_HEAL", "effect": {"heal_pct": 0.25}}
	var loader: Node = get_root().get_node("DataLoader")
	var ok: bool = RewardPool.apply_reward(state, reward, "", loader)
	checks.assert_equal(ok, true, "R_HEAL apply succeeds.")
	var healed: Dictionary = (state.reserve as Array)[0] as Dictionary
	checks.assert_equal(int(healed.get("hp", 0)), 13, "reserve healed 25 percent.")
	checks.assert_equal(int(healed.get("atk", 0)), 9, "atk preserved after heal.")

func _test_apply_atk_requires_target() -> void:
	var state: Resource = RunStateScript.new()
	state.reserve = [{
		"unit_id": "P_M01_001",
		"template_id": "M01",
		"hp": 10,
		"max_hp": 18,
		"skill_id": "S_FIRE_CLAW"
	}]
	var reward: Dictionary = {
		"id": "R_ATK",
		"effect": {"stat": "atk", "delta": 2, "target": "one_pet"}
	}
	var loader: Node = get_root().get_node("DataLoader")
	var ok: bool = RewardPool.apply_reward(state, reward, "", loader)
	checks.assert_equal(ok, false, "R_ATK without target fails.")
	var entry: Dictionary = (state.reserve as Array)[0] as Dictionary
	checks.assert_equal(entry.has("atk"), false, "atk unchanged on failure.")

func _make_rm() -> Node:
	var rm: Node = RunManagerScript.new()
	get_root().add_child(rm)
	return rm

func _test_apply_rescue() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(55)
	var state: Resource = rm.get_state()
	var reward: Dictionary = {
		"id": "R_RESCUE",
		"effect": {"random_pet": "unlocked_pool", "hp_pct": 0.5}
	}
	var loader: Node = get_root().get_node("DataLoader")
	var ok: bool = RewardPool.apply_reward(state, reward, "", loader, rm)
	checks.assert_equal(ok, true, "R_RESCUE apply succeeds.")
	checks.assert_equal((state.reserve as Array).size(), 1, "reserve gains one unit.")
	rm.queue_free()

func _test_boss_bonus_smoke() -> void:
	var boss_hits: int = 0
	var normal_hits: int = 0
	var bonus_ids: Array = ["R_ATK", "R_SKILL", "R_RESCUE"]
	for seed_val in range(50):
		var rng_boss := RandomNumberGenerator.new()
		rng_boss.seed = seed_val
		var rng_normal := RandomNumberGenerator.new()
		rng_normal.seed = seed_val
		for entry_v in RewardPool.pick_three(rng_boss, true):
			if bonus_ids.has(String((entry_v as Dictionary).get("id", ""))):
				boss_hits += 1
		for entry_v2 in RewardPool.pick_three(rng_normal, false):
			if bonus_ids.has(String((entry_v2 as Dictionary).get("id", ""))):
				normal_hits += 1
	checks.assert_true(boss_hits >= normal_hits, "boss mode does not reduce bonus reward frequency.")

func _test_rescue_pool_includes_meta_extra() -> void:
	var mm: Node = get_root().get_node("MetaManager")
	mm.set_unlocked(["META_M05"])
	var pool: Array = RewardPool.get_rescue_pool()
	checks.assert_true(pool.has("M05"), "rescue pool includes M05 when META_M05 unlocked.")
	mm.reset()
