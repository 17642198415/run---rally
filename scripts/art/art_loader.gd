extends Node

const MANIFEST_PATH: String = "res://assets/art/art_manifest.json"
const ASSETS_ROOT: String = "res://assets/art/"

const DEFAULT_TILE_SIZE: int = 32
const DEFAULT_UNIT_SIZE: int = 64
const DEFAULT_ICON_SIZE: int = 16
const DEFAULT_UI_SIZE: int = 16

var _manifest: Dictionary = {}
var _cache_tiles: Dictionary = {}
var _cache_units: Dictionary = {}
var _cache_icons: Dictionary = {}
var _cache_ui: Dictionary = {}

func _ready() -> void:
	_manifest = _load_manifest()

func get_manifest_version() -> int:
	return int(_manifest.get("version", 1))

func get_tile(name: String) -> Texture2D:
	if _cache_tiles.has(name):
		return _cache_tiles[name]
	var tex: Texture2D = _resolve_tex("tiles", name, DEFAULT_TILE_SIZE)
	_cache_tiles[name] = tex
	return tex

func get_unit(template_id: String) -> Texture2D:
	if _cache_units.has(template_id):
		return _cache_units[template_id]
	var tex: Texture2D = _resolve_tex("units", template_id, DEFAULT_UNIT_SIZE)
	_cache_units[template_id] = tex
	return tex

func get_icon(action: String) -> Texture2D:
	if _cache_icons.has(action):
		return _cache_icons[action]
	var tex: Texture2D = _resolve_tex("icons", action, DEFAULT_ICON_SIZE)
	_cache_icons[action] = tex
	return tex

func get_ui(name: String) -> Texture2D:
	if _cache_ui.has(name):
		return _cache_ui[name]
	var tex: Texture2D = _resolve_tex("ui", name, DEFAULT_UI_SIZE)
	_cache_ui[name] = tex
	return tex

func get_unit_fallback_glyph(template_id: String) -> String:
	var section: Dictionary = _manifest.get("units", {}) as Dictionary
	var entry: Dictionary = section.get(template_id, {}) as Dictionary
	return String(entry.get("fallback_glyph", ""))

func get_unit_fallback_bg(template_id: String) -> Color:
	var section: Dictionary = _manifest.get("units", {}) as Dictionary
	var entry: Dictionary = section.get(template_id, {}) as Dictionary
	return _color_from_hex(String(entry.get("fallback_bg", "#888888")))

func _resolve_tex(section: String, key: String, default_size: int) -> Texture2D:
	var entry: Dictionary = _get_entry(section, key)
	var size: int = default_size
	if entry.has("size"):
		var arr: Array = entry["size"] as Array
		if arr.size() >= 1:
			size = int(arr[0])
	if entry.has("path"):
		var full_path: String = ASSETS_ROOT + String(entry["path"])
		if ResourceLoader.exists(full_path):
			var tex: Texture2D = load(full_path) as Texture2D
			if tex != null:
				return tex
	return _make_placeholder(section, key, entry, size)

func _get_entry(section: String, key: String) -> Dictionary:
	var sec: Dictionary = _manifest.get(section, {}) as Dictionary
	if sec.has(key):
		return sec[key] as Dictionary
	if not _is_legal_name(key):
		push_warning("ArtLoader: illegal asset key '%s' under section '%s'." % [key, section])
	return {}

func _is_legal_name(name: String) -> bool:
	if name.is_empty():
		return false
	for ch in name:
		var c: String = ch
		var ok: bool = (
			(c >= "a" and c <= "z") or
			(c >= "A" and c <= "Z") or
			(c >= "0" and c <= "9") or
			c == "_" or c == "-"
		)
		if not ok:
			return false
	return true

func _make_placeholder(section: String, key: String, entry: Dictionary, size: int) -> Texture2D:
	var img: Image
	match section:
		"tiles":
			img = _make_tile_image(entry, size)
		"units":
			img = _make_unit_image(entry, size)
		"icons":
			img = _make_icon_image(entry, size)
		_:
			img = _make_ui_image(entry, size)
	return ImageTexture.create_from_image(img)

func _make_tile_image(entry: Dictionary, size: int) -> Image:
	var bg: Color = _color_from_hex(String(entry.get("fallback_color", "#888888")))
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	var border: Color = bg.darkened(0.35)
	for x in size:
		img.set_pixel(x, 0, border)
		img.set_pixel(x, size - 1, border)
	for y in size:
		img.set_pixel(0, y, border)
		img.set_pixel(size - 1, y, border)
	return img

func _make_unit_image(entry: Dictionary, size: int) -> Image:
	var bg: Color = _color_from_hex(String(entry.get("fallback_bg", "#5C5E66")))
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center: Vector2 = Vector2(size, size) * 0.5
	var radius: float = float(size) * 0.46
	var ring: Color = bg.lightened(0.25)
	for y in size:
		for x in size:
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d <= radius - 1.0:
				img.set_pixel(x, y, bg)
			elif d <= radius:
				img.set_pixel(x, y, ring)
	return img

func _make_icon_image(entry: Dictionary, size: int) -> Image:
	var bg: Color = _color_from_hex(String(entry.get("fallback_bg", "#5C5E66")))
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var inset: int = 2
	var fill: Color = bg
	for y in range(inset, size - inset):
		for x in range(inset, size - inset):
			img.set_pixel(x, y, fill)
	var border: Color = bg.darkened(0.4)
	for x in range(inset - 1, size - inset + 1):
		img.set_pixel(x, inset - 1, border)
		img.set_pixel(x, size - inset, border)
	for y in range(inset - 1, size - inset + 1):
		img.set_pixel(inset - 1, y, border)
		img.set_pixel(size - inset, y, border)
	return img

func _make_ui_image(entry: Dictionary, size: int) -> Image:
	var bg: Color = _color_from_hex(String(entry.get("fallback_color", "#212733")))
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	return img

func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("ArtLoader: manifest missing at %s, using built-in defaults." % MANIFEST_PATH)
		return _builtin_defaults()
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_warning("ArtLoader: cannot open manifest, using built-in defaults.")
		return _builtin_defaults()
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("ArtLoader: manifest JSON invalid, using built-in defaults.")
		return _builtin_defaults()
	return parsed as Dictionary

func _builtin_defaults() -> Dictionary:
	return {
		"version": 1,
		"tiles": {
			"plain":  {"size": [32, 32], "fallback_color": "#7FB069"},
			"forest": {"size": [32, 32], "fallback_color": "#3F7A3F", "fallback_glyph": "木"},
			"water":  {"size": [32, 32], "fallback_color": "#3D6FA8", "fallback_glyph": "水"},
			"wall":   {"size": [32, 32], "fallback_color": "#6E5B45", "fallback_glyph": "墙"},
			"deploy": {"size": [32, 32], "fallback_color": "#4FA77F"}
		},
		"units": {
			"HERO":      {"size": [64, 64], "fallback_glyph": "旅", "fallback_bg": "#3A6BD8"},
			"BOSS_MERC": {"size": [64, 64], "fallback_glyph": "佣", "fallback_bg": "#8B2F2F"}
		},
		"icons": {
			"move":     {"size": [16, 16], "fallback_glyph": "→", "fallback_bg": "#3A6BD8"},
			"attack":   {"size": [16, 16], "fallback_glyph": "刀", "fallback_bg": "#A93A3A"},
			"skill":    {"size": [16, 16], "fallback_glyph": "★", "fallback_bg": "#7B4FB8"},
			"capture":  {"size": [16, 16], "fallback_glyph": "球", "fallback_bg": "#3FAEB8"},
			"wait":     {"size": [16, 16], "fallback_glyph": "歇", "fallback_bg": "#5C5E66"},
			"end_turn": {"size": [16, 16], "fallback_glyph": "终", "fallback_bg": "#3F8A5F"},
			"confirm":  {"size": [16, 16], "fallback_glyph": "✔", "fallback_bg": "#3F7BC9"}
		},
		"ui": {
			"panel_bg":    {"size": [16, 16], "fallback_color": "#212733"},
			"avatar_ring": {"size": [64, 64], "fallback_color": "#FFFFFF"},
			"card_shadow": {"size": [16, 16], "fallback_color": "#000000"}
		}
	}

func _color_from_hex(hex: String) -> Color:
	if hex.begins_with("#"):
		return Color.html(hex)
	return Color.html("#" + hex)
