# chapter-2-grid-and-movement Specification

## Purpose

Defines the chapter 2 battlefield foundation for the Godot tactics monster demo: 10×10 grid, terrain modifiers, occupancy, BFS pathfinding, click-to-move battle scene, and command-line unit test coverage.

## Requirements

### Requirement: Battlefield grid is a 10x10 integer lattice
The system SHALL represent the battlefield as a 10×10 integer grid with `(0,0)` at the top-left and positions using `Vector2i`. The grid SHALL expose its `width`, `height`, the per-cell terrain code, and per-cell occupancy.

#### Scenario: Grid dimensions and origin are correct
- **WHEN** a `Grid` is constructed from `data/map_templates/test_grid.json`
- **THEN** `grid.width == 10` and `grid.height == 10` and `grid.get_terrain(Vector2i(0, 0))` returns the value at `terrain[0][0]` of the JSON

#### Scenario: Out-of-bounds positions are rejected
- **WHEN** any `Grid` query is made with a position whose `x` or `y` is outside `[0, width-1]` / `[0, height-1]`
- **THEN** `Grid.is_walkable` returns `false` and the grid does not crash

### Requirement: Four terrain types plus walls with documented modifiers
The system SHALL support five terrain codes — `PLAIN=0`, `FOREST=1`, `MOUNT=2`, `WATER=3`, `WALL=4` — and apply the modifiers defined in Demo plan §2.4.1: forest gives `def +1`, mountain gives `def +1` and adds `+1` to entering move cost, water blocks foot units but allows flying units, and walls block all units.

#### Scenario: Terrain modifiers match the table
- **WHEN** `terrain_types.get_def_bonus()` and `terrain_types.get_move_cost_extra()` are queried for each terrain code
- **THEN** `FOREST` and `MOUNT` return `def_bonus = 1`, all others return `0`; `MOUNT` returns `move_cost_extra = 1`, all others return `0`

#### Scenario: Foot units cannot enter water or wall
- **WHEN** `Grid.is_walkable(pos, "foot")` is called for a cell whose terrain is `WATER` or `WALL` and which is unoccupied
- **THEN** the result is `false`

#### Scenario: Flying units cross water but not walls
- **WHEN** `Grid.is_walkable(pos, "flying")` is called
- **THEN** `WATER` cells return `true` while `WALL` cells return `false`

### Requirement: Occupancy table prevents two units sharing a cell
The system SHALL maintain a `Vector2i → unit_id` occupancy table that supports `set_occupant`, `clear_occupant`, and excludes occupied cells from `is_walkable` for any unit other than the current occupant.

#### Scenario: Occupied cell blocks other units
- **WHEN** unit `A` occupies `Vector2i(2, 2)` and `Grid.is_walkable(Vector2i(2, 2), "foot")` is called for a different mover
- **THEN** the result is `false`

#### Scenario: Mover is not blocked by its own cell
- **WHEN** unit `A` occupies `Vector2i(2, 2)` and `Grid.is_walkable(Vector2i(2, 2), "foot", "A")` is called with `A` as the moving unit
- **THEN** the result is `true`

#### Scenario: Move updates occupancy atomically
- **WHEN** the controller moves unit `A` from `Vector2i(2, 2)` to `Vector2i(2, 3)` via `clear_occupant` then `set_occupant`
- **THEN** `Vector2i(2, 2)` becomes free and `Vector2i(2, 3)` is occupied by `A`

### Requirement: BFS reachability respects MOV, terrain cost, walls and occupancy
The system SHALL compute reachable cells for a unit using a Dijkstra-style BFS where each step costs `1 + terrain_extra(neighbor)`, total cost must not exceed `mov`, walls and unwalkable terrain are skipped, and other units' cells are not entered.

#### Scenario: Plain terrain reach matches MOV
- **WHEN** `Pathfinding.get_reachable(grid, Vector2i(5, 5), 4, "foot")` is called on an all-plain grid
- **THEN** the result contains every cell whose Manhattan distance to `(5,5)` is between `1` and `4` inclusive

#### Scenario: Mountain consumes extra move cost
- **WHEN** a foot unit at `(0, 0)` with `mov = 3` faces a mountain at `(1, 0)`
- **THEN** entering `(1, 0)` costs `2`, so `(2, 0)` (cost `3` if `(1,0)` is the only mountain on that path) is reachable but `(3, 0)` is not

#### Scenario: Walls and other units are skipped
- **WHEN** a wall sits at `(2, 0)` and an enemy occupies `(0, 2)`
- **THEN** `get_reachable` from `(0, 0)` with `mov = 3` excludes both `(2, 0)` and `(0, 2)` from the result

#### Scenario: Flying unit traverses water
- **WHEN** a flying unit runs `get_reachable` over a row containing water cells
- **THEN** those water cells appear in the result while a foot unit's call excludes them

### Requirement: Path reconstruction returns a connected sequence
The system SHALL provide `Pathfinding.find_path(grid, start, goal, mov, unit_type)` that returns an `Array[Vector2i]` from `start` to `goal` (inclusive) when `goal` is in the reachable set, and an empty array otherwise.

#### Scenario: Path is connected and within reach
- **WHEN** `find_path` succeeds
- **THEN** the returned array starts at `start`, ends at `goal`, has consecutive cells differing by exactly one in one axis, and every intermediate cell is walkable for the unit

#### Scenario: Unreachable goal returns empty
- **WHEN** the goal lies behind a wall or beyond `mov` budget
- **THEN** `find_path` returns an empty array

### Requirement: Test map template defines terrain and deploy zones
The repository SHALL provide `data/map_templates/test_grid.json` containing `width=10`, `height=10`, a `terrain` matrix matching Demo plan §2.4.2 exactly, and `deploy_zones` for both player and enemy.

#### Scenario: Template loads without errors
- **WHEN** the JSON is parsed and passed to `Grid.from_template`
- **THEN** the resulting grid has the documented terrain values at sample cells: `(3,3)=WALL`, `(8,2)=WATER`, `(4,1)=MOUNT`, `(1,1)=FOREST`, `(0,0)=PLAIN`

#### Scenario: Deploy zones are loaded but not enforced this chapter
- **WHEN** the template is loaded
- **THEN** `grid.deploy_zones["player"]` and `grid.deploy_zones["enemy"]` are non-empty arrays of `Vector2i`, and the chapter 2 controller does not yet restrict spawning by them

### Requirement: Battle scene renders grid and supports click-to-move
The `scenes/battle/battle.tscn` scene SHALL render the 10×10 grid as colored cells, place one test unit, highlight reachable cells when the unit is clicked, and tween-move the unit to any clicked reachable cell while updating occupancy.

#### Scenario: Cells are colored by terrain
- **WHEN** the battle scene opens with `test_grid.json`
- **THEN** plain, forest, mountain, water, and wall cells are visibly distinguishable via the colors defined in `terrain_types.gd`

#### Scenario: Clicking the unit highlights reachable cells
- **WHEN** the user clicks the test unit
- **THEN** all cells returned by `Pathfinding.get_reachable` are visually highlighted (semi-transparent overlay) and unreachable cells are not

#### Scenario: Clicking a reachable cell moves the unit
- **WHEN** a reachable cell is clicked while a unit is selected
- **THEN** the unit tweens to that cell, occupancy updates from old to new, the highlight clears, and the controller returns to the idle state

#### Scenario: Clicking an unreachable cell is ignored
- **WHEN** an unreachable cell is clicked while a unit is selected
- **THEN** the unit does not move, occupancy is unchanged, and the selection state remains unchanged

### Requirement: No combat, turn or AI features are added in this chapter
The system SHALL NOT introduce HP, attack ranges, damage calculation, skill cooldowns, deploy phase, turn cycling, or enemy AI in chapter 2. Chapter 2 only delivers grid, terrain, occupancy, BFS pathfinding, and click-to-move.

#### Scenario: No combat UI is present
- **WHEN** the battle scene runs
- **THEN** there is no attack button, no HP bar, no end-turn button, and no AI movement happens

### Requirement: Chapter 2 has command-line unit tests for grid and pathfinding
The project SHALL include headless unit tests (under `tests/unit/`) that cover terrain modifiers, `Grid.is_walkable`, move cost, BFS reachability with mountains/water/walls/occupancy, flying-unit water traversal, and `find_path` reconstruction.

#### Scenario: Grid and pathfinding tests pass
- **WHEN** the existing chapter 1 headless test command is run
- **THEN** all chapter 2 tests pass with a zero exit code together with chapter 1 tests
