extends Panel
class_name PlayerCard

@onready var avatar: TextureRect = $Avatar
@onready var name_label: Label = $Info/Name
@onready var title_label: Label = $Info/Title
@onready var state_label: Label = $Info/State
@onready var avatar_frame: Panel = $AvatarFrame
@onready var emote_badge: TextureRect = $EmoteBadge

var _emote_tween: Tween

func _ready() -> void:
    resized.connect(_layout_contents)
    _layout_contents()
    _apply_avatar_frame("classic")

func _layout_contents() -> void:
    if not is_node_ready():
        return
    var mobile_scale := 1.0
    if is_inside_tree():
        var win := get_window().size
        var short_side := minf(float(win.x), float(win.y))
        if short_side > 0.0:
            mobile_scale = clampf(720.0 / short_side, 1.0, 1.85)

    # Tarjeta deliberadamente transparente: durante la partida solo importan
    # el avatar y el nombre. El reloj vive fuera de esta tarjeta.
    add_theme_stylebox_override("panel", StyleBoxEmpty.new())
    clip_contents = false
    title_label.visible = false
    state_label.visible = false
    name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
    name_label.clip_text = true

    var viewport_size := get_viewport_rect().size if is_inside_tree() else Vector2(360.0, 640.0)
    if viewport_size.x > viewport_size.y:
        # Landscape player rail: avatar left, readable name to its right.
        # This avoids vertical labels and clipped names in narrow side columns.
        var avatar_side_landscape := clampf(size.y - 8.0, 44.0, 54.0)
        avatar_frame.size = Vector2(avatar_side_landscape + 2.0, avatar_side_landscape + 2.0)
        avatar_frame.position = Vector2(2.0, (size.y - avatar_side_landscape - 2.0) * 0.5)
        avatar.size = Vector2(avatar_side_landscape, avatar_side_landscape)
        avatar.position = avatar_frame.position + Vector2(1.0, 1.0)
        $Info.position = Vector2(avatar_side_landscape + 9.0, 0.0)
        $Info.size = Vector2(maxf(20.0, size.x - avatar_side_landscape - 12.0), size.y)
        name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_label.add_theme_font_size_override("font_size", int(round(clampf(15.0 * mobile_scale, 14.0, 18.0))))
        return

    var compact := size.x < 112.0 or size.y < 74.0
    # El avatar conserva una zona nítida sin forzar una fila demasiado alta.
    var avatar_side := clampf(size.y - (18.0 if compact else 20.0), 48.0 if compact else 48.0, 50.0 if compact else 60.0)

    avatar_frame.size = Vector2(avatar_side + 2.0, avatar_side + 2.0)
    avatar_frame.position = Vector2((size.x - avatar_side - 2.0) * 0.5, 0.0)
    avatar.size = Vector2(avatar_side, avatar_side)
    avatar.position = avatar_frame.position + Vector2(1.0, 1.0)

    $Info.position = Vector2(1.0, avatar_side + 4.0)
    $Info.size = Vector2(maxf(16.0, size.x - 2.0), maxf(18.0, size.y - avatar_side - 4.0))
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    var name_size := 15.0 if compact else clampf(16.0 * mobile_scale, 15.0, 17.0)
    name_label.add_theme_font_size_override("font_size", int(round(name_size)))
    title_label.visible = false
    state_label.visible = false

func set_profile(profile: Dictionary, role: String, active: bool, is_turn: bool, accent: Color) -> void:
    var raw_name := String(profile.get("name", "Jugador")).strip_edges()
    name_label.text = raw_name.left(10)
    title_label.text = ""
    state_label.text = ""
    var path := String(profile.get("avatar", ""))
    if path.begins_with("user://") and FileAccess.file_exists(path):
        var image := Image.load_from_file(ProjectSettings.globalize_path(path))
        if image != null and not image.is_empty():
            avatar.texture = ImageTexture.create_from_image(image)
    elif not path.is_empty() and ResourceLoader.exists(path):
        avatar.texture = load(path)
    elif ResourceLoader.exists("res://assets/avatars/avatar_you.svg"):
        avatar.texture = load("res://assets/avatars/avatar_you.svg")
    _apply_avatar_frame(String(profile.get("frame", "classic")))
    name_label.add_theme_color_override("font_color", _name_color(String(profile.get("name_color", "cream"))))
    _layout_contents()
    _fit_name_to_width()
    update_state(active, is_turn, accent, role)

func _fit_name_to_width() -> void:
    if not is_node_ready() or name_label.text.is_empty():
        return
    var font := name_label.get_theme_font("font")
    var size := int(name_label.get_theme_font_size("font_size"))
    var available := maxf(20.0, name_label.size.x - 2.0)
    while size > 13:
        if font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x <= available:
            break
        size -= 1
    name_label.add_theme_font_size_override("font_size", size)

func _apply_avatar_frame(frame_id: String) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0)
    style.set_corner_radius_all(10)
    style.set_border_width_all(2)
    style.border_color = Color("#4A4034")
    if frame_id == "gold":
        style.border_color = Color("#D5A84E")
        style.set_border_width_all(3)
    avatar_frame.add_theme_stylebox_override("panel", style)

func _name_color(color_id: String) -> Color:
    match color_id:
        "gold": return Color("#D5A84E")
        "blue": return Color("#77B7FF")
        "green": return Color("#9FCB9A")
        "red": return Color("#E47B6E")
        _: return Color("#F0E3C4")

func update_state(active: bool, is_turn: bool, accent: Color, role: String = "Jugador") -> void:
    # El foco de turno vive en el reloj; aquí solo comunicamos disponibilidad
    # de forma muy discreta para no crear otra tarjeta ni otro marco.
    var alpha := 1.0 if active else 0.52
    avatar.modulate = Color(1.0, 1.0, 1.0, alpha)
    name_label.modulate = Color(1.0, 1.0, 1.0, alpha)
    add_theme_stylebox_override("panel", StyleBoxEmpty.new())

func show_emote(texture: Texture2D) -> void:
    if texture == null:
        return
    emote_badge.texture = texture
    # Reacción temporal grande y nítida; puede sobresalir de la tarjeta y rozar el tablero.
    var badge_size: float = clampf(max(min(size.x, size.y) * 1.34, 92.0), 92.0, 132.0)
    emote_badge.size = Vector2(badge_size, badge_size)
    # Puede invadir brevemente el espacio del tablero, pero no altera el layout.
    emote_badge.position = Vector2(max(2.0, size.x - badge_size - 2.0), -badge_size * 0.20)
    emote_badge.modulate = Color(1, 1, 1, 1)
    emote_badge.scale = Vector2(0.68, 0.68)
    emote_badge.pivot_offset = Vector2(badge_size * 0.5, badge_size * 0.5)
    emote_badge.visible = true
    if _emote_tween and _emote_tween.is_valid():
        _emote_tween.kill()
    _emote_tween = create_tween()
    _emote_tween.set_parallel(true)
    _emote_tween.tween_property(emote_badge, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _emote_tween.tween_property(emote_badge, "position:y", -badge_size * 0.18, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _emote_tween.set_parallel(false)
    _emote_tween.tween_interval(1.05)
    _emote_tween.tween_property(emote_badge, "modulate:a", 0.0, 0.18)
    _emote_tween.tween_callback(func():
        emote_badge.visible = false
        emote_badge.modulate.a = 1.0
    )
