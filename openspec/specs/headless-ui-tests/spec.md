# headless-ui-tests

## Purpose

Headless Godot UI scene tests: shared harness, scene smoke loads, campaign/roguelike navigation flows, and inclusion in the unified test runner.

## Requirements

### Requirement: Scene test harness supports headless UI automation

The project SHALL provide a `SceneTestHarness` helper under `tests/helpers/` that can load a scene by path, await at least one idle frame, find nodes by path or group, emit `Button.pressed`, read the current scene file path, and reset autoload save/run state to deterministic defaults for UI tests.

#### Scenario: Harness loads main menu without crash

- **WHEN** a UI test calls the harness to change to `res://scenes/main_menu.tscn` in headless mode
- **THEN** the scene tree contains `CampaignBtn` and `RoguelikeBtn` after `_ready()` completes

#### Scenario: Harness resets save to defaults

- **WHEN** a UI test calls the harness reset helper before navigation
- **THEN** `SaveManager.load_meta()` returns default campaign progress with only `stage_01` enterable and no active run

### Requirement: All game scenes pass headless smoke load

Every `.tscn` under `scenes/` that is part of the shipped game flow SHALL be loadable in headless mode via UI tests without script errors. Each smoke test SHALL assert at least one scene-specific root or child node exists after `_ready()`.

#### Scenario: Campaign scenes smoke

- **WHEN** `test_ui_scene_smoke` loads `main_menu`, `stage_select`, `party_setup`, and `bestiary_view` with appropriate autoload precondition
- **THEN** each scene completes `_ready()` and required containers (`StageList`, `ReserveList`, species grid) are non-null

#### Scenario: Roguelike scenes smoke

- **WHEN** `test_ui_scene_smoke` loads `route_map`, `rest`, `shop`, `reward_pick`, and `run_summary` with a seeded active `RunManager` state where required
- **THEN** each scene completes `_ready()` without changing back to main menu unexpectedly

#### Scenario: Battle scenes smoke

- **WHEN** `test_ui_scene_smoke` loads `battle.tscn` with a valid `GameState` battle context
- **THEN** battle HUD roots (turn/objective/action regions) exist in the tree

### Requirement: UI navigation flows are automated for campaign and roguelike entry

Headless UI tests SHALL simulate button presses to verify primary navigation paths documented in README MVP playbooks without manual F5.

#### Scenario: Campaign path from main menu

- **WHEN** the test presses **战役** on main menu, selects an enterable stage, and reaches party setup
- **THEN** `GameState.stage_id` is set and `party_setup.tscn` is the current scene

#### Scenario: Roguelike path from main menu

- **WHEN** the test presses **开始征途** with no active run
- **THEN** `RunManager.get_state()` is non-null and `route_map.tscn` is the current scene

#### Scenario: Bestiary round trip

- **WHEN** the test opens bestiary from main menu and presses Back
- **THEN** the current scene returns to `main_menu.tscn`

### Requirement: Unified test runner includes UI tests

`tests/run_all_tests.ps1` SHALL execute all `tests/unit/test_*.gd` and `tests/ui/test_*.gd` files with Godot headless. Failure in any file SHALL exit non-zero. Success SHALL print a single summary line with total count.

#### Scenario: Full suite green

- **WHEN** `tests/run_all_tests.ps1` runs on a clean dev machine with Godot 4.6
- **THEN** output includes `ALL N TESTS PASSED` where N equals unit plus UI test file counts
