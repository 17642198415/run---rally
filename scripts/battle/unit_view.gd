extends Control

const CELL_SIZE: int = 64

const FRAME_PLAYER: Color = Color(0.38, 0.68, 0.98)
const FRAME_ENEMY: Color = Color(0.92, 0.42, 0.36)
const FRAME_DOWNED: Color = Color(0.30, 0.85, 0.95)
const FRAME_BG: Color = Color(0.12, 0.13, 0.18, 0.92)

const ACTED_MODULATE: Color = Color(0.55, 0.55, 0.6, 1.0)
const DOWNED_MODULATE: Color = Color(0.85, 0.85, 0.85, 0.9)

var unit_id: String = ""
var unit_type: String = "foot"
var mov: int = 4
var grid_pos: Vector2i = Vector2i.ZERO
var battle_unit: RefCounted = null

var _is_player: bool = true
var _selected: bool = false
var _acted: bool = false

var _frame_outer: ColorRect = null
var _frame_bg: ColorRect = null
var _sprite: TextureRect = null
var _label: Label = null
var _hp_bar_bg: ColorRect = null
var _hp_bar_fill: ColorRect = null
var _hp_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	size = Vector2(CELL_SIZE, CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_visual()
	_apply_grid_pos()

func setup(p_unit_id: String, p_unit_type: String, p_mov: int, p_grid_pos: Vector2i, label_text: String, body_color: Color) -> void:
	unit_id = p_unit_id
	unit_type = p_unit_type
	mov = p_mov
	grid_pos = p_grid_pos
	_ensure_visual()
	_label.text = label_text
	_apply_grid_pos()

func setup_from_battle_unit(bu: RefCounted, label_text: String, body_color: Color) -> void:
	battle_unit = bu
	_is_player = bool(bu.is_player)
	setup(String(bu.unit_id), String(bu.unit_type), int(bu.mov), bu.grid_pos, label_text, body_color)
	_apply_unit_texture(String(bu.template_id), label_text)
	sync_from_battle_unit()

func sync_from_battle_unit() -> void:
	if battle_unit == null:
		return
	grid_pos = battle_unit.grid_pos
	mov = int(battle_unit.mov)
	unit_type = String(battle_unit.unit_type)
	_apply_grid_pos()
	_update_hp_bar(int(battle_unit.hp), int(battle_unit.max_hp))
	_update_team_frame()

func set_selected(selected: bool) -> void:
	_selected = selected
	_update_team_frame()

func set_acted(acted: bool) -> void:
	_acted = acted
	_update_team_frame()

func set_grid_pos(pos: Vector2i) -> void:
	grid_pos = pos
	if battle_unit != null:
		battle_unit.grid_pos = pos
	_apply_grid_pos()

func get_world_position(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)

func _ensure_visual() -> void:
	if _frame_outer == null:
		_frame_outer = ColorRect.new()
		_frame_outer.position = Vector2(2, 2)
		_frame_outer.size = Vector2(CELL_SIZE - 4, CELL_SIZE - 4)
		_frame_outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_frame_outer)
	if _frame_bg == null:
		_frame_bg = ColorRect.new()
		_frame_bg.position = Vector2(5, 5)
		_frame_bg.size = Vector2(CELL_SIZE - 10, CELL_SIZE - 10)
		_frame_bg.color = FRAME_BG
		_frame_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_frame_bg)
	if _sprite == null:
		_sprite = TextureRect.new()
		_sprite.position = Vector2(6, 4)
		_sprite.size = Vector2(CELL_SIZE - 12, CELL_SIZE - 18)
		_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_sprite)
	if _label == null:
		_label = Label.new()
		_label.position = Vector2(6, 4)
		_label.size = Vector2(CELL_SIZE - 12, CELL_SIZE - 18)
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.text = "?"
		_label.add_theme_font_size_override("font_size", 22)
		_label.add_theme_color_override("font_color", Color(1, 1, 1))
		_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_label.add_theme_constant_override("outline_size", 4)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_label)
	if _hp_bar_bg == null:
		_hp_bar_bg = ColorRect.new()
		_hp_bar_bg.size = Vector2(CELL_SIZE - 12, 5)
		_hp_bar_bg.position = Vector2(6, CELL_SIZE - 11)
		_hp_bar_bg.color = Color(0.08, 0.10, 0.14, 0.9)
		_hp_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hp_bar_bg)
	if _hp_bar_fill == null:
		_hp_bar_fill = ColorRect.new()
		_hp_bar_fill.size = Vector2(CELL_SIZE - 12, 5)
		_hp_bar_fill.position = Vector2(6, CELL_SIZE - 11)
		_hp_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hp_bar_fill)

func _apply_unit_texture(template_id: String, fallback_label: String) -> void:
	var art: Node = get_node_or_null("/root/ArtLoader")
	if art != null:
		var tex: Texture2D = art.get_unit(template_id)
		_sprite.texture = tex
		_label.text = ""
	else:
		_sprite.texture = null
		_label.text = fallback_label

func _update_hp_bar(hp: int, max_hp: int) -> void:
	if _hp_bar_fill == null or max_hp <= 0:
		return
	var ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var target_w: float = (CELL_SIZE - 12) * ratio
	if _hp_tween != null and _hp_tween.is_valid():
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(_hp_bar_fill, "size:x", target_w, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if ratio > 0.55:
		_hp_bar_fill.color = Color(0.35, 0.82, 0.48)
	elif ratio > 0.25:
		_hp_bar_fill.color = Color(0.92, 0.72, 0.28)
	else:
		_hp_bar_fill.color = Color(0.88, 0.32, 0.30)

func _update_team_frame() -> void:
	if _frame_outer == null:
		return
	var downed: bool = battle_unit != null and bool(battle_unit.get("downed_capturable"))
	var frame: Color
	if downed:
		frame = FRAME_DOWNED
	elif _is_player:
		frame = FRAME_PLAYER
	else:
		frame = FRAME_ENEMY
	if _selected:
		frame = frame.lightened(0.22)
	_frame_outer.color = frame
	if downed:
		modulate = DOWNED_MODULATE
	elif _acted:
		modulate = ACTED_MODULATE
	else:
		modulate = Color(1, 1, 1, 1)

func _apply_grid_pos() -> void:
	position = get_world_position(grid_pos)
