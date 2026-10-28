extends Control
const ThemePalette = preload("res://core/theme/theme_tokens.gd")
const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

const AppConfig = preload("res://core/services/app.gd")
const BotData = preload("res://domain/bots/bot_data.gd")

const BG := ThemePalette.BG
const PANEL := ThemePalette.PANEL
const PANEL_2 := ThemePalette.PANEL_2
const TEXT := ThemePalette.TEXT
const MUTED := ThemePalette.MUTED
const GOLD := ThemePalette.GOLD

var list_box: VBoxContainer
var selected_bot_id := "mateo"
var info: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_resize()
	get_viewport().size_changed.connect(_resize)

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var top := HBoxContainer.new()
	top.custom_minimum_size.y = 50
	root.add_child(top)
	var back := Button.new()
	back.text = "← Volver"
	back.custom_minimum_size = Vector2(92, 44)
	back.pressed.connect(func(): Navigation.go(ScreenCatalog.MAIN_MENU))
	top.add_child(back)
	var title := Label.new()
	title.text = "VS IA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", TEXT)
	title.add_theme_font_size_override("font_size", 25)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)

	var intro := Label.new()
	intro.text = "Elige un rival por su NEXUS. Los rangos son objetivos de fuerza del motor propio; no afectan tu NEXUS ni tu ranking."
	intro.add_theme_color_override("font_color", MUTED)
	intro.add_theme_font_size_override("font_size", 18)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(intro)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 8)
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)

	var last_difficulty := ""
	for profile in BotData.profiles():
		var difficulty := String(profile.get("difficulty", "Normal"))
		if difficulty != last_difficulty:
			_add_difficulty_header(difficulty)
			last_difficulty = difficulty
		_add_bot(profile)

	info = Label.new()
	info.add_theme_color_override("font_color", MUTED)
	info.add_theme_font_size_override("font_size", 18)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(info)
	_refresh_info()

	var start := Button.new()
	start.text = "JUGAR CONTRA ESTE BOT"
	start.custom_minimum_size.y = 60
	start.add_theme_color_override("font_color", TEXT)
	start.add_theme_font_size_override("font_size", 25)
	start.add_theme_stylebox_override("normal", _style(Color("#6B4F24"), 12, 1, Color("#A87931")))
	start.add_theme_stylebox_override("hover", _style(Color("#7C5B2B"), 12, 1, GOLD))
	start.pressed.connect(_start_game)
	root.add_child(start)


func _add_difficulty_header(difficulty: String) -> void:
	var header := Label.new()
	header.text = "— %s —" % difficulty.to_upper()
	header.add_theme_color_override("font_color", GOLD)
	header.add_theme_font_size_override("font_size", 20)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.custom_minimum_size.y = 28
	list_box.add_child(header)

func _add_bot(profile: Dictionary) -> void:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", _style(PANEL_2, 14, 1, Color("#3D3428")))
	row.custom_minimum_size.y = 84
	list_box.add_child(row)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_theme_constant_override("margin_left", 10)
	row.add_child(h)

	var avatar := TextureRect.new()
	var tex := load(String(profile["avatar"]))
	if tex is Texture2D:
		avatar.texture = tex
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.custom_minimum_size = Vector2(54, 54)
	h.add_child(avatar)

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info_box)
	var name_label := Label.new()
	name_label.text = "%s  ·  NEXUS %d" % [String(profile["name"]), int(profile["nexus"])]
	name_label.add_theme_color_override("font_color", TEXT)
	name_label.add_theme_font_size_override("font_size", 23)
	info_box.add_child(name_label)
	var style_label := Label.new()
	style_label.text = String(profile["style"])
	style_label.add_theme_color_override("font_color", GOLD)
	style_label.add_theme_font_size_override("font_size", 18)
	info_box.add_child(style_label)
	var desc := Label.new()
	desc.text = String(profile["desc"])
	desc.add_theme_color_override("font_color", MUTED)
	desc.add_theme_font_size_override("font_size", 18)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_box.add_child(desc)

	var choose := Button.new()
	choose.text = "Elegir"
	choose.custom_minimum_size = Vector2(78, 42)
	choose.pressed.connect(func(id: String = String(profile["id"])): _select(id))
	h.add_child(choose)

func _select(bot_id: String) -> void:
	selected_bot_id = bot_id
	_refresh_info()

func _refresh_info() -> void:
	var profile := BotData.get_profile(selected_bot_id)
	info.text = "Seleccionado: %s · NEXUS %d · %s" % [String(profile["name"]), int(profile["nexus"]), String(profile["style"])]

func _start_game() -> void:
	var profile := BotData.get_profile(selected_bot_id)
	var app := RuntimeServicesScript.get_autoload("App")
	if app != null:
		app.selected_mode = AppConfig.MODE_VS_BOT
		app.selected_bot_id = selected_bot_id
		app.selected_bot_elo = int(profile["elo"])
		app.selected_bot_nexus = int(profile["nexus"])
		app.temporary_online_bots = false
	Navigation.go(ScreenCatalog.GAME)

func _style(fill: Color, radius: int, border_width: int, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_width)
	s.border_color = border
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _resize() -> void:
	var vp := get_viewport_rect().size
	var portrait := vp.y >= vp.x
	for child in list_box.get_children() if list_box else []:
		child.custom_minimum_size.y = 92.0 if portrait else 82.0
