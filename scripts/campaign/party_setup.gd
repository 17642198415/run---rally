extends Control

const MAX_RESERVE_PICK: int = 3

var _selected_unit_ids: Array[String] = []
var _stage_id: String = ""

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var hero_label: Label = $Panel/VBox/HeroLabel
@onready var reserve_list: VBoxContainer = $Panel/VBox/ScrollContainer/ReserveList
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var confirm_btn: Button = $Panel/VBox/Buttons/ConfirmBtn
@onready var back_btn: Button = $Panel/VBox/Buttons/BackBtn

func _ready() -> void:
	var gs: Node = get_node("/root/GameState")
	_stage_id = String(gs.stage_id)
	confirm_btn.pressed.connect(_on_confirm)
	back_btn.pressed.connect(_on_back)
	_refresh()

func _refresh() -> void:
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	var stage: Dictionary = loader.get_stage(_stage_id)
	title_label.text = "%s · 编队（HERO + 备用栏 ≤ 3）" % String(stage.get("name", _stage_id))
	hero_label.text = "★ HERO（旅团新人）— 固定出战"

	for child in reserve_list.get_children():
		child.queue_free()

	var party: Node = get_node("/root/PartyManager")
	party.ensure_loaded()
	var reserve: Array = party.reserve
	if reserve.is_empty():
		var hint: Label = Label.new()
		hint.text = "（备用栏为空 —— 先去战役里捕一只灵兽）"
		hint.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))
		reserve_list.add_child(hint)
	else:
		for entry_v in reserve:
			var entry: Dictionary = entry_v as Dictionary
			var cb: CheckBox = CheckBox.new()
			cb.text = "%s — %s（HP %d/%d）" % [
				String(entry.get("unit_id", "")),
				String(loader.get_unit(String(entry.get("template_id", ""))).get("name", entry.get("template_id", ""))),
				int(entry.get("hp", 0)),
				int(entry.get("max_hp", 0))
			]
			cb.set_meta("unit_id", String(entry.get("unit_id", "")))
			cb.toggled.connect(_on_reserve_toggled.bind(cb))
			reserve_list.add_child(cb)
	_update_status()

func _on_reserve_toggled(pressed: bool, cb: CheckBox) -> void:
	var uid: String = String(cb.get_meta("unit_id"))
	if pressed:
		if _selected_unit_ids.size() >= MAX_RESERVE_PICK:
			cb.set_pressed_no_signal(false)
			status_label.text = "最多选择 %d 只备用栏单位。" % MAX_RESERVE_PICK
			return
		if not _selected_unit_ids.has(uid):
			_selected_unit_ids.append(uid)
	else:
		_selected_unit_ids.erase(uid)
	_update_status()

func _update_status() -> void:
	status_label.text = "已选 %d / %d 只" % [_selected_unit_ids.size(), MAX_RESERVE_PICK]

func _on_confirm() -> void:
	var party: Node = get_node("/root/PartyManager")
	var deploy_list: Array = []
	deploy_list.append({
		"template_id": "HERO",
		"unit_id": "P_HERO",
		"hp": 0,
		"max_hp": 0
	})
	for entry_v in party.reserve:
		var entry: Dictionary = entry_v as Dictionary
		var uid: String = String(entry.get("unit_id", ""))
		if _selected_unit_ids.has(uid):
			deploy_list.append({
				"template_id": String(entry.get("template_id", "")),
				"unit_id": uid,
				"hp": int(entry.get("max_hp", 0)),
				"max_hp": int(entry.get("max_hp", 0))
			})
	var gs: Node = get_node("/root/GameState")
	gs.start_campaign_battle(_stage_id, deploy_list)
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/campaign/stage_select.tscn")
