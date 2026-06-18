extends Control

func _ready() -> void:
	$Panel/VBox/CampaignBtn.pressed.connect(_on_campaign)
	$Panel/VBox/BestiaryBtn.pressed.connect(_on_bestiary)
	$Panel/VBox/RoguelikeBtn.pressed.connect(_on_roguelike_locked)
	$Panel/VBox/OptionsBtn.pressed.connect(_on_options_locked)
	$Panel/VBox/RoguelikeBtn.disabled = true

func _on_campaign() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign/stage_select.tscn")

func _on_bestiary() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign/bestiary_view.tscn")

func _on_roguelike_locked() -> void:
	$Panel/VBox/HintLabel.text = "「开始征途」将在第 7 章启用。"

func _on_options_locked() -> void:
	$Panel/VBox/HintLabel.text = "选项页敬请期待。"
