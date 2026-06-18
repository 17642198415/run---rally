extends Node2D

const TurnManager = preload("res://scripts/battle/turn_manager.gd")
const DeployPhase = preload("res://scripts/battle/deploy_phase.gd")
const EnemyAI = preload("res://scripts/battle/enemy_ai.gd")
const BattleController = preload("res://scripts/battle/battle_controller.gd")
const CaptureSystem = preload("res://scripts/battle/capture_system.gd")

@export var stage_id: String = "DEBUG_01"
@export var allow_debug_tab: bool = false

@onready var grid_controller: Node2D = $GridController

var turn_manager: RefCounted = null
var deploy_phase: RefCounted = null
var stage_data: Dictionary = {}
var _enemy_turn_running: bool = false
var _capture_rng: RandomNumberGenerator = null
var _pending_capture: Dictionary = {}
var _capture_prompt: Control = null

func _ready() -> void:
	turn_manager = TurnManager.new()
	deploy_phase = DeployPhase.new()
	_capture_rng = RandomNumberGenerator.new()
	_capture_rng.randomize()
	grid_controller.orchestrator = self
	_bind_capture_prompt()
	_begin_stage()

func _bind_capture_prompt() -> void:
	var canvas: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas == null:
		return
	_capture_prompt = canvas.get_node_or_null("CapturePrompt") as Control
	if _capture_prompt == null:
		return
	if _capture_prompt.has_signal("confirmed"):
		_capture_prompt.confirmed.connect(_on_capture_confirmed)
	if _capture_prompt.has_signal("cancelled"):
		_capture_prompt.cancelled.connect(_on_capture_cancelled)

func _begin_stage() -> void:
	var loader: Node = get_node("/root/DataLoader")
	loader.load_all()
	var gs: Node = get_node("/root/GameState")
	if gs.current_mode == gs.GameMode.CAMPAIGN and not String(gs.stage_id).is_empty():
		stage_id = String(gs.stage_id)
	stage_data = loader.get_stage(stage_id)
	if stage_data.is_empty():
		push_error("Stage not found: %s" % stage_id)
		return
	var grid: RefCounted = loader.load_stage_map(stage_data)
	if grid == null:
		push_error("Failed to load map for stage %s" % stage_id)
		return
	deploy_phase.setup(stage_data, grid)
	turn_manager.reset()
	_sync_game_state(TurnManager.TurnPhase.DEPLOY)
	_init_balls_for_stage()
	_mark_stage_enemies_discovered()
	grid_controller.begin_stage(grid, deploy_phase)
	_update_ui()

func _init_balls_for_stage() -> void:
	var balls: int = 3
	var player_block: Variant = stage_data.get("player", null)
	if typeof(player_block) == TYPE_DICTIONARY and (player_block as Dictionary).has("balls"):
		balls = int((player_block as Dictionary).get("balls", 3))
	elif stage_data.has("player_ball_count"):
		balls = int(stage_data.get("player_ball_count", 3))
	var gs: Node = get_node("/root/GameState")
	gs.set_battle_balls(stage_id, balls)

func _mark_stage_enemies_discovered() -> void:
	var bestiary: Node = get_node_or_null("/root/BestiaryManager")
	if bestiary == null:
		return
	for enemy_def in stage_data.get("enemy_units", []):
		var template_id: String = String((enemy_def as Dictionary).get("template", ""))
		if not template_id.is_empty():
			bestiary.mark_discovered(template_id)

func get_turn_phase() -> int:
	return turn_manager.current_phase

func can_control_unit(unit: RefCounted) -> bool:
	if _enemy_turn_running:
		return false
	return turn_manager.can_control_unit(unit)

func is_deploy_phase() -> bool:
	return turn_manager.current_phase == TurnManager.TurnPhase.DEPLOY

func is_player_turn() -> bool:
	return turn_manager.current_phase == TurnManager.TurnPhase.PLAYER_TURN

func is_battle_over() -> bool:
	return turn_manager.current_phase == TurnManager.TurnPhase.BATTLE_END

func handle_deploy_click(cell: Vector2i) -> void:
	if not is_deploy_phase():
		return
	if deploy_phase.placed_cells.has(cell):
		deploy_phase.remove_at(cell)
		grid_controller.remove_unit_at(cell)
	else:
		var next_index: int = deploy_phase.get_next_unplaced_index()
		if next_index < 0:
			return
		var unit: RefCounted = deploy_phase.place_at(cell, next_index)
		if unit != null:
			grid_controller.spawn_unit(unit)
	grid_controller.highlight_deploy_zone(deploy_phase)
	_update_ui()

func on_confirm_deploy() -> void:
	if not is_deploy_phase() or not deploy_phase.can_confirm():
		return
	var enemies: Array = deploy_phase.spawn_enemies()
	for enemy in enemies:
		grid_controller.spawn_unit(enemy)
	grid_controller.rebuild_units_list()
	turn_manager.confirm_deploy(grid_controller.units)
	_sync_game_state(TurnManager.TurnPhase.PLAYER_TURN)
	grid_controller.clear_highlights_only()
	grid_controller.select_active_unit(turn_manager.active_unit)
	_update_ui()

func on_unit_action_completed(unit: RefCounted) -> void:
	if unit == null:
		return
	BattleController.tick_cooldown(unit)
	turn_manager.mark_unit_acted(unit)
	if turn_manager.check_battle_end(grid_controller.units):
		_on_battle_end()
		return
	grid_controller.select_active_unit(turn_manager.active_unit)
	_update_ui()

func on_capture_requested(attacker: RefCounted, target: RefCounted) -> void:
	if attacker == null or target == null:
		return
	if not bool(target.get("downed_capturable")):
		return
	var balls: int = _get_balls()
	if balls <= 0:
		return
	_pending_capture = {
		"attacker_id": String(attacker.unit_id),
		"target_id": String(target.unit_id)
	}
	if _capture_prompt == null:
		_resolve_capture()
		return
	var rate: float = CaptureSystem.compute_rate(target, _get_event_bonus())
	var tier: String = CaptureSystem.tier_for_rate(rate)
	_capture_prompt.show_prompt(String(target.display_name), int(target.hp), int(target.max_hp), rate, tier, balls)

func _on_capture_confirmed() -> void:
	_resolve_capture()

func _on_capture_cancelled() -> void:
	_pending_capture = {}

func _resolve_capture() -> void:
	if _pending_capture.is_empty():
		return
	var attacker_id: String = String(_pending_capture.get("attacker_id", ""))
	var target_id: String = String(_pending_capture.get("target_id", ""))
	_pending_capture = {}
	var attacker: RefCounted = grid_controller.get_unit_by_id(attacker_id)
	var target: RefCounted = grid_controller.get_unit_by_id(target_id)
	if attacker == null or target == null:
		return
	var balls_before: int = _get_balls()
	var result: Dictionary = CaptureSystem.attempt(target, balls_before, _get_event_bonus(), _capture_rng)
	if String(result.get("error", "")) == "no_balls":
		return
	var gs: Node = get_node("/root/GameState")
	gs.decrement_ball()
	var success: bool = bool(result.get("success", false))
	if success:
		_apply_successful_capture(target)
	_persist_save()
	if turn_manager.check_battle_end(grid_controller.units):
		_on_battle_end()
		return
	on_unit_action_completed(attacker)

func _apply_successful_capture(target: RefCounted) -> void:
	var party: Node = get_node_or_null("/root/PartyManager")
	var bestiary: Node = get_node_or_null("/root/BestiaryManager")
	if party != null and party.can_accept():
		party.add_capture(
			String(target.template_id),
			int(target.max_hp),
			int(target.max_hp),
			String(target.skill_id)
		)
	if bestiary != null:
		bestiary.mark_caught(String(target.template_id))
	grid_controller.remove_captured_unit(target)

func _persist_save() -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr == null:
		return
	save_mgr.save_meta(_assemble_save_dict())

func _assemble_save_dict() -> Dictionary:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	var data: Dictionary = save_mgr.get_default_save() if save_mgr != null else {}
	var bestiary: Node = get_node_or_null("/root/BestiaryManager")
	if bestiary != null:
		data["bestiary"] = bestiary.to_dict()
	var party: Node = get_node_or_null("/root/PartyManager")
	if party != null:
		data["party"] = party.to_dict()
	var campaign: Node = get_node_or_null("/root/CampaignManager")
	if campaign != null:
		data["campaign"] = campaign.to_dict()
	return data

func _get_balls() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.get_balls_remaining())

func _get_event_bonus() -> float:
	var loader: Node = get_node_or_null("/root/DataLoader")
	if loader == null:
		return 0.0
	var cfg: Dictionary = loader.get_capture_config()
	return float(cfg.get("event_bonus_default", 0.0))

func on_end_turn() -> void:
	if not is_player_turn() or _enemy_turn_running:
		return
	turn_manager.end_player_turn()
	_sync_game_state(TurnManager.TurnPhase.ENEMY_TURN)
	grid_controller.clear_selection()
	_update_ui()
	_run_enemy_turn()

func _run_enemy_turn() -> void:
	if _enemy_turn_running:
		return
	_enemy_turn_running = true
	while turn_manager.current_phase == TurnManager.TurnPhase.ENEMY_TURN:
		var enemy: RefCounted = turn_manager.active_unit
		if enemy == null:
			break
		var profile: String = String(stage_data.get("ai_profile", ""))
		var action: Dictionary = EnemyAI.decide_action(enemy, grid_controller.grid, grid_controller.units, profile)
		await grid_controller.execute_ai_action(action, enemy)
		BattleController.tick_cooldown(enemy)
		if turn_manager.check_battle_end(grid_controller.units):
			break
		if not turn_manager.advance_enemy_after_action():
			break
		await get_tree().create_timer(0.35).timeout
	turn_manager.finish_enemy_turn(grid_controller.units)
	_enemy_turn_running = false
	if turn_manager.current_phase == TurnManager.TurnPhase.BATTLE_END:
		_on_battle_end()
	else:
		_sync_game_state(TurnManager.TurnPhase.PLAYER_TURN)
		grid_controller.select_active_unit(turn_manager.active_unit)
	_update_ui()

func _on_battle_end() -> void:
	_sync_game_state(TurnManager.TurnPhase.BATTLE_END)
	var result: String = BattleController.check_victory(grid_controller.units)
	grid_controller.show_victory(result)
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null:
		var data: Dictionary = _assemble_save_dict()
		var stats: Dictionary = data.get("stats", {}) as Dictionary
		if result == "player":
			stats["battles_won"] = int(stats.get("battles_won", 0)) + 1
		data["stats"] = stats
		save_mgr.save_meta(data)
	_handle_campaign_battle_end(result)
	_update_ui()

func _handle_campaign_battle_end(result: String) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or gs.current_mode != gs.GameMode.CAMPAIGN:
		return
	if result == "player":
		var campaign: Node = get_node_or_null("/root/CampaignManager")
		if campaign != null:
			var unlock_next: String = String(stage_data.get("unlock_next", ""))
			campaign.mark_cleared(stage_id, unlock_next)
			var save_mgr: Node = get_node_or_null("/root/SaveManager")
			if save_mgr != null:
				var data: Dictionary = _assemble_save_dict()
				data["campaign"] = campaign.to_dict()
				save_mgr.save_meta(data)
	var return_path: String = String(gs.return_scene_path)
	if return_path.is_empty():
		return_path = "res://scenes/campaign/stage_select.tscn"
	gs.clear_battle_context()
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_inside_tree():
			get_tree().change_scene_to_file(return_path)
	)

func _sync_game_state(phase: int) -> void:
	var gs: Node = get_node("/root/GameState")
	gs.stage_id = stage_id
	match phase:
		TurnManager.TurnPhase.DEPLOY:
			gs.current_battle_phase = gs.BattlePhase.DEPLOY
		TurnManager.TurnPhase.PLAYER_TURN:
			gs.current_battle_phase = gs.BattlePhase.PLAYER_TURN
		TurnManager.TurnPhase.ENEMY_TURN:
			gs.current_battle_phase = gs.BattlePhase.ENEMY_TURN
		TurnManager.TurnPhase.BATTLE_END:
			gs.current_battle_phase = gs.BattlePhase.END

func _update_ui() -> void:
	var phase_text: String = "部署阶段"
	var active_name: String = "—"
	match turn_manager.current_phase:
		TurnManager.TurnPhase.PLAYER_TURN:
			phase_text = "玩家回合"
			if turn_manager.active_unit != null:
				active_name = String(turn_manager.active_unit.display_name)
		TurnManager.TurnPhase.ENEMY_TURN:
			phase_text = "敌方回合"
			if turn_manager.active_unit != null:
				active_name = String(turn_manager.active_unit.display_name)
		TurnManager.TurnPhase.BATTLE_END:
			phase_text = "战斗结束"
	grid_controller.update_turn_ui(turn_manager.round_number, active_name, phase_text)
	if grid_controller.action_bar == null:
		return
	match turn_manager.current_phase:
		TurnManager.TurnPhase.DEPLOY:
			grid_controller.action_bar.set_deploy_mode(true, deploy_phase.can_confirm())
		TurnManager.TurnPhase.PLAYER_TURN:
			grid_controller.action_bar.set_player_turn_mode(true)
			if turn_manager.active_unit != null:
				var unit: RefCounted = turn_manager.active_unit
				grid_controller.action_bar.show_for_unit(
					String(unit.display_name),
					int(unit.hp),
					int(unit.max_hp),
					BattleController.can_use_skill(unit)
				)
		_:
			grid_controller.action_bar.set_enemy_turn_hidden()
