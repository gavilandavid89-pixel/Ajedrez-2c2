extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")

var name_edit: LineEdit
var description_edit: TextEdit
var access: OptionButton
var nexus_edit: SpinBox
var create_button: Button
var selected_icon := "♞"
var selected_gallery_path := ""
var icon_buttons: Array[Button] = []

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    Factory.configure_main_content_margin(self, margin, 14.0, 16.0, 16.0, 16.0, 16.0, 16.0, 16.0)
    margin.custom_minimum_size.x = 0.0
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size.x = 0.0
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    margin.add_child(scroll)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 10)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.custom_minimum_size.x = 0.0
    scroll.add_child(body)
    Factory.make_top_bar("Crear club", body, func(): Navigation.go(ScreenCatalog.CLUBS))

    body.add_child(Factory.section_title("NOMBRE"))
    name_edit = LineEdit.new()
    name_edit.placeholder_text = "Nombre del club"
    name_edit.max_length = 30
    name_edit.custom_minimum_size.y = 48
    name_edit.text_changed.connect(_validate)
    body.add_child(name_edit)

    body.add_child(Factory.section_title("ICONO"))
    var icon_row := HBoxContainer.new()
    icon_row.add_theme_constant_override("separation", 8)
    body.add_child(icon_row)
    var icon_scroll := ScrollContainer.new()
    icon_scroll.name = "IconChoicesScroll"
    icon_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    icon_scroll.custom_minimum_size.y = 48.0
    icon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    icon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    icon_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
    icon_row.add_child(icon_scroll)
    var icons := HBoxContainer.new()
    icons.name = "IconChoices"
    icons.add_theme_constant_override("separation", 4)
    icon_scroll.add_child(icons)
    for symbol in ["♞", "♜", "♝", "♛", "♚", "♟"]:
        var b := Button.new()
        b.text = symbol
        b.custom_minimum_size = Vector2(40.0, 48.0)
        b.add_theme_font_size_override("font_size", 22)
        b.pressed.connect(func(): _select_icon(symbol))
        icons.add_child(b)
        icon_buttons.append(b)
    var gallery := Factory.make_secondary("GALERÍA", 48)
    gallery.name = "GalleryButton"
    gallery.custom_minimum_size = Vector2(82.0, 48.0)
    gallery.add_theme_font_size_override("font_size", 12)
    gallery.autowrap_mode = TextServer.AUTOWRAP_OFF
    gallery.clip_text = true
    gallery.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    gallery.pressed.connect(_open_gallery)
    icon_row.add_child(gallery)

    body.add_child(Factory.section_title("DESCRIPCIÓN · OPCIONAL"))
    description_edit = TextEdit.new()
    description_edit.placeholder_text = "Cuenta de qué trata tu club"
    description_edit.custom_minimum_size.y = 100
    description_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
    body.add_child(description_edit)

    body.add_child(Factory.section_title("ACCESO"))
    access = OptionButton.new()
    access.custom_minimum_size.y = 48
    access.add_item("Público · entrada directa", 0)
    access.add_item("Privado · NEXUS + aprobación", 1)
    access.add_item("Privado · solo invitación", 2)
    access.item_selected.connect(_validate)
    body.add_child(access)

    nexus_edit = SpinBox.new()
    nexus_edit.name = "MinimumNexus"
    nexus_edit.min_value = 0
    nexus_edit.max_value = 3000
    nexus_edit.step = 50
    nexus_edit.value = 500
    nexus_edit.custom_minimum_size.y = 48
    nexus_edit.prefix = "NEX mínimo: "
    nexus_edit.visible = false
    body.add_child(nexus_edit)

    create_button = Factory.make_primary("CREAR CLUB", 54)
    create_button.disabled = true
    create_button.pressed.connect(_create)
    body.add_child(create_button)
    _select_icon(selected_icon)
    _validate()

func _select_icon(symbol: String) -> void:
    selected_icon = symbol
    for b in icon_buttons:
        b.add_theme_color_override("font_color", Factory.colors()["gold"] if b.text == symbol else Factory.colors()["text"])
    _validate()

func _validate(_unused: Variant = null) -> void:
    if create_button == null:
        return
    nexus_edit.visible = access != null and access.selected == 1
    if nexus_edit.visible:
        nexus_edit.tooltip_text = "El solicitante debe cumplir este NEXUS y luego un Rey/Dama puede aceptar o rechazar."
    create_button.disabled = name_edit == null or name_edit.text.strip_edges().is_empty() or selected_icon.is_empty()

func _open_gallery() -> void:
    var dialog := FileDialog.new()
    dialog.name = "ClubGallery"
    dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    dialog.access = FileDialog.ACCESS_FILESYSTEM
    dialog.filters = PackedStringArray(["*.png ; PNG", "*.jpg ; JPG", "*.jpeg ; JPEG", "*.webp ; WEBP"])
    dialog.title = "Seleccionar icono del club"
    dialog.file_selected.connect(func(path: String):
        selected_gallery_path = path
        if create_button != null:
            create_button.tooltip_text = "Icono de galería seleccionado"
    )
    add_child(dialog)
    dialog.popup_centered_ratio(0.85)

func _create() -> void:
    var clubs := get_node_or_null("/root/ClubsService")
    if clubs == null:
        return
    var access_type := "public"
    if access.selected == 1:
        access_type = "nexus"
    elif access.selected == 2:
        access_type = "invite"
    var created: Dictionary = clubs.create_club(name_edit.text, selected_icon, description_edit.text, access_type, int(nexus_edit.value), selected_gallery_path)
    if created.is_empty():
        return
    Navigation.go(ScreenCatalog.CLUB_DETAIL)
