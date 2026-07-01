## Context

第 7A 已交付 `RunState`、`RouteGenerator`、`EnemyGroupPicker`、`RunManager` 及全套 JSON 数据，25 个 headless 单测全绿。战役模式（M2）已有完整链路：主菜单 → 关卡选择 → `party_setup` → Battle → 回 `stage_select`。`GameState` 已有 `GameMode.CAMPAIGN` 与 `return_scene_path` 机制；`battle_scene.gd` 仅在 `CAMPAIGN` 模式下处理战后逻辑。

本 change（7B1）在**不破坏战役**的前提下，接通肉鸽最小可玩闭环（M3 前半）。用户已确认：
- 入口：主菜单「开始征途」/「继续征途」
- 编队：复用 `party_setup.tscn`，按 `GameState.current_mode` 分支
- 战后回路：复用 `return_scene_path`，由 `route_map` 或 `battle_scene` 处理 Roguelike 分支
- 范围：仅 `battle`/`elite`/`boss` 可交互；`rest`/`shop`/`capture_event` 灰色不可点

## Goals / Non-Goals

**Goals:**
- 主菜单可开新 Run / 继续 Run / 放弃 Run
- `route_map.tscn` 竖向 6 层路线图 + 侧边栏（层数、球、币、reserve 数量）
- 点击当前层战斗节点 → `EnemyGroupPicker` 抽敌组 → `party_setup`（ROGUELIKE 模式）→ Battle → 胜/负处理
- BOSS 胜或主角阵亡 → `run_summary.tscn`；其他情况回路线图并 `RunManager.save()`
- `RunManager.consume_battle_result()` 封装战后状态机，可单测
- 里程碑 M3 手动验收清单中与本切片相关的条目可通过

**Non-Goals:**
- `rest` / `shop` / `capture_event` 场景与逻辑（7B2）
- 精英胜后三选一奖励（第 8 章）
- `MetaManager.stats` 写入（第 8 章）
- 路线图动画、连线美化、音效
- 新 headless UI 场景测试

## Decisions

### D1: 战后结果由 `RunManager.consume_battle_result` 集中处理

**选择**：`battle_scene.gd` 在 ROGUELIKE 模式战后收集 `surviving_units` / `hero_hp`，调用 `RunManager.consume_battle_result(node_id, result, payload)`，由 RunManager 负责：
- 胜利：`mark_node_completed` + 同步 reserve（阵亡移除、存活更新 HP）+ `save()`
- 失败且主角存活：不回路线图节点完成，仅同步 reserve
- 主角 HP≤0：`hero_dead = true` + `save()` + 跳转 `run_summary`
- BOSS 胜：标记节点 + `save()` + 跳转 `run_summary`（胜利）

**备选**：在 `battle_scene` 内直接改 `RunState` 字段。  
**理由**：保持 `RunManager` 为 Run 状态唯一写入口，与 7A 设计一致，便于单测。

### D2: 战斗回路复用 `GameState.return_scene_path`

**选择**：`GameState.start_roguelike_battle(...)` 设置 `return_scene_path = res://scenes/roguelike/route_map.tscn`。`battle_scene` 战后：
- 若需 `run_summary`：直接 `change_scene_to_file(run_summary.tscn)`
- 否则：延迟 1.5s 后 `change_scene_to_file(return_scene_path)`（与战役一致）

**备选**：`battle_scene` 回调 `RunManager` 再由其切场景。  
**理由**：最小侵入，复用现有 timer + scene change 模式。

### D3: `party_setup.tscn` 双模式，不新建场景

**选择**：`_ready()` 读 `GameState.current_mode`：
- `CAMPAIGN`：现有逻辑（`PartyManager.reserve`、`stage_id` 标题、`start_campaign_battle`）
- `ROGUELIKE`：读 `RunManager.get_state().reserve`；标题显示当前节点类型/层数；确认调用 `GameState.start_roguelike_battle`；返回按钮回 `route_map.tscn`

进入编队前，`route_map` 已将 `battle_context` 的 `run_node_id`、`enemies`、`map_template`、`is_elite`、`is_boss` 写入 `GameState`（通过 `prepare_roguelike_battle` 或等价方法）。

### D4: 路线图节点可点击性规则

**选择**：
- **可点**：`node.layer == RunState.current_layer` 且 `type in {battle, elite, boss}` 且 `node.id not in selected_path`
- **灰显不可点**：已完成节点（id 在 `selected_path`）；非当前层；`rest`/`shop`/`capture_event`（显示 tooltip「第 7B2 章启用」）
- **BOSS 层**：层 6 仅 1 节点，规则同上

节点按钮颜色读 `data/route/node_types.json`（与 `MenuStyle` 卡片样式组合）。

### D5: 初始 Run party 仅 HERO

**选择**：`RunManager.start_new_run` 扩展（或 `route_map` 首次进入时）将 `party` 设为含 HERO 的序列化条目；`reserve` 为空；`balls=3`、`coins=0`。战斗前编队从 `reserve` 选最多 3 只（初始可为 0）。

**理由**：对齐 `Demo完整实施计划.md` 7.4.5。

### D6: Roguelike 战斗敌组来源

**选择**：`battle_scene` 在 `GameMode.ROGUELIKE` 时：
- `map_template` 与 `enemies` 来自 `GameState.battle_context`（由 `EnemyGroupPicker` 在 `route_map` 点击时生成）
- `balls` 来自 `RunState.balls`（经 `GameState.set_battle_balls` 或 battle_context 传递）
- 战后捕捉成功写入 `RunState.reserve`（复用现有 capture 逻辑，需确认 battle 内 reserve 目标从 PartyManager 改为 RunState——在 `consume_battle_result` 或 battle 内分支）

**风险**：战役 capture 写 `PartyManager`，肉鸽需写 `RunState.reserve`。在 `battle_scene` 或 capture 回调加 `current_mode` 分支。

### D7: 主菜单 Run 入口 UI

**选择**：
- 无存档 Run（`run.active == false`）：「开始征途」→ `RunManager.start_new_run(randi())` + `save()` + 进 `route_map`
- 有存档 Run：`RoguelikeBtn` 文案改为「继续征途」；旁加「放弃征途」小按钮或二次确认对话框 → `RunManager.clear()` + 恢复「开始征途」

禁用态移除；`HintLabel` 用于放弃确认提示。

### D8: `run_summary.tscn` 简版

**选择**：显示胜利/失败标题、层数/种子摘要、「返回主菜单」按钮。胜利时调用 `RunManager.clear()`（Run 结束不写 party）；失败同理。stats 占位不写（第 8 章）。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| Capture 战后写入目标错误（PartyManager vs RunState） | `battle_scene` / capture 路径显式 `GameMode` 分支；手动验收捕捉入 reserve |
| `party_setup` 双模式耦合 | 用 `current_mode` 早分支，战役路径零改动 |
| 非战斗节点被随机到但不可点，玩家困惑 | tooltip + 灰色样式；多种子测试确保每层仍有 battle 可选 |
| `consume_battle_result` 与 UI 跳转职责重叠 | RunManager 只改状态+save，返回 bool `{run_ended, victory}` 由 battle_scene 决定跳 summary 或 route_map |
| reserve HP 同步复杂 | 7B1 仅同步本战 deploy_list 中单位的 HP；未参战 reserve 不变 |

## Migration Plan

1. 扩展 `GameState` + `RunManager`（可单测）→ 绿灯
2. `route_map` + `run_summary` 场景（可手动进场景调试）
3. `main_menu` 接入口
4. `party_setup` ROGUELIKE 分支
5. `battle_scene` ROGUELIKE 分支 + capture 目标
6. 全量 headless 测试 + M3 手动验收

回滚：主菜单恢复 disabled；移除 Roguelike 分支不影响战役。

## Open Questions

- （实现时确认）`battle_scene` 加载 Roguelike 敌组是否需新 helper，或复用 stage JSON 加载路径传 `enemies` 数组
- （7B2）rest/shop/capture_event 启用后，灰显规则改为可点
