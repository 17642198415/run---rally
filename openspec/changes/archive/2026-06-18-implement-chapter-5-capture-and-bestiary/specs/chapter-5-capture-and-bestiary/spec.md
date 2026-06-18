## ADDED Requirements

### Requirement: Wild defeated units enter downed_capturable state

The system SHALL mark wild enemy units (`is_player == false` and not `boss`) whose `hp` reaches `0` as `downed_capturable` instead of removing them from `Grid` and the active units list. Such units SHALL not act in `ENEMY_TURN`, SHALL retain grid occupancy until battle end, and SHALL count as defeated for `BattleController.check_victory`.

#### Scenario: Wild M01 reduced to 0 hp becomes downed
- **WHEN** a wild `M01` unit takes damage that brings `hp` to `0`
- **THEN** the unit's `downed_capturable` is `true`, it is still present in `Grid.cells[unit.grid_pos].occupant`, and it is not removed from the active `units` list

#### Scenario: Downed unit cannot act on enemy turn
- **WHEN** `ENEMY_TURN` builds its action queue
- **THEN** any `downed_capturable` unit is skipped and never assigned as `active_unit`

#### Scenario: Downed enemies count as defeated for victory
- **WHEN** every enemy unit is either dead or `downed_capturable`
- **THEN** `BattleController.check_victory(units)` returns `"player"`

### Requirement: CaptureSystem computes capture rate and four-tier display

The system SHALL provide `CaptureSystem` with a static `compute_rate(unit, event_bonus)` returning a probability in `[0.05, 0.95]`, and `tier_for_rate(rate)` returning one of `"high"`, `"mid"`, `"low"`, `"vlow"`. The probability formula SHALL use the unit template's `base_capture_rate` and a hp factor derived from `1.0 - clamp(hp/max_hp, 0.0, 1.0)`.

#### Scenario: Downed unit shows higher tier than full hp
- **WHEN** the same `M01` (`base_capture_rate = 0.45`) is queried at full hp vs `downed_capturable`
- **THEN** the rate at downed state is strictly greater than the rate at full hp

#### Scenario: Tier thresholds match boundaries
- **WHEN** `tier_for_rate` is called with `0.50`, `0.30`, `0.20`, `0.10`
- **THEN** results are `"high"`, `"mid"`, `"low"`, `"vlow"` respectively

#### Scenario: Rate is clamped within [0.05, 0.95]
- **WHEN** any inputs would produce a rate outside `[0.05, 0.95]`
- **THEN** the returned rate is clamped to that range

### Requirement: Capture attempt consumes one ball and resolves success or failure

`CaptureSystem.attempt(unit, balls_remaining, event_bonus, rng)` SHALL deduct one ball, roll against the computed rate using the supplied `RandomNumberGenerator`, and return a result containing `success`, `rate`, `tier`, and `balls_remaining_after`.

#### Scenario: Successful capture consumes ball and returns success
- **WHEN** `attempt` is called with seeded RNG that rolls below the rate and `balls_remaining = 3`
- **THEN** the result has `success = true`, `balls_remaining_after = 2`

#### Scenario: Failed capture still consumes ball
- **WHEN** seeded RNG rolls above the rate and `balls_remaining = 3`
- **THEN** the result has `success = false`, `balls_remaining_after = 2`

#### Scenario: Zero balls rejects attempt
- **WHEN** `attempt` is called with `balls_remaining = 0`
- **THEN** the result has `success = false` and `balls_remaining_after = 0` and an `error = "no_balls"` field

### Requirement: ActionBar exposes Capture button when an adjacent downed wild unit exists

During `PLAYER_TURN`, the `ActionBar` SHALL show a `[捕捉]` button that is enabled if and only if the currently selected `active_unit` has at least one orthogonally adjacent (Manhattan distance `1`) `downed_capturable` wild unit and `balls_remaining > 0`.

#### Scenario: Adjacent downed enables capture
- **WHEN** the player's active unit stands at `(2,4)` and a `downed_capturable` `M01` is at `(2,5)` with `balls_remaining = 2`
- **THEN** the `[捕捉]` button is enabled

#### Scenario: Diagonal does not count as adjacent
- **WHEN** the only `downed_capturable` enemy is at `(3,5)` while the active unit is at `(2,4)`
- **THEN** the `[捕捉]` button is disabled

#### Scenario: Zero balls disables capture
- **WHEN** an adjacent `downed_capturable` exists but `balls_remaining = 0`
- **THEN** the `[捕捉]` button is disabled

### Requirement: Capture attempt counts as the active unit's action

When the player confirms a capture attempt via `CapturePrompt`, the system SHALL deduct the ball, resolve success/failure, mark the active unit as having acted (advancing the player queue), and write any persistence side effects regardless of success.

#### Scenario: Successful capture advances active unit
- **WHEN** the player confirms a capture and rolls success
- **THEN** the captured wild unit is removed from `Grid` and `units`, the player's `active_unit` is marked acted, and the next player unit (or end of player turn) is selected

#### Scenario: Failed capture also advances active unit
- **WHEN** the player confirms a capture and rolls failure
- **THEN** the wild unit remains `downed_capturable` on its cell and the player's `active_unit` still completes its action

### Requirement: BestiaryManager tracks discovered and caught states

The autoload `BestiaryManager` SHALL maintain a per-template entry with `discovered: bool` and `caught: bool`. Wild units encountered at battle start SHALL flip `discovered = true` for their `template_id`. Successful captures SHALL flip `caught = true` (and `discovered = true` if absent).

#### Scenario: Battle start marks wild templates discovered
- **WHEN** `DEBUG_01` battle begins with wild `M01` and `M02`
- **THEN** `BestiaryManager.is_discovered("M01")` and `is_discovered("M02")` both return `true`

#### Scenario: Successful capture marks template caught
- **WHEN** the player successfully captures a wild `M01`
- **THEN** `BestiaryManager.is_caught("M01")` returns `true`

#### Scenario: Failed capture does not mark caught
- **WHEN** the player attempts a capture and fails
- **THEN** `BestiaryManager.is_caught(template_id)` remains `false`

### Requirement: PartyManager owns the reserve list of captured units

The autoload `PartyManager` SHALL maintain `reserve: Array[Dictionary]` with each entry storing `{unit_id, template_id, hp, max_hp, skill_id}`. New captures SHALL append to `reserve` with a unique `unit_id` formatted `"P_<template_id>_<index>"`. The reserve cap SHALL be `MAX_RESERVE = 12`.

#### Scenario: Capture appends entry with unique id
- **WHEN** a wild `M01` is captured into an empty reserve
- **THEN** `reserve` contains one entry with `template_id = "M01"` and `unit_id = "P_M01_001"`

#### Scenario: Reserve full rejects new capture
- **WHEN** reserve already contains `MAX_RESERVE` entries and a successful roll occurs
- **THEN** `PartyManager.can_accept()` returns `false` and the captured unit is not appended (capture is treated as failed for party purposes; ball is still consumed)

### Requirement: SaveManager persists bestiary, party, stats, campaign, meta in user://save_meta.json

`SaveManager.save_meta(data)` SHALL write a JSON object containing exactly the top-level keys `bestiary`, `party`, `stats`, `campaign`, `meta`. `SaveManager.load_meta()` SHALL return such an object (filling missing keys from defaults).

#### Scenario: Round-trip preserves bestiary and party
- **WHEN** a save object with a `caught` `M01` and one reserve entry is saved and then loaded
- **THEN** the loaded object contains `bestiary.M01.caught == true` and `party.reserve[0].template_id == "M01"`

#### Scenario: Missing keys default safely
- **WHEN** an existing save file has only `bestiary`
- **THEN** `load_meta()` returns an object with `party.reserve = []`, `stats = {}`, `campaign = {}`, `meta.unlocked = []`

#### Scenario: Capture success triggers save
- **WHEN** a successful capture is resolved in battle
- **THEN** `SaveManager.save_meta(...)` is invoked with updated `bestiary` and `party` reflecting the capture

### Requirement: Stage JSON drives initial ball count

`BattleScene._begin_stage()` SHALL read `stage.player_ball_count` (default `3` if missing) and store it on `GameState.current_battle.balls_remaining`. The HUD SHALL display the remaining ball count, and capture attempts SHALL decrement it.

#### Scenario: DEBUG_01 starts with 3 balls
- **WHEN** `DEBUG_01` battle begins
- **THEN** `GameState.current_battle.balls_remaining == 3` and the HUD shows `球: 3`

#### Scenario: Successful capture decrements display
- **WHEN** a capture attempt resolves
- **THEN** the HUD ball count drops by `1` regardless of success

### Requirement: Chapter 5 has headless unit tests for capture, bestiary, party, save

The project SHALL include headless tests for:
- `CaptureSystem` rate formula, tier thresholds, attempt success/failure with seeded RNG and ball deduction.
- `BestiaryManager` discovered/caught transitions.
- `PartyManager` reserve append, unique id, and `MAX_RESERVE` rejection.
- `SaveManager` round-trip and default-merge.
- Combat-side regression: a wild unit hit to `0` hp keeps grid occupancy and is not in `BattleController.alive_units(units, false)`.

#### Scenario: Chapter 5 unit tests pass headlessly
- **WHEN** `tests/run_all_tests.ps1` is executed
- **THEN** the new tests `test_capture_system.gd`, `test_bestiary_manager.gd`, `test_party_manager.gd`, `test_save_manager.gd`, and the regression case in `test_battle_setup.gd` all pass with chapters 1-4 still green
