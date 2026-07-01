## ADDED Requirements

### Requirement: Shared menu card styling matches battle HUD palette

The project SHALL provide a shared `MenuStyle` helper that produces panel/card/button StyleBoxes consistent with Tier 1 battle HUD cards: rounded corners (radius 14), semi-transparent dark background `Color(0.13, 0.15, 0.20, 0.92)`, subtle shadow, and white or light-gray primary text. All four menu pages (`main_menu`, `stage_select`, `party_setup`, `bestiary_view`) MUST apply this helper in `_ready()` without changing navigation or business logic.

#### Scenario: Menu pages use unified card background

- **WHEN** any of the four menu scenes finishes `_ready()`
- **THEN** the root content panel uses the shared card StyleBox (Flat or Texture fallback via `ArtLoader.get_ui("panel_bg")`)

#### Scenario: Buttons use unified normal/hover/pressed/disabled styles

- **WHEN** a menu page contains `Button` nodes
- **THEN** each button receives shared StyleBox overrides from `MenuStyle.make_button_styles()` and disabled buttons appear visually muted

### Requirement: Main menu presents cardized navigation

`main_menu.tscn` SHALL display the title and four navigation actions inside a styled card on the dark page background. **开始征途** and **选项** MUST remain functionally disabled or show placeholder hints; **战役** and **图鉴** MUST remain fully clickable.

#### Scenario: Campaign and bestiary buttons navigate unchanged

- **WHEN** the player clicks **战役** or **图鉴**
- **THEN** the game loads `stage_select.tscn` or `bestiary_view.tscn` respectively (same as pre-polish behavior)

#### Scenario: Locked roguelike entry is visually disabled

- **WHEN** the main menu is shown
- **THEN** **开始征途** appears grayed/disabled and shows or triggers the chapter-7-not-ready hint without crashing

### Requirement: Stage select shows three status-distinguishable stage cards

`stage_select.tscn` SHALL render `stage_01`, `stage_02`, and `stage_03` as individual card panels (not plain text buttons) with display names from stage JSON and visual variants for campaign status `locked`, `unlocked`, and `cleared`. Entering an enterable stage MUST still open `party_setup.tscn`; locked stages MUST NOT be enterable.

#### Scenario: Locked stage card is gray and not enterable

- **WHEN** `stage_02` has status `locked`
- **THEN** its card uses the locked color variant, shows a "未解锁" badge, and cannot be clicked to start battle

#### Scenario: Unlocked stage card is highlighted

- **WHEN** `stage_02` has status `unlocked`
- **THEN** its card uses the unlocked (blue-accent) variant and shows a "可挑战" badge

#### Scenario: Cleared stage card shows completion

- **WHEN** `stage_01` has status `cleared`
- **THEN** its card uses the cleared (gold-accent) variant and shows a "已通关" badge

#### Scenario: Selecting enterable stage opens party setup

- **WHEN** the player clicks an unlocked or cleared enterable stage card
- **THEN** `GameState.stage_id` is set and `party_setup.tscn` loads

### Requirement: Party setup highlights HERO and cardizes reserve rows

`party_setup.tscn` SHALL display HERO as a fixed, visually prominent card row (gold accent or star marker) and each reserve entry as a card row with checkbox, unit avatar placeholder from `ArtLoader.get_unit(template_id)`, and HP text. Selection rules (HERO fixed + max 3 reserve) MUST remain unchanged.

#### Scenario: HERO row is visually distinct

- **WHEN** party setup is shown for any stage
- **THEN** the HERO row uses a highlighted card style separate from reserve rows

#### Scenario: Reserve selection limit unchanged

- **WHEN** the player tries to select a fourth reserve unit
- **THEN** the checkbox is rejected and status text shows the max-3 message (same logic as before)

#### Scenario: Confirm still builds deploy_list correctly

- **WHEN** the player confirms with HERO and selected reserve units
- **THEN** `GameState.start_campaign_battle` receives the same deploy_list structure as pre-polish

### Requirement: Bestiary view shows eight styled species cells

`bestiary_view.tscn` SHALL display an 8-cell grid for `M01`–`M08` where each cell is a card containing a unit avatar (or `?` placeholder when undiscovered), species name when discovered, and a status badge for 未发现 / 已发现 / 已捕获. Data MUST come from `BestiaryManager` without changing persistence rules.

#### Scenario: Undiscovered species shows hidden placeholder

- **WHEN** `M05` is not discovered
- **THEN** the cell shows a gray `?` avatar placeholder and does not reveal the species name

#### Scenario: Caught species shows green completion badge

- **WHEN** `M01` is marked caught in `BestiaryManager`
- **THEN** the cell shows the unit avatar and a caught/completed indication (green accent)

#### Scenario: Discovered-only species shows yellow badge

- **WHEN** `M02` is discovered but not caught
- **THEN** the cell shows the species name and a discovered (yellow accent) badge

### Requirement: Menu polish reuses ArtLoader without new asset pipeline

Menu pages SHALL reuse the existing `ArtLoader` autoload for `get_ui("panel_bg")` and `get_unit(template_id)` textures. Missing physical files MUST fall back to code-generated placeholders without errors, matching battle-page behavior.

#### Scenario: Missing panel_bg file still renders

- **WHEN** `assets/art/ui/panel_bg.png` does not exist
- **THEN** menu panels render using StyleBoxFlat fallback and the game does not crash

#### Scenario: Existing unit tests remain green

- **WHEN** `tests/run_all_tests.ps1` runs after menu visual changes
- **THEN** all existing headless unit tests pass with exit code zero
