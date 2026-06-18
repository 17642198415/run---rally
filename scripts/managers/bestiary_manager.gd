extends Node

var entries: Dictionary = {}
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
	from_dict(data.get("bestiary", {}))
	_initialized = true

func mark_discovered(template_id: String) -> void:
	if template_id.is_empty():
		return
	var entry: Dictionary = entries.get(template_id, {"discovered": false, "caught": false})
	entry["discovered"] = true
	entries[template_id] = entry

func mark_caught(template_id: String) -> void:
	if template_id.is_empty():
		return
	var entry: Dictionary = entries.get(template_id, {"discovered": false, "caught": false})
	entry["discovered"] = true
	entry["caught"] = true
	entries[template_id] = entry

func is_discovered(template_id: String) -> bool:
	var entry: Dictionary = entries.get(template_id, {})
	return bool(entry.get("discovered", false))

func is_caught(template_id: String) -> bool:
	var entry: Dictionary = entries.get(template_id, {})
	return bool(entry.get("caught", false))

func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for key in entries.keys():
		var entry: Dictionary = entries[key] as Dictionary
		out[String(key)] = {
			"discovered": bool(entry.get("discovered", false)),
			"caught": bool(entry.get("caught", false))
		}
	return out

func from_dict(data: Dictionary) -> void:
	entries.clear()
	for key in data.keys():
		var raw: Variant = data[key]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw as Dictionary
		entries[String(key)] = {
			"discovered": bool(entry.get("discovered", false)),
			"caught": bool(entry.get("caught", false))
		}
	_initialized = true

func clear() -> void:
	entries.clear()

func _save_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SaveManager")
