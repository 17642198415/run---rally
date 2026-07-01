## MODIFIED Requirements

### Requirement: Full automated test suite passes before M4 sign-off

Before marking chapter 9 complete, `tests/run_all_tests.ps1` SHALL exit zero with all unit test files **and** all headless UI scene test files under `tests/ui/` passing.

#### Scenario: All unit tests green

- **WHEN** `tests/run_all_tests.ps1` is executed on the release candidate branch
- **THEN** output includes `ALL N TESTS PASSED` with exit code 0 and N includes both `tests/unit/` and `tests/ui/` file counts

#### Scenario: UI navigation smoke included in automation

- **WHEN** the README MVP section references automated verification for G1 (dual mode entry)
- **THEN** `tests/ui/test_ui_campaign_flow.gd` and `tests/ui/test_ui_roguelike_flow.gd` (or equivalent) cover main-menu entry to campaign and roguelike route map without crash
