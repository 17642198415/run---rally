extends Control

const SPECIES: Array[String] = ["M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08"]

@onready var grid: GridContainer = $Panel/VBox/SpeciesPanel/Grid
@onready var unlock_list: VBoxContainer = $Panel/VBox/UnlockPanel/UnlockList
@onready var species_panel: Control = $Panel/VBox/SpeciesPanel
@onready var unlock_panel: Control = $Panel/VBox/UnlockPanel
@onready var species_tab_btn: Button = $Panel/VBox/TabBar/SpeciesTabBtn
@onready var unlock_tab_btn: Button = $Panel/VBox/TabBar/UnlockTabBtn
@onready var back_btn: Button = $Panel/VBox/BackBtn
@onready var title_label: Label = $Panel/VBox/TitleLabel

var _active_tab: String = "species"

func _ready() -> void:
	MenuStyle.apply_page_shell(self)
	title_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
	MenuStyle.apply_button_styles(back_btn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))
	MenuStyle.apply_button_styles(species_tab_btn, Color(0.22, 0.42, 0.72), Color(0.30, 0.52, 0.82))
	MenuStyle.apply_button_styles(unlock_tab_btn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))
	species_tab_btn.pressed.connect(_on_species_tab)
	unlock_tab_btn.pressed.connect(_on_unlock_tab)
	back_btn.pressed.connect(_on_back)
	_show_tab("species")

func _show_tab(tab: String) -> void:
	_active_tab = tab
	species_panel.visible = tab == "species"
	unlock_panel.visible = tab == "unlock"
	if tab == "species":
		_refresh_species()
	else:
		_refresh_unlock_tab()

func _on_species_tab() -> void:
	_show_tab("species")

func _on_unlock_tab() -> void:
	_show_tab("unlock")

func _refresh_species() -> void:
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	var bestiary: Node = get_node("/root/BestiaryManager")
	bestiary.ensure_loaded()
	for child in grid.get_children():
		child.queue_free()
	for tid in SPECIES:
		var unit: Dictionary = loader.get_unit(tid)
		var name: String = String(unit.get("name", tid))
		var status_key: String
		if bestiary.is_caught(tid):
			status_key = "caught"
		elif bestiary.is_discovered(tid):
			status_key = "discovered"
		else:
			status_key = "unknown"
		grid.add_child(MenuStyle.build_bestiary_cell(tid, name, status_key))

func _refresh_unlock_tab() -> void:
	var mm: Node = get_node("/root/MetaManager")
	var save_mgr: Node = get_node("/root/SaveManager")
	var meta_snapshot: Dictionary = save_mgr.load_meta()
	for child in unlock_list.get_children():
		child.queue_free()
	for def_v in mm.get_definitions():
		var def: Dictionary = def_v as Dictionary
		var unlock_id: String = String(def.get("id", ""))
		var unlocked: bool = mm.is_unlocked(unlock_id)
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override(
			"panel",
			MenuStyle.make_card_style(
				MenuStyle.CardVariant.CLEARED if unlocked else MenuStyle.CardVariant.LOCKED
			)
		)
		card.custom_minimum_size = Vector2(0, 72)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var text_box: VBoxContainer = VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label: Label = Label.new()
		name_label.text = String(def.get("name", unlock_id))
		name_label.add_theme_color_override("font_color", MenuStyle.TEXT_PRIMARY)
		var desc_label: Label = Label.new()
		desc_label.text = String(def.get("desc", mm.condition_hint(def, meta_snapshot)))
		desc_label.add_theme_color_override("font_color", MenuStyle.TEXT_MUTED)
		text_box.add_child(name_label)
		text_box.add_child(desc_label)
		row.add_child(text_box)
		var badge: Label = Label.new()
		badge.text = "已解锁" if unlocked else "未解锁"
		badge.add_theme_color_override(
			"font_color",
			Color(0.36, 0.72, 0.45) if unlocked else Color(0.55, 0.58, 0.64)
		)
		row.add_child(badge)
		card.add_child(row)
		unlock_list.add_child(card)

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
