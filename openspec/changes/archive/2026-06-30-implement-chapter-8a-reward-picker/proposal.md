## Why

第 7 章肉鸽核心（7A/7B1/7B2）已交付：路线图、6 类节点、休息/商店/捕捉事件、Run 状态与存档全部跑通。但目前**精英战与 BOSS 战胜利只发普通金币**，玩家在 Run 中缺乏「轮次内成长」的关键反馈循环。Demo 计划第 8 章的「三选一奖励」正是补齐这块——它直接决定 Run 的策略深度（球/HP/单点强化/招募）与节奏（精英战值不值得打）。

为保持节奏可控、便于单测覆盖，本轮把 Demo 第 8 章按 7A/7B1/7B2 同样的方式拆分：**8A 只做奖励池数据 + 三选一弹窗 + 战斗胜利钩子**；Meta 解锁、stats 统计、解锁页 UI 与全局数值打磨归入后续 8B。本轮交付完成后，玩家在每次精英/BOSS 胜利后看到 3 张奖励卡牌，选 1 张直接应用到 `RunState`，再回到路线图。

## What Changes

- 新增数据 `data/route/reward_pool.json`：7 种奖励（`R_BALL` / `R_HEAL` / `R_ATK` / `R_HP` / `R_SKILL` / `R_COIN` / `R_RESCUE`），含 `id / name / desc / effect`；顶层 `boss_weight_bonus` 数组列出 BOSS 战权重加成的奖励 id（`R_ATK` / `R_SKILL` / `R_RESCUE`）
- 新增 `scripts/roguelike/reward_pool.gd`（纯静态模块）：`load_pool()`、`pick_three(rng, is_boss) -> Array[Dictionary]`（不放回随机 3 张；BOSS 战时把 `boss_weight_bonus` 的权重 ×2）、`apply_reward(state, reward, target_unit_id) -> bool`（把 effect 应用到 `RunState`，含失败回滚）
- 新增 `scripts/roguelike/reward_picker.gd` + `scenes/roguelike/reward_pick.tscn`：纯 UI 场景，从 `RunManager.get_pending_rewards()` 读取 3 张卡，玩家点选 1 张后调用 `RunManager.apply_reward_choice(reward_id, target_unit_id)`，再回到 `route_map.tscn`
- 修改 `scripts/autoload/run_manager.gd`：
  - 新增 `_pending_rewards: Array` 字段与 `roll_post_battle_rewards(is_boss, rng_or_null)` / `get_pending_rewards()` / `apply_reward_choice(reward_id, target_unit_id)` / `clear_pending_rewards()` 接口
  - 修改 `consume_battle_result`：在「精英胜利」「BOSS 胜利」时不再直接 `save()` 后返回，而是先 `roll_post_battle_rewards(...)`、再 `save()`；返回值新增字段 `pending_rewards: bool`（普通胜利 / 失败 / 非战斗为 false）
  - `RunState` 序列化扩展：把 `pending_rewards` 一并写入存档（中途关游戏也能恢复奖励选择）
- 修改 `scripts/battle/battle_scene.gd`：胜利结算后读 `outcome.pending_rewards`；若为 true 且非 BOSS 通关（BOSS 通关也要先选完奖励再进 `run_summary`），把 `return_scene_path` 临时指向 `res://scenes/roguelike/reward_pick.tscn`，奖励选完后由 `reward_picker.gd` 决定下一步（普通/精英 → `route_map`；BOSS → `run_summary`）
- 修改 `scripts/roguelike/run_state.gd`：`serialize() / deserialize()` 增加 `pending_rewards` 字段（默认空数组）
- 新增单测：`tests/unit/test_reward_pool.gd`（加载、3 张唯一、BOSS 权重生效、apply_reward 各 effect 类型）、`tests/unit/test_run_manager_rewards.gd`（精英胜利后 pending_rewards 非空；apply_reward_choice 正确改 RunState；普通胜利不 roll 奖励）
- 更新 README「进度」一行：「第 8A 章 三选一奖励（精英/BOSS 战后）」

不在本轮范围（归 8B）：`MetaManager` 解锁判定与三个解锁项、`stats` 写入、主菜单/图鉴解锁页、`shop_discount` 等 Meta 应用点、数值打磨清单、音效占位。

## Capabilities

### New Capabilities

- `roguelike-rewards`: 三选一战后奖励系统——奖励池数据、随机抽取（含 BOSS 权重）、`RewardPool` 静态工具、`reward_pick.tscn` UI、`RunManager` 钩子（roll / apply / persist pending）、奖励效果到 `RunState` 的映射规则

### Modified Capabilities

- `roguelike-core`: 扩展 `RunState` 序列化字段加入 `pending_rewards`；扩展 `RunManager.consume_battle_result` 在精英/BOSS 胜利时填充 pending_rewards 并在返回值中标记
- `chapter-6-campaign-and-menu`: 无 spec 行为变更（不动）

## Impact

- **代码**
  - 新增 `scripts/roguelike/reward_pool.gd`、`scripts/roguelike/reward_picker.gd`
  - 修改 `scripts/autoload/run_manager.gd`、`scripts/roguelike/run_state.gd`、`scripts/battle/battle_scene.gd`
- **场景**
  - 新增 `scenes/roguelike/reward_pick.tscn`（PanelContainer + 3 张卡 + 标题/描述/确认）
- **数据**
  - 新增 `data/route/reward_pool.json`
- **测试**
  - 新增 2 个测试文件，预计 8~10 个新单测；现有 30 个单测保持 GREEN
- **存档**
  - `RunState` 序列化字段新增 `pending_rewards`；旧存档反序列化时缺字段默认空数组（向后兼容）
- **依赖 / 风险**
  - 仅依赖 Godot 4.6 标准库；`RewardPool.apply_reward` 涉及对 `party / reserve` 单位字段（`atk` / `hp` / `max_hp` / `skill_cd`）写入，需保证 `BattleUnit` 序列化字段已含这些键（已确认）
  - `R_RESCUE`（招募未解锁池单位）当前 META 池为空，本轮先用 `["M01","M02","M03","M04"]` 兜底，待 8B 接入 `MetaManager` 后改读真实解锁池
