## Context

第 1 章已完成数据层：8 单位 + 10 技能 + 主角 JSON、Autoload（DataLoader/GameState/SaveManager/MetaManager）、headless 单测入口（`tests/unit/`）。当前 `scenes/battle/battle.tscn` 仅是占位。

第 2 章要把战场层「几何 + 寻路 + 点击交互」做完整，但**不引入** HP / 攻击 / 回合 / AI / 部署。第 3 章战斗将复用本章的 `Grid` 占格表与 `Pathfinding` 服务计算攻击范围；第 4 章部署阶段会读 `test_grid.json` 的 `deploy_zones`。因此本章设计需要保证：

- 网格、寻路、单位视图三者职责清晰，便于第 3~4 章扩展。
- 渲染层（ColorRect 色块）与逻辑层（`Grid` / `Pathfinding`）解耦：逻辑层无 `Node` 依赖，可在 headless 单测中直接构造。
- 地形规则与第 0~1 章设定一致（详见 [Demo 计划 §2.4.1](../../../Demo完整实施计划.md#241-地形枚举)）。

约束：

- Godot 4.6 + GDScript，沿用 `class_name` + 静态方法风格。
- Windows 中文路径，所有 JSON 用 UTF-8 无 BOM。
- 仍只走 `tests/unit/` 的 headless 测试入口，不引入 GUT 等插件。

## Goals / Non-Goals

**Goals:**

- 10×10 整数格、`(0,0)` 左上、坐标用 `Vector2i`。
- 四种地形（平原/森林/山地/水域）+ 墙；地形修正按 §2.4.1：森林 `def +1`、山地 `mov_cost +1` 且 `def +1`、水域步行不可进且飞行可进、墙不可通行。
- `Grid` 维护 `terrain` 二维数组与 `occupancy: Dictionary[Vector2i → unit_id]`，提供 `is_walkable / set_occupant / clear_occupant / get_terrain / get_move_cost` 等纯逻辑 API。
- `Pathfinding`（纯静态函数）实现 BFS：`get_reachable(grid, start, mov, unit_type) → Array[Vector2i]` 与 `find_path(grid, start, goal, mov, unit_type) → Array[Vector2i]`，能正确处理山地额外消耗与占格阻挡（自身格不算阻挡）。
- `data/map_templates/test_grid.json` 与 §2.4.2 完全一致（terrain 二维 + `deploy_zones`）。
- `battle.tscn` 渲染 10×10 色块 + 1 个测试单位；点击单位高亮可达格、点击合法格 tween 移动并更新 `occupancy`；点击不可达格忽略。
- 单元测试：地形修正、is_walkable、move_cost、BFS 可达、路径回溯（含山地 / 墙 / 水域 / 占格 / 飞行例外）。

**Non-Goals:**

- 不实现 HP / 攻击 / 技能 / CD / 死亡 / 胜负判定（第 3 章）。
- 不实现回合机、部署阶段、AI（第 4 章）。
- 不读取 `data/units/*.json` 的真实数值（测试单位用最小硬编码 `mov=4, unit_type="foot"`）。
- 不接入 main_menu 跳转（直接在编辑器打开 `battle.tscn` 运行验收）。
- 不做美术资源，全部 ColorRect 色块。

## Decisions

1. **逻辑层与视图层分离：`Grid` / `Pathfinding` 不继承 `Node`。**
   - 方案：`Grid` 用 `class_name Grid extends RefCounted`；`Pathfinding` 写成纯静态函数（`class_name Pathfinding`，全 `static func`）；`UnitView` 与 `BattleGridController` 才继承 `Node2D` / `Node`。
   - 理由：headless 单测可直接 `Grid.new()` 与 `Pathfinding.get_reachable(...)`，无需场景树；第 3 章战斗也能复用同样的逻辑实例。
   - 替代方案：`Grid` 做 Autoload。缺点是单测需启动整个 Autoload 链；多场景时全局状态难管理。否决。

2. **地形修正用查表函数 + 集中常量。**
   - 方案：`terrain_types.gd` 暴露 `PLAIN/FOREST/MOUNT/WATER/WALL` 常量与三个静态函数：`get_move_cost_extra(terrain) -> int`（山地 +1，其它 0）、`get_def_bonus(terrain) -> int`（森林/山地 +1）、`is_passable(terrain, unit_type) -> bool`（墙永不通；水域只允许 `flying`）。
   - 理由：第 3 章伤害公式与第 4 章 AI 都会读地形修正，集中常量利于一致性；`unit_type` 限定在 `foot / flying / heavy / mount` 字符串（先实现 foot/flying，第 3 章扩展）。
   - 替代方案：在 `Grid` 内嵌入修正。缺点是与渲染/单位耦合。否决。

3. **BFS 用 Dijkstra-lite（统一权重 + 山地额外 +1）。**
   - 方案：`Pathfinding.get_reachable` 维护 `cost_so_far: Dictionary[Vector2i → int]`，每次扩展邻居时计算 `new_cost = cost_so_far[cur] + 1 + terrain_extra(neighbor)`，若 `new_cost <= mov` 且优于已记录则入队。终态返回 `cost_so_far` 中除起点外的所有键。`find_path` 用 `came_from` 字典回溯。
   - 理由：mov_cost 仅 0/1 两档，等价于带权 BFS，实现更直观；统一在「进入邻居时算 cost」避免「在出发格扣山地费」的双扣 bug（[Demo §C.2 山地双扣](../../../Demo完整实施计划.md#c2-网格与移动)）。
   - 替代方案：标准 BFS + 多趟扩展。会复杂且容易遗漏山地情形。否决。

4. **占格表用 `Dictionary[Vector2i → String]`，自身格不算阻挡。**
   - 方案：`Grid.is_walkable(pos, unit_type, mover_id := "")`：先判越界 → 地形不可通行 → 然后看 `occupancy.get(pos, "") not in ["", mover_id]`。`set_occupant` 移动时由 controller 先 `clear_occupant(old)` 再 `set_occupant(new)`。
   - 理由：BFS 路径会经过 `mover` 自己出发的格；以 `mover_id` 排除自身可避免起点被自身阻断。
   - 替代方案：先临时清除自身再算。可行但耦合到 mover 状态，单测复杂。否决。

5. **测试地图：JSON 模板 + 加载器。**
   - 方案：`Grid.from_template(template: Dictionary) -> Grid` 静态构造；`battle_grid_controller.gd` 启动时 `JSON.parse_string(load(path).get_as_text())` 读 `data/map_templates/test_grid.json`，传入构造。
   - 理由：与第 1 章 DataLoader 风格一致（数据驱动）；第 4 章可复用同一模板格式。
   - 不在 DataLoader 里加方法：保持第 1 章接口稳定，等第 6 章战役模板再决定是否合并。

6. **渲染：每格一个 ColorRect 子节点，固定 64×64 像素。**
   - 方案：`battle.tscn` 根节点 `Node2D`，下挂 `GridRoot: Node2D`（含 100 个 ColorRect 格 + 高亮层 ColorRect）+ `UnitsRoot: Node2D`；色按 `terrain_types.gd` 中的 `COLOR_BY_TERRAIN` 字典查表。10×10 × 64 = 640px，加 HUD 留白能放进 1280×720。
   - 替代方案：TileMap。优点是更"正统"；缺点是要做 TileSet 资源，第 2 章避免引入额外资源管理。第 3~4 章再视进度切换。

7. **点击交互的状态机（极简两态）。**
   - 状态：`IDLE`（无选中）、`UNIT_SELECTED`（已选中且高亮可达）。
   - 流程：`IDLE` 点中单位 → `UNIT_SELECTED` 计算并显示高亮；`UNIT_SELECTED` 点高亮格 → 执行 tween 移动，结束后回 `IDLE`；点同一单位或空白处 → 回 `IDLE` 清高亮。
   - 理由：第 3 章再加 `ATTACK_TARGETING` 等态，本章先不引入「移动后再操作」概念。

## Risks / Trade-offs

- [Risk] BFS 在 10×10 + mov=4 下性能没问题，但若第 5 章肉鸽地图扩到更大尺寸需要重做寻路 → Mitigation：API 层不假设 10×10，所有遍历用 `grid.width / grid.height`；第 7 章再评估是否升级 A*。
- [Risk] `Vector2i` 作为 `Dictionary` 键在 Godot 4.6 是按值哈希但 GDScript 2 早期版本曾有 bug → Mitigation：测试中显式构造同值 `Vector2i` 验证字典命中；如遇问题改用 `int = y * width + x` 编码键。
- [Risk] tween 移动期间用户连点导致状态错乱 → Mitigation：`BattleGridController` 在 tween 期间设 `is_moving = true`，期间忽略输入；tween `finished` 后恢复并 emit 信号。
- [Risk] 测试地图坐标体系（行 = y，列 = x）容易和 JSON 二维数组（外层 = 行）混淆 → Mitigation：在 `Grid.from_template` 注释明确 `terrain[y][x]`；单测加一条「读 (x=3,y=3) 应为 WALL」的断言锁住约定。
- [Trade-off] 不接 main_menu 跳转：本章靠直接打开 `battle.tscn` 运行；好处是不污染主菜单流程，坏处是体验上要切场景手工运行。第 4 章里把入口接回 main_menu 的「调试入口」按钮。
- [Trade-off] 单位视图 `UnitView` 用 ColorRect + Label（首字图标）而非 Sprite2D：当前美术全占位，等第 5 章再统一替换为图标贴图。
