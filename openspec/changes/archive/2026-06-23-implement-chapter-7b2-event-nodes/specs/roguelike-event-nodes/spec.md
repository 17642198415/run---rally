## ADDED Requirements

### Requirement: Rest node offers heal or sacrifice choice

`scenes/roguelike/rest.tscn` SHALL present two options when entered from the route map: **全队恢复 30% HP** (applies to all units in `RunState.party` and `RunState.reserve`, capping at `max_hp`), or **献祭 1 只备用宠换全队满血** (player selects one `reserve` unit to remove; all remaining party and reserve units set to `hp = max_hp`). If `reserve` is empty, the sacrifice option SHALL be hidden or disabled. Confirming either option and choosing **离开营地** SHALL call `RunManager.complete_event_node(run_node_id)` and return to `route_map.tscn`.

#### Scenario: Heal 30 percent applies to party and reserve
- **WHEN** the player chooses heal 30% with HERO at 10/20 HP and one reserve at 6/12 HP
- **THEN** HERO becomes 16/20 and reserve becomes 9/12 (rounded down), then node completes on leave

#### Scenario: Sacrifice removes one reserve and full heals others
- **WHEN** the player sacrifices reserve unit `P_M01_001` with two other units damaged
- **THEN** `P_M01_001` is removed from reserve and all other units have `hp == max_hp`

#### Scenario: Empty reserve hides sacrifice
- **WHEN** `RunState.reserve` is empty on rest screen
- **THEN** sacrifice option is not available

### Requirement: Shop node displays three seeded purchasable items

`scenes/roguelike/shop.tscn` SHALL roll exactly 3 items from `data/route/shop_catalog.json` using a seed derived from `RunState.seed`, node id, and layer (reproducible per visit). Each item SHALL show display name and coin cost. Purchasing SHALL deduct `RunState.coins` when affordable and apply the item effect (`add_ball`, `heal_all_pct`, or `add_random_reserve`). **离开商店** SHALL call `RunManager.complete_event_node` and return to the route map.

#### Scenario: Same seed produces same three shop items
- **WHEN** `ShopCatalog.roll_3` is called twice with the same seed inputs
- **THEN** both results list the same three item ids in order

#### Scenario: Purchase deducts coins and adds ball
- **WHEN** the player buys an `add_ball` item costing 15 coins with 20 coins available
- **THEN** `RunState.coins == 5` and `RunState.balls` increases by 1

#### Scenario: Cannot buy when insufficient coins
- **WHEN** the player attempts to buy a 25-coin item with 10 coins
- **THEN** purchase is rejected and coins unchanged

### Requirement: Capture event node launches high-rate capture battle

Clicking a `capture_event` node on the current layer SHALL load enemies from `data/enemy_groups/capture_event.json` (1-2 low-tier units), set `GameState.battle_context.capture_event_bonus` to a positive value (default 0.35), and proceed through roguelike party setup into battle. On player victory, the normal `consume_battle_result` path SHALL apply and return to the route map.

#### Scenario: Capture event sets bonus in battle context
- **WHEN** a capture_event node is entered
- **THEN** `battle_context.capture_event_bonus` is 0.35 and enemies come from capture_event.json

#### Scenario: Battle uses elevated capture bonus
- **WHEN** a roguelike battle starts from a capture_event node
- **THEN** `battle_scene` capture rate calculation uses `capture_event_bonus` instead of default 0.0

#### Scenario: Capture event victory completes node
- **WHEN** the player wins the capture_event battle
- **THEN** the node id is added to `selected_path` and layer advances

### Requirement: NodeHandlers dispatches all six node types from route map

`scripts/roguelike/node_handlers.gd` SHALL provide `enter_node(node_type, node_id, layer, rng) -> String` returning the next scene path (or empty if battle prep is done in-place). It SHALL handle `battle`, `elite`, `boss`, `rest`, `shop`, and `capture_event` without the route map containing type-specific branching logic beyond calling the handler.

#### Scenario: Rest type returns rest scene path
- **WHEN** `enter_node("rest", "L2N1", 2, rng)` is called
- **THEN** the return value is `res://scenes/roguelike/rest.tscn` and pending node context is stored on GameState or RunManager

#### Scenario: Shop type returns shop scene path
- **WHEN** `enter_node("shop", "L3N2", 3, rng)` is called
- **THEN** the return value is `res://scenes/roguelike/shop.tscn`

### Requirement: Shop and capture event data files exist

The project SHALL include `data/route/shop_catalog.json` with a weighted `items` array (at least 3 distinct purchasable entries) and `data/enemy_groups/capture_event.json` with at least one group containing 1-2 enemy spawn entries and a `map_template`.

#### Scenario: Shop catalog loads with items array
- **WHEN** `shop_catalog.json` is parsed
- **THEN** it contains an `items` array with at least 3 entries each having `id`, `cost`, `effect_type`, and `weight`

#### Scenario: Capture event group file exists
- **WHEN** the game checks `res://data/enemy_groups/capture_event.json`
- **THEN** the file exists and contains groups with `enemies` and `map_template`
