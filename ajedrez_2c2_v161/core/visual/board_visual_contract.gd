extends RefCounted
class_name BoardVisualContract

## Shared visual contract for every chessboard, including replay and live play.
const PIECE_DRAW_RATIO := 1.55
const MOVE_DURATION := 0.32
const HIGHLIGHT_LAST_MOVE := Color(0.94, 0.83, 0.28, 0.40)
const HIGHLIGHT_SELECTED := Color(0.12, 0.86, 0.33, 0.28)
const HIGHLIGHT_SUGGESTION := Color(0.31, 0.66, 1.0, 0.90)
const HIGHLIGHT_ERROR := Color(0.88, 0.20, 0.20, 0.38)

static func classification_color(classification: String) -> Color:
    return {
        "Error grave": Color("#D94B4B"),
        "Error": Color("#E06B5E"),
        "Imprecisa": Color("#D9A441"),
        "Bien": Color("#77B96A"),
        "Muy bien": Color("#63C96B"),
        "Excelente": Color("#45D36B"),
        "Genial": Color("#61A8FF"),
        "Brillante": Color("#C07CFF"),
        "Mejor jugada": HIGHLIGHT_SUGGESTION,
    }.get(classification, Color(0, 0, 0, 0))
