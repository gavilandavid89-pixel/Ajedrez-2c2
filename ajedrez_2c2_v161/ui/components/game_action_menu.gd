extends Control

signal action_selected(action: String)
signal dismissed

@onready var panel: Panel = $Panel
@onready var resign: Button = $Panel/Buttons/Rendirse
@onready var draw_button: Button = $Panel/Buttons/Tablas

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    resign.pressed.connect(func(): _choose("surrender"))
    draw_button.pressed.connect(func(): _choose("draw"))
    gui_input.connect(_on_gui_input)
    hide_menu()

func show_menu(anchor: Rect2, viewport_size: Vector2, min_y: float = 0.0) -> void:
    visible = true
    move_to_front()
    var margin := 8.0
    var menu_w := clampf(188.0, 176.0, maxf(176.0, viewport_size.x - margin * 2.0))
    var menu_h := 80.0
    var x := clampf(anchor.position.x + anchor.size.x - menu_w, margin, maxf(margin, viewport_size.x - menu_w - margin))
    var y := anchor.position.y - menu_h - 8.0
    if y < margin:
        y = anchor.end.y + 8.0
    if min_y > 0.0:
        y = maxf(y, min_y)
    if y + menu_h > viewport_size.y - margin:
        y = maxf(margin, viewport_size.y - menu_h - margin)
    panel.position = Vector2(x, y)
    panel.size = Vector2(menu_w, menu_h)
    $Panel/Buttons.position = Vector2(8.0, 6.0)
    $Panel/Buttons.size = Vector2(menu_w - 16.0, 68.0)

func hide_menu() -> void:
    visible = false

func _choose(action: String) -> void:
    hide_menu()
    action_selected.emit(action)

func _dismiss() -> void:
    hide_menu()
    dismissed.emit()

func _on_gui_input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventScreenTouch and event.pressed:
        if not panel.get_global_rect().has_point(event.position):
            _dismiss()
            get_viewport().set_input_as_handled()
