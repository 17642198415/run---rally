extends Node

const MAX_RESERVE: int = 12

var reserve: Array = []
var _seq_by_template: Dictionary = {}
var _initialized: bool = false

func _ready() -> void:
	if not _initialized:
		_load_from_save()

func ensure_loaded() -> void:
	if not _initialized:
		_load_from_save()

func _load_from_save() -> void:
	var save_mgr: Node = _save_manager()
	if save_mgr == null:
		_initialized = true
		return
	var data: Dictionary = save_mgr.load_meta()
	from_dict(data.get("party", {}))
	_initialized = true

func can_accept() -> bool:
	return reserve.size() < MAX_RESERVE

func add_capture(template_id: String, hp: int, max_hp: int, skill_id: String) -> Dictionary:
	if not can_accept():
		return {}
	var seq: int = int(_seq_by_template.get(template_id, 0)) + 1
	_seq_by_template[template_id] = seq
	var unit_id: String = "P_%s_%03d" % [template_id, seq]
	var entry: Dictionary = {
		"unit_id": unit_id,
		"template_id": template_id,
		"hp": hp,
		"max_hp": max_hp,
		"skill_id": skill_id
	}
	reserve.append(entry)
	return entry.duplicate(true)

func to_dict() -> Dictionary:
	var copy: Array = []
	for entry in reserve:
		copy.append((entry as Dictionary).duplicate(true))
	return {
		"reserve": copy,
		"_seq_by_template": _seq_by_template.duplicate(true)
	}

func from_dict(data: Dictionary) -> void:
	reserve.clear()
	_seq_by_template.clear()
	var arr: Array = data.get("reserve", []) as Array
	for entry_variant in arr:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant as Dictionary
		reserve.append({
			"unit_id": String(entry.get("unit_id", "")),
			"template_id": String(entry.get("template_id", "")),
			"hp": int(entry.get("hp", 1)),
			"max_hp": int(entry.get("max_hp", 1)),
			"skill_id": String(entry.get("skill_id", ""))
		})
	var seq_raw: Dictionary = data.get("_seq_by_template", {}) as Dictionary
	for key in seq_raw.keys():
		_seq_by_template[String(key)] = int(seq_raw[key])
	_recalc_sequences()
	_initialized = true

func clear() -> void:
	reserve.clear()
	_seq_by_template.clear()

func _recalc_sequences() -> void:
	for entry in reserve:
		var template_id: String = String(entry.get("template_id", ""))
		var unit_id: String = String(entry.get("unit_id", ""))
		var prefix: String = "P_%s_" % template_id
		if not unit_id.begins_with(prefix):
			continue
		var tail: String = unit_id.substr(prefix.length())
		if not tail.is_valid_int():
			continue
		var idx: int = int(tail)
		if idx > int(_seq_by_template.get(template_id, 0)):
			_seq_by_template[template_id] = idx

func _save_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SaveManager")
