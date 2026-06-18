## ADDED Requirements

### Requirement: Weapon triangle provides counter multipliers
The system SHALL implement a sword-axe-spear weapon triangle where the advantaged weapon deals ×1.2 damage, the disadvantaged weapon deals ×0.8 damage, and unrelated or `none` weapons deal ×1.0 damage.

#### Scenario: Sword counters axe
- **WHEN** `weapon_triangle.get_multiplier("sword", "axe")` is called
- **THEN** the result is `1.2`

#### Scenario: Axe is weak to sword
- **WHEN** `weapon_triangle.get_multiplier("axe", "sword")` is called
- **THEN** the result is `0.8`

#### Scenario: None weapon is neutral
- **WHEN** `weapon_triangle.get_multiplier("none", "sword")` is called
- **THEN** the result is `1.0`

### Requirement: Damage calculation uses atk, effective def, weapon and skill multipliers
The system SHALL compute damage as `max(1, (atk - effective_def) * weapon_mult * skill_mult)` where `effective_def = defender.def + terrain_def_bonus` from the defender's current cell terrain, and `weapon_mult` comes from the weapon triangle.

#### Scenario: Minimum damage is 1
- **WHEN** a weak attacker with `atk <= effective_def` attacks with neutral multipliers
- **THEN** the calculated damage is `1`

#### Scenario: Forest terrain increases effective defense
- **WHEN** the same attack is computed against a defender on `FOREST` versus `PLAIN`
- **THEN** the damage on forest is less than or equal to the damage on plain

#### Scenario: Skill multiplier increases damage
- **WHEN** `S_FIRE_CLAW` with `mult = 1.3` is used
- **THEN** damage is higher than the same attack with `skill_mult = 1.0`

### Requirement: BattleUnit holds runtime combat state
The system SHALL provide a `BattleUnit` model created from `DataLoader` templates with fields including `unit_id`, `template_id`, `is_player`, `grid_pos`, `hp`, `max_hp`, `atk`, `def`, `mov`, `weapon`, `unit_type`, `skill_id`, and `skill_cooldown_left`.

#### Scenario: Unit is constructed from template
- **WHEN** `BattleUnit.from_template("M01", is_player=true, grid_pos)` is created after `DataLoader.load_all()`
- **THEN** `hp` equals the template `stats.hp` and `skill_id` equals `S_FIRE_CLAW`

#### Scenario: Dead unit is marked when hp reaches zero
- **WHEN** damage reduces `hp` to `0` or below
- **THEN** the unit is considered dead and removed from the active unit list and grid occupancy

### Requirement: Attack range distinguishes melee and ranged units
The system SHALL allow melee attacks at Manhattan distance `1` and ranged attacks (flying units) at Manhattan distance `2` through `3`, with skill range taken from skill JSON when using skills.

#### Scenario: Melee cannot attack at distance 2
- **WHEN** a foot unit attempts a basic attack at Manhattan distance `2`
- **THEN** the target is not a valid basic-attack target

#### Scenario: Flying unit can attack across one empty cell
- **WHEN** a flying unit such as `M03` performs a basic attack at Manhattan distance `2` with clear line of distance
- **THEN** the attack is allowed

#### Scenario: Skill uses skill JSON range
- **WHEN** a unit uses `S_GUST` with `range = 3`
- **THEN** targets up to Manhattan distance `3` are valid for that skill

### Requirement: BattleController executes attacks and skills with cooldown
The system SHALL provide `BattleController` methods to perform basic attacks and skills, apply damage, tick skill cooldown after actions, and reject skill use while `skill_cooldown_left > 0`.

#### Scenario: Skill enters cooldown after use
- **WHEN** a unit uses a skill with `cooldown = 2`
- **THEN** `skill_cooldown_left` becomes `2` and the skill cannot be used again until cooldown reaches `0`

#### Scenario: Wait action ticks cooldown
- **WHEN** a unit with `skill_cooldown_left = 2` performs a wait/standby action
- **THEN** `skill_cooldown_left` decreases by `1`

### Requirement: Victory is decided by annihilation
The system SHALL expose `check_victory(units)` returning `"player"`, `"enemy"`, or `"none"` when one side has no living units.

#### Scenario: All enemies dead is player victory
- **WHEN** every unit with `is_player == false` has `hp <= 0`
- **THEN** `check_victory` returns `"player"`

#### Scenario: All player units dead is enemy victory
- **WHEN** every unit with `is_player == true` has `hp <= 0`
- **THEN** `check_victory` returns `"enemy"`

### Requirement: Battle scene supports 2v2 free-test combat with action bar
The `scenes/battle/battle.tscn` scene SHALL spawn 2 player units and 2 enemy units, allow manual switching of the active faction for testing, provide an action bar with move/attack/skill/wait actions, highlight valid move or attack ranges, and display victory text when one side is eliminated.

#### Scenario: Action bar shows selected unit HP
- **WHEN** the player selects a friendly unit in manual test mode
- **THEN** the UI shows that unit's current and max HP

#### Scenario: Victory message appears on annihilation
- **WHEN** one side is fully eliminated in the 2v2 test scene
- **THEN** the HUD displays `Player Win` or `Enemy Win`

#### Scenario: No full turn cycle is present
- **WHEN** the battle scene runs
- **THEN** there is no deploy phase, no end-turn button that auto-runs enemy AI, and no enemy AI autonomous turn

### Requirement: Chapter 3 has command-line unit tests for combat logic
The project SHALL include headless unit tests for weapon triangle, damage calculation, and battle controller victory/cooldown behavior.

#### Scenario: Combat unit tests pass
- **WHEN** the chapter 3 headless test scripts are executed
- **THEN** all tests pass with a zero exit code alongside chapter 1 and chapter 2 tests
