## 1. 测试基础设施

- [x] 1.1 新增 `tests/helpers/scene_test_harness.gd`：`change_scene`、`await_idle`、`find_button`、`press_button`、`assert_current_scene`、`reset_save_defaults`
- [x] 1.2 若 harness 需要：在 `SaveManager` 增加 `reset_to_default_for_tests()`（仅测试调用，不写 disk 或写隔离路径）
- [x] 1.3 更新 `.cursor/skills/godot-unit-testing/SKILL.md`：UI 测试目录、`SceneTree` 多帧等待约定

## 2. 全场景 smoke（`tests/ui/test_ui_scene_smoke.gd`）

- [x] 2.1 战役 4 场景：main_menu / stage_select / party_setup / bestiary_view
- [x] 2.2 肉鸽 5 场景：route_map / rest / shop / reward_pick / run_summary（种子 Run + pending 上下文）
- [x] 2.3 战斗：battle.tscn + battle/ui 子场景 instantiate
- [x] 2.4 本地 headless 跑通该文件

## 3. 导航流 UI 测试

- [x] 3.1 `test_ui_campaign_flow.gd`：战役 → 选关 stage_01 → 编队 → 返回选关/主菜单
- [x] 3.2 `test_ui_roguelike_flow.gd`：开始征途 → 路线图 → 返回主菜单
- [x] 3.3 `test_ui_bestiary_tabs.gd`：灵兽 Tab / 解锁 Tab 切换
- [x] 3.4 `test_ui_battle_shell.gd`：注入 GameState → battle 加载 → HUD 节点存在

## 4. 统一入口与文档

- [x] 4.1 扩展 `tests/run_all_tests.ps1`：扫描 `tests/ui/test_*.gd`，汇总 PASS 计数
- [x] 4.2 README 测试节：说明 unit + ui 双目录、`ALL N TESTS PASSED` 新计数
- [x] 4.3 README MVP 终验：G1 等项标注可由 `tests/ui/*` 自动化覆盖
- [x] 4.4 全量 `run_all_tests.ps1` PASS（34 unit + 新增 ui）

## 5. 回归

- [x] 5.1 修复 headless 下发现的阻塞 crash（若有），优先 harness/测试上下文，其次最小业务 headless 兼容

## 6. 导航流补充（MVP 缺口 · 可 headless 自动化）

对照 README「MVP 终验清单」与当前 5 个 UI 测的覆盖空洞；本节为**未做**项。

- [x] 6.1 `test_ui_bestiary_nav.gd`：主菜单 → **图鉴** → 返回主菜单（补 G1 图鉴入口；`test_ui_bestiary_tabs` 仅测 Tab 未测入口导航）
- [x] 6.2 `test_ui_roguelike_event_flow.gd`：固定 seed Run → 路线图点 **rest** 或 **shop** 节点 → `LeaveBtn` 回路线图（补事件节点串联）
- [x] 6.3 `test_ui_reward_pick_flow.gd`：注入 pending rewards → 点选**无目标**奖励卡 → 断言 pending 清空并回到路线图/结算（补 R4 选卡链路，不测完整战斗）
- [x] 6.4 `test_ui_route_map_structure.gd`：seed=42 新 Run → 路线图 `RouteLayers` 子节点总数在 **8～12**（R1）；层 6 含 boss 节点（unit 已验生成器，本项验 UI 层呈现）
- [x] 6.5 `test_ui_stage_locked.gd`：存档 stage_02=locked → 点第二张关卡卡**不**进编队、仍停留选关（补战役边界）
- [x] 6.6 `test_ui_run_summary_flow.gd`：注入胜利/失败 `get_last_outcome` → `run_summary` 显示 → `MenuBtn` 回主菜单并 `RunManager` 已 clear

## 7. 状态断言补充（harness / unit 延伸）

逻辑层 unit 已有部分覆盖；下列为 MVP 项与测试的**显式挂钩**（缺则补测）。

- [x] 7.1 **R2**：UI 或 harness 断言新 Run 开局 `party` 仅 HERO、`reserve` 为空（可并入 `test_ui_roguelike_flow` 或独立断言）
- [x] 7.2 **B3**：已在 `test_data_loader.gd`；README MVP 表注明「已覆盖」避免重复造轮子
- [x] 7.3 **R6（部分）**：headless 注入 Meta 解锁后 `MetaManager.get_start_balls_bonus()==1` → `start_new_run` 球数=4（`test_run_manager_meta` 延伸或 UI 读 Sidebar `BallsLabel`）
- [x] 7.4 harness：`press_route_node(layer_index, node_index)` 辅助方法，供 6.2/6.4 复用

## 8. 明确不自动化（M4 手动验收 · 记入 tasks 防遗漏）

下列**不**纳入 headless UI（完整回合/目视/关游戏重启）；第 9 章 F5 勾选。

| MVP | 项 | 验证方式 |
|-----|-----|----------|
| B1 | 移动、攻击、技能、克制、地形 | F5/F6 战役关 2 或 battle |
| B2 | 捕捉四档 UI | F5 观察捕捉弹窗 |
| B4 | 图鉴点亮 | 剧本 A/B 捕 1 只后看图鉴 |
| C1 | 3 关含 BOSS | 剧本 A |
| C2 | 进度存档 | 剧本 A 步骤 4（退出 Godot 再进） |
| R3 | 5 地图模板随机 | F5 多次普通战目视地形 |
| R4 | 精英/BOSS 三选一（完整） | 剧本 B/C 实战战后 UI |
| R5 | 失败结算 Meta 保留 | 剧本 B |
| R6 | Meta 解锁可感知 | 剧本 C + 图鉴「解锁」Tab 目视 |
| G2 | 路线图 6 类节点色块 | F5 目视 |

- [ ] 8.1 F5 **剧本 A**（战役新档 ~30 min）→ 勾选 C1/C2/B4
- [ ] 8.2 F5 **剧本 B**（肉鸽失败 ~25 min）→ 勾选 R4/R5
- [ ] 8.3 F5 **剧本 C**（肉鸽通关 ~40 min）→ 勾选 R4/R6/R2/R3
- [ ] 8.4 F5 **B1/B2/G2** 目视项单独勾选

## 9. 文档与计数同步（随 §6/§7 完成而更新）

- [x] 9.1 README MVP 表：为 6.x/7.x 新增自动化项补充 `test_ui_*` 列引用
- [x] 9.2 README 测试节：`ALL N TESTS PASSED` 计数随新增 UI 文件更新
- [x] 9.3 `run_all_tests.ps1` 全绿（unit + 全部 ui）
