extends Node

const SAVE_PATH := "user://save_meta.json"

func get_default_save() -> Dictionary:
	return {
		"bestiary": {},
		"meta_unlocked": [],
		"stats": {},
		"campaign": {}
	}

func get_save_path() -> String:
	return SAVE_PATH

func load_meta() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return get_default_save()

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot read save file: %s" % SAVE_PATH)
		return get_default_save()

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file root must be an object: %s" % SAVE_PATH)
		return get_default_save()

	return parsed

func save_meta(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save file: %s" % SAVE_PATH)
		return false

	file.store_string(JSON.stringify(data, "  "))
	return true
