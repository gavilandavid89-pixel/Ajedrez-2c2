extends RefCounted
class_name GameOverlayController

signal action_requested(action: String)

var host: Control
var panel: Control
var title_label: Label
var body_label: Label
var cooldown_label: Label
var actions_box: Container
var font_provider: Callable
var dragging := false
var drag_offset := Vector2.ZERO

func attach(owner: Control, mini_panel: Control, title: Label, body: Label, cooldown: Label, actions: Container, scaled_font: Callable) -> void:
    host = owner
    panel = mini_panel
    title_label = title
    body_label = body
    cooldown_label = cooldown
    actions_box = actions
    font_provider = scaled_font
    if title_label != null:
        title_label.mouse_default_cursor_shape = Control.CURSOR_MOVE

func show_suggestion(proposer_name: String, target_name: String) -> void:
    if panel == null:
        return
    panel.set_meta("manual_open", false)
    panel.set_meta("suggestion_mode", true)
    panel.set_meta("manual_position", false)
    title_label.text = "\"%s\"" % proposer_name.left(10)
    title_label.clip_text = true
    title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    body_label.text = "sugiere %s" % target_name
    body_label.clip_text = true
    body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    cooldown_label.text = ""
    cooldown_label.visible = false
    panel.get_node("Close").visible = false
    _clear_actions()
    var specs := [
        ["✅", "accept_suggestion", "#4F6B56", "Aceptar"],
        ["❌", "reject_suggestion", "#B64B3E", "Rechazar"],
        ["❔❔", "challenge", "#8D6A36", "Cuestionar"],
    ]
    for spec in specs:
        _add_action(String(spec[0]), String(spec[1]), String(spec[2]), String(spec[3]), false, 34.0)
    panel.visible = true
    title_label.mouse_filter = Control.MOUSE_FILTER_STOP

func show_panel(title: String, body: String, cooldown: String, actions: Array, mobile_scale: float = 1.0) -> void:
    if panel == null:
        return
    panel.set_meta("manual_open", false)
    panel.set_meta("suggestion_mode", false)
    panel.set_meta("manual_position", false)
    title_label.text = title
    body_label.text = body
    cooldown_label.text = cooldown
    cooldown_label.visible = not cooldown.is_empty()
    panel.get_node("Close").visible = true
    _clear_actions()
    var action_count: int = max(1, actions.size())
    var viewport_width: float = host.get_viewport_rect().size.x if host != null and host.is_inside_tree() else 360.0
    var contextual_width: float = minf(316.0, maxf(224.0, viewport_width - 24.0))
    var action_gap_total: float = 6.0 * float(max(0, action_count - 1))
    var action_available: float = maxf(120.0, contextual_width - 54.0 - action_gap_total)
    var action_width: float = clampf(action_available / float(action_count), 74.0, 112.0)
    var action_height: float = 48.0 if action_count <= 2 and mobile_scale > 1.30 else 42.0
    for spec in actions:
        _add_action(String(spec[0]), String(spec[1]), String(spec[2]), "", false, action_height, action_width, action_count)
    panel.visible = true

func close() -> void:
    if panel == null:
        return
    panel.visible = false
    panel.set_meta("manual_open", false)
    panel.set_meta("suggestion_mode", false)
    dragging = false

func is_suggestion_mode() -> bool:
    return panel != null and panel.visible and bool(panel.get_meta("suggestion_mode", false))

func handle_title_input(event: InputEvent) -> void:
    if not is_suggestion_mode():
        return
    if host == null or panel == null:
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            dragging = true
            drag_offset = panel.global_position - event.position
            panel.set_meta("manual_position", true)
            host.get_viewport().set_input_as_handled()
        else:
            dragging = false
            host.get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and dragging:
        move_to(event.position + drag_offset)
        host.get_viewport().set_input_as_handled()

func move_to(target: Vector2) -> void:
    if host == null or panel == null:
        return
    var vp := host.get_viewport_rect().size
    var margin := 6.0
    var x := clampf(target.x, margin, maxf(margin, vp.x - panel.size.x - margin))
    var y := clampf(target.y, margin, maxf(margin, vp.y - panel.size.y - margin))
    panel.global_position = Vector2(x, y)

func _clear_actions() -> void:
    if actions_box == null:
        return
    for child in actions_box.get_children():
        child.queue_free()

func _add_action(symbol: String, action: String, fill: String, tooltip: String, _unused := false, height: float = 42.0, width: float = -1.0, action_count: int = 1) -> void:
    var button := Button.new()
    button.text = symbol
    if not tooltip.is_empty():
        button.tooltip_text = tooltip
    var target_width := width
    if target_width <= 0.0:
        target_width = 32.0 if symbol != "❔❔" else 42.0
    button.custom_minimum_size = Vector2(target_width, height)
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    var style := StyleBoxFlat.new()
    style.bg_color = Color(fill)
    style.set_corner_radius_all(9 if action_count == 1 else 8)
    button.add_theme_stylebox_override("normal", style)
    var font_size := 13
    if action_count >= 3:
        font_size = 12
    elif font_provider.is_valid():
        font_size = int(font_provider.call(13.0, 18.0))
    button.add_theme_font_size_override("font_size", font_size)
    button.pressed.connect(func():
        action_requested.emit(action)
        close()
    )
    actions_box.add_child(button)
