# chapter-6-campaign-and-menu Specification

## Purpose

Defines chapter 6 campaign mode and main menu for the Godot tactics monster demo: main menu navigation, stage select, party setup, CampaignManager progress, three campaign stages with map templates, campaign battle flow via GameState, bestiary view, and headless test coverage. Achieves milestone **M2**: a playable 3-stage campaign demo with save persistence.

## Requirements

### Requirement: Main menu provides campaign and bestiary navigation

The `scenes/main_menu.tscn` scene SHALL display a title and four navigation actions: **开始征途** (disabled or shows chapter-7-not-ready message), **战役**, **图鉴**, and **选项** (placeholder). Selecting **战役** SHALL open `stage_select.tscn`. Selecting **图鉴** SHALL open `bestiary_view.tscn`.

#### Scenario: Campaign button opens stage select
- **WHEN** the player chooses **战役** from the main menu
- **THEN** the game loads `scenes/campaign/stage_select.tscn`

#### Scenario: Roguelike entry is not available
- **WHEN** the player attempts **开始征途**
- **THEN** the action is disabled or shows a message that roguelike mode is not yet available

#### Scenario: Bestiary button opens bestiary view
- **WHEN** the player chooses **图鉴** from the main menu
- **THEN** the game loads `scenes/campaign/bestiary_view.tscn`

### Requirement: CampaignManager tracks stage unlock and clear state

The system SHALL provide a `CampaignManager` that reads and writes `campaign` inside `user://save_meta.json` with per-stage status `locked`, `unlocked`, or `cleared`. A new save SHALL have `stage_01` as `unlocked` and `stage_02` / `stage_03` as `locked`.

#### Scenario: Fresh save unlocks only stage_01
- **WHEN** no save file exists or campaign is empty
- **THEN** `stage_01` is `unlocked` and `stage_02` and `stage_03` are `locked`

#### Scenario: Clearing stage_01 unlocks stage_02
- **WHEN** the player wins `stage_01` and campaign progress is saved
- **THEN** `stage_01` becomes `cleared` and `stage_02` becomes `unlocked`

#### Scenario: Locked stage cannot be entered
- **WHEN** `stage_02` is `locked` on the stage select screen
- **THEN** the player cannot start a battle for `stage_02`

### Requirement: Stage select shows three campaign stages with status

`stage_select.tscn` SHALL list `stage_01`, `stage_02`, and `stage_03` with display names from stage JSON and visual status from `CampaignManager` (locked / unlocked / cleared). Selecting an unlocked or cleared stage SHALL proceed to party setup for that stage.

#### Scenario: Stage cards reflect campaign state
- **WHEN** `stage_01` is cleared and `stage_02` is unlocked
- **THEN** the UI shows `stage_01` as cleared and `stage_02` as enterable

#### Scenario: Entering a stage opens party setup
- **WHEN** the player selects an enterable `stage_02` card
- **THEN** `party_setup.tscn` opens with `stage_02` as the pending battle

### Requirement: Party setup selects HERO plus up to three reserve units

`party_setup.tscn` SHALL always include **HERO** as a fixed deploy member and allow selecting 0 to 3 additional units from `PartyManager.reserve`, for a maximum of 4 player units. Confirming SHALL write the selection to `GameState.battle_context.deploy_list` and start the campaign battle for the chosen stage.

#### Scenario: HERO is always in deploy list
- **WHEN** the player confirms party setup with zero reserve units selected
- **THEN** `deploy_list` contains exactly one entry for `HERO`

#### Scenario: Up to three reserve units can be added
- **WHEN** the player selects three reserve units and confirms
- **THEN** `deploy_list` contains HERO plus three reserve template entries (4 total)

#### Scenario: More than three reserve units cannot be selected
- **WHEN** the player already selected 3 reserve units
- **THEN** additional reserve units cannot be toggled on until one is deselected

### Requirement: Campaign battles use stage data and party deploy list

When `GameState.current_mode` is `CAMPAIGN`, `battle_scene.gd` SHALL load the stage JSON referenced by `GameState.stage_id`, build `player_units` for `DeployPhase` from `battle_context.deploy_list`, read `player.balls` from the stage, and spawn `enemy_units` from the stage. Debug direct-run of `battle.tscn` with `GameMode.NONE` SHALL continue to use `DEBUG_01` behavior.

#### Scenario: Campaign stage loads correct map and enemies
- **WHEN** a campaign battle starts for `stage_01`
- **THEN** the grid is built from `T_PLAIN` and enemies include two `M01` and one `M02` at configured spawns

#### Scenario: Deploy phase accepts multiple player templates
- **WHEN** `deploy_list` contains HERO and one captured `M01` and the player places both in the deploy zone
- **THEN** `DeployPhase.can_confirm()` returns true after both are placed

### Requirement: Campaign battle end returns to stage select and persists progress

On `BATTLE_END` in campaign mode, the system SHALL save `bestiary` and `party` via `SaveManager`, mark the stage `cleared` and unlock `unlock_next` on player victory, SHALL NOT remove reserve units on defeat, and SHALL return to `stage_select.tscn`.

#### Scenario: Victory updates campaign and returns to select
- **WHEN** the player wins `stage_01` in campaign mode
- **THEN** campaign progress is saved with `stage_01` cleared, `stage_02` unlocked, and the scene changes to stage select

#### Scenario: Defeat returns without clearing progress
- **WHEN** the player loses a campaign battle
- **THEN** campaign stage status is unchanged, reserve and bestiary remain intact, and the scene returns to stage select

### Requirement: Bestiary view displays eight species discovery state

`bestiary_view.tscn` SHALL display a read-only grid for unit ids `M01` through `M08`, showing discovered vs unknown and caught vs discovered-only states from `BestiaryManager`.

#### Scenario: Undiscovered species appear hidden
- **WHEN** `M05` has never been discovered
- **THEN** the bestiary cell does not reveal the species name (placeholder such as `?`)

#### Scenario: Caught species show completed state
- **WHEN** `M01` is marked caught in `BestiaryManager`
- **THEN** the `M01` cell shows caught/completed indication

### Requirement: Three campaign stages and map templates exist

The project SHALL include stage JSON files `stage_01_border_plain.json`, `stage_02_wet_edge.json`, and `stage_03_old_fort_boss.json`, and map templates `T_PLAIN.json`, `T_WET.json`, and `T_FORT.json`. Stage 3 SHALL include `BOSS_MERC` using `data/units/BOSS_MERC.json` with `tags` containing `boss` and `ai_profile: boss_default`.

#### Scenario: All three stages load via DataLoader
- **WHEN** `DataLoader.load_all()` runs
- **THEN** `get_stage("stage_01")`, `get_stage("stage_02")`, and `get_stage("stage_03")` return non-empty dictionaries

#### Scenario: BOSS_MERC is not capturable as wild
- **WHEN** `BOSS_MERC` is reduced to 0 HP in battle
- **THEN** the unit is removed or treated as non-wild boss death, not `downed_capturable`

### Requirement: Chapter 6 has headless tests for campaign and stage data

The project SHALL include headless tests for campaign unlock logic and loading of the three campaign stages (and map templates).

#### Scenario: Chapter 6 unit tests pass
- **WHEN** `test_campaign_manager.gd` and extended stage loader tests run
- **THEN** they pass alongside existing chapter 1–5 tests with exit code zero
