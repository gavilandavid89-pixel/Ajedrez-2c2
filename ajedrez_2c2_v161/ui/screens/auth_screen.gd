extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

var auth: Node
var sync: Node
var body: VBoxContainer
var status_label: Label
var message_label: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    auth = RuntimeServicesScript.get_autoload("AuthService")
    sync = RuntimeServicesScript.get_autoload("AccountSync")
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.offset_left = 16
    margin.offset_right = -16
    margin.offset_top = 14.0 if get_viewport_rect().size.y >= get_viewport_rect().size.x else 10.0
    margin.offset_bottom = -16
    add_child(margin)
    Factory.configure_main_content_margin(self, margin, 14.0, 16.0, 16.0, 16.0, 16.0, 16.0, 16.0)
    var scroll := ScrollContainer.new()
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    margin.add_child(scroll)
    body = VBoxContainer.new()
    body.add_theme_constant_override("separation", 10)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(body)
    Factory.make_top_bar("Cuenta y progreso", body, func(): Navigation.go(ScreenCatalog.MORE))
    _build()
    if auth != null and auth.has_signal("auth_changed"):
        auth.auth_changed.connect(_refresh)
    if auth != null and auth.has_signal("message_changed"):
        auth.message_changed.connect(_show_message)
    if sync != null and sync.has_signal("state_changed"):
        sync.state_changed.connect(_on_sync_state_changed)
    _refresh(auth.current_account() if auth != null else {})

func _build() -> void:
    var intro := Label.new()
    intro.text = "Conecta una cuenta para conservar tu progreso fuera de este dispositivo. El progreso local sigue funcionando aunque no haya conexión."
    intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    intro.add_theme_color_override("font_color", Factory.colors()["muted"])
    body.add_child(intro)

    status_label = Label.new()
    status_label.name = "AccountStatus"
    status_label.add_theme_font_size_override("font_size", 23)
    status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(status_label)

    message_label = Label.new()
    message_label.name = "AccountMessage"
    message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    message_label.add_theme_color_override("font_color", Factory.colors()["muted"])
    body.add_child(message_label)

    var section := Factory.section_title("INICIAR SESIÓN")
    section.name = "ProviderSection"
    body.add_child(section)
    _provider_button("Google", "google", "Continuar con Google")
    _provider_button("Facebook", "facebook", "Continuar con Facebook")
    _provider_button("Google Play Juegos", "play_games", "Continuar con Google Play Juegos")
    _provider_button("Correo electrónico", "email", "Preparar acceso por correo")

    var info := PanelContainer.new()
    info.name = "DataPolicy"
    info.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["border"], 12))
    body.add_child(info)
    var info_box := VBoxContainer.new()
    info.add_child(info_box)
    var title := Label.new()
    title.text = "🔐 Datos que podemos pedir"
    title.add_theme_font_size_override("font_size", 22)
    info_box.add_child(title)
    var data := Label.new()
    data.text = "Nombre mostrado · correo · foto de perfil · estado de verificación.\nLos tokens de sesión no se guardan dentro de tu progreso. El servidor debe validar el token recibido del proveedor."
    data.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    data.add_theme_color_override("font_color", Factory.colors()["muted"])
    info_box.add_child(data)

func _provider_button(label: String, provider: String, text_value: String) -> void:
    var row := HBoxContainer.new()
    row.name = "Provider_%s" % provider
    row.add_theme_constant_override("separation", 6)
    body.add_child(row)
    var button := Factory.make_secondary(text_value, 52)
    button.name = "SignIn_%s" % provider
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.pressed.connect(func(): _sign_in(provider))
    row.add_child(button)
    var state := Label.new()
    state.name = "State"
    state.custom_minimum_size.x = 128
    state.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    state.autowrap_mode = TextServer.AUTOWRAP_OFF
    state.clip_text = false
    state.text = "Listo" if auth != null and auth.provider_available(provider) else "Preparado"
    state.add_theme_color_override("font_color", Factory.colors()["muted"])
    row.add_child(state)

func _sign_in(provider: String) -> void:
    if auth == null:
        return
    var result: Dictionary = auth.sign_in(provider)
    if not bool(result.get("ok", false)):
        _show_message(String(result.get("reason", "No se pudo iniciar sesión")))
    else:
        _show_message("Abriendo %s…" % auth.provider_label(provider))

func _on_sync_state_changed(_status: String, _detail: Dictionary) -> void:
    _refresh(auth.current_account() if auth != null else {})

func _refresh(account_state: Dictionary) -> void:
    if status_label == null:
        return
    var authenticated := String(account_state.get("status", "anonymous")) == "authenticated"
    if authenticated:
        var name := String(account_state.get("display_name", "Cuenta"))
        var provider := String(account_state.get("provider", ""))
        status_label.text = "✅ Cuenta conectada\n%s · %s" % [name, auth.provider_label(provider) if auth != null else provider]
        if sync != null:
            var sync_text := String(sync.last_status)
            if sync_text == "synced":
                message_label.text = "☁ Progreso respaldado y sincronizado."
            elif sync_text == "conflict":
                message_label.text = "⚠ Hay un conflicto entre este dispositivo y la nube. Ningún progreso se sobreescribió automáticamente."
                _add_conflict_controls()
            else:
                message_label.text = "☁ Cuenta conectada. El respaldo se hará cuando haya servidor configurado."
        _add_account_controls(account_state)
    else:
        var linked := String(account_state.get("account_id", "")).strip_edges() != "" and String(account_state.get("status", "")) == "linked"
        if linked:
            status_label.text = "🔗 Cuenta vinculada\n%s · inicia sesión para sincronizarla." % String(account_state.get("display_name", "Cuenta"))
        else:
            status_label.text = "💾 Cuenta local\nTu progreso se guarda en este dispositivo."

func _add_account_controls(account_state: Dictionary) -> void:
    if body.find_child("AccountControls", true, false) != null:
        return
    var section := Factory.section_title("CUENTA")
    section.name = "AccountControls"
    body.add_child(section)
    var refresh := Factory.make_secondary("ACTUALIZAR DATOS DE PERFIL", 48)
    refresh.name = "RefreshProfile"
    refresh.pressed.connect(func():
        if auth != null:
            var result: Dictionary = auth.request_profile_data()
            _show_message(String(result.get("status", "Datos solicitados")))
    )
    body.add_child(refresh)
    var linked: Array = account_state.get("linked_providers", []) if account_state.get("linked_providers", []) is Array else []
    for provider in ["google", "facebook", "play_games", "email"]:
        if linked.has(provider):
            continue
        var link: Button = Factory.make_secondary("VINCULAR %s" % (auth.provider_label(provider) if auth != null else provider), 44)
        link.name = "Link_%s" % provider
        link.pressed.connect(func(provider_id: String = provider):
            if auth != null:
                var result: Dictionary = auth.link_provider(provider_id)
                _show_message(String(result.get("reason", result.get("status", "Vinculación solicitada"))))
        )
        body.add_child(link)
    _add_sign_out_button()

func _add_sign_out_button() -> void:
    if body.find_child("SignOut", true, false) != null:
        return
    var button := Factory.make_secondary("CERRAR SESIÓN", 48)
    button.name = "SignOut"
    button.pressed.connect(func():
        if auth != null:
            auth.sign_out()
        Navigation.go(ScreenCatalog.MORE)
    )
    body.add_child(button)

func _add_conflict_controls() -> void:
    if body.find_child("ConflictControls", true, false) != null:
        return
    var box := HBoxContainer.new()
    box.name = "ConflictControls"
    box.add_theme_constant_override("separation", 6)
    body.add_child(box)
    var local := Factory.make_secondary("CONSERVAR ESTE DISPOSITIVO", 48)
    local.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    local.pressed.connect(func():
        if sync != null:
            await sync.keep_local_progress()
            _refresh(auth.current_account())
    )
    box.add_child(local)
    var cloud := Factory.make_secondary("RESTAURAR NUBE", 48)
    cloud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cloud.pressed.connect(func():
        if sync != null:
            await sync.restore_cloud_progress()
            _refresh(auth.current_account())
    )
    box.add_child(cloud)

func _show_message(message: String) -> void:
    if message_label != null:
        message_label.text = message

func _exit_tree() -> void:
    if auth != null and is_instance_valid(auth):
        if auth.has_signal("auth_changed") and auth.auth_changed.is_connected(_refresh):
            auth.auth_changed.disconnect(_refresh)
        if auth.has_signal("message_changed") and auth.message_changed.is_connected(_show_message):
            auth.message_changed.disconnect(_show_message)
    if sync != null and is_instance_valid(sync):
        if sync.has_signal("state_changed") and sync.state_changed.is_connected(_on_sync_state_changed):
            sync.state_changed.disconnect(_on_sync_state_changed)

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club":
            var clubs := get_node_or_null("/root/ClubsService")
            Navigation.go(ScreenCatalog.CLUB_CHAT if clubs != null and not String(clubs.active_club_id).is_empty() else ScreenCatalog.CLUBS)
        "friends": Navigation.go(ScreenCatalog.FRIENDS)
        "more": Navigation.go(ScreenCatalog.MORE)
