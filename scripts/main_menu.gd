extends Control

@onready var label: Label = $Panel/Label

func _ready() -> void:
	var fire_fox: Dictionary = DataLoader.get_unit("M01")
	var display_name := String(fire_fox.get("name", "未知单位"))
	var unit_count := DataLoader.get_all_unit_ids().size()
	var inspire_skill: Dictionary = DataLoader.get_skill("S_INSPIRE")
	var skill_status := "OK" if not inspire_skill.is_empty() else "缺失"
	label.text = "Run & Rally\n\n第 1 章：项目骨架与数据层已加载\n\nDataLoader 运行时验证：\n- 单位数量：%d / 8\n- M01 名称：%s\n- HERO 技能 S_INSPIRE：%s\n\n下一章：网格、地形与移动" % [unit_count, display_name, skill_status]
	print("DataLoader M01 name: %s" % display_name)
