## MODIFIED Requirements

### Requirement: Battle scene supports 2v2 free-test combat with action bar
The `scenes/battle/battle.tscn` scene SHALL provide an action bar with move/attack/skill/wait actions, highlight valid move or attack ranges, and display victory text when one side is eliminated. When started with a stage JSON (default `DEBUG_01`), the scene SHALL run deploy and turn-based flow per chapter 4 instead of manual faction switching.

#### Scenario: Action bar shows selected unit HP
- **WHEN** the player selects the active friendly unit during `PLAYER_TURN`
- **THEN** the UI shows that unit's current and max HP

#### Scenario: Victory message appears on annihilation
- **WHEN** one side is fully eliminated
- **THEN** the HUD displays player or enemy victory text

#### Scenario: Stage mode uses turn flow
- **WHEN** `battle.tscn` runs with stage `DEBUG_01`
- **THEN** the player experiences deploy phase, sequential player turns with end-turn, and autonomous enemy turns until battle end
