## Why

第 3 章已交付伤害、克制、技能 CD 与 2v2「手动切换操作方」自由测试，但战场仍缺少真实战棋流程：没有部署摆位、没有玩家/敌方回合轮换、没有敌方 AI 自主行动。第 4 章要在现有 `Grid` / `BattleUnit` / `BattleController` 之上接入 **部署 → 玩家回合 → 结束回合 → 敌方 AI 回合** 的完整循环，并用 `data/stages/debug_battle.json` 跑通一场可从开始到胜/负的战斗，达成里程碑 **M1**。

## What Changes

- 新增 `scripts/battle/turn_manager.gd`：`DEPLOY → PLAYER_TURN → ENEMY_TURN → BATTLE_END` 状态机，维护 `round_number`、双方行动队列、`active_unit`。
- 新增 `scripts/battle/deploy_phase.gd`：玩家在 `deploy_zones.player` 内点击放置单位（测试关 1 主角 + 预留槽位），确认后进入玩家回合。
- 新增 `scripts/battle/enemy_ai.gd`：敌方单位按顺序决策——攻击范围内 HP 最低玩家；否则向最近玩家移动一步（用尽 MOV）；否则待机。预留 BOSS `ai_profile` 接口（HP<50% 用技能，可先 stub）。
- 新增 `scripts/battle/battle_scene.gd`（或等价总控）：加载关卡 JSON、协调 TurnManager / DeployPhase / 现有战斗交互与 `battle_grid_controller` 视图层。
- 新增 `data/stages/debug_battle.json`：验收关卡（`test_grid` 地图，玩家 HERO 部署，敌方 M01+M02 固定出生点）。
- 扩展 `scenes/battle/ui/action_bar.tscn`：增加「结束回合」按钮；新增 `turn_banner.tscn` 显示回合数与当前行动单位。
- 重构 `battle_grid_controller.gd`：移除 Tab 手动切阵营作为默认流程（可保留调试开关）；玩家回合内依次操作全部友军，结束回合后锁定玩家输入直至敌方回合完成。
- 回合末 tick 所有单位技能 CD（与第 3 章「待机 tick」对齐并扩展到回合边界）。
- 同步 `GameState.battle_phase` 与 TurnManager 阶段。
- 补充 headless 单测：`test_turn_manager.gd`、`test_deploy_phase.gd`、`test_enemy_ai.gd`。
- 更新 `README.md` 第 4 章验收说明与 M1 里程碑。

## Capabilities

### New Capabilities

- `chapter-4-turns-deploy-and-ai`：覆盖部署阶段、回合状态机、玩家回合队列与结束回合、敌方 AI 决策、`debug_battle.json` 关卡驱动、回合 UI 与 M1 验收。

### Modified Capabilities

- `chapter-3-combat-and-counter`：战斗场景从「仅自由测试模式」扩展为支持关卡驱动的正式回合流程；**移除**第 3 章「无完整回合轮换」作为 `battle.tscn` 在关卡模式下的约束（手动 Tab 测试改为可选调试，非默认验收路径）。

## Impact

- **代码**：新增 `turn_manager.gd`、`deploy_phase.gd`、`enemy_ai.gd`、`battle_scene.gd`；大幅重构 `battle_grid_controller.gd` 交互与阶段门控；扩展 `action_bar.gd`、新增 `turn_banner` UI；可能扩展 `DataLoader` 读取 `data/stages/*.json`。
- **数据**：新增 `data/stages/debug_battle.json`；复用 `data/map_templates/test_grid.json` 的 `deploy_zones`。
- **Autoload**：`GameState` 的 `BattlePhase` 与战斗场景同步。
- **测试**：`test_turn_manager.gd`、`test_deploy_phase.gd`、`test_enemy_ai.gd`；现有 ch1–ch3 测试保持绿。
- **场景**：`battle.tscn` 挂载 turn banner、结束回合按钮；可用 stage id 或默认 `DEBUG_01` 启动。
- **禁项**：无捕捉、无战役/肉鸽主菜单流程、无图鉴/商店（第 5–7 章）。
- **里程碑**：完成即 **M1**——`debug_battle` 从头打到胜/负无卡死，AI 行为符合设计。
