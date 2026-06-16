# Run & Rally

战棋捉宠 Demo（Godot 4.6 + GDScript）。详细实施计划见 [`Demo完整实施计划.md`](./Demo完整实施计划.md)。

## 运行

1. 用 Godot 4.3+（当前工程标记为 4.6）打开本目录的 `project.godot`
2. 按 `F5` 运行主场景（`scenes/main_menu.tscn`），出现 1280×720 窗口即正常

## 目录约定（按 Demo 计划逐章扩展）

```
data/        游戏数据 JSON（单位、技能、关卡、路线池等）
scenes/      Godot 场景（主菜单、战斗、肉鸽路线图等）
scripts/     GDScript（autoload、battle、roguelike、campaign）
assets/      美术/音效占位资源
```

## 进度

- [x] 第 0 章 环境与工具链
- [x] 第 1 章 项目骨架与数据层
- [ ] 第 2 章 网格、地形与移动
- [ ] 第 3 章 战斗与克制
- [ ] 第 4 章 回合、部署与敌方 AI（→ M1）
- [ ] 第 5 章 捕捉、备用栏与图鉴
- [ ] 第 6 章 战役模式与主菜单（→ M2）
- [ ] 第 7 章 肉鸽路线图与 Run 状态（→ M3）
- [ ] 第 8 章 三选一奖励、Meta 解锁与打磨
- [ ] 第 9 章 最终验收与发布准备（→ M4）
