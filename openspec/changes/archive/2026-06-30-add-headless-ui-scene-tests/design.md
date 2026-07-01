## Context

- 现有测试：`tests/unit/*.gd` + `SceneTree._initialize()` + `test_assertions.gd`；`run_all_tests.ps1` 只扫 `unit/`。
- 15 个游戏场景（主菜单、战役 4 页、肉鸽 5 页、战斗及子 UI）均无自动化加载验证。
- 第 1 章设计刻意**不引入 GUT**；第 9 章归档后手动 F5 仍是 M4 缺口。
- Godot 4.6 `--headless --path` 可 `change_scene_to_packed`、emit 信号、跑 `_process`；DisplayServer 无窗口但 Control 树可用。

约束：Windows UTF-8；不新增 npm/插件；业务改动最小；34 既有单测保持 PASS。

## Goals / Non-Goals

**Goals:**

- `tests/ui/` 下 headless **真实场景**测试：实例化 `.tscn`、触发 `Button.pressed`、断言 `current_scene` 路径
- **全场景 smoke**：仓库内全部 `scenes/**/*.tscn` 可加载且关键节点存在
- **导航流**：战役（G1 部分）、肉鸽入口（G1）、图鉴 Tab、路线图返回
- **战斗壳层**：`battle.tscn` 在注入 `GameState` 上下文后可进入部署/HUD 态
- `run_all_tests.ps1` 统一跑 unit + ui，一条命令全绿

**Non-Goals:**

- GUT / gdUnit4 / Playwright / 导出 Web
- 完整回合战斗、捕捉成功率四档、剧本 A/B/C 通关（仍手动）
- 像素/视觉回归、截图对比
- 性能压测

## Decisions

### D1 — 扩展既有 harness，不引入 GUT

- **决定**：新增 `SceneTestHarness`（`tests/helpers/scene_test_harness.gd`），复用 `Assertions`；UI 测试仍为 `extends SceneTree` 脚本，`godot --headless --path --script tests/ui/xxx.gd`
- **理由**：与 34 单测同入口、零插件、CI 友好
- **否决 GUT**：额外 addon、学习成本、与现有 `finish()` 约定分裂

### D2 — 场景测试用「独立 SceneTree 进程」而非单进程聚合

- **决定**：每个 `tests/ui/test_*.gd` 独立进程（与 unit 一致），进程内可多次 `change_scene`
- **理由**：场景切换污染 autoload 状态；独立进程隔离简单
- **.harness**：提供 `reset_meta_to_defaults()` 写临时 `user://` 或使用 `SaveManager` 内存默认（若可注入则 mock 字典）

### D3 — 存档隔离：测试专用 meta 快照

- **决定**：harness 在 UI 测试开头调用 `SaveManager` 默认档 + 清空 `run.active`；战役测试用固定 `stage_01` unlocked 种子档（内存 merge，不写真实 user 路径若可绕过）
- **理由**：导航测试需可重复；不依赖用户删 `save_meta.json`
- **实现**：优先在 harness 内 `save_mgr._meta_cache = save_mgr.get_default_save()`（若 API 无私有字段，则增 `SaveManager.reset_to_default_for_tests()` 公开方法——唯一允许的业务侧小钩子）

### D4 — 全场景 smoke 列表

| 场景 | 断言要点 |
|------|----------|
| `main_menu` | 四按钮 + HintLabel |
| `stage_select` | StageList 容器 |
| `party_setup` | HeroCard / ReserveList |
| `bestiary_view` | Tab + Grid |
| `route_map` | 需先 `RunManager.start_new_run(42)` |
| `rest` / `shop` | 需活跃 Run + `GameState` 节点上下文 |
| `reward_pick` | 需 `RunManager` pending rewards |
| `run_summary` | 需 Run 结束态或 mock |
| `battle` | 需 `GameState.start_campaign_battle` 或 roguelike context |
| `battle/ui/*` | 子场景可 `instantiate` + 子节点存在 |

### D5 — 导航测试分层

1. `test_ui_scene_smoke.gd` — 上表全覆盖（最宽）
2. `test_ui_campaign_flow.gd` — 主菜单 → 战役 → 选关点击 stage_01 → 编队 → Back
3. `test_ui_roguelike_flow.gd` — 开始征途 → 路线图层 1 节点存在 → Back
4. `test_ui_bestiary_tabs.gd` — 灵兽/解锁 Tab 切换无 crash
5. `test_ui_battle_shell.gd` — DEBUG_01 或 stage_01 deploy 后 HUD 节点

### D6 — `run_all_tests.ps1` 扩展

```powershell
$unitFiles = Get-ChildItem "$testsDir\unit\test_*.gd"
$uiFiles   = Get-ChildItem "$testsDir\ui\test_*.gd"
# 合并排序后执行；失败任一 exit 1
```

README 更新为 `ALL (34 + M) TESTS PASSED`。

### D7 — headless 旁路（仅必要时）

若某 `_ready()` 访问 `DisplayServer.window_get_size()` 等，在业务代码加：

```gdscript
if not DisplayServer.get_name().is_empty(): # or OS.has_feature("headless")
```

优先在测试中 stub；仅当 crash 时改业务 1 行。

## Risks / Trade-offs

- [route_map 无 Run 则跳主菜单] → smoke 前 `RunManager.start_new_run(42); save()`
- [reward_pick 需 pending] → smoke 用 `RunManager` API 注入 pending 或跳过该场景仅测 instantiate  detached
- [战斗完整流程过长] → 只测 shell，不测 AI 回合
- [测试变慢] → UI 约 +10～20s；可接受
- [SaveManager 测试钩子] → 仅 `reset_to_default_for_tests()` 一条公开 API

## Migration Plan

1. 实现 harness + `SaveManager` 测试重置（若需要）
2. 实现 smoke → 导航 → battle shell
3. 扩展 `run_all_tests.ps1`
4. 全绿后更新 README / skill
5. 回滚：删除 `tests/ui/` 与 harness 扩展，`run_all_tests` revert

## Open Questions

- `SaveManager` 是否已有可复用的测试重置？apply 时先读代码再定是否新增 API。
- `rest.tscn` / `shop.tscn` 是否要求从 `route_map` 跳入才 `_ready` 成功？apply 时按实际调整 seed 上下文。
