extends Control

const SPECIES: Array[String] = ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08"]

@onready var grid: GridContainer = $Panel/VBox/Grid
@onready var back_btn: Button = $Panel/VBox/BackBtn

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_refresh()

func _refresh() -> void:
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	var bestiary: Node = get_node("/root/BestiaryManager")
	bestiary.ensure_loaded()
	for child in grid.get_children():
		child.queue_free()
	for tid in SPECIES:
		var cell: Panel = Panel.new()
		cell.custom_minimum_size = Vector2(120, 80)
		var label: Label = Label.new()
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var unit: Dictionary = loader.get_unit(tid)
		var name: String = String(unit.get("name", tid))
		var status: String
		if bestiary.is_caught(tid):
			status = "已捕获"
			label.text = "%s\n%s\n[%s]" % [tid, name, status]
			label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
		elif bestiary.is_discovered(tid):
			status = "已发现"
			label.text = "%s\n%s\n[%s]" % [tid, name, status]
			label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.45))
		else:
			status = "未发现"
			label.text = "%s\n?\n[%s]" % [tid, status]
			label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
		cell.add_child(label)
		grid.add_child(cell)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
