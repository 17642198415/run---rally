## MODIFIED Requirements

### Requirement: Only battle elite and boss nodes on current layer are clickable

On `route_map.tscn`, a node SHALL be clickable when `node.layer == RunState.current_layer`, `node.id` is not in `selected_path`, and `node.type` is one of: `battle`, `elite`, `boss`, `rest`, `shop`, or `capture_event`. Clicking SHALL delegate to `NodeHandlers.enter_node` for scene routing or battle preparation. Completed nodes and nodes on non-current layers SHALL remain disabled.

#### Scenario: Current layer battle node opens battle flow
- **WHEN** the player clicks a `battle` node on the current layer
- **THEN** `EnemyGroupPicker.pick` is invoked for that layer and the game proceeds to roguelike party setup

#### Scenario: Current layer rest node opens rest scene
- **WHEN** the player clicks a `rest` node on the current layer
- **THEN** `rest.tscn` loads

#### Scenario: Current layer shop node opens shop scene
- **WHEN** the player clicks a `shop` node on the current layer
- **THEN** `shop.tscn` loads

#### Scenario: Current layer capture event opens capture battle flow
- **WHEN** the player clicks a `capture_event` node on the current layer
- **THEN** capture event enemies are loaded and party setup is shown before battle

#### Scenario: Completed nodes cannot be re-selected
- **WHEN** a node id is already in `selected_path`
- **THEN** that node is not clickable
