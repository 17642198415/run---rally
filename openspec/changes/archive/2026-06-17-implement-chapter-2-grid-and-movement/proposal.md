## Why

第 1 章数据层已就绪，但工程仍缺少可视化战场与移动逻辑。第 2 章要求建立 10×10 整数格、四种地形 + 墙、占格表与 BFS 寻路，让单位能在复杂地形上根据 MOV 计算可达范围并通过点击移动。这是后续战斗（第 3 章）、回合与部署（第 4 章）的共用基础——没有它，攻击范围、AI 寻路、部署区都无法实现。本章只做格点和移动，**不做攻击、回合、菜单**，目的是把战场层的几何与寻路问题先彻底解决，避免和战斗逻辑耦合。

## What Changes

- 新增 `scripts/battle/` 模块：`terrain_types.gd`（地形常量与修正）、`grid.gd`（10×10 网格、地形查询、占格表）、`pathfinding.gd`（BFS 可达范围 + 路径回溯）、`unit_view.gd`（单位渲染与格坐标）。
- 新增 `data/map_templates/test_grid.json`：第 2 章验收用的测试地图，含 4 种地形 + 墙 + 双方部署区。
- 扩展 `scenes/battle/battle.tscn`：以色块（ColorRect）渲染 10×10 网格，放置 1 个测试单位；点击单位高亮可达格、点击合法格触发 tween 移动并更新占格。
- 新增最小化的 `scripts/battle/battle_grid_controller.gd`（或在 `battle.tscn` 根脚本中）承担「点击 → 高亮 → 移动」的交互调度，**不引入** HP / 攻击 / 回合按钮。
- 补充第 2 章单元测试（沿用第 1 章的 headless 测试入口）：覆盖地形修正、`is_walkable`（步行 vs 飞行 vs 墙 vs 占格）、移动消耗（山地 +1）、BFS 可达范围、路径回溯。
- 更新 `README.md` 第 2 章进度勾选与本章运行/验收说明。

## Capabilities

### New Capabilities

- `chapter-2-grid-and-movement`：覆盖 10×10 战场网格、四种地形 + 墙规则、占格管理、BFS 可达与寻路、点击移动交互、测试地图模板。

### Modified Capabilities

无。第 1 章 `chapter-1-data-layer` 不变，仅作为依赖被 Battle 场景的初始化复用（本章不读取单位 JSON 数值；测试单位采用最小化硬编码参数即可）。

## Impact

- **Godot 工程**：`scenes/battle/battle.tscn` 由占位升级为可交互测试场景；不改变 main scene（仍为 `scenes/main_menu.tscn`），第 2 章通过编辑器直接打开 `battle.tscn` 运行验收。
- **代码**：新增 `scripts/battle/{terrain_types,grid,pathfinding,unit_view,battle_grid_controller}.gd` 与对应 `.uid`；不修改第 1 章 Autoload 接口。
- **数据**：新增 `data/map_templates/test_grid.json`；不影响 `data/units/`、`data/skills/`、`data/hero.json`。
- **测试**：在 `tests/unit/` 下新增 `test_grid.gd`、`test_pathfinding.gd`，沿用第 1 章 headless 测试入口；测试文件不依赖渲染。
- **依赖**：无新增第三方依赖；继续使用 GDScript + Godot 4.6 原生能力。
- **后续章节**：第 3 章战斗将复用 `Grid.is_walkable`、`Pathfinding.get_reachable` 计算攻击范围；第 4 章部署阶段将读取 `test_grid.json` 的 `deploy_zones`。
