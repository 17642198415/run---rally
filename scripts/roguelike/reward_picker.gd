extends Control

const ROUTE_MAP_SCENE: String = "res://scenes/roguelike/route_map.tscn"
const RUN_SUMMARY_SCENE: String = "res://scenes/roguelike/run_summary.tscn"

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var cards_box: HBoxContainer = $Panel/VBox/CardsBox
@onready var target_list: ItemList = $Panel/VBox/TargetList
@onready var confirm_btn: Button = $Panel/VBox/ConfirmBtn

var _rewards: Array = []
var _selected_reward: Dictionary = {}
var _selected_target_id: String = ""

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	status_label.add_theme_color_override("font_color", MenuStyle.TEXT_HINT)
	MenuStyle.apply_button_styles(confirm_btn, Color(0.22, 0.42, 0.72), Color(0.30, 0.52, 0.82))
	confirm_btn.pressed.connect(_on_confirm)
	target_list.item_selected.connect(_on_target_selected)

	var rm: Node = get_node("/root/RunManager")
	if not rm.has_pending_rewards():
		_go_next()
		return

	_rewards = rm.get_pending_rewards()
	_build_cards()

func _build_cards() -> void:
	for child in cards_box.get_children():
		child.queue_free()
	for reward_v in _rewards:
		var reward: Dictionary = reward_v as Dictionary
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(200, 120)
		btn.text = "%s\n%s" % [
			String(reward.get("name", "")),
			String(reward.get("desc", ""))
		]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var needs_target: bool = _needs_target(reward)
		var can_pick: bool = not needs_target or not _get_reserve().is_empty()
		btn.disabled = not can_pick
		MenuStyle.apply_button_styles(btn, Color(0.20, 0.48, 0.36), Color(0.28, 0.58, 0.44))
		btn.pressed.connect(_on_card_pressed.bind(reward.duplicate(true)))
		cards_box.add_child(btn)

func _needs_target(reward: Dictionary) -> bool:
	var effect: Dictionary = reward.get("effect", {}) as Dictionary
	return String(effect.get("target", "")) == "one_pet"

func _get_reserve() -> Array:
	var rm: Node = get_node("/root/RunManager")
	var state: Resource = rm.get_state()
	if state == null:
		return []
	return state.reserve as Array

func _on_card_pressed(reward: Dictionary) -> void:
	_selected_reward = reward
	_selected_target_id = ""
	if _needs_target(reward):
		_show_target_picker()
		return
	_apply_and_leave("")

func _show_target_picker() -> void:
	target_list.clear()
	target_list.visible = true
	confirm_btn.visible = true
	status_label.text = "选择要强化的灵兽"
	for entry_v in _get_reserve():
		var entry: Dictionary = entry_v as Dictionary
		var uid: String = String(entry.get("unit_id", ""))
		var label: String = "%s  HP %d/%d" % [
			String(entry.get("template_id", "")),
			int(entry.get("hp", 0)),
			int(entry.get("max_hp", 0))
		]
		target_list.add_item(label)
		target_list.set_item_metadata(target_list.item_count - 1, uid)

func _on_target_selected(index: int) -> void:
	_selected_target_id = String(target_list.get_item_metadata(index))

func _on_confirm() -> void:
	if _selected_reward.is_empty() or _selected_target_id.is_empty():
		status_label.text = "请先选择灵兽"
		return
	_apply_and_leave(_selected_target_id)

func _apply_and_leave(target_unit_id: String) -> void:
	var rm: Node = get_node("/root/RunManager")
	var reward_id: String = String(_selected_reward.get("id", ""))
	if reward_id.is_empty():
		_go_next()
		return
	if not rm.apply_reward_choice(reward_id, target_unit_id):
		status_label.text = "无法应用该奖励"
		return
	_go_next()

func _go_next() -> void:
	var rm: Node = get_node("/root/RunManager")
	var outcome: Dictionary = rm.get_last_outcome()
	if bool(outcome.get("victory", false)):
		get_tree().change_scene_to_file(RUN_SUMMARY_SCENE)
	else:
		get_tree().change_scene_to_file(ROUTE_MAP_SCENE)
