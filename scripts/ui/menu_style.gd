class_name MenuStyle
extends RefCounted

enum CardVariant { DEFAULT, LOCKED, UNLOCKED, CLEARED, HERO }

const PAGE_BG: Color = Color(0.09, 0.11, 0.15, 1.0)
const TEXT_PRIMARY: Color = Color(0.92, 0.94, 0.98, 1.0)
const TEXT_MUTED: Color = Color(0.78, 0.86, 0.98, 1.0)
const TEXT_HINT: Color = Color(0.92, 0.86, 0.45, 1.0)
const BADGE_LOCKED: Color = Color(0.55, 0.58, 0.62, 1.0)
const BADGE_UNLOCKED: Color = Color(0.38, 0.55, 0.82, 1.0)
const BADGE_CLEARED: Color = Color(0.85, 0.65, 0.30, 1.0)
const STATUS_CAUGHT: Color = Color(0.55, 0.95, 0.65, 1.0)
const STATUS_DISCOVERED: Color = Color(0.95, 0.86, 0.45, 1.0)
const STATUS_UNKNOWN: Color = Color(0.55, 0.55, 0.60, 1.0)

static func apply_page_shell(page: Control) -> void:
	var bg: ColorRect = page.get_node_or_null("Background") as ColorRect
	if bg != null:
		bg.color = PAGE_BG
	var panel: Control = page.get_node_or_null("Panel") as Control
	if panel != null:
		panel.add_theme_stylebox_override("panel", make_panel_style())

static func style_buttons_in_tree(root: Node) -> void:
	if root is Button:
		apply_button_styles(root as Button)
	for child in root.get_children():
		style_buttons_in_tree(child)

static func apply_button_styles(button: Button, base: Color = Color(0.22, 0.42, 0.72), hover: Color = Color(0.30, 0.52, 0.82)) -> void:
	var styles: Dictionary = make_button_styles(base, hover)
	button.add_theme_stylebox_override("normal", styles["normal"])
	button.add_theme_stylebox_override("hover", styles["hover"])
	button.add_theme_stylebox_override("pressed", styles["pressed"])
	button.add_theme_stylebox_override("disabled", styles["disabled"])
	button.add_theme_color_override("font_color", styles["font_color"])
	button.add_theme_color_override("font_disabled_color", styles["font_disabled_color"])

static func make_button_styles(base: Color = Color(0.22, 0.42, 0.72), hover: Color = Color(0.30, 0.52, 0.82)) -> Dictionary:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = base
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hovered: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hovered.bg_color = hover
	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base.darkened(0.12)
	var disabled: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.22, 0.24, 0.28, 0.7)
	return {
		"normal": normal,
		"hover": hovered,
		"pressed": pressed,
		"disabled": disabled,
		"font_color": TEXT_PRIMARY,
		"font_disabled_color": Color(0.55, 0.58, 0.62, 1.0)
	}

static func make_panel_style() -> StyleBox:
	var tex_style: StyleBoxTexture = _try_panel_texture_style()
	if tex_style != null:
		return tex_style
	return _make_flat_card(Color(0.38, 0.55, 0.82, 0.45), CardVariant.DEFAULT)

static func make_card_style(variant: CardVariant = CardVariant.DEFAULT) -> StyleBoxFlat:
	match variant:
		CardVariant.LOCKED:
			return _make_flat_card(Color(0.33, 0.35, 0.38, 0.55), variant)
		CardVariant.UNLOCKED:
			return _make_flat_card(Color(0.38, 0.55, 0.82, 0.55), variant)
		CardVariant.CLEARED:
			return _make_flat_card(Color(0.85, 0.65, 0.30, 0.55), variant)
		CardVariant.HERO:
			var style: StyleBoxFlat = _make_flat_card(Color(0.85, 0.65, 0.30, 0.65), variant)
			style.border_width_left = 4
			return style
		_:
			return _make_flat_card(Color(0.38, 0.55, 0.82, 0.35), variant)

static func badge_color_for_status(status: String) -> Color:
	match status:
		"cleared", "已通关":
			return BADGE_CLEARED
		"unlocked", "可挑战":
			return BADGE_UNLOCKED
		"caught", "已捕获":
			return STATUS_CAUGHT
		"discovered", "已发现":
			return STATUS_DISCOVERED
		_:
			return BADGE_LOCKED

static func build_stage_card(
	stage_id: String,
	stage_name: String,
	status: String,
	can_enter: bool,
	on_pressed: Callable = Callable()
) -> PanelContainer:
	var variant: CardVariant = CardVariant.LOCKED
	if status == "cleared":
		variant = CardVariant.CLEARED
	elif status == "unlocked":
		variant = CardVariant.UNLOCKED
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 72)
	card.add_theme_stylebox_override("panel", make_card_style(variant))
	if not can_enter:
		card.modulate = Color(0.72, 0.72, 0.76, 1.0)
	var wrapper: Control = Control.new()
	wrapper.custom_minimum_size = Vector2(0, 72)
	card.add_child(wrapper)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	wrapper.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	row.add_child(text_col)
	var title: Label = Label.new()
	title.text = stage_name
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	title.add_theme_font_size_override("font_size", 18)
	text_col.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = stage_id
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	subtitle.add_theme_font_size_override("font_size", 12)
	text_col.add_child(subtitle)
	var badge: Label = Label.new()
	badge.text = _status_label(status)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(72, 28)
	badge.add_theme_color_override("font_color", badge_color_for_status(status))
	badge.add_theme_font_size_override("font_size", 13)
	row.add_child(badge)
	if can_enter:
		var hit: Button = Button.new()
		hit.set_anchors_preset(Control.PRESET_FULL_RECT)
		hit.flat = true
		hit.mouse_filter = Control.MOUSE_FILTER_STOP
		hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		if on_pressed.is_valid():
			hit.pressed.connect(on_pressed.bind(stage_id))
		wrapper.add_child(hit)
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return card

static func build_hero_card(text: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 56)
	card.add_theme_stylebox_override("panel", make_card_style(CardVariant.HERO))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var label: Label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", BADGE_CLEARED)
	label.add_theme_font_size_override("font_size", 16)
	margin.add_child(label)
	return card

static func build_reserve_row(entry: Dictionary, unit_name: String, toggled_cb: Callable) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 52)
	card.add_theme_stylebox_override("panel", make_card_style(CardVariant.DEFAULT))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var cb: CheckBox = CheckBox.new()
	cb.text = ""
	cb.set_meta("unit_id", String(entry.get("unit_id", "")))
	cb.toggled.connect(toggled_cb.bind(cb))
	row.add_child(cb)
	var avatar: TextureRect = TextureRect.new()
	avatar.custom_minimum_size = Vector2(36, 36)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var template_id: String = String(entry.get("template_id", ""))
	var art: Node = Engine.get_main_loop().root.get_node_or_null("/root/ArtLoader")
	if art != null:
		avatar.texture = art.get_unit(template_id)
	row.add_child(avatar)
	var info: Label = Label.new()
	info.text = "%s — %s（HP %d/%d）" % [
		String(entry.get("unit_id", "")),
		unit_name,
		int(entry.get("hp", 0)),
		int(entry.get("max_hp", 0))
	]
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_color_override("font_color", TEXT_PRIMARY)
	row.add_child(info)
	return card

static func build_bestiary_cell(template_id: String, unit_name: String, status_key: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 100)
	var variant: CardVariant = CardVariant.DEFAULT
	if status_key == "caught":
		variant = CardVariant.CLEARED
	elif status_key == "discovered":
		variant = CardVariant.UNLOCKED
	elif status_key == "unknown":
		variant = CardVariant.LOCKED
	card.add_theme_stylebox_override("panel", make_card_style(variant))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var col: VBoxContainer = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(col)
	var avatar: TextureRect = TextureRect.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var art: Node = Engine.get_main_loop().root.get_node_or_null("/root/ArtLoader")
	if status_key == "unknown":
		avatar.modulate = Color(0.45, 0.45, 0.48, 1.0)
		if art != null:
			avatar.texture = art.get_unit(template_id)
	elif art != null:
		avatar.texture = art.get_unit(template_id)
	col.add_child(avatar)
	var name_label: Label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if status_key == "unknown":
		name_label.text = "%s\n?" % template_id
		name_label.add_theme_color_override("font_color", STATUS_UNKNOWN)
	else:
		name_label.text = "%s\n%s" % [template_id, unit_name]
		name_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 12)
	col.add_child(name_label)
	var badge: Label = Label.new()
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match status_key:
		"caught":
			badge.text = "[已捕获]"
			badge.add_theme_color_override("font_color", STATUS_CAUGHT)
		"discovered":
			badge.text = "[已发现]"
			badge.add_theme_color_override("font_color", STATUS_DISCOVERED)
		_:
			badge.text = "[未发现]"
			badge.add_theme_color_override("font_color", STATUS_UNKNOWN)
	badge.add_theme_font_size_override("font_size", 11)
	col.add_child(badge)
	return card

static func _status_label(status: String) -> String:
	match status:
		"cleared":
			return "已通关"
		"unlocked":
			return "可挑战"
		_:
			return "未解锁"

static func _try_panel_texture_style() -> StyleBoxTexture:
	var art: Node = Engine.get_main_loop().root.get_node_or_null("/root/ArtLoader")
	if art == null:
		return null
	var tex: Texture2D = art.get_ui("panel_bg")
	if tex == null:
		return null
	var style: StyleBoxTexture = StyleBoxTexture.new()
	style.texture = tex
	style.set_texture_margin_all(4)
	style.modulate_color = Color(1, 1, 1, 0.92)
	return style

static func _make_flat_card(border_color: Color, variant: CardVariant) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.15, 0.20, 0.92)
	if variant == CardVariant.LOCKED:
		style.bg_color = Color(0.10, 0.11, 0.14, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style
