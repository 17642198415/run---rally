extends RefCounted

var unit_id: String = ""
var template_id: String = ""
var display_name: String = ""
var is_player: bool = false
var grid_pos: Vector2i = Vector2i.ZERO
var hp: int = 0
var max_hp: int = 0
var atk: int = 0
var def: int = 0
var mov: int = 0
var weapon: String = "none"
var unit_type: String = "foot"
var skill_id: String = ""
var skill_cooldown_left: int = 0
var buffs: Array = []
var tags: Array = []
var base_capture_rate: float = 0.0
var downed_capturable: bool = false

static func from_template(template_id: String, is_player: bool, grid_pos: Vector2i, unit_id: String = "") -> RefCounted:
	var unit: RefCounted = (load("res://scripts/battle/battle_unit.gd") as GDScript).new()
	unit.template_id = template_id
	unit.is_player = is_player
	unit.grid_pos = grid_pos
	unit.unit_id = unit_id if not unit_id.is_empty() else "%s_%d_%d" % [template_id, grid_pos.x, grid_pos.y]

	var loader: Node = _get_data_loader()
	var data: Dictionary = {}
	if template_id == "HERO":
		data = loader.get_hero()
	else:
		data = loader.get_unit(template_id)

	var stats: Dictionary = data.get("stats", {})
	unit.display_name = String(data.get("name", template_id))
	unit.hp = int(stats.get("hp", 1))
	unit.max_hp = unit.hp
	unit.atk = int(stats.get("atk", 1))
	unit.def = int(stats.get("def", 0))
	unit.mov = int(stats.get("mov", 1))
	unit.weapon = String(data.get("weapon", "none"))
	unit.unit_type = String(data.get("unit_type", "foot"))
	unit.skill_id = String(data.get("skill_id", ""))
	unit.skill_cooldown_left = 0
	unit.buffs = []
	unit.tags = (data.get("tags", []) as Array).duplicate()
	unit.base_capture_rate = float(data.get("base_capture_rate", 0.0))
	unit.downed_capturable = false
	return unit

func is_boss() -> bool:
	for tag in tags:
		if String(tag) == "boss":
			return true
	return false

func is_wild() -> bool:
	return not is_player and not is_boss()

func is_alive_for_battle() -> bool:
	return int(hp) > 0 and not downed_capturable

static func _get_data_loader() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node("DataLoader")
