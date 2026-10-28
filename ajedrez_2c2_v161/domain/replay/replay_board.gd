# Board renderer for replay. Owns only board drawing; no replay navigation/state.
extends Control
class_name ReplayBoard

const BoardVisualContractScript = preload("res://core/visual/board_visual_contract.gd")
const BoardPieceRendererScript = preload("res://core/visual/board_piece_renderer.gd")
const PIECE_PATHS := {
    "torre_blanca": "res://assets/pieces/white_rook.png",
    "caballo_blanca": "res://assets/pieces/white_knight.png",
    "alfil_blanca": "res://assets/pieces/white_bishop.png",
    "dama_blanca": "res://assets/pieces/white_queen.png",
    "rey_blanca": "res://assets/pieces/white_king.png",
    "peon_blanca": "res://assets/pieces/white_pawn.png",
    "torre_negro": "res://assets/pieces/black_rook.png",
    "caballo_negro": "res://assets/pieces/black_knight.png",
    "alfil_negro": "res://assets/pieces/black_bishop.png",
    "dama_negro": "res://assets/pieces/black_queen.png",
    "rey_negro": "res://assets/pieces/black_king.png",
    "peon_negro": "res://assets/pieces/black_pawn.png",
}
const LIGHT := Color("#A9BED1")
const DARK := Color("#354B62")
const BORDER := Color("#13283D")
var owner_view: Node
var state: Dictionary = {}
var highlight_from := Vector2i(-1, -1)
var highlight_to := Vector2i(-1, -1)
var highlight_color := Color(0, 0, 0, 0)
var font: Font
var board_rect := Rect2()
static var _texture_cache: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    font = ThemeDB.fallback_font
    resized.connect(_on_resized)
    _on_resized()

func attach_owner(value: Node) -> void:
    owner_view = value

func set_state(value: Dictionary) -> void:
    state = value.duplicate(true)
    var visual_events = get_node_or_null("/root/BoardVisualEvents") if is_inside_tree() else null
    if visual_events != null:
        visual_events.publish_state("replay", state)
    queue_redraw()

func set_highlight(from_square: String, to_square: String, classification: String) -> void:
    highlight_from = _square_to_pos(from_square)
    highlight_to = _square_to_pos(to_square)
    highlight_color = _class_color(classification)
    var visual_events = get_node_or_null("/root/BoardVisualEvents") if is_inside_tree() else null
    if visual_events != null:
        visual_events.publish_highlight("replay", from_square, to_square, "suggestion")
    queue_redraw()


func _class_color(classification: String) -> Color:
    return BoardVisualContractScript.classification_color(classification)

func _square_to_pos(square: String) -> Vector2i:
    if square.length() != 2:
        return Vector2i(-1, -1)
    var x := square.unicode_at(0) - 97
    var rank := square.unicode_at(1) - 48
    var y := 8 - rank
    return Vector2i(x, y) if x >= 0 and x < 8 and y >= 0 and y < 8 else Vector2i(-1, -1)

func _on_resized() -> void:
    var side := minf(size.x, size.y)
    board_rect = Rect2(Vector2((size.x - side) * 0.5, (size.y - side) * 0.5), Vector2(side, side))
    queue_redraw()

func _draw() -> void:
    var side := board_rect.size.x
    if side <= 0.0:
        return
    var cell := side / 8.0
    draw_rect(board_rect.grow(2.0), BORDER, true)

    var board: Array = state.get("board", [])
    var valid := board.size() == 8
    if valid:
        for row in board:
            if not (row is Array) or row.size() != 8:
                valid = false
                break

    for y in range(8):
        for x in range(8):
            var rect := Rect2(board_rect.position + Vector2(x * cell, y * cell), Vector2(cell, cell))
            draw_rect(rect, LIGHT if (x + y) % 2 == 0 else DARK)
            var is_from := Vector2i(x, y) == highlight_from
            var is_to := Vector2i(x, y) == highlight_to
            if highlight_color.a > 0.0 and (is_from or is_to):
                draw_rect(rect, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.38), true)
                draw_rect(rect.grow(-2.0), Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.62), false, 3.0)
            var edge_color := Color(0.18, 0.17, 0.15, 0.80) if (x + y) % 2 == 0 else Color(0.95, 0.94, 0.90, 0.82)
            if x == 0:
                draw_string(font, rect.position + Vector2(4, 14), str(8 - y), HORIZONTAL_ALIGNMENT_LEFT, 20, 12, edge_color)
            if y == 7:
                draw_string(font, rect.position + Vector2(cell - 16, cell - 4), String.chr(97 + x), HORIZONTAL_ALIGNMENT_LEFT, 16, 12, edge_color)

            if valid:
                var piece_id := String(board[y][x])
                if PIECE_PATHS.has(piece_id):
                    _draw_piece(piece_id, rect, cell)

func _draw_piece(piece_id: String, cell_rect: Rect2, cell: float) -> void:
    var texture := _load_piece_texture(String(PIECE_PATHS[piece_id]))
    if texture == null:
        return
    BoardPieceRendererScript.draw_piece(self, texture, cell_rect, cell)

func _load_piece_texture(path: String) -> Texture2D:
    if _texture_cache.has(path):
        return _texture_cache[path]
    if not OS.has_feature("android"):
        var image := Image.load_from_file(ProjectSettings.globalize_path(path))
        if image != null and not image.is_empty():
            var texture := ImageTexture.create_from_image(image)
            _texture_cache[path] = texture
            return texture
    var resource := load(path) as Texture2D
    if resource != null:
        _texture_cache[path] = resource
    return resource

