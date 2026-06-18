extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const CampaignManager = preload("res://scripts/campaign/campaign_manager.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	_test_fresh_defaults()
	_test_clear_unlocks_next()
	_test_locked_cannot_enter()
	_test_round_trip_dict()
	_test_unknown_stage_ignored()
	quit(checks.finish())

func _make_manager() -> Node:
	var cm: Node = CampaignManager.new()
	cm.from_dict({})
	return cm

func _test_fresh_defaults() -> void:
	var cm: Node = _make_manager()
	checks.assert_equal(cm.get_status("stage_01"), CampaignManager.STATUS_UNLOCKED, "fresh stage_01 unlocked.")
	checks.assert_equal(cm.get_status("stage_02"), CampaignManager.STATUS_LOCKED, "fresh stage_02 locked.")
	checks.assert_equal(cm.get_status("stage_03"), CampaignManager.STATUS_LOCKED, "fresh stage_03 locked.")
	cm.free()

func _test_clear_unlocks_next() -> void:
	var cm: Node = _make_manager()
	cm.mark_cleared("stage_01", "stage_02")
	checks.assert_equal(cm.get_status("stage_01"), CampaignManager.STATUS_CLEARED, "stage_01 cleared.")
	checks.assert_equal(cm.get_status("stage_02"), CampaignManager.STATUS_UNLOCKED, "stage_02 unlocked after clear.")
	cm.mark_cleared("stage_02", "stage_03")
	checks.assert_equal(cm.get_status("stage_03"), CampaignManager.STATUS_UNLOCKED, "stage_03 unlocked.")
	cm.free()

func _test_locked_cannot_enter() -> void:
	var cm: Node = _make_manager()
	checks.assert_true(cm.can_enter("stage_01"), "stage_01 enterable.")
	checks.assert_true(not cm.can_enter("stage_02"), "stage_02 not enterable when locked.")
	checks.assert_true(not cm.can_enter("stage_03"), "stage_03 not enterable when locked.")
	cm.free()

func _test_round_trip_dict() -> void:
	var cm: Node = _make_manager()
	cm.mark_cleared("stage_01", "stage_02")
	var dict: Dictionary = cm.to_dict()
	var cm2: Node = CampaignManager.new()
	cm2.from_dict(dict)
	checks.assert_equal(cm2.get_status("stage_01"), CampaignManager.STATUS_CLEARED, "round trip cleared.")
	checks.assert_equal(cm2.get_status("stage_02"), CampaignManager.STATUS_UNLOCKED, "round trip unlocked.")
	checks.assert_equal(cm2.get_status("stage_03"), CampaignManager.STATUS_LOCKED, "round trip locked default.")
	cm.free()
	cm2.free()

func _test_unknown_stage_ignored() -> void:
	var cm: Node = _make_manager()
	cm.from_dict({"stage_99": "cleared"})
	checks.assert_equal(cm.get_status("stage_99"), CampaignManager.STATUS_LOCKED, "unknown stage ignored.")
	cm.free()
