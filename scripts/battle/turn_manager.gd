extends RefCounted

const BattleController = preload("res://scripts/battle/battle_controller.gd")

enum TurnPhase { DEPLOY, PLAYER_TURN, ENEMY_TURN, BATTLE_END }

var current_phase: int = TurnPhase.DEPLOY
var round_number: int = 1
var active_unit: RefCounted = null
var player_queue: Array = []
var enemy_queue: Array = []
var player_acted: Dictionary = {}
var enemy_index: int = 0

func reset() -> void:
	current_phase = TurnPhase.DEPLOY
	round_number = 1
	active_unit = null
	player_queue.clear()
	enemy_queue.clear()
	player_acted = {}
	enemy_index = 0

func build_queues(units: Array) -> void:
	player_queue.clear()
	enemy_queue.clear()
	for unit in units:
		if not BattleController.is_alive(unit):
			continue
		if unit.is_player:
			player_queue.append(unit)
		else:
			enemy_queue.append(unit)
	_sort_queue(player_queue)
	_sort_queue(enemy_queue)

func confirm_deploy(units: Array) -> void:
	build_queues(units)
	current_phase = TurnPhase.PLAYER_TURN
	round_number = 1
	_reset_player_acted()
	_set_next_active_player()

func _reset_player_acted() -> void:
	player_acted = {}
	for unit in player_queue:
		player_acted[String(unit.unit_id)] = false

func _sort_queue(queue: Array) -> void:
	queue.sort_custom(func(a: RefCounted, b: RefCounted) -> bool:
		if a.grid_pos.y != b.grid_pos.y:
			return a.grid_pos.y < b.grid_pos.y
		return a.grid_pos.x < b.grid_pos.x
	)

func _set_next_active_player() -> void:
	active_unit = null
	for unit in player_queue:
		if not BattleController.is_alive(unit):
			continue
		if not bool(player_acted.get(String(unit.unit_id), false)):
			active_unit = unit
			return

func mark_unit_acted(unit: RefCounted) -> void:
	if unit == null:
		return
	player_acted[String(unit.unit_id)] = true
	_set_next_active_player()

func end_player_turn() -> void:
	current_phase = TurnPhase.ENEMY_TURN
	active_unit = null
	enemy_index = 0
	_advance_enemy_index()

func _advance_enemy_index() -> void:
	active_unit = null
	while enemy_index < enemy_queue.size():
		var unit: RefCounted = enemy_queue[enemy_index] as RefCounted
		enemy_index += 1
		if unit != null and BattleController.is_alive(unit):
			active_unit = unit
			return

func advance_enemy_after_action() -> bool:
	_advance_enemy_index()
	return active_unit != null

func finish_enemy_turn(units: Array) -> void:
	if check_battle_end(units):
		return
	build_queues(units)
	current_phase = TurnPhase.PLAYER_TURN
	round_number += 1
	_reset_player_acted()
	_set_next_active_player()

func check_battle_end(units: Array) -> bool:
	var result: String = BattleController.check_victory(units)
	if result != "none":
		current_phase = TurnPhase.BATTLE_END
		active_unit = null
		return true
	return false

func can_control_unit(unit: RefCounted) -> bool:
	if current_phase != TurnPhase.PLAYER_TURN:
		return false
	if active_unit == null or unit == null:
		return false
	return String(unit.unit_id) == String(active_unit.unit_id)

func all_players_acted() -> bool:
	for unit in player_queue:
		if not BattleController.is_alive(unit):
			continue
		if not bool(player_acted.get(String(unit.unit_id), false)):
			return false
	return true
