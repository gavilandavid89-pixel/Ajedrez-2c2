extends RefCounted
class_name BoardPieceRenderer

## Single source of truth for piece scale, centering and shadow across all board views.
const BoardVisualContractScript = preload("res://core/visual/board_visual_contract.gd")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.16)

static func piece_size(texture: Texture2D, cell: float) -> Vector2:
    if texture == null or cell <= 0.0:
        return Vector2.ZERO
    var source_size := texture.get_size()
    if source_size.x <= 0.0 or source_size.y <= 0.0:
        return Vector2.ZERO
    var target_side := cell * BoardVisualContractScript.PIECE_DRAW_RATIO
    var scale_factor := minf(target_side / source_size.x, target_side / source_size.y)
    return source_size * scale_factor

static func draw_piece(canvas: CanvasItem, texture: Texture2D, cell_rect: Rect2, cell: float) -> void:
    if canvas == null or texture == null:
        return
    var size := piece_size(texture, cell)
    if size == Vector2.ZERO:
        return
    var pos := cell_rect.position + (cell_rect.size - size) * 0.5
    var shadow_rect := Rect2(pos + Vector2(0.0, maxf(1.5, cell * 0.018)), size)
    canvas.draw_texture_rect(texture, shadow_rect, false, SHADOW_COLOR)
    canvas.draw_texture_rect(texture, Rect2(pos, size), false)
