## 1. Test Framework and RED Tests

- [x] 1.1 Add `tests/unit/test_weapon_triangle.gd`: sword>axe ×1.2, axe>sword ×0.8, axe>spear ×1.2, spear>axe ×0.8, none neutral, unrelated 1.0
- [x] 1.2 Add `tests/unit/test_combat_calc.gd`: min damage 1, forest effective_def reduces damage vs plain, skill mult 1.3 increases damage, weapon mult applied
- [x] 1.3 Add `tests/unit/test_battle_controller.gd`: attack reduces hp, hp<=0 removes unit, check_victory player/enemy/none, skill CD set on use and ticks on wait
- [x] 1.4 Run all three tests before implementation and confirm RED

## 2. Pure Combat Logic

- [x] 2.1 Create `scripts/battle/weapon_triangle.gd` with `TRIANGLE` map and `get_multiplier(attacker_weapon, defender_weapon) -> float`
- [x] 2.2 Create `scripts/battle/combat_calc.gd` with `calc_damage(attacker: BattleUnit, defender: BattleUnit, grid, skill_mult := 1.0) -> int` using effective_def from terrain
- [x] 2.3 Create `scripts/battle/battle_unit.gd` (`RefCounted`) with `from_template(template_id, is_player, grid_pos, unit_id)` reading `DataLoader`
- [x] 2.4 Create `scripts/battle/attack_range.gd` with `get_attack_targets(grid, unit, min_dist, max_dist) -> Array[Vector2i]` (Manhattan) and helpers `get_basic_attack_range(unit) -> {min,max}`
- [x] 2.5 Create `scripts/battle/battle_controller.gd` with `perform_attack`, `perform_skill`, `apply_damage`, `remove_dead_unit`, `tick_cooldown(unit)`, `check_victory(units) -> String`
- [x] 2.6 Run tests until 1.1 / 1.2 / 1.3 GREEN

## 3. View and UI

- [x] 3.1 Extend `scripts/battle/unit_view.gd`: bind `BattleUnit`, show HP label under icon, `sync_from_battle_unit()`, hide/queue_free on death
- [x] 3.2 Create `scenes/battle/ui/action_bar.tscn` + script: buttons Move / Attack / Skill / Wait, HP info label, signal `action_selected(action: String)`
- [x] 3.3 Add manual faction toggle button or hotkey (e.g. Tab) labeled `Turn: -- (manual)` in HUD

## 4. Battle Scene Integration

- [x] 4.1 Refactor `battle_grid_controller.gd`: maintain `units: Array` of `BattleUnit` + `views: Dictionary`; spawn 2v2 from DataLoader (HERO+M01 vs M02+M03) on `test_grid.json`
- [x] 4.2 Extend state machine: `UNIT_SELECTED` → action bar → `TARGETING_MOVE | TARGETING_ATTACK | TARGETING_SKILL` → execute → `IDLE`; reuse chapter 2 move logic
- [x] 4.3 Attack targeting: highlight attack-range cells (red tint), click enemy on valid cell → `BattleController.perform_attack` or `perform_skill`; show floating damage number or HUD log
- [x] 4.4 On kill: `grid.clear_occupant`, remove from `units`, `view.queue_free()`; call `check_victory` → show `Player Win` / `Enemy Win`
- [x] 4.5 Skill: load mult/cooldown/range from `DataLoader.get_skill`; block when `skill_cooldown_left > 0`; Wait ticks CD for active unit
- [x] 4.6 Update `scenes/battle/battle.tscn` to instance `action_bar.tscn` under `CanvasLayer`
- [x] 4.7 Update HUD title to `Chapter 3 — Combat & Counter`

## 5. Verification

- [x] 5.1 Run all headless tests (ch1 + ch2 + ch3) green
- [x] 5.2 Manual: F6 `battle.tscn` — 2v2 visible, select unit, move, attack enemy, enemy HP drops
- [x] 5.3 Manual: HERO (sword) vs unit with overridden axe weapon or compare damage via test log — ×1.2 / ×0.8 visible in damage numbers
- [x] 5.4 Manual: M03 flying attacks at distance 2; skill `S_GUST` reaches range 3 when tested
- [x] 5.5 Manual: fight until one side wiped — victory banner text
- [x] 5.6 Manual: skill used → CD blocks reuse; Wait reduces CD
- [x] 5.7 Confirm no turn_manager / deploy / enemy_ai / capture code added
- [x] 5.8 Update `README.md` chapter 3 checkbox and battle scene instructions
