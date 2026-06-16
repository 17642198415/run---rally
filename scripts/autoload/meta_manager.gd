extends Node

var unlocked: Array[String] = []

func reset() -> void:
	unlocked = []

func set_unlocked(ids: Array) -> void:
	unlocked = []
	for id in ids:
		unlocked.append(String(id))

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)
