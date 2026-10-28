extends RefCounted
class_name SocialUIFactory

const MainNavigationScript = preload("res://ui/navigation/main_navigation.gd")

const ThemeTokens = preload("res://core/theme/theme_tokens.gd")
const ResponsiveMarginControllerScript = preload("res://core/layout/responsive_margin_controller.gd")

static func is_landscape(host: Control) -> bool:
    if host == null:
        return false
    var viewport_size := host.get_viewport_rect().size
    return viewport_size.x > viewport_size.y

static func colors() -> Dictionary:
    return {
        "bg": ThemeTokens.BG,
        "panel": ThemeTokens.PANEL,
        "panel2": ThemeTokens.PANEL_2,
        "text": ThemeTokens.TEXT,
        "muted": ThemeTokens.MUTED,
        "gold": ThemeTokens.GOLD,
        "green": ThemeTokens.GREEN,
        "red": ThemeTokens.RED,
        "border": ThemeTokens.BORDER,
        "button": ThemeTokens.BUTTON,
    }

static func panel_style(fill: Color = ThemeTokens.PANEL, border: Color = ThemeTokens.BORDER, radius: int = 12) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(1)
    box.set_corner_radius_all(radius)
    box.content_margin_left = 12
    box.content_margin_right = 12
    box.content_margin_top = 10
    box.content_margin_bottom = 10
    return box

static func button_style(fill: Color = ThemeTokens.BUTTON, border: Color = ThemeTokens.BORDER, radius: int = 10) -> StyleBoxFlat:
    var box := panel_style(fill, border, radius)
    box.content_margin_left = 10
    box.content_margin_right = 10
    box.content_margin_top = 10
    box.content_margin_bottom = 10
    return box

static func add_background(host: Control) -> ColorRect:
    var bg := ColorRect.new()
    bg.name = "Background"
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = ThemeTokens.BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    host.add_child(bg)
    return bg

static func make_top_bar(title_text: String, host: Control, back_action: Callable = Callable()) -> HBoxContainer:
    var top := HBoxContainer.new()
    top.name = "TopBar"
    top.custom_minimum_size.y = 76
    top.add_theme_constant_override("separation", 8)
    host.add_child(top)
    if back_action.is_valid():
        var back := Button.new()
        back.name = "Back"
        back.text = "‹"
        back.custom_minimum_size = Vector2(64, 64)
        back.add_theme_font_size_override("font_size", 38)
        back.add_theme_color_override("font_color", ThemeTokens.TEXT)
        back.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
        back.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
        back.pressed.connect(back_action)
        top.add_child(back)
    var title := Label.new()
    title.name = "Title"
    title.text = title_text
    title.add_theme_color_override("font_color", ThemeTokens.TEXT)
    var title_font_size := 34
    if title_text.length() > 24:
        title_font_size = 23
    elif title_text.length() > 18:
        title_font_size = 26
    elif title_text.length() > 12:
        title_font_size = 30
    title.add_theme_font_size_override("font_size", title_font_size)
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.autowrap_mode = TextServer.AUTOWRAP_OFF
    title.clip_text = true
    title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    title.custom_minimum_size.x = 0.0
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    return top

static func section_title(text_value: String) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_color_override("font_color", ThemeTokens.MUTED)
    label.add_theme_font_size_override("font_size", 28)
    return label

static func make_primary(text_value: String, height: float = 50) -> Button:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size.y = maxf(height, 52.0)
    b.add_theme_color_override("font_color", ThemeTokens.TEXT)
    b.add_theme_font_size_override("font_size", 31)
    b.add_theme_stylebox_override("normal", button_style(ThemeTokens.GOLD, ThemeTokens.GOLD, 10))
    b.add_theme_stylebox_override("hover", button_style(Color("#E1B65C"), ThemeTokens.GOLD, 10))
    return b

static func make_secondary(text_value: String, height: float = 48) -> Button:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size.y = maxf(height, 48.0)
    b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    b.add_theme_color_override("font_color", ThemeTokens.TEXT)
    b.add_theme_font_size_override("font_size", 28)
    b.add_theme_stylebox_override("normal", button_style(ThemeTokens.BUTTON, ThemeTokens.BORDER, 10))
    b.add_theme_stylebox_override("hover", button_style(ThemeTokens.BUTTON_HOVER, ThemeTokens.GOLD, 10))
    return b


static func configure_main_content_margin(
    host: Control,
    margin: Control,
    top_portrait: float = 14.0,
    bottom_portrait: float = 104.0,
    left_portrait: float = 16.0,
    right_portrait: float = 16.0,
    left_landscape: float = 174.0,
    right_landscape: float = 16.0,
    bottom_landscape: float = 16.0
) -> void:
    var controller := ResponsiveMarginControllerScript.new() as ResponsiveMarginController
    controller.name = "ResponsiveMarginController"
    controller.configure(
        host, margin,
        left_portrait, right_portrait, top_portrait, bottom_portrait,
        left_landscape, right_landscape, 10.0, bottom_landscape
    )
    host.add_child(controller)

static func attach_main_nav(host: Control, active: String, callback: Callable) -> Control:
    var nav := MainNavigationScript.new()
    nav.name = "MainNavigation"
    nav.set_active(active)
    nav.navigate.connect(callback)
    host.add_child(nav)
    return nav
