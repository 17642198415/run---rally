const RunStateScript = preload("res://scripts/roguelike/run_state.gd")

const POOL_PATH: String = "res://data/route/reward_pool.json"
const DEFAULT_RESCUE_POOL: Array[String] = ["M01", "M02", "M03", "M04"]
const MAX_RUN_RESERVE: int = 8

static func load_pool() -> Dictionary:
	if not FileAccess.file_exists(POOL_PATH):
		push_error("RewardPool: missing %s" % POOL_PATH)
		return {"rewards": [], "boss_weight_bonus": []}
	var file := FileAccess.open(POOL_PATH, FileAccess.READ)
	if file == null:
		return {"rewards": [], "boss_weight_bonus": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"rewards": [], "boss_weight_bonus": []}
	var data: Dictionary = parsed as Dictionary
	return {
		"rewards": (data.get("rewards", []) as Array).duplicate(true),
		"boss_weight_bonus": (data.get("boss_weight_bonus", []) as Array).duplicate()
	}

static func get_rescue_pool() -> Array[String]:
	var pool: Array[String] = DEFAULT_RESCUE_POOL.duplicate()
	var mm: Node = _meta_manager_node()
	if mm != null:
		for extra in mm.get_pool_extras() as Array:
			var template_id: String = String(extra)
			if not template_id.is_empty() and not pool.has(template_id):
				pool.append(template_id)
	return pool

static func _meta_manager_node() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("MetaManager")

static func pick_three(rng: RandomNumberGenerator, is_boss: bool) -> Array:
	var pool_data: Dictionary = load_pool()
	var rewards: Array = pool_data.get("rewards", []) as Array
	if rewards.is_empty():
		return []
	var bonus_ids: Array = pool_data.get("boss_weight_bonus", []) as Array
	var pool: Array = []
	for entry_v in rewards:
		var entry: Dictionary = (entry_v as Dictionary).duplicate(true)
		var weight: float = float(entry.get("weight", 10))
		if is_boss and bonus_ids.has(String(entry.get("id", ""))):
			weight *= 2.0
		entry["weight"] = weight
		pool.append(entry)
	var picked: Array = []
	for _i in range(mini(3, pool.size())):
		var index: int = _pick_index(pool, rng)
		picked.append((pool[index] as Dictionary).duplicate(true))
		pool.remove_at(index)
	return picked

static func apply_reward(
	state: Resource,
	reward: Dictionary,
	target_unit_id: String,
	loader: Node,
	rm: Node = null
) -> bool:
	if state == null:
		return false
	var snapshot: Dictionary = state.serialize()
	if not _apply_reward_inner(state, reward, target_unit_id, loader, rm):
		_restore_state(state, snapshot)
		return false
	return true

static func _apply_reward_inner(
	state: Resource,
	reward: Dictionary,
	target_unit_id: String,
	loader: Node,
	rm: Node
) -> bool:
	var effect: Dictionary = reward.get("effect", {}) as Dictionary
	if effect.has("balls"):
		state.balls = int(state.balls) + int(effect.get("balls", 0))
		return true
	if effect.has("coins"):
		state.coins = int(state.coins) + int(effect.get("coins", 0))
		return true
	if effect.has("heal_pct"):
		var pct: float = float(effect.get("heal_pct", 0.0))
		state.party = _heal_keep_extras(state.party as Array, pct, 25)
		state.reserve = _heal_keep_extras(state.reserve as Array, pct, 25)
		return true
	if effect.has("random_pet"):
		return _apply_rescue(state, effect, loader, rm)
	if effect.has("skill_cd") and String(effect.get("target", "")) == "one_pet":
		return _apply_skill_cd(state, effect, target_unit_id, loader)
	if effect.has("stat") and String(effect.get("target", "")) == "one_pet":
		return _apply_stat_delta(state, effect, target_unit_id, loader)
	return false

static func _apply_rescue(state: Resource, effect: Dictionary, loader: Node, rm: Node) -> bool:
	if rm == null or loader == null:
		return false
	if (state.reserve as Array).size() >= MAX_RUN_RESERVE:
		return false
	var pool: Array[String] = get_rescue_pool()
	if pool.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = int(state.seed) + int(state.current_layer) * 2003
	var template_id: String = pool[rng.randi_range(0, pool.size() - 1)]
	var unit: Dictionary = loader.get_unit(template_id)
	var max_hp: int = int((unit.get("stats", {}) as Dictionary).get("hp", 10))
	var hp_pct: float = float(effect.get("hp_pct", 0.5))
	var hp: int = maxi(1, int(float(max_hp) * hp_pct))
	return rm.add_capture_to_reserve(
		template_id,
		hp,
		max_hp,
		String(unit.get("skill_id", ""))
	)

static func _apply_stat_delta(
	state: Resource,
	effect: Dictionary,
	target_unit_id: String,
	loader: Node
) -> bool:
	if target_unit_id.is_empty():
		return false
	var stat: String = String(effect.get("stat", ""))
	var delta: int = int(effect.get("delta", 0))
	var reserve: Array = state.reserve as Array
	for i in range(reserve.size()):
		var entry: Dictionary = reserve[i] as Dictionary
		if String(entry.get("unit_id", "")) != target_unit_id:
			continue
		var updated: Dictionary = entry.duplicate(true)
		if stat == "atk":
			var base_atk: int = _base_atk_for_entry(entry, loader)
			var current: int = int(updated.get("atk", base_atk))
			updated["atk"] = current + delta
		elif stat == "hp":
			var base_max: int = _base_max_hp_for_entry(entry, loader)
			var max_hp: int = int(updated.get("max_hp", base_max))
			if max_hp <= 0:
				max_hp = base_max
			max_hp += delta
			updated["max_hp"] = max_hp
			updated["hp"] = mini(max_hp, int(updated.get("hp", max_hp)) + delta)
		else:
			return false
		reserve[i] = updated
		state.reserve = reserve
		return true
	return false

static func _apply_skill_cd(
	state: Resource,
	effect: Dictionary,
	target_unit_id: String,
	loader: Node
) -> bool:
	if target_unit_id.is_empty():
		return false
	var delta: int = int(effect.get("skill_cd", 0))
	var reserve: Array = state.reserve as Array
	for i in range(reserve.size()):
		var entry: Dictionary = reserve[i] as Dictionary
		if String(entry.get("unit_id", "")) != target_unit_id:
			continue
		var updated: Dictionary = entry.duplicate(true)
		var base_cd: int = _base_skill_cd_for_entry(entry, loader)
		var current: int = int(updated.get("skill_cd", base_cd))
		updated["skill_cd"] = maxi(0, current + delta)
		reserve[i] = updated
		state.reserve = reserve
		return true
	return false

static func _heal_keep_extras(entries: Array, pct: float, hero_max_hp: int) -> Array:
	var healed: Array = RunStateScript.heal_entries_percent(entries, pct, hero_max_hp)
	var out: Array = []
	for i in range(healed.size()):
		var healed_entry: Dictionary = healed[i] as Dictionary
		var source: Dictionary = entries[i] as Dictionary
		var merged: Dictionary = healed_entry.duplicate(true)
		if source.has("atk"):
			merged["atk"] = int(source.get("atk", 0))
		if source.has("skill_cd"):
			merged["skill_cd"] = int(source.get("skill_cd", 0))
		out.append(merged)
	return out

static func _base_atk_for_entry(entry: Dictionary, loader: Node) -> int:
	if loader == null:
		return 0
	var template_id: String = String(entry.get("template_id", ""))
	if template_id.is_empty():
		return 0
	var unit: Dictionary = loader.get_unit(template_id)
	return int((unit.get("stats", {}) as Dictionary).get("atk", 0))

static func _base_max_hp_for_entry(entry: Dictionary, loader: Node) -> int:
	var max_hp: int = int(entry.get("max_hp", 0))
	if max_hp > 0:
		return max_hp
	if loader == null:
		return 1
	var template_id: String = String(entry.get("template_id", ""))
	var unit: Dictionary = loader.get_unit(template_id)
	return int((unit.get("stats", {}) as Dictionary).get("hp", 1))

static func _base_skill_cd_for_entry(entry: Dictionary, loader: Node) -> int:
	if loader == null:
		return 0
	var skill_id: String = String(entry.get("skill_id", ""))
	if skill_id.is_empty():
		return 0
	var skill: Dictionary = loader.get_skill(skill_id)
	return int(skill.get("cooldown", 0))

static func _restore_state(state: Resource, snapshot: Dictionary) -> void:
	var restored: Resource = RunStateScript.deserialize(snapshot)
	state.seed = restored.seed
	state.current_layer = restored.current_layer
	state.route_graph = restored.route_graph
	state.selected_path = restored.selected_path
	state.party = restored.party
	state.reserve = restored.reserve
	state.balls = restored.balls
	state.coins = restored.coins
	state.hero_dead = restored.hero_dead
	state.pending_rewards = restored.pending_rewards
	state.pending_reward_is_boss = restored.pending_reward_is_boss

static func _pick_index(pool: Array, rng: RandomNumberGenerator) -> int:
	var total: float = 0.0
	for entry_v in pool:
		total += float((entry_v as Dictionary).get("weight", 10))
	if total <= 0.0:
		return 0
	var roll: float = rng.randf_range(0.0, total)
	var cumulative: float = 0.0
	for i in range(pool.size()):
		cumulative += float((pool[i] as Dictionary).get("weight", 10))
		if roll <= cumulative:
			return i
	return pool.size() - 1
