# Run & Rally

战棋捉宠 Demo（Godot 4.6 + GDScript）。详细实施计划见 [`Demo完整实施计划.md`](./Demo完整实施计划.md)。

## 运行

1. 用 Godot 4.3+（当前工程标记为 4.6）打开本目录的 `project.godot`
2. 按 `F5` 运行主场景（`scenes/main_menu.tscn`），出现 1280×720 窗口即正常

## 目录约定（按 Demo 计划逐章扩展）

```
data/        游戏数据 JSON（单位、技能、关卡、路线池等）
scenes/      Godot 场景（主菜单、战斗、肉鸽路线图等）
scripts/     GDScript（autoload、battle、roguelike、campaign、art）
assets/
  art/         美术资源（tiles 32x32 / units 64x64 / icons 16x16 / ui）
    art_manifest.json   逻辑键 → 路径 + 占位回退索引
```

### 美术资源接入

资源路径与命名约定（详见 `assets/art/art_manifest.json`）：

| 类别 | 路径 | 尺寸 | 命名 |
|---|---|---|---|
| 地形 | `assets/art/tiles/<name>.png` | 32x32 | `plain/forest/water/wall/deploy` |
| 单位 | `assets/art/units/<id>.png` | 64x64 | 模板 ID 小写：`hero/m01/.../m08/boss_merc` |
| 图标 | `assets/art/icons/<name>.png` | 16x16 | `move/attack/skill/capture/wait/end_turn/confirm` |
| UI | `assets/art/ui/<name>.png` | 任意 | `panel_bg/avatar_ring/...` |

**资源缺失时自动回退**：`ArtLoader` autoload 会用代码生成占位图（圆角色块 + 同色描边 + 汉字 fallback），所以业务代码无需感知是否为占位；下载真实素材（如 Kenney pixel pack）放到对应目录即可热替换。文件名 MUST 全小写、kebab-case 或 snake_case、不含中文/空格。

## 第 4 章手动验收（回合、部署与 AI）★ M1

在 Godot 编辑器打开并 **F6** 运行 `scenes/battle/battle.tscn`（关卡 `DEBUG_01`）：

1. **部署**：左侧蓝色部署区点击放置 HERO → 点「确认部署」
2. **玩家回合**：仅当前行动单位可操作 → `[移动][攻击][技能][待机]` → 行动后自动切换；可点「结束回合」
3. **敌方回合**：敌方自动行动（优先攻击范围内 HP 最低玩家，否则向最近玩家移动）
4. **回合显示**：顶部横幅显示「第 N 回合」与当前行动单位
5. 打到一方全灭 → HUD 显示胜负

敌方为 `M01` + `M02`（固定出生点）；无战役入口。

## 第 6 章手动验收（战役模式与主菜单）★ M2

按 **F5** 运行 `scenes/main_menu.tscn`：

1. **主菜单**：四按钮（开始征途 / 战役 / 图鉴 / 选项占位）
2. **战役**：进入选关 → 新档仅 `stage_01` 可挑战，其余「未解锁」
3. **编队**：HERO 固定出战 + 备用栏勾选 ≤3 只 → 确认出战
4. **战斗**：进入对应地图（草原 / 湿地 / 古堡）；通关后自动回选关并解锁下一关
5. **图鉴**：从主菜单进入 → 显示 8 格 M01~M08 的「未发现 / 已发现 / 已捕获」
6. **进度持久化**：通关一关后退出游戏再进，选关页 `stage_xx` 状态保持

「开始征途」进入肉鸽路线图；「选项」仍为占位提示。

## 第 5 章手动验收（捕捉、备用栏与图鉴）

在 Godot 编辑器 **F6** 运行 `scenes/battle/battle.tscn`（关卡 `DEBUG_01`）：

1. **击倒可捕**：把野生 `M01` 打到 0 HP → 单位留在格上（`downed_capturable`），不会立刻消失
2. **捕捉条件**：当前行动玩家单位走到相邻格 → `[捕捉]` 按钮亮起（左上角显示 `球: 3`）
3. **捕捉弹窗**：点 `[捕捉]` → 选青色高亮格 → 弹窗显示成功率档位（高/中/低/极低）与剩余球
4. **成功/失败**：确认后扣 1 球；成功则目标消失并写入图鉴 `caught` + 备用栏；失败目标仍留在场上
5. **持久化**：捕捉成功后关闭游戏再开，`user://save_meta.json` 中 `bestiary.M01.caught` 仍为 `true`

图鉴 UI 面板留到第 6 章主菜单；本章仅数据层 + 战斗内捕捉流程。

## 第 3 章（战斗逻辑，已由第 4 章场景覆盖）

战斗公式、克制、技能 CD 等逻辑仍由 `BattleController` / `combat_calc` 等模块实现；`battle.tscn` 已升级为第 4 章回合流程，不再使用 Tab 手动切阵营。

主菜单（`F5`）仍是第 1 章 DataLoader 自检页。

## 第 2 章（网格移动）

网格、寻路、地形逻辑仍由 `Grid` / `Pathfinding` 提供，在第 4 章战斗中复用。

## 测试

一键跑全部单元测试：

```powershell
powershell -ExecutionPolicy Bypass -File "tests\run_all_tests.ps1"
```

或逐个运行：

```powershell
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_data_loader.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_terrain_types.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_grid.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_pathfinding.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_weapon_triangle.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_combat_calc.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_battle_controller.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_attack_range.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_battle_unit.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_battle_setup.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_turn_manager.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_deploy_phase.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_enemy_ai.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_stage_loader.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_capture_system.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_bestiary_manager.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_party_manager.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_save_manager.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_campaign_manager.gd"
& "D:\develop\Godot_v4.6.3-stable_win64.exe" --headless --script "tests\unit\test_art_loader.gd"
```

全部通过时输出 `ALL 46 TESTS PASSED`（34 个 `tests/unit/` + 12 个 `tests/ui/`）。

`run_all_tests.ps1` 会先跑 `unit/`，再跑 `ui/`；若 `.godot/global_script_class_cache.cfg` 为空会自动执行一次 `godot --import`（注册 `MenuStyle`、`RunState` 等 `class_name`，headless 场景测试依赖此项）。

**UI 测试**（`tests/ui/`，headless 加载真实 `.tscn`、模拟 `Button.pressed`、断言场景路径）：

- `test_ui_scene_smoke.gd` — 全 15 场景 + battle/ui 子场景可实例化
- `test_ui_campaign_flow.gd` — 主菜单 → 战役 → 选关 → 编队 → 返回
- `test_ui_roguelike_flow.gd` — 开始征途 → 路线图 → 返回；新 Run 仅 HERO（R2）
- `test_ui_bestiary_tabs.gd` — 图鉴灵兽/解锁 Tab 切换
- `test_ui_bestiary_nav.gd` — 主菜单 → 图鉴 → 返回（G1）
- `test_ui_roguelike_event_flow.gd` — 路线图 → 休息 → 回路线图
- `test_ui_reward_pick_flow.gd` — 精英战后三选一选卡 → pending 清空（R4 部分）
- `test_ui_route_map_structure.gd` — 6 层路线图节点数与 boss 呈现（R1）
- `test_ui_stage_locked.gd` — 未解锁关卡无进入按钮
- `test_ui_run_summary_flow.gd` — 通关结算 → 主菜单并 clear Run
- `test_ui_meta_start_balls.gd` — META_BALL 后新 Run 球数=4（R6 部分）
- `test_ui_battle_shell.gd` — 注入 GameState 后 battle HUD 存在

共享 harness：`tests/helpers/scene_test_harness.gd`（`change_scene`、`await_idle`、`press_button`、`reset_save_defaults`、`setup_run_for_node_type`、`press_route_node_on_current_layer`、`assert_new_run_roster` 等）。

第 7B1 章新增 2 个测试文件：`test_game_state_modes.gd`、`test_run_manager_consume_result.gd`。

第 7B2 章新增 3 个测试文件：`test_run_manager_event_node.gd`（`complete_event_node`、战斗掉币）、`test_shop_catalog.gd`（商店 3 槽种子可复现）、`test_node_handlers.gd`（6 类型节点分发）。

第 8A 章新增 2 个测试文件：`test_reward_pool.gd`（奖励池抽取与应用）、`test_run_manager_rewards.gd`（精英/BOSS 战后 pending 奖励）。

第 8B 章新增 2 个测试文件：`test_meta_manager.gd`（Meta 解锁判定与 effect）、`test_run_manager_meta.gd`（Run 结束 stats 与新 Run 球数 bonus）。

## Tier 1 战斗页美化 手动验收

按 **F6** 运行 `scenes/battle/battle.tscn`：

1. **地形可肉眼区分**：草地（绿浅）、林（绿深）、水（蓝）、墙（暗），部署区在地形之上叠加青绿高亮
2. **单位有圆形头像**：玩家=蓝描边、敌方=红描边、`downed_capturable` 野怪=青描边 + 半透灰度
3. **HUD 三卡片**：左上 `TurnCard`（标题 + 阵营/回合）、右上 `ObjectiveCard`（球数 + 目标）、底部 `ActionBar`（图标按钮）
4. **高亮呼吸**：选中后高亮格透明度 0.30~0.55 缓慢循环
5. **资源缺失回退**：删除任一 `assets/art/units/*.png`（如 `hero.png`）后重新运行，单位仍能显示占位（圆形 + 字符），不报错
6. **可热替换**：把 Kenney 等真实素材按命名约定放到 `assets/art/<section>/`，重启场景后画面切换为正式素材

## Tier 1 菜单页美化 手动验收

按 **F5** 运行 `scenes/main_menu.tscn`，走战役全流程：

1. **主菜单卡片化**：居中圆角深色面板 + 四按钮统一样式；「开始征途」可进肉鸽；「选项」灰显占位提示
2. **选关三态卡片**：`stage_01` 可挑战（蓝边框）、未解锁关卡灰卡、「已通关」金边框
3. **编队 HERO 突出**：HERO 行金色左边框 + ★；备用栏每行含圆形头像占位 + CheckBox
4. **图鉴双 Tab**：「灵兽」8 格网格（未发现=`?` 灰、已发现=黄标、已捕获=绿标 + 头像）；「解锁」Tab 显示 META 条目与解锁状态
5. **全流程导航**：主菜单 → 战役 / 开始征途 / 图鉴 → 返回，无 crash
6. **资源缺失回退**：删除 `assets/art/ui/panel_bg.png`（若存在）后重进菜单，仍显示 Flat 卡片背景，不报错

## MVP 终验清单 ★ M4

对照 Demo 计划 §9.3。自动化项由 `tests/run_all_tests.ps1`（46 个：34 unit + 12 ui）覆盖逻辑与场景导航；其余按 **F5** 手动勾选。

**可由 `tests/ui/*` 部分覆盖：** G1（战役/肉鸽/图鉴入口）、R1/R2/R4（部分）/R6（部分）、图鉴 Tab；G2 路线图节点色块需 F5 目视。

### 共用战斗层

| # | 标准 | 验证方法 | ☐ |
|---|------|----------|---|
| B1 | 移动、攻击、技能、克制、地形分工明确 | 战役关 2（飞行+水域）或 F6 `battle.tscn` | |
| B2 | 捕捉成功率 UI 四档 | 同一单位不同 HP 档观察捕捉弹窗 | |
| B3 | 8 种灵兽数据就绪 | `test_data_loader.gd` 断言 M01–M08（已自动化） | |
| B4 | 图鉴可点亮 | 战役或肉鸽各捕 1 只 → 图鉴「灵兽」Tab | |

### 战役

| # | 标准 | 验证方法 | ☐ |
|---|------|----------|---|
| C1 | 3 关可打通含 BOSS | 新档连续通关 stage_01→03 | |
| C2 | 进度可存档 | 重启后选关页 stage 状态正确 | |

### 肉鸽

| # | 标准 | 验证方法 | ☐ |
|---|------|----------|---|
| R1 | 6 层路线，分支节点呈现 | `test_ui_route_map_structure` + `test_route_generator`；F5 目视 G2 | |
| R2 | 主角+0 宠开局，路上捕捉 | `test_ui_roguelike_flow` 断言开局 roster；捕捉入队需 F5 | |
| R3 | 5 地图模板随机 | 多次普通战观察地形差异（PLAIN/WET/FORT/FOREST/MIX） | |
| R4 | 精英/BOSS 三选一 | `test_ui_reward_pick_flow`（选卡链路）；完整战后 UI 见剧本 B/C | |
| R5 | Run 失败结束，Meta 保留 | 主角阵亡 → 失败结算；图鉴/Meta 仍在 | |
| R6 | 3 项 Meta 可解锁可感知 | `test_ui_meta_start_balls` + `test_run_manager_meta`；图鉴「解锁」Tab 目视 | |

### 通用

| # | 标准 | 验证方法 | ☐ |
|---|------|----------|---|
| G1 | 主菜单进两种模式 | `test_ui_campaign_flow` / `test_ui_roguelike_flow` / `test_ui_bestiary_nav` | |
| G2 | 占位美术可区分 | 路线图 6 类节点颜色/图标可辨 | |

## 回归测试剧本

预估合计 ~95 分钟，可分次执行。每剧本走通后在上方终验表勾选对应项。

### 剧本 A — 战役新档（~30 min）

1. 删除或备份 `user://save_meta.json`（新档）→ **战役** → 关 1 → 捕 M01 → 胜
2. 关 2 带 M01 → 捕 M04 → 胜
3. 关 3 BOSS → 尝试捕 M08 → 胜
4. 退出 Godot 再 F5 → 选关进度与图鉴仍在

### 剧本 B — 肉鸽失败 Run（~25 min）

1. **开始征途** → 层 1 普通战 → 胜
2. 层 2 休息 → 层 3 精英 → 三选一 → 胜
3. 层 4 故意让主角阵亡 → 失败结算
4. 确认图鉴 / Meta「解锁」Tab 数据未丢

### 剧本 C — 肉鸽通关 Run（~40 min）

1. 新 Run → 保守路线多休息
2. 商店买球 → 捕捉事件捕 1 只
3. 层 6 BOSS → 胜 → 通关结算
4. 若已解锁 META_BALL，新 Run 开局球数应为 **4**

## 已知限制与 v3 Backlog

**Demo 预期内（非 bug）：**

- 无永久死亡、无进化、无异常状态（毒/麻痹/燃烧）
- 反击未实现
- Meta 仅 3 项（`META_BALL` / `META_M05` / `META_M08`）；`META_SHOP`、`META_HP` 为 v3
- 美术均为色块/圆形占位，非正式素材
- **Run 中途存档**：7A 起活跃 Run 写入 `save_meta.json` 的 `run` 节；主菜单「开始征途」可续局（非「关游戏即丢 Run」）

**v3 Backlog（不实现）：** 永久死亡模式、异常状态、Lv5 进化、8 层路线与难度阶、装备掉落、每日 Seed 排行。

## Windows 导出（可选）

1. Godot **Project → Export** → **Add…** → **Windows Desktop**
2. 安装导出模板（Editor → Manage Export Templates）若尚未安装
3. 导出路径设为 `builds/demo/RunAndRally.exe`（目录可导出时自动创建）
4. 运行 exe，重复剧本 A 首关 smoke 测试

> 注：`export_presets.cfg` 含本机路径，已在 `.gitignore` 中，不提交仓库。

未安装导出模板时不阻塞 M4；编辑器 F5 验收即可。

## 进度

- [x] 第 0 章 环境与工具链
- [x] 第 1 章 项目骨架与数据层
- [x] 第 2 章 网格、地形与移动
- [x] 第 3 章 战斗与克制
- [x] 第 4 章 回合、部署与敌方 AI（→ M1）
- [x] 第 5 章 捕捉、备用栏与图鉴
- [x] 第 6 章 战役模式与主菜单（→ M2）
- [x] 第 7A 章 肉鸽核心（RunState / RouteGenerator / EnemyGroupPicker / RunManager / 数据底座）
- [x] 第 7B1 章 路线图 UI 与战斗接入（→ M3）
- [x] 第 7B2 章 休息/商店/捕捉事件节点
- [x] 第 8A 章 三选一奖励（精英/BOSS 战后）
- [x] 第 8B 章 Meta 解锁与打磨
- [ ] 第 9 章 最终验收与发布准备（→ M4）
