## 1. 数据与 MetaManager 核心

- [x] 1.1 新建 `data/meta_unlocks.json`（META_BALL / META_M05 / META_M08，对齐 Demo §8.4.2）
- [x] 1.2 新建 `tests/unit/test_meta_manager.gd`：加载 3 条定义；`or` 条件解锁 META_BALL；bestiary 条件解锁 M05/M08；`get_start_balls_bonus` / `get_pool_extras`；`to_dict`/`from_dict` 圆环
- [x] 1.3 扩展 `scripts/autoload/meta_manager.gd`：`load_definitions`、`evaluate_unlocks`、`record_run_end`、`get_start_balls_bonus`、`get_pool_extras`、Save 回灌
- [x] 1.4 扩展 `SaveManager.merge_with_defaults`：补齐 `stats` 六键默认值 0（若尚未覆盖）

## 2. Run 生命周期接入

- [x] 2.1 新建 `tests/unit/test_run_manager_meta.gd`：BOSS 胜/失败 Run 写 stats；`clear()` 后 stats 保留；新 Run `balls==4`（META_BALL 已解锁）
- [x] 2.2 修改 `RunManager.start_new_run`：应用 `get_start_balls_bonus()`
- [x] 2.3 修改 `RunManager.clear()` 与 BOSS 胜进入 `run_summary` 路径：调用 `MetaManager.record_run_end` + `evaluate_unlocks` + `save_meta`
- [x] 2.4 修改 `scripts/roguelike/run_summary.gd`：摘要行显示征途次数 / 最深层次 / Meta X/3

## 3. Meta 效果应用到池子

- [x] 3.1 修改 `RewardPool.get_rescue_pool()`：合并 `MetaManager.get_pool_extras()`；扩展 `test_reward_pool.gd` 断言
- [x] 3.2 修改 `EnemyGroupPicker`（或等价入口）：层 3~5 普通/精英与 capture_event 可按 Meta 池替换一只敌人；单测覆盖 M05 入池
- [x] 3.3 `BestiaryManager` 发现/捕获写盘后触发 `MetaManager.evaluate_unlocks`（仅新解锁时 save）

## 4. 图鉴解锁 Tab UI

- [x] 4.1 改 `scenes/campaign/bestiary_view.tscn`：灵兽/解锁 Tab 按钮 + 解锁列表容器
- [x] 4.2 改 `scripts/campaign/bestiary_view.gd`：`_refresh_unlock_tab()` 渲染 3 张 Meta 卡（名称、条件、锁定/已解锁徽章）；Tab 切换不破坏现有 8 格逻辑
- [x] 4.3 验证：无存档全锁定；DEBUG 发现 M05 后解锁 Tab 显示 META_M05 已解锁

## 5. 轻量打磨与文档

- [x] 5.1 复查 `route_map.gd` 已完成节点灰显（若缺失则补 `modulate`）
- [x] 5.2 README 进度勾选「第 8B 章 Meta 解锁与打磨」；测试计数 +2 文件（`test_meta_manager` / `test_run_manager_meta`）
- [x] 5.3 全量 `tests/run_all_tests.ps1` PASS（32 + 新增 ≥10）
- [ ] 5.4 F5 手动验收：通关或到层 5 → 新 Run 球=4；发现 M05 → 解锁 Tab + 招募池含 M05；失败 Run 后 Meta 仍在
