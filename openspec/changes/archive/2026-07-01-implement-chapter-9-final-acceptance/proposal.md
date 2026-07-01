## Why

第 0～8 章功能已全部落地：战役三关（M2）、肉鸽 6 层路线图与事件节点（M3）、三选一奖励与 Meta 解锁（M4 前置）。Demo 计划第 9 章是 **里程碑 M4 收尾**——对照 MVP §1.5 成功标准做全量回归、固定手动剧本、修阻塞性 bug、记录已知限制，并可选导出 Windows 包。本轮**不加 v3 功能**，只做验收与发布准备。

## What Changes

- README 增补 **「MVP 终验清单」**（对齐 Demo §9.3：B1～B4 战斗层、C1～C2 战役、R1～R6 肉鸽、G1～G2 通用）与 **回归剧本 A/B/C** 步骤说明
- README 增补 **「已知限制与 v3 Backlog」** 小节（Demo §9.6～9.7，修正「Run 中不存档」为当前已支持中途存档的说明）
- 执行全量 `tests/run_all_tests.ps1`（34 个）并记录结果；对终验中发现的**阻塞 bug** 做最小修复（若有）
- 可选：新增 `export_presets.cfg` 或 README 导出步骤（Windows Desktop → `builds/demo/`），不强制 CI 打包
- 修正 README 中已与现状不符的验收描述（如主菜单「开始征途」已启用、肉鸽解锁 Tab 等）
- 更新 README 进度：勾选「第 9 章 最终验收与发布准备（→ M4）」
- 不在本轮：永久死亡、异常状态、进化、第 4 种 Meta、8 层路线、新玩法、大规模视觉/音效

## Capabilities

### New Capabilities

- `mvp-acceptance`: MVP 成功标准终验表、三条回归剧本、已知限制文档化、全量单测与可选导出约定

### Modified Capabilities

- 无（除非终验发现 spec 级行为缺口，届时以 delta spec 记录最小修复项）

## Impact

- **文档**：`README.md`（主交付物，不新建 `ACCEPTANCE.md` 除非终验时发现 README 过长）
- **代码**：仅阻塞 bug 的最小修复（范围不确定，待回归后定）
- **配置**：可选 `export_presets.cfg`
- **测试**：保持 34 个 headless 单测 GREEN；可选 1 个 smoke 测试聚合 DataLoader 8 单位（仅当终验发现缺口时加）
- **里程碑**：M4 达成条件 = §9.3 清单可勾选 + 剧本 A/B/C 各走通 1 次无阻塞 crash
