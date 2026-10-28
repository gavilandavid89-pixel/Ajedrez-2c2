class_name ChessLayoutMetrics
extends RefCounted

const OUTER := 12.0
const TOP_BAR_TOP := 10.0
const TOP_BAR_HEIGHT := 54.0

# Portrait has two layout tiers. The compact tier is used on short phones so
# the board + both team headers + controls still fit without clipping.
const PORTRAIT_BOARD_SIDE_MARGIN := 8.0
const PORTRAIT_COMPACT_MAX_HEIGHT := 800.0
const PORTRAIT_COMPACT_TEAM_HEADER_HEIGHT := 70.0
const PORTRAIT_FULL_TEAM_HEADER_HEIGHT := 84.0
const PORTRAIT_BOARD_HEADER_GAP := 8.0
const PORTRAIT_MOVE_STATUS_GAP := 6.0
const PORTRAIT_PLAYER_BLOCK_GAP := 6.0
const PORTRAIT_ACTIONS_GAP := 4.0
const PORTRAIT_COMPACT_BOTTOM_OFFSET := 4.0
const PORTRAIT_FULL_BOTTOM_OFFSET := 6.0

const LANDSCAPE_BOARD_TOP := 12.0
const LANDSCAPE_BOTTOM_RESERVED := 112.0
const LANDSCAPE_BOTTOM_RESERVED_COMPACT := 120.0
const LANDSCAPE_SIDE_WIDTH_MIN := 176.0
const LANDSCAPE_SIDE_WIDTH_MAX := 264.0
const LANDSCAPE_SIDE_GAP := 14.0
const TEAM_HEADER_LANDSCAPE_HEIGHT_2C2 := 184.0
const TEAM_HEADER_LANDSCAPE_HEIGHT_1C1 := 112.0

const BOTTOM_HEIGHT := 60.0
const BOTTOM_HEIGHT_COMPACT := 64.0

static func is_portrait(viewport: Vector2) -> bool:
    return viewport.y >= viewport.x

static func is_compact_portrait(viewport: Vector2) -> bool:
    return is_portrait(viewport) and (
        viewport.y < PORTRAIT_COMPACT_MAX_HEIGHT
        or viewport.x < 400.0
    )

static func portrait_team_header_height(viewport: Vector2) -> float:
    return PORTRAIT_COMPACT_TEAM_HEADER_HEIGHT if is_compact_portrait(viewport) else PORTRAIT_FULL_TEAM_HEADER_HEIGHT

static func portrait_bottom_offset(viewport: Vector2) -> float:
    return PORTRAIT_COMPACT_BOTTOM_OFFSET if is_compact_portrait(viewport) else PORTRAIT_FULL_BOTTOM_OFFSET

static func portrait_bottom_height(viewport: Vector2) -> float:
    # The compact portrait action bar wraps into two rows on narrow phones.
    return BOTTOM_HEIGHT_COMPACT if viewport.x < 560.0 else BOTTOM_HEIGHT

static func landscape_side_width(viewport: Vector2) -> float:
    return clampf(viewport.x * 0.21, LANDSCAPE_SIDE_WIDTH_MIN, LANDSCAPE_SIDE_WIDTH_MAX)

static func portrait_stack_metrics(viewport: Vector2) -> Dictionary:
    var team_height: float = portrait_team_header_height(viewport)
    var moves_height: float = 16.0 if is_compact_portrait(viewport) else 18.0
    var bottom_team_extra: float = 18.0 if viewport.y > 900.0 else 8.0
    var lower_stack_height: float = moves_height + PORTRAIT_MOVE_STATUS_GAP + PORTRAIT_PLAYER_BLOCK_GAP + team_height + bottom_team_extra + PORTRAIT_ACTIONS_GAP + BOTTOM_HEIGHT_COMPACT
    return {"team_height": team_height, "moves_height": moves_height, "bottom_team_extra": bottom_team_extra, "lower_stack_height": lower_stack_height}

static func portrait_team_top(viewport: Vector2) -> float:
    var metrics := portrait_stack_metrics(viewport)
    var team_height: float = float(metrics["team_height"])
    var lower_stack_height: float = float(metrics["lower_stack_height"])
    var side_margin := minf(PORTRAIT_BOARD_SIDE_MARGIN, maxf(0.0, (viewport.x - 220.0) * 0.5))
    var width_limit: float = maxf(220.0, viewport.x - side_margin * 2.0)
    var height_limit: float = maxf(220.0, viewport.y - team_height - lower_stack_height - PORTRAIT_BOARD_HEADER_GAP - 12.0)
    var size: float = minf(width_limit, height_limit)
    var free_vertical: float = maxf(0.0, viewport.y - team_height - PORTRAIT_BOARD_HEADER_GAP - size - lower_stack_height)
    # La identidad del rival se acerca a la parte superior; el espacio sobrante
    # se deja entre los grupos inferiores para que no parezca un tablero flotante.
    return free_vertical * 0.32

static func board_rect(viewport: Vector2, result_mode: bool = false) -> Rect2:
    var portrait := is_portrait(viewport)
    if portrait:
        var side_margin := minf(PORTRAIT_BOARD_SIDE_MARGIN, maxf(0.0, (viewport.x - 220.0) * 0.5))
        var width_limit: float = maxf(220.0, viewport.x - side_margin * 2.0)
        if result_mode:
            var result_top := 54.0
            var result_height_limit: float = maxf(220.0, viewport.y - result_top - 190.0)
            var result_size: float = minf(width_limit, result_height_limit)
            return Rect2(Vector2((viewport.x - result_size) * 0.5, result_top), Vector2(result_size, result_size))
        var metrics := portrait_stack_metrics(viewport)
        var team_height: float = float(metrics["team_height"])
        var lower_stack_height: float = float(metrics["lower_stack_height"])
        var height_limit: float = maxf(220.0, viewport.y - team_height - lower_stack_height - PORTRAIT_BOARD_HEADER_GAP - 12.0)
        var size: float = minf(width_limit, height_limit)
        var top: float = portrait_team_top(viewport) + team_height + PORTRAIT_BOARD_HEADER_GAP
        return Rect2(Vector2((viewport.x - size) * 0.5, top), Vector2(size, size))

    # El tablero de ajedrez debe conservar casillas cuadradas. En horizontal
    # se maximiza contra la altura disponible; estirarlo a todo el ancho de un
    # móvil 16:9 deformaría las casillas o cortaría filas/columnas.
    var horizontal_limit: float = maxf(220.0, viewport.x - 24.0)
    var vertical_limit: float = maxf(220.0, viewport.y - LANDSCAPE_BOARD_TOP - 12.0)
    var size: float = minf(horizontal_limit, vertical_limit)
    return Rect2(Vector2((viewport.x - size) * 0.5, maxf(8.0, (viewport.y - size) * 0.5)), Vector2(size, size))

static func bottom_rect(viewport: Vector2, board: Rect2, compact: bool = false) -> Rect2:
    if is_portrait(viewport):
        var height := portrait_bottom_height(viewport)
        return Rect2(
            Vector2(OUTER, board.end.y + portrait_bottom_offset(viewport)),
            Vector2(max(0.0, viewport.x - OUTER * 2.0), height)
        )

    var height: float = BOTTOM_HEIGHT_COMPACT if (compact or board.size.x < 520.0) else BOTTOM_HEIGHT
    # En horizontal también hay una línea de movimientos bajo el tablero.
    # Separa la barra de acciones lo suficiente para que no tape ese texto.
    return Rect2(
        Vector2(OUTER, board.end.y + 36.0),
        Vector2(max(0.0, viewport.x - OUTER * 2.0), height)
    )

static func landscape_side_rect(viewport: Vector2, right_side: bool, height: float) -> Rect2:
    var board := board_rect(viewport, false)
    var x: float
    var width: float
    if right_side:
        x = board.end.x + OUTER
        width = maxf(0.0, viewport.x - x - OUTER)
    else:
        x = OUTER
        width = maxf(0.0, board.position.x - OUTER * 2.0)
    return Rect2(Vector2(x, LANDSCAPE_BOARD_TOP), Vector2(width, height))
