## MODIFIED Requirements

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
