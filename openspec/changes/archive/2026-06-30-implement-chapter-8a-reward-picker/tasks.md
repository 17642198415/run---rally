## 1. 数据与 RewardPool 纯逻辑

- [x] 1.1 新建 `data/route/reward_pool.json`：7 种奖励 + `boss_weight_bonus`（`R_ATK`/`R_SKILL`/`R_RESCUE`），每条含 `weight`（默认 10）
- [x] 1.2 新建 `scripts/roguelike/reward_pool.gd`：`load_pool()`、`pick_three(rng, is_boss)`（不放回、BOSS bonus ×2）、`get_rescue_pool()` 兜底 `M01~M04`
- [x] 1.3 实现 `apply_reward(state, reward, target_unit_id, loader)`：balls / heal_pct / coins / atk / max_hp / skill_cd / random_pet；失败零副作用
- [x] 1.4 新建 `tests/unit/test_reward_pool.gd`：加载、3 张唯一、同种子可复现、R_BALL/R_HEAL/R_ATK/R_RESCUE apply、BOSS bonus smoke

## 2. RunState 序列化扩展

- [x] 2.1 `run_state.gd` 增加 `pending_rewards: Array`、`pending_reward_is_boss: bool` 字段
- [x] 2.2 `serialize()` / `deserialize()` 读写上述字段；缺字段默认 `[]` / `false`
- [x] 2.3 `_normalize_reserve` 保留 `atk`、`skill_cd` 键（若存在）
- [x] 2.4 扩展 `test_run_state.gd`：round-trip 含 pending；legacy deserialize 默认值

## 3. RunManager 奖励钩子

- [x] 3.1 `consume_battle_result`：精英/BOSS 胜利路径调用 `RewardPool.pick_three`，写入 `state.pending_rewards`，设 `pending_reward_is_boss`；返回值加 `pending_rewards: bool`
- [x] 3.2 实现 `get_pending_rewards()`、`has_pending_rewards()`、`apply_reward_choice(reward_id, target_unit_id)`（成功清 pending + save）
- [x] 3.3 新建 `tests/unit/test_run_manager_rewards.gd`：精英胜 pending=3、普通胜 pending 空、apply R_COIN 改 coins、BOSS 胜 pending+run_ended

## 4. 三选一 UI

- [x] 4.1 新建 `scenes/roguelike/reward_pick.tscn`：标题 + 3 卡槽容器 + 目标选择列表 + 状态 Label
- [x] 4.2 新建 `scripts/roguelike/reward_picker.gd`：`MenuStyle.apply_page_shell`；读 `get_pending_rewards()` 建卡；`one_pet` 两步选目标；确认调 `apply_reward_choice`
- [x] 4.3 选奖后路由：精英 → `route_map.tscn`；`get_last_outcome().victory` → `run_summary.tscn`；无 pending 时 fallback 路线图

## 5. 战斗结算路由

- [x] 5.1 改 `battle_scene._handle_roguelike_battle_end`：`pending_rewards` 优先跳 `reward_pick.tscn`；否则 `run_ended` → `run_summary`；否则 `return_path`
- [x] 5.2 确认 BOSS 战：先 reward_pick 再 run_summary（不跳过奖励）

## 6. 文档与回归

- [x] 6.1 README 进度追加「第 8A 章 三选一奖励（精英/BOSS 战后）」；测试计数更新（+2 文件）
- [x] 6.2 全量 `tests/run_all_tests.ps1` PASS（30 + 新增）
- [ ] 6.3 F5 手动：精英胜 → 三选一 → 选 R_BALL → 路线图 balls+1；BOSS 胜 → 三选一 → run_summary
