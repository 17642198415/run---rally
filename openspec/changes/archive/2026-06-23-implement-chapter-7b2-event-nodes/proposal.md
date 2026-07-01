## Why

第 7B1 已实现肉鸽最小闭环（`battle`/`elite`/`boss` + 路线图 + 战斗接入），但 `rest`、`shop`、`capture_event` 三种节点在路线图上**灰显不可点**。`Demo完整实施计划.md` 7.7 验收要求「休息/商店/捕捉事件可进入并返回路线图」，且层 1/3/4/5 的池配置会随机到这些节点——不实现则玩家常遇到「死路」式灰按钮，M3 不完整。

本 change（7B2）补齐三类**非战斗事件节点**的简版实现，并打通 `route_map` → 事件场景 → 标记完成 → 回路线图。

## What Changes

- **新场景**：`scenes/roguelike/rest.tscn`、`scenes/roguelike/shop.tscn`（`capture_event` 复用战斗 + 高捕获率，不单独建全屏场景）
- **新脚本**：`scripts/roguelike/node_handlers.gd`（节点类型分发）、`scripts/roguelike/rest_event.gd`、`scripts/roguelike/shop_event.gd`、`scripts/roguelike/shop_catalog.gd`（加权随机 3 商品槽）
- **新数据**：`data/route/shop_catalog.json`（商品池与价格）、`data/enemy_groups/capture_event.json`（1～2 只指定系遭遇）
- **`route_map.gd`**：当前层 `rest`/`shop`/`capture_event` 可点击；移除 7B2 灰显 tooltip
- **`RunManager`**：新增 `complete_event_node(node_id)`（`mark_node_completed` + `advance_layer` + `save`）；`consume_battle_result` 胜利时发放征途币（普通 +8、精英 +15，BOSS 不变）
- **`GameState`**：`battle_context` 支持 `capture_event_bonus`（float）；`prepare_roguelike_capture_event(...)` 或扩展现有 prepare 方法
- **`battle_scene.gd`**：ROGUELIKE 模式下读取 `capture_event_bonus` 覆盖默认 `event_bonus_default`
- **捕捉事件流程**：点击 → 专用敌组 → `party_setup` → 战斗（高捕获率）→ 胜后 `consume_battle_result` 回路线图

## Capabilities

### New Capabilities
- `roguelike-event-nodes`: 休息/商店/捕捉事件三类节点的行为、数据、场景与 `node_handlers` 分发

### Modified Capabilities
- `roguelike-ui`: 路线图节点可点击性扩展为当前层全部 6 种类型；移除「7B2 未启用」灰显规则
- `roguelike-core`: `RunManager.complete_event_node`、战斗胜利征途币奖励

## Impact

- **代码**：新增 `scripts/roguelike/node_handlers.gd`、`rest_event.gd`、`shop_event.gd`、`shop_catalog.gd`；修改 `route_map.gd`、`run_manager.gd`、`game_state.gd`、`battle_scene.gd`
- **测试**：`test_run_manager_event_node.gd`（complete_event_node）、`test_shop_catalog.gd`（种子可复现 3 槽）、`test_node_handlers.gd`（类型分发）；扩展 capture 相关测试验证 bonus 覆盖
- **依赖**：7A 核心 + 7B1 UI/战斗接入；不依赖第 8 章 Meta/三选一
- **不破坏**：战役模式与 7B1 战斗节点流程保持兼容
