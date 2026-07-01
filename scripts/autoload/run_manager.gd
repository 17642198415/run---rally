extends Node

const RouteGenerator = preload("res://scripts/roguelike/route_generator.gd")
const RunStateScript = preload("res://scripts/roguelike/run_state.gd")
const RewardPool = preload("res://scripts/roguelike/reward_pool.gd")

var _state: Resource = null
var _last_outcome: Dictionary = {"run_ended": false, "victory": false, "pending_rewards": false}
var _run_stats_recorded: bool = false

func start_new_run(seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	var graph: Array = RouteGenerator.generate(seed, rng)
	var rs: Resource = RunStateScript.new()
	rs.seed = seed
	rs.current_layer = 1
	rs.route_graph = graph
	rs.selected_path = []
	rs.party = [{
		"template_id": "HERO",
		"unit_id": "P_HERO",
		"hp": 0,
		"max_hp": 0
	}]
	rs.reserve = []
	rs.balls = 3 + _meta_bonus_balls()
	rs.coins = 0
	rs.hero_dead = false
	rs.pending_rewards = []
	rs.pending_reward_is_boss = false
	_state = rs
	_run_stats_recorded = false

func get_state() -> Resource:
	return _state

func save() -> bool:
	if _state == null:
		push_error("RunManager: No active run to save.")
		return false
	var meta: Dictionary = _save_manager().load_meta()
	meta["run"] = {
		"active": true,
		"state": _state.serialize()
	}
	return _save_manager().save_meta(meta)

func load_from_meta() -> bool:
	var meta: Dictionary = _save_manager().load_meta()
	var run_section: Dictionary = meta.get("run", {}) as Dictionary
	if not bool(run_section.get("active", false)):
		_state = null
		return false
	var state_dict: Dictionary = run_section.get("state", {}) as Dictionary
	if state_dict.is_empty():
		_state = null
		return false
	_state = RunStateScript.deserialize(state_dict)
	return true

func clear() -> void:
	if _state != null and not _run_stats_recorded:
		_finalize_run_stats(false)
	_state = null
	var meta: Dictionary = _save_manager().load_meta()
	meta["run"] = {
		"active": false,
		"state": null
	}
	_save_manager().save_meta(meta)

func get_last_outcome() -> Dictionary:
	return _last_outcome.duplicate()

func get_pending_rewards() -> Array:
	if _state == null:
		return []
	return (_state.pending_rewards as Array).duplicate(true)

func has_pending_rewards() -> bool:
	return _state != null and not (_state.pending_rewards as Array).is_empty()

func apply_reward_choice(reward_id: String, target_unit_id: String = "") -> bool:
	if _state == null:
		return false
	var pending: Array = _state.pending_rewards as Array
	var chosen: Dictionary = {}
	for entry_v in pending:
		var entry: Dictionary = entry_v as Dictionary
		if String(entry.get("id", "")) == reward_id:
			chosen = entry.duplicate(true)
			break
	if chosen.is_empty():
		return false
	var loader: Node = _data_loader()
	if not RewardPool.apply_reward(_state, chosen, target_unit_id, loader, self):
		return false
	_state.pending_rewards = []
	_state.pending_reward_is_boss = false
	save()
	return true

func consume_battle_result(node_id: String, result: String, payload: Dictionary) -> Dictionary:
	if _state == null:
		_last_outcome = {"run_ended": false, "victory": false, "pending_rewards": false}
		return _last_outcome

	var hero_dead: bool = bool(payload.get("hero_dead", false))
	var is_boss: bool = bool(payload.get("is_boss", false))
	var is_elite: bool = bool(payload.get("is_elite", false))
	_state.balls = int(payload.get("balls_remaining", _state.balls))

	if hero_dead:
		_state.hero_dead = true
		_sync_reserve_from_battle(payload)
		save()
		_finalize_run_stats(false)
		_last_outcome = {"run_ended": true, "victory": false, "pending_rewards": false}
		return _last_outcome

	_sync_reserve_from_battle(payload)

	if result != "player":
		save()
		_last_outcome = {"run_ended": false, "victory": false, "pending_rewards": false}
		return _last_outcome

	_state.mark_node_completed(node_id)
	_state.advance_layer()

	if is_boss:
		_roll_pending_rewards(true)
		save()
		_finalize_run_stats(true)
		_last_outcome = {
			"run_ended": true,
			"victory": true,
			"pending_rewards": has_pending_rewards()
		}
		return _last_outcome

	_award_battle_coins(is_elite)
	if is_elite:
		_roll_pending_rewards(false)
	save()
	_last_outcome = {
		"run_ended": false,
		"victory": false,
		"pending_rewards": has_pending_rewards()
	}
	return _last_outcome

func complete_event_node(node_id: String) -> void:
	if _state == null:
		return
	_state.mark_node_completed(node_id)
	_state.advance_layer()
	save()

func _award_battle_coins(is_elite: bool) -> void:
	if is_elite:
		_state.coins = int(_state.coins) + 15
	else:
		_state.coins = int(_state.coins) + 8

func _roll_pending_rewards(is_boss: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_state.seed) + int(_state.current_layer) * 1009 + (_state.selected_path as Array).size() * 131
	_state.pending_rewards = RewardPool.pick_three(rng, is_boss)
	_state.pending_reward_is_boss = is_boss

func _sync_reserve_from_battle(payload: Dictionary) -> void:
	var survivors: Array = payload.get("survivors", []) as Array
	var deploy_ids: Array = payload.get("deploy_unit_ids", []) as Array
	var survivor_by_id: Dictionary = {}
	for survivor_v in survivors:
		var survivor: Dictionary = survivor_v as Dictionary
		survivor_by_id[String(survivor.get("unit_id", ""))] = survivor

	var new_reserve: Array = []
	for entry_v in _state.reserve as Array:
		var entry: Dictionary = entry_v as Dictionary
		var uid: String = String(entry.get("unit_id", ""))
		if deploy_ids.has(uid):
			continue
		new_reserve.append(entry.duplicate(true))

	for survivor_v2 in survivors:
		var survivor2: Dictionary = survivor_v2 as Dictionary
		var template_id: String = String(survivor2.get("template_id", ""))
		if template_id == "HERO":
			_update_hero_party(survivor2)
			continue
		var uid2: String = String(survivor2.get("unit_id", ""))
		if deploy_ids.has(uid2):
			new_reserve.append(survivor2.duplicate(true))

	_state.reserve = new_reserve

func _update_hero_party(hero_entry: Dictionary) -> void:
	var party: Array = _state.party as Array
	if party.is_empty():
		_state.party = [hero_entry.duplicate(true)]
		return
	var updated: Array = []
	for entry_v in party:
		var entry: Dictionary = entry_v as Dictionary
		if String(entry.get("template_id", "")) == "HERO":
			updated.append(hero_entry.duplicate(true))
		else:
			updated.append(entry.duplicate(true))
	_state.party = updated

func add_capture_to_reserve(template_id: String, hp: int, max_hp: int, skill_id: String) -> bool:
	if _state == null:
		return false
	const MAX_RUN_RESERVE: int = 8
	if (_state.reserve as Array).size() >= MAX_RUN_RESERVE:
		return false
	var unit_id: String = RunStateScript.next_reserve_unit_id(
		_state.reserve as Array,
		_state.party as Array,
		template_id
	)
	(_state.reserve as Array).append({
		"unit_id": unit_id,
		"template_id": template_id,
		"hp": hp,
		"max_hp": max_hp,
		"skill_id": skill_id
	})
	save()
	return true

func _save_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SaveManager")

func _data_loader() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("DataLoader")

func _meta_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("MetaManager")

func _meta_bonus_balls() -> int:
	var mm: Node = _meta_manager()
	if mm == null:
		return 0
	return int(mm.get_start_balls_bonus())

func _finalize_run_stats(victory: bool) -> void:
	if _state == null or _run_stats_recorded:
		return
	_run_stats_recorded = true
	var mm: Node = _meta_manager()
	if mm == null:
		return
	mm.record_run_end(_state, victory)