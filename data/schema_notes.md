# 数据字段说明

第 1 章 JSON 数据约定：

- `id`：数据唯一标识。
- `name`：显示名称。
- `element`：元素类型。
- `weapon`：武器类型；灵兽当前使用 `none`，主角使用 `sword`。
- `unit_type`：移动类型，后续章节用于地形与寻路。
- `rarity` / `base_capture_rate`：后续捕捉系统使用。
- `stats`：基础 `hp`、`atk`、`def`、`mov`。
- `skill_id`：关联 `data/skills` 中的技能。
