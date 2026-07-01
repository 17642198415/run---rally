# mvp-acceptance

## Purpose

MVP milestone M4 acceptance criteria: README documentation for the §9.3 checklist, regression playbooks, known limitations, automated test gate, and optional Windows export instructions.

## Requirements

### Requirement: MVP acceptance checklist is documented in README

The project README SHALL include an「MVP 终验清单」section covering Demo §9.3 success criteria: battle layer (B1–B4), campaign (C1–C2), roguelike (R1–R6), and general (G1–G2). Each item SHALL list a verification method and a checkbox for manual sign-off.

#### Scenario: Checklist includes all fourteen criteria

- **WHEN** a reviewer opens the README MVP acceptance section
- **THEN** items B1 through B4, C1 through C2, R1 through R6, and G1 through G2 are present with verification hints

#### Scenario: Roguelike mid-run save is documented correctly

- **WHEN** the known limitations section describes run persistence
- **THEN** it states that active runs are saved via `SaveManager.run` and can be continued from the main menu (not「关闭游戏 = Run 丢失」as obsolete Demo text)

### Requirement: Three regression playbooks are documented

The README SHALL document regression playbooks A (campaign new save), B (roguelike failed run), and C (roguelike clear run) with step-by-step instructions aligned with Demo §9.4.

#### Scenario: Playbook A covers campaign full clear

- **WHEN** playbook A is followed from a fresh save
- **THEN** the steps cover stage_01 through stage_03 BOSS, capture, and restart persistence check

#### Scenario: Playbook C verifies META_BALL after clear

- **WHEN** playbook C completes a BOSS victory and the player starts a new run with META_BALL unlocked
- **THEN** the documented expected outcome is `RunState.balls == 4`

### Requirement: Known limitations and v3 backlog are recorded

The README SHALL include a「已知限制」subsection listing Demo-expected limitations (no permadeath, no evolution, no status effects, counterattack not implemented, 3 Meta only, placeholder art) and a brief v3 backlog list without implementing those features.

#### Scenario: v3 features are listed as out of scope

- **WHEN** the known limitations section is read
- **THEN** permanent death, poison/paralysis/burn, Lv5 evolution, and META_SHOP are listed as future work, not current bugs

### Requirement: Full automated test suite passes before M4 sign-off

Before marking chapter 9 complete, `tests/run_all_tests.ps1` SHALL exit zero with all unit test files **and** all headless UI scene test files under `tests/ui/` passing.

#### Scenario: All unit tests green

- **WHEN** `tests/run_all_tests.ps1` is executed on the release candidate branch
- **THEN** output includes `ALL N TESTS PASSED` with exit code 0 and N includes both `tests/unit/` and `tests/ui/` file counts

#### Scenario: UI navigation smoke included in automation

- **WHEN** the README MVP section references automated verification for G1 (dual mode entry)
- **THEN** `tests/ui/test_ui_campaign_flow.gd` and `tests/ui/test_ui_roguelike_flow.gd` (or equivalent) cover main-menu entry to campaign and roguelike route map without crash

### Requirement: Optional Windows export instructions exist

The README SHALL document optional Windows Desktop export steps (Godot Project → Export) with a recommended output directory under `builds/demo/`. Export itself is optional and does not block M4 if export templates are unavailable.

#### Scenario: Export path is documented

- **WHEN** a developer follows README export instructions
- **THEN** a target directory `builds/demo/` (or equivalent) is specified for the Windows executable
