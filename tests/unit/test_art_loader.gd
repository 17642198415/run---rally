extends SceneTree

const Assertions = preload("res://tests/helpers/test_assertions.gd")

var checks: Assertions = Assertions.new()

func _initialize() -> void:
	var loader: Node = get_root().get_node_or_null("ArtLoader")
	checks.assert_true(loader != null, "ArtLoader autoload available.")
	if loader == null:
		quit(checks.finish())
		return

	# manifest 解析：版本号
	checks.assert_true(int(loader.get_manifest_version()) >= 1, "manifest version >= 1.")

	# tiles：5 种地形（plain/forest/water/wall/deploy）
	for terrain_name in ["plain", "forest", "water", "wall", "deploy"]:
		var tex: Texture2D = loader.get_tile(terrain_name)
		checks.assert_true(tex != null, "get_tile(%s) returns Texture2D." % terrain_name)
		if tex != null:
			checks.assert_equal(int(tex.get_width()), 32, "tile %s width = 32." % terrain_name)
			checks.assert_equal(int(tex.get_height()), 32, "tile %s height = 32." % terrain_name)

	# units：HERO + M01..M08 + BOSS_MERC
	var unit_ids: Array[String] = ["HERO", "M01", "M02", "M03", "M04", "M05", "M06", "M07", "M08", "BOSS_MERC"]
	for uid in unit_ids:
		var tex: Texture2D = loader.get_unit(uid)
		checks.assert_true(tex != null, "get_unit(%s) returns Texture2D." % uid)
		if tex != null:
			checks.assert_equal(int(tex.get_width()), 64, "unit %s width = 64." % uid)
			checks.assert_equal(int(tex.get_height()), 64, "unit %s height = 64." % uid)

	# icons：7 个动作图标
	for icon_name in ["move", "attack", "skill", "capture", "wait", "end_turn", "confirm"]:
		var tex: Texture2D = loader.get_icon(icon_name)
		checks.assert_true(tex != null, "get_icon(%s) returns Texture2D." % icon_name)
		if tex != null:
			checks.assert_equal(int(tex.get_width()), 16, "icon %s width = 16." % icon_name)
			checks.assert_equal(int(tex.get_height()), 16, "icon %s height = 16." % icon_name)

	# 未知键 → 仍返回非空占位
	var unknown_tile: Texture2D = loader.get_tile("__unknown_terrain__")
	checks.assert_true(unknown_tile != null, "unknown tile falls back to placeholder.")
	var unknown_unit: Texture2D = loader.get_unit("__unknown_unit__")
	checks.assert_true(unknown_unit != null, "unknown unit falls back to placeholder.")
	var unknown_icon: Texture2D = loader.get_icon("__unknown_icon__")
	checks.assert_true(unknown_icon != null, "unknown icon falls back to placeholder.")

	# 缓存：相同 key 两次取应返回同一引用
	var first_tex: Texture2D = loader.get_tile("plain")
	var second_tex: Texture2D = loader.get_tile("plain")
	checks.assert_true(first_tex == second_tex, "tile texture cached across calls.")

	quit(checks.finish())
