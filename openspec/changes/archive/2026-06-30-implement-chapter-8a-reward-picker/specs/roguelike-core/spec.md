## MODIFIED Requirements

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
