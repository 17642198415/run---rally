extends Control

signal confirmed
signal cancelled

const TIER_LABELS: Dictionary = {
	"high": "高",
	"mid": "中",
	"low": "低",
	"vlow": "极低"
}

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var hp_label: Label = $Panel/VBox/HpLabel
@onready var rate_label: Label = $Panel/VBox/RateLabel
@onready var balls_label: Label = $Panel/VBox/BallsLabel
@onready var confirm_btn: Button = $Panel/VBox/Buttons/ConfirmBtn
@onready var cancel_btn: Button = $Panel/VBox/Buttons/CancelBtn

func _ready() -> void:
	_apply_styles()
	visible = false
	confirm_btn.pressed.connect(func() -> void:
		visible = false
		confirmed.emit()
	)
	cancel_btn.pressed.connect(func() -> void:
		visible = false
		cancelled.emit()
	)

func show_prompt(target_name: String, hp: int, max_hp: int, rate: float, tier: String, balls: int) -> void:
	title_label.text = "捕捉目标：%s" % target_name
	var hp_pct: int = 0
	if max_hp > 0:
		hp_pct = int(round(float(hp) * 100.0 / float(max_hp)))
	hp_label.text = "HP  %d / %d  (%d%%)" % [hp, max_hp, hp_pct]
	var tier_label: String = String(TIER_LABELS.get(tier, tier))
	rate_label.text = "成功率：[%s]   (%.0f%%)" % [tier_label, rate * 100.0]
	balls_label.text = "剩余捕捉球：%d" % balls
	confirm_btn.disabled = balls <= 0
	visible = true

func _apply_styles() -> void:
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.16, 0.22, 0.96)
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.36, 0.66, 0.74, 0.8)
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", panel_style)

	for label in [title_label, hp_label, rate_label, balls_label]:
		label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
		label.add_theme_font_size_override("font_size", 16)

	_style_button(confirm_btn, Color(0.20, 0.55, 0.62), Color(0.30, 0.70, 0.78))
	_style_button(cancel_btn, Color(0.28, 0.30, 0.34), Color(0.38, 0.40, 0.46))

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
