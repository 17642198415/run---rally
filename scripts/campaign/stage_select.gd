extends Control

const STAGE_FILES: Dictionary = {
	"stage_01": "stage_01_border_plain",
	"stage_02": "stage_02_wet_edge",
	"stage_03": "stage_03_old_fort_boss"
}

const STAGE_ORDER: Array[String] = ["stage_01", "stage_02", "stage_03"]

@onready var stage_list: VBoxContainer = $Panel/VBox/StageList
@onready var hint_label: Label = $Panel/VBox/HintLabel
@onready var back_btn: Button = $Panel/VBox/BackBtn
@onready var title_label: Label = $Panel/VBox/TitleLabel

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	hint_label.add_theme_color_override("font_color", MenuStyle.TEXT_HINT)
	MenuStyle.apply_button_styles(back_btn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))
	back_btn.pressed.connect(_on_back)
	_refresh_stage_cards()

func _refresh_stage_cards() -> void:
	for child in stage_list.get_children():
		child.queue_free()
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	var campaign: Node = get_node("/root/CampaignManager")
	campaign.ensure_loaded()
	for stage_id in STAGE_ORDER:
		var stage: Dictionary = loader.get_stage(stage_id)
		var name: String = String(stage.get("name", stage_id))
		var status: String = campaign.get_status(stage_id)
		var can_enter: bool = campaign.can_enter(stage_id)
		var card: PanelContainer = MenuStyle.build_stage_card(
			stage_id,
			name,
			status,
			can_enter,
			_on_stage_pressed
		)
		stage_list.add_child(card)

func _on_stage_pressed(stage_id: String) -> void:
	var campaign: Node = get_node("/root/CampaignManager")
	if not campaign.can_enter(stage_id):
		hint_label.text = "%s 尚未解锁。" % stage_id
		return
	var gs: Node = get_node("/root/GameState")
	gs.current_mode = gs.GameMode.CAMPAIGN
	gs.stage_id = stage_id
	get_tree().change_scene_to_file("res://scenes/campaign/party_setup.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
