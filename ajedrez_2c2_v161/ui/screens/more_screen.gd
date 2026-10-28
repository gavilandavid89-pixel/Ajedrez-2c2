extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")

var content: VBoxContainer

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.configure_main_content_margin(self, margin, 10.0, 120.0, 12.0, 12.0, 174.0, 12.0, 12.0)
    add_child(margin)
    var compact := Factory.is_landscape(self)
    var scroll := ScrollContainer.new()
    scroll.name = "MoreScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    margin.add_child(scroll)
    content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 8 if compact else 12)
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(content)
    Factory.make_top_bar("Más", content, func(): Navigation.go(ScreenCatalog.MAIN_MENU))
    _build_options()
    Factory.attach_main_nav(self, "more", _on_nav)

func _build_options() -> void:
    content.add_child(Factory.section_title("CUENTA"))
    _add_option("☁  Cuenta y progreso", "Google, Facebook, Play Juegos y respaldo de datos", "auth")
    content.add_child(Factory.section_title("CONFIGURACIÓN"))
    _add_option("⚙  Ajustes", "Preferencias, privacidad y comportamiento", "settings")
    _add_option("👤  Identidad", "Avatar, marco y título", "appearance")
    _add_option("🎨  Experiencia", "Tablero, piezas y reacciones", "reactions")
    content.add_child(Factory.section_title("COMPETITIVO"))
    _add_option("📊  Rankings", "Clasificaciones 1c1 y 2c2", "ranking")
    _add_option("🏆  Copas", "Copas, liga y progreso", "cups")
    _add_option("🧠  NEXUS", "Resumen de tu sistema competitivo", "profile")
    content.add_child(Factory.section_title("AYUDA"))
    _add_option("❔  Ayuda", "Cómo jugar y entender los modos", "help")

func _add_option(label: String, subtitle: String, page: String) -> void:
    var compact := Factory.is_landscape(self)
    var button := Factory.make_secondary("%s\n%s" % [label, subtitle], 82 if compact else 108)
    button.custom_minimum_size.x = 0.0
    button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.alignment = HORIZONTAL_ALIGNMENT_LEFT
    button.add_theme_font_size_override("font_size", 19 if compact else 23)
    button.add_theme_constant_override("h_separation", 8)
    button.pressed.connect(func():
        if page == "auth":
            Navigation.go(ScreenCatalog.AUTH)
            return
        var app := get_node_or_null("/root/App")
        if app != null:
            app.account_start_page = page
        Navigation.go(ScreenCatalog.ACCOUNT)
    )
    content.add_child(button)

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club":
            var clubs := get_node_or_null("/root/ClubsService")
            if clubs != null and not String(clubs.active_club_id).is_empty():
                Navigation.go(ScreenCatalog.CLUB_CHAT)
            else:
                Navigation.go(ScreenCatalog.CLUBS)
        "friends": Navigation.go(ScreenCatalog.FRIENDS)
        "more": pass
