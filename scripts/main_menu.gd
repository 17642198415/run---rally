extends Control

const ROUTE_MAP_SCENE: String = "res://scenes/roguelike/route_map.tscn"

@onready var roguelike_btn: Button = $Panel/VBox/RoguelikeBtn
@onready var abandon_btn: Button = $Panel/VBox/AbandonBtn
@onready var hint_label: Label = $Panel/VBox/HintLabel

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	MenuStyle.apply_button_styles($Panel/VBox/CampaignBtn)
	MenuStyle.apply_button_styles($Panel/VBox/BestiaryBtn, Color(0.42, 0.24, 0.62), Color(0.55, 0.34, 0.75))
	MenuStyle.apply_button_styles(roguelike_btn, Color(0.55, 0.38, 0.18), Color(0.68, 0.48, 0.24))
	MenuStyle.apply_button_styles(abandon_btn, Color(0.42, 0.22, 0.22), Color(0.55, 0.30, 0.30))
	MenuStyle.apply_button_styles($Panel/VBox/OptionsBtn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))
	$Panel/VBox/TitleLabel.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	$Panel/VBox/SubtitleLabel.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	hint_label.add_theme_color_override("font_color", MenuStyle.TEXT_HINT)
	$Panel/VBox/CampaignBtn.pressed.connect(_on_campaign)
	$Panel/VBox/BestiaryBtn.pressed.connect(_on_bestiary)
	roguelike_btn.pressed.connect(_on_roguelike)
	abandon_btn.pressed.connect(_on_abandon)
	$Panel/VBox/OptionsBtn.pressed.connect(_on_options_locked)
	_refresh_run_buttons()

func _refresh_run_buttons() -> void:
	var save_mgr: Node = get_node("/root/SaveManager")
	var meta: Dictionary = save_mgr.load_meta()
	var run_section: Dictionary = meta.get("run", {}) as Dictionary
	var active: bool = bool(run_section.get("active", false))
	roguelike_btn.disabled = false
	roguelike_btn.text = "继续征途" if active else "开始征途"
	abandon_btn.visible = active
	hint_label.text = ""

func _on_campaign() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign/stage_select.tscn")

func _on_bestiary() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign/bestiary_view.tscn")

func _on_roguelike() -> void:
	var rm: Node = get_node("/root/RunManager")
	var save_mgr: Node = get_node("/root/SaveManager")
	var meta: Dictionary = save_mgr.load_meta()
	var active: bool = bool((meta.get("run", {}) as Dictionary).get("active", false))
	if active:
		if not rm.load_from_meta():
			hint_label.text = "存档加载失败，请重新开始征途。"
			return
	else:
		rm.start_new_run(randi())
		rm.save()
	get_tree().change_scene_to_file(ROUTE_MAP_SCENE)

func _on_abandon() -> void:
	var rm: Node = get_node("/root/RunManager")
	rm.clear()
	hint_label.text = "已放弃当前征途。"
	_refresh_run_buttons()

func _on_options_locked() -> void:
	hint_label.text = "选项页敬请期待。"
