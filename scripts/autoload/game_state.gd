extends Node

enum GameMode { NONE, CAMPAIGN, ROGUELIKE }
enum BattlePhase { DEPLOY, PLAYER_TURN, ENEMY_TURN, RESOLVE, END }

var current_mode: GameMode = GameMode.NONE
var current_battle_phase: BattlePhase = BattlePhase.DEPLOY
var stage_id := ""
var battle_context: Dictionary = {}

func reset() -> void:
	current_mode = GameMode.NONE
	current_battle_phase = BattlePhase.DEPLOY
	stage_id = ""
	battle_context = {}
