## Why

第 7A 章已经把肉鸽核心数据/逻辑（`RunState`、`RouteGenerator`、`EnemyGroupPicker`、`RunManager` 持久化）打通到 25 个 headless 单测全绿，但还**完全没有 UI**，玩家无法实际开始一次 Run。本 change（7B1）为里程碑 M3 提供**最小可玩闭环**：从主菜单开新 Run → 看到 6 层路线图 → 选战斗节点 → 编队 → 战斗 → 胜/负回路线图或结算页 → 通关 BOSS 或主角阵亡触发结束。

非战斗节点（`rest` / `shop` / `capture_event`）暂不实现交互，**在路线图上以灰色不可点呈现**，留给下一个 change（7B2）。

## What Changes

- **新场景**：`scenes/roguelike/route_map.tscn`（竖向 6 层路线图，侧边栏显示队伍/球/币/层数）、`scenes/roguelike/run_summary.tscn`（Run 结算页：胜利/失败 + 回主菜单）
- **新脚本**：`scripts/roguelike/route_map.gd`、`scripts/roguelike/run_summary.gd`、`scripts/roguelike/run_battle_bridge.gd`（在战斗胜负回调里调用 `RunState.mark_node_completed` + `RunManager.save` 的桥接逻辑）
- **主菜单入口**：`scripts/main_menu.gd` 解锁「开始征途」按钮，根据 `SaveManager.load_meta().run.active` 显示「开始征途」或「继续征途 + 放弃」二选一
- **`party_setup.tscn` 双模式复用**：通过 `GameState.current_mode` 区分数据源
  - `CAMPAIGN` 模式：读 `PartyManager.reserve`（既有行为，不变）
  - `ROGUELIKE` 模式：读 `RunState.reserve`，确认后写入 `GameState.battle_context.deploy_list`、设定 `return_scene_path = res://scenes/roguelike/route_map.tscn`，进战斗
- **`GameState` 扩展**：新增 `start_roguelike_battle(node_id, enemies, map_template, is_elite, is_boss, deploy_list)` 与对应的 `battle_context` 字段（`run_node_id` / `enemies` / `map_template` / `is_elite` / `is_boss`），用于战斗场景识别敌组与回路逻辑
- **`battle_scene.gd` 接 Roguelike 分支**：新增 `_handle_roguelike_battle_end(result)`，胜利时调用 `RunManager.get_state().mark_node_completed()` + `RunManager.save()`、回路线图；BOSS 胜或主角阵亡（按 `RunState.hero_dead`）→ 跳转 `run_summary.tscn`
- **节点点击交互**：路线图只允许点击「当前层 + 类型为 `battle`/`elite`/`boss`」的节点；`rest`/`shop`/`capture_event` 显示但置灰、tooltip 提示「下一章节启用」
- **战斗敌组**：`EnemyGroupPicker.pick(layer, is_elite, is_boss, rng)` 返回的 `enemies` + `map_template` 由 `battle_scene` 在 ROGUELIKE 模式下作为敌方数据源（替代战役 stage 的固定敌组）
- **失败判定**：仅当 `HERO` 单位 `hp <= 0`（或被标记为无法行动）时设置 `RunState.hero_dead = true` 并跳 `run_summary`；其他出战单位阵亡仅从本战移除，不影响 `RunState.reserve`（已死亡的 reserve 单位从 reserve 移除，存活回流）

## Capabilities

### New Capabilities
- `roguelike-ui`: 路线图 UI、Run 结算页、主菜单 Run 入口、肉鸽编队复用模式、战斗场景的 Roguelike 接入逻辑

### Modified Capabilities
- `roguelike-core`: `RunManager` 新增 `consume_battle_result(node_id, result, surviving_units)` 接口（封装"标记节点完成 + 处理 reserve 存活/阵亡 + 检测 hero_dead + 自动 save"的逻辑），保持单测可测；`GameState` 在 `roguelike-core` spec 中目前没有覆盖，本次也不动 `GameState` 的 `core` 行为，仅在 `roguelike-ui` 内描述新增字段
- `chapter-6-campaign-and-menu`: 主菜单「开始征途」按钮从 placeholder（disabled）变为 functional；`party_setup.tscn` 新增 ROGUELIKE 模式分支（数据源切换 + 返回路径切换）

## Impact

- **代码**：
  - 新增：`scripts/roguelike/route_map.gd`、`run_summary.gd`、`run_battle_bridge.gd` 及对应 `.tscn`
  - 修改：`scripts/main_menu.gd`、`scripts/campaign/party_setup.gd`、`scripts/battle/battle_scene.gd`、`scripts/autoload/game_state.gd`、`scripts/autoload/run_manager.gd`
- **测试**：新增 `tests/unit/test_run_manager_consume_result.gd`（验证 consume_battle_result 的副作用：节点标记、reserve 同步、hero_dead 检测、自动 save），新增 `tests/unit/test_game_state_modes.gd`（验证 `start_roguelike_battle` 写入 battle_context）。UI 场景不做 headless 单测，仅手动验收
- **数据**：无新增数据文件（沿用 7A 落盘的所有 JSON）
- **依赖**：依赖 7A 的 `RunState`、`RouteGenerator`、`EnemyGroupPicker`、`RunManager`、`SaveManager.run` 节
- **不破坏**：战役模式（CAMPAIGN）的所有现有行为保持兼容；`party_setup.tscn` 在没有 `GameState.current_mode == ROGUELIKE` 时走原战役分支
