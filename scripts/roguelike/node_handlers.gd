const EnemyGroupPicker = preload("res://scripts/roguelike/enemy_group_picker.gd")

const REST_SCENE: String = "res://scenes/roguelike/rest.tscn"
const SHOP_SCENE: String = "res://scenes/roguelike/shop.tscn"
const PARTY_SETUP_SCENE: String = "res://scenes/campaign/party_setup.tscn"
const CAPTURE_EVENT_PATH: String = "res://data/enemy_groups/capture_event.json"
const CAPTURE_EVENT_BONUS: float = 0.35

static func enter_node(
	node_type: String,
	node_id: String,
	layer: int,
	rng: RandomNumberGenerator
) -> String:
	var gs: Node = _game_state()
	if gs == null:
		return ""
	gs.set_pending_event_node(node_id, layer, node_type)
	match node_type:
		"rest":
			return REST_SCENE
		"shop":
			return SHOP_SCENE
		"capture_event":
			return _enter_capture_event(node_id, rng)
		"battle", "elite", "boss":
			return _enter_battle_node(node_id, layer, node_type, rng)
		_:
			push_error("NodeHandlers: unknown type %s" % node_type)
			return ""

static func _enter_battle_node(
	node_id: String,
	layer: int,
	node_type: String,
	rng: RandomNumberGenerator
) -> String:
	var is_elite: bool = node_type == "elite"
	var is_boss: bool = node_type == "boss"
	var pool_extras: Array = _meta_pool_extras()
	var group: Dictionary = EnemyGroupPicker.pick(layer, is_elite, is_boss, rng, pool_extras)
	var enemies: Array = group.get("enemies", []) as Array
	var map_template: String = String(group.get("map_template", ""))
	if enemies.is_empty() or map_template.is_empty():
		return ""
	var gs: Node = _game_state()
	gs.prepare_roguelike_node(node_id, enemies, map_template, is_elite, is_boss)
	return PARTY_SETUP_SCENE

static func _enter_capture_event(node_id: String, rng: RandomNumberGenerator) -> String:
	var group: Dictionary = _pick_capture_group(rng)
	var enemies: Array = group.get("enemies", []) as Array
	var map_template: String = String(group.get("map_template", "T_PLAIN"))
	if enemies.is_empty():
		return ""
	var gs: Node = _game_state()
	gs.prepare_roguelike_node(
		node_id,
		enemies,
		map_template,
		false,
		false,
		CAPTURE_EVENT_BONUS
	)
	return PARTY_SETUP_SCENE

static func _pick_capture_group(rng: RandomNumberGenerator) -> Dictionary:
	if not FileAccess.file_exists(CAPTURE_EVENT_PATH):
		push_error("NodeHandlers: capture_event.json missing")
		return {}
	var file := FileAccess.open(CAPTURE_EVENT_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var groups: Array = (parsed as Dictionary).get("groups", []) as Array
	if groups.is_empty():
		return {}
	var picked: Dictionary = _pick_weighted(groups, rng)
	var pool_extras: Array = _meta_pool_extras()
	if pool_extras.is_empty():
		return picked
	return EnemyGroupPicker.inject_pool_extras(picked, pool_extras, rng)

static func _pick_weighted(groups: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total: float = 0.0
	for g in groups:
		total += float((g as Dictionary).get("weight", 0))
	if total <= 0.0:
		return (groups[0] as Dictionary).duplicate(true)
	var roll: float = rng.randf_range(0.0, total)
	var cumulative: float = 0.0
	for g in groups:
		cumulative += float((g as Dictionary).get("weight", 0))
		if roll <= cumulative:
			return (g as Dictionary).duplicate(true)
	return (groups[groups.size() - 1] as Dictionary).duplicate(true)

static func _game_state() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("GameState")

static func _meta_pool_extras() -> Array:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return []
	var mm: Node = tree.root.get_node_or_null("MetaManager")
	if mm == null:
		return []
	return mm.get_pool_extras()
