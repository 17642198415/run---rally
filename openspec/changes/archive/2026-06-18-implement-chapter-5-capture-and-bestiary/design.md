## Context

第 1~4 章已建好「数据 → 网格 → 战斗 → 回合」的骨架，但只是「打」，没有「捉」。MVP §4.5~4.6 的捕捉是 Demo 玩法核心，也是唯一持久化文件 `user://save_meta.json` 的第一个真实写入方。

当前相关位置：

- `scripts/autoload/save_manager.gd`：已有 `load_meta` / `save_meta`，未接入任何业务模块。
- `scripts/battle/battle_unit.gd`：`hp` 通过 `take_damage` 直接归 0，由 `BattleController._after_action` 从 `units` 列表 + `Grid.set_occupant(null)` 移除。
- `scripts/battle/battle_controller.gd`：`check_victory` 只看 `hp > 0`。
- `data/units/Mxx.json`：已有 `base_capture_rate` 字段。
- `data/stages/debug_battle.json`：已有 `player_ball_count` 字段。

约束：

- Godot 4.6 + GDScript；不引入第三方依赖。
- Windows + PowerShell；测试走 `tests/run_all_tests.ps1`。
- 单一持久化文件 `user://save_meta.json`，不允许新增独立 save 文件。
- 现有第 4 章 14 个测试必须保持 PASS。

## Goals / Non-Goals

**Goals:**

- 把「击败野生敌人」从「直接消失」改成「击倒可捕」中间态，并提供成功/失败的捕捉闭环。
- 把图鉴 / 备用栏 / 捕捉球 / 战役 / Meta 落到统一的 `user://save_meta.json`，且重启后能正确回灌。
- 提供四档显示概率、清晰可测的 `CaptureSystem`，以及覆盖核心分支的 headless 单测。
- 拓展 `ActionBar` 与 `BattleScene` 暴露 `[捕捉]`，对玩家动作链路保持一致（捕捉视为一次完整行动，等同 attack/skill 后切换 `active_unit`）。

**Non-Goals:**

- 战役选关、主菜单、`party_setup` UI（第 6 章）。
- 肉鸽 reserve / Run 状态（第 7 章）。
- 球的商店 / 三选一经济（第 7~8 章）。
- 完整图鉴页面 UI（第 6 章主菜单一并做）。
- 已捕单位上场出战（保持 HERO 唯一玩家可部署，本章不动 deploy）。

## Decisions

### D1：野生单位 HP≤0 进入 `downed_capturable`，不立即移除

**选择**：`BattleUnit` 增加 `downed_capturable: bool` 与 `is_wild: bool`（`is_player == false` 默认即野生；BOSS 通过模板 `tags: ["boss"]` 排除）。`BattleController.execute_attack` / `execute_skill` 完成伤害后，若目标 `is_wild and hp <= 0`，置 `downed_capturable = true`，**保留** grid 占格，不参与 AI 队列、不参与 `check_victory` 的「存活敌方」判定。`is_alive_for_battle()` 返回 `hp > 0 and not downed_capturable`。

**备选**：直接死亡 + 在原位生成「掉落物」节点。被否决——多一类对象，破坏现有 `units` 列表统一性，且与图鉴/捕捉的语义解耦更复杂。

**理由**：保持 `units` 单一来源，最少侵入；占格在战斗结束前只是视觉/规则细节，不影响后续章节。

### D2：捕捉视为一次「行动」，与攻击同级

**选择**：`ActionBar` 新增 `[捕捉]` 按钮，`BattleGridController` 在玩家选中时计算「相邻所有 `downed_capturable` 野单位」，若 ≥1 则启用按钮。点击进入捕捉模式（高亮可捕格），目标确认后弹 `CapturePrompt`，`[确认]` 调 `CaptureSystem.attempt`，无论成败都 `mark_unit_acted` + 推进队列。

**备选**：捕捉作为「自由动作」、不消耗行动。被否决——破坏第 4 章「一次行动后自动切换」的不变量，AI/回合框架要打补丁。

**理由**：与第 4 章既有动作链路完全一致，回合机不需要任何改动。

### D3：成功率公式（与 MVP §4.5 对齐，简化为可单测）

```
hp_factor    = 1.0 - clamp(unit.hp / unit.max_hp, 0.0, 1.0)   # downed 时 hp=0 → 1.0
base         = unit.template.base_capture_rate                # 0.10 ~ 0.55
event_bonus  = capture_config.event_bonus (默认 0.0)
rate         = clamp(base * (0.5 + 0.5 * hp_factor) + event_bonus, 0.05, 0.95)
```

档位：`>=0.5 高 / >=0.25 中 / >=0.12 低 / else 极低`。

**理由**：在 `downed_capturable` 状态下 `hp=0` 必然 `hp_factor=1`，单测可以稳定断言「档位匹配 base_capture_rate」。第 7 章商店增益事件可注入 `event_bonus`，无需改公式。

### D4：捕捉球数据来源 = stage JSON

`stage.player.balls`（不存在则默认 3）在 `BattleScene._begin_stage()` 写入 `GameState.current_battle.balls_remaining`。`HudLabel` 显示「球: N」。第 6 章战役复用，第 7 章肉鸽改为从 `RunState.balls` 读，接口不变。

### D5：Save 结构与回灌时机

`user://save_meta.json` 唯一字段（本章定型）：

```json
{
  "bestiary": { "M01": {"discovered": true, "caught": true}, ... },
  "party":    { "reserve": [{"unit_id": "P_M01_001", "template_id": "M01", "hp": 18, "max_hp": 18, "skill_id": "S_FIRE_CLAW"}, ...] },
  "stats":    { "captures_total": 3, "battles_won": 1 },
  "campaign": { },
  "meta":     { "unlocked": [] }
}
```

启动时机：`autoload/boot.gd` 类入口 → `SaveManager.load_meta()` → 灌进 `BestiaryManager` / `PartyManager` / `MetaManager`。本章不做 `boot.gd`，改在 `DataLoader.load_all()` 之后由各 manager 的 `_ready()` 自取。

写入时机：捕捉成功 / 战斗胜利 / 关闭场景 三处显式 `SaveManager.save_meta(...)`。本章先实现「捕捉成功 / 战斗结束」两处，关闭事件留到第 6 章主菜单。

### D6：discovered 写入时机

野生敌人在 `_begin_stage()` 完成 spawn 后立即把所有 `is_wild` 单位的 `template_id` 写入 `BestiaryManager.mark_discovered()`，而不是「玩家看见」。理由：本章无视野系统，地图全显，统一规则简单可测。

### D7：BattleEnd 仍然「敌方全部存活=0 即胜」

`check_victory` 只看 `is_alive_for_battle()`。downed 单位即使留在格上，胜负判定上视为「死亡」。这条同时是 `chapter-3` / `chapter-4` 的 MODIFIED 点，需要在两个 delta spec 里写明。

## Risks / Trade-offs

- **R1**：野生 BOSS 也可被捕（如未来第 7 章 BOSS 战）。→ 通过模板 `tags: ["boss"]` 在 `is_wild_capturable()` 排除，本章 `DEBUG_01` 没有 boss，不存在该路径，但接口预留。
- **R2**：downed 单位占格阻塞玩家移动 → 玩家可绕路或捕掉。视为玩法特性，不缓解。
- **R3**：`SaveManager` 写入失败（磁盘只读） → 现有实现已 `push_error` + 返回 `false`，本章在调用点检查并 HUD 提示「存档失败」，不阻塞战斗。
- **R4**：`BestiaryManager` / `PartyManager` 作为新 autoload，可能与未来 `boot.gd` 集中加载冲突 → 用 `_ready()` 内部 guard：若已被外部注入则跳过自取。
- **R5**：随机 roll 让单测不稳 → `CaptureSystem.attempt(rng: RandomNumberGenerator)` 注入 RNG，单测传定 seed RNG 复现。

## Migration Plan

1. 先加 `BattleUnit.downed_capturable` 字段并改 `BattleController._after_action`，跑现有 14 个测试，确保不退化。
2. 加 `CaptureSystem` + 单测（不接 UI）。
3. 加 `BestiaryManager` / `PartyManager` / `SaveManager` 写入路径 + 单测，使用 `user://test_save_meta.json` 临时路径或 `SaveManager.SAVE_PATH` 在测试 `setup` 里改写。
4. `ActionBar` + `CapturePrompt` UI 接入，手动验收。
5. README 增加「第 5 章手动验收」段，更新 `tests/run_all_tests.ps1` 列表。

回滚：以上每步独立可回退；`BattleUnit.downed_capturable` 默认 `false`，关闭捕捉只需 `ActionBar` 隐藏按钮即可保留旧行为。

## Open Questions

- 备用栏上限：MVP §A.4 写「肉鸽 8 / 战役 12」。本章先按「逻辑常量 12」（`PartyManager.MAX_RESERVE = 12`），第 7 章引入 `RunState` 时再覆盖为 8。
- 捕捉成功后的 `unit_id` 命名：用 `"P_%s_%03d" % [template_id, party_count]` 保证唯一，第 6 章编队读取无歧义。
