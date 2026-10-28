extends RefCounted
class_name AccountPageRenderer

var _preview_board_theme: String = ""
var _preview_piece_set: String = ""

const ThemePalette = preload("res://core/theme/theme_tokens.gd")
const AppConfig = preload("res://core/services/app.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")
const Competitive = preload("res://domain/competitive/competitive_system.gd")
const NexusTeam = preload("res://domain/competitive/nexus_team.gd")
const EmoteDataScript = preload("res://domain/player/emote_data.gd")

const BG := ThemePalette.BG
const PANEL := ThemePalette.PANEL
const TEXT := ThemePalette.TEXT
const MUTED := ThemePalette.MUTED
const GOLD := ThemePalette.GOLD

var host: Control
var body: VBoxContainer
var stat_grid: GridContainer
static var _avatar_texture_cache: Dictionary = {}

var page: String:
    get: return String(host.page)
    set(value): host.page = value
var selected_history_index: int:
    get: return int(host.selected_history_index)
    set(value): host.selected_history_index = value

func _init(p_host: Control) -> void:
    host = p_host
    body = host.body

func get_tree() -> SceneTree:
    return host.get_tree()

func render(section: String) -> void:
    body = host.body
    match section:
        "profile": _build_profile()
        "profile_edit": _build_profile_edit()
        "ranking": _build_ranking()
        "cups": _build_cups()
        "history": _build_history()
        "analysis": _build_analysis()
        "replay": _build_replay()
        "appearance": _build_appearance()
        "reactions": _build_reactions()
        "settings": _build_settings()
        "more": _build_more()
        "help": _build_help()
        _: pass
    _apply_mobile_readability()

func _apply_mobile_readability() -> void:
    if body == null or not is_instance_valid(body):
        return
    var viewport := _layout_viewport()
    if viewport.x >= viewport.y:
        return
    # Account subpages used several 14–16 px labels and short tap targets.
    # Raise only the small text and touch controls, preserving larger headings.
    var stack: Array[Control] = [body]
    while not stack.is_empty():
        var control: Control = stack.pop_back()
        for child in control.get_children():
            if child is Control:
                stack.append(child)
        if control is Button:
            var button := control as Button
            button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 50.0)
            var font_size := button.get_theme_font_size("font_size")
            if font_size < 20:
                button.add_theme_font_size_override("font_size", 20)
        elif control is Label:
            var label := control as Label
            var font_size := label.get_theme_font_size("font_size")
            if font_size > 0 and font_size < 18:
                label.add_theme_font_size_override("font_size", 18)
        elif control is LineEdit or control is TextEdit or control is OptionButton:
            control.custom_minimum_size.y = maxf(control.custom_minimum_size.y, 48.0)
            control.add_theme_font_size_override("font_size", maxf(18.0, control.get_theme_font_size("font_size")))

func _build_profile() -> void:
    var data = _data()
    var profile: Dictionary = data.profile
    var stats: Dictionary = data.individual

    var header := _card()
    body.add_child(header)
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 12)
    _card_content(header).add_child(h)

    var avatar := TextureRect.new()
    var path := String(profile.get("avatar", "res://assets/avatars/avatar_you.svg"))
    _set_avatar_texture(avatar, path)
    avatar.custom_minimum_size = Vector2(68, 68)
    avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    h.add_child(avatar)

    var info := VBoxContainer.new()
    info.add_theme_constant_override("separation", 0)
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    h.add_child(info)
    var name_label := Label.new()
    name_label.text = String(profile.get("name", "Tú"))
    name_label.add_theme_color_override("font_color", _name_color(data.get_appearance("name_color", "cream")))
    name_label.add_theme_font_size_override("font_size", 29)
    info.add_child(name_label)
    var sub := Label.new()
    sub.text = "Rating %d" % int(stats.get("rating", Competitive.DEFAULT_RATING))
    sub.add_theme_color_override("font_color", MUTED)
    sub.add_theme_font_size_override("font_size", 18)
    sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sub.custom_minimum_size.x = 0
    sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    sub.clip_text = true
    sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    sub.custom_minimum_size.y = 16
    info.add_child(sub)

    var league: Dictionary = data.current_league()
    var league_label := Label.new()
    league_label.text = "Liga %s · temporadas: próximamente" % String(league.get("name", "Bronce"))
    league_label.add_theme_color_override("font_color", GOLD)
    league_label.add_theme_font_size_override("font_size", 18)
    league_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    league_label.custom_minimum_size.x = 0
    league_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    league_label.clip_text = true
    league_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    league_label.custom_minimum_size.y = 16
    info.add_child(league_label)

    var edit := Button.new()
    edit.text = "✎  EDITAR PERFIL"
    edit.custom_minimum_size.y = 50
    edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    edit.pressed.connect(func(): page = "profile_edit"; _refresh())
    _card_content(header).add_child(edit)

    stat_grid = GridContainer.new()
    stat_grid.name = "StatsGrid"
    stat_grid.columns = 2 if _layout_viewport().y >= _layout_viewport().x else 4
    stat_grid.add_theme_constant_override("h_separation", 8)
    stat_grid.add_theme_constant_override("v_separation", 8)
    body.add_child(stat_grid)
    for spec in [["Copas", int(stats.get("cups", 0))], ["Rating", int(stats.get("rating", Competitive.DEFAULT_RATING))], ["Partidas", int(stats.get("games", 0))], ["Victorias", int(stats.get("wins", 0))]]:
        stat_grid.add_child(_stat_card(String(spec[0]), str(spec[1])))

    var recent := _card()
    body.add_child(recent)
    var rt := Label.new()
    rt.text = "Actividad reciente"
    rt.add_theme_color_override("font_color", TEXT)
    rt.add_theme_font_size_override("font_size", 23)
    _card_content(recent).add_child(rt)
    if data.history.is_empty():
        _card_content(recent).add_child(_muted("Todavía no hay resultados registrados."))
    else:
        for item in data.history.slice(maxi(0, data.history.size() - 5)):
            var mode_name := "2c2" if int(item.get("mode", 0)) == AppConfig.MODE_2C2 else "1c1"
            var outcome := String(item.get("outcome", "draw")).capitalize()
            var cup_delta := int(item.get("cup_delta", 0))
            var rating_delta := int(item.get("rating_delta", 0))
            var line := Label.new()
            line.text = "%s · %s · rating %+d · copas %+d" % [mode_name, outcome, rating_delta, cup_delta]
            line.add_theme_color_override("font_color", MUTED)
            line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            _card_content(recent).add_child(line)

    var split_card := _card()
    body.add_child(split_card)
    _card_content(split_card).add_child(_section_title("Resumen por modalidad"))
    var split_grid := GridContainer.new()
    split_grid.columns = 2 if _layout_viewport().x < 640.0 else 4
    split_grid.add_theme_constant_override("h_separation", 8)
    split_grid.add_theme_constant_override("v_separation", 8)
    _card_content(split_card).add_child(split_grid)
    for mode_spec in [[AppConfig.MODE_1C1, "1v1"], [AppConfig.MODE_2C2, "2v2"]]:
        var summary := _history_mode_summary(data.history, int(mode_spec[0]))
        var games := int(summary["games"])
        var wins := int(summary["wins"])
        var rate := (float(wins) / float(games)) * 100.0 if games > 0 else 0.0
        split_grid.add_child(_stat_card("%s · Partidas" % String(mode_spec[1]), str(games)))
        split_grid.add_child(_stat_card("%s · Victorias" % String(mode_spec[1]), "%d (%.0f%%)" % [wins, rate]))

    var records := _card()
    body.add_child(records)
    _card_content(records).add_child(_section_title("Récords"))
    var record_grid := GridContainer.new()
    record_grid.columns = 2 if _layout_viewport().x < 640.0 else 4
    record_grid.add_theme_constant_override("h_separation", 8)
    record_grid.add_theme_constant_override("v_separation", 8)
    _card_content(records).add_child(record_grid)
    record_grid.add_child(_stat_card("Mejor rating", str(int(stats.get("best_rating", Competitive.DEFAULT_RATING)))))
    record_grid.add_child(_stat_card("Racha actual", str(_current_streak(data))))
    record_grid.add_child(_stat_card("Parejas", str(data.pair_records.size())))
    var best_pair := _best_pair(data)
    record_grid.add_child(_stat_card("Mejor pareja", String(best_pair.get("display_name", "—")) if not best_pair.is_empty() else "—"))

    var achievements := _card()
    body.add_child(achievements)
    _card_content(achievements).add_child(_section_title("Logros"))
    _card_content(achievements).add_child(_muted("Sistema preparado. Los logros, sus condiciones y recompensas se definirán más adelante."))

    _build_2c2_profile(data)
    _build_profile_personalization(data)



func _build_profile_edit() -> void:
    var data: Object = _data()

    var intro := _card()
    body.add_child(intro)
    _card_content(intro).add_child(_section_title("✎ Editar perfil"))
    _card_content(intro).add_child(_muted("Todo lo que aparece aquí forma parte de tu identidad pública. Los cambios se guardan en el perfil local y quedarán listos para sincronización con tu cuenta."))
    _add_profile_preview(intro, data)

    var name_card := _card()
    body.add_child(name_card)
    _card_content(name_card).add_child(_section_title("Nombre"))
    var name_edit := LineEdit.new()
    name_edit.name = "ProfileNameEdit"
    name_edit.text = String(data.profile.get("name", "Tú"))
    name_edit.placeholder_text = "Nombre (1-10 caracteres)"
    name_edit.max_length = PlayerDataScript.MAX_DISPLAY_NAME_LENGTH
    name_edit.custom_minimum_size.y = 48
    _card_content(name_card).add_child(name_edit)
    var save_name := Button.new()
    save_name.text = "Guardar nombre"
    save_name.custom_minimum_size.y = 44
    save_name.pressed.connect(func():
        if data.set_display_name(name_edit.text):
            _refresh()
        else:
            name_edit.grab_focus()
    )
    _card_content(name_card).add_child(save_name)

    var icon_card := _card()
    body.add_child(icon_card)
    _card_content(icon_card).add_child(_section_title("Icono"))
    _add_edit_icon_controls(icon_card, data)

    var title_card := _card()
    body.add_child(title_card)
    _card_content(title_card).add_child(_section_title("Título"))
    _add_title_choice(_card_content(title_card), "Jugador", "Título base disponible", "jugador", true, data.get_appearance("player_title", "jugador"))
    _add_title_choice(_card_content(title_card), "Estratega", "Título alternativo disponible", "estratega", true, data.get_appearance("player_title", "jugador"))
    _add_title_choice(_card_content(title_card), "Veterano", "Título alternativo disponible", "veterano", true, data.get_appearance("player_title", "jugador"))

    var frame_card := _card()
    body.add_child(frame_card)
    _card_content(frame_card).add_child(_section_title("Marco"))
    _add_profile_frame_choice(_card_content(frame_card), "Clásico", "Marco base", "classic", data.get_appearance("profile_frame", "classic"))
    _add_profile_frame_choice(_card_content(frame_card), "Dorado", "Marco destacado preparado para personalización", "gold", data.get_appearance("profile_frame", "classic"))

    var color_card := _card()
    body.add_child(color_card)
    _card_content(color_card).add_child(_section_title("Color del nombre"))
    _card_content(color_card).add_child(_muted("Este color se utiliza en tu identidad durante las partidas y en las vistas donde tu nombre representa al jugador."))
    for spec in [["Crema", "cream", Color("#F0E3C4")], ["Dorado", "gold", Color("#D5A84E")], ["Azul", "blue", Color("#77B7FF")], ["Verde", "green", Color("#9FCB9A")], ["Rojo", "red", Color("#E47B6E")]]:
        _add_name_color_choice(_card_content(color_card), String(spec[0]), String(spec[1]), spec[2], data.get_appearance("name_color", "cream"))

    var back := Button.new()
    back.text = "← Volver al perfil"
    back.custom_minimum_size.y = 46
    back.pressed.connect(func(): page = "profile"; _refresh())
    body.add_child(back)

func _add_edit_icon_controls(card: PanelContainer, data: Object) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    _card_content(card).add_child(row)
    var avatar := TextureRect.new()
    avatar.custom_minimum_size = Vector2(64, 64)
    avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _set_avatar_texture(avatar, String(data.profile.get("avatar", "res://assets/avatars/avatar_you.svg")))
    row.add_child(avatar)
    var actions := VBoxContainer.new()
    actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(actions)

    var gallery := Button.new()
    gallery.text = "🖼  Elegir desde galería"
    gallery.custom_minimum_size.y = 44
    gallery.pressed.connect(func(): _open_profile_gallery(data))
    actions.add_child(gallery)

    var reset := Button.new()
    reset.text = "Usar avatar predeterminado"
    reset.custom_minimum_size.y = 42
    reset.pressed.connect(func():
        data.set_avatar("res://assets/avatars/avatar_you.svg")
        _refresh()
    )
    actions.add_child(reset)
    _card_content(card).add_child(_muted("Predeterminado: avatar creado para Ajedrez 2c2. Tus imágenes externas se copian al almacenamiento privado de la app."))

func _open_profile_gallery(data: Object) -> void:
    var dialog := FileDialog.new()
    dialog.name = "ProfileGallery"
    dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    dialog.access = FileDialog.ACCESS_FILESYSTEM
    dialog.filters = PackedStringArray(["*.png ; PNG", "*.jpg ; JPG", "*.jpeg ; JPEG", "*.webp ; WEBP"])
    dialog.title = "Elegir imagen de perfil"
    dialog.file_selected.connect(func(path: String):
        var source := FileAccess.open(path, FileAccess.READ)
        if source == null:
            return
        var bytes := source.get_buffer(source.get_length())
        source.close()
        if bytes.is_empty():
            return
        var ext := "png"
        var lower := path.to_lower()
        if lower.ends_with(".jpg") or lower.ends_with(".jpeg"):
            ext = "jpg"
        elif lower.ends_with(".webp"):
            ext = "webp"
        var destination := "user://profile_avatar.%s" % ext
        var out := FileAccess.open(destination, FileAccess.WRITE)
        if out == null:
            return
        out.store_buffer(bytes)
        out.close()
        if data.set_avatar(destination):
            _refresh()
        dialog.queue_free()
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    host.add_child(dialog)
    dialog.popup_centered_ratio(0.90)

func _add_name_color_choice(parent: VBoxContainer, label_text: String, value: String, swatch_color: Color, current: String) -> void:
    var row := PanelContainer.new()
    row.add_theme_stylebox_override("panel", _panel_style(PANEL))
    parent.add_child(row)
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    row.add_child(h)
    var swatch := ColorRect.new()
    swatch.color = swatch_color
    swatch.custom_minimum_size = Vector2(26, 26)
    h.add_child(swatch)
    var text := Label.new()
    text.text = label_text
    text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    text.add_theme_color_override("font_color", swatch_color)
    text.add_theme_font_size_override("font_size", 22)
    h.add_child(text)
    var radio := CheckButton.new()
    radio.button_pressed = current == value
    radio.toggled.connect(func(on: bool):
        if on:
            _data().set_appearance("name_color", value)
            _refresh()
    )
    h.add_child(radio)

func _set_avatar_texture(target: TextureRect, path: String) -> void:
    var clean := path.strip_edges()
    if clean.is_empty():
        clean = "res://assets/avatars/avatar_you.svg"
    if clean.begins_with("user://") and FileAccess.file_exists(clean):
        var image := Image.load_from_file(ProjectSettings.globalize_path(clean))
        if image != null and not image.is_empty():
            target.texture = ImageTexture.create_from_image(image)
            return
    if ResourceLoader.exists(clean):
        target.texture = load(clean)
    elif ResourceLoader.exists("res://assets/avatars/avatar_you.svg"):
        target.texture = load("res://assets/avatars/avatar_you.svg")

func _name_color(color_id: String) -> Color:
    match color_id:
        "gold": return Color("#D5A84E")
        "blue": return Color("#77B7FF")
        "green": return Color("#9FCB9A")
        "red": return Color("#E47B6E")
        _: return TEXT


func _build_profile_personalization(data: Object) -> void:
    var box := _card()
    body.add_child(box)
    _card_content(box).add_child(_section_title("Personalización"))
    _card_content(box).add_child(_muted("Separamos tu identidad visual de la experiencia del tablero para que cada menú tenga una función clara."))
    var grid := GridContainer.new()
    var viewport := _layout_viewport()
    var narrow_mobile := viewport.x < 560.0 and viewport.y > viewport.x
    grid.columns = 1 if narrow_mobile else 2
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    _card_content(box).add_child(grid)
    var appearance_button := Button.new()
    appearance_button.text = "👤 Identidad\nIcono · marco · título"
    appearance_button.custom_minimum_size = Vector2(0, 72 if narrow_mobile else 64)
    appearance_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    appearance_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    appearance_button.add_theme_font_size_override("font_size", 18)
    appearance_button.pressed.connect(func():
        page = "appearance"
        _refresh()
    )
    grid.add_child(appearance_button)
    var reactions_button := Button.new()
    reactions_button.text = "🎨 Experiencia\nTablero · piezas · reacciones"
    reactions_button.custom_minimum_size = Vector2(0, 72 if narrow_mobile else 64)
    reactions_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    reactions_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reactions_button.add_theme_font_size_override("font_size", 18)
    reactions_button.pressed.connect(func():
        page = "reactions"
        _refresh()
    )
    grid.add_child(reactions_button)


func _build_profile_competitive(data: Object) -> void:
    var box := _card()
    body.add_child(box)
    _card_content(box).add_child(_section_title("🏆 Ranking, copas y liga"))
    var grid := GridContainer.new()
    grid.columns = 2 if _layout_viewport().x < 620.0 else 4
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    _card_content(box).add_child(grid)
    var id := String(data.profile.get("id", ""))
    grid.add_child(_stat_card("2c2 Rating", str(int(data.individual.get("rating", Competitive.DEFAULT_RATING)))))
    grid.add_child(_stat_card("2c2 Ranking", "#%d" % _rank_for_id(data.individual_rank_rows(), id, "rating")))
    grid.add_child(_stat_card("2c2 Copas", str(int(data.individual.get("cups", 0)))))
    grid.add_child(_stat_card("2c2 Copas #", "#%d" % _rank_for_id(data.individual_cup_rank_rows(), id, "cups")))
    grid.add_child(_stat_card("1c1 Rating", str(int(data.individual_1c1.get("rating", Competitive.DEFAULT_RATING)))))
    grid.add_child(_stat_card("1c1 Ranking", "#%d" % _rank_for_id(data.individual_1c1_rank_rows(), id, "rating")))
    grid.add_child(_stat_card("1c1 Copas", str(int(data.individual_1c1.get("cups", 0)))))
    grid.add_child(_stat_card("1c1 Copas #", "#%d" % _rank_for_id(data.individual_1c1_cup_rank_rows(), id, "cups")))
    var league: Dictionary = data.current_league()
    var league_1c1: Dictionary = data.current_league_1c1()
    _card_content(box).add_child(_muted("2c2: Liga %s · 1c1: Liga %s · progresiones completamente independientes." % [String(league.get("name", "Bronce")), String(league_1c1.get("name", "Bronce"))]))

    var pairs_box := _card()
    body.add_child(pairs_box)
    _card_content(pairs_box).add_child(_section_title("Posición de parejas"))
    var pair_rows: Array[Dictionary] = data.pair_rank_rows()
    var pair_cup_rows: Array[Dictionary] = data.pair_cup_rank_rows()
    if pair_rows.is_empty():
        _card_content(pairs_box).add_child(_muted("Todavía no hay una pareja competitiva registrada."))
    else:
        for i in range(mini(pair_rows.size(), 3)):
            var row := HBoxContainer.new()
            row.custom_minimum_size.y = 42
            row.add_theme_constant_override("separation", 8)
            _card_content(pairs_box).add_child(row)
            var pos := Label.new()
            pos.text = "#%d" % (i + 1)
            pos.custom_minimum_size.x = 38
            pos.add_theme_color_override("font_color", GOLD if i == 0 else MUTED)
            row.add_child(pos)
            var pair_name := Label.new()
            pair_name.text = String(pair_rows[i].get("name", "Pareja"))
            pair_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            pair_name.clip_text = true
            pair_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
            pair_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            pair_name.add_theme_color_override("font_color", TEXT if bool(pair_rows[i].get("me", false)) else MUTED)
            row.add_child(pair_name)
            var metric := Label.new()
            var cup_row: Dictionary = pair_cup_rows[i] if i < pair_cup_rows.size() else {}
            metric.text = "%d rating · 🏆 %d" % [int(pair_rows[i].get("rating", 0)), int(cup_row.get("cups", 0))]
            metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            metric.custom_minimum_size.x = 120
            metric.add_theme_color_override("font_color", GOLD)
            row.add_child(metric)


func _history_mode_summary(history_items: Array, mode_value: int) -> Dictionary:
    var out := {"games": 0, "wins": 0, "losses": 0, "draws": 0}
    for item in history_items:
        if not item is Dictionary or int(item.get("mode", -999)) != mode_value:
            continue
        out["games"] += 1
        match String(item.get("outcome", "draw")):
            "win": out["wins"] += 1
            "loss": out["losses"] += 1
            _: out["draws"] += 1
    return out


func _current_streak(data: Object) -> int:
    var streak := 0
    for item in data.history:
        if not item is Dictionary:
            continue
        var outcome := String(item.get("outcome", ""))
        if outcome == "win":
            streak += 1
        elif outcome == "loss":
            break
    return streak


func _best_pair(data: Object) -> Dictionary:
    var best_id := String(data.best_pair_id) if "best_pair_id" in data else ""
    if not best_id.is_empty() and data.pair_records.has(best_id) and data.pair_records[best_id] is Dictionary:
        return data.pair_records[best_id]
    var best: Dictionary = {}
    var best_score := -1.0e30
    for key in data.pair_records.keys():
        var pair: Dictionary = data.pair_records[key]
        var score := NexusTeam.validated_best_score(pair)
        if score > best_score:
            best_score = score
            best = pair
    return best


func _build_2c2_profile(data: Object) -> void:
    var section := _card()
    body.add_child(section)
    _card_content(section).add_child(_section_title("👥 Pareja actual 2c2"))
    var current: Dictionary = data.current_partner
    var current_pair_key := String(data.current_pair_id) if "current_pair_id" in data else String(current.get("pair_key", ""))
    if current_pair_key.is_empty():
        current_pair_key = String(current.get("pair_key", ""))
    if current_pair_key.is_empty() or not data.pair_records.has(current_pair_key):
        _card_content(section).add_child(_muted("Todavía no tienes una pareja 2c2 registrada. Cuando juegues con alguien, aquí aparecerán su nombre, fuerza de pareja y sus clasificaciones."))
    else:
        current = data.current_partner
        if String(current.get("name", "")).strip_edges().is_empty():
            var stored_current: Dictionary = data.pair_records.get(current_pair_key, {})
            current = {"id": String(stored_current.get("partner_id", "")), "name": String(stored_current.get("partner_name", "")), "pair_key": current_pair_key}
        var partner_key := current_pair_key
        var pair: Dictionary = data.pair_records.get(partner_key, {})
        if pair.is_empty():
            pair = data.ensure_pair_record(partner_key, String(current.get("name", "")), String(current.get("id", "")))
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 10)
        row.custom_minimum_size.y = 54
        _card_content(section).add_child(row)
        _add_avatar(row, String(data.profile.get("avatar", "")))
        _add_avatar(row, "res://assets/avatars/avatar_mate.svg")
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var name_line := Label.new()
        name_line.text = String(pair.get("display_name", "Tú & " + String(current.get("name", ""))))
        name_line.add_theme_color_override("font_color", TEXT)
        name_line.add_theme_font_size_override("font_size", 22)
        name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_line.custom_minimum_size.x = 0.0
        name_line.clip_text = true
        name_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        info.add_child(name_line)
        var rating_line := Label.new()
        rating_line.text = "Fuerza pareja %d · 🏆 %d · ±%d" % [int(pair.get("pair_strength", pair.get("rating", Competitive.DEFAULT_RATING))), int(pair.get("cups", 0)), int(roundf(float(pair.get("pair_uncertainty", NexusTeam.INITIAL_UNCERTAINTY))))]
        rating_line.add_theme_color_override("font_color", MUTED)
        rating_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        rating_line.custom_minimum_size.x = 0.0
        rating_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        rating_line.clip_text = true
        rating_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        info.add_child(rating_line)
        var rank_line := Label.new()
        rank_line.text = "Ranking rating #%d · copas #%d" % [_rank_for_id(data.pair_rank_rows(), "PAIR:" + partner_key, "rating"), _rank_for_id(data.pair_cup_rank_rows(), "PAIR:" + partner_key, "cups")]
        rank_line.add_theme_color_override("font_color", GOLD)
        rank_line.add_theme_font_size_override("font_size", 18)
        rank_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        rank_line.custom_minimum_size.x = 0.0
        rank_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        rank_line.clip_text = true
        rank_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        info.add_child(rank_line)

    var solo := _card()
    body.add_child(solo)
    _card_content(solo).add_child(_section_title("Mis marcas competitivas"))
    var best_cards := GridContainer.new()
    best_cards.columns = 2 if _layout_viewport().y >= _layout_viewport().x else 4
    best_cards.add_theme_constant_override("h_separation", 8)
    best_cards.add_theme_constant_override("v_separation", 8)
    _card_content(solo).add_child(best_cards)
    best_cards.add_child(_stat_card("2c2 mejor", str(int(data.individual.get("best_rating", Competitive.DEFAULT_RATING)))))
    best_cards.add_child(_stat_card("2c2 copas", str(int(data.individual.get("cups", 0)))))
    best_cards.add_child(_stat_card("1c1 mejor", str(int(data.individual_1c1.get("best_rating", Competitive.DEFAULT_RATING)))))
    best_cards.add_child(_stat_card("1c1 copas", str(int(data.individual_1c1.get("cups", 0)))))

    var pairs := _card()
    body.add_child(pairs)
    _card_content(pairs).add_child(_section_title("Mejores parejas y clasificaciones"))
    var best_pair_hint := _best_pair(data)
    var best_hint_text := String(best_pair_hint.get("display_name", best_pair_hint.get("partner_name", "Pareja"))) if not best_pair_hint.is_empty() else "Pendiente"
    _card_content(pairs).add_child(_muted("★ MEJOR · " + best_hint_text))
    var keys: Array = data.pair_records.keys()
    if keys.is_empty():
        _card_content(pairs).add_child(_muted("Aquí aparecerá cada pareja con la que hayas jugado: rating actual, mejor rating alcanzado, copas y posición en los rankings."))
    else:
        keys.sort_custom(func(a, b): return int(data.pair_records[a].get("best_rating", 0)) > int(data.pair_records[b].get("best_rating", 0)))
        for key in keys:
            var pair: Dictionary = data.pair_records[key]
            var marker := ""
            if String(key) == String(data.best_pair_id):
                marker = " · ★ MEJOR"
            elif String(key) == String(data.current_pair_id):
                marker = " · ACTUAL"
            var row := HBoxContainer.new()
            row.add_theme_constant_override("separation", 8)
            row.custom_minimum_size.y = 54
            _card_content(pairs).add_child(row)
            _add_avatar(row, String(data.profile.get("avatar", "")))
            _add_avatar(row, "res://assets/avatars/avatar_mate.svg")
            var texts := VBoxContainer.new()
            texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(texts)
            var narrow_mobile := _layout_viewport().x < 480.0
            var label := Label.new()
            label.text = String(pair.get("display_name", key)) + marker
            label.add_theme_color_override("font_color", TEXT)
            label.add_theme_font_size_override("font_size", 20)
            label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            label.custom_minimum_size.x = 0.0
            label.clip_text = true
            label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
            texts.add_child(label)
            var details := Label.new()
            details.text = "Pico %d · fuerza %d · 🏆 %d · %dV / %dD / %dT" % [int(pair.get("peak_strength", pair.get("best_rating", Competitive.DEFAULT_RATING))), int(pair.get("pair_strength", pair.get("rating", Competitive.DEFAULT_RATING))), int(pair.get("cups", 0)), int(pair.get("wins", 0)), int(pair.get("losses", 0)), int(pair.get("draws", 0))]
            details.add_theme_color_override("font_color", MUTED)
            details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            details.custom_minimum_size.x = 0.0
            details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            details.clip_text = true
            details.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
            texts.add_child(details)
            var ranks := Label.new()
            ranks.text = "#%d rating · #%d copas" % [_rank_for_id(data.pair_rank_rows(), "PAIR:" + String(key), "rating"), _rank_for_id(data.pair_cup_rank_rows(), "PAIR:" + String(key), "cups")]
            ranks.custom_minimum_size.x = 0.0 if narrow_mobile else 90.0
            ranks.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow_mobile else Control.SIZE_SHRINK_END
            ranks.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if narrow_mobile else HORIZONTAL_ALIGNMENT_RIGHT
            ranks.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            ranks.add_theme_color_override("font_color", GOLD)
            ranks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if narrow_mobile else TextServer.AUTOWRAP_OFF
            ranks.clip_text = true
            ranks.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
            if narrow_mobile:
                texts.add_child(ranks)
            else:
                row.add_child(ranks)

    # El historial se abre desde el icono de reloj de la cabecera.


func _rank_for_id(rows: Array[Dictionary], target_id: String, metric: String) -> int:
    for i in range(rows.size()):
        if String(rows[i].get("id", "")) == target_id:
            return i + 1
    return 0

# ---------------- Funciones secundarias ----------------


func _build_more() -> void:
    var intro := _card()
    body.add_child(intro)
    _card_content(intro).add_child(_section_title("Más funciones"))
    _card_content(intro).add_child(_muted("Aquí viven funciones secundarias que no necesitan ocupar un lugar permanente en la navegación principal. Perfil, Apariencia, Reacciones y Ajustes permanecen fuera de esta barra."))

    var grid := GridContainer.new()
    grid.columns = 2 if _layout_viewport().x < 560.0 else 3
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    _card_content(intro).add_child(grid)

    var help := Button.new()
    help.text = "❔\nAyuda"
    help.custom_minimum_size.y = 72
    help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    help.pressed.connect(func(): page = "help"; _refresh())
    grid.add_child(help)

    var achievements := Button.new()
    achievements.text = "🏅\nLogros · pronto"
    achievements.disabled = true
    achievements.custom_minimum_size.y = 72
    achievements.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_child(achievements)

    var events := Button.new()
    events.text = "📣\nEventos · pronto"
    events.disabled = true
    events.custom_minimum_size.y = 72
    events.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_child(events)

    var future := _card()
    body.add_child(future)
    _card_content(future).add_child(_section_title("Espacio para funciones futuras"))
    _card_content(future).add_child(_muted("Este apartado queda deliberadamente ligero para poder añadir nuevas funciones sin volver a sobrecargar la pantalla principal."))

    var exit_card := _card()
    body.add_child(exit_card)
    _card_content(exit_card).add_child(_section_title("Sesión"))
    var exit_button := Button.new()
    exit_button.text = "Salir de la aplicación"
    exit_button.custom_minimum_size.y = 46
    exit_button.pressed.connect(func(): get_tree().quit())
    _card_content(exit_card).add_child(exit_button)


func _build_help() -> void:
    var intro := _card()
    body.add_child(intro)
    var back := Button.new()
    back.text = "← Volver a Más"
    back.custom_minimum_size.y = 42
    back.pressed.connect(func(): page = "more"; _refresh())
    _card_content(intro).add_child(back)
    _card_content(intro).add_child(_section_title("Cómo jugar"))
    _card_content(intro).add_child(_muted("2c2: cuatro jugadores, dos equipos y turnos compartidos. 1c1: ajedrez clásico online. VS IA: partida local contra uno de los bots calibrados. 1c1 Local: dos personas en el mismo dispositivo."))
    _card_content(intro).add_child(_muted("Durante la partida puedes consultar sugerencias, usar reacciones y revisar el estado del equipo desde el HUD."))

    var rules := _card()
    body.add_child(rules)
    _card_content(rules).add_child(_section_title("Controles básicos"))
    _card_content(rules).add_child(_muted("Toca una pieza para seleccionarla y toca una casilla válida para moverla. Las reacciones se equipan desde Reacciones. El historial conserva las jugadas para poder reproducirlas después."))

# ---------------- Ranking / competitive ----------------


func _build_ranking() -> void:
    var data := _data()
    var intro := _card()
    body.add_child(intro)
    _card_content(intro).add_child(_section_title("Clasificación"))
    _card_content(intro).add_child(_muted("Aquí compites por posición. 1c1 y 2c2 tienen clasificaciones completamente independientes."))

    var mode_row := HBoxContainer.new()
    mode_row.name = "RankingModes"
    mode_row.add_theme_constant_override("separation", 8)
    _card_content(intro).add_child(mode_row)

    var solo_btn := Button.new()
    solo_btn.name = "Ranking1c1"
    solo_btn.text = "1c1"
    solo_btn.custom_minimum_size = Vector2(0, 44)
    solo_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    solo_btn.pressed.connect(func(): host.ranking_mode = "1c1"; _refresh())
    mode_row.add_child(solo_btn)

    var team_btn := Button.new()
    team_btn.name = "Ranking2c2"
    team_btn.text = "2c2"
    team_btn.custom_minimum_size = Vector2(0, 44)
    team_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    team_btn.pressed.connect(func(): host.ranking_mode = "2c2"; _refresh())
    mode_row.add_child(team_btn)

    var selected := String(host.ranking_mode)
    var selected_fill := Color("#D5A84E")
    if selected == "1c1":
        solo_btn.disabled = true
        solo_btn.add_theme_stylebox_override("disabled", _button_style(selected_fill, 12, 1, selected_fill))
        solo_btn.add_theme_color_override("font_color", BG)
        _card_content(intro).add_child(_muted("Competencia individual · NEXUS 1c1"))
        _add_rank_table("1c1 · NEXUS", data.individual_1c1_rank_rows(), "rating")
        _add_rank_table("1c1 · Copas", data.individual_1c1_cup_rank_rows(), "cups")
    else:
        team_btn.disabled = true
        team_btn.add_theme_stylebox_override("disabled", _button_style(selected_fill, 12, 1, selected_fill))
        team_btn.add_theme_color_override("font_color", BG)
        _card_content(intro).add_child(_muted("Competencia por equipos · NEXUS 2c2"))
        _add_rank_table("2c2 · NEXUS de jugadores", data.individual_rank_rows(), "rating")
        _add_rank_table("2c2 · NEXUS de parejas", data.pair_rank_rows(), "rating")
        _add_rank_table("2c2 · Copas de jugadores", data.individual_cup_rank_rows(), "cups")
        _add_rank_table("2c2 · Copas de parejas", data.pair_cup_rank_rows(), "cups")

    var future := _card()
    body.add_child(future)
    _card_content(future).add_child(_section_title("Clasificación semanal"))
    _card_content(future).add_child(_muted("La clasificación competitiva se integrará al servicio online para agrupar jugadores, cerrar la semana y resolver ascensos o permanencias sin mezclarla con la Temporada."))

func _add_rank_table(table_title: String, rows: Array[Dictionary], metric: String) -> void:
    var box := _card()
    body.add_child(box)
    var t := Label.new()
    t.text = table_title
    t.add_theme_color_override("font_color", TEXT)
    t.add_theme_font_size_override("font_size", 23)
    _card_content(box).add_child(t)

    var header := HBoxContainer.new()
    header.custom_minimum_size.y = 24
    header.add_theme_constant_override("separation", 8)
    _card_content(box).add_child(header)
    var header_pos := Label.new()
    header_pos.text = "#"
    header_pos.custom_minimum_size.x = 34
    header_pos.add_theme_color_override("font_color", MUTED)
    header.add_child(header_pos)
    var header_identity := Label.new()
    header_identity.text = "Jugador / pareja"
    header_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header_identity.add_theme_color_override("font_color", MUTED)
    header.add_child(header_identity)
    var header_metric := Label.new()
    header_metric.text = "🏆 Copas" if metric == "cups" else "Rating"
    header_metric.custom_minimum_size.x = 82
    header_metric.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    header_metric.add_theme_color_override("font_color", MUTED)
    header.add_child(header_metric)

    for i in range(mini(rows.size(), 5)):
        var row := HBoxContainer.new()
        row.custom_minimum_size.y = 48
        row.add_theme_constant_override("separation", 8)

        var position_label := Label.new()
        position_label.text = "%d" % (i + 1)
        position_label.custom_minimum_size.x = 34
        position_label.add_theme_color_override("font_color", GOLD if i == 0 else MUTED)
        position_label.add_theme_font_size_override("font_size", 22)
        position_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        row.add_child(position_label)

        var identity := HBoxContainer.new()
        identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        identity.add_theme_constant_override("separation", 8)
        row.add_child(identity)

        if rows[i].has("avatar1"):
            _add_avatar(identity, String(rows[i].get("avatar1", "")))
            _add_avatar(identity, String(rows[i].get("avatar2", "")))
        else:
            _add_avatar(identity, String(rows[i].get("avatar", "")))

        var name_label := Label.new()
        var display_name := String(rows[i]["name"])
        if bool(rows[i].get("is_best", false)):
            display_name += " · ★ MEJOR"
        elif bool(rows[i].get("is_current", false)):
            display_name += " · ACTUAL"
        name_label.text = display_name
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_label.clip_text = true
        name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_label.add_theme_color_override("font_color", TEXT if bool(rows[i]["me"]) else MUTED)
        identity.add_child(name_label)

        var metric_label := Label.new()
        metric_label.text = "%d" % int(rows[i][metric])
        metric_label.custom_minimum_size.x = 82
        metric_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        metric_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        metric_label.add_theme_color_override("font_color", GOLD if metric == "cups" else TEXT)
        metric_label.add_theme_font_size_override("font_size", 22)
        row.add_child(metric_label)
        _card_content(box).add_child(row)


func _add_avatar(parent: Container, path: String) -> void:
    var avatar := TextureRect.new()
    var resolved_path := _resolved_avatar_path(path)
    if not OS.has_feature("headless") and not resolved_path.is_empty() and FileAccess.file_exists(resolved_path):
        if _avatar_texture_cache.has(resolved_path):
            avatar.texture = _avatar_texture_cache[resolved_path]
        else:
            var image := Image.load_from_file(ProjectSettings.globalize_path(resolved_path))
            if image != null and not image.is_empty():
                var cached := ImageTexture.create_from_image(image)
                _avatar_texture_cache[resolved_path] = cached
                avatar.texture = cached
    avatar.custom_minimum_size = Vector2(34, 34)
    avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    parent.add_child(avatar)


func _resolved_avatar_path(path: String) -> String:
    if path.ends_with(".svg"):
        var png_path := path.get_basename() + ".png"
        if FileAccess.file_exists(png_path):
            return png_path
    return path

# ---------------- Historial / análisis ----------------


func _build_history() -> void:
    var data := _data()
    var intro := _card()
    body.add_child(intro)
    _card_content(intro).add_child(_section_title("Historial de partidas"))
    _card_content(intro).add_child(_muted("Tus partidas finalizadas se guardan localmente. Desde aquí puedes abrir una partida y estudiarla cuando quieras."))
    if data.history.is_empty():
        _card_content(intro).add_child(_muted("Todavía no hay partidas terminadas."))
        return
    var entries: Array = data.history.duplicate()
    entries.reverse()
    for item in entries:
        _add_history_row(item)


func _add_history_row(item: Dictionary) -> void:
    var box := _card()
    body.add_child(box)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    _card_content(box).add_child(row)
    var mode_value := int(item.get("mode", AppConfig.MODE_2C2))
    var icon := Label.new()
    icon.text = "👥" if mode_value == AppConfig.MODE_2C2 else ("🤖" if mode_value == AppConfig.MODE_VS_BOT else "♟")
    icon.custom_minimum_size.x = 28
    icon.add_theme_font_size_override("font_size", 29)
    row.add_child(icon)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    var title_line := Label.new()
    title_line.text = "%s · %s" % [_history_mode_name(mode_value), _history_outcome(item)]
    title_line.add_theme_color_override("font_color", TEXT)
    title_line.add_theme_font_size_override("font_size", 23)
    info.add_child(title_line)
    var detail_line := Label.new()
    detail_line.text = _format_history_date(int(item.get("timestamp", 0)))
    detail_line.add_theme_color_override("font_color", MUTED)
    detail_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_child(detail_line)
    var meta := Label.new()
    var partner := String(item.get("partner", ""))
    var opponents = item.get("opponents", [])
    if mode_value == AppConfig.MODE_VS_BOT:
        meta.text = "%s · %d Elo" % [String(item.get("bot_id", "Bot")).capitalize(), int(item.get("bot_elo", 0))]
    elif mode_value == AppConfig.MODE_2C2 and not partner.is_empty():
        meta.text = "Pareja: %s" % partner
    elif opponents is Array and not opponents.is_empty():
        meta.text = "Rival: %s" % String(opponents[0])
    else:
        meta.text = "Partida local"
    meta.add_theme_color_override("font_color", GOLD)
    meta.add_theme_font_size_override("font_size", 18)
    info.add_child(meta)
    var analyze := Button.new()
    var already_analyzed := bool(item.get("analysis_viewed", false))
    analyze.text = "Ver" if already_analyzed else "Analizar partida"
    analyze.tooltip_text = "Ver el análisis de esta partida" if already_analyzed else "Abrir el replay para analizar esta partida"
    analyze.custom_minimum_size = Vector2(136 if not already_analyzed else 88, 46)
    analyze.pressed.connect(func(record_id: String = String(item.get("match_id", ""))):
        _open_history_primary(record_id)
    )
    row.add_child(analyze)



func _build_analysis() -> void:
    var data := _data()
    if selected_history_index < 0 or selected_history_index >= data.history.size():
        page = "history"
        _build_history()
        return

    var item: Dictionary = data.history[selected_history_index]
    var moves: Array = item.get("moves", []).duplicate(true) if item.get("moves", []) is Array else []
    var replay_data: Variant = item.get("replay_data", {})

    var viewer := MatchReplayView.new()
    viewer.name = "GameReviewStudy"
    viewer.configure_view("")
    viewer.set_review_mode("analysis")
    viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(viewer)
    viewer.set_replay_data(replay_data if replay_data is Dictionary else {}, moves)

    # Si ya existe un análisis guardado, la revisión aparece instantáneamente.
    var stored_analysis: Variant = item.get("engine_analysis", {})
    if stored_analysis is Dictionary and stored_analysis.get("moves", []) is Array and not stored_analysis.get("moves", []).is_empty():
        viewer.set_engine_analysis(stored_analysis)
        return

    var engine_status := Label.new()
    engine_status.name = "EngineStatus"
    engine_status.text = "Analizando la partida…"
    engine_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    engine_status.add_theme_color_override("font_color", MUTED)
    engine_status.add_theme_font_size_override("font_size", 20)
    engine_status.custom_minimum_size.y = 24
    body.add_child(engine_status)

    call_deferred("_start_engine_review", item, moves, replay_data if replay_data is Dictionary else {}, engine_status, viewer)


func _build_replay() -> void:
    var data := _data()
    if selected_history_index < 0 or selected_history_index >= data.history.size():
        page = "history"
        _build_history()
        return
    var item: Dictionary = data.history[selected_history_index]

    # No repetimos la tarjeta de resultado encima del replay: el propio marco de
    # la partida muestra jugadores, relojes y resultado para mantener el tablero
    # cerca de la parte superior, igual que en la partida en vivo.

    # El Replay es una superficie de estudio propia: no lo metemos dentro de
    # otra tarjeta/panel para que el tablero pueda comportarse como el de una
    # partida normal y usar todo el ancho disponible.
    var replay := MatchReplayView.new()
    replay.name = "GameReplayStudy"
    replay.configure_view("")
    replay.set_review_mode("replay")
    replay.analysis_requested.connect(func(record_id: String = String(item.get("match_id", ""))):
        _open_history_analysis(record_id)
    )
    replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.add_child(replay)
    var replay_data: Variant = item.get("replay_data", {})
    var moves: Variant = item.get("moves", [])
    replay.set_replay_data(replay_data if replay_data is Dictionary else {}, moves if moves is Array else [])
    replay.set_match_metadata(item)



func _history_mode_name(mode_value: int) -> String:
    match mode_value:
        AppConfig.MODE_2C2: return "2c2"
        AppConfig.MODE_1C1: return "1c1 online"
        AppConfig.MODE_VS_BOT: return "VS IA"
        AppConfig.MODE_1C1_LOCAL: return "1c1 local"
    return "Ajedrez"


func _history_outcome(item: Dictionary) -> String:
    match String(item.get("outcome", "draw")):
        "win": return "Victoria"
        "loss": return "Derrota"
        _: return "Tablas"


func _format_history_date(timestamp: int) -> String:
    if timestamp <= 0: return "Fecha no disponible"
    return Time.get_datetime_string_from_unix_time(timestamp, true).replace("T", " ")


func _history_participants_text(item: Dictionary) -> String:
    var mode_value := int(item.get("mode", AppConfig.MODE_2C2))
    if mode_value == AppConfig.MODE_VS_BOT:
        return "Rival: Bot %s · Elo %d" % [String(item.get("bot_id", "")).capitalize(), int(item.get("bot_elo", 0))]
    if mode_value == AppConfig.MODE_2C2:
        var opponents = item.get("opponents", [])
        return "Pareja: %s · Rivales: %s" % [(String(item.get("partner", "")) if not String(item.get("partner", "")).is_empty() else "sin pareja"), ", ".join(opponents) if opponents is Array else ""]
    var opponents = item.get("opponents", [])
    return "Rival: %s" % (String(opponents[0]) if opponents is Array and not opponents.is_empty() else "Rival")

# ---------------- Copas / temporadas ----------------


func _build_cups() -> void:
    var data := _data()
    var stats: Dictionary = data.individual

    var box := _card()
    body.add_child(box)
    _card_content(box).add_child(_section_title("Copas"))

    var value := Label.new()
    value.text = "%d" % int(stats.get("cups", 0))
    value.add_theme_color_override("font_color", GOLD)
    value.add_theme_font_size_override("font_size", 44)
    value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _card_content(box).add_child(value)

    var league: Dictionary = data.current_league()
    var league_label := Label.new()
    league_label.text = "Liga %s" % String(league.get("name", "Bronce"))
    league_label.add_theme_color_override("font_color", TEXT)
    league_label.add_theme_font_size_override("font_size", 25)
    league_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _card_content(box).add_child(league_label)
    _card_content(box).add_child(_muted("Sistema visual preparado.\nLa fórmula definitiva de copas y sus temporadas se cerrará más adelante."))

    var formula := _card()
    body.add_child(formula)
    _card_content(formula).add_child(_section_title("Cómo se mostrará la progresión"))
    _card_content(formula).add_child(_muted("Victoria · empate · derrota
Indicador de cambio después de la partida
Progreso hacia la siguiente liga"))

    var future := _card()
    body.add_child(future)
    _card_content(future).add_child(_section_title("Temporadas"))
    _card_content(future).add_child(_muted("Solo diseño por ahora.\nAquí habrá selector de temporada, calendario, clasificación, recompensas e historial cuando definamos sus reglas."))
    var preview := GridContainer.new()
    preview.columns = 2 if _layout_viewport().x < 480.0 else 3
    preview.add_theme_constant_override("h_separation", 8)
    preview.add_theme_constant_override("v_separation", 8)
    _card_content(future).add_child(preview)
    for text_value in ["Temporada", "Clasificación", "Recompensas"]:
        var b := Button.new()
        b.text = text_value
        b.disabled = true
        b.custom_minimum_size.y = 40
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        preview.add_child(b)

    var pairs := _card()
    body.add_child(pairs)
    _card_content(pairs).add_child(_section_title("Mis parejas"))
    var pair_keys: Array = data.pair_records.keys()
    if pair_keys.is_empty():
        _card_content(pairs).add_child(_muted("Aquí se mostrará el historial visual de tus parejas. Tus partidas 2c2 aparecerán aquí."))
    else:
        for key in pair_keys:
            var pair: Dictionary = data.pair_records[key]
            var line := Label.new()
            var pair_name := String(pair.get("display_name", key))
            line.text = "%s · %d rating · %d copas · %dV / %dD / %dT" % [pair_name, int(pair.get("rating", Competitive.DEFAULT_RATING)), int(pair.get("cups", 0)), int(pair.get("wins", 0)), int(pair.get("losses", 0)), int(pair.get("draws", 0))]
            line.add_theme_color_override("font_color", MUTED)
            line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            _card_content(pairs).add_child(line)

# ---------------- Experiencia de juego: tablero, piezas y reacciones ----------------


func _build_reactions() -> void:
    var data: Object = _data()

    var intro := _card()
    body.add_child(intro)
    _card_content(intro).add_child(_section_title("🎨 Experiencia de juego"))
    _card_content(intro).add_child(_muted("Aquí se personaliza lo que ves durante una partida: tablero, piezas y reacciones. La identidad del jugador se mantiene separada en Apariencia."))

    # El tablero y las piezas son equipables de forma independiente.
    # La vista previa usa estados temporales y nunca modifica PlayerData hasta
    # pulsar "Equipar". Esto permite probar cualquier combinación: por ejemplo,
    # piezas Grafito + dorado sobre tablero Clásico.
    if _preview_board_theme.is_empty():
        _preview_board_theme = data.get_appearance("board_theme", "classic")
    if _preview_piece_set.is_empty():
        _preview_piece_set = data.get_appearance("piece_set", "classic")

    var preview := _board_preview(data)
    body.add_child(preview)

    var preview_note := _muted("La vista previa no cambia tu equipamiento. Puedes combinar tablero y piezas libremente y equiparlos por separado.")
    _card_content(preview).add_child(preview_note)

    var board_card := _card()
    body.add_child(board_card)
    _card_content(board_card).add_child(_section_title("Tablero"))
    _add_visual_choice(_card_content(board_card), "Clásico", "Tablero original: madera clara y marrón", "board_theme", "classic", true, data.get_appearance("board_theme", "classic"))
    _add_visual_choice(_card_content(board_card), "Grafito + dorado", "Gris grafito + gris metal con marco dorado", "board_theme", "graphite_gold", true, data.get_appearance("board_theme", "classic"))

    var piece_card := _card()
    body.add_child(piece_card)
    _card_content(piece_card).add_child(_section_title("Piezas"))
    _add_visual_choice(_card_content(piece_card), "Clásicas", "Conjunto original del juego", "piece_set", "classic", true, data.get_appearance("piece_set", "classic"))
    _add_visual_choice(_card_content(piece_card), "Grafito + dorado", "Blancas rellenas de blanco con detalles dorados · negras rellenas de negro con contorno azul acero", "piece_set", "graphite_gold", true, data.get_appearance("piece_set", "classic"))

    var reactions_card := _card()
    body.add_child(reactions_card)
    _card_content(reactions_card).add_child(_section_title("Reacciones"))
    _card_content(reactions_card).add_child(_muted("Equipa hasta %d reacciones. El orden es el mismo que verás durante la partida." % PlayerDataScript.MAX_EQUIPPED_EMOTES))
    _build_reaction_loadout(reactions_card, data)
    _build_reaction_catalog(reactions_card, data)


func _build_reaction_loadout(card: PanelContainer, data: Object) -> void:
    _card_content(card).add_child(_section_title("Equipadas"))
    var equipped: Array = data.get_equipped_emotes()
    if equipped.is_empty():
        _card_content(card).add_child(_muted("No tienes ninguna reacción equipada."))
        return
    for i in range(equipped.size()):
        var item: Dictionary = EmoteDataScript.get_emote(String(equipped[i]))
        if item.is_empty():
            continue
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        _card_content(card).add_child(row)
        var icon := TextureRect.new()
        icon.texture = load(String(item.get("path", "")))
        icon.custom_minimum_size = Vector2(42, 42)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        row.add_child(icon)
        var reaction_name := Label.new()
        reaction_name.text = "%d. %s" % [i + 1, String(item.get("label", "Reacción"))]
        reaction_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        reaction_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        reaction_name.add_theme_color_override("font_color", TEXT)
        row.add_child(reaction_name)
        for spec in [["↑", -1], ["↓", 1], ["Quitar", 0]]:
            var button := Button.new()
            button.text = String(spec[0])
            button.custom_minimum_size = Vector2(44 if spec[0] != "Quitar" else 68, 38)
            var id := String(item["id"])
            button.pressed.connect(func(direction: int = int(spec[1]), emote_id: String = id):
                if direction == 0:
                    data.toggle_emote_equipped(emote_id)
                else:
                    data.move_equipped_emote(emote_id, direction)
                _refresh()
            )
            row.add_child(button)


func _build_reaction_catalog(card: PanelContainer, data: Object) -> void:
    _card_content(card).add_child(_section_title("Catálogo de reacciones"))
    var grid := GridContainer.new()
    grid.columns = 2 if _layout_viewport().x < 520.0 else 3
    grid.add_theme_constant_override("h_separation", 8)
    grid.add_theme_constant_override("v_separation", 8)
    _card_content(card).add_child(grid)
    var equipped: Array = data.get_equipped_emotes()
    for item in EmoteDataScript.all():
        var id := String(item["id"])
        var cell := VBoxContainer.new()
        cell.add_theme_constant_override("separation", 4)
        var icon := TextureRect.new()
        icon.texture = load(String(item["path"]))
        icon.custom_minimum_size = Vector2(56, 56)
        icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        cell.add_child(icon)
        var button := Button.new()
        button.text = "Quitar" if equipped.has(id) else ("Equipar" if equipped.size() < PlayerDataScript.MAX_EQUIPPED_EMOTES else "Lleno")
        button.disabled = not equipped.has(id) and equipped.size() >= PlayerDataScript.MAX_EQUIPPED_EMOTES
        button.custom_minimum_size.y = 38
        button.pressed.connect(func(emote_id: String = id):
            data.toggle_emote_equipped(emote_id)
            _refresh()
        )
        cell.add_child(button)
        grid.add_child(cell)

# ---------------- Ajustes ----------------


func _build_settings() -> void:
    var data: Object = _data()
    var intro := _card()
    body.add_child(intro)
    _card_content(intro).add_child(_section_title("Ajustes"))
    _card_content(intro).add_child(_muted("La apariencia del tablero y de las piezas tendrá su propio espacio para que puedas cambiarla sin mezclarla con las opciones de partida."))
    _add_toggle("Vibración", "Respuesta háptica al interactuar con el juego.", "vibration", data.get_setting("vibration", true))
    _add_toggle("Mostrar coordenadas", "Muestra filas y columnas en el tablero.", "show_coordinates", data.get_setting("show_coordinates", true))
    _add_toggle("Confirmar rendición", "Evita rendirse con un toque accidental.", "confirm_surrender", data.get_setting("confirm_surrender", true))
    _add_toggle("Reducir movimiento", "Reserva el ajuste para transiciones que posteriormente tengan animación.", "reduced_motion", data.get_setting("reduced_motion", false))
    _add_toggle("Sonido", "Activa los efectos cortos de movimientos, capturas y resultados.", "sound", data.get_setting("sound", true))
    var note := _muted("Los ajustes se guardan localmente en este dispositivo. Los efectos usan un sistema central y pueden ampliarse después sin modificar las escenas de partida.")
    body.add_child(note)

# ---------------- Apariencia: identidad visual del jugador ----------------


func _build_appearance() -> void:
    var data: Object = _data()

    var intro := _card()
    body.add_child(intro)
    _card_content(intro).add_child(_section_title("👤 Identidad visual"))
    _card_content(intro).add_child(_muted("Apariencia define cómo te presentas como jugador: icono, marco y título. El tablero, las piezas y las reacciones están en su propio apartado."))

    _add_profile_preview(intro, data)

    var icon_card := _card()
    body.add_child(icon_card)
    _card_content(icon_card).add_child(_section_title("Icono de perfil"))
    _add_icon_choice(icon_card, data)

    var frame_card := _card()
    body.add_child(frame_card)
    _card_content(frame_card).add_child(_section_title("Marco del perfil"))
    _add_profile_frame_choice(_card_content(frame_card), "Clásico", "Marco base", "classic", data.get_appearance("profile_frame", "classic"))
    _add_profile_frame_choice(_card_content(frame_card), "Dorado", "Marco destacado preparado para personalización", "gold", data.get_appearance("profile_frame", "classic"))

    var title_card := _card()
    body.add_child(title_card)
    _card_content(title_card).add_child(_section_title("Título de jugador"))
    _add_title_choice(_card_content(title_card), "Jugador", "Título base disponible", "jugador", true, data.get_appearance("player_title", "jugador"))
    _add_title_choice(_card_content(title_card), "Estratega", "Título alternativo disponible", "estratega", true, data.get_appearance("player_title", "jugador"))
    _add_title_choice(_card_content(title_card), "Veterano", "Título alternativo disponible", "veterano", true, data.get_appearance("player_title", "jugador"))

    body.add_child(_muted("El título seleccionado aparecerá debajo de tu nombre durante las partidas."))


func _add_profile_preview(card: PanelContainer, data: Object) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 12)
    _card_content(card).add_child(row)

    # The frame is an outer ring, never a panel over the avatar image.
    var avatar_box := Control.new()
    avatar_box.custom_minimum_size = Vector2(92, 92)
    row.add_child(avatar_box)

    var frame_ring := Panel.new()
    frame_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
    frame_ring.add_theme_stylebox_override("panel", _profile_frame_style(data.get_appearance("profile_frame", "classic"), 3, true))
    avatar_box.add_child(frame_ring)

    var avatar := TextureRect.new()
    avatar.position = Vector2(5, 5)
    avatar.size = Vector2(82, 82)
    avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var avatar_path := String(data.profile.get("avatar", "res://assets/avatars/avatar_you.svg"))
    _set_avatar_texture(avatar, avatar_path)
    avatar_box.add_child(avatar)

    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_theme_constant_override("separation", 2)
    row.add_child(info)
    var name_label := Label.new()
    name_label.text = String(data.profile.get("name", "Tú"))
    name_label.add_theme_color_override("font_color", _name_color(data.get_appearance("name_color", "cream")))
    name_label.add_theme_font_size_override("font_size", 29)
    info.add_child(name_label)
    var title_label := Label.new()
    title_label.text = _player_title_label(data.get_appearance("player_title", "jugador"))
    title_label.add_theme_color_override("font_color", GOLD)
    title_label.add_theme_font_size_override("font_size", 18)
    info.add_child(title_label)
    info.add_child(_muted("Así aparecerás en tu perfil y debajo de tu nombre durante una partida."))


func _add_icon_choice(card: PanelContainer, data: Object) -> void:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    _card_content(card).add_child(row)
    var avatar := TextureRect.new()
    avatar.custom_minimum_size = Vector2(64, 64)
    avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    var path := String(data.profile.get("avatar", "res://assets/avatars/avatar_you.svg"))
    _set_avatar_texture(avatar, path)
    row.add_child(avatar)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    info.add_child(_muted("Icono actual"))
    var future := Button.new()
    future.text = "Cambiar icono · galería"
    future.disabled = false
    future.pressed.connect(func(): _open_profile_gallery(data))
    future.custom_minimum_size.y = 42
    future.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_child(future)


func _add_profile_frame_choice(parent: VBoxContainer, title_text: String, desc_text: String, value: String, current: String) -> void:
    var row := PanelContainer.new()
    row.add_theme_stylebox_override("panel", _panel_style(PANEL))
    parent.add_child(row)
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    row.add_child(h)
    var preview := PanelContainer.new()
    preview.custom_minimum_size = Vector2(48, 48)
    preview.add_theme_stylebox_override("panel", _profile_frame_style(value, 3))
    h.add_child(preview)
    var texts := VBoxContainer.new()
    texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    h.add_child(texts)
    var label := Label.new()
    label.text = title_text
    label.add_theme_color_override("font_color", TEXT)
    label.add_theme_font_size_override("font_size", 20)
    texts.add_child(label)
    var desc := Label.new()
    desc.text = desc_text
    desc.add_theme_color_override("font_color", MUTED)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texts.add_child(desc)
    var radio := CheckButton.new()
    radio.button_pressed = current == value
    radio.toggled.connect(func(on: bool):
        if on:
            _data().set_appearance("profile_frame", value)
            _refresh()
    )
    h.add_child(radio)


func _add_title_choice(parent: VBoxContainer, title_text: String, desc_text: String, value: String, enabled: bool, current: String) -> void:
    var row := PanelContainer.new()
    row.add_theme_stylebox_override("panel", _panel_style(PANEL))
    parent.add_child(row)
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 10)
    row.add_child(h)
    var texts := VBoxContainer.new()
    texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    h.add_child(texts)
    var label := Label.new()
    label.text = title_text
    label.add_theme_color_override("font_color", TEXT if enabled else MUTED)
    label.add_theme_font_size_override("font_size", 20)
    texts.add_child(label)
    var desc := Label.new()
    desc.text = desc_text
    desc.add_theme_color_override("font_color", MUTED)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texts.add_child(desc)
    var radio := CheckButton.new()
    radio.button_pressed = enabled and current == value
    radio.disabled = not enabled
    if enabled:
        radio.toggled.connect(func(on: bool):
            if on:
                _data().set_appearance("player_title", value)
                _refresh()
        )
    h.add_child(radio)


func _player_title_label(title_id: String) -> String:
    match title_id:
        "jugador": return "Jugador"
        "estratega": return "Estratega"
        "veterano": return "Veterano"
    return "Jugador"


func _profile_frame_style(frame_id: String, border_width: int = 2, circular: bool = false) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0)
    style.border_color = Color("#4A4034")
    style.set_border_width_all(border_width)
    style.set_corner_radius_all(42 if circular else 10)
    if frame_id == "gold":
        style.border_color = GOLD
        style.set_border_width_all(maxi(3, border_width))
    return style


func _add_visual_choice(parent: VBoxContainer, title_text: String, desc_text: String, key: String, value: String, enabled: bool, current: String) -> void:
    var row := PanelContainer.new()
    row.add_theme_stylebox_override("panel", _panel_style(PANEL))
    parent.add_child(row)

    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 7)
    row.add_child(outer)

    var top := VBoxContainer.new()
    top.add_theme_constant_override("separation", 6)
    outer.add_child(top)

    var texts := VBoxContainer.new()
    texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(texts)

    var label := Label.new()
    label.text = title_text + (" · EQUIPADO" if enabled and current == value else "")
    label.add_theme_color_override("font_color", TEXT if enabled else MUTED)
    label.add_theme_font_size_override("font_size", 20)
    texts.add_child(label)

    var desc := Label.new()
    desc.text = desc_text
    desc.add_theme_color_override("font_color", MUTED)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texts.add_child(desc)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 8)
    actions.size_flags_horizontal = Control.SIZE_SHRINK_END
    outer.add_child(actions)

    var preview_button := Button.new()
    preview_button.text = "Previsualizar"
    preview_button.custom_minimum_size = Vector2(112, 40)
    preview_button.disabled = not enabled
    actions.add_child(preview_button)
    preview_button.pressed.connect(func():
        if key == "board_theme":
            _preview_board_theme = value
        else:
            _preview_piece_set = value
        _refresh()
    )

    var equip_button := Button.new()
    equip_button.text = "Equipar" if enabled and current != value else "Equipado"
    equip_button.custom_minimum_size = Vector2(88, 40)
    equip_button.disabled = not enabled or current == value
    actions.add_child(equip_button)
    equip_button.pressed.connect(func():
        if key == "board_theme":
            _data().set_appearance("board_theme", value)
            _preview_board_theme = value
        else:
            _data().set_appearance("piece_set", value)
            _preview_piece_set = value
        _refresh()
    )


func _board_preview(data: Object) -> PanelContainer:
    var box := _card()
    _card_content(box).add_child(_section_title("Vista previa de partida"))
    var preview := MatchPreviewBoard.new()
    preview.custom_minimum_size = Vector2(260, 260)
    preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    var preview_board: String = _preview_board_theme if not _preview_board_theme.is_empty() else String(data.get_appearance("board_theme", "classic"))
    var preview_pieces: String = _preview_piece_set if not _preview_piece_set.is_empty() else String(data.get_appearance("piece_set", "classic"))
    preview.set_theme_value(preview_board, preview_pieces)
    _card_content(box).add_child(preview)
    var board_name := "Grafito + dorado" if preview_board == "graphite_gold" else "Clásico"
    var piece_name := "Grafito + dorado" if preview_pieces == "graphite_gold" else "Clásicas"
    var equipped_board: String = String(data.get_appearance("board_theme", "classic"))
    var equipped_pieces: String = String(data.get_appearance("piece_set", "classic"))
    var dirty: bool = preview_board != equipped_board or preview_pieces != equipped_pieces
    var label := _muted("Vista previa: Tablero %s · Piezas %s" % [board_name, piece_name])
    _card_content(box).add_child(label)
    if dirty:
        var pending := _muted("Previsualización temporal · no está equipada todavía")
        _card_content(box).add_child(pending)
    else:
        _card_content(box).add_child(_muted("Así está equipado actualmente."))
    return box

class MatchPreviewBoard extends Control:
    static var _texture_cache: Dictionary = {}
    var board_theme := "classic"
    var piece_set := "classic"
    const PIECES := {
        "classic": {
            "black_rook":"res://assets/pieces/black_rook.png", "black_knight":"res://assets/pieces/black_knight.png", "black_bishop":"res://assets/pieces/black_bishop.png", "black_queen":"res://assets/pieces/black_queen.png", "black_king":"res://assets/pieces/black_king.png", "black_pawn":"res://assets/pieces/black_pawn.png",
            "white_rook":"res://assets/pieces/white_rook.png", "white_knight":"res://assets/pieces/white_knight.png", "white_bishop":"res://assets/pieces/white_bishop.png", "white_queen":"res://assets/pieces/white_queen.png", "white_king":"res://assets/pieces/white_king.png", "white_pawn":"res://assets/pieces/white_pawn.png"
        },
        "graphite_gold": {
            "black_rook":"res://assets/pieces/skin_graphite_gold/black_rook.png", "black_knight":"res://assets/pieces/skin_graphite_gold/black_knight.png", "black_bishop":"res://assets/pieces/skin_graphite_gold/black_bishop.png", "black_queen":"res://assets/pieces/skin_graphite_gold/black_queen.png", "black_king":"res://assets/pieces/skin_graphite_gold/black_king.png", "black_pawn":"res://assets/pieces/skin_graphite_gold/black_pawn.png",
            "white_rook":"res://assets/pieces/skin_graphite_gold/white_rook.png", "white_knight":"res://assets/pieces/skin_graphite_gold/white_knight.png", "white_bishop":"res://assets/pieces/skin_graphite_gold/white_bishop.png", "white_queen":"res://assets/pieces/skin_graphite_gold/white_queen.png", "white_king":"res://assets/pieces/skin_graphite_gold/white_king.png", "white_pawn":"res://assets/pieces/skin_graphite_gold/white_pawn.png"
        }
    }
    func set_theme_value(board_value: String, piece_value: String) -> void:
        board_theme = board_value
        piece_set = piece_value
        queue_redraw()
    func _draw() -> void:
        var side := minf(size.x, size.y)
        if side <= 0.0: return
        var cell := side / 8.0
        var use_graphite := board_theme == "graphite_gold"
        var light := Color("#68707A") if use_graphite else Color("#F0D9B5")
        var dark := Color("#30363E") if use_graphite else Color("#B58863")
        if use_graphite:
            draw_rect(Rect2(-7, -7, side + 14, side + 14), Color("#13171D"), true)
            draw_rect(Rect2(-6, -6, side + 12, side + 12), Color("#E6AD32"), false, 2.0)
        else:
            draw_rect(Rect2(-3, -3, side + 6, side + 6), Color("#0D0E10"), true)
        for y in range(8):
            for x in range(8):
                draw_rect(Rect2(Vector2(x * cell, y * cell), Vector2(cell, cell)), light if (x + y) % 2 == 0 else dark)
        var back_black := ["black_rook","black_knight","black_bishop","black_queen","black_king","black_bishop","black_knight","black_rook"]
        var back_white := ["white_rook","white_knight","white_bishop","white_queen","white_king","white_bishop","white_knight","white_rook"]
        for x in range(8):
            _piece(back_black[x], x, 0, cell)
            _piece("black_pawn", x, 1, cell)
            _piece("white_pawn", x, 6, cell)
            _piece(back_white[x], x, 7, cell)
    func _piece(id: String, x: int, y: int, cell: float) -> void:
        var set_dict: Dictionary = PIECES.get(piece_set, PIECES["classic"])
        var path := String(set_dict.get(id, ""))
        var tex: Texture2D
        var cache_key := piece_set + ":" + id
        if _texture_cache.has(cache_key):
            tex = _texture_cache[cache_key]
        else:
            tex = load(path) as Texture2D
            if tex != null:
                _texture_cache[cache_key] = tex
        if tex == null: return
        var source := tex.get_size()
        if source.x <= 0 or source.y <= 0: return
        var target := cell * 0.88
        var scale := minf(target / source.x, target / source.y)
        var piece_size := source * scale
        var pos := Vector2(x * cell + (cell - piece_size.x) * 0.5, y * cell + (cell - piece_size.y) * 0.5)
        draw_texture_rect(tex, Rect2(pos + Vector2(0, 1), piece_size), false, Color(0,0,0,0.13))
        draw_texture_rect(tex, Rect2(pos, piece_size), false)


func _section_title(text_value: String) -> Label:
    var l := Label.new()
    l.text = text_value
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.custom_minimum_size.x = 0.0
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.clip_text = true
    l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    l.add_theme_color_override("font_color", TEXT)
    var viewport := _layout_viewport()
    l.add_theme_font_size_override("font_size", 21 if viewport.x < 560.0 else 23)
    return l


func _add_toggle(label_text: String, description: String, key: String, value: bool) -> void:
    var box := _card()
    body.add_child(box)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    _card_content(box).add_child(row)
    var texts := VBoxContainer.new()
    texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(texts)
    var label := Label.new()
    label.text = label_text
    label.add_theme_color_override("font_color", TEXT)
    label.add_theme_font_size_override("font_size", 22)
    texts.add_child(label)
    var desc := Label.new()
    desc.text = description
    desc.add_theme_color_override("font_color", MUTED)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texts.add_child(desc)
    var check := CheckButton.new()
    check.button_pressed = value
    check.toggled.connect(func(on: bool):
        _data().set_setting(key, on)
        if key == "vibration" and on:
            Input.vibrate_handheld(25)
        _refresh()
    )
    row.add_child(check)


func _data() -> Object:
    return host._data()

func _card() -> PanelContainer:
    return host._card()

func _card_content(card: PanelContainer) -> VBoxContainer:
    return host._card_content(card)

func _stat_card(label_text: String, value: String) -> PanelContainer:
    return host._stat_card(label_text, value)

func _muted(text_value: String) -> Label:
    return host._muted(text_value)

func _button_style(fill: Color, radius: int, border_width: int, border: Color) -> StyleBoxFlat:
    return host._button_style(fill, radius, border_width, border)

func _panel_style(fill: Color) -> StyleBoxFlat:
    return host._panel_style(fill)

func _layout_viewport() -> Vector2:
    return host._layout_viewport()

func _edit_name() -> void:
    host._edit_name()

func _refresh() -> void:
    host._refresh()

func _open_history_analysis(record_id: String) -> void:
    host._open_history_analysis(record_id)

func _open_history_primary(record_id: String) -> void:
    host._open_history_primary(record_id)

func _start_engine_review(item: Dictionary, moves: Array, replay_data: Dictionary, status_label: Label, viewer: Control) -> void:
    host._start_engine_review(item, moves, replay_data, status_label, viewer)

func _mobile_ui_scale() -> float:
    return host._mobile_ui_scale()
