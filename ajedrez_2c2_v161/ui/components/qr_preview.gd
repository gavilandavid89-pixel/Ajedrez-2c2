class_name InviteQrPreview
extends Control

@export var seed_text: String = "A2V7K9"

func _ready() -> void:
    custom_minimum_size = Vector2(164, 164)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()

func set_code(code: String) -> void:
    seed_text = code
    queue_redraw()

func _hash_value(x: int, y: int) -> int:
    var h := 2166136261
    for c in seed_text.to_utf8_buffer():
        h = int((h ^ int(c)) * 16777619) & 0x7fffffff
    h = int((h ^ (x * 374761393)) * 668265263) & 0x7fffffff
    h = int((h ^ (y * 1274126177)) * 2246822519) & 0x7fffffff
    return h

func _finder_on(x: int, y: int, ox: int, oy: int) -> bool:
    if x < ox or x >= ox + 7 or y < oy or y >= oy + 7:
        return false
    var dx := x - ox
    var dy := y - oy
    return dx == 0 or dx == 6 or dy == 0 or dy == 6 or (dx >= 2 and dx <= 4 and dy >= 2 and dy <= 4)

func _draw() -> void:
    var side := minf(size.x, size.y)
    var cell := side / 17.0
    draw_style_box(_box(Color("#F5E8C9"), 12), Rect2(Vector2.ZERO, Vector2(side, side)))
    var inset := 1.0
    for y in range(17):
        for x in range(17):
            var on := false
            if _finder_on(x, y, 0, 0) or _finder_on(x, y, 10, 0) or _finder_on(x, y, 0, 10):
                on = true
            elif x >= 8 and x <= 11 and y == 8:
                on = (x % 2 == 0)
            elif y >= 8 and y <= 11 and x == 8:
                on = (y % 2 == 1)
            else:
                on = (_hash_value(x, y) % 5) < 2
            if on:
                draw_rect(Rect2(Vector2(x * cell + inset, y * cell + inset), Vector2(maxf(1.0, cell - inset * 2.0), maxf(1.0, cell - inset * 2.0))), Color("#1E1915"))

func _box(color: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.set_corner_radius_all(radius)
    return style
