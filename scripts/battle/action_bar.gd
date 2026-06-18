extends Control

signal action_selected(action: String)
signal end_turn_pressed
signal confirm_deploy_pressed
signal capture_pressed

@onready var panel: Panel = $Panel
@onready var hp_label: Label = $Panel/VBox/HpLabel
@onready var move_btn: Button = $Panel/VBox/Buttons/MoveBtn
@onready var attack_btn: Button = $Panel/VBox/Buttons/AttackBtn
@onready var skill_btn: Button = $Panel/VBox/Buttons/SkillBtn
@onready var capture_btn: Button = $Panel/VBox/Buttons/CaptureBtn
@onready var wait_btn: Button = $Panel/VBox/Buttons/WaitBtn
@onready var end_turn_btn: Button = $Panel/VBox/Buttons/EndTurnBtn
@onready var confirm_deploy_btn: Button = $Panel/VBox/Buttons/ConfirmDeployBtn

func _ready() -> void:
	_apply_styles()
	_apply_icons()
	move_btn.pressed.connect(func() -> void: action_selected.emit("move"))
	attack_btn.pressed.connect(func() -> void: action_selected.emit("attack"))
	skill_btn.pressed.connect(func() -> void: action_selected.emit("skill"))
	wait_btn.pressed.connect(func() -> void: action_selected.emit("wait"))
	capture_btn.pressed.connect(func() -> void: capture_pressed.emit())
	end_turn_btn.pressed.connect(func() -> void: end_turn_pressed.emit())
	confirm_deploy_btn.pressed.connect(func() -> void: confirm_deploy_pressed.emit())
	visible = false
	capture_btn.visible = false
	capture_btn.disabled = true
	set_deploy_mode(false, false)

func _apply_icons() -> void:
	var art: Node = get_node_or_null("/root/ArtLoader")
	if art == null:
		return
	var pairs: Array = [
		[move_btn, "move"],
		[attack_btn, "attack"],
		[skill_btn, "skill"],
		[capture_btn, "capture"],
		[wait_btn, "wait"],
		[end_turn_btn, "end_turn"],
		[confirm_deploy_btn, "confirm"]
	]
	for pair in pairs:
		var btn: Button = pair[0]
		var key: String = pair[1]
		var tex: Texture2D = art.get_icon(key)
		if tex != null:
			btn.icon = tex
			btn.expand_icon = false
			btn.add_theme_constant_override("h_separation", 6)
			btn.custom_minimum_size = Vector2(0, 32)

func set_unit_info(unit_name: String, hp: int, max_hp: int, skill_ready: bool) -> void:
	hp_label.text = "%s    HP  %d / %d" % [unit_name, hp, max_hp]
	skill_btn.disabled = not skill_ready

func show_for_unit(unit_name: String, hp: int, max_hp: int, skill_ready: bool) -> void:
	set_unit_info(unit_name, hp, max_hp, skill_ready)
	visible = true
	confirm_deploy_btn.visible = false
	end_turn_btn.visible = true

func hide_bar() -> void:
	visible = false

func set_capture_enabled(enabled: bool) -> void:
	capture_btn.visible = true
	capture_btn.disabled = not enabled

func hide_capture_button() -> void:
	capture_btn.visible = false
	capture_btn.disabled = true

func set_deploy_mode(show_confirm: bool, confirm_enabled: bool) -> void:
	visible = show_confirm
	hp_label.text = "部署阶段：点击左侧部署区放置单位"
	move_btn.visible = false
	attack_btn.visible = false
	skill_btn.visible = false
	wait_btn.visible = false
	end_turn_btn.visible = false
	capture_btn.visible = false
	confirm_deploy_btn.visible = show_confirm
	confirm_deploy_btn.disabled = not confirm_enabled

func set_player_turn_mode(show_end_turn: bool) -> void:
	move_btn.visible = true
	attack_btn.visible = true
	skill_btn.visible = true
	wait_btn.visible = true
	end_turn_btn.visible = show_end_turn
	confirm_deploy_btn.visible = false
	capture_btn.visible = false
	capture_btn.disabled = true

func set_enemy_turn_hidden() -> void:
	visible = false
	capture_btn.visible = false

func set_view_only_mode() -> void:
	visible = true
	move_btn.visible = false
	attack_btn.visible = false
	skill_btn.visible = false
	wait_btn.visible = false
	capture_btn.visible = false
	end_turn_btn.visible = true
	confirm_deploy_btn.visible = false

func _apply_styles() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.13, 0.15, 0.20, 0.94)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.38, 0.55, 0.82, 0.55)
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel_style.shadow_color = Color(0, 0, 0, 0.35)
	panel_style.shadow_size = 8
	panel_style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", panel_style)

	hp_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	hp_label.add_theme_font_size_override("font_size", 15)

	_style_button(move_btn, Color(0.22, 0.42, 0.72), Color(0.30, 0.52, 0.82))
	_style_button(attack_btn, Color(0.62, 0.22, 0.22), Color(0.78, 0.32, 0.28))
	_style_button(skill_btn, Color(0.42, 0.24, 0.62), Color(0.55, 0.34, 0.75))
	_style_button(capture_btn, Color(0.20, 0.55, 0.62), Color(0.30, 0.70, 0.78))
	_style_button(wait_btn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))
	_style_button(end_turn_btn, Color(0.20, 0.48, 0.36), Color(0.28, 0.58, 0.44))
	_style_button(confirm_deploy_btn, Color(0.22, 0.42, 0.72), Color(0.30, 0.52, 0.82))

func _style_button(button: Button, base: Color, hover: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hovered: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hovered.bg_color = hover

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base.darkened(0.12)

	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.22, 0.24, 0.28, 0.7)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hovered)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98))
	button.add_theme_color_override("font_disabled_color", Color(0.55, 0.58, 0.62))
