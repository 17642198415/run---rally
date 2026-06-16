## Context

当前仓库是 Godot 4.6 标记的空 Demo 工程，已完成第 0 章环境配置：`project.godot`、`README.md` 与 `scenes/main_menu.tscn` 已存在。第 1 章要求在此基础上建立数据驱动骨架，并保持后续章节可复用：所有基础单位、技能、主角数据从 `data/` JSON 加载，通用状态与存档入口通过 Autoload 暴露。

本次变更还需要补充单元测试框架。仓库目前没有测试框架，因此采用 Godot 原生 headless 执行脚本的最小测试方式，避免在第 1 章引入 GUT 等额外插件依赖；后续如测试规模扩大，可再迁移到 GUT。

## Goals / Non-Goals

**Goals:**

- 按第 1 章创建数据目录、Autoload 脚本和占位场景。
- `DataLoader` 能读取 `data/units/*.json`、`data/skills/*.json` 与 `data/hero.json`，提供 `get_unit()`、`get_skill()`、`get_hero()`、`get_all_unit_ids()`。
- `project.godot` 注册 Autoload，顺序为 `DataLoader` → `GameState` → `SaveManager` → `MetaManager`。
- 补充可在命令行运行的单元测试，覆盖 JSON 解析、关键字段、单位技能关联和接口返回。

**Non-Goals:**

- 不实现网格、战斗、捕捉、战役、肉鸽或 Meta 解锁逻辑。
- 不引入大型测试插件或 CI 配置。
- 不改变第 0 章已完成的显示分辨率与运行方式。

## Decisions

1. **使用 Godot headless 脚本作为最小测试框架。**
   - 方案：新增 `tests/unit/test_data_loader.gd` 与简单断言工具，通过 `godot --headless --script tests/unit/test_data_loader.gd` 运行。
   - 理由：符合“没有框架要补充测试框架”的要求，同时避免第 1 章引入额外插件目录和复杂配置。
   - 替代方案：引入 GUT。优点是功能完整；缺点是依赖更重、初始化文件更多，超出当前章的数据层需求。

2. **`DataLoader` 以静态路径扫描和字典缓存实现。**
   - 方案：扫描 `res://data/units` 和 `res://data/skills` 下 `.json` 文件，解析后按 `id` 缓存。
   - 理由：后续章节能通过稳定接口获取数据，不依赖具体文件名；新增 JSON 不需要改代码。
   - 替代方案：硬编码文件列表。优点是简单；缺点是扩展时容易遗漏。

3. **Autoload 保持轻量空壳。**
   - 方案：`GameState` 只放枚举与基础字段，`SaveManager` 提供固定 `user://save_meta.json` 路径和默认结构，`MetaManager` 保留第 8 章扩展点。
   - 理由：满足第 1 章接口与顺序要求，不提前实现后续章节行为。

## Risks / Trade-offs

- [Risk] 本地 Godot 可执行文件不在 PATH，测试命令无法运行 → Mitigation：优先尝试 `godot --version`，失败时报告需要用户配置 Godot CLI；测试脚本本身仍落盘。
- [Risk] Godot 4.6 对部分 typed Array 或脚本语法要求较严格 → Mitigation：使用保守 GDScript 语法，运行 headless 测试校验。
- [Risk] 直接编辑 `project.godot` 的 Autoload 配置可能与编辑器生成格式有差异 → Mitigation：使用 Godot 支持的 `[autoload]` 配置形式，并保持 main scene 既有 UID 不变。
