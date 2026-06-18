# chapter-4-turns-deploy-and-ai Specification

## Purpose

Defines chapter 4 turn-based combat for the Godot tactics monster demo: deploy phase, turn manager (DEPLOY → PLAYER_TURN → ENEMY_TURN → BATTLE_END), enemy AI (lowest-HP-in-range / move-toward-nearest / wait), stage JSON driver (`DEBUG_01`), turn UI (round banner + end-turn / confirm-deploy buttons), and headless unit test coverage. Achieves milestone **M1**: a complete `DEBUG_01` battle from deploy to victory or defeat.

## Requirements

### Requirement: TurnManager drives deploy and turn phases
The system SHALL provide a `TurnManager` with phases `DEPLOY`, `PLAYER_TURN`, `ENEMY_TURN`, and `BATTLE_END`, tracking `round_number` (starting at 1), `active_unit`, `player_queue`, and `enemy_queue`. Battle end SHALL be reached when one side has no units alive for battle (treating `downed_capturable` enemies as not alive).

#### Scenario: Deploy confirms into player turn
- **WHEN** the player completes deployment and confirms
- **THEN** `current_phase` becomes `PLAYER_TURN`, `round_number` is `1`, and the first living player unit becomes `active_unit`

#### Scenario: End turn switches to enemy
- **WHEN** the player presses end turn during `PLAYER_TURN`
- **THEN** `current_phase` becomes `ENEMY_TURN` and player units can no longer be controlled until the enemy turn completes

#### Scenario: Enemy turn completion starts next player round
- **WHEN** all enemy units have acted in `ENEMY_TURN` and both sides still have living units
- **THEN** `current_phase` becomes `PLAYER_TURN`, `round_number` increments by `1`, and player queues reset for a new player round

#### Scenario: Annihilation or full-downed enemy ends battle
- **WHEN** `BattleController.check_victory(units)` returns `"player"` or `"enemy"`, including the case where every wild enemy is `downed_capturable`
- **THEN** `current_phase` becomes `BATTLE_END`

### Requirement: Deploy phase places player units only in player deploy zones

The system SHALL load player unit templates from stage JSON **or** from `GameState.battle_context.deploy_list` when the stage specifies `player.party_source == "campaign_setup"`, and allow placement only on unoccupied cells in `deploy_zones.player` before battle starts.

#### Scenario: Out-of-zone placement is rejected
- **WHEN** the player clicks a cell outside `deploy_zones.player` during deploy
- **THEN** no unit is placed on that cell

#### Scenario: Enemy units spawn at configured coordinates
- **WHEN** deployment is confirmed for a stage with `enemy_units`
- **THEN** each `enemy_units` entry spawns at its `spawn` position and is registered on the grid

#### Scenario: Confirm requires all player templates placed
- **WHEN** not all player unit templates from the pending deploy list have been placed
- **THEN** the confirm-deploy action is disabled or rejected

#### Scenario: Campaign multi-unit deploy list is supported
- **WHEN** deploy list contains HERO and two reserve templates and the player places all three
- **THEN** confirm deploy is allowed and all three units join the battle

### Requirement: Player turn operates units sequentially
During `PLAYER_TURN`, the system SHALL allow the player to control only `active_unit` when it is a living player unit, and SHALL advance to the next living player unit after that unit completes an action (move, attack, skill, or wait).

#### Scenario: Only active unit accepts commands
- **WHEN** the player selects a friendly unit that is not `active_unit` during `PLAYER_TURN`
- **THEN** no action bar commands are issued for that unit

#### Scenario: End turn locks player input
- **WHEN** the player ends the turn
- **THEN** no further player unit commands are accepted until `ENEMY_TURN` completes

### Requirement: Enemy AI attacks lowest HP in range or moves toward nearest player
The system SHALL implement `EnemyAI` so that each enemy unit, on its turn, attacks the lowest-HP living player in basic attack range if any exist; otherwise moves toward the nearest living player using up to its MOV; otherwise waits. `downed_capturable` enemy units SHALL be skipped entirely when building the enemy action queue.

#### Scenario: AI prefers lowest HP target in range
- **WHEN** two player units are within attack range and one has lower current HP
- **THEN** the AI chooses the lower-HP unit as the attack target

#### Scenario: AI moves toward nearest player when out of range
- **WHEN** no player is within attack range
- **THEN** the AI moves along a reachable path that minimizes Manhattan distance to the nearest player

#### Scenario: AI waits when no move improves position
- **WHEN** the enemy cannot attack and has no reachable cell that reduces distance to the nearest player
- **THEN** the AI performs a wait action

#### Scenario: Downed capturable enemies are skipped
- **WHEN** the enemy queue is built for `ENEMY_TURN`
- **THEN** any unit with `downed_capturable == true` is excluded from the queue and never becomes `active_unit`

### Requirement: Stage JSON drives debug battle setup

The system SHALL load stage JSON by id from `data/stages/`. For debug acceptance, `DEBUG_01` SHALL remain playable when `battle.tscn` is run directly with `GameState.current_mode == NONE`. For campaign, the active stage id and deploy list SHALL come from `GameState.stage_id` and `GameState.battle_context` set by party setup before battle loads.

#### Scenario: DEBUG_01 loads map and factions
- **WHEN** battle starts with stage `DEBUG_01` in non-campaign mode
- **THEN** the grid is built from `test_grid.json`, player templates include `HERO`, and enemy templates include at least `M01` and `M02` at configured spawn points

#### Scenario: Campaign stage uses GameState stage id
- **WHEN** `GameState.start_campaign_battle("stage_01", deploy_list)` was called before battle loads
- **THEN** battle uses `stage_01` data and `deploy_list` for player deploy templates

#### Scenario: Full battle completes without deadlock
- **WHEN** a stage battle is played from deploy to `BATTLE_END`
- **THEN** the battle reaches `"player"` or `"enemy"` victory without soft-locking input or AI

### Requirement: Turn UI shows round and end-turn control
The battle scene SHALL display the current round number and active unit name, and SHALL provide an end-turn button during `PLAYER_TURN` plus a confirm-deploy control during `DEPLOY`.

#### Scenario: Round number updates
- **WHEN** a new player round begins after an enemy turn
- **THEN** the HUD shows the incremented round number

#### Scenario: End turn button visible on player turn
- **WHEN** `current_phase` is `PLAYER_TURN`
- **THEN** the action bar or HUD exposes an end-turn control

### Requirement: GameState reflects battle phase
The `GameState` autoload SHALL mirror the battle phase (`DEPLOY`, `PLAYER_TURN`, `ENEMY_TURN`, `END`) while a stage battle is running.

#### Scenario: Phase sync on deploy start
- **WHEN** a stage battle enters deploy
- **THEN** `GameState.current_battle_phase` is `DEPLOY`

#### Scenario: Phase sync on battle end
- **WHEN** `TurnManager` enters `BATTLE_END`
- **THEN** `GameState.current_battle_phase` is `END`

### Requirement: Chapter 4 has headless unit tests for turn deploy and AI
The project SHALL include headless tests for turn phase transitions, deploy zone validation, and enemy AI target selection.

#### Scenario: Chapter 4 unit tests pass
- **WHEN** `test_turn_manager.gd`, `test_deploy_phase.gd`, and `test_enemy_ai.gd` are executed
- **THEN** all pass alongside chapter 1–3 tests with exit code zero
