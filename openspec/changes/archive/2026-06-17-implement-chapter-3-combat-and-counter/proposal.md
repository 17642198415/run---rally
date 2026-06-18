## Why

第 2 章已完成网格、地形与点击移动，但战场仍无法造成伤害、判定死亡或分出胜负。第 3 章要在现有 `Grid` / `Pathfinding` / `UnitView` 基础上叠加战斗层：伤害公式（攻击、防御、武器克制、技能系数、地形防御）、近战/远程攻击范围、HP 归零移除、一方全灭胜负判定。本章仍保持「自由测试模式」（可手动切换操作方），**不实现**完整回合机、部署、AI、捕捉或菜单——为第 4 章回合与 AI 提供可复用的 `BattleUnit` 与 `BattleController` 战斗原语。

## What Changes

- 新增 `scripts/battle/weapon_triangle.gd`：剑→斧→枪→剑克制表，`get_multiplier(attacker_weapon, defender_weapon)` 返回 1.2 / 0.8 / 1.0。
- 新增 `scripts/battle/combat_calc.gd`：纯函数伤害计算，公式 `max(1, (atk - effective_def) * weapon_mult * skill_mult)`，其中 `effective_def = def + terrain_def_bonus`。
- 新增 `scripts/battle/battle_unit.gd`（`RefCounted` 运行时模型）：从 `DataLoader` 模板构造，含 `hp/max_hp/atk/def/mov/weapon/unit_type/skill_id/skill_cooldown_left` 等字段。
- 新增 `scripts/battle/battle_controller.gd`：攻击/技能执行、死亡处理、`check_victory(units) -> "player"|"enemy"|"none"`。
- 新增 `scripts/battle/attack_range.gd`（或并入 `combat_calc`）：近战曼哈顿距离 1；远程（`unit_type == "flying"` 或技能 `range >= 2`）攻击范围 2～3 格。
- 扩展 `scripts/battle/unit_view.gd`：绑定 `BattleUnit`，显示 HP 简条/文字，死亡时 `queue_free`。
- 重构/扩展 `scripts/battle/battle_grid_controller.gd` → 战斗场景总控：2 玩家 + 2 敌人测试编队；交互状态机增加 `ACTION_MODE`（移动/攻击/技能/待机）；攻击范围高亮 + 点击敌人目标；手动切换当前操作方（测试模式）。
- 新增 `scenes/battle/ui/action_bar.tscn`：占位按钮 `[移动][攻击][技能][待机]` + 当前单位 HP 信息。
- 补充 headless 单测：`test_weapon_triangle.gd`、`test_combat_calc.gd`、`test_battle_controller.gd`（伤害、克制、地形防御、胜负、CD）。
- 更新 `README.md` 第 3 章进度与 `battle.tscn` 验收说明。

## Capabilities

### New Capabilities

- `chapter-3-combat-and-counter`：覆盖伤害公式、武器克制、运行时 `BattleUnit`、攻击/技能流程、攻击范围、死亡移除、胜负判定、2v2 自由测试场景与 action bar UI。

### Modified Capabilities

无。第 2 章 `chapter-2-grid-and-movement` 的网格/寻路/占格 API 保持不变；本章在 battle 场景层叠加战斗逻辑，不修改其 requirement 行为。

## Impact

- **代码**：新增 `weapon_triangle.gd`、`combat_calc.gd`、`battle_unit.gd`、`battle_controller.gd`、`attack_range.gd`；大幅扩展 `battle_grid_controller.gd` 与 `unit_view.gd`；新增 `scenes/battle/ui/action_bar.tscn`。
- **数据**：复用第 1 章 `data/units/*.json`、`data/skills/*.json`、`data/hero.json`；2v2 测试编队通过代码从 `DataLoader` 加载（HERO + M01 玩家方，M02 + M03 敌方，武器克制测试可额外注入 `sword`/`axe` 调试单位或覆盖 weapon 字段）。
- **测试**：`tests/unit/test_weapon_triangle.gd`、`test_combat_calc.gd`、`test_battle_controller.gd`。
- **场景**：`scenes/battle/battle.tscn` 挂载 action bar；主场景仍为 `main_menu.tscn`。
- **禁项**：无 `turn_manager`、无 `deploy_phase`、无 `enemy_ai`、无捕捉、无战役/肉鸽入口。
- **后续**：第 4 章 `TurnManager` 将复用 `BattleController` 的攻击/技能/死亡/胜负接口。
