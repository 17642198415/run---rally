## Context

7B1 交付了路线图与战斗类节点闭环。`route_map.gd` 中 `BATTLE_TYPES` 仅含 `battle`/`elite`/`boss`；`rest`/`shop`/`capture_event` 显示但 `disabled=true`。

`Demo完整实施计划.md` 7.4.3 定义：
| type | 行为 |
| rest | 全员 +30% HP 或弃 1 宠换满血 |
| shop | 3 商品槽，征途币购买 |
| capture_event | 高捕获率遭遇 1～2 指定系 |

当前 `RunState.coins` 初始为 0 且战斗胜利未发币——商店需要先补**战斗掉币**才有意义。

## Goals / Non-Goals

**Goals:**
- 三种事件节点可从路线图进入、交互后标记完成并回路线图
- 休息：二选一（全队 +30% max_hp 或牺牲 1 只 reserve 换全队满血）
- 商店：种子可复现 3 商品槽；支持买球、全队小治疗、随机低价宠（简版）
- 捕捉事件：专用敌组 + `capture_event_bonus` 提高捕获率；仍走编队→战斗→胜后回图
- 战斗胜利发放征途币（普通 8 / 精英 15）
- headless 单测覆盖核心逻辑

**Non-Goals:**
- Meta 商店折扣（第 8 章）
- 精英胜后三选一
- 商店 UI 动画、休息剧情文本
- 新地图模板或新敌组层表（除 capture_event 专用 JSON）

## Decisions

### D1: `node_handlers.gd` 集中分发

`route_map` 点击节点后调用 `NodeHandlers.enter_node(type, node_id, layer, rng)` 返回目标场景路径或触发 battle prepare。

- `rest` / `shop` → 各自 `.tscn`
- `capture_event` → `EnemyGroupPicker` 或专用 `CaptureEventPicker` 读 `capture_event.json` → `GameState.prepare_roguelike_node` + `capture_event_bonus` → `party_setup`

### D2: 非战斗完成用 `RunManager.complete_event_node`

```gdscript
func complete_event_node(node_id: String) -> void:
    _state.mark_node_completed(node_id)
    _state.advance_layer()
    save()
```

`rest`/`shop` 玩家点「离开」时调用。战斗类仍走 `consume_battle_result`。

### D3: 商店数据 `data/route/shop_catalog.json`

结构：`items: [{id, display, cost, effect_type, effect_value, weight}]`。`ShopCatalog.roll_3(seed, rng)` 无放回抽 3 个。效果类型：`add_ball`、`heal_all_pct`、`add_random_reserve`（从 M01-M04 随机）。

购买扣 `RunState.coins`，应用效果，不自动完成节点——玩家点「离开商店」才 `complete_event_node`。

### D4: 捕捉事件捕获率加成

`GameState.battle_context["capture_event_bonus"] = 0.35`（叠加 `CaptureSystem` 计算）。`battle_scene._get_event_bonus()` 在 ROGUELIKE 且 context 有该字段时返回该值。

敌组：`data/enemy_groups/capture_event.json`，1～2 只低阶宠（M01-M04），固定 `T_PLAIN`。

### D5: 休息 HP 作用于 party + reserve

- **选项 A（+30%）**：对 `party` 与 `reserve` 每条 `hp = mini(max_hp, hp + int(max_hp * 0.3))`
- **选项 B（献祭）**：玩家选 1 只 reserve 移除；其余 party+reserve 全部 `hp = max_hp`

HERO 在 `party` 中，参与治疗；献祭仅可选 reserve（非 HERO）。

### D6: 战斗掉币并入 `consume_battle_result`

胜利时：`coins += 8`（普通）、`15`（`is_elite`）、BOSS 不加（Run 将结束）。在 7B2 一并实现，避免空商店。

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| 商店无币可买 | 战斗胜利发币 + 初始层 1 普通战也能攒币 |
| capture_event 与 normal battle 代码分叉 | 复用 `prepare_roguelike_node` + bonus 字段 |
| rest 献祭误删唯一宠 | UI 无 reserve 时隐藏献祭选项 |
| 节点完成双写 | rest/shop 仅 `complete_event_node`；capture 仅 `consume_battle_result` |

## Migration Plan

1. `RunManager.complete_event_node` + 掉币逻辑（单测）
2. `shop_catalog.json` + `ShopCatalog`（单测）
3. `rest.tscn` / `shop.tscn`
4. `capture_event.json` + battle bonus 接线
5. `route_map` + `node_handlers` 启用三类型
6. 全量回归 + M3 验收补项

## Open Questions

- （实现时）`add_random_reserve` 是否需检查 reserve 上限 8——是，满则商品显示售罄
