extends Node

const UNLOCKS_PATH: String = "res://data/meta_unlocks.json"

const STAT_KEYS: Array[String] = [
	"runs_started",
	"runs_won",
	"runs_lost",
	"deepest_layer",
	"total_captures",
	"total_coins_spent"
]

var unlocked: Array[String] = []
var _definitions: Array = []
var _loaded: bool = false

func _ready() -> void:
	load_definitions()
	_load_from_save()

func load_definitions() -> void:
	_definitions = []
	if not FileAccess.file_exists(UNLOCKS_PATH):
		push_error("MetaManager: missing %s" % UNLOCKS_PATH)
		return
	var file := FileAccess.open(UNLOCKS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_definitions = ((parsed as Dictionary).get("unlocks", []) as Array).duplicate(true)
	_loaded = true

func get_definitions() -> Array:
	if not _loaded:
		load_definitions()
	return _definitions.duplicate(true)

func reset() -> void:
	unlocked = []

func set_unlocked(ids: Array) -> void:
	unlocked = []
	for id in ids:
		unlocked.append(String(id))

func from_dict(data: Dictionary) -> void:
	unlocked = []
	for id in (data.get("unlocked", []) as Array):
		unlocked.append(String(id))

func to_dict() -> Dictionary:
	return {"unlocked": unlocked.duplicate()}

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func unlocked_count() -> int:
	return unlocked.size()

func get_start_balls_bonus() -> int:
	var bonus: int = 0
	for def_v in get_definitions():
		var def: Dictionary = def_v as Dictionary
		var unlock_id: String = String(def.get("id", ""))
		if not is_unlocked(unlock_id):
			continue
		var effect: Dictionary = def.get("effect", {}) as Dictionary
		if effect.has("start_balls_bonus"):
			bonus += int(effect.get("start_balls_bonus", 0))
	return bonus

func get_pool_extras() -> Array[String]:
	var out: Array[String] = []
	for def_v in get_definitions():
		var def: Dictionary = def_v as Dictionary
		if not is_unlocked(String(def.get("id", ""))):
			continue
		var effect: Dictionary = def.get("effect", {}) as Dictionary
		if effect.has("add_to_pool"):
			var template_id: String = String(effect.get("add_to_pool", ""))
			if not template_id.is_empty() and not out.has(template_id):
				out.append(template_id)
	return out

func evaluate_unlocks(meta_snapshot: Dictionary) -> Array[String]:
	var newly: Array[String] = []
	for def_v in get_definitions():
		var def: Dictionary = def_v as Dictionary
		var unlock_id: String = String(def.get("id", ""))
		if unlock_id.is_empty() or unlocked.has(unlock_id):
			continue
		if _condition_met(def.get("condition", {}) as Dictionary, meta_snapshot):
			unlocked.append(unlock_id)
			newly.append(unlock_id)
	return newly

func record_run_end(state: Resource, victory: bool) -> void:
	if state == null:
		return
	var save_mgr: Node = _save_manager()
	if save_mgr == null:
		return
	var meta: Dictionary = save_mgr.load_meta()
	var stats: Dictionary = normalize_stats(meta.get("stats", {}) as Dictionary)
	stats["runs_started"] = int(stats.get("runs_started", 0)) + 1
	if victory:
		stats["runs_won"] = int(stats.get("runs_won", 0)) + 1
	else:
		stats["runs_lost"] = int(stats.get("runs_lost", 0)) + 1
	var layer_reached: int = _layer_reached(state, victory)
	stats["deepest_layer"] = maxi(int(stats.get("deepest_layer", 0)), layer_reached)
	stats["total_captures"] = int(stats.get("total_captures", 0)) + (state.reserve as Array).size()
	meta["stats"] = stats
	evaluate_unlocks(meta)
	meta["meta"] = to_dict()
	save_mgr.save_meta(meta)

func evaluate_after_bestiary_change() -> void:
	var save_mgr: Node = _save_manager()
	if save_mgr == null:
		return
	var meta: Dictionary = save_mgr.load_meta()
	var bestiary: Node = _bestiary_manager()
	if bestiary != null:
		meta["bestiary"] = bestiary.to_dict()
	var before: int = unlocked.size()
	evaluate_unlocks(meta)
	if unlocked.size() > before:
		meta["meta"] = to_dict()
		save_mgr.save_meta(meta)

static func normalize_stats(stats: Dictionary) -> Dictionary:
	var out: Dictionary = stats.duplicate(true)
	for key in STAT_KEYS:
		if not out.has(key):
			out[key] = 0
	return out

func condition_hint(def: Dictionary, meta_snapshot: Dictionary) -> String:
	var condition: Dictionary = def.get("condition", {}) as Dictionary
	var cond_type: String = String(condition.get("type", ""))
	if cond_type == "or":
		return "通关 1 次征途，或抵达第 %d 层" % int(condition.get("deepest_layer", 5))
	if cond_type == "bestiary":
		var unit_id: String = String(condition.get("unit_id", ""))
		var state_name: String = String(condition.get("state", "seen"))
		if state_name == "caught":
			return "图鉴捕获 %s" % unit_id
		return "图鉴发现 %s" % unit_id
	return ""

func _condition_met(condition: Dictionary, meta_snapshot: Dictionary) -> bool:
	var cond_type: String = String(condition.get("type", ""))
	if cond_type == "or":
		var stats: Dictionary = normalize_stats(meta_snapshot.get("stats", {}) as Dictionary)
		var need_wins: int = int(condition.get("runs_won", 1))
		var need_layer: int = int(condition.get("deepest_layer", 5))
		return int(stats.get("runs_won", 0)) >= need_wins or int(stats.get("deepest_layer", 0)) >= need_layer
	if cond_type == "bestiary":
		return _bestiary_condition_met(condition, meta_snapshot)
	return false

func _bestiary_condition_met(condition: Dictionary, meta_snapshot: Dictionary) -> bool:
	var unit_id: String = String(condition.get("unit_id", ""))
	var want_state: String = String(condition.get("state", "seen"))
	var bestiary: Dictionary = meta_snapshot.get("bestiary", {}) as Dictionary
	var entry: Dictionary = bestiary.get(unit_id, {}) as Dictionary
	if want_state == "caught":
		return bool(entry.get("caught", false))
	return bool(entry.get("discovered", false))

func _layer_reached(state: Resource, victory: bool) -> int:
	if victory:
		return 6
	var layer: int = int(state.current_layer)
	var path_len: int = (state.selected_path as Array).size()
	return maxi(layer, path_len)

func _load_from_save() -> void:
	var save_mgr: Node = _save_manager()
	if save_mgr == null:
		return
	var meta: Dictionary = save_mgr.load_meta()
	from_dict((meta.get("meta", {}) as Dictionary))

func _save_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SaveManager")

func _bestiary_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("BestiaryManager")
