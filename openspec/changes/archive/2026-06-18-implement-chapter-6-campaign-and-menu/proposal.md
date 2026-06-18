## Why

第 5 章已在 `DEBUG_01` 战斗内跑通捕捉与 `save_meta.json` 持久化，但玩家仍只能 F6 直进调试关，主菜单仍是第 1 章 DataLoader 自检页。第 6 章把「能打的战斗」包装成可展示的 **战役 Demo**：主菜单导航、3 关固定关卡、战前编队（主角 + 已捕获灵兽）、通关解锁与进度存档，并补上第 5 章延后的图鉴 UI。完成本章即达成 **里程碑 M2**。

## What Changes

- 重做 `scenes/main_menu.tscn`：四按钮导航（开始征途占位禁用、战役、图鉴、选项占位）
- 新增 `scenes/campaign/stage_select.tscn`：3 关卡片，显示 locked / unlocked / cleared
- 新增 `scenes/campaign/party_setup.tscn`：战役编队（HERO 固定 + 备用栏最多选 3 宠，共 ≤4 单位）
- 新增 `scenes/campaign/bestiary_view.tscn`：8 格图鉴只读展示（discovered / caught 状态）
- 新增 `scripts/campaign/campaign_manager.gd`（autoload 或 RefCounted + Save 同步）：读写 `save_meta.campaign`，初始仅 `stage_01` 解锁，通关解锁下一关
- 扩展 `GameState`：`start_campaign_battle(stage_id, deploy_list)`，战斗结束回调回 `stage_select`
- 扩展 `battle_scene.gd` / `deploy_phase.gd`：战役模式下 `player_units` 来自编队结果而非仅 stage 内 HERO 模板；球数仍读 stage `player.balls`
- 新增数据：
  - `data/stages/stage_01_border_plain.json`、`stage_02_wet_edge.json`、`stage_03_old_fort_boss.json`
  - `data/map_templates/T_PLAIN.json`、`T_WET.json`、`T_FORT.json`
  - `data/units/BOSS_MERC.json`
- 战斗胜负后：胜利写 campaign 进度 + 保留图鉴/备用栏；失败不写进度、不扣持久化宠
- **MODIFIED**：`chapter-4-turns-deploy-and-ai` — Battle 入口由 `GameState` 战役上下文驱动，不再仅依赖 `@export stage_id = DEBUG_01`
- **非目标**：肉鸽路线图、RunState、Meta 解锁 UI、商店、战役外永久死亡

## Capabilities

### New Capabilities
- `chapter-6-campaign-and-menu`：主菜单、战役选关、战前编队、图鉴 UI、campaign 存档、3 关关卡与地图数据、战役 Battle 回流、M2 验收

### Modified Capabilities
- `chapter-4-turns-deploy-and-ai`：部署阶段支持战役编队传入的多单位 `player_units`；战斗场景支持从 `GameState` 读取 `stage_id` 与 `battle_context`

## Impact

- 场景：`main_menu.tscn` 重写；新增 `scenes/campaign/*`；`battle.tscn` 可能加「返回选关」按钮或自动切场景
- 脚本：新增 `campaign_manager.gd`、`stage_select.gd`、`party_setup.gd`、`bestiary_view.gd`、`main_menu.gd` 重写；改 `game_state.gd`、`battle_scene.gd`、`deploy_phase.gd`
- 数据：3 stage JSON + 3 map template + BOSS_MERC；stage 字段统一用现有 `enemy_units` / `player_units` 键（与 `debug_battle.json` 一致）
- 存档：`SaveManager` 的 `campaign` 字段写入 `stage_XX: locked|unlocked|cleared`
- 测试：新增 `test_campaign_manager.gd`；扩展 `test_stage_loader.gd` 加载 3 关；`test_deploy_phase.gd` 多单位部署用例
- Autoload：视设计将 `CampaignManager` 注册为 autoload
