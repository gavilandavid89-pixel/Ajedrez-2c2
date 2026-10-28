extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")

var clubs: Node
var body: VBoxContainer
var scroll: ScrollContainer
var search: LineEdit
var list_box: VBoxContainer
var loading := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.configure_main_content_margin(self, margin, 14.0, 120.0, 14.0, 14.0, 174.0, 16.0, 16.0)
    add_child(margin)
    var compact := Factory.is_landscape(self)
    scroll = ScrollContainer.new()
    scroll.name = "ClubScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    margin.add_child(scroll)
    body = VBoxContainer.new()
    body.add_theme_constant_override("separation", 6 if compact else 10)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(body)
    Factory.make_top_bar("Clubes", body, func(): Navigation.go(ScreenCatalog.MAIN_MENU))
    var intro := Label.new()
    intro.text = "Explora clubes. Desliza hasta el final para cargar más."
    intro.add_theme_color_override("font_color", Factory.colors()["muted"])
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.add_theme_font_size_override("font_size", 14 if compact else 16)
    body.add_child(intro)
    search = LineEdit.new()
    search.name = "Search"
    search.placeholder_text = "Buscar club..."
    search.custom_minimum_size.y = 48 if compact else 58
    search.text_changed.connect(_on_search_changed)
    body.add_child(search)
    var create := Factory.make_primary("CREAR MI CLUB", 48 if compact else 52)
    create.pressed.connect(func(): Navigation.go(ScreenCatalog.CLUB_CREATE))
    body.add_child(create)
    body.add_child(Factory.section_title("CLUBES DISPONIBLES"))
    list_box = VBoxContainer.new()
    list_box.name = "ClubList"
    list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_box.add_theme_constant_override("separation", 8)
    body.add_child(list_box)
    clubs = get_node_or_null("/root/ClubsService")
    if clubs != null:
        clubs.page_loaded.connect(_refresh)
    var bar := scroll.get_v_scroll_bar()
    bar.value_changed.connect(_on_scroll_changed)
    _refresh()
    Factory.attach_main_nav(self, "club", _on_nav)

func _on_search_changed(_value: String) -> void:
    _refresh()

func _on_scroll_changed(value: float) -> void:
    if loading or search.text.strip_edges() != "" or clubs == null or not clubs.can_load_more():
        return
    var bar := scroll.get_v_scroll_bar()
    if value >= bar.max_value - bar.page - 80:
        loading = true
        clubs.load_more()
        loading = false

func _refresh() -> void:
    if list_box == null:
        return
    for child in list_box.get_children():
        child.queue_free()
    var rows: Array = [] if clubs == null else clubs.visible_clubs(search.text)
    if rows.is_empty():
        var empty := Label.new()
        empty.text = "No encontramos clubes con esa búsqueda."
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty.add_theme_color_override("font_color", Factory.colors()["muted"])
        list_box.add_child(empty)
        return
    for club in rows:
        _add_club_card(club)

func _add_club_card(club: Dictionary) -> void:
    var access_type := String(club.get("access_type", "public"))
    var compact := Factory.is_landscape(self)
    var card := Button.new()
    card.custom_minimum_size.y = (70.0 if access_type == "public" else 80.0) if compact else (86.0 if access_type == "public" else 106.0)
    card.alignment = HORIZONTAL_ALIGNMENT_LEFT
    card.add_theme_stylebox_override("normal", Factory.panel_style())
    card.add_theme_stylebox_override("hover", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 12))
    card.add_theme_stylebox_override("pressed", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 12))
    card.pressed.connect(func(): _open_club(String(club.get("id", ""))))
    list_box.add_child(card)
    var row := HBoxContainer.new()
    row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    row.offset_left = 10
    row.offset_right = -10
    row.offset_top = 4
    row.offset_bottom = -4
    row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_theme_constant_override("separation", 10)
    card.add_child(row)
    var icon := Label.new()
    icon.text = String(club.get("icon", "♟"))
    icon.custom_minimum_size = Vector2(48, 48) if compact else Vector2(64, 64)
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 26 if compact else 32)
    row.add_child(icon)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    var name := Label.new()
    name.text = String(club.get("name", "Club"))
    name.add_theme_color_override("font_color", Factory.colors()["text"])
    name.add_theme_font_size_override("font_size", 20 if compact else 24)
    name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_child(name)
    var meta := Label.new()
    var access := "Público" if access_type == "public" else ("Privado · NEXUS %d" % int(club.get("min_nexus", 0)) if access_type == "nexus" else "Privado · Invitación")
    meta.text = "%d miembros · %s" % [int(club.get("members", 0)), access]
    meta.add_theme_color_override("font_color", Factory.colors()["muted"])
    meta.add_theme_font_size_override("font_size", 15 if compact else 19)
    meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_child(meta)


func _open_club(club_id: String) -> void:
    var service := clubs
    if service != null:
        service.mark_detail_seen(club_id)
    Navigation.go(ScreenCatalog.CLUB_DETAIL)

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club":
            if clubs != null and not String(clubs.active_club_id).is_empty():
                Navigation.go(ScreenCatalog.CLUB_CHAT)
            else:
                pass
        "friends": Navigation.go(ScreenCatalog.FRIENDS)
        "more": Navigation.go(ScreenCatalog.MORE)
