extends Control

const ShopCatalog = preload("res://scripts/roguelike/shop_catalog.gd")
const ROUTE_MAP_SCENE: String = "res://scenes/roguelike/route_map.tscn"

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var coins_label: Label = $Panel/VBox/CoinsLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var items_box: VBoxContainer = $Panel/VBox/ItemsBox
@onready var leave_btn: Button = $Panel/VBox/LeaveBtn

var _node_id: String = ""
var _shop_items: Array = []
var _purchased: Dictionary = {}

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	coins_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
	status_label.add_theme_color_override("font_color", MenuStyle.TEXT_HINT)
	MenuStyle.apply_button_styles(leave_btn, Color(0.22, 0.42, 0.72), Color(0.30, 0.52, 0.82))

	var gs: Node = get_node("/root/GameState")
	var pending: Dictionary = gs.pending_event_node as Dictionary
	_node_id = String(pending.get("run_node_id", ""))
	if _node_id.is_empty():
		get_tree().change_scene_to_file(ROUTE_MAP_SCENE)
		return

	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	var layer: int = int(pending.get("layer", state.current_layer))
	var roll_seed: int = int(state.seed) + layer * 1009 + _node_id.hash()
	_shop_items = ShopCatalog.roll_3(roll_seed)

	leave_btn.pressed.connect(_on_leave)
	_refresh()

func _refresh() -> void:
	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	coins_label.text = "征途币：%d" % int(state.coins)
	for child in items_box.get_children():
		child.queue_free()
	for i in range(_shop_items.size()):
		var item: Dictionary = _shop_items[i] as Dictionary
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label: Label = Label.new()
		label.text = "%s — %d 币" % [String(item.get("display", "")), int(item.get("cost", 0))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var buy_btn: Button = Button.new()
		var item_id: String = String(item.get("id", ""))
		var sold: bool = bool(_purchased.get(item_id, false))
		buy_btn.text = "已购" if sold else "购买"
		buy_btn.disabled = sold or not _can_afford(item) or not _can_apply(item)
		MenuStyle.apply_button_styles(buy_btn, Color(0.20, 0.48, 0.36), Color(0.28, 0.58, 0.44))
		buy_btn.pressed.connect(_on_buy.bind(i))
		row.add_child(buy_btn)
		items_box.add_child(row)

func _can_afford(item: Dictionary) -> bool:
	var rm: Node = get_node("/root/RunManager")
	return int(rm.get_state().coins) >= int(item.get("cost", 0))

func _can_apply(item: Dictionary) -> bool:
	return ShopCatalog.can_apply_item(item, _get_reserve().size())

func _on_buy(index: int) -> void:
	if index < 0 or index >= _shop_items.size():
		return
	var item: Dictionary = _shop_items[index] as Dictionary
	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	var loader: Node = get_node("/root/DataLoader")
	var result: Dictionary = ShopCatalog.try_purchase(
		item,
		state,
		rm,
		_node_id,
		_hero_max_hp(),
		loader
	)
	if not bool(result.get("ok", false)):
		status_label.text = "无法购买该商品。"
		return
	_purchased[String(item.get("id", ""))] = true
	rm.save()
	status_label.text = "购买成功：%s" % String(item.get("display", ""))
	_refresh()

func _hero_max_hp() -> int:
	var hero: Dictionary = get_node("/root/DataLoader").get_hero()
	return int((hero.get("stats", {}) as Dictionary).get("hp", 25))

func _get_reserve() -> Array:
	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	if state == null:
		return []
	return state.reserve as Array

func _on_leave() -> void:
	var rm: Node = get_node("/root/RunManager")
	rm.complete_event_node(_node_id)
	get_node("/root/GameState").pending_event_node = {}
	get_tree().change_scene_to_file(ROUTE_MAP_SCENE)
