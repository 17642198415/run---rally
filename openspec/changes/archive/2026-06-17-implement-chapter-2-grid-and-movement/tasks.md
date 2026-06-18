## 1. Test Framework and RED Tests

- [x] 1.1 Add `tests/unit/test_terrain_types.gd`: assert `def_bonus`、`move_cost_extra`、`is_passable(foot/flying)` 与 §2.4.1 对齐（含 PLAIN/FOREST/MOUNT/WATER/WALL 全表）
- [x] 1.2 Add `tests/unit/test_grid.gd`: 覆盖 `from_template` 加载 `test_grid.json`、越界、`is_walkable` 步行 vs 飞行 vs 墙 vs 占格、`mover_id` 自身格不阻挡、`set_occupant` / `clear_occupant`
- [x] 1.3 Add `tests/unit/test_pathfinding.gd`: 覆盖 BFS 平原可达 = 曼哈顿 ≤ MOV、山地额外 +1 cost、墙跳过、敌方占格跳过、飞行单位过水、`find_path` 起终连通 + 不可达返回空
- [x] 1.4 把第 2 章测试纳入既有 headless 测试入口（保持与第 1 章 `tests/unit/` 同一命令运行），首次运行确认全部 RED

## 2. Logic Layer (Pure GDScript, no Node)

- [x] 2.1 创建 `scripts/battle/terrain_types.gd`：定义 `PLAIN/FOREST/MOUNT/WATER/WALL` 常量、`COLOR_BY_TERRAIN`、`get_def_bonus`、`get_move_cost_extra`、`is_passable(terrain, unit_type)`
- [x] 2.2 创建 `scripts/battle/grid.gd`（`class_name Grid extends RefCounted`）：`width/height/terrain/occupancy/deploy_zones`，`from_template(d) -> Grid`、`get_terrain`、`is_walkable(pos, unit_type, mover_id := "")`、`set_occupant`、`clear_occupant`、`get_move_cost(from, to, unit_type)`
- [x] 2.3 创建 `scripts/battle/pathfinding.gd`（`class_name Pathfinding`，全 `static func`）：`get_reachable(grid, start, mov, unit_type) -> Array[Vector2i]`、`find_path(grid, start, goal, mov, unit_type) -> Array[Vector2i]`，按 design §Decisions 第 3 条用 Dijkstra-lite + `came_from` 回溯
- [x] 2.4 跑测试，迭代到 1.1 / 1.2 / 1.3 全绿

## 3. Test Map Data

- [x] 3.1 新建 `data/map_templates/test_grid.json`，`width=10`, `height=10`, `terrain` 矩阵与 Demo 计划 §2.4.2 完全一致（特别校对 `(3,3)=4`, `(8,2)=3`, `(4,1)=2`, `(1,1)=1`）
- [x] 3.2 在 `terrain` 后追加 `deploy_zones.player` / `deploy_zones.enemy`（与 §2.4.2 一致），由 `Grid.from_template` 解析为 `Array[Vector2i]`
- [x] 3.3 在 `test_grid.gd` 测试中读 JSON 并验证 (3,3)/(8,2)/(4,1) 等关键格地形

## 4. View Layer & Interaction

- [x] 4.1 创建 `scripts/battle/unit_view.gd`（`extends Node2D`）：`grid_pos: Vector2i`、`unit_id: String`、`unit_type: String`、`mov: int`、`set_grid_pos(pos)` 同步 `position = pos * CELL_SIZE`、内部用 ColorRect + 首字 Label 占位渲染
- [x] 4.2 创建 `scripts/battle/battle_grid_controller.gd`（`extends Node2D`）：启动时加载 `test_grid.json` 构造 `Grid`、生成 `GridRoot` 下 100 个 ColorRect 着色、初始化 1 个测试 `UnitView`（`unit_type="foot"`, `mov=4`，初始格在部署区）
- [x] 4.3 在 controller 中实现两态状态机：`IDLE`/`UNIT_SELECTED`；`_unhandled_input` 处理鼠标点击 → 命中单位选中并显示高亮、命中可达格 tween 移动、命中其它处取消选中
- [x] 4.4 高亮层用一个 `HighlightLayer: Node2D`，每次进入 `UNIT_SELECTED` 时根据 `Pathfinding.get_reachable` 生成半透明 ColorRect；离开时清空
- [x] 4.5 移动时：`grid.clear_occupant(old)` → tween `position` 动画（约 0.2s）→ tween `finished` 后 `grid.set_occupant(new)` 与 `unit_view.grid_pos = new`，期间 controller 的 `is_moving` 锁住输入
- [x] 4.6 改造 `scenes/battle/battle.tscn`：根节点附加 `battle_grid_controller.gd`，下挂 `GridRoot/HighlightLayer/UnitsRoot`；保存场景

## 5. Verification

- [x] 5.1 在编辑器手动运行 `scenes/battle/battle.tscn`：肉眼验证 5 种地形色块 + 单位首字图标
- [x] 5.2 手动执行验收剧本：步行单位被水/墙阻挡；飞行可过水由 `test_pathfinding.gd::_test_flying_traverses_water` 自动覆盖（无需手工改代码）
- [x] 5.3 手动执行验收剧本：山地路线相比平原少走 1 格；两单位不能同格已由 `test_grid.gd` 占格用例自动覆盖
- [x] 5.4 重新跑 headless 单测全绿；确保第 1 章测试不回归
- [x] 5.5 更新 `README.md`：第 2 章打勾 + 「直接打开 `scenes/battle/battle.tscn` 运行验收」一段说明
- [x] 5.6 自检无 HP / 攻击 / 回合 / 部署 / AI 相关代码或 UI 元素引入
