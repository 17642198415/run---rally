## Context

当前状态：

- `main_menu.tscn` 为第 1 章自检页，无导航
- `battle_scene.gd` 通过 `@export stage_id = "DEBUG_01"` 直进调试关；`deploy_phase` 仅读 stage `player_units`（目前只有 HERO）
- 第 5 章已交付 `BestiaryManager`、`PartyManager`、`SaveManager`（`bestiary` / `party.reserve` / `campaign` 占位）
- `GameState` 已有 `GameMode.CAMPAIGN` 枚举但未使用
- `enemy_ai.gd` 已支持 `ai_profile: boss_default`（HP<50% 放技能）
- `S_BERSERK` 技能 JSON 已存在；`BOSS_MERC` 单位尚未落盘

约束：Godot 4.6 + GDScript；单一存档 `user://save_meta.json`；美术色块占位；第 7 章肉鸽入口仅占位。

## Goals / Non-Goals

**Goals:**

- F5 从主菜单进入战役 → 选关 → 编队 → 部署战斗 → 胜/败回选关
- 新档仅 `stage_01` 可进；通关顺序解锁 `stage_02`、`stage_03`
- 编队可选 `PartyManager.reserve` 中已捕获单位（最多 3 宠 + HERO）
- 图鉴页展示 M01~M08 发现/完成状态（读 `BestiaryManager`）
- 战役进度持久化；失败不丢图鉴与备用栏
- 达成 M2：给人看的 3 关战役 Demo

**Non-Goals:**

- 肉鸽「开始征途」实装（灰显 + 提示「第 7 章启用」）
- Meta 解锁页、选项菜单实质功能
- 战役编队与肉鸽共用以外的 Run 经济
- 新 Meta 项或三选一奖励

## Decisions

### D1：场景流用 `change_scene_to_packed` 链式导航

```
MainMenu → StageSelect → PartySetup → Battle → (胜/败) → StageSelect
MainMenu → BestiaryView → MainMenu
```

`GameState` 在 `PartySetup` 确认时写入 `battle_context.deploy_list`（`Array[Dictionary]`，每项 `{template_id, unit_id?, from_reserve?}`），`BattleScene` 在 `_begin_stage` 将其转为 `player_units` 供 `DeployPhase`。

**理由**：与 Godot 场景树习惯一致，比单场景 FSM 更易维护；各屏独立验收。

### D2：Campaign 进度存在 `save_meta.campaign`

```json
"campaign": {
  "stage_01": "cleared",
  "stage_02": "unlocked",
  "stage_03": "locked"
}
```

状态枚举：`locked` | `unlocked` | `cleared`。新档默认：`stage_01=unlocked`，其余 `locked`。通关 `stage_N` 将自身标 `cleared`，若 stage 有 `unlock_next` 则标 `unlocked`。

`CampaignManager` 为 autoload，启动时 `from_dict(SaveManager.load_meta().campaign)`，变更后 `save_meta` 整包写回。

### D3：Stage JSON 键名与 DEBUG_01 对齐

使用 `player_units` / `enemy_units`（不用 demo 草稿里的 `enemies`）。战役关 `player` 块：

```json
"player": { "deploy_max": 4, "balls": 3, "party_source": "campaign_setup" }
```

`party_source: campaign_setup` 表示部署模板来自编队而非 stage 内写死列表；`debug_battle` 仍用内联 `player_units: [{template: HERO}]`。

### D4：编队规则

- HERO 固定出战，不可取消
- 从 `PartyManager.reserve` 勾选 0~3 只（UI 显示 checkbox）
- 确认后生成 `deploy_list`：HERO 在 index 0，其余按勾选顺序
- 战役失败：不修改 `reserve`（阵亡单位仍保留在备用栏，简化 Demo）
- 战役胜利：捕捉成功仍走第 5 章逻辑追加 `reserve`

### D5：Battle 结束回流

`battle_scene.gd` 在 `BATTLE_END`：

- 若 `GameState.current_mode == CAMPAIGN`：根据胜负更新 campaign（仅胜利）、`save_meta`，延迟 1.5s 或点按钮后 `change_scene_to_file("res://scenes/campaign/stage_select.tscn")`
- 若 `DEBUG` 直跑（`GameMode.NONE`）：保持现有 HUD 胜负文案，不跳场景

### D6：三关地图与敌人（对齐 Demo §6.6）

| Stage ID | 文件 | 地图 | 敌人概要 |
|----------|------|------|----------|
| stage_01 | stage_01_border_plain.json | T_PLAIN | 2×M01 + 1×M02 |
| stage_02 | stage_02_wet_edge.json | T_WET | M03 + M04 + M06 + 增援 M01（`spawn_round` 可简化为开局全刷） |
| stage_03 | stage_03_old_fort_boss.json | T_FORT | BOSS_MERC + 2 小怪 + M08 低概率位（M08 作普通敌模板，capturable） |

地图 10×10，部署区左右分列，地形比 `test_grid` 简单可辨（湿地有水、要塞有墙）。

`BOSS_MERC`：`tags: ["boss"]`，`capturable: false`（或靠 boss tag 不可捕），`ai_profile: boss_default`。

### D7：图鉴 UI

`bestiary_view.tscn`：8 格 `GridContainer`，每格显示 id、名称（已发现）或 `?`（未发现）、角标「发现/完成」。只读，不写档。

### D8：测试策略

- `test_campaign_manager.gd`：新档解锁、通关解锁下一关、merge 缺字段
- `test_stage_loader.gd`：3 个战役关 + 3 地图模板可加载
- `test_deploy_phase.gd`：多 `player_units` 模板（HERO + M01）部署确认
- 不新增 UI 自动化；M2 靠 README 手动剧本

## Risks / Trade-offs

- **R1**：`battle.tscn` 直跑 F6 与战役入口行为分叉 → `GameState.current_mode` 显式分支，单测仍用 DEBUG_01 + NONE
- **R2**：stage_02 增援机制复杂 → 本章简化为开局全敌人 spawn，不做回合增援
- **R3**：编队单位 HP 是否继承 reserve → 战役开战用 `max_hp` 满血简化；reserve 存盘 HP 字段保留供第 7 章
- **R4**：主菜单重写破坏第 1 章自检 → README 改为「数据层测试见单元测试」；可选保留小字链接或控制台仍打印 DataLoader

## Migration Plan

1. `CampaignManager` + 单测 + Save 字段
2. 3 地图 + 3 stage + BOSS_MERC 数据
3. `GameState.start_campaign_battle` + `deploy_phase` / `battle_scene` 战役分支
4. `stage_select` → `party_setup` → battle 回流
5. `main_menu` + `bestiary_view`
6. README M2 验收 + 全量测试

## Open Questions

- `stage_select` 是否显示每关最佳成绩：本章不做，仅 locked/unlocked/cleared
- 选项按钮：弹 Label「敬请期待」即可
