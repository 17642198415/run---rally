## 1. 共享样式基础设施

- [x] 1.1 新建 `scripts/ui/menu_style.gd`（`class_name MenuStyle`）：`make_panel_style()`、`make_card_style(variant: locked/unlocked/cleared/default)`、`make_button_styles() -> Dictionary`、`apply_page_shell(page: Control)`（背景色 + 根 Panel StyleBox）
- [x] 1.2 卡片 StyleBox 数值对齐 `battle_grid_controller._apply_card_styles`（圆角 14、bg 0.13/0.15/0.20/0.92、shadow 8/offset 3）；关卡三态边框色按 design D3
- [x] 1.3 （可选增强）尝试 `ArtLoader.get_ui("panel_bg")` → `StyleBoxTexture` 9-slice；失败则 Flat 回退
- [x] 1.4 （可选）扩展 `assets/art/art_manifest.json` 的 `ui` 段：确认 `panel_bg` 条目存在；可加 `stage_locked`/`stage_cleared` 占位键（非阻塞）

## 2. 主菜单 `main_menu`

- [x] 2.1 改 `scenes/main_menu.tscn`：根 Panel 改 `PanelContainer` 或保留 Panel 并在脚本 override；标题/副标题字号与间距微调
- [x] 2.2 改 `scripts/main_menu.gd`：`_ready()` 调 `MenuStyle.apply_page_shell(self)` + 四个 Button 套 `make_button_styles()`；RoguelikeBtn/OptionsBtn 保持 disabled + 灰度
- [x] 2.3 验证：F5 主菜单 → 战役/图鉴可跳转；开始征途/选项仍提示且不 crash

## 3. 选关页 `stage_select`

- [x] 3.1 改 `scenes/campaign/stage_select.tscn`：移除 3 个 plain Stage Btn，改为 `StageList` 容器（VBox/HBox）供脚本填充卡片
- [x] 3.2 改 `scripts/campaign/stage_select.gd`：`_refresh_stage_buttons()` 构建 3 个 `PanelContainer` 关卡卡（标题=stage name、徽章=状态文案、覆盖 Button 或 gui_input）；`locked` 不可点、`unlocked`/`cleared` 可点
- [x] 3.3 保留 BackBtn + HintLabel；BackBtn 套 MenuStyle 按钮样式
- [x] 3.4 验证：新档仅 stage_01 可挑战（蓝卡）；通关后 stage_02 解锁、stage_01 金卡；锁定关卡灰卡

## 4. 编队页 `party_setup`

- [x] 4.1 改 `scenes/campaign/party_setup.tscn`：HeroLabel 改为 `HeroCard` 容器占位（或脚本动态建）；ReserveList 容器保留
- [x] 4.2 改 `scripts/campaign/party_setup.gd`：`_refresh()` 构建 HERO 高亮 `PanelContainer` 行（金左边框/★）；reserve 每条 = 卡片行 + CheckBox + `TextureRect`(ArtLoader.get_unit) + Label
- [x] 4.3 ConfirmBtn/BackBtn 套 MenuStyle；空 reserve 提示仍显示
- [x] 4.4 验证：选 0~3 只 reserve、超选拒绝、确认后 deploy_list 与改前一致

## 5. 图鉴页 `bestiary_view`

- [x] 5.1 改 `scripts/campaign/bestiary_view.gd`：`_refresh()` 每格 `PanelContainer`（min 120×100）含 TextureRect 48×48 + 名称 Label + 状态角标/Label；未发现=灰 `?`、发现=黄、捕获=绿
- [x] 5.2 改 `scenes/campaign/bestiary_view.tscn`：Grid columns=4 间距 12；标题/BackBtn 样式；`MenuStyle.apply_page_shell`
- [x] 5.3 验证：无存档全 `?`；DEBUG 捕捉后 M01 显示头像+已捕获绿标

## 6. 文档与回归

- [x] 6.1 README 增补「Tier 1 菜单页美化 手动验收」：5~6 项（主菜单卡片 / 选关三态 / HERO 突出 / 图鉴 8 格 / 全流程 F5 战役 / 资源缺失不 crash）
- [x] 6.2 全量 `tests/run_all_tests.ps1` PASS（仍 20 个，无新增单测）
- [ ] 6.3 Godot 编辑器手动验收 6.1 清单（F5 主菜单 → 战役 → 选关 → 编队 → 返回 → 图鉴）
