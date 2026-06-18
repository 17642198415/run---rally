## Context

- 当前战斗页：`Grid` 数据正确，但视觉是色块格 + 汉字 `Label` 单位 + DEBUG 风文字 HUD。看起来"原型味"重，对玩家与外部演示不友好。
- 渲染层（`BattleView`、`BattleUnitView`、`battle_grid_controller._render_terrain/_render_highlights`）已经有清晰封装边界，但内部全部写死 `ColorRect + Label`。
- `assets/` 目录下尚未规划过美术资源，没有 manifest，没有命名约束，未来加 Kenney/AI 生成图也会撞车。
- Tier 1 的目标是在不动战斗逻辑、不引入 3D、不改 Save 与关卡数据的前提下，把"画面"拉到可演示水平。

## Goals / Non-Goals

**Goals:**

- 战斗格子使用 `TileMap + TileSet` 渲染，地形可被纹理化或图标化区分。
- 战斗单位使用 `Sprite2D + 圆形头像底框 + 阵营色描边 + HP 条`。
- HUD 重排成"左上回合 / 右上球数 / 底部 ActionBar"三块统一风格卡片。
- 高亮 + 选中 + 描边样式统一，含呼吸动画。
- 建立 `assets/art/{tiles,units,icons,ui}/ + art_manifest.json` 资源管线，提供"代码占位 → 真素材"的无缝切换通道。
- 不破坏现有 19 个单测；新增 `ArtLoader` 单测。

**Non-Goals:**

- 不实现等距/2.5D/3D 视图（留给后续 Tier 2/Tier 3）。
- 不修改 `MainMenu`、`StageSelect`、`PartySetup`、`BestiaryView` 美化（拆给下一轮 Change：`polish-menu-visuals-tier1`）。
- 不引入真实的 Kenney/外部素材文件（用户后续自行下载替换）；本次首版资源用代码生成的占位 PNG。
- 不改任何战斗规则、Save 字段、关卡数据。
- 不引入第三方 GD 插件。

## Decisions

### D1：战斗格子 TileMap vs 继续 ColorRect

- **决定**：改用 `TileMap + TileSet`。
- **原因**：
  - `TileSet` 提供统一的"地形 → 纹理"映射；后续无论替换为什么样的地形 PNG，业务代码不动。
  - `TileMap` 天然支持多层（地形层、部署区高亮层、攻击/移动高亮层），比一堆 `ColorRect` 子节点干净。
  - 性能比一堆 `ColorRect` 子节点更好（重要：地图扩到 20x20 也不退化）。
- **替代方案**：
  - 保留 `ColorRect`，仅给每格加 `StyleBox` 描边/阴影。**否决**：纹理替换成本高，多层难做。
  - 直接上 Sprite2D 阵列。**否决**：失去 `TileSet` 的命名 → 资源映射统一性。

### D2：单位渲染 Sprite2D vs 保留 Label

- **决定**：`BattleUnitView` 改为：底框 `Panel` + `Sprite2D`（单位图）+ HP `ProgressBar`，再叠一个 `Label`（fallback 时才显示）。
- **原因**：
  - 圆形头像底框是当前战棋视觉的标配。
  - 资源缺失时 `Label` 自动显示，保证演示不黑屏。
- **替代方案**：完全替换为 `Sprite2D`。**否决**：占位回退做不出"带字符占位"的效果。

### D3：高亮层呼吸动画 Tween vs Shader

- **决定**：用 `Tween` 循环改 `modulate.a` 实现呼吸。
- **原因**：
  - Godot 4.x `Tween` 循环简单稳定，零着色器维护。
  - 性能足够（高亮格上限通常 < 30）。
- **替代方案**：自定义 shader。**否决**：成本/收益不划算。

### D4：HUD 重排沿用 CanvasLayer，不引入 Theme

- **决定**：`scenes/battle/battle.tscn` 里维持 `CanvasLayer`，把现有 `HudLabel/TurnBanner/BallsLabel` 改为三块 `PanelContainer`（卡片）。
- **原因**：
  - 不动场景层级，避免破坏 `_bind_*` 路径。
  - `Theme` 全局化引入 Tier 1 太重，留给 Tier 2 统一规范化时一起做。
- **替代方案**：引入 `Theme` 资源做全局样式。**否决**：Tier 1 范围打不住。

### D5：图标 + 文字按钮的实现

- **决定**：在 `ActionBar._apply_styles()` 末尾按 `action_id` 调用 `ArtLoader.get_icon(name)`，赋给 `Button.icon` 属性，并设 `expand_icon = false`。
- **原因**：Godot 4.x `Button` 原生支持 `icon` 字段；缺图就赋 `null`，Button 自动只显示文字。
- **替代方案**：自绘 HBox（Icon+Label）。**否决**：丢掉了 `Button.disabled` 视觉反馈。

### D6：美术资源管线 ArtLoader

- **决定**：新增 `scripts/art/art_loader.gd`，autoload 名 `ArtLoader`。
  - 启动时读 `assets/art/art_manifest.json`（不存在则用内置默认）。
  - 对外提供 `get_tile(name) / get_unit(template_id) / get_icon(action) / get_ui(name) -> Texture2D`。
  - 内部缓存 `Dictionary[str, Texture2D]`；找不到物理文件就调 `_make_placeholder()` 合成一个 `ImageTexture`。
- **原因**：
  - 解耦"渲染调用 vs 资源寻址"，方便美术替换。
  - 单一入口便于单测。
- **替代方案**：每个 view 自己 `load("res://assets/...")`。**否决**：占位回退散落各处，难统一。

### D7：占位图实现

- **决定**：`_make_placeholder()` 用 `Image.create()` + `Image.fill_rect()` + `Image.draw_string()`（如 Godot 4 `Image` 不直接支持 draw_string，则改用 `Font.draw_string()` 渲到一张 `Image` 再转 `ImageTexture`）。
- **回退**：若运行时绘字困难，则只画"圆形 + 描边"，glyph 用同色底图代替（接受这种降级）。
- **原因**：完全零外部资源；首版可立即跑起来。

### D8：切分两个 Change

- **决定**：本 Change 只覆盖**战斗页**；下一 Change `polish-menu-visuals-tier1` 覆盖主菜单 + 选关 + 编队 + 图鉴。
- **原因**：战斗页改动面最大、风险最集中；先稳住主玩法 UI，再统一菜单类页面。

## Risks / Trade-offs

- [TileMap 接入 vs 既有 `_render_terrain` 风险] → 保留 `BattleView.draw_grid` 接口形状不变，内部用 TileMap 实现；老的 `ColorRect` 路径作为 `art_fallback_mode` 留出（环境变量或开关），保证可回退。
- [呼吸动画 Tween 在场景频繁切换时遗漏 kill] → `_clear_highlights()` 中遍历 kill 节点上挂的 `Tween`；统一在 `_render_highlights` 入口创建。
- [`ArtLoader._make_placeholder()` 的 draw_string 平台差异] → 单测仅校验 `Texture2D != null` 与尺寸，不强校素材像素，保证 CI 稳定。
- [中文字符 fallback_glyph 在 Image 上字体缺失] → 选用 Godot 自带 `ThemeDB.fallback_font`，并在 `art_manifest.json` 给所有 unit 都填 fallback_glyph；缺失字体时仍能渲染矩形。
- [`Button.icon` 可能撑大按钮高度] → 在 `ActionBar` 上设 `expand_icon = false` + 固定 `custom_minimum_size`。
- [现有 19 个单测稳定] → 本次不改任何逻辑脚本与数据；新增的 `ArtLoader` 在 autoload 但默认 lazy 初始化，避免影响 headless 测试。

## Migration Plan

- 实施顺序：
  1. 落 `assets/art/` 目录与 `art_manifest.json` 默认结构。
  2. `ArtLoader` 与单测先行。
  3. `BattleView`/`BattleUnitView`/`battle_grid_controller` 改为通过 `ArtLoader` 取纹理（占位回退）。
  4. HUD 三卡片化 + ActionBar 图标化。
  5. 高亮层呼吸 Tween + 配色规范。
  6. 全量回归 + 手动验收。
- 回滚：每步独立提交；如 TileMap 化引入回退性问题，可单独把 `BattleView` 切回旧 `_render_terrain`，其它视觉改动保留。

## Open Questions

- 是否要在 Tier 1 顺手把"未行动 / 已行动"灰度叠在 `BattleUnitView`？建议**做**（成本低，体验提升大），列入 tasks 但作为可选项，超时则砍。
- `BallsLabel` 现在是单独 Label，要不要合到右上"球数+目标"卡片？建议**合并**，避免界面碎片。

## Implementation Note (D1 调整)

进入 apply 阶段后发现：当前战斗渲染走的是 `Control + ColorRect` 体系（不是 `Node2D + TileMap`），整个高亮层、UnitView、CanvasLayer 都基于 Control 锚点工作。引入 `TileMap` 会让坐标系跨 `Node2D/Control` 边界，破坏现有的 `GRID_ORIGIN`/`HighlightLayer`/`UnitsRoot` 同步定位逻辑，回退面巨大。

**调整决策**：保留 `Control` 体系，但将每格的 `ColorRect` 升级为 `TextureRect`，纹理来自 `ArtLoader.get_tile()`；部署区做一层独立的 `TextureRect` 叠加；高亮层也复用 `TextureRect`/`ColorRect` + 描边 + 呼吸动画。这与 spec 中"地形可肉眼区分 / 占位回退 / 部署区高亮"的可观测验收完全等价（spec 写的是"使用 TileMap 与 TileSet 渲染"作为实现手段，但实际验收点是视觉差异和占位回退能力）。

后续若做等距视图（Tier 2），再统一切换到真正的 `TileMap`/`Node2D` 体系。
