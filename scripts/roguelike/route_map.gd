extends Control

const NodeHandlers = preload("res://scripts/roguelike/node_handlers.gd")
const PARTY_SETUP_SCENE: String = "res://scenes/campaign/party_setup.tscn"
const MAIN_MENU_SCENE: String = "res://scenes/main_menu.tscn"

const ALL_NODE_TYPES: Array[String] = ["battle", "elite", "boss", "rest", "shop", "capture_event"]

@onready var title_label: Label = $HBox/Sidebar/VBox/TitleLabel
@onready var layer_label: Label = $HBox/Sidebar/VBox/LayerLabel
@onready var balls_label: Label = $HBox/Sidebar/VBox/BallsLabel
@onready var coins_label: Label = $HBox/Sidebar/VBox/CoinsLabel
@onready var reserve_label: Label = $HBox/Sidebar/VBox/ReserveLabel
@onready var hint_label: Label = $HBox/Sidebar/VBox/HintLabel
@onready var route_scroll: ScrollContainer = $HBox/RouteScroll
@onready var route_layers: VBoxContainer = $HBox/RouteScroll/RouteLayers
@onready var back_btn: Button = $HBox/Sidebar/VBox/BackBtn

var _state: Resource = null
var _node_types: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	layer_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	balls_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	coins_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	reserve_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	hint_label.add_theme_color_override("font_color", MenuStyle.TEXT_HINT)
	MenuStyle.apply_button_styles(back_btn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))
	back_btn.pressed.connect(_on_back)

	var rm: Node = get_node("/root/RunManager")
	_state = rm.get_state()
	if _state == null:
		if not rm.load_from_meta():
			get_tree().change_scene_to_file(MAIN_MENU_SCENE)
			return
		_state = rm.get_state()
	if _state == null:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
		return

	if rm.has_pending_rewards():
		get_tree().change_scene_to_file("res://scenes/roguelike/reward_pick.tscn")
		return

	_rng.seed = int(_state.seed) + int(_state.current_layer) * 997 + (_state.selected_path as Array).size() * 131
	_load_node_types()
	_refresh()

func _load_node_types() -> void:
	_node_types = {}
	var path: String = "res://data/route/node_types.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_node_types = (parsed as Dictionary).get("types", {}) as Dictionary

func _refresh() -> void:
	layer_label.text = "当前层：%d / 6" % int(_state.current_layer)
	balls_label.text = "捕获球：%d" % int(_state.balls)
	coins_label.text = "征途币：%d" % int(_state.coins)
	reserve_label.text = "备用栏：%d 只" % (_state.reserve as Array).size()
	title_label.text = "肉鸽征途"
	_rebuild_route()

func _rebuild_route() -> void:
	for child in route_layers.get_children():
		child.queue_free()

	var graph: Array = _state.route_graph as Array
	var layers_sorted: Array = graph.duplicate()
	layers_sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("layer", 0)) > int(b.get("layer", 0))
	)

	for layer_entry_v in layers_sorted:
		var layer_entry: Dictionary = layer_entry_v as Dictionary
		var layer_num: int = int(layer_entry.get("layer", 0))
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)

		var layer_tag: Label = Label.new()
		layer_tag.text = "层 %d" % layer_num
		layer_tag.custom_minimum_size = Vector2(48, 0)
		layer_tag.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
		row.add_child(layer_tag)

		var nodes_box: HBoxContainer = HBoxContainer.new()
		nodes_box.alignment = BoxContainer.ALIGNMENT_CENTER
		nodes_box.add_theme_constant_override("separation", 8)
		for node_v in layer_entry.get("nodes", []) as Array:
			nodes_box.add_child(_make_node_button(node_v as Dictionary, layer_num))
		row.add_child(nodes_box)
		route_layers.add_child(row)

func _make_node_button(node: Dictionary, layer_num: int) -> Button:
	var node_id: String = String(node.get("id", ""))
	var node_type: String = String(node.get("type", ""))
	var meta: Dictionary = (_node_types.get(node_type, {}) as Dictionary)
	var icon: String = String(meta.get("icon", "?"))
	var display: String = String(meta.get("display", node_type))
	var btn: Button = Button.new()
	btn.text = "%s %s" % [icon, display]
	btn.custom_minimum_size = Vector2(110, 44)

	var completed: bool = (_state.selected_path as Array).has(node_id)
	var is_current_layer: bool = layer_num == int(_state.current_layer)
	var is_valid_type: bool = ALL_NODE_TYPES.has(node_type)

	if completed:
		MenuStyle.apply_button_styles(btn, Color(0.28, 0.28, 0.30), Color(0.32, 0.32, 0.34))
		btn.modulate = Color(0.55, 0.55, 0.55, 1.0)
		btn.disabled = true
	elif not is_current_layer or not is_valid_type:
		MenuStyle.apply_button_styles(btn, Color(0.30, 0.32, 0.36), Color(0.34, 0.36, 0.40))
		btn.disabled = true
	else:
		var base: Color = _color_from_hex(String(meta.get("color_hex", "#DCDCDC")))
		MenuStyle.apply_button_styles(btn, base.darkened(0.35), base.darkened(0.15))
		btn.pressed.connect(_on_node_pressed.bind(node_id, node_type, layer_num))

	return btn

func _color_from_hex(hex: String) -> Color:
	var cleaned: String = hex.strip_edges()
	if cleaned.begins_with("#"):
		cleaned = cleaned.substr(1)
	if cleaned.length() != 6:
		return Color(0.7, 0.7, 0.7)
	return Color(
		cleaned.substr(0, 2).hex_to_int() / 255.0,
		cleaned.substr(2, 2).hex_to_int() / 255.0,
		cleaned.substr(4, 2).hex_to_int() / 255.0
	)

func _on_node_pressed(node_id: String, node_type: String, layer_num: int) -> void:
	var next_scene: String = NodeHandlers.enter_node(node_type, node_id, layer_num, _rng)
	if next_scene.is_empty():
		hint_label.text = "无法进入该节点，请检查数据配置。"
		return
	get_tree().change_scene_to_file(next_scene)

func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
