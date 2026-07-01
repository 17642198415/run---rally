class_name RunState
extends Resource

@export var seed: int = 0
@export var current_layer: int = 1
@export var route_graph: Array = []
@export var selected_path: Array = []
@export var party: Array = []
@export var reserve: Array = []
@export var balls: int = 3
@export var coins: int = 0
@export var hero_dead: bool = false
@export var pending_rewards: Array = []
@export var pending_reward_is_boss: bool = false

func serialize() -> Dictionary:
	return {
		"seed": seed,
		"current_layer": current_layer,
		"route_graph": _deep_copy_array(route_graph),
		"selected_path": (selected_path as Array).duplicate(),
		"party": _normalize_party(_deep_copy_array(party)),
		"reserve": _normalize_reserve(_deep_copy_array(reserve)),
		"balls": balls,
		"coins": coins,
		"hero_dead": hero_dead,
		"pending_rewards": _deep_copy_array(pending_rewards),
		"pending_reward_is_boss": pending_reward_is_boss
	}

static func deserialize(d: Dictionary) -> RunState:
	var rs := load("res://scripts/roguelike/run_state.gd").new() as RunState
	rs.seed = int(d.get("seed", 0))
	rs.current_layer = int(d.get("current_layer", 1))
	rs.route_graph = _normalize_route_graph(_deep_copy_array_static(d.get("route_graph", []) as Array))
	rs.selected_path = (d.get("selected_path", []) as Array).duplicate()
	rs.party = _normalize_party(_deep_copy_array_static(d.get("party", []) as Array))
	rs.reserve = _normalize_reserve(_deep_copy_array_static(d.get("reserve", []) as Array))
	rs.balls = int(d.get("balls", 3))
	rs.coins = int(d.get("coins", 0))
	rs.hero_dead = bool(d.get("hero_dead", false))
	rs.pending_rewards = _deep_copy_array_static(d.get("pending_rewards", []) as Array)
	rs.pending_reward_is_boss = bool(d.get("pending_reward_is_boss", false))
	return rs

func mark_node_completed(node_id: String) -> void:
	if not (selected_path as Array).has(node_id):
		(selected_path as Array).append(node_id)

func advance_layer() -> void:
	current_layer = current_layer + 1

static func heal_entries_percent(entries: Array, pct: float, hero_max_hp: int = 25) -> Array:
	var out: Array = []
	for entry_v in entries:
		var entry: Dictionary = entry_v as Dictionary
		var resolved: Dictionary = _resolve_unit_hp(entry, hero_max_hp)
		var max_hp: int = int(resolved.get("max_hp", 1))
		var hp: int = int(resolved.get("hp", max_hp))
		var gain: int = int(float(max_hp) * pct)
		out.append({
			"unit_id": String(resolved.get("unit_id", "")),
			"template_id": String(resolved.get("template_id", "")),
			"hp": mini(max_hp, hp + gain),
			"max_hp": max_hp,
			"skill_id": String(resolved.get("skill_id", ""))
		})
	return out

static func full_heal_entries(entries: Array, hero_max_hp: int = 25) -> Array:
	var out: Array = []
	for entry_v in entries:
		var entry: Dictionary = entry_v as Dictionary
		var resolved: Dictionary = _resolve_unit_hp(entry, hero_max_hp)
		var max_hp: int = int(resolved.get("max_hp", 1))
		out.append({
			"unit_id": String(resolved.get("unit_id", "")),
			"template_id": String(resolved.get("template_id", "")),
			"hp": max_hp,
			"max_hp": max_hp,
			"skill_id": String(resolved.get("skill_id", ""))
		})
	return out

static func remove_reserve_unit(reserve: Array, unit_id: String) -> Array:
	var out: Array = []
	for entry_v in reserve:
		var entry: Dictionary = entry_v as Dictionary
		if String(entry.get("unit_id", "")) != unit_id:
			out.append(entry.duplicate(true))
	return out

static func next_reserve_unit_id(reserve: Array, party: Array, template_id: String) -> String:
	var max_seq: int = 0
	var prefix: String = "P_%s_" % template_id
	for source in [reserve, party]:
		for entry_v in source:
			var uid: String = String((entry_v as Dictionary).get("unit_id", ""))
			if not uid.begins_with(prefix):
				continue
			var tail: String = uid.substr(prefix.length())
			if tail.is_valid_int():
				max_seq = maxi(max_seq, int(tail))
	return "P_%s_%03d" % [template_id, max_seq + 1]

static func _resolve_unit_hp(entry: Dictionary, hero_max_hp: int) -> Dictionary:
	var template_id: String = String(entry.get("template_id", ""))
	var max_hp: int = int(entry.get("max_hp", 0))
	var hp: int = int(entry.get("hp", 0))
	if template_id == "HERO" and max_hp <= 0:
		max_hp = hero_max_hp
		if hp <= 0:
			hp = max_hp
	return {
		"unit_id": String(entry.get("unit_id", "")),
		"template_id": template_id,
		"hp": hp,
		"max_hp": max_hp,
		"skill_id": String(entry.get("skill_id", ""))
	}

func _deep_copy_array(src: Array) -> Array:
	return _deep_copy_array_static(src)

static func _normalize_route_graph(graph: Array) -> Array:
	var out: Array = []
	for l in graph:
		var layer_dict: Dictionary = l as Dictionary
		var nodes_raw: Array = layer_dict.get("nodes", []) as Array
		var fixed_nodes: Array = []
		for nd in nodes_raw:
			var nd_dict: Dictionary = nd as Dictionary
			fixed_nodes.append({
				"id": String(nd_dict.get("id", "")),
				"type": String(nd_dict.get("type", ""))
			})
		out.append({
			"layer": int(layer_dict.get("layer", 0)),
			"nodes": fixed_nodes
		})
	return out

static func _normalize_party(party: Array) -> Array:
	var out: Array = []
	for entry_v in party:
		var entry: Dictionary = entry_v as Dictionary
		out.append({
			"template_id": String(entry.get("template_id", "")),
			"unit_id": String(entry.get("unit_id", "")),
			"hp": int(entry.get("hp", 0)),
			"max_hp": int(entry.get("max_hp", 0))
		})
	return out

static func _normalize_reserve(reserve: Array) -> Array:
	var out: Array = []
	for entry_v in reserve:
		var entry: Dictionary = entry_v as Dictionary
		var normalized: Dictionary = {
			"unit_id": String(entry.get("unit_id", "")),
			"template_id": String(entry.get("template_id", "")),
			"hp": int(entry.get("hp", 0)),
			"max_hp": int(entry.get("max_hp", entry.get("hp", 0))),
			"skill_id": String(entry.get("skill_id", ""))
		}
		if entry.has("atk"):
			normalized["atk"] = int(entry.get("atk", 0))
		if entry.has("skill_cd"):
			normalized["skill_cd"] = int(entry.get("skill_cd", 0))
		out.append(normalized)
	return out

static func _deep_copy_array_static(src: Array) -> Array:
	var out: Array = []
	for item in src:
		if typeof(item) == TYPE_DICTIONARY:
			out.append((item as Dictionary).duplicate(true))
		elif typeof(item) == TYPE_ARRAY:
			out.append(_deep_copy_array_static(item as Array))
		else:
			out.append(item)
	return out