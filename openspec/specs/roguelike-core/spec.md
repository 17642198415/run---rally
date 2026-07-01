# roguelike-core

## Purpose

Core data types and utilities for the roguelike Run mode. This capability covers the in-memory state representation, route graph generation, enemy group selection, run lifecycle management, and persistence for roguelike mode. UI rendering and battle integration are covered by other capabilities.

## Requirements

### Requirement: RunState supports in-memory roguelike run state with serialization

The system SHALL provide a `RunState` class (GDScript, `class_name RunState extends Resource`) that holds all in-memory state of a single roguelike run. Fields: `seed` (int), `current_layer` (int, 1-based), `route_graph` (Array of layer dicts), `selected_path` (Array[String] of node IDs in traversal order), `party` (Array[Dictionary] of serialized BattleUnit), `reserve` (Array[Dictionary] of serialized BattleUnit), `balls` (int, initial 3), `coins` (int, initial 0), `hero_dead` (bool, initially false), `pending_rewards` (Array of reward dict snapshots, initially empty), `pending_reward_is_boss` (bool, initially false). It SHALL provide `serialize() -> Dictionary` and `static func deserialize(d: Dictionary) -> RunState` for round-trip save/load, and `mark_node_completed(node_id: String) -> void` / `advance_layer() -> void` for lifecycle progression.

#### Scenario: Fresh RunState has correct defaults
- **WHEN** `RunState.new()` is created with default constructor
- **THEN** `balls == 3`, `coins == 0`, `current_layer == 1`, `hero_dead == false`, `party == []`, `reserve == []`, `pending_rewards == []`, `pending_reward_is_boss == false`

#### Scenario: Serialize-deserialize round-trip preserves all fields
- **WHEN** a populated RunState is serialized via `.serialize()`, then deserialized via `RunState.deserialize(d)`
- **THEN** the deserialized state `.serialize()` is identical to the original serialized dictionary

#### Scenario: Marking a node completed updates selected_path and may advance layer
- **WHEN** `mark_node_completed("L1N1")` is called
- **THEN** `"L1N1"` is appended to `selected_path`, and if the route graph for layer 1 has all reachable nodes marked, `advance_layer()` increments `current_layer`

#### Scenario: Legacy deserialize without pending_rewards defaults safely
- **WHEN** `RunState.deserialize` receives a dictionary without `pending_rewards` or `pending_reward_is_boss`
- **THEN** the resulting state has `pending_rewards == []` and `pending_reward_is_boss == false`

### Requirement: RouteGenerator produces seed-reproducible 6-layer route with constraints

The system SHALL provide a `RouteGenerator` static utility that reads `data/route/layer_pools.json` and produces a `route_graph` array given a seed (int) and an optional `RandomNumberGenerator`. The generator SHALL produce exactly 6 layers. Each layer SHALL have `pick_count` nodes drawn (without replacement) from the layer's pool. Layer 6 SHALL have exactly 1 node of type `boss`. The generator SHALL enforce the constraint: among layers 3 and 5, at least one node SHALL be of type `elite` or `shop`; if the random draw does not satisfy this, a re-draw SHALL occur (maximum 32 retries, then force-promote layer 3's first node to `elite`).

#### Scenario: Same seed produces identical route graph
- **WHEN** `RouteGenerator.generate(42)` is called twice
- **THEN** both results have identical `route_graph` structure, node IDs, and types

#### Scenario: Different seeds produce different route graphs (with high probability)
- **WHEN** `RouteGenerator.generate(s1)` and `RouteGenerator.generate(s2)` are called with different seeds, repeated 50 times
- **THEN** at least 45 of the 50 pairs produce non-identical route_graph structures

#### Scenario: Layer 6 always has exactly one node of type boss
- **WHEN** `RouteGenerator.generate(s)` is called for any seed
- **THEN** layer 6 has exactly 1 node and that node's `type` is `"boss"`

#### Scenario: Constraint "layer 3 or 5 has elite or shop" holds for 100 different seeds
- **WHEN** `RouteGenerator.generate(s)` is called for 100 distinct seeds
- **THEN** for every seed, at least one node in layer 3 or layer 5 has type `"elite"` or `"shop"`

#### Scenario: Force-promote fallback works when no valid config possible
- **WHEN** a layer pool config makes it impossible to satisfy the constraint (edge case)
- **THEN** the generator does not crash and layer 3's first node is set to `"elite"` after retry exhaustion

### Requirement: EnemyGroupPicker returns weighted random enemy group for a layer

The system SHALL provide an `EnemyGroupPicker` static utility that consumes a layer number, an `is_elite` flag, an `is_boss` flag, and a `RandomNumberGenerator`. It SHALL read `data/enemy_groups/<layer>-<difficulty>.json` (e.g., `layer_1_2_normal.json`, `layer_6_boss.json`) and return a group dict with keys `map_template` (string) and `enemies` (Array[Dictionary]). Selection SHALL use seeded weighted random (cumulative weight + `randf_range`). If the requested file is missing, the picker SHALL `push_error` and return an empty default group.

#### Scenario: Normal layer 1 battle returns valid group with map template
- **WHEN** `EnemyGroupPicker.pick(1, false, false, rng)` is called
- **THEN** the return value has a non-empty `map_template` string and an `enemies` array with at least 1 entry

#### Scenario: Layer 6 boss pick returns boss group
- **WHEN** `EnemyGroupPicker.pick(6, false, true, rng)` is called
- **THEN** the returned group's `enemies` contain at least one entry with `template` that corresponds to a boss unit

#### Scenario: Same seed and same picker input produces same result
- **WHEN** `EnemyGroupPicker.pick(1, false, false, same_rng)` is called twice with identically seeded RNGs
- **THEN** both return values are structurally identical (same map_template, same enemies with same template IDs and spawn coords)

### Requirement: Data assets for roguelike routes and enemy groups exist

The project SHALL include the following data files:
- `data/route/layer_pools.json`: 6-layer pool config with per-layer `pool`, `pick_count`, `choose`, and global constraints
- `data/route/node_types.json`: node type metadata (type id, display icon/emoji, color hex, label)
- `data/enemy_groups/layer_1_2_normal.json`: groups for layers 1-2 normal battles
- `data/enemy_groups/layer_3_4_normal.json`: groups for layers 3-4 normal battles
- `data/enemy_groups/layer_3_4_elite.json`: groups for layers 3-4 elite battles
- `data/enemy_groups/layer_5_elite.json`: groups for layer 5 elite battles
- `data/enemy_groups/layer_6_boss.json`: groups for layer 6 boss battle
- `data/map_templates/T_FOREST.json`: forest-themed 10x10 map template
- `data/map_templates/T_MIX.json`: mixed-terrain 10x10 map template

#### Scenario: All roguelike data files load via DataLoader conventions
- **WHEN** the game loads in headless mode and DataLoader initializes
- **THEN** `FileAccess.file_exists("res://data/route/layer_pools.json")` is true, and all enemy group files exist at their expected paths

#### Scenario: layer_pools.json structure is parseable
- **WHEN** `layer_pools.json` is loaded and parsed
- **THEN** it SHALL contain a `layers` array with exactly 6 entries; each entry SHALL have integer keys `layer`, `pick_count`, `choose`, and a string array `pool`

#### Scenario: T_FOREST and T_MIX are valid 10x10 map templates
- **WHEN** `T_FOREST.json` and `T_MIX.json` are loaded
- **THEN** each has `width == 10`, `height == 10`, a 10x10 `terrain` integer array, `deploy_zones.player` with 6 entries, and `deploy_zones.enemy` with 4 entries

### Requirement: RunManager autoload manages run lifecycle and persistence

The system SHALL provide a `RunManager` autoload (registered in project.godot) with the following public interface:
- `start_new_run(seed: int) -> void`: generates a route via RouteGenerator, creates a new RunState with initial HERO-only party, stores it internally
- `get_state() -> RunState`: returns the current RunState (or null if no active run)
- `save() -> bool`: serializes current RunState into `SaveManager.load_meta()` under `run` key and writes to disk
- `load_from_meta() -> bool`: if saved `run.active` is true, deserializes and restores RunState
- `clear() -> void`: sets internal RunState to null and writes `run.active = false` to save meta
- `consume_battle_result(node_id: String, result: String, payload: Dictionary) -> Dictionary`: processes post-battle state updates and returns `{"run_ended": bool, "victory": bool, "pending_rewards": bool}` where `victory` is true only for boss clear
- `complete_event_node(node_id: String) -> void`: marks a non-battle node complete, advances layer, and saves
- `get_pending_rewards() -> Array`, `apply_reward_choice(reward_id: String, target_unit_id: String = "") -> bool`, `has_pending_rewards() -> bool`: reward picker integration

On player victory (`result == "player"`), `consume_battle_result` SHALL award coins (`+8` normal, `+15` if `is_elite`, `+0` on boss), call `RunState.mark_node_completed(node_id)`, sync surviving deploy units back to `reserve`, and call `save()`. When victory occurs on an elite or boss node, it SHALL additionally roll three rewards via `RewardPool.pick_three`, store them in `state.pending_rewards`, set `state.pending_reward_is_boss` from payload `is_boss`, and set return field `pending_rewards=true`. On hero death it SHALL set `hero_dead = true`, save, and return `run_ended=true, victory=false, pending_rewards=false`. On boss victory it SHALL mark the node, save, return `run_ended=true, victory=true`, and `pending_rewards=true` when rewards were rolled.

The `RunManager` SHALL handle the case where `SaveManager` returns an old save file without the `run` key gracefully (treated as no active run). The `RunManager` SHALL NOT directly change scenes or UI; scene routing remains in battle/UI layers.

#### Scenario: Starting a new run sets a valid non-null state
- **WHEN** `RunManager.start_new_run(42)` is called
- **THEN** `get_state()` returns a non-null RunState with `seed == 42` and `current_layer == 1`

#### Scenario: Save and load round-trip preserves run state
- **WHEN** a run is started, then saved via `save()`, in-memory state is cleared, then `load_from_meta()` succeeds
- **THEN** `get_state().serialize()` matches the original state before save

#### Scenario: Clear deactivates run and resets state
- **WHEN** `clear()` is called after a run has started
- **THEN** `get_state() == null` and loading save meta shows `run.active == false`

#### Scenario: Legacy save compatibility
- **WHEN** `SaveManager.load_meta()` returns a dictionary with no `run` key
- **THEN** `RunManager.load_from_meta()` returns false and `get_state()` remains null (no crash)

#### Scenario: consume_battle_result marks node on normal win
- **WHEN** `consume_battle_result("L1N1", "player", payload_with_survivors)` is called for a non-boss, non-elite node
- **THEN** `"L1N1"` is in `selected_path`, `save()` persists, return value is `run_ended=false, pending_rewards=false`

#### Scenario: consume_battle_result awards coins on normal win
- **WHEN** `consume_battle_result` succeeds for a non-elite battle with `coins == 5`
- **THEN** `get_state().coins == 13`

#### Scenario: Elite victory rolls pending rewards
- **WHEN** `consume_battle_result` succeeds with `is_elite=true` and `is_boss=false`
- **THEN** return value has `pending_rewards=true` and `get_pending_rewards().size() == 3`

#### Scenario: Normal victory does not roll rewards
- **WHEN** `consume_battle_result` succeeds with `is_elite=false` and `is_boss=false`
- **THEN** return value has `pending_rewards=false` and `get_pending_rewards()` is empty

#### Scenario: complete_event_node advances layer without battle
- **WHEN** `complete_event_node("L2N1")` is called with `current_layer == 2`
- **THEN** `"L2N1"` is in `selected_path`, `current_layer == 3`, and save persists

#### Scenario: consume_battle_result sets hero_dead on hero death
- **WHEN** `consume_battle_result` is called with payload indicating HERO hp <= 0
- **THEN** `get_state().hero_dead == true`, return value is `run_ended=true, victory=false, pending_rewards=false`

#### Scenario: consume_battle_result ends run on boss win with pending rewards
- **WHEN** `consume_battle_result` is called for a boss node with `result == "player"`
- **THEN** return value is `run_ended=true, victory=true, pending_rewards=true` and state is saved

### Requirement: SaveManager default save includes run section

The `SaveManager.get_default_save()` SHALL include a `run` key in the returned dictionary with structure `{"active": false, "state": null}`. The `merge_with_defaults` function SHALL ensure this key exists in loaded save data even when reading old save files that predate this change. The `run.state` sub-dictionary SHALL NOT be recursively merged (it is written and read as a whole unit).

#### Scenario: Fresh default save has run section
- **WHEN** `SaveManager.get_default_save()` is called
- **THEN** the returned dict includes `"run": {"active": false, "state": null}`

#### Scenario: Legacy save without run key gets merged with default
- **WHEN** `merge_with_defaults({"campaign": {"stage_01": "cleared"}})` is called
- **THEN** the result includes `"run": {"active": false, "state": null}` alongside the existing `campaign` data

### Requirement: MetaManager stats are populated on roguelike run end

The `MetaManager` SHALL integrate with top-level `stats` in `user://save_meta.json` using keys `runs_started`, `runs_won`, `runs_lost`, `deepest_layer`, `total_captures`, and `total_coins_spent` (each int, default 0 when missing). `MetaManager.record_run_end(state, victory)` SHALL update these counters when a roguelike run ends and then call `evaluate_unlocks`. `SaveManager.get_default_save()` SHALL include `"stats": {}` with merge filling missing stat keys as zero.

#### Scenario: Fresh save has zero stats
- **WHEN** `SaveManager.load_meta()` is called on a fresh save
- **THEN** all stat keys are present with value 0 after merge

#### Scenario: Run end writes stats to save
- **WHEN** a roguelike run ends and `MetaManager.record_run_end` is invoked
- **THEN** `SaveManager.load_meta().stats.runs_started` increments and the file is persisted

### Requirement: RunManager applies Meta on new run and records stats on end

`RunManager.start_new_run` SHALL query `MetaManager.get_start_balls_bonus()` when initializing `RunState.balls`. When a run ends (`clear()` or transition to run summary after BOSS victory), `RunManager` SHALL call `MetaManager.record_run_end` before clearing active run state so stats and unlock evaluation are persisted.

#### Scenario: start_new_run uses Meta ball bonus
- **WHEN** `META_BALL` is unlocked and `RunManager.start_new_run(42)` is called
- **THEN** the new `RunState.balls` equals 4

#### Scenario: clear records failed run stats
- **WHEN** `RunManager.clear()` is called while a run is active with hero dead
- **THEN** `stats.runs_lost` increases and `run.active` becomes false
