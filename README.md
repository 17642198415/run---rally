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

1. **主菜单**：四按钮（开始征途禁用 / 战役 / 图鉴 / 选项占位）
2. **战役**：进入选关 → 新档仅 `stage_01` 可挑战，其余「未解锁」
3. **编队**：HERO 固定出战 + 备用栏勾选 ≤3 只 → 确认出战
4. **战斗**：进入对应地图（草原 / 湿地 / 古堡）；通关后自动回选关并解锁下一关
5. **图鉴**：从主菜单进入 → 显示 8 格 M01~M08 的「未发现 / 已发现 / 已捕获」
6. **进度持久化**：通关一关后退出游戏再进，选关页 `stage_xx` 状态保持

无肉鸽入口，「开始征途」按钮灰显并提示「第 7 章启用」。

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

全部通过时输出 `ALL 20 TESTS PASSED`。

## Tier 1 战斗页美化 手动验收

按 **F6** 运行 `scenes/battle/battle.tscn`：

1. **地形可肉眼区分**：草地（绿浅）、林（绿深）、水（蓝）、墙（暗），部署区在地形之上叠加青绿高亮
2. **单位有圆形头像**：玩家=蓝描边、敌方=红描边、`downed_capturable` 野怪=青描边 + 半透灰度
3. **HUD 三卡片**：左上 `TurnCard`（标题 + 阵营/回合）、右上 `ObjectiveCard`（球数 + 目标）、底部 `ActionBar`（图标按钮）
4. **高亮呼吸**：选中后高亮格透明度 0.30~0.55 缓慢循环
5. **资源缺失回退**：删除任一 `assets/art/units/*.png`（如 `hero.png`）后重新运行，单位仍能显示占位（圆形 + 字符），不报错
6. **可热替换**：把 Kenney 等真实素材按命名约定放到 `assets/art/<section>/`，重启场景后画面切换为正式素材

## 进度

- [x] 第 0 章 环境与工具链
- [x] 第 1 章 项目骨架与数据层
- [x] 第 2 章 网格、地形与移动
- [x] 第 3 章 战斗与克制
- [x] 第 4 章 回合、部署与敌方 AI（→ M1）
- [x] 第 5 章 捕捉、备用栏与图鉴
- [x] 第 6 章 战役模式与主菜单（→ M2）
- [ ] 第 7 章 肉鸽路线图与 Run 状态（→ M3）
- [ ] 第 8 章 三选一奖励、Meta 解锁与打磨
- [ ] 第 9 章 最终验收与发布准备（→ M4）
