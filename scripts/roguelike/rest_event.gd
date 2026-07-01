extends Control

const ROUTE_MAP_SCENE: String = "res://scenes/roguelike/route_map.tscn"

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var heal_btn: Button = $Panel/VBox/HealBtn
@onready var sacrifice_btn: Button = $Panel/VBox/SacrificeBtn
@onready var sacrifice_list: ItemList = $Panel/VBox/SacrificeList
@onready var leave_btn: Button = $Panel/VBox/LeaveBtn

var _node_id: String = ""
var _applied: bool = false

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	status_label.add_theme_color_override("font_color", MenuStyle.TEXT_HINT)
	MenuStyle.apply_button_styles(heal_btn, Color(0.20, 0.48, 0.36), Color(0.28, 0.58, 0.44))
	MenuStyle.apply_button_styles(sacrifice_btn, Color(0.55, 0.38, 0.18), Color(0.68, 0.48, 0.24))
	MenuStyle.apply_button_styles(leave_btn, Color(0.22, 0.42, 0.72), Color(0.30, 0.52, 0.82))

	var gs: Node = get_node("/root/GameState")
	var pending: Dictionary = gs.pending_event_node as Dictionary
	_node_id = String(pending.get("run_node_id", ""))
	if _node_id.is_empty():
		get_tree().change_scene_to_file(ROUTE_MAP_SCENE)
		return

	heal_btn.pressed.connect(_on_heal_30)
	sacrifice_btn.pressed.connect(_on_sacrifice)
	leave_btn.pressed.connect(_on_leave)
	_refresh_sacrifice_list()

func _refresh_sacrifice_list() -> void:
	sacrifice_list.clear()
	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	var reserve: Array = state.reserve as Array
	sacrifice_btn.visible = not reserve.is_empty()
	sacrifice_list.visible = not reserve.is_empty()
	if reserve.is_empty():
		status_label.text = "选择恢复方式后离开营地。"
		return
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	for i in range(reserve.size()):
		var entry: Dictionary = reserve[i] as Dictionary
		var name: String = String(
			loader.get_unit(String(entry.get("template_id", ""))).get("name", entry.get("template_id", ""))
		)
		sacrifice_list.add_item("%s (%s)" % [name, String(entry.get("unit_id", ""))])
	status_label.text = "已恢复：%s" % ("是" if _applied else "否")

func _on_heal_30() -> void:
	if _applied:
		return
	_apply_heal_percent(0.3)
	_applied = true
	_lock_choice()
	status_label.text = "全队已恢复 30% HP。"

func _on_sacrifice() -> void:
	if _applied:
		return
	var selected: PackedInt32Array = sacrifice_list.get_selected_items()
	if selected.is_empty():
		status_label.text = "请先选择要献祭的备用宠。"
		return
	var index: int = int(selected[0])
	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	var reserve: Array = state.reserve as Array
	if index < 0 or index >= reserve.size():
		return
	var sacrifice_id: String = String((reserve[index] as Dictionary).get("unit_id", ""))
	var hero_max: int = _hero_max_hp()
	state.reserve = RunState.remove_reserve_unit(reserve, sacrifice_id)
	state.party = RunState.full_heal_entries(state.party as Array, hero_max)
	state.reserve = RunState.full_heal_entries(state.reserve as Array, hero_max)
	_applied = true
	_lock_choice()
	_refresh_sacrifice_list()
	status_label.text = "献祭完成，其余单位已满血。"

func _lock_choice() -> void:
	heal_btn.disabled = true
	sacrifice_btn.disabled = true
	sacrifice_list.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_leave() -> void:
	if not _applied:
		status_label.text = "请先选择恢复方式。"
		return
	var rm: Node = get_node("/root/RunManager")
	rm.save()
	rm.complete_event_node(_node_id)
	get_node("/root/GameState").pending_event_node = {}
	get_tree().change_scene_to_file(ROUTE_MAP_SCENE)

func _apply_heal_percent(pct: float) -> void:
	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	var hero_max: int = _hero_max_hp()
	state.party = RunState.heal_entries_percent(state.party as Array, pct, hero_max)
	state.reserve = RunState.heal_entries_percent(state.reserve as Array, pct, hero_max)

func _hero_max_hp() -> int:
	var loader: Node = get_node("/root/DataLoader")
	var hero: Dictionary = loader.get_hero()
	return int((hero.get("stats", {}) as Dictionary).get("hp", 25))
