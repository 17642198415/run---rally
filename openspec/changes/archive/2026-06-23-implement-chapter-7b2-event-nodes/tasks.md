## 1. RunManager 扩展（TDD）

- [x] 1.1 RED: `tests/unit/test_run_manager_event_node.gd` — `complete_event_node` 标记路径/进层/save；`consume_battle_result` 普通胜 +8 币、精英 +15 币
- [x] 1.2 GREEN: `run_manager.gd` 实现 `complete_event_node`；`consume_battle_result` 增加掉币逻辑
- [x] 1.3 跑 Group 1 单测 + 既有 `test_run_manager_consume_result` 回归

## 2. 数据与 ShopCatalog

- [x] 2.1 创建 `data/route/shop_catalog.json`（≥3 商品：加球/全队治疗%/随机宠）
- [x] 2.2 创建 `data/enemy_groups/capture_event.json`（1-2 低阶敌 + map_template）
- [x] 2.3 RED: `tests/unit/test_shop_catalog.gd` — 同 seed 同 3 槽、权重合法
- [x] 2.4 GREEN: `scripts/roguelike/shop_catalog.gd` 实现 `roll_3(seed, rng)`

## 3. NodeHandlers 与 route_map

- [x] 3.1 实现 `scripts/roguelike/node_handlers.gd`（6 类型分发 + pending `run_node_id` 存 GameState）
- [x] 3.2 RED: `tests/unit/test_node_handlers.gd` — rest/shop/capture/battle 返回正确路径或 prepare 副作用
- [x] 3.3 修改 `route_map.gd`：可点击类型扩为 6 种；点击调 `NodeHandlers`；移除 7B2 灰显 tooltip

## 4. 休息场景

- [x] 4.1 创建 `scenes/roguelike/rest.tscn` + `scripts/roguelike/rest_event.gd`
- [x] 4.2 实现 +30% HP 与献祭 1 reserve 全队满血；空 reserve 隐藏献祭
- [x] 4.3 「离开营地」→ `complete_event_node` → `route_map.tscn`

## 5. 商店场景

- [x] 5.1 创建 `scenes/roguelike/shop.tscn` + `scripts/roguelike/shop_event.gd`
- [x] 5.2 渲染 3 商品槽、购买扣币与应用效果（含 reserve 满 8 售罄）
- [x] 5.3 「离开商店」→ `complete_event_node` → `route_map.tscn`

## 6. 捕捉事件战斗接入

- [x] 6.1 `GameState.prepare_roguelike_node` 扩展 `capture_event_bonus` 可选参数
- [x] 6.2 `node_handlers` capture 分支：读 `capture_event.json` 敌组 + bonus 0.35 → party_setup
- [x] 6.3 `battle_scene.gd` `_get_event_bonus()` 读取 `battle_context.capture_event_bonus`
- [x] 6.4 手动/单测验证捕捉率高于普通战（可选：扩展 `test_capture_system` 或 battle 集成烟测）

## 7. 文档与回归

- [x] 7.1 全量 headless 单测
- [x] 7.2 README：7B2 完成、测试数更新、M3 验收项勾选说明
- [x] 7.3 手动：路线图点 rest/shop/capture_event 各 1 次 → 回图 → 币/HP/球变化正确
- [x] 7.4 勾选 `tasks.md` 全部完成项
