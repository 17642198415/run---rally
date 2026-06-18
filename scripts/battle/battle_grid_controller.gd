extends Node2D

const TerrainTypes = preload("res://scripts/battle/terrain_types.gd")
const Grid = preload("res://scripts/battle/grid.gd")
const Pathfinding = preload("res://scripts/battle/pathfinding.gd")
const UnitView = preload("res://scripts/battle/unit_view.gd")
const BattleUnit = preload("res://scripts/battle/battle_unit.gd")
const BattleController = preload("res://scripts/battle/battle_controller.gd")
const AttackRange = preload("res://scripts/battle/attack_range.gd")

const CELL_SIZE: int = 64
const GRID_ORIGIN: Vector2 = Vector2(320, 64)
const MOVE_TWEEN_SECONDS: float = 0.2

const UNIT_VISUALS: Dictionary = {
	"HERO": ["旅", Color(0.95, 0.85, 0.30)],
	"M01": ["狐", Color(0.55, 0.85, 0.95)],
	"M02": ["龟", Color(0.75, 0.55, 0.35)],
	"M03": ["鹰", Color(0.65, 0.45, 0.85)]
}

enum InteractionState { IDLE, UNIT_SELECTED, TARGETING_MOVE, TARGETING_ATTACK, TARGETING_SKILL, TARGETING_CAPTURE }

var orchestrator: Node = null
var grid: RefCounted = null
var grid_backdrop: ColorRect = null
var world_root: Control = null
var grid_root: Control = null
var highlight_layer: Control = null
var units_root: Control = null
var hud_label: Label = null
var action_bar: Control = null
var faction_label: Label = null
var turn_banner: Control = null
var capture_prompt: Control = null
var balls_label: Label = null

var units: Array = []
var views: Dictionary = {}
var state: int = InteractionState.IDLE
var is_moving: bool = false
var selected_unit_id: String = ""
var current_targets: Array[Vector2i] = []
var victory_result: String = "none"
var last_log: String = ""
var deploy_phase_ref: RefCounted = null
var capture_target_id: String = ""

func _ready() -> void:
	_bind_scene_nodes()

func begin_stage(grid_ref: RefCounted, deploy: RefCounted) -> void:
	grid = grid_ref
	deploy_phase_ref = deploy
	units = []
	views = {}
	victory_result = "none"
	_ensure_world_nodes()
	_render_terrain()
	highlight_deploy_zone(deploy)
	_refresh_hud("点击左侧蓝色部署区放置单位，然后确认部署。")

func rebuild_units_list() -> void:
	units = []
	for uid in views.keys():
		var view: Control = views[uid] as Control
		if view != null and view.battle_unit != null:
			units.append(view.battle_unit)

func has_unit_view(unit: RefCounted) -> bool:
	return views.has(String(unit.unit_id))

func _bind_scene_nodes() -> void:
	var canvas: CanvasLayer = get_parent().get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas != null:
		action_bar = canvas.get_node_or_null("ActionBar") as Control
		# 优先从新卡片路径查找；缺失时回退到旧扁平路径
		hud_label = canvas.get_node_or_null("TurnCard/VBox/HudLabel") as Label
		if hud_label == null:
			hud_label = canvas.get_node_or_null("HudLabel") as Label
		faction_label = canvas.get_node_or_null("TurnCard/VBox/FactionLabel") as Label
		if faction_label == null:
			faction_label = canvas.get_node_or_null("FactionLabel") as Label
		balls_label = canvas.get_node_or_null("ObjectiveCard/VBox/BallsLabel") as Label
		if balls_label == null:
			balls_label = canvas.get_node_or_null("BallsLabel") as Label
		turn_banner = canvas.get_node_or_null("TurnBanner") as Control
		capture_prompt = canvas.get_node_or_null("CapturePrompt") as Control
		_apply_card_styles(canvas)
	if action_bar != null:
		if action_bar.has_signal("action_selected"):
			action_bar.action_selected.connect(_on_action_selected)
		if action_bar.has_signal("end_turn_pressed"):
			action_bar.end_turn_pressed.connect(_on_end_turn_pressed)
		if action_bar.has_signal("confirm_deploy_pressed"):
			action_bar.confirm_deploy_pressed.connect(_on_confirm_deploy_pressed)
		if action_bar.has_signal("capture_pressed"):
			action_bar.capture_pressed.connect(_on_capture_pressed)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("balls_changed"):
		gs.balls_changed.connect(_on_balls_changed)
		_refresh_balls_label()

func _apply_card_styles(canvas: CanvasLayer) -> void:
	var turn_card: PanelContainer = canvas.get_node_or_null("TurnCard") as PanelContainer
	var obj_card: PanelContainer = canvas.get_node_or_null("ObjectiveCard") as PanelContainer
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.15, 0.20, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.border_color = Color(0.38, 0.55, 0.82, 0.45)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	if turn_card != null:
		turn_card.add_theme_stylebox_override("panel", style.duplicate() as StyleBoxFlat)
	if obj_card != null:
		var obj_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		obj_style.border_color = Color(0.85, 0.65, 0.30, 0.55)
		obj_card.add_theme_stylebox_override("panel", obj_style)

func _on_end_turn_pressed() -> void:
	if orchestrator != null and orchestrator.has_method("on_end_turn"):
		orchestrator.on_end_turn()

func _on_confirm_deploy_pressed() -> void:
	if orchestrator != null and orchestrator.has_method("on_confirm_deploy"):
		orchestrator.on_confirm_deploy()

func _on_capture_pressed() -> void:
	var unit: RefCounted = _get_unit_by_id(selected_unit_id)
	if unit == null:
		return
	var targets: Array[Vector2i] = _get_capturable_adjacent_cells(unit)
	if targets.is_empty():
		return
	state = InteractionState.TARGETING_CAPTURE
	current_targets = targets
	_render_highlights(targets, TerrainTypes.HIGHLIGHT_CAPTURE)
	_refresh_hud("点击青色格子尝试捕捉。")

func _on_balls_changed(_remaining: int) -> void:
	_refresh_balls_label()
	_update_capture_button_state()

func _ensure_world_nodes() -> void:
	var canvas: CanvasLayer = get_parent().get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas == null:
		return
	world_root = canvas.get_node_or_null("WorldRoot") as Control
	if world_root == null:
		world_root = Control.new()
		world_root.name = "WorldRoot"
		world_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		world_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(world_root)
		var background: Node = canvas.get_node_or_null("Background")
		if background != null:
			canvas.move_child(world_root, background.get_index() + 1)
	grid_root = world_root.get_node_or_null("GridRoot") as Control
	if grid_root == null:
		grid_root = Control.new()
		grid_root.name = "GridRoot"
		grid_root.position = GRID_ORIGIN
		grid_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_root.add_child(grid_root)
	highlight_layer = world_root.get_node_or_null("HighlightLayer") as Control
	if highlight_layer == null:
		highlight_layer = Control.new()
		highlight_layer.name = "HighlightLayer"
		highlight_layer.position = GRID_ORIGIN
		highlight_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_root.add_child(highlight_layer)
	units_root = world_root.get_node_or_null("UnitsRoot") as Control
	if units_root == null:
		units_root = Control.new()
		units_root.name = "UnitsRoot"
		units_root.position = GRID_ORIGIN
		units_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		world_root.add_child(units_root)

func _unhandled_input(event: InputEvent) -> void:
	if victory_result != "none":
		return
	if orchestrator != null and orchestrator.get("allow_debug_tab") and orchestrator.allow_debug_tab:
		if event is InputEventKey and event.pressed and not event.echo:
			if (event as InputEventKey).keycode == KEY_TAB:
				get_viewport().set_input_as_handled()
				return
	if grid == null or is_moving:
		return
	if orchestrator != null and orchestrator.get("_enemy_turn_running") and orchestrator._enemy_turn_running:
		return
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var cell: Vector2i = _cell_from_mouse(mb.position)
	if not grid.in_bounds(cell):
		_clear_selection()
		return
	get_viewport().set_input_as_handled()
	if orchestrator != null and orchestrator.has_method("is_deploy_phase") and orchestrator.is_deploy_phase():
		orchestrator.handle_deploy_click(cell)
		return
	_handle_cell_click(cell)

func _handle_cell_click(cell: Vector2i) -> void:
	if orchestrator != null and orchestrator.has_method("is_player_turn") and not orchestrator.is_player_turn():
		return
	match state:
		InteractionState.IDLE:
			_try_select_unit_at(cell)
		InteractionState.UNIT_SELECTED:
			_try_select_unit_at(cell)
		InteractionState.TARGETING_MOVE:
			if _is_in_targets(cell):
				_move_selected_unit_to(cell)
			else:
				_clear_selection()
		InteractionState.TARGETING_ATTACK, InteractionState.TARGETING_SKILL:
			if _is_in_targets(cell):
				_strike_cell(cell)
			else:
				_clear_selection()
		InteractionState.TARGETING_CAPTURE:
			if _is_in_targets(cell):
				_request_capture_at(cell)
			else:
				_clear_selection()

func select_active_unit(unit: RefCounted) -> void:
	if unit == null:
		_clear_selection()
		return
	selected_unit_id = String(unit.unit_id)
	state = InteractionState.UNIT_SELECTED
	_clear_highlights()
	_update_selection_visuals()
	if action_bar != null:
		action_bar.show_for_unit(
			String(unit.display_name),
			int(unit.hp),
			int(unit.max_hp),
			BattleController.can_use_skill(unit)
		)
	_update_capture_button_state()

func _try_select_unit_at(cell: Vector2i) -> void:
	var unit: RefCounted = _get_unit_at(cell)
	if unit == null:
		_clear_selection()
		return
	if not BattleController.is_alive(unit):
		# 允许查看 downed_capturable 野怪（hp=0 但仍占格），让玩家能看 HP 0/x
		if not bool(unit.get("downed_capturable")):
			return
	var controllable: bool = false
	if orchestrator != null and orchestrator.has_method("can_control_unit"):
		controllable = orchestrator.can_control_unit(unit)
	if controllable:
		select_active_unit(unit)
		_refresh_hud("请选择下方行动按钮。")
	else:
		_select_for_inspect(unit)

func _select_for_inspect(unit: RefCounted) -> void:
	selected_unit_id = String(unit.unit_id)
	state = InteractionState.UNIT_SELECTED
	_clear_highlights()
	_update_selection_visuals()
	if action_bar != null:
		action_bar.show_for_unit(
			String(unit.display_name),
			int(unit.hp),
			int(unit.max_hp),
			false
		)
		if action_bar.has_method("set_view_only_mode"):
			action_bar.set_view_only_mode()
	if action_bar != null:
		action_bar.hide_capture_button()
	var label: String = "查看 %s（非当前行动单位）" % String(unit.display_name)
	if not unit.is_player:
		label = "查看敌方 %s" % String(unit.display_name)
	if bool(unit.get("downed_capturable")):
		label = "查看 %s（已击倒，可被相邻友军捕捉）" % String(unit.display_name)
	_refresh_hud(label)

func _on_action_selected(action: String) -> void:
	if selected_unit_id.is_empty():
		return
	var unit: RefCounted = _get_unit_by_id(selected_unit_id)
	if unit == null:
		return
	match action:
		"move":
			state = InteractionState.TARGETING_MOVE
			current_targets = Pathfinding.get_reachable(grid, unit.grid_pos, int(unit.mov), String(unit.unit_type), String(unit.unit_id))
			_render_highlights(current_targets, TerrainTypes.HIGHLIGHT_MOVE)
			_refresh_hud("点击蓝色格子移动。")
		"attack":
			state = InteractionState.TARGETING_ATTACK
			var atk_range: Dictionary = AttackRange.get_basic_attack_range(unit)
			current_targets = AttackRange.get_attack_targets(grid, unit.grid_pos, int(atk_range.min), int(atk_range.max))
			_render_highlights(current_targets, TerrainTypes.HIGHLIGHT_ATTACK)
			_refresh_hud("点击红色范围内的敌人攻击。")
		"skill":
			if not BattleController.can_use_skill(unit):
				_refresh_hud("技能冷却中。")
				return
			state = InteractionState.TARGETING_SKILL
			var skill: Dictionary = _data_loader().get_skill(String(unit.skill_id))
			var skill_range: Dictionary = AttackRange.get_skill_range(skill)
			current_targets = AttackRange.get_attack_targets(grid, unit.grid_pos, int(skill_range.min), int(skill_range.max))
			_render_highlights(current_targets, TerrainTypes.HIGHLIGHT_SKILL)
			_refresh_hud("点击范围内敌人释放 %s。" % String(skill.get("name", unit.skill_id)))
		"wait":
			_finish_unit_action(unit)

func _finish_unit_action(unit: RefCounted) -> void:
	_clear_selection()
	_refresh_hud("%s 结束行动。" % unit.display_name)
	if orchestrator != null and orchestrator.has_method("on_unit_action_completed"):
		orchestrator.on_unit_action_completed(unit)

func _strike_cell(cell: Vector2i) -> void:
	var attacker: RefCounted = _get_unit_by_id(selected_unit_id)
	var defender: RefCounted = _get_unit_at(cell)
	if attacker == null or defender == null:
		_clear_selection()
		return
	if attacker.is_player == defender.is_player:
		_clear_selection()
		return
	var damage: int = 0
	if state == InteractionState.TARGETING_SKILL:
		var skill: Dictionary = _data_loader().get_skill(String(attacker.skill_id))
		damage = BattleController.perform_skill(attacker, defender, grid, skill)
	else:
		damage = BattleController.perform_attack(attacker, defender, grid)
	last_log = "%s -> %s : %d dmg (HP %d)" % [attacker.display_name, defender.display_name, damage, defender.hp]
	_sync_view(defender)
	_sync_view(attacker)
	if BattleController.is_dead(defender) and not bool(defender.get("downed_capturable")):
		_remove_unit(defender)
	if orchestrator != null and orchestrator.has_method("is_battle_over"):
		pass
	victory_result = BattleController.check_victory(units)
	if victory_result != "none":
		show_victory(victory_result)
	else:
		_finish_unit_action(attacker)

func _move_selected_unit_to(target: Vector2i) -> void:
	var unit: RefCounted = _get_unit_by_id(selected_unit_id)
	var view: Control = views.get(selected_unit_id) as Control
	if unit == null or view == null:
		return
	is_moving = true
	_clear_highlights()
	var old_pos: Vector2i = unit.grid_pos
	grid.clear_occupant(old_pos)
	var target_world: Vector2 = view.get_world_position(target)
	var tween: Tween = create_tween()
	tween.tween_property(view, "position", target_world, MOVE_TWEEN_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_move_finished.bind(target, unit))

func _on_move_finished(target: Vector2i, unit: RefCounted) -> void:
	if unit == null:
		is_moving = false
		return
	unit.grid_pos = target
	grid.set_occupant(target, String(unit.unit_id))
	var view: Control = views.get(String(unit.unit_id)) as Control
	if view != null:
		view.set_grid_pos(target)
		_sync_view(unit)
	is_moving = false
	_finish_unit_action(unit)

func execute_ai_action(action: Dictionary, enemy: RefCounted) -> void:
	var action_type: String = String(action.get("action", "wait"))
	match action_type:
		"attack":
			var target: RefCounted = action.get("target_unit") as RefCounted
			if target != null:
				BattleController.perform_attack(enemy, target, grid)
				_sync_view(target)
				_sync_view(enemy)
				if BattleController.is_dead(target) and not bool(target.get("downed_capturable")):
					_remove_unit(target)
		"skill":
			var target_skill: RefCounted = action.get("target_unit") as RefCounted
			if target_skill != null:
				var skill: Dictionary = _data_loader().get_skill(String(enemy.skill_id))
				BattleController.perform_skill(enemy, target_skill, grid, skill)
				_sync_view(target_skill)
				_sync_view(enemy)
				if BattleController.is_dead(target_skill) and not bool(target_skill.get("downed_capturable")):
					_remove_unit(target_skill)
		"move":
			var cell: Vector2i = action.get("target_cell", enemy.grid_pos)
			if cell != enemy.grid_pos:
				await _ai_move_unit_to(enemy, cell)
		_:
			pass
	victory_result = BattleController.check_victory(units)
	if victory_result != "none":
		show_victory(victory_result)

func _ai_move_unit_to(unit: RefCounted, target: Vector2i) -> void:
	var view: Control = views.get(String(unit.unit_id)) as Control
	if view == null:
		return
	grid.clear_occupant(unit.grid_pos)
	unit.grid_pos = target
	grid.set_occupant(target, String(unit.unit_id))
	view.set_grid_pos(target)
	_sync_view(unit)
	await get_tree().create_timer(MOVE_TWEEN_SECONDS).timeout

func remove_unit_at(cell: Vector2i) -> void:
	var unit: RefCounted = _get_unit_at(cell)
	if unit == null:
		return
	grid.clear_occupant(cell)
	units.erase(unit)
	var view: Control = views.get(String(unit.unit_id)) as Control
	if view != null:
		views.erase(String(unit.unit_id))
		view.queue_free()

func spawn_unit(unit: RefCounted) -> void:
	if _get_unit_by_id(String(unit.unit_id)) != null:
		_sync_view(unit)
		return
	units.append(unit)
	var template_id: String = String(unit.template_id)
	var visual: Array = UNIT_VISUALS.get(template_id, ["?", Color(0.7, 0.7, 0.7)]) as Array
	var icon: String = String(visual[0])
	var color: Color = visual[1] as Color
	var view: Control = UnitView.new()
	view.name = String(unit.unit_id)
	units_root.add_child(view)
	view.setup_from_battle_unit(unit, icon, color)
	views[String(unit.unit_id)] = view

func highlight_deploy_zone(deploy: RefCounted) -> void:
	_clear_highlights()
	if deploy == null:
		return
	var zones: Array = deploy.grid.deploy_zones.get("player", [])
	var cells: Array[Vector2i] = []
	for cell_variant in zones:
		cells.append(cell_variant as Vector2i)
	_render_highlights(cells, TerrainTypes.HIGHLIGHT_DEPLOY)

func clear_highlights_only() -> void:
	_clear_highlights()

func update_turn_ui(round_number: int, active_name: String, phase_text: String) -> void:
	if turn_banner != null and turn_banner.has_method("update_banner"):
		turn_banner.update_banner(round_number, active_name, phase_text)
	if faction_label != null:
		faction_label.text = "%s  |  当前: %s" % [phase_text, active_name]

func _remove_unit(unit: RefCounted) -> void:
	BattleController.remove_dead_unit(units, unit, grid)
	var view: Control = views.get(String(unit.unit_id)) as Control
	if view != null:
		views.erase(String(unit.unit_id))
		view.queue_free()

func _clear_selection() -> void:
	clear_selection()

func clear_selection() -> void:
	state = InteractionState.IDLE
	selected_unit_id = ""
	current_targets = []
	_clear_highlights()
	_update_selection_visuals()
	if action_bar != null and orchestrator != null:
		if orchestrator.has_method("is_player_turn") and orchestrator.is_player_turn():
			if orchestrator.turn_manager.active_unit != null:
				var active: RefCounted = orchestrator.turn_manager.active_unit
				action_bar.show_for_unit(
					String(active.display_name),
					int(active.hp),
					int(active.max_hp),
					BattleController.can_use_skill(active)
				)
				if action_bar.has_method("set_player_turn_mode"):
					action_bar.set_player_turn_mode(true)
				selected_unit_id = String(active.unit_id)
				state = InteractionState.UNIT_SELECTED
				_update_selection_visuals()
				_update_capture_button_state()
			else:
				action_bar.set_player_turn_mode(true)
		elif orchestrator.has_method("is_deploy_phase") and orchestrator.is_deploy_phase():
			action_bar.set_deploy_mode(true, deploy_phase_ref.can_confirm() if deploy_phase_ref != null else false)

func _update_selection_visuals() -> void:
	for uid in views.keys():
		var view: Control = views[uid] as Control
		if view != null and view.has_method("set_selected"):
			view.set_selected(String(uid) == selected_unit_id)

func _get_unit_at(cell: Vector2i) -> RefCounted:
	for unit in units:
		if unit.grid_pos == cell and (BattleController.is_alive(unit) or bool(unit.get("downed_capturable"))):
			return unit
	return null

func _get_unit_by_id(unit_id: String) -> RefCounted:
	for unit in units:
		if String(unit.unit_id) == unit_id:
			return unit
	return null

func _sync_view(unit: RefCounted) -> void:
	var view: Control = views.get(String(unit.unit_id)) as Control
	if view != null and view.has_method("sync_from_battle_unit"):
		view.sync_from_battle_unit()

func _is_in_targets(cell: Vector2i) -> bool:
	for c in current_targets:
		if c == cell:
			return true
	return false

func _cell_from_mouse(screen_pos: Vector2) -> Vector2i:
	var local: Vector2 = (screen_pos - GRID_ORIGIN) / float(CELL_SIZE)
	return Vector2i(int(floor(local.x)), int(floor(local.y)))

func _render_terrain() -> void:
	if grid_root == null or grid == null:
		return
	for child in grid_root.get_children():
		child.queue_free()
	grid_backdrop = ColorRect.new()
	grid_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_root.add_child(grid_backdrop)
	var grid_px: int = grid.width * CELL_SIZE
	grid_backdrop.position = Vector2(-8, -8)
	grid_backdrop.size = Vector2(grid_px + 16, grid.height * CELL_SIZE + 16)
	grid_backdrop.color = TerrainTypes.GRID_BACKDROP
	var gap: int = TerrainTypes.GRID_GAP
	var art: Node = get_node_or_null("/root/ArtLoader")
	for y in grid.height:
		for x in grid.width:
			var terrain: int = grid.get_terrain(Vector2i(x, y))
			var tile_key: String = String(TerrainTypes.TILE_KEY_BY_TERRAIN.get(terrain, "plain"))
			if art != null:
				var tex_rect: TextureRect = TextureRect.new()
				tex_rect.size = Vector2(CELL_SIZE - gap, CELL_SIZE - gap)
				tex_rect.position = Vector2(x * CELL_SIZE + gap / 2, y * CELL_SIZE + gap / 2)
				tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
				tex_rect.texture = art.get_tile(tile_key)
				tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				grid_root.add_child(tex_rect)
			else:
				var rect: ColorRect = ColorRect.new()
				rect.size = Vector2(CELL_SIZE - gap, CELL_SIZE - gap)
				rect.position = Vector2(x * CELL_SIZE + gap / 2, y * CELL_SIZE + gap / 2)
				rect.color = TerrainTypes.COLOR_BY_TERRAIN.get(terrain, Color(1, 0, 1))
				rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				grid_root.add_child(rect)
	grid_root.move_child(grid_backdrop, 0)

func _render_highlights(cells: Array[Vector2i], color: Color) -> void:
	_clear_highlights()
	for cell in cells:
		var rect: ColorRect = ColorRect.new()
		rect.size = Vector2(CELL_SIZE - 8, CELL_SIZE - 8)
		rect.position = Vector2(cell.x * CELL_SIZE + 4, cell.y * CELL_SIZE + 4)
		rect.color = color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_layer.add_child(rect)
		_attach_breath_tween(rect)

func _attach_breath_tween(rect: ColorRect) -> void:
	var tween: Tween = create_tween()
	tween.set_loops()
	tween.tween_property(rect, "modulate:a", TerrainTypes.HIGHLIGHT_BREATH_MAX, TerrainTypes.HIGHLIGHT_BREATH_SECONDS * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rect, "modulate:a", TerrainTypes.HIGHLIGHT_BREATH_MIN, TerrainTypes.HIGHLIGHT_BREATH_SECONDS * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	rect.set_meta("breath_tween", tween)
	rect.tree_exiting.connect(func() -> void:
		var t: Tween = rect.get_meta("breath_tween") as Tween
		if t != null and t.is_valid():
			t.kill()
	)

func _clear_highlights() -> void:
	if highlight_layer == null:
		return
	for child in highlight_layer.get_children():
		if child.has_meta("breath_tween"):
			var t: Tween = child.get_meta("breath_tween") as Tween
			if t != null and t.is_valid():
				t.kill()
		child.queue_free()

func show_victory(result: String) -> void:
	_clear_selection()
	victory_result = result
	_refresh_hud("")

func _refresh_hud(extra: String) -> void:
	if hud_label == null:
		return
	var title: String = "Run & Rally  ·  DEBUG_01"
	if victory_result != "none":
		var win_text: String = "玩家胜利" if victory_result == "player" else "敌方胜利"
		hud_label.text = "%s\n\n★  %s  ★" % [title, win_text]
		hud_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	else:
		hud_label.text = "%s\n%s" % [title, extra]
		hud_label.add_theme_color_override("font_color", Color(0.90, 0.92, 0.96))

func _data_loader() -> Node:
	return get_node("/root/DataLoader")

func _get_capturable_adjacent_cells(unit: RefCounted) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if unit == null or grid == null:
		return cells
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for dir in dirs:
		var cell: Vector2i = unit.grid_pos + dir
		if not grid.in_bounds(cell):
			continue
		var occupant: RefCounted = _get_any_unit_at(cell)
		if occupant == null:
			continue
		if not bool(occupant.get("downed_capturable")):
			continue
		cells.append(cell)
	return cells

func _get_any_unit_at(cell: Vector2i) -> RefCounted:
	for unit in units:
		if unit.grid_pos == cell:
			return unit
	return null

func _update_capture_button_state() -> void:
	if action_bar == null:
		return
	if orchestrator == null or not orchestrator.has_method("is_player_turn") or not orchestrator.is_player_turn():
		action_bar.hide_capture_button()
		return
	var active_unit: RefCounted = null
	if orchestrator.turn_manager != null:
		active_unit = orchestrator.turn_manager.active_unit
	if active_unit == null or not active_unit.is_player:
		action_bar.hide_capture_button()
		return
	if not _can_capturer(active_unit):
		action_bar.hide_capture_button()
		return
	var selected: RefCounted = _get_unit_by_id(selected_unit_id)
	if selected != null and String(selected.unit_id) != String(active_unit.unit_id):
		action_bar.hide_capture_button()
		return
	var balls: int = _get_balls_remaining()
	var has_target: bool = not _get_capturable_adjacent_cells(active_unit).is_empty()
	action_bar.set_capture_enabled(has_target and balls > 0)

func _can_capturer(unit: RefCounted) -> bool:
	if unit == null:
		return false
	# 只有旅人(HERO)可以发起捕捉
	return String(unit.template_id) == "HERO"

func _get_balls_remaining() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.get_balls_remaining())

func _refresh_balls_label() -> void:
	if balls_label == null:
		return
	balls_label.text = "球: %d" % _get_balls_remaining()

func _request_capture_at(cell: Vector2i) -> void:
	var attacker: RefCounted = _get_unit_by_id(selected_unit_id)
	var target: RefCounted = _get_any_unit_at(cell)
	if attacker == null or target == null or not bool(target.get("downed_capturable")):
		_clear_selection()
		return
	if orchestrator == null or not orchestrator.has_method("on_capture_requested"):
		_clear_selection()
		return
	capture_target_id = String(target.unit_id)
	_clear_highlights()
	orchestrator.on_capture_requested(attacker, target)

func get_unit_by_id(unit_id: String) -> RefCounted:
	return _get_unit_by_id(unit_id)

func remove_captured_unit(unit: RefCounted) -> void:
	if unit == null:
		return
	BattleController.remove_unit(units, unit, grid)
	var view: Control = views.get(String(unit.unit_id)) as Control
	if view != null:
		views.erase(String(unit.unit_id))
		view.queue_free()
	capture_target_id = ""
