## Why

第 9 章 MVP 终验仍依赖 F5 手动剧本（~95 分钟），现有 34 个 headless 单测只覆盖逻辑层（autoload / 纯函数），**不加载场景、不模拟按钮、不验证 `change_scene` 导航**。一旦场景节点路径、`_ready()` 或 UI 接线回归，单测全绿但游戏 crash。需要在**不引入 GUT 插件**的前提下，用 Godot `--headless` 跑**真实场景 UI 测试**，纳入 `tests/run_all_tests.ps1` 一键回归。

## What Changes

- 新增 `tests/helpers/scene_test_harness.gd`：headless 场景加载、`await process_frame`、查找节点、`Button.pressed.emit()`、断言当前场景路径、隔离存档的 `reset_autoloads()` 钩子
- 新增 `tests/ui/` 目录与多份 UI 测试脚本：
  - **全场景 smoke**：15 个 `.tscn` 均可 `_ready()` 不 crash、关键 `@onready` 节点存在
  - **战役导航**：主菜单 → 选关 → 编队 → 返回；主菜单 → 图鉴（双 Tab）→ 返回
  - **肉鸽导航**：主菜单「开始征途」→ 路线图；路线图 → 休息/商店（种子化 Run）；返回主菜单
  - **战斗壳层**：在预设 `GameState` 上下文下加载 `battle.tscn`，断言 HUD / ActionBar 节点存在（不跑完整回合 AI）
- 扩展 `tests/run_all_tests.ps1`：先跑 `tests/unit/`，再跑 `tests/ui/`，输出 `ALL N TESTS PASSED`（N = 34 + 新增 UI 数）
- 更新 `README.md` 测试章节与 `mvp-acceptance` 说明：B3/G1 等项可由 UI 测试部分自动化
- **不**引入 GUT / gdUnit4；**不**做完整剧本 A/B/C 战斗通关自动化（仍留手动）；**不**改游戏业务逻辑（仅测试侧最小 `test_mode` 钩子若阻塞则加）

## Capabilities

### New Capabilities

- `headless-ui-tests`: headless 场景 smoke、UI 导航流、测试 harness、`run_all_tests` 统一入口

### Modified Capabilities

- `mvp-acceptance`: 自动化回归除 34 逻辑单测外，增加 UI 场景测试作为 CI/本地一键门禁

## Impact

- **代码**：`tests/helpers/scene_test_harness.gd`；`tests/ui/test_*.gd`（约 4～6 个）；`tests/run_all_tests.ps1`；可选 `project.godot` 无改动
- **业务脚本**：默认零改动；若 headless 下某场景依赖显示服务器，仅允许加 `OS.has_feature("headless")` 测试旁路（须单测证明）
- **文档**：`README.md` 测试节；`.cursor/skills/godot-unit-testing/SKILL.md` 补充 UI 测试约定
- **依赖**：无新外部包；仍用 Godot 4.6 `--headless --path`
