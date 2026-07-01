## Context

第 7 章是 Demo 完整实施计划的肉鸽核心，里程碑 M3。Demo 计划 7.9 已给出「两步走」做法：7A 只做生成器 + RunState，7B 做 UI + 战斗接入。当前仓库已完成 0~6 章（M2 战役模式）与两轮 Tier 1 视觉打磨；战斗框架 (`battle_scene.gd`)、数据加载 (`DataLoader`)、存档 (`SaveManager`) 与战役自动加载 (`CampaignManager / PartyManager / BestiaryManager`) 已稳定。

约束：
- Godot 4.6 + GDScript，禁止引入新外部依赖
- 现有 20 个 headless 单测必须保持通过；本章新增的逻辑必须可在 headless 环境下覆盖
- 用户全局规则：优先在现有目录约定下新增能力，不新建平行入口；不擅自新增文档
- 数据先行：本 Change 一次性补齐 5 张地图模板 + 5 个敌组文件，让 7B UI 可以直接消费

## Goals / Non-Goals

**Goals:**
- 提供「种子可重放」的 `RouteGenerator`：同种子 → 同 6 层结构 + 同节点 id 序列
- 提供「可序列化」的 `RunState`：能完整还原一次 Run 的内存状态
- 提供 `RunManager` 自动加载：把 Run 生命周期与 `SaveManager` 解耦，UI 层（7B）只需调用高层 API
- 数据契约稳定：`layer_pools.json`、`enemy_groups/*.json`、新增 2 张地图模板符合既有命名与结构约定
- 单测可独立验证：所有新模块都能在 headless 模式下被 `tests/run_tests.gd` 加载并断言

**Non-Goals:**
- 不做任何 UI：route_map / shop / rest / capture_event / run_summary 场景 → 7B
- 不接入 Battle：节点 → 战斗的串联、PartySetup 肉鸽版 → 7B
- 不实现 Meta 解锁、不做三选一奖励 → 第 8 章
- 不修改战役流程的对外行为；`stage_select` / `party_setup` / `bestiary_view` 不改

## Decisions

### D1 — RunState 用 `class_name` + `Resource`，不做 autoload

候选：
- A. `class_name RunState extends Resource`，由 `RunManager` 持有当前实例
- B. 把 RunState 直接做成 autoload（全局单例）
- C. 用普通 Dictionary 散落在 `RunManager`

选择 **A**。原因：(1) `Resource` 支持 `ResourceSaver`，未来可直接落盘 `.tres` 做 debug snapshot；(2) `class_name` 让单测可以 `var rs := RunState.new()` 直接构造，无需依赖 `/root/`；(3) 与 Demo 7.4.1 类签名一致。B 的问题是测试无法构造多个独立实例；C 失去类型检查。

### D2 — 路线表示用「层数组 + 节点 id」而非邻接表

`route_graph` 结构：
```
[
  { "layer": 1, "nodes": [ {"id": "L1N0", "type": "battle"}, {"id": "L1N1", "type": "capture_event"} ] },
  { "layer": 2, "nodes": [ ... ] },
  ...
  { "layer": 6, "nodes": [ {"id": "L6N0", "type": "boss"} ] }
]
```

候选：
- A. 层数组（上）— 选中
- B. 完整 DAG（每节点带 `connections`）
- C. 邻接矩阵

选 **A**。Demo 7.5 的路线图是「每层平行 N 选 1，相邻层全连通」的最简结构；不存在「跳层」或「分支汇合」，DAG/矩阵是过度设计。`selected_path: Array[String]` 按层顺序累积节点 id 即可表达走过的路径，UI 渲染连线时按「上层选中 → 下层全部」即可。

### D3 — 约束「层 3 或 5 至少 elite 或 shop」用「生成 + 重抽」而非「先抽再插入」

候选：
- A. 生成完毕后检查约束，不满足则重抽（最多 N 次，失败兜底强制把层 3 第一个节点替换为 `elite`）
- B. 在抽样前先保留某槽位

选 **A**。原因：池子很小（每层 ≤ 3 候选），重抽收敛极快；A 实现简单、纯函数无副作用，便于单测断言「100 个不同种子下约束 100% 满足」。

### D4 — 敌组数据用「按层加权」JSON，picker 用 `RandomNumberGenerator.randf_range`

`data/enemy_groups/layer_*_*.json` 结构：
```
{
  "id": "layer_1_2_normal",
  "groups": [
    {
      "weight": 60,
      "map_template": "T_PLAIN",
      "enemies": [
        { "template": "M01", "spawn": { "x": 7, "y": 3 } },
        { "template": "M02", "spawn": { "x": 8, "y": 4 } }
      ]
    },
    { "weight": 40, "map_template": "T_FOREST", "enemies": [...] }
  ]
}
```

每个 group 自带 `map_template`，picker 用「累积权重 + randf * total」选中后整组返回。地图与敌组绑定，避免出现「平原模板上配森林敌人」这种语义错位。

### D5 — `RunManager` 与 `SaveManager` 的边界

`RunManager`（autoload）只做三件事：
1. 持有当前 `RunState`（可为 `null`）
2. 调用 `RouteGenerator` 创建新 Run
3. 调用 `SaveManager.load_meta() / save_meta()` 读写 `run` 节

`SaveManager` 不感知 `RunState` 类，只看到 `Dictionary`；序列化在 `RunState.serialize()` 完成。这样：
- `SaveManager` 仍是「纯 IO + 默认值合并」
- `RunManager` 可以单测，不需要真实文件系统（注入 mock SaveManager 即可）

存档 schema 扩展（仅追加）：
```
{
  ...既有字段保持不变...,
  "run": {
    "active": false,
    "state": null
  }
}
```

`active = true` 时 `state` 是 RunState 序列化字典；`active = false` 时 `state` 必须为 `null`。`merge_with_defaults` 不递归合并 `state` 子字段（它是整体写整体读）。

### D6 — 不动现有 GameState

`GameState` 已有 `enum GameMode { NONE, CAMPAIGN, ROGUELIKE }`，本章不写入 `ROGUELIKE`、不动 `battle_context`。7B 在「肉鸽节点 → Battle」时再设置 `current_mode = ROGUELIKE` 并填 `battle_context`。这样保证战役回归测试不受影响。

### D7 — 新增 2 张地图模板的尺寸与部署区与既有 3 张保持一致

`T_FOREST.json` 与 `T_MIX.json` 都使用 10x10 网格、`deploy_zones.player` 6 格、`enemy` 4 格的同一约定，仅 `terrain` 不同：
- `T_FOREST`：障碍密集在中线，玩家从左侧进入
- `T_MIX`：障碍混合分布，更接近 BOSS 战的复杂度

这样 7B 接 Battle 时无需修改任何 `deploy_phase / grid` 代码。

## Risks / Trade-offs

- **风险 1**：种子重抽兜底逻辑可能在极端池配下死循环 → **缓解**：硬上限 `MAX_RETRIES = 32`，超过则按 D3 兜底强制替换，并在 `push_warning` 中打印种子供调试
- **风险 2**：`SaveManager.merge_with_defaults` 当前只浅合并一层，加 `run` 节后若旧存档没有该字段需正确补齐 → **缓解**：新增单测 `test_save_run_legacy_compat`，断言旧存档加载后自动得到 `run = {active: false, state: null}`
- **风险 3**：`RunState` 序列化层若漏掉新字段会导致存档不可还原 → **缓解**：新增「序列化-反序列化幂等」单测，断言 `RunState.deserialize(rs.serialize()).serialize() == rs.serialize()`
- **风险 4**：新地图模板 deploy_zones 与 stage JSON 现有 spawn 坐标不一致可能导致 7B 战斗加载失败 → **缓解**：本章只交付模板与敌组，spawn 坐标在敌组 JSON 内统一管理，避免和现有 `stage_*.json` 耦合
- **Trade-off**：`route_graph` 用层数组而非 DAG，未来若需要「桥接节点」或「跳层」需要重构数据结构 → 接受，按 YAGNI 原则当前不预设

## Migration Plan

1. 先扩展 `SaveManager.get_default_save()` + 单测（兼容旧存档）
2. 落数据：`layer_pools.json` / `node_types.json` / `enemy_groups/*.json` / `T_FOREST.json` / `T_MIX.json`
3. 写 `RunState`（含 serialize/deserialize）+ 单测
4. 写 `RouteGenerator`（依赖 `RunState`）+ 单测
5. 写 `EnemyGroupPicker`（依赖数据）+ 单测
6. 写 `RunManager` autoload + 注册 `project.godot` + 单测（mock SaveManager）
7. 跑全量 headless 单测（既有 20 + 新增 ≥12）

回滚：所有新增文件可整体删除；唯一对现有文件的修改是 `SaveManager.get_default_save()` 和 `project.godot` 的 autoload 列表，回滚成本低。
