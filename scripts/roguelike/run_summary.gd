extends Control

const ROUTE_MAP_SCENE: String = "res://scenes/roguelike/route_map.tscn"

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var summary_label: Label = $Panel/VBox/SummaryLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var menu_btn: Button = $Panel/VBox/MenuBtn

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	summary_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	stats_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	MenuStyle.apply_button_styles(menu_btn, Color(0.22, 0.42, 0.72), Color(0.30, 0.52, 0.82))
	menu_btn.pressed.connect(_on_menu)

	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	var outcome: Dictionary = rm.get_last_outcome()
	var victory: bool = bool(outcome.get("victory", false))
	var seed_val: int = 0 if state == null else int(state.seed)
	var layer_val: int = 1 if state == null else mini(int(state.current_layer), 6)

	if victory:
		title_label.text = "征途通关！"
		summary_label.text = "种子 %d · BOSS 已击败" % seed_val
	elif state != null and bool(state.hero_dead):
		title_label.text = "征途失败"
		summary_label.text = "种子 %d · 主角倒下（第 %d 层）" % [seed_val, layer_val]
	else:
		title_label.text = "征途结束"
		summary_label.text = "种子 %d · 抵达第 %d 层" % [seed_val, layer_val]

	var save_mgr: Node = get_node("/root/SaveManager")
	var mm: Node = get_node("/root/MetaManager")
	var meta: Dictionary = save_mgr.load_meta()
	var stats: Dictionary = mm.normalize_stats(meta.get("stats", {}) as Dictionary)
	stats_label.text = "征途 %d 次 · 最深 %d 层 · Meta %d/3" % [
		int(stats.get("runs_started", 0)),
		int(stats.get("deepest_layer", 0)),
		mm.unlocked_count()
	]

func _on_menu() -> void:
	var rm: Node = get_node("/root/RunManager")
	rm.clear()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
