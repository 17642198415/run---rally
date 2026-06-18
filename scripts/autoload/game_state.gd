extends Node

enum GameMode { NONE, CAMPAIGN, ROGUELIKE }
enum BattlePhase { DEPLOY, PLAYER_TURN, ENEMY_TURN, RESOLVE, END }

var current_mode: GameMode = GameMode.NONE
var current_battle_phase: BattlePhase = BattlePhase.DEPLOY
var stage_id := ""
var battle_context: Dictionary = {}
var return_scene_path: String = ""
var current_battle: Dictionary = {
	"stage_id": "",
	"balls_remaining": 0
}

signal balls_changed(remaining: int)

func reset() -> void:
	current_mode = GameMode.NONE
	current_battle_phase = BattlePhase.DEPLOY
	stage_id = ""
	battle_context = {}
	return_scene_path = ""
	current_battle = {"stage_id": "", "balls_remaining": 0}

func start_campaign_battle(target_stage_id: String, deploy_list: Array) -> void:
	current_mode = GameMode.CAMPAIGN
	stage_id = target_stage_id
	battle_context = {
		"deploy_list": deploy_list.duplicate(true)
	}
	return_scene_path = "res://scenes/campaign/stage_select.tscn"

func clear_battle_context() -> void:
	battle_context = {}
	current_mode = GameMode.NONE
	return_scene_path = ""

func set_battle_balls(stage_id_value: String, count: int) -> void:
	current_battle = {
		"stage_id": stage_id_value,
		"balls_remaining": maxi(0, count)
	}
	balls_changed.emit(int(current_battle["balls_remaining"]))

func decrement_ball() -> int:
	var n: int = int(current_battle.get("balls_remaining", 0))
	n = maxi(0, n - 1)
	current_battle["balls_remaining"] = n
	balls_changed.emit(n)
	return n

func get_balls_remaining() -> int:
	return int(current_battle.get("balls_remaining", 0))
