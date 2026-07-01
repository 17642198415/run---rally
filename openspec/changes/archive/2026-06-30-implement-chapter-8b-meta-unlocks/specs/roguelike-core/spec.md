## MODIFIED Requirements

### Requirement: MetaManager stats structure is prepared (not yet populated)

The `MetaManager` SHALL integrate with top-level `stats` in `user://save_meta.json` using keys `runs_started`, `runs_won`, `runs_lost`, `deepest_layer`, `total_captures`, and `total_coins_spent` (each int, default 0 when missing). `MetaManager.record_run_end(state, victory)` SHALL update these counters when a roguelike run ends and then call `evaluate_unlocks`. `SaveManager.get_default_save()` SHALL include `"stats": {}` with merge filling missing stat keys as zero.

#### Scenario: Fresh save has zero stats

- **WHEN** `SaveManager.load_meta()` is called on a fresh save
- **THEN** all stat keys are present with value 0 after merge

#### Scenario: Run end writes stats to save

- **WHEN** a roguelike run ends and `MetaManager.record_run_end` is invoked
- **THEN** `SaveManager.load_meta().stats.runs_started` increments and the file is persisted

## ADDED Requirements

### Requirement: RunManager applies Meta on new run and records stats on end

`RunManager.start_new_run` SHALL query `MetaManager.get_start_balls_bonus()` when initializing `RunState.balls`. When a run ends (`clear()` or transition to run summary after BOSS victory), `RunManager` SHALL call `MetaManager.record_run_end` before clearing active run state so stats and unlock evaluation are persisted.

#### Scenario: start_new_run uses Meta ball bonus

- **WHEN** `META_BALL` is unlocked and `RunManager.start_new_run(42)` is called
- **THEN** the new `RunState.balls` equals 4

#### Scenario: clear records failed run stats

- **WHEN** `RunManager.clear()` is called while a run is active with hero dead
- **THEN** `stats.runs_lost` increases and `run.active` becomes false
