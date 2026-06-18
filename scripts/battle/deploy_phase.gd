extends RefCounted

const BattleUnit = preload("res://scripts/battle/battle_unit.gd")

var stage: Dictionary = {}
var grid: RefCounted = null
var pending_templates: Array = []
var placed: Dictionary = {}
var placed_cells: Dictionary = {}

func setup(stage_data: Dictionary, grid_ref: RefCounted) -> void:
	stage = stage_data
	grid = grid_ref
	pending_templates = []
	placed = {}
	placed_cells = {}
	var player_block: Variant = stage.get("player", null)
	var party_source: String = ""
	if typeof(player_block) == TYPE_DICTIONARY:
		party_source = String((player_block as Dictionary).get("party_source", ""))
	if party_source == "campaign_setup":
		var deploy_list: Array = _get_deploy_list_from_game_state()
		for entry_variant in deploy_list:
			var entry: Dictionary = entry_variant as Dictionary
			pending_templates.append({
				"template": String(entry.get("template_id", "")),
				"unit_id": String(entry.get("unit_id", "")),
				"hp": int(entry.get("hp", 0)),
				"max_hp": int(entry.get("max_hp", 0))
			})
		return
	var player_entries: Array = stage.get("player_units", [])
	for entry in player_entries:
		pending_templates.append(entry)

func _get_deploy_list_from_game_state() -> Array:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	var gs: Node = tree.root.get_node_or_null("GameState")
	if gs == null:
		return []
	var ctx: Dictionary = gs.battle_context as Dictionary
	return ctx.get("deploy_list", []) as Array

func reset() -> void:
	placed = {}
	placed_cells = {}

func is_deploy_cell(cell: Vector2i) -> bool:
	var zones: Array = grid.deploy_zones.get("player", [])
	return zones.has(cell)

func can_place_at(cell: Vector2i) -> bool:
	if grid == null:
		return false
	if not grid.in_bounds(cell):
		return false
	if not is_deploy_cell(cell):
		return false
	if placed_cells.has(cell):
		return false
	var occupant: String = String(grid.get_occupant(cell))
	return occupant.is_empty()

func get_next_unplaced_index() -> int:
	for i in pending_templates.size():
		if not placed.has(i):
			return i
	return -1

func place_at(cell: Vector2i, template_index: int) -> RefCounted:
	if template_index < 0 or template_index >= pending_templates.size():
		return null
	if not can_place_at(cell):
		return null
	if placed.has(template_index):
		return null
	var entry: Dictionary = pending_templates[template_index] as Dictionary
	var template_id: String = String(entry.get("template", ""))
	var explicit_id: String = String(entry.get("unit_id", ""))
	var unit_id: String = explicit_id if not explicit_id.is_empty() else "P_%s_%d" % [template_id, template_index]
	var unit: RefCounted = BattleUnit.from_template(template_id, true, cell, unit_id)
	var entry_hp: int = int(entry.get("hp", 0))
	if entry_hp > 0:
		unit.hp = entry_hp
	var entry_max: int = int(entry.get("max_hp", 0))
	if entry_max > 0:
		unit.max_hp = entry_max
	placed[template_index] = {"unit": unit, "cell": cell}
	placed_cells[cell] = template_index
	grid.set_occupant(cell, unit_id)
	return unit

func remove_at(cell: Vector2i) -> void:
	if not placed_cells.has(cell):
		return
	var template_index: int = int(placed_cells[cell])
	placed.erase(template_index)
	placed_cells.erase(cell)
	grid.clear_occupant(cell)

func can_confirm() -> bool:
	if pending_templates.is_empty():
		return false
	return placed.size() == pending_templates.size()

func get_placed_units() -> Array:
	var result: Array = []
	for key in placed.keys():
		var entry: Dictionary = placed[key] as Dictionary
		result.append(entry.get("unit"))
	return result

func spawn_enemies() -> Array:
	var result: Array = []
	var enemy_entries: Array = stage.get("enemy_units", [])
	var idx: int = 0
	for entry_variant in enemy_entries:
		var entry: Dictionary = entry_variant as Dictionary
		var template_id: String = String(entry.get("template", ""))
		var spawn: Dictionary = entry.get("spawn", {}) as Dictionary
		var pos: Vector2i = Vector2i(int(spawn.get("x", 0)), int(spawn.get("y", 0)))
		var unit_id: String = "E_%s_%d" % [template_id, idx]
		idx += 1
		var unit: RefCounted = BattleUnit.from_template(template_id, false, pos, unit_id)
		grid.set_occupant(pos, unit_id)
		result.append(unit)
	return result
