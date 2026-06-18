## Context

第 2 章已交付：`Grid` / `Pathfinding` / `terrain_types` / `unit_view` / `battle_grid_controller`，`battle.tscn` 支持 1 个测试单位点击移动。第 1 章 `DataLoader` 提供 8 单位 + 10 技能 + 主角 JSON。

第 3 章要在不破坏网格层的前提下叠加战斗：伤害、克制、HP、攻击范围、技能 CD、死亡、胜负。Demo 计划 §3.4 明确公式与 `BattleUnit` 字段；§3.5 验收要求 2v2 互殴、克制可肉眼区分、**尚无**完整回合轮换（手动切换操作方）。

约束：

- Godot 4.6 + GDScript，逻辑层（`combat_calc` / `weapon_triangle` / `BattleUnit` / `BattleController`）不依赖 `Node`，可 headless 单测。
- 地形防御与第 2 章 `terrain_types.get_def_bonus()` 统一：`effective_def = def + get_def_bonus(defender_terrain)`。
- 武器克制仅对 `sword/axe/spear` 三角生效；`weapon == "none"` 时倍率 1.0。

## Goals / Non-Goals

**Goals:**

- `weapon_triangle.get_multiplier`：克制 1.2、被克 0.8、无关/none 1.0。
- `combat_calc.calc_damage(attacker, defender, grid, skill_mult)` 实现 Demo §3.4.3 公式，最低伤害 1。
- `BattleUnit` 从 `DataLoader` 模板 + `is_player` + `grid_pos` 构造；维护 `hp`、`skill_cooldown_left`。
- `BattleController`：`perform_attack` / `perform_skill`、目标死亡时 `grid.clear_occupant` + 从单位列表移除、`check_victory`。
- 攻击范围：近战（默认）曼哈顿距离 = 1；远程 `unit_type == "flying"` 或单位带 `attack_range >= 2` 时距离 2～3（M03 验收「隔 1 格」= 距离 2）。
- `battle.tscn` 2v2 测试：玩家 HERO(sword) + M01，敌方 M02 + M03(flying)；可 `[切换操作方]` 或点击友方单位选手动测试。
- Action bar：`[移动][攻击][技能][待机]`；选中单位后选模式 → 高亮范围 → 点目标执行。
- 技能：读 `DataLoader.get_skill(skill_id)` 的 `mult`/`cooldown`/`range`；使用后 `skill_cooldown_left = cooldown`，每行动结束 tick -1（本章简化为每次攻击/技能/待机后 tick 当前单位 CD）。
- 一方全灭 → HUD 显示 `Player Win` / `Enemy Win`。
- Headless 单测覆盖克制、伤害、森林防御、胜负、CD。

**Non-Goals:**

- 不实现 `turn_manager`、`deploy_phase`、`enemy_ai`。
- 不实现捕捉、图鉴写入、战役/肉鸽。
- 不实现反击、异常状态、Buff 系统（`buffs` 字段预留空数组）。
- 不做完整「结束回合」轮换；仅手动切换当前可操作友方/敌方（测试模式标签 `Turn: -- (manual)`）。

## Decisions

1. **数据模型与视图分离：`BattleUnit` (RefCounted) + `UnitView` 绑定。**
   - 方案：`BattleUnit` 存运行时数值；`UnitView.setup_from_battle_unit(bu)` 同步显示与 `unit_id`；controller 维护 `Array[BattleUnit]` 与 `Dictionary[unit_id -> UnitView]`。
   - 理由：战斗逻辑可单测；与第 2 章 `UnitView` 轻量扩展一致。
   - 否决：把 HP/atk 全塞进 `UnitView`。视图与逻辑耦合，难测。

2. **伤害公式用有效防御，不加到最终伤害上。**
   - 方案：`effective_def = defender.def + TerrainTypes.get_def_bonus(grid.get_terrain(defender.grid_pos))`；`base = max(0, attacker.atk - effective_def)`；`damage = max(1, int(base * weapon_mult * skill_mult))`。
   - 理由：与 Demo「森林 +1 有效防御」一致；山地 def+1 同样生效。
   - 否决：`final_damage = ... + terrain_def_bonus`（加在伤害上语义不对）。

3. **攻击范围独立模块 `attack_range.gd`。**
   - 方案：`get_attack_cells(grid, unit, min_range, max_range)` 返回曼哈顿距离在 `[min,max]` 且视线不被墙阻挡的格（本章墙阻挡移动也阻挡射击，简化 LOS：无墙则仅距离判定）。
   - 默认：`melee` min=1 max=1；`flying` min=2 max=3；技能攻击使用 `skill.range` 覆盖（`S_GUST` range=3）。
   - M03 验收：flying + 普通攻击 max=2 或技能 range=3；设计采用 **普通攻击** flying 为 min=2 max=2（隔 1 格），技能用 skill range。

4. **2v2 测试编队硬编码在 controller，从 DataLoader 实例化。**
   - 玩家：`(0,4) HERO`、`(1,4) M01`；敌方：`(9,4) M02`、`(8,3) M03`。
   - 克制肉眼测试：额外在 HUD 显示伤害数字；单测用 `weapon_triangle` 直接断言。若需剑斧对比，测试用例用 mock `BattleUnit` 设 `weapon=sword/axe`，不强制 2v2 场景内必有剑斧对局（HERO 已是 sword，敌方无 axe——单测覆盖克制，场景覆盖「有伤害差异」即可）。
   - 可选：spawn 调试用 `DEBUG_AXE` 单位替换 M02 并设 `weapon=axe` 便于肉眼验 sword vs axe；tasks 中列为可选验收增强。

5. **交互状态机扩展（在 Chapter 2 两态基础上）。**
   - 状态：`IDLE` → 点友方当前操作方单位 → `UNIT_SELECTED` → action bar 选 `移动|攻击|技能|待机` → `TARGETING_MOVE|TARGETING_ATTACK|TARGETING_SKILL` → 点合法格/敌人 → 执行 → `IDLE`。
   - `待机`：tick 技能 CD，结束该单位本「伪回合」；手动点「切换操作方」换边。
   - 移动逻辑复用第 2 章 `Pathfinding.get_reachable`。

6. **Action bar 用 `CanvasLayer` + `Control` 预制 `action_bar.tscn`。**
   - 挂到 `battle.tscn`；controller 通过 `@onready` 或 `get_node` 连接信号。
   - HP 显示：选中单位时更新 Label `HP 12/18`。

7. **测试策略：TDD，三个纯逻辑测试文件 + 不测 Node 输入。**
   - `test_weapon_triangle.gd`、`test_combat_calc.gd`、`test_battle_controller.gd`。
   - 场景交互靠手动验收清单 §3.5。

## Risks / Trade-offs

- [Risk] Demo 公式 `+ terrain_def_bonus` 字面与「有效防御」两种写法混用 → Mitigation：design/spec 统一写 `effective_def`，单测锁森林防守更耐打。
- [Risk] `UnitView` 与 `BattleUnit` 双份 `grid_pos` 不同步 → Mitigation：移动/攻击后只通过 controller 更新 `BattleUnit.grid_pos` 再 `unit_view.set_grid_pos`。
- [Risk] 2v2 场景无天然 sword vs axe → Mitigation：单测覆盖克制；场景用 HERO(sword) 打 M02 显示伤害；README 说明肉眼克制看控制台/飘字伤害对比。
- [Trade-off] 无 LOS 复杂算法：仅距离 + 墙不可达；第 4 章前足够。
- [Trade-off] `battle_grid_controller.gd` 继续扩展而非重命名；第 4 章再拆 `battle_scene.gd`。
