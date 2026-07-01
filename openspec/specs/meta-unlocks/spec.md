# meta-unlocks

## Purpose

Cross-run Meta progression for the roguelike mode: unlock definitions, `MetaManager` evaluation and persistence, run-end stats tracking, Meta effects on new runs, and the bestiary unlock progress tab.

## Requirements

### Requirement: Meta unlock definitions are data-driven

The project SHALL provide `data/meta_unlocks.json` with an `unlocks` array. Each entry SHALL include `id`, `name`, `condition` (object), and `effect` (object). The initial data SHALL define exactly three unlocks: `META_BALL` (or-condition: `runs_won >= 1` OR `deepest_layer >= 5`, effect `start_balls_bonus: 1`), `META_M05` (bestiary `M05` seen, effect `add_to_pool: M05`), and `META_M08` (bestiary `M08` seen, effect `add_to_pool: M08`).

#### Scenario: Meta unlock file loads three entries

- **WHEN** `MetaManager.load_definitions()` runs at startup
- **THEN** exactly 3 unlock definitions are available with ids `META_BALL`, `META_M05`, and `META_M08`

### Requirement: MetaManager evaluates and persists unlock state

`MetaManager` SHALL load unlock definitions from `data/meta_unlocks.json`, persist unlocked ids in `SaveManager.load_meta().meta.unlocked`, and expose `is_unlocked(id) -> bool`, `evaluate_unlocks(meta_snapshot: Dictionary) -> Array[String]` (returns newly unlocked ids), `get_start_balls_bonus() -> int`, and `get_pool_extras() -> Array[String]` (template ids from `add_to_pool` effects). Unlock evaluation SHALL run after run end stats update and after bestiary discovery changes that may satisfy bestiary conditions.

#### Scenario: META_BALL unlocks after first run won

- **WHEN** `stats.runs_won` becomes 1 and `evaluate_unlocks` is called
- **THEN** `META_BALL` is added to `meta.unlocked` and `is_unlocked("META_BALL")` is true

#### Scenario: META_BALL unlocks when deepest layer reaches 5 without a win

- **WHEN** a run ends with `stats.deepest_layer >= 5` and `stats.runs_won == 0`
- **THEN** `META_BALL` becomes unlocked

#### Scenario: META_M05 unlocks when M05 is discovered in bestiary

- **WHEN** `BestiaryManager` marks `M05` as discovered and `evaluate_unlocks` runs
- **THEN** `META_M05` is unlocked and persisted in save meta

#### Scenario: Unlocked ids survive run clear

- **WHEN** `RunManager.clear()` is called after unlocks were earned
- **THEN** `SaveManager.load_meta().meta.unlocked` still contains the earned ids

### Requirement: Run end updates roguelike stats

When a roguelike run ends (victory, hero death, or abandon), the system SHALL update top-level `stats` in `user://save_meta.json` with keys `runs_started`, `runs_won`, `runs_lost`, `deepest_layer`, `total_captures`, and `total_coins_spent`. Each run end SHALL increment `runs_started`; victories increment `runs_won`; non-victory endings increment `runs_lost`; `deepest_layer` SHALL be the maximum layer reached across all runs; capture and coin totals SHALL accumulate from the ending `RunState`.

#### Scenario: Failed run increments runs_lost and deepest_layer

- **WHEN** a run ends with hero dead at layer 4
- **THEN** `stats.runs_lost` increases by 1, `stats.runs_started` increases by 1, and `stats.deepest_layer` is at least 4

#### Scenario: BOSS victory increments runs_won

- **WHEN** a run ends with BOSS victory
- **THEN** `stats.runs_won` increases by 1 and `stats.deepest_layer` is at least 6

### Requirement: Meta effects apply on new roguelike runs

A new run started via `RunManager.start_new_run` SHALL apply unlocked Meta effects: initial `balls` SHALL be `3 + start_balls_bonus` when `META_BALL` is unlocked (4 total). `RewardPool.get_rescue_pool()` SHALL include all `add_to_pool` template ids from unlocked Meta entries. Enemy group picking for layers 3–5 normal/elite battles and capture events SHALL be able to spawn Meta pool extras (`M05`, `M08`) when those Meta entries are unlocked.

#### Scenario: New run starts with four balls when META_BALL unlocked

- **WHEN** `META_BALL` is unlocked and the player starts a new run
- **THEN** `RunState.balls == 4`

#### Scenario: Rescue pool includes M05 when META_M05 unlocked

- **WHEN** `META_M05` is unlocked
- **THEN** `RewardPool.get_rescue_pool()` contains `"M05"`

### Requirement: Bestiary unlock tab shows Meta progress

`bestiary_view.tscn` SHALL provide a tab switch between **灵兽** (existing 8-cell grid) and **解锁** (Meta unlock list). The unlock tab SHALL display all entries from `meta_unlocks.json` with name, human-readable condition summary, and a visual locked/unlocked indicator. Data SHALL reflect current `meta.unlocked`, `stats`, and bestiary state without modifying bestiary persistence rules.

#### Scenario: Locked META_BALL shows progress hint

- **WHEN** the unlock tab is shown and `META_BALL` is not unlocked with `stats.runs_won == 0` and `stats.deepest_layer == 3`
- **THEN** the card shows locked state and a condition hint referencing win or layer 5

#### Scenario: Unlocked Meta shows completed badge

- **WHEN** `META_M05` is unlocked
- **THEN** its unlock tab card shows an unlocked/completed visual state
