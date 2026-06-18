extends Node

const STAGE_ORDER: Array[String] = ["stage_01", "stage_02", "stage_03"]
const STATUS_LOCKED: String = "locked"
const STATUS_UNLOCKED: String = "unlocked"
const STATUS_CLEARED: String = "cleared"

var status: Dictionary = {}
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
		ensure_defaults({})
		_initialized = true
		return
	var data: Dictionary = save_mgr.load_meta()
	from_dict(data.get("campaign", {}) as Dictionary)

func ensure_defaults(existing: Dictionary) -> Dictionary:
	var out: Dictionary = existing.duplicate(true)
	for stage_id in STAGE_ORDER:
		if not out.has(stage_id):
			out[stage_id] = STATUS_LOCKED
	if String(out.get(STAGE_ORDER[0], STATUS_LOCKED)) == STATUS_LOCKED:
		out[STAGE_ORDER[0]] = STATUS_UNLOCKED
	return out

func get_status(stage_id: String) -> String:
	return String(status.get(stage_id, STATUS_LOCKED))

func can_enter(stage_id: String) -> bool:
	var s: String = get_status(stage_id)
	return s == STATUS_UNLOCKED or s == STATUS_CLEARED

func mark_cleared(stage_id: String, unlock_next: String = "") -> void:
	if not status.has(stage_id):
		return
	status[stage_id] = STATUS_CLEARED
	if not unlock_next.is_empty() and STAGE_ORDER.has(unlock_next):
		var current: String = String(status.get(unlock_next, STATUS_LOCKED))
		if current == STATUS_LOCKED:
			status[unlock_next] = STATUS_UNLOCKED

func to_dict() -> Dictionary:
	return status.duplicate(true)

func from_dict(data: Dictionary) -> void:
	status.clear()
	for key in data.keys():
		var sid: String = String(key)
		if STAGE_ORDER.has(sid):
			status[sid] = String(data[key])
	status = ensure_defaults(status)
	_initialized = true

func reset_progress() -> void:
	status.clear()
	status = ensure_defaults({})
	_initialized = true

func _save_manager() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("SaveManager")
