## Why

第 0 章环境已完成，但工程尚缺少第 1 章要求的可运行项目骨架、Autoload 数据入口与基础 JSON 数据。先建立稳定的数据层和测试框架，可以为后续网格、战斗、捕捉、战役与肉鸽系统提供统一数据契约。

## What Changes

- 建立第 1 章目录结构：`data/`、`scripts/autoload/`、`scenes/battle/`、`assets/placeholder/` 等。
- 新增 8 个灵兽 JSON、10 个技能 JSON 与 `data/hero.json`，字段对齐实施计划第 1 章。
- 实现 Autoload 脚本空壳与数据读取接口：`DataLoader`、`GameState`、`SaveManager`、`MetaManager`。
- 将主场景保持为 `scenes/main_menu.tscn`，启动时显示占位文字并触发数据加载验证。
- 补充 Godot/GDScript 单元测试框架与数据层测试，确保 `DataLoader` 能解析单位、技能、主角并暴露查询接口。

## Capabilities

### New Capabilities
- `chapter-1-data-layer`: 覆盖项目骨架、基础游戏 JSON 数据、Autoload 单例和数据加载查询接口。

### Modified Capabilities

无。

## Impact

- 影响 Godot 工程配置 `project.godot`：注册 Autoload、确认 main scene。
- 新增/修改数据文件：`data/units/*.json`、`data/skills/*.json`、`data/hero.json`。
- 新增/修改 GDScript：`scripts/autoload/*.gd` 与测试脚本。
- 新增测试运行能力，后续章节可复用同一测试入口执行单元测试。
