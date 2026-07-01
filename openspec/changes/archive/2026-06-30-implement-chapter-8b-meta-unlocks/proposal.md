## Why

第 8A 章已交付精英/BOSS 战后三选一奖励，Run 内成长循环已跑通，但肉鸽仍缺乏**跨 Run 持久进度**：起始球数固定 3、招募池写死 M01~M04、敌组池不含 M05/M08，玩家多次失败后没有可感知的 Meta 回报。Demo 计划第 8 章后半（Meta 解锁 + stats + 解锁页 + 轻量打磨）是 M4 里程碑「3 项 Meta 可解锁可感知」的前置；本轮补齐 8A 刻意延后的 Meta 侧，让通关/探索图鉴能改变下一局体验。

## What Changes

- 新增 `data/meta_unlocks.json`：3 项解锁（`META_BALL` / `META_M05` / `META_M08`），含 `condition` 与 `effect`（对齐 Demo §8.4.2）
- 扩展 `scripts/autoload/meta_manager.gd`：
  - 从 JSON 加载解锁定义；`evaluate_unlocks(save_meta) -> Array[String]` 根据 stats + bestiary 判定新解锁
  - `is_unlocked(id)` / `get_effect(id)` / `get_start_balls_bonus()` / `get_rescue_pool()` / `get_enemy_pool_extras()` 等查询 API
  - `from_dict` / `to_dict` 与 `SaveManager.meta.unlocked` 持久化；`_ready()` 从存档回灌
- Run 结束写 stats：`RunManager.clear()` 或 `run_summary` 路径在 Run 结束前调用 `MetaManager.record_run_end(state, victory)`，更新 `stats`（`runs_started` / `runs_won` / `runs_lost` / `deepest_layer` / `total_captures` / `total_coins_spent`）并 `evaluate_unlocks` + `save_meta`
- 新 Run 应用 Meta：`RunManager.start_new_run` 初始化 `balls = 3 + MetaManager.get_start_balls_bonus()`；`RewardPool.get_rescue_pool()` 改读 Meta 解锁池；`EnemyGroupPicker` / 捕捉事件敌组在抽样时合并 `add_to_pool` 单位
- 图鉴解锁子页：`bestiary_view.tscn` 增加「灵兽 / 解锁」Tab 切换；解锁 Tab 展示 3 项 Meta 卡片（名称、条件文案、已解锁勾 / 进度提示），数据来自 `meta_unlocks.json` + 当前 stats/bestiary
- 轻量打磨（Demo §8.6 子集）：`run_summary` 显示 stats 摘要行；主菜单 Hint 显示 Meta 解锁数；确认路线图已完成节点灰显（若 7B 未完全覆盖则补）；无新增第 4 种 Meta、无 shop_discount（留 v3）
- 新增单测：`test_meta_manager.gd`（条件判定、解锁持久化、effect 查询）、`test_run_manager_meta.gd`（Run 结束写 stats、新 Run 球数 bonus）、扩展 `test_reward_pool.gd`（rescue 池读 Meta）
- 更新 README 进度：「第 8B 章 Meta 解锁与打磨」；测试计数 +2 文件

不在本轮范围：第 4 种 Meta（`META_SHOP`）、进化、永久死亡、全量音效资源、Tier 2 视觉、第 9 章终验清单。

## Capabilities

### New Capabilities

- `meta-unlocks`: Meta 解锁数据、判定逻辑、`MetaManager` API、图鉴解锁子页、Run 结束 stats 写入与新 Run 效果应用

### Modified Capabilities

- `roguelike-core`: `MetaManager` stats 从占位改为实际写入；`RunManager.start_new_run` / `clear` 接入 Meta；修改「stats 不写入」相关 requirement
- `roguelike-rewards`: `RewardPool.get_rescue_pool()` 从 Meta 解锁池读取，替换 8A 硬编码兜底
- `chapter-6-campaign-and-menu`: `bestiary_view` 增加解锁 Tab 与 Meta 进度展示（导航与战役逻辑不变）

## Impact

- **代码**
  - 扩展 `scripts/autoload/meta_manager.gd`
  - 修改 `scripts/autoload/run_manager.gd`、`scripts/roguelike/reward_pool.gd`、`scripts/roguelike/enemy_group_picker.gd`（或等价敌组入口）、`scripts/roguelike/run_summary.gd`
  - 修改 `scripts/campaign/bestiary_view.gd`、`scenes/campaign/bestiary_view.tscn`
- **数据**
  - 新增 `data/meta_unlocks.json`
- **存档**
  - `meta.unlocked` 由空数组变为持久解锁 id 列表；`stats` 字段开始累积（向后兼容：缺键用 0 默认）
- **测试**
  - 新增 2 个测试文件，预计 10~12 个新单测；现有 32 个单测保持 GREEN
- **依赖**
  - 依赖 8A `reward_pool.gd` 的 `get_rescue_pool()` 钩子；依赖 `BestiaryManager` 发现状态作为 META_M05/M08 条件
