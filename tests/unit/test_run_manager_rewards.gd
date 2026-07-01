extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RunManagerScript = preload("res://scripts/autoload/run_manager.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node("DataLoader")
	loader.load_all()

	_test_elite_win_rolls_pending()
	_test_normal_win_no_pending()
	_test_apply_coin_clears_pending()
	_test_boss_win_pending_and_run_ended()
	quit(checks.finish())

func _make_rm() -> Node:
	var rm: Node = RunManagerScript.new()
	get_root().add_child(rm)
	return rm

func _win_payload(is_elite: bool, is_boss: bool) -> Dictionary:
	return {
		"is_elite": is_elite,
		"is_boss": is_boss,
		"hero_dead": false,
		"balls_remaining": 3,
		"deploy_unit_ids": ["P_HERO"],
		"survivors": [{
			"unit_id": "P_HERO",
			"template_id": "HERO",
			"hp": 20,
			"max_hp": 20,
			"skill_id": ""
		}]
	}

func _test_elite_win_rolls_pending() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(101)
	var outcome: Dictionary = rm.consume_battle_result(
		"L3N1",
		"player",
		_win_payload(true, false)
	)
	checks.assert_equal(bool(outcome.get("pending_rewards", false)), true, "elite win sets pending_rewards.")
	checks.assert_equal(rm.get_pending_rewards().size(), 3, "elite win rolls 3 rewards.")
	rm.queue_free()

func _test_normal_win_no_pending() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(202)
	var outcome: Dictionary = rm.consume_battle_result(
		"L1N1",
		"player",
		_win_payload(false, false)
	)
	checks.assert_equal(bool(outcome.get("pending_rewards", false)), false, "normal win has no pending rewards.")
	checks.assert_equal(rm.get_pending_rewards().size(), 0, "pending list empty.")
	rm.queue_free()

func _test_apply_coin_clears_pending() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(303)
	rm.consume_battle_result("L3N2", "player", _win_payload(true, false))
	var state: Resource = rm.get_state()
	var coins_before: int = int(state.coins)
	var pending: Array = rm.get_pending_rewards()
	var coin_id: String = _pick_applicable_reward_id(pending)
	var ok: bool = rm.apply_reward_choice(coin_id)
	checks.assert_equal(ok, true, "apply_reward_choice succeeds.")
	checks.assert_equal(rm.get_pending_rewards().size(), 0, "pending cleared after apply.")
	if coin_id == "R_COIN":
		checks.assert_equal(int(state.coins), coins_before + 15, "R_COIN adds 15 coins.")
	rm.queue_free()

func _test_boss_win_pending_and_run_ended() -> void:
	var rm: Node = _make_rm()
	rm.start_new_run(404)
	var state: Resource = rm.get_state()
	state.current_layer = 6
	var outcome: Dictionary = rm.consume_battle_result(
		"L6N0",
		"player",
		_win_payload(false, true)
	)
	checks.assert_equal(bool(outcome.get("run_ended", false)), true, "boss win ends run.")
	checks.assert_equal(bool(outcome.get("victory", false)), true, "boss win is victory.")
	checks.assert_equal(bool(outcome.get("pending_rewards", false)), true, "boss win rolls rewards.")
	checks.assert_equal(rm.get_pending_rewards().size(), 3, "boss pending has 3 rewards.")
	rm.queue_free()

func _pick_applicable_reward_id(pending: Array) -> String:
	for entry_v in pending:
		var entry: Dictionary = entry_v as Dictionary
		var effect: Dictionary = entry.get("effect", {}) as Dictionary
		if effect.has("coins") or effect.has("balls") or effect.has("heal_pct") or effect.has("random_pet"):
			return String(entry.get("id", ""))
	if pending.is_empty():
		return ""
	return String((pending[0] as Dictionary).get("id", ""))
