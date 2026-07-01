## Context

- 仓库已完成 Demo 计划第 0～8B 章：34 个 headless 单测全绿；战役、肉鸽、三选一、Meta 均已实现。
- README 已有 Tier 1 战斗/菜单手动验收章节，但缺少 Demo §9.3 的**结构化 MVP 终验表**与剧本 A/B/C。
- Demo §9.6「Run 中不存档」与当前实现矛盾（7A 起 `SaveManager.run` 支持中途存档）；终验文档需更正。
- 用户规则：不擅自新建文档文件；验收清单优先写入 README。

约束：Godot 4.6；Windows UTF-8；不加 v3 功能；bug 修复仅限阻塞项。

## Goals / Non-Goals

**Goals:**

- README 承载完整 MVP 终验清单（B/C/R/G 共 14 项）与三条回归剧本
- 全量单测 PASS + 手动剧本 A/B/C 可走通
- 已知限制与 v3 backlog 落盘（README 小节）
- 可选 Windows 导出说明或 preset
- README 进度勾选第 9 章

**Non-Goals:**

- v3 backlog 功能实现
- 新 Meta、进化、异常状态、反击
- 大规模 polish、真实素材替换
- 强制 git tag `demo-mvp-v1.0`（可选，由用户执行）

## Decisions

### D1 — 验收文档落在 README，不新建 ACCEPTANCE.md

- **决定**：在 README 新增「MVP 终验」与「已知限制」章节，与现有 Tier 1 手动验收并列
- **理由**：用户规则禁止未请求的文档；README 已是进度与验收入口
- **替代**：独立 `ACCEPTANCE.md`。**否决**：除非 README 超 500 行再拆

### D2 — 自动化 vs 手动边界

| 类别 | 自动化（已有单测） | 手动（F5 剧本） |
|------|-------------------|-----------------|
| B3 8 种灵兽数据 | `test_data_loader` / `test_stage_loader` | — |
| C2 存档 | `test_save_manager` / `test_campaign_manager` | 剧本 A 步骤 4 重启验证 |
| R6 Meta | `test_meta_manager` / `test_run_manager_meta` | 剧本 B/C 球数/解锁 Tab |
| B1/B2/R1～R5/G1/G2 | 部分逻辑单测 | 剧本 A/B/C 全流程 |

- **决定**：apply 阶段先跑 34 单测；手动项在 README 用 checkbox 供执行者勾选
- **理由**：终验本质是回归，不重复造 E2E 框架

### D3 — Bug 修复范围

- **决定**：仅修复剧本 A/B/C 或单测中发现的 **crash / 进度丢失 / 核心流程阻断**；UI 瑕疵、平衡性不调
- **理由**：第 9 章工时是「4h 回归 + 4～8h 修 bug」，不是新功能

### D4 — 导出（可选）

- **决定**：README 写 Godot Export 步骤；若仓库尚无 `export_presets.cfg`，apply 时可添加 Windows Desktop preset 指向 `builds/demo/`，**不**在 apply 中强制打出 exe（依赖本机 Godot 导出模板）
- **理由**：Demo §9.5 标为可选；CI 无 Godot 导出环境

### D5 — 修正过时验收描述

- **决定**：更新 Tier 1 菜单验收第 1 条：「开始征途」已可用；图鉴验收补充「解锁」Tab
- **理由**：7B1/8B 已改变主菜单与图鉴行为，终验文档需与现状一致

## Risks / Trade-offs

- [手动剧本耗时长 ~95 min] → README 标注预估时间，可分次执行
- [终验发现大量 bug] → 优先修阻塞项，非阻塞记入 README 已知限制
- [导出模板未安装] → README 说明需 Godot 导出模板，失败不阻塞 M4

## Migration Plan

1. README 增补终验清单 + 剧本 + 已知限制
2. `tests/run_all_tests.ps1` 全绿确认
3. F5 走剧本 A/B/C，记录并修阻塞 bug
4. 更新进度勾选第 9 章
5. 可选：export preset + 本地打一次包

## Open Questions

- 是否在 apply 阶段新增 `test_mvp_smoke.gd` 聚合「8 单位 + 5 地图 + 3 Meta 定义」一次性断言？**建议**：仅当现有单测未覆盖时再补，默认不加。
