## Why

战斗页当前是色块网格 + 汉字方块单位 + DEBUG 风格 HUD，视觉粗糙不利于演示与体验验收。Tier 1 在不动战斗逻辑的前提下，对战斗页做一次"视觉打磨"，让画面跨入"开发期可演示"水平，同时建立后续美术资源接入的目录与命名约定。

## What Changes

- 战斗格子改为 `TileMap + TileSet`，地形（草/林/水/墙/部署区）通过纹理化的 tile 呈现，保留现有 `TerrainTypes`/`Grid` 的逻辑接口不变。
- 战斗单位改为 `Sprite2D` 立绘 + 圆形头像底框 + 阵营色描边 + HP 进度条，保留现有 `BattleUnitView` 接口（汉字字符作为占位符回退方案）。
- HUD 重排：左上 `回合状态卡片`、右上 `球数+目标卡片`、底部 `ActionBar 卡片`；统一深色半透明、圆角、阴影、状态色。
- 高亮层（移动蓝/攻击红/技能紫/捕捉青/选中金）改为带描边和呼吸动画的样式。
- 动作栏按钮图标化（移动/攻击/技能/捕捉/待机/结束回合 各配一个 16x16 图标）。
- 引入"美术资源占位符"规范：`assets/art/{tiles,units,ui,icons}/` 目录、命名约定、`art_manifest.json` 索引；首版用代码生成的占位图（圆角色块 + emoji 同色描边），后续可无缝替换为 Kenney 等真实素材。
- 不改任何战斗规则、Save 字段、关卡数据；不引入 3D；不改菜单/选关/编队/图鉴页（留给 Tier 1 第二轮 Change）。

## Capabilities

### New Capabilities

- `battle-visual-style`: 战斗页视觉规范（地形 TileSet、单位 Sprite、HUD 卡片、状态色、描边/呼吸动画）。
- `art-asset-pipeline`: 美术资源目录、命名、占位符回退、`art_manifest.json` 索引规则。

### Modified Capabilities

- 无（Tier 1 仅做视觉，不改既有 spec 的需求行为）。

## Impact

- **代码**：
  - `scripts/battle/battle_view.gd`、`battle_grid_controller.gd`、`battle_unit_view.gd`、`action_bar.gd`、`capture_prompt.gd`、`hud_label.gd`、`turn_banner.gd`、`balls_label.gd`、`faction_label.gd`。
  - 新增 `scripts/art/art_loader.gd`（解析 `art_manifest.json`，提供占位回退）。
- **场景**：
  - `scenes/battle/battle.tscn`、`scenes/battle/ui/*.tscn` 重排版。
- **资源**：
  - 新增 `assets/art/tiles/*.png`（首版为代码生成的占位 32x32 PNG）、`assets/art/units/*.png`、`assets/art/icons/*.png`、`assets/art/ui/*.png`。
  - 新增 `assets/art/art_manifest.json`。
- **测试**：
  - 现有 19 个单测保持 GREEN（不动逻辑）。
  - 新增 `tests/unit/test_art_loader.gd`：占位回退、manifest 解析、命名校验。
- **数据/Save/关卡**：不变。
