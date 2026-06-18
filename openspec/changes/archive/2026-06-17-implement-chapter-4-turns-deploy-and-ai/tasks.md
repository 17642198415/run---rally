## 1. Test Framework and RED Tests

- [x] 1.1 Add `tests/unit/test_turn_manager.gd`: deploy→player turn, end turn→enemy turn, enemy complete→round+1, victory→BATTLE_END
- [x] 1.2 Add `tests/unit/test_deploy_phase.gd`: reject out-of-zone placement, require all player templates placed before confirm, enemy spawn at JSON coordinates
- [x] 1.3 Add `tests/unit/test_enemy_ai.gd`: pick lowest HP in range, move toward nearest player when out of range, wait when stuck
- [x] 1.4 Run new tests before implementation and confirm RED

## 2. Stage Data and Loading

- [x] 2.1 Create `data/stages/debug_battle.json` per design (`DEBUG_01`, `test_grid`, HERO deploy + M01/M02 enemy spawns)
- [x] 2.2 Extend `DataLoader` (or add stage loader) with `get_stage(id) -> Dictionary` and `load_stage_map(stage) -> Grid`
- [x] 2.3 Add headless assertion that `DEBUG_01` parses and references valid unit templates

## 3. Pure Turn / Deploy / AI Logic

- [x] 3.1 Create `scripts/battle/turn_manager.gd` (`RefCounted`): `TurnPhase`, queues, `active_unit`, `round_number`, phase transition methods
- [x] 3.2 Create `scripts/battle/deploy_phase.gd`: pending templates, place/remove on `deploy_zones.player`, `can_confirm()`, `spawn_enemies()` from stage JSON
- [x] 3.3 Create `scripts/battle/enemy_ai.gd`: `decide_action(enemy, grid, units) -> Dictionary` per design (attack lowest HP / move toward nearest / wait)
- [x] 3.4 Stub `ai_profile` hook for future boss behavior (no-op unless `boss_default` + hp ratio)
- [x] 3.5 Run tests until 1.1 / 1.2 / 1.3 GREEN

## 4. Battle Scene Orchestration

- [x] 4.1 Create `scripts/battle/battle_scene.gd`: load stage `DEBUG_01`, own `TurnManager` + `DeployPhase`, expose signals `phase_changed`, `active_unit_changed`
- [x] 4.2 Refactor `battle_grid_controller.gd`: accept orchestrator; gate input with `can_control_unit(unit)`; remove default Tab faction switch (optional debug flag only)
- [x] 4.3 Wire deploy click flow: highlight deploy zone, place/remove HERO, confirm → spawn enemies → `PLAYER_TURN`
- [x] 4.4 Wire player turn: auto-select `active_unit`, advance queue after move/attack/skill/wait, tick acting unit CD via `BattleController.tick_cooldown`
- [x] 4.5 Wire end-turn button: lock player input, run enemy turn sequence
- [x] 4.6 Wire enemy turn: iterate enemies, call `EnemyAI.decide_action`, execute via `BattleController` + movement tween, check victory between units
- [x] 4.7 Sync `GameState.current_battle_phase` and `stage_id` on phase changes
- [x] 4.8 On `BATTLE_END`, show victory/defeat HUD and disable input

## 5. UI

- [x] 5.1 Create `scenes/battle/ui/turn_banner.tscn` + script: show `Round N` and active unit display name
- [x] 5.2 Extend `action_bar.tscn` / `action_bar.gd`: add「结束回合」button, signal `end_turn_pressed`, hide during DEPLOY/ENEMY_TURN
- [x] 5.3 Add deploy UI:「确认部署」button (disabled until all player units placed); update HUD copy for deploy phase
- [x] 5.4 Update `battle.tscn`: mount `battle_scene.gd`, `turn_banner`, wire export `stage_id = "DEBUG_01"`

## 6. Verification

- [x] 6.1 Run `tests/run_all_tests.ps1` — all tests green (ch1–ch4)
- [x] 6.2 Manual: F6 `battle.tscn` — deploy HERO only in player zone, confirm, fight `DEBUG_01`
- [x] 6.3 Manual: operate each player unit in sequence; end turn locks player; enemy attacks lowest HP in range
- [x] 6.4 Manual: enemy moves toward player when out of range; round number increments
- [x] 6.5 Manual: play to victory or defeat without soft-lock
- [x] 6.6 Confirm no capture / campaign / roguelike / bestiary code added
- [x] 6.7 Update `README.md` chapter 4 checkbox, M1 milestone, and acceptance steps
- [x] 6.8 Update `tests/run_all_tests.ps1` if new test files need documenting in README only (script auto-discovers `test_*.gd`)
