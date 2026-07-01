## MODIFIED Requirements

### Requirement: RunManager autoload manages run lifecycle and persistence

The system SHALL provide a `RunManager` autoload (registered in project.godot) with the following public interface:
- `start_new_run(seed: int) -> void`: generates a route via RouteGenerator, creates a new RunState with initial HERO-only party, stores it internally
- `get_state() -> RunState`: returns the current RunState (or null if no active run)
- `save() -> bool`: serializes current RunState into `SaveManager.load_meta()` under `run` key and writes to disk
- `load_from_meta() -> bool`: if saved `run.active` is true, deserializes and restores RunState
- `clear() -> void`: sets internal RunState to null and writes `run.active = false` to save meta
- `consume_battle_result(node_id: String, result: String, payload: Dictionary) -> Dictionary`: processes post-battle state updates and returns `{"run_ended": bool, "victory": bool}` where `victory` is true only for boss clear

On player victory (`result == "player"`), `consume_battle_result` SHALL call `RunState.mark_node_completed(node_id)`, sync surviving deploy units back to `reserve` (remove dead, update HP), and call `save()`. On hero death it SHALL set `hero_dead = true`, save, and return `run_ended=true, victory=false`. On boss victory it SHALL mark the node, save, and return `run_ended=true, victory=true`. On player defeat with hero alive it SHALL sync reserve without marking the node complete.

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
- **WHEN** `consume_battle_result("L1N1", "player", payload_with_survivors)` is called for a non-boss node
- **THEN** `"L1N1"` is in `selected_path`, `save()` persists, and return value is `run_ended=false`

#### Scenario: consume_battle_result sets hero_dead on hero death
- **WHEN** `consume_battle_result` is called with payload indicating HERO hp <= 0
- **THEN** `get_state().hero_dead == true`, return value is `run_ended=true, victory=false`

#### Scenario: consume_battle_result ends run on boss win
- **WHEN** `consume_battle_result` is called for a boss node with `result == "player"`
- **THEN** return value is `run_ended=true, victory=true` and state is saved
