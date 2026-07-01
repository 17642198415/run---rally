extends RefCounted

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const RewardPool = preload("res://scripts/roguelike/reward_pool.gd")
const RouteGenerator = preload("res://scripts/roguelike/route_generator.gd")

const TEST_SAVE_PATH: String = "user://ui_test_save.json"

const ROUTE_NODE_DISPLAY: Dictionary = {
	"battle": "普通战",
	"elite": "精英战",
	"rest": "休息",
	"shop": "商店",
	"capture_event": "捕捉",
	"boss": "BOSS"
}

var _tree: SceneTree
var _checks: Assertions

func _init(tree: SceneTree, checks: Assertions) -> void:
	_tree = tree
	_checks = checks

func change_scene(scene_path: String) -> void:
	var err: Error = _tree.change_scene_to_file(scene_path)
	_checks.assert_true(err == OK, "change_scene failed for %s (err=%s)" % [scene_path, str(err)])

func await_idle(frames: int = 3) -> void:
	for _i in frames:
		await _tree.process_frame

func get_current_scene() -> Node:
	return _tree.current_scene

func current_scene_path() -> String:
	var scene: Node = _tree.current_scene
	if scene == null:
		return ""
	return scene.scene_file_path

func assert_current_scene(expected_path: String, message: String) -> void:
	var actual: String = current_scene_path()
	_checks.assert_equal(actual, expected_path, message)

func find_button(root: Node, node_name: String) -> Button:
	var node: Node = root.find_child(node_name, true, false)
	return node as Button

func find_first_button(root: Node) -> Button:
	var buttons: Array[Node] = root.find_children("*", "Button", true, false)
	if buttons.is_empty():
		return null
	return buttons[0] as Button

func press_button(btn: Button, label: String = "button") -> void:
	_checks.assert_true(btn != null, "missing %s" % label)
	if btn != null:
		btn.pressed.emit()

func reset_save_defaults() -> void:
	var save: Node = _tree.root.get_node("SaveManager")
	save.set_save_path(TEST_SAVE_PATH)
	save.reset_to_default_for_tests()
	_reload_managers_from_save()

func _reload_managers_from_save() -> void:
	var save: Node = _tree.root.get_node("SaveManager")
	var data: Dictionary = save.load_meta()
	_tree.root.get_node("GameState").reset()
	_tree.root.get_node("CampaignManager").from_dict(data.get("campaign", {}) as Dictionary)
	_tree.root.get_node("PartyManager").from_dict(data.get("party", {}) as Dictionary)
	_tree.root.get_node("BestiaryManager").from_dict(data.get("bestiary", {}) as Dictionary)
	_tree.root.get_node("MetaManager").from_dict(data.get("meta", {}) as Dictionary)
	_tree.root.get_node("RunManager").load_from_meta()

func setup_active_run(seed: int) -> void:
	var rm: Node = _tree.root.get_node("RunManager")
	rm.start_new_run(seed)
	rm.save()

func setup_run_at_layer(seed: int, layer: int) -> void:
	setup_active_run(seed)
	var rm: Node = _tree.root.get_node("RunManager")
	var state: Resource = rm.get_state()
	state.current_layer = layer
	state.selected_path = []
	rm.save()

func setup_run_for_node_type(node_type: String) -> int:
	for seed in range(200):
		var graph: Array = RouteGenerator.generate(seed)
		for layer_entry_v in graph:
			var layer_entry: Dictionary = layer_entry_v as Dictionary
			var layer_num: int = int(layer_entry.get("layer", 0))
			for node_v in layer_entry.get("nodes", []) as Array:
				var node: Dictionary = node_v as Dictionary
				if String(node.get("type", "")) == node_type:
					setup_run_at_layer(seed, layer_num)
					return seed
	_checks.assert_true(false, "no seed with node type %s" % node_type)
	return -1

func assert_new_run_roster() -> void:
	var rm: Node = _tree.root.get_node("RunManager")
	var state: Resource = rm.get_state()
	_checks.assert_true(state != null, "active run state")
	if state == null:
		return
	var party: Array = state.party as Array
	var reserve: Array = state.reserve as Array
	_checks.assert_equal(party.size(), 1, "R2 party size 1")
	_checks.assert_equal(reserve.size(), 0, "R2 reserve empty")
	if not party.is_empty():
		var hero: Dictionary = party[0] as Dictionary
		_checks.assert_equal(String(hero.get("template_id", "")), "HERO", "R2 hero only")

func count_route_map_nodes() -> int:
	var scene: Node = get_current_scene()
	if scene == null:
		return 0
	var route_layers: Node = scene.find_child("RouteLayers", true, false)
	if route_layers == null:
		return 0
	return route_layers.find_children("*", "Button", true, false).size()

func route_map_has_boss_node() -> bool:
	var scene: Node = get_current_scene()
	if scene == null:
		return false
	var route_layers: Node = scene.find_child("RouteLayers", true, false)
	if route_layers == null:
		return false
	for btn_v in route_layers.find_children("*", "Button", true, false):
		var btn: Button = btn_v as Button
		if "BOSS" in btn.text:
			return true
	return false

func press_route_node_on_current_layer(node_type: String) -> void:
	var display: String = String(ROUTE_NODE_DISPLAY.get(node_type, node_type))
	var scene: Node = get_current_scene()
	var route_layers: Node = scene.find_child("RouteLayers", true, false)
	_checks.assert_true(route_layers != null, "RouteLayers exists")
	if route_layers == null:
		return
	for btn_v in route_layers.find_children("*", "Button", true, false):
		var btn: Button = btn_v as Button
		if btn.disabled:
			continue
		if display in btn.text:
			press_button(btn, "route node %s" % node_type)
			return
	_checks.assert_true(false, "no enabled route node %s" % node_type)

func press_first_reward_card() -> void:
	var scene: Node = get_current_scene()
	var cards_box: Node = scene.find_child("CardsBox", true, false)
	_checks.assert_true(cards_box != null, "CardsBox exists")
	if cards_box == null:
		return
	for child in cards_box.get_children():
		var btn: Button = child as Button
		if btn != null and not btn.disabled:
			press_button(btn, "reward card")
			return
	_checks.assert_true(false, "no enabled reward card")

func setup_meta_unlocked(unlock_ids: Array[String]) -> void:
	var save: Node = _tree.root.get_node("SaveManager")
	var data: Dictionary = save.load_meta()
	var mm: Node = _tree.root.get_node("MetaManager")
	mm.set_unlocked(unlock_ids)
	data["meta"] = {"unlocked": unlock_ids.duplicate()}
	save.save_meta(data)
	mm.from_dict(data.get("meta", {}) as Dictionary)

func setup_campaign_stage_status(status_map: Dictionary) -> void:
	var save: Node = _tree.root.get_node("SaveManager")
	var data: Dictionary = save.load_meta()
	data["campaign"] = status_map.duplicate(true)
	save.save_meta(data)
	_tree.root.get_node("CampaignManager").from_dict(status_map)

func setup_pending_event(node_id: String, layer: int, node_type: String) -> void:
	setup_active_run(42)
	var gs: Node = _tree.root.get_node("GameState")
	gs.set_pending_event_node(node_id, layer, node_type)

func setup_pending_rewards(seed: int, is_boss: bool) -> void:
	var rm: Node = _tree.root.get_node("RunManager")
	rm.start_new_run(seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var state: Resource = rm.get_state()
	state.pending_rewards = RewardPool.pick_three(rng, is_boss)
	rm.save()

func setup_run_summary_context(victory: bool, hero_dead: bool) -> void:
	var rm: Node = _tree.root.get_node("RunManager")
	rm.start_new_run(99)
	var state: Resource = rm.get_state()
	if hero_dead:
		state.hero_dead = true
	rm.consume_battle_result("L6N0", "player" if victory else "enemy", {
		"hero_dead": hero_dead,
		"is_boss": victory,
		"is_elite": false,
		"balls_remaining": 2,
		"survivors": state.party,
		"deploy_unit_ids": []
	})

func instantiate_smoke(scene_path: String, required_names: Array[String]) -> Node:
	var packed: PackedScene = load(scene_path) as PackedScene
	_checks.assert_true(packed != null, "load scene %s" % scene_path)
	var inst: Node = packed.instantiate()
	_tree.root.add_child(inst)
	for node_name in required_names:
		var found: Node = _find_named_node(inst, String(node_name))
		_checks.assert_true(found != null, "%s has %s" % [scene_path, node_name])
	inst.queue_free()
	return inst

func _find_named_node(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	return root.find_child(node_name, true, false)

func press_stage_card_by_index(root: Node, index: int) -> void:
	var stage_list: Node = root.find_child("StageList", true, false)
	_checks.assert_true(stage_list != null, "StageList exists")
	if stage_list == null:
		return
	_checks.assert_true(index < stage_list.get_child_count(), "stage card index %d" % index)
	var card: Node = stage_list.get_child(index)
	var btn: Button = _find_button_in(card)
	press_button(btn, "stage card %d" % index)

func _find_button_in(node: Node) -> Button:
	if node is Button:
		return node as Button
	for child in node.get_children():
		var found: Button = _find_button_in(child)
		if found != null:
			return found
	return null
