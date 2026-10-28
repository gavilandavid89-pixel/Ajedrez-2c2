extends Control
class_name PieceMoveAnimator

## Animador visual independiente de la lógica de ajedrez.
## El estado real se actualiza primero; este componente solo interpola la
## representación de la pieza para que el movimiento no parezca instantáneo.

signal move_started(move: Dictionary)
signal move_landed(move: Dictionary)

const BoardVisualContractScript = preload("res://core/visual/board_visual_contract.gd")
const DEFAULT_DURATION := BoardVisualContractScript.MOVE_DURATION
const MAX_DURATION := 0.45
const LIFT_RATIO := 0.070

var board_view: Control
var active_move: Dictionary = {}
var active_segments: Array[Dictionary] = []
var elapsed := 0.0
var duration := DEFAULT_DURATION
var _tween: Tween
@export var visual_source := "match"

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    z_index = 20
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func bind_board(board: Control) -> void:
    board_view = board
    queue_redraw()

func is_animating() -> bool:
    return not active_move.is_empty()

func animate_move(move: Dictionary) -> void:
    if move.is_empty() or board_view == null:
        return
    var from := _parse_square(String(move.get("from", "")))
    var to := _parse_square(String(move.get("to", "")))
    if from == Vector2i(-1, -1) or to == Vector2i(-1, -1):
        return

    stop_animation(false)
    active_move = move.duplicate(true)
    active_segments.clear()
    active_segments.append({
        "piece": String(move.get("piece", "")),
        "from": from,
        "to": to,
    })

    # Enroque: la torre también debe deslizarse. Ambas piezas aterrizan juntas.
    if bool(move.get("castle", false)):
        var rook_from_x := 7 if to.x > from.x else 0
        var rook_to_x := 5 if to.x > from.x else 3
        var rook_piece := "torre_blanca" if String(move.get("piece", "")).ends_with("blanca") else "torre_negro"
        active_segments.append({
            "piece": rook_piece,
            "from": Vector2i(rook_from_x, from.y),
            "to": Vector2i(rook_to_x, from.y),
        })

    var max_distance := 1.0
    for segment in active_segments:
        max_distance = maxf(max_distance, Vector2(segment["from"]).distance_to(Vector2(segment["to"])))
    duration = clampf(DEFAULT_DURATION * (0.82 + minf(max_distance, 3.0) * 0.15), 0.28, MAX_DURATION)
    elapsed = 0.0
    move_started.emit(active_move)
    var visual_events = get_node_or_null("/root/BoardVisualEvents")
    if visual_events != null:
        visual_events.publish_move_started(visual_source, active_move)
    queue_redraw()

    _tween = create_tween()
    _tween.set_trans(Tween.TRANS_CUBIC)
    _tween.set_ease(Tween.EASE_OUT)
    _tween.tween_property(self, "elapsed", duration, duration)
    _tween.finished.connect(_finish_animation)

func stop_animation(emit_finished: bool = false) -> void:
    if _tween != null and is_instance_valid(_tween):
        _tween.kill()
    _tween = null
    var previous := active_move
    active_move = {}
    active_segments.clear()
    elapsed = 0.0
    queue_redraw()
    if board_view != null:
        board_view.queue_redraw()
    if emit_finished and not previous.is_empty():
        move_landed.emit(previous)

func _finish_animation() -> void:
    var landed := active_move.duplicate(true)
    _tween = null
    active_move = {}
    active_segments.clear()
    elapsed = 0.0
    queue_redraw()
    if board_view != null:
        board_view.queue_redraw()
    if not landed.is_empty():
        move_landed.emit(landed)
        var visual_events = get_node_or_null("/root/BoardVisualEvents")
        if visual_events != null:
            visual_events.publish_move_finished(visual_source, landed)

func should_hide_piece_at(logical: Vector2i) -> bool:
    if active_move.is_empty():
        return false
    for segment in active_segments:
        if Vector2i(segment["to"]) == logical:
            return true
    return false

func _process(_delta: float) -> void:
    if not active_move.is_empty():
        queue_redraw()

func _draw() -> void:
    if active_move.is_empty() or board_view == null:
        return
    var cell: float = board_view.board_rect.size.x / 8.0
    if cell <= 0.0:
        return
    for segment in active_segments:
        var piece := String(segment["piece"])
        var from := Vector2i(segment["from"])
        var to := Vector2i(segment["to"])
        var t := clampf(elapsed / maxf(0.001, duration), 0.0, 1.0)
        # Desaceleración suave al llegar al escaque, evitando el efecto de
        # teletransporte. Un pequeño levantamiento visual refuerza el trayecto.
        var eased := 1.0 - pow(1.0 - t, 2.0)
        var lift := sin(PI * eased) * cell * LIFT_RATIO
        var screen_from: Vector2i = board_view._screen_pos(from)
        var screen_to: Vector2i = board_view._screen_pos(to)
        var screen := Vector2(screen_from).lerp(Vector2(screen_to), eased)
        var center: Vector2 = board_view.board_rect.position + Vector2(
            (screen.x + 0.5) * cell,
            (screen.y + 0.5) * cell - lift
        )
        var texture: Texture2D = board_view.get_piece_texture(piece)
        var piece_size: Vector2 = board_view.piece_draw_size(piece, cell)
        if texture == null or piece_size == Vector2.ZERO:
            continue
        var piece_pos: Vector2 = center - piece_size * 0.5
        var shadow_rect := Rect2(piece_pos + Vector2(0.0, max(1.5, cell * 0.018)), piece_size)
        draw_texture_rect(texture, shadow_rect, false, Color(0.0, 0.0, 0.0, 0.16))
        draw_texture_rect(texture, Rect2(piece_pos, piece_size), false)

func _parse_square(value: String) -> Vector2i:
    var text := value.strip_edges().to_lower()
    if text.length() != 2:
        return Vector2i(-1, -1)
    var file := text.unicode_at(0) - 97
    var rank := text.unicode_at(1) - 49
    if file < 0 or file > 7 or rank < 0 or rank > 7:
        return Vector2i(-1, -1)
    return Vector2i(file, 7 - rank)
