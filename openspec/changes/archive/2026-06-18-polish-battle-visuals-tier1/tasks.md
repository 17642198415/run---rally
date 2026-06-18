## 1. RED 测试骨架

- [x] 1.1 新增 `tests/unit/test_art_loader.gd`：覆盖 `get_tile/get_unit/get_icon/get_ui` 在物理文件存在 / 不存在两条路径，断言均返回非空 `Texture2D`、尺寸正确、不报错；manifest 文件缺失时使用内置默认。
- [x] 1.2 修复 `tests/run_all_tests.ps1` 自动发现新测试，确保新增 1 个测试，总数 19 → 20。
- [x] 1.3 跑一次回归，确认 `test_art_loader.gd` RED（其他 19 个仍 GREEN）。

## 2. ArtLoader 与资源管线

- [x] 2.1 新建目录 `assets/art/{tiles,units,icons,ui}/`，加 `.gitkeep`。
- [x] 2.2 写入 `assets/art/art_manifest.json`：覆盖 5 种地形、HERO + M01..M08 + BOSS_MERC 共 10 个单位、7 个动作图标、3 个 UI 元素，全部带 `fallback_*` 字段。
- [x] 2.3 实现 `scripts/art/art_loader.gd`：
  - 启动加载 manifest（缺失时使用内置默认）。
  - `get_tile/get_unit/get_icon/get_ui(name) -> Texture2D`，缓存 + 占位回退。
  - `_make_tile_placeholder(color)`：32x32 纯色 + 1px 暗描边。
  - `_make_unit_placeholder(bg, glyph)`：64x64 圆形 + 文字。
  - `_make_icon_placeholder(glyph)`：16x16 透明 + 文字。
  - 资源命名校验：非法名 push_warning。
- [x] 2.4 在 `project.godot` 注册 `ArtLoader` 为 autoload。
- [x] 2.5 跑测试，让 1.1 中的 `test_art_loader.gd` 转 GREEN。

## 3. 战斗格子纹理化 + 高亮呼吸

- [x] 3.1 在 `battle_grid_controller._render_terrain` 中，把每格的 `ColorRect` 替换为 `TextureRect`，纹理通过 `ArtLoader.get_tile(name)` 获取（地形→key 映射：PLAIN→plain、FOREST→forest、WATER→water、WALL→wall、MOUNT→forest 复用）；保留 `_render_terrain` 接口签名不变。
- [x] 3.2 部署区在地形之上叠加独立 `TextureRect`（`ArtLoader.get_tile("deploy")`，`modulate.a = 0.55`），与原 `highlight_deploy_zone` 接口兼容。
- [x] 3.3 高亮层 `_render_highlights` 改为生成 `ColorRect + 1px 描边`，并启动呼吸 Tween（`modulate:a` 在 0.30~0.55 间循环）；`_clear_highlights` 中显式 kill 子节点的 Tween。
- [x] 3.4 配色按 spec 表统一（移动蓝 / 攻击红 / 技能紫 / 捕捉青 / 选中金），统一收敛到 `terrain_types.gd` 常量。

## 4. 战斗单位视觉

- [x] 4.1 重写 `scenes/battle/battle_unit_view.tscn`：根 Control 64x64，子节点 `Bg(Panel/CircleStyleBox)` + `Sprite2D` + `ProgressBar(HP)` + `FactionRing(描边)` + `FallbackLabel`。
- [x] 4.2 `scripts/battle/battle_unit_view.gd`：在 `set_unit_data()` 中调 `ArtLoader.get_unit(template_id)` 赋 `Sprite2D.texture`；缺失时显示 `FallbackLabel`（已有汉字逻辑保留）；HP tween 0.2s。
- [x] 4.3 阵营色描边规则：玩家蓝、敌方红、`downed_capturable` 青 + 半透灰度滤镜。
- [x] 4.4 已行动后叠加 `modulate = 0.6` 灰度（可通过 `set_acted(bool)` 切换）。

## 5. HUD 与 ActionBar 卡片化

- [x] 5.1 `scenes/battle/battle.tscn` 把 `HudLabel/TurnBanner/BallsLabel` 替换为三块 `PanelContainer`（左上 `TurnCard`、右上 `ObjectiveCard`、底部 `ActionBarCard`），统一 StyleBox（圆角 14、阴影、半透明深色 0.13/0.15/0.20/0.92）。
- [x] 5.2 右上 `ObjectiveCard` 合并球数 + 阶段目标提示（如 `球: 3 · 击败首领`）。
- [x] 5.3 `ActionBar` 的 7 个按钮通过 `ArtLoader.get_icon(action)` 取图标赋 `Button.icon`，缺图自动回退纯文字；按钮高度固定避免抖动。
- [x] 5.4 `CapturePrompt` 同样套用卡片样式（保持现有功能）。

## 6. 联交 + README + 全量回归

- [x] 6.1 全部 20 个单测 GREEN（`tests/run_all_tests.ps1`）。
- [x] 6.2 README 增补 `assets/art/` 目录说明 + 资源替换指引（如何放 Kenney 素材到 `assets/art/units/hero.png`）。
- [x] 6.3 README 增补"Tier 1 战斗页美化 手动验收"章节：覆盖 5 项视觉验收点（地形可区分 / 单位有头像 / HUD 三卡片 / 高亮呼吸 / 已行动灰度）。
- [ ] 6.4 在 Godot 编辑器内手动验收：F5 进 DEBUG 关，确认上述 5 项 + 资源缺失回退仍能跑。
