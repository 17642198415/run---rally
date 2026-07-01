## 1. SaveManager 扩展（先做，含 RED 测试）

- [x] 1.1 在 `tests/` 下新增 `test_save_run_legacy_compat.gd`：断言旧存档（无 `run` 键）经过 `SaveManager.load_meta()` 后包含 `run = {active: false, state: null}` 与 `stats = {}`（RED：当前默认无该字段）
- [x] 1.2 修改 `scripts/autoload/save_manager.gd`：`get_default_save()` 追加 `"run": {"active": false, "state": null}` 与 `"stats": {}`
- [x] 1.3 跑 `godot --headless --script tests/run_tests.gd`，确认 1.1 转 GREEN 且既有 20 个测试保持通过

## 2. 路线/敌组/地图数据落盘

- [x] 2.1 创建 `data/route/layer_pools.json`，按 design.md D3 写入 6 层池配置（与 Demo 7.4.2 一致）
- [x] 2.2 创建 `data/route/node_types.json`，包含 6 种节点类型（battle/elite/rest/shop/capture_event/boss）的 `display`、`color_hex`、`icon` 字段（颜色按 Demo 7.6 表格）
- [x] 2.3 创建 `data/enemy_groups/layer_1_2_normal.json`，2~3 组，权重总和 100，全部使用 `T_PLAIN` / `T_WET` / `T_FOREST` 任一
- [x] 2.4 创建 `data/enemy_groups/layer_3_4_normal.json`，难度略升，可混入 `M03` / `M04`
- [x] 2.5 创建 `data/enemy_groups/layer_3_4_elite.json`，敌组规模 ≥ 3，倾向 `T_FORT` / `T_MIX`
- [x] 2.6 创建 `data/enemy_groups/layer_5_elite.json`，含 `M05` / `M06` 高级单位
- [x] 2.7 创建 `data/enemy_groups/layer_6_boss.json`，1 组固定，包含 `BOSS_MERC` 与 2 个护卫
- [x] 2.8 创建 `data/map_templates/T_FOREST.json`：10x10、障碍中线密集、deploy_zones 与 T_PLAIN 同结构
- [x] 2.9 创建 `data/map_templates/T_MIX.json`：10x10、障碍混合分布、deploy_zones 与 T_PLAIN 同结构

## 3. RunState（class_name + Resource）

- [x] 3.1 在 `tests/` 下新增 `test_run_state.gd`：(a) 默认值断言；(b) 序列化-反序列化幂等；(c) `mark_node_completed` 行为（RED）
- [x] 3.2 创建 `scripts/roguelike/run_state.gd`，`class_name RunState extends Resource`，按 design D1 实现字段与 `@export` 标记
- [x] 3.3 实现 `serialize() -> Dictionary` / `static func deserialize(d: Dictionary) -> RunState`
- [x] 3.4 实现 `mark_node_completed(node_id: String) -> void` 与 `advance_layer() -> void`
- [x] 3.5 跑单测，确认 3.1 全部 GREEN

## 4. RouteGenerator（纯函数）

- [x] 4.1 在 `tests/` 下新增 `test_route_generator.gd`：(a) 同种子可重放；(b) 不同种子大概率不同（50 对 ≥ 45）；(c) 层 6 恒为 boss；(d) 100 种子下层 3/5 约束 100% 满足（RED）
- [x] 4.2 创建 `scripts/roguelike/route_generator.gd`，提供 `static func generate(seed: int, rng: RandomNumberGenerator = null) -> Array`
- [x] 4.3 在 generator 内部读 `data/route/layer_pools.json`（通过 `FileAccess`，避免依赖 `DataLoader`）并实现「层数组」结构（design D2）
- [x] 4.4 实现约束检查 + 最多 32 次重抽 + 兜底强制 elite（design D3）
- [x] 4.5 节点 id 命名格式 `L<layer>N<index>`，全 graph 唯一
- [x] 4.6 跑单测，确认 4.1 全部 GREEN

## 5. EnemyGroupPicker（纯函数）

- [x] 5.1 在 `tests/` 下新增 `test_enemy_group_picker.gd`：(a) 普通层返回合法 group；(b) boss 层返回含 boss 单位；(c) 相同 RNG 种子结果一致（RED）
- [x] 5.2 创建 `scripts/roguelike/enemy_group_picker.gd`，提供 `static func pick(layer: int, is_elite: bool, is_boss: bool, rng: RandomNumberGenerator) -> Dictionary`
- [x] 5.3 实现「文件路径解析 → 累积权重 → randf 选中」逻辑（design D4）
- [x] 5.4 缺失文件时 `push_error` 并返回 `{"map_template": "", "enemies": []}`
- [x] 5.5 跑单测，确认 5.1 全部 GREEN

## 6. RunManager autoload

- [x] 6.1 在 `tests/` 下新增 `test_run_manager_persistence.gd`：(a) `start_new_run` → 状态非空；(b) `save() → clear() → load_from_meta()` 幂等；(c) `clear` 后 `get_state() == null`；(d) 旧存档兼容（RED）
- [x] 6.2 创建 `scripts/autoload/run_manager.gd`，按 design D5 实现 5 个公共方法
- [x] 6.3 在 `project.godot` 的 `[autoload]` 段追加 `RunManager="*res://scripts/autoload/run_manager.gd"`（注意顺序：在 SaveManager 之后）
- [x] 6.4 测试中通过临时改 `SaveManager.SAVE_PATH = "user://test_run_save.json"` 避免污染真实存档，测试结束后清理临时文件
- [x] 6.5 跑单测，确认 6.1 全部 GREEN

## 7. 文档与回归

- [x] 7.1 `README.md` 的「进度」章节追加一行：`- [x] 第 7A 章 肉鸽核心（数据/状态/Generator/RunManager）已完成`
- [x] 7.2 `README.md` 在「测试」段说明新增单测文件数与覆盖范围（仅追加，不重写）
- [x] 7.3 跑全量 headless 测试：`godot --headless --script tests/run_tests.gd`，确认 既有 20 个 + 本章新增 ≥ 12 个 全部通过
- [x] 7.4 用 3 个不同 seed 跑 `RouteGenerator.generate` 并打印 route_graph，目检层数与约束符合 Demo 7.4.2
- [x] 7.5 勾选 `tasks.md` 全部任务，准备 `/opsx-apply` 后 `/opsx-archive`
