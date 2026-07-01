## Why

Demo 完整实施计划第 7 章「肉鸽路线图与 Run 状态」是里程碑 M3 的核心，需要把当前只有战役（M2）的内容扩展为可重复游玩的肉鸽流程。为了让节奏可控、单测可验，我们按 Demo 计划 7.9 的「两步走」做法把第 7 章拆分为 **7A（纯逻辑层）** 与 7B（UI + 战斗接入）；本 Change 仅交付 7A：种子化路线生成、Run 内存/存档状态、敌组与地图模板的数据底座，让 7B 在 UI 层能直接消费稳定的纯函数与数据契约。同步引入「Run 中存档」能力，让肉鸽流程中途也能保存到 `user://save_meta.json`，避免玩家被关闭游戏打断。

## What Changes

- 新增 `RunState`（GDScript class，纯数据/方法对象，非自动加载），包含 `seed / current_layer / route_graph / selected_path / party / reserve / balls / coins / hero_dead` 字段，以及 `serialize() / deserialize()`、`mark_node_completed()`、`advance_layer()` 等接口
- 新增 `RouteGenerator`（纯函数模块），输入种子 + `data/route/layer_pools.json` → 输出固定 6 层、每层 2~3 选 1、层 6 固定 BOSS、且满足「层 3 或 5 至少有 elite 或 shop」约束的 `route_graph`
- 新增 `EnemyGroupPicker`（纯函数模块），输入层号、是否精英、是否 boss、`RandomNumberGenerator` → 输出 `{ map_template, enemies }`；按 `data/enemy_groups/*.json` 加权挑选
- 新增数据：
  - `data/route/layer_pools.json`（按 Demo 7.4.2 落盘）
  - `data/route/node_types.json`（type 元信息、颜色、显示文本，便于 7B UI 直接读取）
  - `data/enemy_groups/layer_1_2_normal.json`、`layer_3_4_normal.json`、`layer_3_4_elite.json`、`layer_5_elite.json`、`layer_6_boss.json`
  - `data/map_templates/T_FOREST.json`、`T_MIX.json`（补齐到 5 张）
- 新增自动加载 `RunManager`：持有「当前进行中的 Run」（可为空），提供 `start_new_run(seed) / get_state() / clear() / save() / load_from_meta()`，仅负责生命周期与与 `SaveManager` 的桥接，**不**渲染 UI、**不**直接调用 Battle
- 扩展 `SaveManager.get_default_save()`：新增顶层 `run` 节，结构 `{ "active": bool, "state": <RunState dict> }`；新增 `clear_active_run()` 等便捷方法（仅写入/读取，不感知业务）
- `MetaManager` 新增 `stats` 钩子（仅占位结构，本章不写入）：`stats.run_total / run_won / run_lost / enemies_captured`，留给第 8 章
- 不在本章实现：路线图 UI、节点 handler 进入战斗的串联、PartySetup 肉鸽版、Shop/Rest/CaptureEvent/RunSummary 场景、主菜单「开始征途」启用 → 全部归入后续 7B Change
- 不破坏现有战役流程：`GameState.current_mode = ROGUELIKE` 在 7B 才会被设置，本章仅保留枚举与文档约定

## Capabilities

### New Capabilities
- `roguelike-core`: Run 内存与存档状态、种子化路线生成器、敌组与地图模板数据底座、`RunManager` 自动加载、保存/加载 Run 的契约

### Modified Capabilities
- `chapter-6-campaign-and-menu`: 主菜单「开始征途」的「未就绪」描述需保留但补充说明「7A 数据/状态已就绪、7B 接入 UI 后启用」；除此之外无 spec 级行为变更

## Impact

- **代码**
  - 新增 `scripts/roguelike/run_state.gd`、`scripts/roguelike/route_generator.gd`、`scripts/roguelike/enemy_group_picker.gd`
  - 新增 autoload `scripts/autoload/run_manager.gd` 并在 `project.godot` 注册
  - 扩展 `scripts/autoload/save_manager.gd`（默认结构 + `merge_with_defaults` 支持 `run` 节）
  - 扩展 `scripts/autoload/meta_manager.gd`（新增 `stats` 占位结构，不修改既有 `unlocked`）
- **数据**
  - 新增 `data/route/layer_pools.json`、`data/route/node_types.json`
  - 新增 `data/enemy_groups/*.json`（5 个文件）
  - 新增 `data/map_templates/T_FOREST.json`、`T_MIX.json`
- **测试**
  - 新增 `tests/test_run_state.gd`、`tests/test_route_generator.gd`、`tests/test_enemy_group_picker.gd`、`tests/test_run_manager_persistence.gd`
  - 既有 20 个单测保持通过；新章节单测 ≥ 12 个，覆盖：种子可重放、约束满足、序列化-反序列化幂等、SaveManager 存读 Run、加权随机分布
- **风险与依赖**
  - 仅依赖 Godot 4.6 标准库与现有 `DataLoader/SaveManager`，无新外部依赖
  - 不影响现有战役/捕捉/图鉴流程；所有新文件采用现有 `scripts/<feature>/` + `data/<feature>/` 目录约定
- **文档**
  - `README.md` 进度章节追加「第 7A 章 完成」一行；不新建独立文档（依据用户全局规则）
