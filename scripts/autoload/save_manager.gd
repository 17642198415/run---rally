extends Node

const MetaManagerScript = preload("res://scripts/autoload/meta_manager.gd")

var SAVE_PATH: String = "user://save_meta.json"

func get_default_save() -> Dictionary:
	return {
		"bestiary": {},
		"party": {
			"reserve": [],
			"_seq_by_template": {}
		},
		"stats": {},
		"campaign": {},
		"meta": {
			"unlocked": []
		},
		"run": {
			"active": false,
			"state": null
		}
	}

func get_save_path() -> String:
	return SAVE_PATH

func set_save_path(path: String) -> void:
	SAVE_PATH = path

func merge_with_defaults(data: Dictionary) -> Dictionary:
	var defaults: Dictionary = get_default_save()
	var merged: Dictionary = data.duplicate(true)
	for key in defaults.keys():
		if not merged.has(key):
			merged[key] = (defaults[key] as Variant)
			continue
		var def_val: Variant = defaults[key]
		if typeof(def_val) != TYPE_DICTIONARY:
			continue
		var src: Dictionary = merged[key] as Dictionary
		var def_dict: Dictionary = def_val as Dictionary
		for sub_key in def_dict.keys():
			if not src.has(sub_key):
				src[sub_key] = def_dict[sub_key]
		merged[key] = src
	if merged.has("stats") and typeof(merged["stats"]) == TYPE_DICTIONARY:
		merged["stats"] = MetaManagerScript.normalize_stats(merged["stats"] as Dictionary)
	return merged

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

	return merge_with_defaults(parsed as Dictionary)

func save_meta(data: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write save file: %s" % SAVE_PATH)
		return false

	file.store_string(JSON.stringify(data, "  "))
	return true

func reset_to_default_for_tests() -> Dictionary:
	var defaults: Dictionary = get_default_save()
	save_meta(defaults)
	return defaults
