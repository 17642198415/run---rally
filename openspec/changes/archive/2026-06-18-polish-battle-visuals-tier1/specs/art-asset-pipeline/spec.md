## ADDED Requirements

### Requirement: 美术资源目录结构与命名约定

项目 SHALL 在 `assets/art/` 下建立以下目录：

```
assets/art/
  tiles/      # 32x32 PNG，按地形命名：plain.png/forest.png/water.png/wall.png/deploy.png
  units/      # 64x64 PNG，按 template_id 小写命名：hero.png/m01.png/.../m08.png/boss_merc.png
  icons/      # 16x16 PNG，按动作命名：move/attack/skill/capture/wait/end_turn/confirm.png
  ui/         # 任意尺寸，按用途命名：panel_bg.png/avatar_ring.png/...
  art_manifest.json
```

文件名 MUST 全小写、kebab-case 或 snake_case，禁止空格与中文。

#### Scenario: 标准命名通过校验

- **WHEN** `assets/art/tiles/plain.png` 与 `assets/art/units/hero.png` 存在
- **THEN** `ArtLoader.scan_assets()` 返回的 manifest 包含 `tiles.plain` 与 `units.hero` 两条记录

#### Scenario: 非法命名被忽略并 WARN

- **WHEN** `assets/art/tiles/平原.png` 存在
- **THEN** `ArtLoader.scan_assets()` 跳过该文件并 push_warning 一次，不阻塞加载

### Requirement: 提供 art_manifest.json 索引

`assets/art/art_manifest.json` SHALL 描述每个资源的逻辑键、相对路径、像素尺寸与回退占位元数据，结构如下：

```json
{
  "version": 1,
  "tiles": {
    "plain":   { "path": "tiles/plain.png",   "size": [32, 32], "fallback_color": "#7BB661" },
    "forest":  { "path": "tiles/forest.png",  "size": [32, 32], "fallback_color": "#3D7A3D" }
  },
  "units": {
    "hero": { "path": "units/hero.png", "size": [64, 64], "fallback_glyph": "旅", "fallback_bg": "#3A6BD8" }
  },
  "icons": {
    "move": { "path": "icons/move.png", "size": [16, 16], "fallback_glyph": "→" }
  }
}
```

`ArtLoader` MUST 读取此文件并暴露 `get_tile(name)`、`get_unit(template_id)`、`get_icon(action)` 接口；找不到资源时 MUST 返回基于 fallback 字段的占位 `Texture2D`。

#### Scenario: manifest 缺失字段时使用默认回退

- **WHEN** `art_manifest.json` 中 `tiles.plain` 没有 `fallback_color`
- **THEN** `ArtLoader.get_tile("plain")` 仍能返回一个非空 `Texture2D`（使用全局默认占位色）

#### Scenario: manifest 文件不存在

- **WHEN** `assets/art/art_manifest.json` 不存在
- **THEN** `ArtLoader` 启动时构造一个内置默认 manifest，仅保证战斗页能跑通占位流程

### Requirement: 资源缺失时使用代码生成占位图

当 manifest 中声明的物理文件不存在时，`ArtLoader` SHALL 在内存中合成一张占位 `ImageTexture`：

- tile：32x32 纯色（fallback_color）+ 1px 暗色描边。
- unit：64x64 圆形（fallback_bg）+ 居中绘制 fallback_glyph（白色）+ 透明边框。
- icon：16x16 透明背景 + 单字 fallback_glyph（白色）。

占位图 MUST 与正式资源在同一调用接口下可互换（即业务代码无需感知是否为占位）。

#### Scenario: 业务代码无感切换

- **WHEN** `assets/art/units/hero.png` 不存在但 manifest 配置了 `fallback_glyph: 旅`
- **THEN** `BattleUnitView` 调用 `ArtLoader.get_unit("hero")` 得到的纹理可直接赋给 `Sprite2D.texture`，画面显示带"旅"字的圆形占位

#### Scenario: 后续替换为正式素材无需改业务

- **WHEN** 用户后期把真实 `hero.png` 放入 `assets/art/units/`
- **THEN** 重启场景后画面自动切换为正式立绘，业务代码无需任何改动
