extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const AppConfig = preload("res://core/services/app.gd")
const ThemePalette = preload("res://core/theme/theme_tokens.gd")

var selected_minutes := 10
var time_buttons: Dictionary = {}
var card: PanelContainer

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build()
    get_viewport().size_changed.connect(_resize)
    _resize()

func _build() -> void:
    var bg := ColorRect.new()
    bg.color = ThemePalette.BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    card = PanelContainer.new()
    card.add_theme_stylebox_override("panel", _panel_style())
    add_child(card)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    root.add_theme_constant_override("margin_left", 18)
    root.add_theme_constant_override("margin_right", 18)
    root.add_theme_constant_override("margin_top", 18)
    root.add_theme_constant_override("margin_bottom", 18)
    card.add_child(root)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 48
    root.add_child(header)
    var back := Button.new()
    back.text = "← Volver"
    back.custom_minimum_size = Vector2(92, 44)
    back.pressed.connect(func(): Navigation.go(ScreenCatalog.MAIN_MENU))
    header.add_child(back)
    var title := Label.new()
    title.text = "1c1 · LOCAL"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_color_override("font_color", ThemePalette.TEXT)
    title.add_theme_font_size_override("font_size", 24)
    header.add_child(title)
    var spacer := Control.new()
    spacer.custom_minimum_size.x = 92
    header.add_child(spacer)

    var subtitle := Label.new()
    subtitle.text = "Dos personas en el mismo dispositivo"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_color_override("font_color", ThemePalette.MUTED)
    root.add_child(subtitle)

    var section := Label.new()
    section.text = "TIEMPO DE PARTIDA"
    section.add_theme_color_override("font_color", ThemePalette.GOLD)
    section.add_theme_font_size_override("font_size", 20)
    root.add_child(section)

    var times := HBoxContainer.new()
    times.add_theme_constant_override("separation", 8)
    root.add_child(times)
    for minutes in [10, 15, 20]:
        var b := Button.new()
        b.text = "%d'" % minutes
        b.custom_minimum_size.y = 52
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(func(m: int = minutes): _select_time(m))
        times.add_child(b)
        time_buttons[minutes] = b

    var hint := Label.new()
    hint.text = "Elige el ritmo antes de comenzar. Podrás jugar por turnos en el mismo dispositivo."
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", ThemePalette.MUTED)
    root.add_child(hint)

    var start := Button.new()
    start.text = "JUGAR 1c1 LOCAL"
    start.custom_minimum_size.y = 58
    start.add_theme_font_size_override("font_size", 25)
    start.pressed.connect(_start)
    root.add_child(start)
    _select_time(selected_minutes)

func _select_time(minutes: int) -> void:
    selected_minutes = minutes
    for key in time_buttons:
        var button: Button = time_buttons[key]
        button.disabled = int(key) == selected_minutes
        if button.disabled:
            button.tooltip_text = "Seleccionado"

func _start() -> void:
    var app := RuntimeServicesScript.get_autoload("App")
    if app != null:
        app.selected_mode = AppConfig.MODE_1C1_LOCAL
        app.selected_time_minutes = selected_minutes
        app.temporary_online_bots = false
    Navigation.go(ScreenCatalog.GAME)

func _resize() -> void:
    if card == null:
        return
    var vp := get_viewport_rect().size
    var w := minf(520.0, vp.x - 32.0)
    var h := minf(430.0, vp.y - 40.0)
    card.size = Vector2(w, h)
    card.position = (vp - card.size) * 0.5

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = ThemePalette.PANEL
    s.set_corner_radius_all(16)
    s.set_border_width_all(1)
    s.border_color = ThemePalette.BORDER
    return s
