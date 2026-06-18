extends Node

const UNITS_DIR := "res://data/units"
const SKILLS_DIR := "res://data/skills"
const STAGES_DIR := "res://data/stages"
const MAP_TEMPLATES_DIR := "res://data/map_templates"
const HERO_PATH := "res://data/hero.json"
const CAPTURE_CONFIG_PATH := "res://data/capture_config.json"
const Grid = preload("res://scripts/battle/grid.gd")

var units: Dictionary = {}
var skills: Dictionary = {}
var stages: Dictionary = {}
var hero: Dictionary = {}
var capture_config: Dictionary = {}
var loaded := false

func _ready() -> void:
	load_all()

func load_all() -> void:
	units = _load_json_dir(UNITS_DIR)
	skills = _load_json_dir(SKILLS_DIR)
	stages = _load_json_dir(STAGES_DIR)
	hero = _load_json_file(HERO_PATH)
	capture_config = _load_json_file(CAPTURE_CONFIG_PATH)
	loaded = true

func get_capture_config() -> Dictionary:
	_ensure_loaded()
	return capture_config.duplicate(true)

func get_unit(unit_id: String) -> Dictionary:
	_ensure_loaded()
	return units.get(unit_id, {}).duplicate(true)

func get_skill(skill_id: String) -> Dictionary:
	_ensure_loaded()
	return skills.get(skill_id, {}).duplicate(true)

func get_hero() -> Dictionary:
	_ensure_loaded()
	return hero.duplicate(true)

func get_all_unit_ids() -> Array[String]:
	_ensure_loaded()
	var ids: Array[String] = []
	for unit_id in units.keys():
		ids.append(String(unit_id))
	ids.sort()
	return ids

func get_stage(stage_id: String) -> Dictionary:
	_ensure_loaded()
	return stages.get(stage_id, {}).duplicate(true)

func load_stage_map(stage: Dictionary) -> RefCounted:
	_ensure_loaded()
	var template_name: String = String(stage.get("map_template", ""))
	if template_name.is_empty():
		push_error("Stage missing map_template.")
		return null
	var path: String = "%s/%s.json" % [MAP_TEMPLATES_DIR, template_name]
	if not FileAccess.file_exists(path):
		push_error("Map template not found: %s" % path)
		return null
	var data: Dictionary = _load_json_file(path)
	if data.is_empty():
		return null
	return Grid.from_template(data)

func _ensure_loaded() -> void:
	if not loaded:
		load_all()

func _load_json_dir(path: String) -> Dictionary:
	var result := {}
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Cannot open data directory: %s" % path)
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var data := _load_json_file("%s/%s" % [path, file_name])
			var id := String(data.get("id", ""))
			if id.is_empty():
				push_error("JSON file missing id: %s/%s" % [path, file_name])
			else:
				result[id] = data
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("JSON file does not exist: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot read JSON file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("JSON root must be an object: %s" % path)
		return {}

	return parsed
