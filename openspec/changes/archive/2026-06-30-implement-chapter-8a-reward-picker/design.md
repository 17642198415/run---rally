## Context

第 7 章肉鸽核心已完成：`RunState`、`RouteGenerator`、`EnemyGroupPicker`、`NodeHandlers`、`RunManager.consume_battle_result` 都跑通；`battle_scene.gd` 在每场战斗结束后会 `_build_roguelike_payload()` 并通过 `RunManager.consume_battle_result(node_id, result, payload)` 把战果交给 RunManager。RunManager 在精英/普通胜利时只做 `_award_battle_coins` 和 `save()`，BOSS 胜利只标记 `run_ended=true, victory=true` 直接进 `run_summary`。

Demo 计划第 8 章「三选一奖励」要在「精英胜利」与「BOSS 胜利」时插入一段奖励选择流程：随机抽 3 张奖励卡，玩家选 1 张应用到 `RunState`。Demo 计划同时还包含 Meta 解锁、stats、解锁页与全局打磨；为了节奏可控本轮只交付奖励侧（8A），Meta/解锁页/打磨归 8B。

现有约束：
- Godot 4.6 + GDScript，不引入新依赖
- 30 个 headless 单测必须保持 GREEN
- `RunState` 序列化字段一旦扩展，旧存档（无 `pending_rewards`）必须能无错降级（默认空数组）
- 不动战役流程；不动 `GameState.battle_context`
- 用户全局规则：优先在现有目录约定下新增，不擅自新建平行入口；不擅自加文档

## Goals / Non-Goals

**Goals:**

- 精英战与 BOSS 战胜利后弹出三选一奖励 UI，玩家选 1 张后效果写入 `RunState` 并持久化
- `reward_pool.json` 定义 7 种奖励；BOSS 战对 `R_ATK` / `R_SKILL` / `R_RESCUE` 权重 ×2
- `RewardPool` 纯静态模块可 headless 单测：`pick_three`、`apply_reward`、各 effect 类型
- `RunManager` 在 `consume_battle_result` 精英/BOSS 胜利路径 roll 奖励；`pending_rewards` 进 `RunState` 序列化
- `battle_scene` 根据 `outcome.pending_rewards` 跳转 `reward_pick.tscn`；选完后精英回路线图、BOSS 回 `run_summary`
- 复用 `MenuStyle` 卡片风格；现有 30 单测 GREEN + 新增 8~10 单测

**Non-Goals:**

- Meta 解锁、`stats` 写入、解锁页 UI → 8B
- 普通战胜利触发三选一
- 音效、数值全局打磨、路线图灰显增强
- 修改战役流程或 `GameState` 对外接口

## Decisions

### D1 — pending_rewards 存 RunState 而非 RunManager 私有字段

- **决定**：`RunState.pending_rewards: Array`（3 张奖励 dict 快照）+ `pending_reward_is_boss: bool`（决定选完后跳转）
- **理由**：与 `balls/coins/reserve` 同属 Run 快照；`save()` 一次写入，关游戏重开可恢复选奖
- **替代**：`RunManager._pending_rewards` 内存字段。**否决**：中途退出丢奖励

### D2 — RewardPool 静态模块，仿 ShopCatalog

- **决定**：`scripts/roguelike/reward_pool.gd`，`load_pool()` / `pick_three(rng, is_boss)` / `apply_reward(state, reward, target_unit_id, loader) -> bool`
- **理由**：与 7B2 `ShopCatalog` 模式一致；UI 薄、逻辑可单测
- **替代**：逻辑写在 `reward_picker.gd`。**否决**：难 headless 覆盖

### D3 — 触发时机：仅 elite / boss 胜利

- **决定**：`consume_battle_result` 在 `result == "player"` 且 (`is_elite` 或 `is_boss`) 时调用 `RewardPool.pick_three`；普通战不变
- **理由**：与用户确认一致；对齐 Demo 8.7 验收

### D4 — BOSS 流程：先选奖再 run_summary

- **决定**：BOSS 胜利时 `consume_battle_result` 仍设 `run_ended=true, victory=true`，但同时 `pending_rewards=true`；`battle_scene` 优先跳 `reward_pick.tscn`；`reward_picker` 选完后若 `get_last_outcome().victory` 则进 `run_summary`
- **理由**：BOSS 也应拿成长奖励；`run_summary` 在选奖之后出现
- **替代**：BOSS 跳过奖励。**否决**：与 Demo 计划不符

### D5 — 单目标奖励（R_ATK / R_HP / R_SKILL）两步 UI

- **决定**：点卡后若 `effect.target == "one_pet"`，下方展开 reserve 列表（不含 HERO）；点单位再确认；无 reserve 时该卡 disabled 或 apply 失败并提示
- **理由**：Demo 8.5「指定+2ATK」需选目标；reserve 为空时 R_RESCUE 是唯一招募途径

### D6 — R_RESCUE 招募池兜底

- **决定**：8A 用常量 `DEFAULT_RESCUE_POOL = ["M01","M02","M03","M04"]`；`apply_reward` 随机选 template，经 `RunManager.add_capture_to_reserve` 加入（50% HP）
- **理由**：`MetaManager` 完整实现归 8B；接口预留 `get_rescue_pool() -> Array` 便于后续替换

### D7 — RunState reserve 扩展 stat 字段

- **决定**：`apply_reward` 对 reserve 条目写入 `atk` / `skill_cd`（缺省视为模板基础值 + delta）；`max_hp` delta 同步加 `hp`（不超 max）
- **理由**：下一场战斗从 `deploy_list` 读 reserve 快照；需在 Run 层持久化强化
- **实现**：读 `DataLoader.get_unit_template(template_id)` 取基础 atk/max_hp/skill_cd 作为 fallback

### D8 — battle_scene 路由分支

```gdscript
if bool(outcome.get("pending_rewards", false)):
    get_tree().change_scene_to_file("res://scenes/roguelike/reward_pick.tscn")
elif bool(outcome.get("run_ended", false)):
    get_tree().change_scene_to_file("res://scenes/roguelike/run_summary.tscn")
else:
    get_tree().change_scene_to_file(return_path)
```

## Risks / Trade-offs

- [reserve 无 stat 字段导致战斗不读强化] → `party_setup` 肉鸽编队已从 reserve dict 构建 deploy_list；确保 `_normalize_reserve` 保留 `atk`/`skill_cd` 键
- [R_SKILL cd-1 下溢] → `apply_reward` 用 `maxi(0, skill_cd + delta)`
- [pending 未清导致重复选奖] → `apply_reward_choice` 成功后清空 `pending_rewards` 并 `save()`
- [7 种奖抽 3 张重复] → `pick_three` 不放回；池仅 7 张足够
- [R_RESCUE 与 Meta 池不一致] → 8B 替换 `get_rescue_pool`；8A 单测用固定池

## Migration Plan

1. 落 `reward_pool.json` + `RewardPool` + 单测
2. 扩展 `RunState.serialize` + 单测 round-trip
3. 改 `RunManager.consume_battle_result` + `apply_reward_choice` + 单测
4. 做 `reward_pick.tscn` + `reward_picker.gd`
5. 改 `battle_scene._handle_roguelike_battle_end` 路由
6. 全量 `tests/run_all_tests.ps1`；README 进度一行

回滚：删新文件；revert `run_state`/`run_manager`/`battle_scene` 三处改动。

## Open Questions

- `R_HEAL` 是否包含 HERO party 行？**建议**：仅 heal `reserve`（与商店 `heal_all_pct` 一致，HERO 在 party 单独更新）
- 精英与 BOSS 用同一权重表还是 BOSS 仅 bonus？**按 Demo**：同一池 + `boss_weight_bonus` ×2