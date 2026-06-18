extends RefCounted

const PLAIN: int = 0
const FOREST: int = 1
const MOUNT: int = 2
const WATER: int = 3
const WALL: int = 4

const COLOR_BY_TERRAIN: Dictionary = {
	PLAIN: Color(0.72, 0.86, 0.58),
	FOREST: Color(0.32, 0.58, 0.30),
	MOUNT: Color(0.50, 0.42, 0.34),
	WATER: Color(0.32, 0.52, 0.78),
	WALL: Color(0.22, 0.24, 0.28)
}

const TILE_KEY_BY_TERRAIN: Dictionary = {
	PLAIN: "plain",
	FOREST: "forest",
	MOUNT: "forest",
	WATER: "water",
	WALL: "wall"
}

const HIGHLIGHT_MOVE: Color = Color(0.30, 0.55, 0.95, 0.50)
const HIGHLIGHT_ATTACK: Color = Color(0.85, 0.30, 0.30, 0.50)
const HIGHLIGHT_SKILL: Color = Color(0.65, 0.40, 0.85, 0.50)
const HIGHLIGHT_CAPTURE: Color = Color(0.30, 0.80, 0.85, 0.50)
const HIGHLIGHT_SELECTED: Color = Color(1.00, 0.85, 0.40, 0.55)
const HIGHLIGHT_DEPLOY: Color = Color(0.30, 0.75, 0.55, 0.45)

const GRID_BACKDROP: Color = Color(0.10, 0.12, 0.16, 0.85)
const GRID_GAP: int = 2

const HIGHLIGHT_BREATH_MIN: float = 0.30
const HIGHLIGHT_BREATH_MAX: float = 0.55
const HIGHLIGHT_BREATH_SECONDS: float = 1.2

const HIGHLIGHT_COLOR: Color = HIGHLIGHT_MOVE

static func get_def_bonus(terrain: int) -> int:
	if terrain == FOREST or terrain == MOUNT:
		return 1
	return 0

static func get_move_cost_extra(terrain: int) -> int:
	if terrain == MOUNT:
		return 1
	return 0

static func is_passable(terrain: int, unit_type: String) -> bool:
	if terrain == WALL:
		return false
	if terrain == WATER:
		return unit_type == "flying"
	return terrain == PLAIN or terrain == FOREST or terrain == MOUNT
