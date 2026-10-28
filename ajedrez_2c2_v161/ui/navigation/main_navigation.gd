extends Control
class_name MainNavigation

signal navigate(section: String)

const BG := Color("#14110E")
const BORDER := Color("#342B21")
const TEXT := Color("#AFA18A")
const ACTIVE_TEXT := Color("#F0E3C4")
const ACTIVE_FILL := Color("#2B2115")
const ACTIVE_BORDER := Color("#D5A84E")

const ITEMS := [
    {"id": "home", "icon": "⌂", "label": "Inicio"},
    {"id": "club", "icon": "♜", "label": "Club"},
    {"id": "friends", "icon": "♟", "label": "Amigos"},
    {"id": "more", "icon": "⋯", "label": "Más"},
]

var _bar: Panel
var _container: BoxContainer
var _buttons: Dictionary = {}
var _active := ""

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build()
    _refresh_layout()
    get_viewport().size_changed.connect(_on_viewport_changed)

func _exit_tree() -> void:
    var viewport := get_viewport()
    if viewport != null and viewport.size_changed.is_connected(_on_viewport_changed):
        viewport.size_changed.disconnect(_on_viewport_changed)

func _build() -> void:
    _bar = Panel.new()
    _bar.name = "Bar"
    _bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
    _bar.size_flags_horizontal = Control.SIZE_FILL
    _bar.add_theme_stylebox_override("panel", _bar_style())
    add_child(_bar)
    _container = BoxContainer.new()
    _container.name = "Items"
    _container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _container.offset_left = 6
    _container.offset_right = -6
    _container.offset_top = 6
    _container.offset_bottom = -6
    _container.size_flags_horizontal = Control.SIZE_FILL
    _container.add_theme_constant_override("separation", 4)
    _bar.add_child(_container)
    for item in ITEMS:
        var button := Button.new()
        button.name = String(item["id"]).capitalize()
        button.focus_mode = Control.FOCUS_NONE
        button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
        button.text = "%s\n%s" % [String(item["icon"]), String(item["label"])]
        button.add_theme_font_size_override("font_size", 21)
        button.add_theme_color_override("font_color", TEXT)
        button.add_theme_color_override("font_hover_color", ACTIVE_TEXT)
        button.add_theme_stylebox_override("normal", _button_style(false))
        button.add_theme_stylebox_override("hover", _button_style(false, true))
        button.add_theme_stylebox_override("pressed", _button_style(true))
        var id := String(item["id"])
        button.pressed.connect(func(): navigate.emit(id))
        _container.add_child(button)
        _buttons[id] = button

func set_active(section: String) -> void:
    _active = section
    for id in _buttons:
        var button: Button = _buttons[id]
        var active := String(id) == section
        button.add_theme_color_override("font_color", ACTIVE_TEXT if active else TEXT)
        button.add_theme_stylebox_override("normal", _button_style(active))
        var viewport_size := get_viewport_rect().size
        var portrait := viewport_size.y >= viewport_size.x
        var compact := portrait and viewport_size.x < 420.0
        button.add_theme_font_size_override("font_size", (22 if active else 21) if compact else (24 if active else 22))

func _on_viewport_changed() -> void:
    _refresh_layout()

func _refresh_layout() -> void:
    if _bar == null or _container == null:
        return
    var size := get_viewport_rect().size
    var portrait := size.y >= size.x
    set_anchors_preset(Control.PRESET_FULL_RECT)
    offset_left = 10
    offset_right = -10
    if portrait:
        offset_top = 0
        offset_bottom = -10
        _bar.position = Vector2(0, maxf(0.0, size.y - 106.0))
        _bar.size = Vector2(maxf(0.0, size.x - 20.0), 96.0)
        _container.vertical = false
        _container.alignment = BoxContainer.ALIGNMENT_CENTER
        for button in _buttons.values():
            button.custom_minimum_size = Vector2(maxf(76.0, (size.x - 44.0) / 4.0), 84.0)
            button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            button.text = _button_text(button.name)
    else:
        offset_top = 10
        offset_bottom = -10
        _bar.position = Vector2(0, 0)
        _bar.custom_minimum_size.x = 160.0
        _bar.size = Vector2(160.0, maxf(0.0, size.y - 20.0))
        _container.vertical = true
        _container.alignment = BoxContainer.ALIGNMENT_CENTER
        for button in _buttons.values():
            button.custom_minimum_size = Vector2(144.0, 88.0)
            button.size_flags_horizontal = Control.SIZE_FILL
            button.text = _button_text(button.name, true)
    set_active(_active)

func _button_text(button_name: String, landscape: bool = false) -> String:
    for item in ITEMS:
        if String(item["id"]).capitalize() == button_name:
            return "%s  %s" % [String(item["icon"]), String(item["label"])] if landscape else "%s\n%s" % [String(item["icon"]), String(item["label"])]
    return button_name

func _bar_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = BG
    style.border_color = BORDER
    style.set_border_width_all(1)
    style.set_corner_radius_all(16)
    style.content_margin_left = 6
    style.content_margin_right = 6
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    return style

func _button_style(active: bool, hover: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = ACTIVE_FILL if active else (Color("#201A14") if hover else Color(0, 0, 0, 0))
    style.border_color = ACTIVE_BORDER if active else (Color("#4B3E2D") if hover else Color(0, 0, 0, 0))
    style.set_border_width_all(1 if (active or hover) else 0)
    style.set_corner_radius_all(11)
    style.content_margin_left = 5
    style.content_margin_right = 5
    style.content_margin_top = 5
    style.content_margin_bottom = 5
    return style
