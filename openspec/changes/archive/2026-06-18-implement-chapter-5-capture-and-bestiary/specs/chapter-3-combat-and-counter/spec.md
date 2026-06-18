## MODIFIED Requirements

### Requirement: BattleUnit holds runtime combat state
The system SHALL provide a `BattleUnit` model created from `DataLoader` templates with fields including `unit_id`, `template_id`, `is_player`, `grid_pos`, `hp`, `max_hp`, `atk`, `def`, `mov`, `weapon`, `unit_type`, `skill_id`, `skill_cooldown_left`, and a chapter 5 capture flag `downed_capturable` (default `false`).

#### Scenario: Unit is constructed from template
- **WHEN** `BattleUnit.from_template("M01", is_player=true, grid_pos)` is created after `DataLoader.load_all()`
- **THEN** `hp` equals the template `stats.hp`, `skill_id` equals `S_FIRE_CLAW`, and `downed_capturable` is `false`

#### Scenario: Player or boss unit reduced to zero hp is removed
- **WHEN** damage reduces `hp` to `0` or below for a player unit, or for an enemy whose template has `tags` containing `"boss"`
- **THEN** the unit is considered dead and removed from the active unit list and grid occupancy (`downed_capturable` stays `false`)

#### Scenario: Wild non-boss enemy reduced to zero hp becomes downed_capturable
- **WHEN** damage reduces `hp` to `0` or below for an enemy whose template does NOT contain `"boss"` in `tags`
- **THEN** the unit's `downed_capturable` is set to `true`, and it is NOT removed from the active unit list nor from grid occupancy until battle end or successful capture

### Requirement: Victory is decided by annihilation
The system SHALL expose `check_victory(units)` returning `"player"`, `"enemy"`, or `"none"` when one side has no living units. A `downed_capturable` wild unit SHALL be treated as not-living for the purpose of this check.

#### Scenario: All enemies dead or downed is player victory
- **WHEN** every unit with `is_player == false` has `hp <= 0` OR `downed_capturable == true`
- **THEN** `check_victory` returns `"player"`

#### Scenario: All player units dead is enemy victory
- **WHEN** every unit with `is_player == true` has `hp <= 0`
- **THEN** `check_victory` returns `"enemy"`
