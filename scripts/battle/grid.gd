extends RefCounted

const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")

var width: int = 0
var height: int = 0
var terrain: Array = []
var occupancy: Dictionary = {}
var deploy_zones: Dictionary = {}

static func from_template(template: Dictionary) -> RefCounted:
	var grid: RefCounted = (load("res://scripts/battle/grid.gd") as GDScript).new()
	grid.width = int(template.get("width", 0))
	grid.height = int(template.get("height", 0))

	var terrain_raw: Array = template.get("terrain", [])
	var rows: Array = []
	for y in grid.height:
		var row_in: Array = terrain_raw[y] if y < terrain_raw.size() else []
		var row: Array = []
		for x in grid.width:
			var v: int = int(row_in[x]) if x < row_in.size() else TerrainTypes.PLAIN
			row.append(v)
		rows.append(row)
	grid.terrain = rows

	var zones_raw: Dictionary = template.get("deploy_zones", {})
	var zones: Dictionary = {}
	for side_key in zones_raw.keys():
		var key: String = String(side_key)
		var raw_list: Array = zones_raw[side_key]
		var parsed: Array[Vector2i] = []
		for entry in raw_list:
			if entry is Dictionary:
				parsed.append(Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0))))
			elif entry is Vector2i:
				parsed.append(entry)
		zones[key] = parsed
	grid.deploy_zones = zones

	grid.occupancy = {}
	return grid

func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_terrain(pos: Vector2i) -> int:
	if not in_bounds(pos):
		return TerrainTypes.WALL
	return int(terrain[pos.y][pos.x])

func is_walkable(pos: Vector2i, unit_type: String, mover_id: String = "") -> bool:
	if not in_bounds(pos):
		return false
	if not TerrainTypes.is_passable(get_terrain(pos), unit_type):
		return false
	var occupant: String = String(occupancy.get(pos, ""))
	if occupant == "" or occupant == mover_id:
		return true
	return false

func set_occupant(pos: Vector2i, unit_id: String) -> void:
	occupancy[pos] = unit_id

func clear_occupant(pos: Vector2i) -> void:
	occupancy.erase(pos)

func get_occupant(pos: Vector2i) -> String:
	return String(occupancy.get(pos, ""))

func get_move_cost(_from: Vector2i, to: Vector2i, _unit_type: String) -> int:
	if not in_bounds(to):
		return -1
	return 1 + TerrainTypes.get_move_cost_extra(get_terrain(to))
