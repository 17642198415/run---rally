## ADDED Requirements

### Requirement: Main menu starts or continues a roguelike run

The `scenes/main_menu.tscn` scene SHALL enable the **开始征途** action (no longer disabled). When `SaveManager.load_meta().run.active` is `false`, selecting **开始征途** SHALL call `RunManager.start_new_run(seed)`, persist via `RunManager.save()`, and load `scenes/roguelike/route_map.tscn`. When `run.active` is `true`, the button label SHALL change to **继续征途** and load the saved run via `RunManager.load_from_meta()` then `route_map.tscn`. The menu SHALL provide a way to abandon an active run (e.g. **放弃征途**) that calls `RunManager.clear()` and restores the new-run entry state.

#### Scenario: New run from main menu
- **WHEN** no active run exists and the player chooses **开始征途**
- **THEN** `RunManager.get_state()` is non-null, `run.active` is true in save meta, and `route_map.tscn` loads

#### Scenario: Continue active run
- **WHEN** `run.active` is true and the player chooses **继续征途**
- **THEN** `RunManager.load_from_meta()` restores state and `route_map.tscn` loads with matching `current_layer` and `route_graph`

#### Scenario: Abandon run clears persistence
- **WHEN** the player confirms abandoning an active run
- **THEN** `RunManager.clear()` sets `run.active` to false and the main menu shows **开始征途** again

### Requirement: Route map displays vertical 6-layer graph with sidebar status

`scenes/roguelike/route_map.tscn` SHALL render a vertical route map from `RunState.route_graph` (6 layers) and a sidebar showing `current_layer`, `balls`, `coins`, and reserve count. Completed nodes (IDs in `selected_path`) SHALL appear visually completed (muted/gray). Node appearance SHALL use metadata from `data/route/node_types.json` (icon/label/color).

#### Scenario: Route map shows current layer progress
- **WHEN** `route_map.tscn` loads with `RunState.current_layer == 3` and two nodes in `selected_path`
- **THEN** layers 1-2 completed nodes are muted and layer 3 nodes are highlighted as selectable candidates

#### Scenario: Sidebar reflects run resources
- **WHEN** `RunState` has `balls == 2`, `coins == 18`, and 1 reserve unit
- **THEN** the sidebar displays those values

### Requirement: Only battle elite and boss nodes on current layer are clickable

On `route_map.tscn`, a node SHALL be clickable only when `node.layer == RunState.current_layer`, `node.type` is `battle`, `elite`, or `boss`, and `node.id` is not already in `selected_path`. Nodes of type `rest`, `shop`, or `capture_event` SHALL be visible but disabled with a hint that they are not yet available (Chapter 7B2).

#### Scenario: Current layer battle node opens battle flow
- **WHEN** the player clicks a `battle` node on the current layer
- **THEN** `EnemyGroupPicker.pick` is invoked for that layer and the game proceeds to roguelike party setup

#### Scenario: Non-battle node types are disabled
- **WHEN** the route graph contains a `shop` node on the current layer
- **THEN** the node is shown but cannot be clicked and displays a not-yet-available hint

#### Scenario: Completed nodes cannot be re-selected
- **WHEN** a node id is already in `selected_path`
- **THEN** that node is not clickable

### Requirement: Roguelike party setup reuses party_setup scene with ROGUELIKE mode

When `GameState.current_mode == ROGUELIKE`, `party_setup.tscn` SHALL read reserve units from `RunManager.get_state().reserve` (not `PartyManager`). It SHALL still fix HERO in the deploy list and allow 0-3 reserve picks. Confirming SHALL call `GameState.start_roguelike_battle(...)` with `deploy_list`, set `return_scene_path` to `res://scenes/roguelike/route_map.tscn`, and load `battle.tscn`. The back button SHALL return to `route_map.tscn` without starting battle.

#### Scenario: Roguelike party setup uses RunState reserve
- **WHEN** party setup opens in ROGUELIKE mode with 2 units in `RunState.reserve`
- **THEN** both units appear as selectable reserve rows

#### Scenario: Confirm starts roguelike battle context
- **WHEN** the player confirms roguelike party setup
- **THEN** `GameState.current_mode` is ROGUELIKE, `battle_context` contains `run_node_id`, `enemies`, `map_template`, `deploy_list`, and `return_scene_path` points to route map

### Requirement: GameState supports roguelike battle context

`GameState` SHALL provide `start_roguelike_battle(node_id, enemies, map_template, is_elite, is_boss, deploy_list)` that sets `current_mode = ROGUELIKE`, populates `battle_context` with the provided fields, and sets `return_scene_path` to the route map scene path.

#### Scenario: start_roguelike_battle sets context fields
- **WHEN** `start_roguelike_battle("L3N2", enemies, "T_FOREST", true, false, deploy_list)` is called
- **THEN** `current_mode == ROGUELIKE`, `battle_context.run_node_id == "L3N2"`, `battle_context.map_template == "T_FOREST"`, `battle_context.is_elite == true`, and `battle_context.deploy_list` matches deploy_list

### Requirement: Battle scene handles roguelike mode end and routing

`battle_scene.gd` SHALL load enemy groups and map template from `GameState.battle_context` when `current_mode == ROGUELIKE` (instead of campaign stage JSON). On battle end it SHALL call `RunManager.consume_battle_result(node_id, result, payload)` and route as follows: if the result indicates run victory (boss won) or run defeat (hero dead), load `run_summary.tscn`; otherwise return to `return_scene_path` (route map) after the standard delay.

#### Scenario: Roguelike battle uses picker enemies not stage JSON
- **WHEN** a roguelike battle starts with `battle_context.enemies` and `map_template`
- **THEN** the battle loads those enemies on the specified map template

#### Scenario: Non-terminal roguelike win returns to route map
- **WHEN** the player wins a normal `battle` node and hero survives
- **THEN** `consume_battle_result` marks the node complete, saves, and the scene returns to `route_map.tscn`

#### Scenario: Boss win opens run summary
- **WHEN** the player wins a `boss` node
- **THEN** the game loads `run_summary.tscn` with victory presentation

#### Scenario: Hero death opens run summary
- **WHEN** HERO HP reaches 0 during a roguelike battle
- **THEN** `hero_dead` is set, the game loads `run_summary.tscn` with defeat presentation

### Requirement: Run summary ends the run and returns to main menu

`scenes/roguelike/run_summary.tscn` SHALL display victory or defeat based on run outcome, show a brief summary (seed, layers reached), and provide **返回主菜单** that calls `RunManager.clear()` and loads `main_menu.tscn`.

#### Scenario: Victory summary clears run
- **WHEN** the player views a victory summary and chooses return to main menu
- **THEN** `run.active` is false and main menu loads

#### Scenario: Defeat summary clears run
- **WHEN** the player views a defeat summary and chooses return to main menu
- **THEN** `run.active` is false and main menu loads
