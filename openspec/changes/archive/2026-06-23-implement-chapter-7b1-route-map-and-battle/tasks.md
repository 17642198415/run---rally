## 1. GameState + RunManager 扩展（TDD）

- [x] 1.1 RED: `tests/unit/test_game_state_modes.gd` — `start_roguelike_battle` 写入 `current_mode`、`battle_context` 字段、`return_scene_path`
- [x] 1.2 GREEN: `scripts/autoload/game_state.gd` 新增 `start_roguelike_battle(...)` 与 `prepare_roguelike_node(...)`（route_map 用，仅写 context 不设 deploy_list）
- [x] 1.3 RED: `tests/unit/test_run_manager_consume_result.gd` — 普通胜标记节点、hero 阵亡、boss 胜返回 `run_ended`/`victory`、reserve HP 同步
- [x] 1.4 GREEN: `scripts/autoload/run_manager.gd` 实现 `consume_battle_result`；`start_new_run` 初始化 HERO-only `party`
- [x] 1.5 跑 Group 1 单测绿灯

## 2. 主菜单 Run 入口

- [x] 2.1 修改 `scripts/main_menu.gd`：移除 RoguelikeBtn disabled；检测 `run.active` 切换「开始征途」/「继续征途」
- [x] 2.2 新增放弃 Run 交互（按钮或确认对话框）调用 `RunManager.clear()`
- [x] 2.3 新开 Run：`start_new_run(randi())` + `save()` + `change_scene_to_file(route_map.tscn)`
- [x] 2.4 继续 Run：`load_from_meta()` + `change_scene_to_file(route_map.tscn)`
- [x] 2.5 更新 `scenes/main_menu.tscn` 节点（如需放弃按钮）

## 3. 路线图 UI

- [x] 3.1 创建 `scenes/roguelike/route_map.tscn` + `scripts/roguelike/route_map.gd`（MenuStyle 页面壳、侧边栏、6 层竖向节点容器）
- [x] 3.2 从 `RunState.route_graph` + `node_types.json` 渲染节点按钮（颜色/图标/标签）
- [x] 3.3 实现可点击性：当前层 + battle/elite/boss + 未完成；rest/shop/capture_event 灰显 + tooltip
- [x] 3.4 节点点击：`EnemyGroupPicker.pick(layer, is_elite, is_boss, seeded_rng)` → `GameState.prepare_roguelike_node` → `party_setup.tscn`
- [x] 3.5 无 active run 时 redirect 回主菜单

## 4. Party setup 双模式

- [x] 4.1 `party_setup.gd` `_ready` 按 `GameState.current_mode` 分支标题与数据源
- [x] 4.2 ROGUELIKE：读 `RunManager.get_state().reserve`；确认调 `start_roguelike_battle`；返回 `route_map.tscn`
- [x] 4.3 确认 CAMPAIGN 路径零回归（现有单测 + 手动战役流程）

## 5. Battle Roguelike 接入

- [x] 5.1 `battle_scene.gd`：ROGUELIKE 模式从 `battle_context` 加载 `map_template` + `enemies`（非 stage JSON）
- [x] 5.2 开战前 `balls` 取自 `RunState.balls`（`GameState.set_battle_balls` 或等价）
- [x] 5.3 战后 `_handle_roguelike_battle_end`：组装 payload，调 `consume_battle_result`，按返回值跳 `run_summary` 或 `return_scene_path`
- [x] 5.4 Capture 成功：ROGUELIKE 写入 `RunState.reserve`（非 PartyManager）；战役路径不变

## 6. Run 结算页

- [x] 6.1 创建 `scenes/roguelike/run_summary.tscn` + `scripts/roguelike/run_summary.gd`
- [x] 6.2 胜利/失败标题、种子与层数摘要
- [x] 6.3 「返回主菜单」：`RunManager.clear()` + `main_menu.tscn`

## 7. 文档与回归

- [x] 7.1 全量 headless 单测（含新增 2 个 test 文件）
- [x] 7.2 README 进度：第 7B1 进行中/完成，测试数量更新
- [x] 7.3 手动 M3 验收：开 Run → 选 battle 节点 → 编队 → 战斗 → 回路线图 → BOSS 胜/主角阵亡 → summary
- [x] 7.4 勾选 `tasks.md` 全部完成项
