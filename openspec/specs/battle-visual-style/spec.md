# battle-visual-style Specification

## Purpose

Defines Tier 1 battle scene visual requirements: textured terrain grid, sprite-based units, card-style HUD, iconized action bar, and animated highlight overlays. Logic layers (`Grid`, `TerrainTypes`, combat rules) remain unchanged.

## Requirements

### Requirement: 战斗格子使用 TileMap 与 TileSet 渲染

战斗页 SHALL 使用纹理化渲染呈现地形格（实现可为 `TileMap+TileSet` 或 `TextureRect` 网格，视既有体系决定），每种 `TerrainTypes` 中的地形 MUST 在视觉上能被肉眼区分（颜色或图案不同），且可由 `ArtLoader.get_tile(name)` 提供纹理。`Grid`/`TerrainTypes` 的逻辑数据 MUST 保持不变。

#### Scenario: 草地与林地有不同 tile

- **WHEN** 关卡含 `PLAIN` 与 `FOREST` 两种格子
- **THEN** TileMap 渲染时两种格子使用不同的 tile id，玩家可通过纹理或图标差异肉眼区分

#### Scenario: 部署区有特殊高亮

- **WHEN** 处于部署阶段且某格属于 `deploy_zone`
- **THEN** 该格在地形 tile 之上叠加部署区半透明高亮（蓝绿色）

#### Scenario: 资源缺失回退占位

- **WHEN** `assets/art/tiles/<terrain>.png` 不存在
- **THEN** TileSet 自动回退使用代码生成的纯色占位图（不报错），并在控制台 WARN 一次

### Requirement: 战斗单位使用 Sprite 立绘呈现

战斗单位 SHALL 在 `BattleUnitView` 中显示一个圆形头像底框 + 阵营色描边 + 单位 sprite + HP 进度条。当资源缺失时，MUST 回退到带阵营色描边的圆形色块 + 单字汉字（旅/狐/龟…）以保证可玩性。

#### Scenario: 玩家单位使用蓝色描边

- **WHEN** `is_player == true` 的单位被渲染
- **THEN** 头像底框使用蓝色描边

#### Scenario: 敌方单位使用红色描边

- **WHEN** `is_player == false` 且不是 `downed_capturable`
- **THEN** 头像底框使用红色描边

#### Scenario: 已击倒可捕捉野怪有专属表现

- **WHEN** 单位 `downed_capturable == true`
- **THEN** 头像底框使用青色描边并叠加半透明灰度滤镜

#### Scenario: HP 进度条同步显示

- **WHEN** 单位 hp/max_hp 发生变化
- **THEN** HP 进度条在 0.2s 内 tween 到新比例

### Requirement: 战斗 HUD 卡片化重排

战斗页的 HUD 元素 SHALL 重组为三块卡片：左上"回合状态卡片"（玩家/敌方回合 + 当前行动者）、右上"球数+目标卡片"（剩余球数 + 阶段目标提示）、底部"ActionBar 卡片"。所有卡片 MUST 使用统一的圆角、阴影、半透明深色背景与白字。

#### Scenario: 回合切换时左上卡片更新

- **WHEN** `TurnManager` 进入新回合
- **THEN** 左上卡片显示 `第 N 回合 · 玩家回合 · 当前 火尾狐` 三段信息

#### Scenario: 球数变化时右上卡片刷新

- **WHEN** `GameState.balls_remaining` 变化
- **THEN** 右上卡片中 `球: X` 字段同步刷新

### Requirement: 战斗动作栏图标化

`ActionBar` 的 [移动/攻击/技能/捕捉/待机/结束回合/确认部署] 按钮 SHALL 各自显示一个 16x16 的图标 + 文字。图标资源缺失时 MUST 回退到纯文字按钮，但样式仍保持卡片风格。

#### Scenario: 图标存在时显示图标 + 文字

- **WHEN** `assets/art/icons/move.png` 等存在
- **THEN** 按钮左侧显示 16x16 图标，右侧显示文字

#### Scenario: 图标缺失时回退纯文字

- **WHEN** 任意按钮的图标资源缺失
- **THEN** 该按钮回退为纯文字模式，且不报错

### Requirement: 高亮层带描边与呼吸动画

移动/攻击/技能/捕捉/选中高亮 SHALL 使用半透明色块 + 1px 描边 + 1.0~1.6s 周期的透明度呼吸动画，颜色规范为：

| 用途 | 颜色名 | RGBA（近似） |
|---|---|---|
| 移动 | 蓝 | `0.30, 0.55, 0.95, 0.45` |
| 攻击 | 红 | `0.85, 0.30, 0.30, 0.50` |
| 技能 | 紫 | `0.65, 0.40, 0.85, 0.50` |
| 捕捉 | 青 | `0.30, 0.80, 0.85, 0.50` |
| 选中 | 金 | `1.00, 0.85, 0.40, 0.55` |

#### Scenario: 呼吸动画持续

- **WHEN** 高亮格被绘制
- **THEN** 其透明度在 0.30 ~ 0.55 间循环 tween（不影响输入命中）

#### Scenario: 颜色与状态一致

- **WHEN** 状态由 `TARGETING_MOVE` 切到 `TARGETING_ATTACK`
- **THEN** 高亮颜色由蓝切红，呼吸动画继续保持
