extends Control

const MAX_RESERVE_PICK: int = 3
const ROUTE_MAP_SCENE: String = "res://scenes/roguelike/route_map.tscn"

var _selected_unit_ids: Array[String] = []
var _stage_id: String = ""
var _roguelike_mode: bool = false

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var hero_card_slot: VBoxContainer = $Panel/VBox/HeroCardSlot
@onready var reserve_list: VBoxContainer = $Panel/VBox/ScrollContainer/ReserveList
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var confirm_btn: Button = $Panel/VBox/Buttons/ConfirmBtn
@onready var back_btn: Button = $Panel/VBox/Buttons/BackBtn

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	status_label.add_theme_color_override("font_color", MenuStyle.TEXT_HINT)
	MenuStyle.apply_button_styles(confirm_btn, Color(0.20, 0.48, 0.36), Color(0.28, 0.58, 0.44))
	MenuStyle.apply_button_styles(back_btn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))
	var gs: Node = get_node("/root/GameState")
	_roguelike_mode = gs.current_mode == gs.GameMode.ROGUELIKE
	if not _roguelike_mode:
		_stage_id = String(gs.stage_id)
	confirm_btn.pressed.connect(_on_confirm)
	back_btn.pressed.connect(_on_back)
	_refresh()

func _refresh() -> void:
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	if _roguelike_mode:
		var ctx: Dictionary = get_node("/root/GameState").battle_context as Dictionary
		var node_id: String = String(ctx.get("run_node_id", ""))
		title_label.text = "肉鸽编队 · %s（HERO + 备用栏 ≤ 3）" % node_id
	else:
		var stage: Dictionary = loader.get_stage(_stage_id)
		title_label.text = "%s · 编队（HERO + 备用栏 ≤ 3）" % String(stage.get("name", _stage_id))

	for child in hero_card_slot.get_children():
		child.queue_free()
	hero_card_slot.add_child(MenuStyle.build_hero_card("★ HERO（旅团新人）— 固定出战"))

	for child in reserve_list.get_children():
		child.queue_free()

	var reserve: Array = _get_reserve_source()
	if reserve.is_empty():
		var hint_panel: PanelContainer = PanelContainer.new()
		hint_panel.add_theme_stylebox_override("panel", MenuStyle.make_card_style(MenuStyle.CardVariant.LOCKED))
		var hint: Label = Label.new()
		hint.text = "（备用栏为空 —— 战斗中捕捉可补充）" if _roguelike_mode else "（备用栏为空 —— 先去战役里捕一只灵兽）"
		hint.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
		hint_panel.add_child(hint)
		reserve_list.add_child(hint_panel)
	else:
		for entry_v in reserve:
			var entry: Dictionary = entry_v as Dictionary
			var unit_name: String = String(
				loader.get_unit(String(entry.get("template_id", ""))).get("name", entry.get("template_id", ""))
			)
			var row: PanelContainer = MenuStyle.build_reserve_row(
				entry,
				unit_name,
				_on_reserve_toggled
			)
			reserve_list.add_child(row)
	_update_status()

func _get_reserve_source() -> Array:
	if _roguelike_mode:
		var rm: Node = get_node("/root/RunManager")
		var state: Resource = rm.get_state()
		if state == null:
			return []
		return state.reserve as Array
	var party: Node = get_node("/root/PartyManager")
	party.ensure_loaded()
	return party.reserve as Array

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

func _build_deploy_list() -> Array:
	var deploy_list: Array = []
	deploy_list.append({
		"template_id": "HERO",
		"unit_id": "P_HERO",
		"hp": 0,
		"max_hp": 0
	})
	var reserve: Array = _get_reserve_source()
	for entry_v in reserve:
		var entry: Dictionary = entry_v as Dictionary
		var uid: String = String(entry.get("unit_id", ""))
		if _selected_unit_ids.has(uid):
			deploy_list.append({
				"template_id": String(entry.get("template_id", "")),
				"unit_id": uid,
				"hp": int(entry.get("hp", entry.get("max_hp", 0))),
				"max_hp": int(entry.get("max_hp", 0))
			})
	return deploy_list

func _on_confirm() -> void:
	var deploy_list: Array = _build_deploy_list()
	var gs: Node = get_node("/root/GameState")
	if _roguelike_mode:
		var ctx: Dictionary = gs.battle_context as Dictionary
		gs.start_roguelike_battle(
			String(ctx.get("run_node_id", "")),
			ctx.get("enemies", []) as Array,
			String(ctx.get("map_template", "")),
			bool(ctx.get("is_elite", false)),
			bool(ctx.get("is_boss", false)),
			deploy_list
		)
	else:
		gs.start_campaign_battle(_stage_id, deploy_list)
	get_tree().change_scene_to_file("res://scenes/battle/battle.tscn")

func _on_back() -> void:
	if _roguelike_mode:
		get_tree().change_scene_to_file(ROUTE_MAP_SCENE)
	else:
		get_tree().change_scene_to_file("res://scenes/campaign/stage_select.tscn")
