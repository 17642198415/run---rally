extends Control

signal turn_banner_updated(round_number: int, active_name: String, phase_text: String)

@onready var round_label: Label = $Panel/HBox/RoundLabel
@onready var active_label: Label = $Panel/HBox/ActiveLabel

func _ready() -> void:
	_apply_style()

func update_banner(round_number: int, active_name: String, phase_text: String) -> void:
	round_label.text = "第 %d 回合" % round_number
	active_label.text = "%s  |  %s" % [phase_text, active_name]
	turn_banner_updated.emit(round_number, active_name, phase_text)

func _apply_style() -> void:
	var panel: Panel = $Panel
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.13, 0.18, 0.92)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	round_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98))
	active_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98))
