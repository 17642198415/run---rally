## MODIFIED Requirements

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
