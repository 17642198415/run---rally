extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const Harness = preload("res://tests/helpers/scene_test_harness.gd")

const MAIN_MENU: String = "res://scenes/main_menu.tscn"
const STAGE_SELECT: String = "res://scenes/campaign/stage_select.tscn"
const PARTY_SETUP: String = "res://scenes/campaign/party_setup.tscn"
const BESTIARY: String = "res://scenes/campaign/bestiary_view.tscn"
const ROUTE_MAP: String = "res://scenes/roguelike/route_map.tscn"
const REST: String = "res://scenes/roguelike/rest.tscn"
const SHOP: String = "res://scenes/roguelike/shop.tscn"
const REWARD_PICK: String = "res://scenes/roguelike/reward_pick.tscn"
const RUN_SUMMARY: String = "res://scenes/roguelike/run_summary.tscn"
const BATTLE: String = "res://scenes/battle/battle.tscn"

var checks: Assertions = Assertions.new()
var harness: Harness

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	harness = Harness.new(self, checks)
	await harness.reset_save_defaults()
	await _smoke_campaign_scenes()
	await _smoke_roguelike_scenes()
	await _smoke_battle_scenes()
	quit(checks.finish())

func _smoke_campaign_scenes() -> void:
	harness.change_scene(MAIN_MENU)
	await harness.await_idle()
	checks.assert_true(harness.find_button(harness.get_current_scene(), "CampaignBtn") != null, "main_menu CampaignBtn")
	checks.assert_true(harness.find_button(harness.get_current_scene(), "RoguelikeBtn") != null, "main_menu RoguelikeBtn")

	harness.change_scene(STAGE_SELECT)
	await harness.await_idle()
	checks.assert_true(harness.get_current_scene().find_child("StageList", true, false) != null, "stage_select StageList")

	var gs: Node = get_root().get_node("GameState")
	gs.current_mode = gs.GameMode.CAMPAIGN
	gs.stage_id = "stage_01"
	harness.change_scene(PARTY_SETUP)
	await harness.await_idle()
	checks.assert_true(harness.get_current_scene().find_child("HeroCardSlot", true, false) != null, "party_setup HeroCardSlot")
	checks.assert_true(harness.get_current_scene().find_child("ReserveList", true, false) != null, "party_setup ReserveList")

	harness.change_scene(BESTIARY)
	await harness.await_idle()
	checks.assert_true(harness.find_button(harness.get_current_scene(), "SpeciesTabBtn") != null, "bestiary SpeciesTabBtn")
	checks.assert_true(harness.get_current_scene().find_child("Grid", true, false) != null, "bestiary Grid")

func _smoke_roguelike_scenes() -> void:
	harness.setup_active_run(42)
	harness.change_scene(ROUTE_MAP)
	await harness.await_idle(5)
	checks.assert_true(harness.get_current_scene().find_child("RouteLayers", true, false) != null, "route_map RouteLayers")

	harness.setup_pending_event("L2N0", 2, "rest")
	harness.change_scene(REST)
	await harness.await_idle()
	checks.assert_true(harness.find_button(harness.get_current_scene(), "LeaveBtn") != null, "rest LeaveBtn")

	harness.setup_pending_event("L3N1", 3, "shop")
	harness.change_scene(SHOP)
	await harness.await_idle()
	checks.assert_true(harness.get_current_scene().find_child("ItemsBox", true, false) != null, "shop ItemsBox")

	harness.setup_pending_rewards(42, false)
	harness.change_scene(REWARD_PICK)
	await harness.await_idle()
	checks.assert_true(harness.get_current_scene().find_child("CardsBox", true, false) != null, "reward_pick CardsBox")

	harness.setup_active_run(99)
	harness.change_scene(RUN_SUMMARY)
	await harness.await_idle()
	checks.assert_true(harness.find_button(harness.get_current_scene(), "MenuBtn") != null, "run_summary MenuBtn")

func _smoke_battle_scenes() -> void:
	var gs: Node = get_root().get_node("GameState")
	gs.start_campaign_battle("stage_01", [{
		"unit_id": "P_HERO",
		"template_id": "HERO",
		"hp": 0,
		"max_hp": 0
	}])
	harness.change_scene(BATTLE)
	await harness.await_idle(5)
	checks.assert_true(harness.get_current_scene().find_child("ActionBar", true, false) != null, "battle ActionBar")
	checks.assert_true(harness.get_current_scene().find_child("TurnBanner", true, false) != null, "battle TurnBanner")

	harness.instantiate_smoke("res://scenes/battle/ui/action_bar.tscn", ["ActionBar"])
	harness.instantiate_smoke("res://scenes/battle/ui/turn_banner.tscn", ["TurnBanner"])
	harness.instantiate_smoke("res://scenes/battle/ui/capture_prompt.tscn", ["CapturePrompt"])
