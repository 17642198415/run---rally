## Why

Tier 1 战斗页美化（`polish-battle-visuals-tier1`）已完成，但主菜单、选关、编队、图鉴四页仍是第 6 章功能版的默认 `Panel` + 纯文字按钮，视觉风格与战斗 HUD 卡片脱节，M2 演示与第 7 章肉鸽 UI 复用都受影响。本轮在不改战役逻辑、Save 与导航行为的前提下，把四页菜单统一到战斗页同色板与卡片规范，完成 Demo 计划第 6.5 章轮次 B。

## What Changes

- 新增共享 UI 样式工具（`scripts/ui/menu_style.gd` 或等价模块）：复用战斗 HUD 的圆角 14、半透明深色背景、阴影、按钮 StyleBox；可选通过 `ArtLoader.get_ui("panel_bg")` 做 9-slice 背景纹理。
- `main_menu.tscn`：标题区 + 四按钮卡片化；禁用项（开始征途/选项）视觉灰化；Hint 区样式统一。
- `stage_select.tscn`：3 张关卡卡片替代纯 `Button` 列表；按 `locked` / `unlocked` / `cleared` 显示不同边框/底色/状态徽章；保留点击进入 `party_setup` 与返回主菜单逻辑。
- `party_setup.tscn`：HERO 固定行用高亮卡片；备用栏每条 reserve 用可选卡片行（CheckBox + 单位头像占位）；底部确认/返回按钮套用统一 StyleBox。
- `bestiary_view.tscn`：8 格图鉴网格卡片化；每格显示单位头像（`ArtLoader.get_unit`）、发现/捕获状态图标或文字徽章；未发现格显示 `?` 占位。
- README 增补「Tier 1 菜单页美化 手动验收」章节（F5 走主菜单 → 战役 → 选关 → 编队 → 图鉴全流程）。
- 不改 `CampaignManager` / `PartyManager` / `BestiaryManager` 业务逻辑；不引入全局 `Theme` 资源；不新增 headless 单测（纯视觉变更，现有 20 个单测保持 GREEN）。

## Capabilities

### New Capabilities

- `menu-visual-style`: 四页菜单（主菜单、选关、编队、图鉴）的 Tier 1 视觉规范：共享卡片 StyleBox、关卡状态色、图鉴格状态表现、ArtLoader UI 纹理复用。

### Modified Capabilities

- 无（本轮仅视觉层，不改变 `chapter-6-campaign-and-menu` 等功能 spec 的行为需求）。

## Impact

- **代码**：`scripts/main_menu.gd`、`scripts/campaign/stage_select.gd`、`scripts/campaign/party_setup.gd`、`scripts/campaign/bestiary_view.gd`；新增 `scripts/ui/menu_style.gd`（共享样式工厂）。
- **场景**：`scenes/main_menu.tscn`、`scenes/campaign/stage_select.tscn`、`scenes/campaign/party_setup.tscn`、`scenes/campaign/bestiary_view.tscn`。
- **资源**：可选扩展 `assets/art/art_manifest.json` 的 `ui` 段（如 `panel_bg`、`stage_locked` 等）；缺文件时 `ArtLoader` 占位回退，与战斗页一致。
- **测试**：现有 20 个单测不变；可选 smoke 断言 `MenuStyle.make_card_style()` 非空（非必须）。
- **数据/Save/关卡**：不变。
