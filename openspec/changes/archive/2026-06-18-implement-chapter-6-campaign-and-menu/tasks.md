## 1. 测试骨架（先 RED）

- [x] 1.1 新建 `tests/unit/test_campaign_manager.gd`：新档仅 stage_01 unlocked；clear stage_01 解锁 stage_02；locked 关不可 `can_enter`；`to_dict`/`from_dict` 圆环
- [x] 1.2 扩展 `tests/unit/test_stage_loader.gd`：加载 stage_01/02/03 + T_PLAIN/T_WET/T_FORT 地图非空
- [x] 1.3 扩展 `tests/unit/test_deploy_phase.gd`：campaign_setup 模式下 HERO+M01 双模板部署确认
- [x] 1.4 跑全量测试确认新增用例 RED（旧 18 个仍 PASS）

## 2. 数据：地图、关卡、BOSS

- [x] 2.1 新建 `data/map_templates/T_PLAIN.json`（10×10，左右部署区，草原地形）
- [x] 2.2 新建 `data/map_templates/T_WET.json`（含水地形，飞行优势可测）
- [x] 2.3 新建 `data/map_templates/T_FORT.json`（墙/要塞地形）
- [x] 2.4 新建 `data/units/BOSS_MERC.json`（boss tag、S_BERSERK、ai_profile boss_default、不可捕）
- [x] 2.5 新建 `data/stages/stage_01_border_plain.json`（2×M01+1×M02，party_source campaign_setup，balls 3，unlock_next stage_02）
- [x] 2.6 新建 `data/stages/stage_02_wet_edge.json`（M03/M04/M06/M01，unlock_next stage_03）
- [x] 2.7 新建 `data/stages/stage_03_old_fort_boss.json`（BOSS_MERC+小怪+M08，unlock_next 空）
- [x] 2.8 确认 `DataLoader.load_all()` 能索引新 stage id（文件名 id 字段一致）

## 3. CampaignManager + Save

- [x] 3.1 新建 `scripts/campaign/campaign_manager.gd` autoload：`STAGE_ORDER`、`get_status`、`can_enter`、`mark_cleared`、`ensure_defaults`
- [x] 3.2 `project.godot` 注册 `CampaignManager`；`_ready` 从 `SaveManager.load_meta().campaign` 回灌
- [x] 3.3 通关/初始档写入 `save_meta.campaign`（与 Bestiary/Party 合并写）
- [x] 3.4 跑 `test_campaign_manager.gd` GREEN

## 4. GameState + Deploy + Battle 战役分支

- [x] 4.1 扩展 `game_state.gd`：`start_campaign_battle(stage_id, deploy_list)`、`return_scene_path`、`current_mode = CAMPAIGN`
- [x] 4.2 扩展 `deploy_phase.gd`：若 stage `player.party_source == "campaign_setup"`，用 `GameState.battle_context.deploy_list` 构建 `pending_templates`（支持 reserve 的 template_id + 自定义 unit_id）
- [x] 4.3 改 `battle_scene.gd`：`_begin_stage` 优先读 `GameState.stage_id`（战役）否则 `@export stage_id`（DEBUG）；战役 `BATTLE_END` 调 `CampaignManager.mark_cleared`（胜）、`save_meta`、切 `stage_select.tscn`
- [x] 4.4 战役失败不修改 campaign/reserve；胜利后捕捉仍追加 reserve
- [x] 4.5 跑 stage_loader + deploy_phase 扩展测试 GREEN

## 5. 战役 UI 场景

- [x] 5.1 新建 `scripts/campaign/stage_select.gd` + `scenes/campaign/stage_select.tscn`：3 卡片、状态、返回主菜单、进入 party_setup
- [x] 5.2 新建 `scripts/campaign/party_setup.gd` + `scenes/campaign/party_setup.tscn`：HERO 固定 + reserve 多选 ≤3、确认开战
- [x] 5.3 新建 `scripts/campaign/bestiary_view.gd` + `scenes/campaign/bestiary_view.tscn`：8 格 M01~M08 发现/完成只读
- [x] 5.4 重写 `scripts/main_menu.gd` + `scenes/main_menu.tscn`：四按钮导航；开始征途禁用/提示；选项占位

## 6. 整合与手动验收

- [x] 6.1 `battle.tscn` 战役结束时显示简短胜/败文案后自动/按钮回选关（避免卡在战斗场景）
- [x] 6.2 README：第 6 章手动验收（M2）、主菜单 F5 流程、进度勾选第 6 章；更新测试列表
- [x] 6.3 全量 `tests/run_all_tests.ps1` PASS（预期 ≥19 个测试）
- [ ] 6.4 编辑器手动：新档 → 战役 stage_01 → 编队 → 胜 → stage_02 解锁 → 打通 3 关 → 重启进度仍在；图鉴页可见已捕种类
