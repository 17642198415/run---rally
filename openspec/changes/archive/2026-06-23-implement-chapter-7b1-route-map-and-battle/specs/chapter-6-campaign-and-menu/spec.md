## MODIFIED Requirements

### Requirement: Main menu provides campaign and bestiary navigation

The `scenes/main_menu.tscn` scene SHALL display a title and four navigation actions: **开始征途** (or **继续征途** when a run is active), **战役**, **图鉴**, and **选项** (placeholder). Selecting **战役** SHALL open `stage_select.tscn`. Selecting **图鉴** SHALL open `bestiary_view.tscn`. Selecting **开始征途** SHALL start a new roguelike run when none is active; when `run.active` is true, the roguelike action SHALL continue the saved run. An abandon control SHALL allow clearing the active run.

#### Scenario: Campaign button opens stage select
- **WHEN** the player chooses **战役** from the main menu
- **THEN** the game loads `scenes/campaign/stage_select.tscn`

#### Scenario: Roguelike entry starts or continues a run
- **WHEN** the player chooses **开始征途** with no active run
- **THEN** a new run is created and `route_map.tscn` loads

#### Scenario: Roguelike continue loads saved run
- **WHEN** `run.active` is true and the player chooses **继续征途**
- **THEN** the saved run state is restored and `route_map.tscn` loads

#### Scenario: Bestiary button opens bestiary view
- **WHEN** the player chooses **图鉴** from the main menu
- **THEN** the game loads `scenes/campaign/bestiary_view.tscn`

### Requirement: Party setup selects HERO plus up to three reserve units

`party_setup.tscn` SHALL always include **HERO** as a fixed deploy member and allow selecting 0 to 3 additional units, for a maximum of 4 player units. In **CAMPAIGN** mode, reserve units SHALL come from `PartyManager.reserve` and confirming SHALL write `GameState.battle_context.deploy_list` and start the campaign battle for the chosen stage. In **ROGUELIKE** mode, reserve units SHALL come from `RunManager.get_state().reserve`, confirming SHALL call `GameState.start_roguelike_battle` with the pending node context and `deploy_list`, and load `battle.tscn` with `return_scene_path` set to the route map.

#### Scenario: HERO is always in deploy list
- **WHEN** the player confirms party setup with zero reserve units selected (campaign or roguelike)
- **THEN** `deploy_list` contains exactly one entry for `HERO`

#### Scenario: Up to three reserve units can be added
- **WHEN** the player selects three reserve units and confirms
- **THEN** `deploy_list` contains HERO plus three reserve template entries (4 total)

#### Scenario: More than three reserve units cannot be selected
- **WHEN** the player already selected 3 reserve units
- **THEN** additional reserve units cannot be toggled on until one is deselected

#### Scenario: Campaign mode still uses PartyManager
- **WHEN** `GameState.current_mode == CAMPAIGN` and party setup confirms
- **THEN** `start_campaign_battle` is invoked with the stage id and deploy list

#### Scenario: Roguelike mode uses RunState reserve
- **WHEN** `GameState.current_mode == ROGUELIKE` and party setup confirms
- **THEN** `start_roguelike_battle` is invoked and battle loads with route map as return path
