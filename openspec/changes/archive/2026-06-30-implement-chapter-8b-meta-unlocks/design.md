## Context

- 第 7 章肉鸽全流程与第 8A 三选一奖励已交付；32 个 headless 单测 GREEN。
- `MetaManager` 当前仅有 `unlocked: Array[String]` 与 `is_unlocked` / `set_unlocked`，无 stats、无条件判定、无 effect 查询。
- `SaveManager.get_default_save()` 已有 `meta.unlocked` 与顶层 `stats: {}`；7A spec 约定 stats 占位但不写入。
- `RewardPool.get_rescue_pool()` 8A 硬编码 `M01~M04`；`EnemyGroupPicker` 不感知 Meta 额外单位。
- `run_summary.gd` 只显示种子/层数，不写 stats；`RunManager.clear()` 只清 run 节。
- Demo §8.4.2 定义 3 项 Meta；§8.7 验收要求通关或到层 5 解锁 META_BALL、图鉴发现 M05/M08 解锁入池、解锁页可见进度。

约束：Godot 4.6 + GDScript；不引入新外部依赖；既有单测保持通过；优先扩展现有 autoload/模块。

## Goals / Non-Goals

**Goals:**

- 落地 `data/meta_unlocks.json` 与 `MetaManager` 完整判定/查询/持久化
- Run 结束时写入 `stats` 并评估新解锁，失败 Run 不丢 Meta/图鉴
- 新 Run 应用 `start_balls_bonus`；招募池与敌组池合并 Meta `add_to_pool` 单位
- 图鉴页「解锁」Tab 展示 3 项 Meta 状态与条件进度
- `run_summary` 补充一行 stats/Meta 摘要；README 与单测覆盖核心路径

**Non-Goals:**

- 第 4 种 Meta（`META_SHOP` / shop_discount）
- 进化、永久死亡、战役流程改动
- 全量 §8.6 打磨（战斗时长调参、真实音效资源、Tier 2 视觉）
- `party_setup` / `deploy_phase` 传 `atk`/`skill_cd` 到战斗（8A 已知限制，非 8B 阻塞项）

## Decisions

### D1 — stats 字段对齐 Demo §8.4.3，替换 7A 占位命名

- **决定**：`stats` 使用 `runs_started`, `runs_won`, `runs_lost`, `deepest_layer`, `total_captures`, `total_coins_spent`（int，缺键默认 0）
- **理由**：与 Demo 计划与终验剧本 C 一致；7A 的 `run_total` 等仅存在于未实现的 spec 占位
- **替代**：保留 7A 命名并做映射。**否决**：增加维护成本且无外部消费者

### D2 — 解锁判定时机：Run 结束单次 evaluate + 图鉴变更时 evaluate

- **决定**：
  1. `MetaManager.record_run_end(state, victory)` 在 `RunManager` 进入 `run_summary` 前（BOSS 胜）或 `clear()` 前（失败/放弃）调用，更新 stats 后 `evaluate_unlocks(meta_dict)`
  2. `BestiaryManager.mark_discovered/mark_caught` 写盘后调用 `MetaManager.evaluate_unlocks`（满足 META_M05/M08 即时解锁）
- **理由**：META_BALL 依赖 stats；M05/M08 依赖图鉴，捕捉/发现可能发生在 Run 内
- **替代**：仅 Run 结束判定。**否决**：Run 中发现 M05 后需等到 Run 结束才解锁，体验差

### D3 — condition 解析：小 DSL 硬编码 3 种 type

- **决定**：`MetaManager` 内 switch `condition.type`：
  - `"or"`：`runs_won >= N` **或** `deepest_layer >= M`（Demo META_BALL）
  - `"bestiary"`：`BestiaryManager` 对 `unit_id` 达到 `state`（`seen` = discovered，`caught` = caught）
- **理由**：仅 3 条定义，无需通用规则引擎；便于单测逐条断言
- **替代**：表达式解析器。**否决**：过度设计

### D4 — effect 应用点分散在既有入口

| effect | 应用位置 |
|--------|----------|
| `start_balls_bonus` | `RunManager.start_new_run`：`balls = 3 + bonus` |
| `add_to_pool` | `RewardPool.get_rescue_pool()` 合并；`EnemyGroupPicker.pick` 在选中 group 后按权重追加替换一只普通敌人（layer≥3 的普通/精英池，capture_event 池） |

- **理由**：对齐 Demo §8.4.4；最小侵入，不重构敌组 JSON
- **M05/M08 入战**：picker 追加逻辑用 `rng` 决定是否把 group 内一只 `M01~M04` 替换为解锁单位（boss 层 boss 组除外）

### D5 — 解锁 UI：bestiary_view Tab，不新建场景

- **决定**：`bestiary_view.tscn` 顶部 `HBox` 两个 `Button`（灵兽 / 解锁）切换容器；解锁 Tab 用 `MenuStyle` 卡片渲染 3 行（标题、条件、状态徽章）
- **理由**：Demo 附录 A 线框；复用 MenuStyle，不增加主菜单入口
- **替代**：主菜单独立「解锁」页。**否决**：与 Demo 图鉴子 Tab 不一致

### D6 — stats / unlocked 写入与 SaveManager 边界

- **决定**：`MetaManager.record_run_end` 和 `evaluate_unlocks` 读/写通过 `SaveManager.load_meta()` 合并后 `save_meta()`；`MetaManager.to_dict()` → `meta` 节；`stats` 写顶层 `stats` 键
- **理由**：与 Campaign/Bestiary 同一文件；`RunManager.clear()` 调用 `record_run_end` 后仍只清 `run` 节

### D7 — 轻量打磨范围

- **纳入**：`run_summary` 一行「征途 N 次 · 最深 L 层 · Meta X/3」；路线图已完成节点 `modulate` 灰显复查
- **不纳入**：SFX 文件、战斗时长调参、deploy atk 传递

## Risks / Trade-offs

- [stats 键与旧 spec 占位不一致] → MODIFIED roguelike-core requirement；单测用 Demo 键名
- [敌组追加 M05/M08 破坏层 1~2 难度] → 仅 `current_layer >= 3` 的普通/精英替换；层 1~2 池不变
- [evaluate 在 Bestiary 写入时双 save] → `evaluate_unlocks` 仅在产生新解锁 id 时 `save_meta`，避免频繁 IO
- [图鉴 Tab 动态 UI 破坏 @onready] → 保留现有 Grid 容器 id，解锁容器同级切换 `visible`

## Migration Plan

1. 落 `meta_unlocks.json` + `test_meta_manager.gd`（RED→GREEN）
2. 扩展 `MetaManager` + Save 回灌
3. `RunManager` record_run_end + start_new_run balls bonus
4. `RewardPool` / `EnemyGroupPicker` 接 Meta 池
5. `bestiary_view` 解锁 Tab
6. `run_summary` 摘要 + README + 全量单测

回滚：删除 `meta_unlocks.json`、还原 `MetaManager` 与调用点；`stats`/`meta.unlocked` 多写字段无害。

## Open Questions

- `deepest_layer` 统计用 `current_layer`（失败时）还是 `selected_path` 已完成最大层？**建议**：`max(current_layer, len(selected_path))`，BOSS 胜记 6。
- META_M08「BOSS 相关池」是否包含 `layer_6_boss.json`？**建议**：仅 layer 3~5 精英/普通与 capture_event；BOSS 组本身已有 M08 模板，不额外注入。
