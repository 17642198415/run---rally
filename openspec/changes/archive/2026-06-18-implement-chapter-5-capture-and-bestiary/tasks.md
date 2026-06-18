## 1. 测试骨架（先 RED）

- [x] 1.1 新建 `tests/unit/test_capture_system.gd` —— 覆盖 `compute_rate` 单调性、`tier_for_rate` 边界、`attempt` 成功/失败/无球三分支（用 `RandomNumberGenerator` 注入 seed）
- [x] 1.2 新建 `tests/unit/test_bestiary_manager.gd` —— `mark_discovered` / `mark_caught` / 持久化字段读写
- [x] 1.3 新建 `tests/unit/test_party_manager.gd` —— 追加、unique id (`P_M01_001`/`P_M01_002`)、`MAX_RESERVE` 满栏拒绝
- [x] 1.4 新建 `tests/unit/test_save_manager.gd` —— `save_meta` + `load_meta` 圆环；旧档缺字段回灌默认；写入用 `user://test_save_meta.json` 临时路径
- [x] 1.5 在 `tests/unit/test_battle_setup.gd` 增加 1 个用例：野生 `M01` 被 HERO 打到 0 hp 后 `downed_capturable == true` 且仍占格
- [x] 1.6 跑全量测试确认新增测试 RED（旧 14 个仍 PASS）

## 2. 数据模型 + 战斗规则改动

- [x] 2.1 改 `scripts/battle/battle_unit.gd`：加 `downed_capturable: bool = false`、`is_wild() -> bool`（非 player 且模板 tags 不含 `boss`）、`is_alive_for_battle() -> bool`
- [x] 2.2 改 `scripts/battle/battle_controller.gd`：HP≤0 时若 `is_wild()` → `downed_capturable = true`，**不**移除；否则按现行逻辑移除
- [x] 2.3 改 `scripts/battle/battle_controller.gd::check_victory`：`alive_units` 用 `is_alive_for_battle()`；玩家方仍只看 `hp > 0`
- [x] 2.4 让 `tests/unit/test_battle_setup.gd` 新用例转 GREEN，确认旧测试不退化

## 3. CaptureSystem 与持久化模块

- [x] 3.1 新建 `scripts/battle/capture_system.gd` —— 静态 `compute_rate` / `tier_for_rate` / `attempt(unit, balls, event_bonus, rng)` 返回字典 `{success, rate, tier, balls_remaining_after, error?}`
- [x] 3.2 新建 `scripts/managers/bestiary_manager.gd` —— autoload，`mark_discovered`、`mark_caught`、`is_discovered`、`is_caught`、`to_dict`、`from_dict`
- [x] 3.3 新建 `scripts/managers/party_manager.gd` —— autoload，`MAX_RESERVE = 12`、`reserve: Array`、`can_accept`、`add_capture(template_id, hp, max_hp, skill_id) -> Dictionary`、`to_dict`、`from_dict`
- [x] 3.4 改 `scripts/autoload/save_manager.gd::get_default_save` 默认结构对齐 design D5（含 `party.reserve = []`、`meta.unlocked = []`、`stats = {}`、`campaign = {}`），并补 `merge_with_defaults` 回灌缺失字段
- [x] 3.5 在 `project.godot` 注册 `BestiaryManager` / `PartyManager` 两个 autoload；`_ready()` 内若已被注入则跳过自取，否则 `from_dict(SaveManager.load_meta())`
- [x] 3.6 跑 1.1–1.4 单测全部 GREEN

## 4. 关卡数据 + GameState

- [x] 4.1 改 `data/stages/debug_battle.json`：保留/规范 `player_ball_count: 3`（已有）；新增 `tags` 字段约定预留（无需值），文档化在 design 即可
- [x] 4.2 新建 `data/capture_config.json`：`{"event_bonus_default": 0.0, "tier_thresholds": {"high": 0.5, "mid": 0.25, "low": 0.12}}`，`DataLoader` 加 `load_capture_config()` + `get_capture_config()`
- [x] 4.3 改 `scripts/autoload/game_state.gd`：加 `current_battle: Dictionary`，含 `balls_remaining`、`stage_id`，提供 `set_battle_balls(n)` / `decrement_ball()`
- [x] 4.4 改 `scripts/battle/battle_scene.gd::_begin_stage()`：读 `stage.player_ball_count`（缺省 3）写入 `GameState.current_battle.balls_remaining`；spawn 完成后对所有 `is_wild()` 单位调 `BestiaryManager.mark_discovered(template_id)`

## 5. UI：ActionBar + CapturePrompt + HUD 球数

- [x] 5.1 改 `scenes/battle/ui/action_bar.tscn`：在 Buttons 里新增 `CaptureBtn`（label `捕捉`），位置在 `[技能]` 与 `[待机]` 之间
- [x] 5.2 改 `scripts/battle/action_bar.gd`：加 `capture_pressed` 信号、`@onready var capture_btn`、`set_capture_enabled(enabled: bool)`；`set_player_turn_mode` 默认隐藏
- [x] 5.3 新建 `scenes/battle/ui/capture_prompt.tscn` + `scripts/battle/capture_prompt.gd`：显示「目标：<name> HP x/y」、「成功率：<tier>」、「剩余球：N」+ `[确认捕捉]`/`[取消]`，发 `confirmed`/`cancelled` 信号
- [x] 5.4 改 `scripts/battle/battle_grid_controller.gd`：选中玩家时计算「相邻 `downed_capturable` 野单位列表」 → `action_bar.set_capture_enabled(列表非空 and balls > 0)`；点 [捕捉] 进入 `CAPTURE_TARGET` 模式（高亮可捕格）；点目标 → 弹 `CapturePrompt`
- [x] 5.5 改 `scripts/battle/battle_scene.gd`：处理 `CapturePrompt.confirmed` → 调 `CaptureSystem.attempt` → 球数 -1 → 若成功 `PartyManager.add_capture` + `BestiaryManager.mark_caught` + 从 `units`/`Grid` 移除 → `SaveManager.save_meta(...)` → `mark_unit_acted` 推进队列；失败也推进队列
- [x] 5.6 改 HUD 显示「球: N」（绑 `GameState.current_battle.balls_remaining`，球数变化时刷新）

## 6. 战斗胜负 + Save 写入时机

- [x] 6.1 在 `BattleScene._on_battle_end()` 触发处调用 `SaveManager.save_meta(_assemble_save_dict())`（含 `bestiary` / `party` / `stats.battles_won++`）
- [x] 6.2 验证 `check_victory` 在「敌方全部 downed_capturable，无一存活」时返回 `"player"`，触发 BATTLE_END 与 save 写入

## 7. 收尾与全量回归

- [x] 7.1 把新增 5 个 / 改动 1 个测试加入 `tests/run_all_tests.ps1`（保持 `Continue` 错误策略）
- [x] 7.2 `powershell -ExecutionPolicy Bypass -File "tests\run_all_tests.ps1"` 全 PASS（预期 `ALL 18 TESTS PASSED`）
- [x] 7.3 在 `README.md` 加「第 5 章手动验收」段：DEBUG_01 → 把 M01 打到 0 hp（不消失）→ 走到相邻格 → [捕捉] → 看档位 → roll → 成功后存档 → 重启游戏 `BestiaryManager.is_caught("M01")` 仍 true
- [x] 7.4 README 「测试」段更新条目数与命令；「进度」段勾选第 5 章
- [ ] 7.5 编辑器内手动跑完 7.3 验收剧本至少 1 次（成功 + 失败各 1 次），确认 HUD 球数、ActionBar 启用/禁用、Save 文件 `user://save_meta.json` 内容符合预期
