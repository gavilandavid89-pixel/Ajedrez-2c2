extends Node

# Compensates for the portrait reference canvas shrinking in short landscape
# windows. Portrait stays at 1.0; landscape raises the content scale only when
# the physical window height is shorter than the 844 px reference height.
const PORTRAIT_REFERENCE_HEIGHT := 844.0
const MAX_CONTENT_SCALE := 2.5
const SCALE_EPSILON := 0.01

var _window: Window
var _last_window_size := Vector2i.ZERO

func _ready() -> void:
    _window = get_window()
    if _window != null and not _window.size_changed.is_connected(_on_window_size_changed):
        _window.size_changed.connect(_on_window_size_changed)
    call_deferred("_apply_scale")

func _exit_tree() -> void:
    if _window != null and is_instance_valid(_window):
        if _window.size_changed.is_connected(_on_window_size_changed):
            _window.size_changed.disconnect(_on_window_size_changed)
    _window = null

func _on_window_size_changed() -> void:
    _apply_scale()

func _apply_scale() -> void:
    if _window == null or not is_instance_valid(_window):
        return
    var window_size := _window.size
    if window_size.x <= 0 or window_size.y <= 0 or window_size == _last_window_size:
        return
    _last_window_size = window_size
    var target_scale := 1.0
    if window_size.x > window_size.y and window_size.y < PORTRAIT_REFERENCE_HEIGHT:
        target_scale = clampf(PORTRAIT_REFERENCE_HEIGHT / float(window_size.y), 1.0, MAX_CONTENT_SCALE)
    if absf(_window.content_scale_factor - target_scale) > SCALE_EPSILON:
        _window.content_scale_factor = target_scale
