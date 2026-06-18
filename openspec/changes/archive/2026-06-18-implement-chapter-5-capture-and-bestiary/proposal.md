## Why

第 4 章已完成回合制战斗主循环，但击败野生灵兽只是把它们从战场移除——MVP §4.5~4.6 的核心玩法「捉宠」尚未落地。第 5 章引入捕捉、备用栏与图鉴持久化，把单场战斗从「打赢」延伸为「打赢 + 收集」，并落定唯一持久化文件 `user://save_meta.json` 的格式，为第 6 章战役（编队 / 进度）和第 7 章肉鸽（reserve / Run）的存档结构铺路。

## What Changes

- 新增「可捕捉」战场状态：HP≤0 的 **野生敌方单位** 不再被立即从 `Grid` 移除，而是变为 `downed_capturable`，停止行动并保持占格。其他原有死亡判定（玩家阵亡、HERO 阵亡、全灭判胜）保持不变。
- 新增 `CaptureSystem`：相邻规则（曼哈顿距离=1）、成功率公式（HP%、阵营 base、事件加成）、四档显示（高/中/低/极低）、roll 与扣球。
- 新增 `PartyManager`（数据层）：持有「已捕获」备用栏，本章仅维护内存数据结构 + 持久化字段，**不动 deploy 流程**（HERO 仍是唯一玩家可部署单位）。
- 新增 `BestiaryManager`：维护每只灵兽的 `discovered` / `caught` 状态。野生单位首次出现写 discovered，捕获成功写 caught。
- 扩展 `SaveManager`：写入 / 读取 `user://save_meta.json`，结构包含 `bestiary`、`party.reserve`、`stats`、`campaign`（占位）、`meta`（占位）；启动时回灌 `MetaManager` / `BestiaryManager`。
- 扩展 `BattleScene` / `BattleGridController`：捕捉球数从 `stage.player.balls` 读入；`ActionBar` 新增 `[捕捉]` 按钮（仅当当前选中玩家相邻一个 `downed_capturable` 时启用）；UI 弹出 `CapturePrompt` 显示档位 + 剩余球。
- 数据：新增 `data/capture_config.json`（base_rate、各 unit_id 修正、档位阈值）；`debug_battle.json` 增加 `player.balls = 3` 字段。
- 调整 BattleEnd 判定：胜负条件改为「玩家方 HERO 阵亡 → 失败 / 敌方无 **存活** 单位 → 胜利」（`downed_capturable` 不算存活，但占位防止判胜抖动需明确实现）。
- **MODIFIED**：`chapter-3-combat-and-counter` 的死亡处理需要补一条「野生单位 HP≤0 时进入 downed_capturable，不立即从 grid 移除；HERO/玩家方与非野生敌方仍按原逻辑移除」。
- **MODIFIED**：`chapter-4-turns-deploy-and-ai` 的 `BattleEnd` 判定需要补一条「`downed_capturable` 不计入存活敌方」。

## Capabilities

### New Capabilities
- `chapter-5-capture-and-bestiary`：捕捉触发条件、概率公式与档位、捕捉球经济、备用栏数据结构、图鉴 discovered/caught 状态、`user://save_meta.json` 持久化、`ActionBar` 捕捉按钮与 `CapturePrompt` UI。

### Modified Capabilities
- `chapter-3-combat-and-counter`：野生单位「击倒不移除」的死亡处理新分支。
- `chapter-4-turns-deploy-and-ai`：BattleEnd 把 `downed_capturable` 视为非存活敌方。

## Impact

- 代码：新增 `scripts/battle/capture_system.gd`、`scripts/managers/party_manager.gd`、`scripts/managers/bestiary_manager.gd`；扩展 `scripts/autoload/save_manager.gd`；改 `scripts/battle/battle_unit.gd`（加 `downed_capturable` 标记 + `is_wild` / `is_alive_for_battle` 辅助）、`scripts/battle/battle_controller.gd`（hp≤0 分支）、`scripts/battle/battle_scene.gd`（球数 / 胜负 / 捕捉入口）、`scripts/battle/battle_grid_controller.gd`（捕捉按钮联动 + 选中可捕目标判定）、`scripts/battle/action_bar.gd`（[捕捉] 按钮 + 信号）。
- 数据：新增 `data/capture_config.json`；改 `data/stages/debug_battle.json` 加 `player.balls`；`data/units/M01.json` 等已有 `capture` 字段可直接复用。
- 自动加载：`SaveManager` 与 `MetaManager` 改为「启动时 load → autoload 内存」；新增 `BestiaryManager`、`PartyManager` 作为 autoload。
- 测试：新增 `test_capture_system.gd`、`test_bestiary_manager.gd`、`test_party_manager.gd`、`test_save_manager.gd`；现有 `test_battle_setup.gd` 增 1 个用例覆盖「击倒野怪不移除」。
- 场景：`scenes/battle/ui/action_bar.tscn` 加 `[捕捉]` 按钮；新增 `scenes/battle/ui/capture_prompt.tscn`。
- 非目标：本章不做战役选关 / 主菜单 / 编队出战 UI / 商店 / 球的肉鸽经济（统一推到第 6/7/8 章）；图鉴 UI 面板也不做（仅数据 + 持久化），第 6 章主菜单一并接入。
