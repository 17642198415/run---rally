## Context

- 第 6 章已交付战役流程：主菜单 → 选关 → 编队 → 战斗 → 图鉴，逻辑与 Save 稳定，20 个 headless 单测 GREEN。
- 轮次 A（`polish-battle-visuals-tier1`）已建立 `ArtLoader` autoload、`assets/art/art_manifest.json`、战斗 HUD 卡片 StyleBox（圆角 14、`bg_color = Color(0.13, 0.15, 0.20, 0.92)`、阴影、蓝/金边框变体）。
- 四页菜单当前结构：全屏 `ColorRect(0.09, 0.11, 0.15)` 背景 + 居中 `Panel` + `VBox` + 默认 `Button`/`Label`；`bestiary_view.gd` 与 `party_setup.gd` 在 `_refresh()` 里动态创建子节点，样式分散在各脚本。
- 第 7 章肉鸽将复用选关/编队类卡片布局；本轮完成 Tier 1 菜单统一，避免肉鸽 UI 与战斗页两套风格。

约束：Godot 4.6 + GDScript；不引入全局 `Theme.tres`；不修改 Autoload 业务接口；Windows UTF-8。

## Goals / Non-Goals

**Goals:**

- 四页菜单视觉与战斗 HUD 卡片同色板、同圆角/阴影规范。
- 选关页 3 张关卡卡片：`locked` / `unlocked` / `cleared` 状态一眼可辨。
- 编队页 HERO 固定行突出；备用栏每条 reserve 可选卡片行含单位头像占位。
- 图鉴页 8 格网格：头像 + 发现/捕获/未发现状态徽章。
- 共享 `MenuStyle` 静态工厂，避免四页重复 StyleBox 代码。
- 复用 `ArtLoader.get_ui("panel_bg")` 与 `ArtLoader.get_unit(template_id)`；缺资源时占位回退。
- README 手动验收章节；现有 20 单测保持 PASS。

**Non-Goals:**

- 不改战役解锁、编队上限、图鉴数据逻辑。
- 不引入 Kenney 真实素材（用户后续自行替换）。
- 不做全局 `Theme`、粒子、动画转场、音效。
- 不美化战斗页（已在轮次 A 完成）。
- 不新增 headless 单测（可选 smoke 非阻塞）。

## Decisions

### D1：共享 MenuStyle 模块 vs 每页内联 StyleBox

- **决定**：新增 `scripts/ui/menu_style.gd`（`class_name MenuStyle`），提供 `make_panel_style()`、`make_card_style(variant)`、`make_button_styles()`、`apply_page_shell(control)`。
- **理由**：战斗页已在 `battle_grid_controller._apply_card_styles` 有类似逻辑；抽成共享模块后四页与后续肉鸽 UI 一致，改色只改一处。
- **替代**：复制粘贴 StyleBox 到四个脚本。**否决**：维护成本高，易漂移。

### D2：选关卡片用 PanelContainer + Button 覆盖 vs 纯 Button

- **决定**：每个关卡为 `PanelContainer`（卡片底）+ 内部 `VBox`（标题/副标题/状态徽章）+ 透明 `Button` 覆盖整卡（或 `gui_input` on Panel）；`disabled` 时整卡灰度 + 不可点击。
- **理由**：纯 `Button.text = "名字 · 状态"` 无法做分层排版与状态色块；卡片结构便于第 7 章肉鸽节点复用。
- **替代**：继续用 3 个 `Button` 只改 `modulate`。**否决**：状态辨识度不足。

### D3：关卡状态配色

- **决定**（与 Demo 计划 §6.5.3 对齐）：

| 状态 | 边框色 | 底色 tint | 徽章文案 |
|------|--------|-----------|----------|
| `locked` | 灰 `#555960` | 更暗 0.85 modulate | 未解锁 |
| `unlocked` | 蓝 `#6190D1`（与战斗 HUD 一致） | 默认卡片色 | 可挑战 |
| `cleared` | 金 `#D9A64D` | 略亮 | 已通关 |

- **理由**：与战斗页阵营/目标卡片色系统一。

### D4：编队页 HERO 行与 reserve 行动态构建

- **决定**：`party_setup.gd` 的 `_refresh()` 改为构建 `PanelContainer` 行：HERO 行固定金色左边框 + ★ 图标；reserve 行 = `HBoxContainer(CheckBox + TextureRect 32×32 头像 + Label)`。
- **理由**：现有逻辑已是动态 `CheckBox`；只换容器与样式，不改选择上限与 `deploy_list` 结构。
- **替代**：在 `.tscn` 写死 reserve 行。**否决**：reserve 数量动态。

### D5：图鉴格结构

- **决定**：`bestiary_view.gd` 每格 `PanelContainer`（min 120×100）含：`TextureRect` 48×48 居中（`ArtLoader.get_unit`，未发现时用灰色 `?` 占位）、`Label` 名称/状态、`ColorRect` 角标（捕获=绿、发现=黄、未知=灰）。
- **理由**：对齐战斗单位头像管线；只读页无需交互复杂化。

### D6：panel_bg 9-slice

- **决定**：若 `ArtLoader.get_ui("panel_bg")` 返回有效纹理，主面板 `Panel` 用 `StyleBoxTexture`（9-slice margin 4）；否则回退 `StyleBoxFlat`（与 D1 默认一致）。
- **理由**：manifest 已有 `panel_bg` 占位定义；有真素材时可热替换，无则不影响开发。
- **替代**：只用 StyleBoxFlat。**可接受降级**：实现时优先 Flat，Texture 作为增强。

### D7：脚本 vs 场景职责

- **决定**：`.tscn` 保留节点树骨架（Background、RootPanel、VBox）；样式在脚本 `_ready()` 调 `MenuStyle.apply_page_shell(self)`；动态内容（关卡卡、图鉴格、reserve 行）仍在各 `*_refresh()` 构建。
- **理由**：与现有 `bestiary_view` / `party_setup` 动态模式一致，减少 `.tscn` 大改冲突。

## Risks / Trade-offs

- [StyleBox 代码与战斗页 drift] → `MenuStyle` 常量注释引用 `battle_grid_controller._apply_card_styles` 数值；改战斗页时同步改 MenuStyle。
- [动态节点路径变更破坏 @onready] → 尽量保留 `$Panel/VBox/...` 顶层路径；仅替换子内容容器。
- [TextureRect 头像在 headless 无影响] → 单测不加载菜单场景；回归只跑现有 20 测试。
- [选关卡片 Button 覆盖点击区域] → 用 `mouse_filter = MOUSE_FILTER_STOP` 与 `disabled` 同步 `locked` 状态。
- [不引入 Theme 导致按钮样式仍要逐页 apply] → `MenuStyle.make_button_styles()` 一次 apply 到页面所有 `Button`。

## Migration Plan

1. 实现 `MenuStyle` +（可选）manifest `ui` 扩展。
2. 主菜单 → 选关 → 编队 → 图鉴顺序改场景/脚本（每页可独立提交）。
3. README 手动验收 + 全量 `tests/run_all_tests.ps1`。
4. 回滚：每页独立 revert；`MenuStyle` 可保留不影响逻辑。

## Open Questions

- 是否在主菜单背景加 subtle 纹理（`ArtLoader.get_ui("menu_bg")`）？建议**不做**，Tier 1 保持纯色背景 + 居中卡片，降低成本。
- 图鉴格是否显示 `template_id`（M01）？建议**保留**小字灰色，便于调试，与现逻辑一致。
