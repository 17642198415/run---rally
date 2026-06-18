## Context

第 3 章已交付：`BattleUnit`、`BattleController`、`attack_range`、`combat_calc`、`action_bar`，`battle_grid_controller.gd` 以 **Tab 手动切换阵营** 的 2v2 自由测试模式运行。`Grid` 与 `test_grid.json` 已含 `deploy_zones`；`GameState` 已有 `BattlePhase` 枚举但未接入战斗。

第 4 章要把战场从「调试互殴」升级为 **可通关的回合制战斗**：部署 → 玩家依次行动 → 结束回合 → 敌方 AI 依次行动 → 循环，直到 `BattleController.check_victory` 判定结束。Demo 计划 §4.4–§4.6 定义了 `TurnManager` 状态、`debug_battle.json` 结构与 AI 伪代码；验收达成 **M1**。

约束：

- 复用第 3 章战斗原语，不重写伤害/克制/死亡逻辑。
- Godot 4.6 + GDScript；`TurnManager` / `DeployPhase` / `EnemyAI` 为纯逻辑 `RefCounted` 或静态类，可 headless 单测。
- 部署交互本章用 **点击放置**（非拖拽），与现有格子点击输入一致。
- `DataLoader` 扩展或新增 `StageLoader` 读取 `data/stages/*.json`。

## Goals / Non-Goals

**Goals:**

- `TurnManager`：`DEPLOY → PLAYER_TURN → ENEMY_TURN → BATTLE_END`；`round_number` 从 1 递增；维护 `player_queue` / `enemy_queue` 与 `active_unit`。
- 玩家回合：友军单位按队列依次获得行动权；单位执行移动/攻击/技能/待机后标记 `acted` 并推进到下一友军；全部行动完毕或点「结束回合」进入敌方回合。
- 敌方回合：`EnemyAI` 对每个存活敌军顺序决策并执行（动画可简化为瞬移/即时伤害，与第 3 章 tween 移动兼容）。
- `DeployPhase`：从 `debug_battle.json` 读取玩家模板列表，在 `deploy_zones.player` 内点击放置；敌方按 `spawn` 固定坐标生成；「确认部署」后进入 `PLAYER_TURN`。
- `debug_battle.json`（`DEBUG_01`）：1 玩家 HERO + 2 敌方（M01、M02），地图 `test_grid`。
- UI：`turn_banner` 显示 `Round N` 与当前行动单位；`action_bar` 增加「结束回合」；部署阶段显示「确认部署」。
- 回合边界 tick 所有单位 `skill_cooldown_left`（敌方回合结束后或玩家结束回合时，与 Demo FAQ 一致）。
- `GameState.current_battle_phase` 与 `TurnManager.current_phase` 同步。
- Headless 单测：`turn_manager`、`deploy_phase`、`enemy_ai` 核心决策。

**Non-Goals:**

- 不实现捕捉、图鉴、战役选关、肉鸽、主菜单跳转（第 5–7 章）。
- 不实现完整 BOSS AI（`ai_profile: boss_default` 仅预留接口/stub）。
- 不实现多单位编队选择（玩家仅部署 JSON 配置的 1 个 HERO；槽位 UI 可显示空位占位）。
- 不实现反击、Buff、视线遮挡算法（沿用第 3 章曼哈顿距离）。
- 不删除 `battle_grid_controller`；通过 `battle_scene.gd` 编排，逐步从 controller 抽离阶段门控。

## Decisions

1. **`battle_scene.gd` 为场景总控，`battle_grid_controller.gd` 保留视图与输入。**
   - 方案：新建 `battle_scene.gd` 挂 `battle.tscn` 根节点（或子节点 Orchestrator）；加载 stage → 构造 `TurnManager` → 将阶段变化信号接到 controller 更新 UI/输入锁。
   - 理由：第 3 章 design 已约定第 4 章拆总控；避免 controller 再膨胀 500+ 行。
   - 否决：新建完全替代 controller 的场景脚本。迁移成本高、易破坏 ch2/ch3 验收。

2. **`TurnManager` 用 `RefCounted`，不继承 `Node`。**
   - 方案：`enum TurnPhase { DEPLOY, PLAYER_TURN, ENEMY_TURN, BATTLE_END }`；方法 `start_player_turn()`、`advance_after_unit_action(unit)`、`end_player_turn()`、`start_enemy_turn()`、`advance_enemy_unit()`、`check_battle_end(units) -> bool`。
   - 玩家队列：部署确认后按 `grid_pos.y` 再 `grid_pos.x` 排序（或部署顺序）；每单位 `has_acted` 标志。
   - 理由：可单测阶段转换；与 `BattleController` 风格一致。

3. **部署：点击 `deploy_zones.player` 空格子放置待部署单位；再次点击已放置单位可收回（可选）。**
   - 方案：`DeployPhase` 维护 `pending_templates: Array` 与 `placed: Dictionary`；当前选中模板高亮；点击合法格 `BattleUnit.from_template` + `grid.set_occupant`。
   - 确认条件：所有 `player_units` 模板均已放置。
   - 敌方：`enemy_units` 在确认部署时按 `spawn` 坐标生成，不经过玩家操作。
   - 理由：与格子点击模型一致，无需拖拽系统。

4. **敌方 AI：贪心策略，与 Demo §4.4.3 一致。**
   - 方案：`EnemyAI.decide_action(enemy, grid, all_units) -> Dictionary` 返回 `{action: "attack"|"move"|"wait", target_cell?, target_unit?}`。
   - 攻击：在 `AttackRange.get_attack_targets` 内筛选存活玩家单位，选 HP 最低（同 HP 则 Manhattan 距离最近）。
   - 移动：若无攻击目标，BFS 向「最近玩家单位」靠近，在 `Pathfinding.get_reachable` 中选使得到最近玩家距离最小的一格（ tie-break 随机或固定 y 优先）。
   - 技能：若 `can_use_skill` 且攻击范围内有目标，优先技能（简化：与普攻同一目标选择）；BOSS stub 在 `ai_profile == "boss_default"` 且 `hp/max_hp < 0.5` 时尝试技能。
   - 理由：可单测；M1 验收足够。

5. **输入门控：仅 `PLAYER_TURN` 且 `active_unit.is_player` 且 `unit == active_unit` 时可选手动操作。**
   - 方案：移除默认 Tab 切阵营；`battle_grid_controller` 在 `ENEMY_TURN` / `DEPLOY` 忽略战斗 action bar（部署用独立 UI 状态）。
   - 可选：`OS.is_debug_build()` 下保留 Tab 作弊开关，不写进 spec 验收。
   - 「结束回合」：立即结束玩家回合，未行动友军视为跳过（或禁止结束直至全部行动——设计选 **允许提前结束**，未行动单位本回合不能再动，与火纹类似）。

6. **关卡数据：`data/stages/debug_battle.json` + `DataLoader.get_stage(id)`。**
   - 方案：扩展 `DataLoader` 或 `scripts/autoload/stage_loader.gd`；`battle_scene` 默认加载 `DEBUG_01`（export 变量 `stage_id` 可覆盖）。
   - `map_template` 字段解析为 `res://data/map_templates/{name}.json`。

7. **回合 CD tick 时机。**
   - 方案：玩家点击「结束回合」与敌方回合完全结束后，对 **所有存活单位** 调用 `BattleController.tick_cooldown`（待机仍对当前单位额外 tick，与 ch3 一致或合并为仅回合末 tick——tasks 中统一为 **单位行动后 tick 自身 + 回合末不再重复** 或 **仅回合末全员 tick**；选 **每单位行动结束 tick 自身 CD**，回合末不额外全员 tick，避免双倍）。
   - 与 ch3 一致：待机/攻击/技能后 tick 当前单位；敌方 AI 行动后 tick 该敌军。

8. **测试策略。**
   - `test_turn_manager.gd`：阶段转换、队列推进、round 递增。
   - `test_deploy_phase.gd`：仅 deploy_zone 可放、确认后 occupant 正确。
   - `test_enemy_ai.gd`：mock 网格下选最低 HP、向最近玩家移动一步。

## Risks / Trade-offs

- [Risk] Controller 与 Scene 双总控职责重叠 → Mitigation：`battle_scene` 只握 phase/队列，controller 只响应 `can_control_unit(unit)` 查询。
- [Risk] 敌方 AI 同步执行多步导致 UI 卡顿 → Mitigation：用 `await` 串行 tween 或短 `create_timer` 间隔；单测不依赖动画。
- [Risk] 部署与战斗点击冲突 → Mitigation：DEPLOY 阶段禁用 action bar，高亮 deploy_zone。
- [Trade-off] 玩家可「结束回合」跳过未行动友军 → 简化 UI；后续战役可改强制全员行动。
- [Trade-off] AI 无路径绕墙智能：复用 BFS，与 ch2 一致。
- [Trade-off] 仍从编辑器 F6 启动 `battle.tscn`，主菜单入口第 6 章再接。

## Migration Plan

1. 新增纯逻辑模块 + 单测（RED → GREEN）。
2. 新增 `debug_battle.json` 与 stage 加载。
3. 引入 `battle_scene.gd`，默认 stage 模式；迁移 spawn 逻辑从硬编码 2v2 到 stage 驱动。
4. 扩展 UI（结束回合、turn banner、确认部署）。
5. 手动验收 `DEBUG_01` 全流程；确认 ch1–ch3 单测仍绿；更新 README M1。

## Open Questions

- 玩家「结束回合」是否允许在仍有友军未行动时点击？**暂定：允许**（proposal/design 已写）。
- 部署是否支持多宠？**本章仅 JSON 配置的 1 个 HERO**，UI 显示 4 槽位其中 3 个空。
