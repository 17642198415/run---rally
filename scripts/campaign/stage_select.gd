extends Control

const STAGE_FILES: Dictionary = {
	"stage_01": "stage_01_border_plain",
	"stage_02": "stage_02_wet_edge",
	"stage_03": "stage_03_old_fort_boss"
}

@onready var stage_01_btn: Button = $Panel/VBox/StageList/Stage01Btn
@onready var stage_02_btn: Button = $Panel/VBox/StageList/Stage02Btn
@onready var stage_03_btn: Button = $Panel/VBox/StageList/Stage03Btn
@onready var hint_label: Label = $Panel/VBox/HintLabel

func _ready() -> void:
	stage_01_btn.pressed.connect(_on_stage_pressed.bind("stage_01"))
	stage_02_btn.pressed.connect(_on_stage_pressed.bind("stage_02"))
	stage_03_btn.pressed.connect(_on_stage_pressed.bind("stage_03"))
	$Panel/VBox/BackBtn.pressed.connect(_on_back)
	_refresh_stage_buttons()

func _refresh_stage_buttons() -> void:
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	var campaign: Node = get_node("/root/CampaignManager")
	campaign.ensure_loaded()
	for stage_id in STAGE_FILES.keys():
		var btn: Button = _get_button(stage_id)
		var stage: Dictionary = loader.get_stage(stage_id)
		var name: String = String(stage.get("name", stage_id))
		var status: String = campaign.get_status(stage_id)
		var status_label: String = _status_label(status)
		btn.text = "%s  ·  %s" % [name, status_label]
		btn.disabled = not campaign.can_enter(stage_id)

func _status_label(status: String) -> String:
	match status:
		"cleared":
			return "已通关"
		"unlocked":
			return "可挑战"
		_:
			return "未解锁"

func _get_button(stage_id: String) -> Button:
	match stage_id:
		"stage_01":
			return stage_01_btn
		"stage_02":
			return stage_02_btn
		"stage_03":
			return stage_03_btn
	return stage_01_btn

func _on_stage_pressed(stage_id: String) -> void:
	var campaign: Node = get_node("/root/CampaignManager")
	if not campaign.can_enter(stage_id):
		hint_label.text = "%s 尚未解锁。" % stage_id
		return
	var gs: Node = get_node("/root/GameState")
	gs.stage_id = stage_id
	get_tree().change_scene_to_file("res://scenes/campaign/party_setup.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
