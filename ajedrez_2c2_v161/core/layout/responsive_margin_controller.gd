extends Node
class_name ResponsiveMarginController

# Owns viewport resize subscriptions for one screen/margin pair.
# The controller is a child of the screen, so leaving the screen disconnects
# the global viewport signal before either target can be freed.
var _host_ref: WeakRef
var _margin_ref: WeakRef
var _viewport: Viewport
var _portrait := Vector4(16.0, 16.0, 14.0, 104.0) # left, right, top, bottom
var _landscape := Vector4(174.0, 16.0, 10.0, 16.0)

func configure(
    host: Control,
    margin: Control,
    portrait_left: float,
    portrait_right: float,
    portrait_top: float,
    portrait_bottom: float,
    landscape_left: float,
    landscape_right: float,
    landscape_top: float,
    landscape_bottom: float
) -> void:
    _host_ref = weakref(host)
    _margin_ref = weakref(margin)
    _portrait = Vector4(portrait_left, portrait_right, portrait_top, portrait_bottom)
    _landscape = Vector4(landscape_left, landscape_right, landscape_top, landscape_bottom)

func _ready() -> void:
    var host := _host() 
    if host == null:
        return
    _viewport = host.get_viewport()
    if _viewport != null and not _viewport.size_changed.is_connected(_on_viewport_size_changed):
        _viewport.size_changed.connect(_on_viewport_size_changed)
    _apply_layout()
    call_deferred("_apply_layout")

func _exit_tree() -> void:
    if _viewport != null and is_instance_valid(_viewport):
        if _viewport.size_changed.is_connected(_on_viewport_size_changed):
            _viewport.size_changed.disconnect(_on_viewport_size_changed)
    _viewport = null
    _host_ref = null
    _margin_ref = null

func _on_viewport_size_changed() -> void:
    _apply_layout()

func _apply_layout() -> void:
    var host := _host()
    var margin := _margin()
    if host == null or margin == null or not host.is_inside_tree() or not margin.is_inside_tree():
        return
    var viewport_size := host.get_viewport_rect().size
    var values := _portrait if viewport_size.y >= viewport_size.x else _landscape
    margin.offset_left = values.x
    margin.offset_right = -values.y
    margin.offset_top = values.z
    margin.offset_bottom = -values.w

func _host() -> Control:
    if _host_ref == null:
        return null
    return _host_ref.get_ref() as Control

func _margin() -> Control:
    if _margin_ref == null:
        return null
    return _margin_ref.get_ref() as Control
