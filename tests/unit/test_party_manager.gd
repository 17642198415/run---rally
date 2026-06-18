extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")
const PartyManager = preload("res://scripts/managers/party_manager.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var pm: Node = PartyManager.new()
	pm.clear()

	var first: Dictionary = pm.add_capture("M01", 18, 18, "S_FIRE_CLAW")
	checks.assert_equal(String(first.get("unit_id", "")), "P_M01_001", "first M01 capture id is P_M01_001.")
	checks.assert_equal(String(first.get("template_id", "")), "M01", "template id preserved.")

	var second: Dictionary = pm.add_capture("M01", 18, 18, "S_FIRE_CLAW")
	checks.assert_equal(String(second.get("unit_id", "")), "P_M01_002", "second M01 capture id is P_M01_002.")

	var other: Dictionary = pm.add_capture("M02", 28, 28, "S_GUARD")
	checks.assert_equal(String(other.get("unit_id", "")), "P_M02_001", "different template starts at 001.")

	checks.assert_equal(pm.reserve.size(), 3, "reserve has 3 entries.")

	for i in range(PartyManager.MAX_RESERVE - 3):
		pm.add_capture("M03", 16, 16, "S_GUST")
	checks.assert_true(not pm.can_accept(), "reserve full at MAX_RESERVE.")
	var rejected: Dictionary = pm.add_capture("M04", 22, 22, "S_HEAL")
	checks.assert_true(rejected.is_empty(), "full reserve rejects new capture.")
	checks.assert_equal(pm.reserve.size(), PartyManager.MAX_RESERVE, "reserve size unchanged after rejection.")

	var dict: Dictionary = pm.to_dict()
	var pm2: Node = PartyManager.new()
	pm2.clear()
	pm2.from_dict(dict)
	checks.assert_equal(pm2.reserve.size(), PartyManager.MAX_RESERVE, "from_dict restores reserve size.")

	# 验证从字典恢复后，下一只 M01 编号继续递增
	pm2.reserve.pop_back()
	var next_m01: Dictionary = pm2.add_capture("M01", 18, 18, "S_FIRE_CLAW")
	checks.assert_equal(String(next_m01.get("unit_id", "")), "P_M01_003", "sequence continues after restore.")

	pm.free()
	pm2.free()
	quit(checks.finish())
