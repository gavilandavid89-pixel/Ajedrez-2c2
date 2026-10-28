extends RefCounted
class_name CompetitiveSystem

# Primitivas competitivas y economía de copas del proyecto.
# NEXUS-SOLO/NEXUS-TEAM hacen la actualización de rating; estas primitivas
# conservan compatibilidad con migraciones/tests y gestionan copas/ligas.
# Los valores están aislados aquí para poder ajustarlos sin tocar PlayerData/UI.
const DEFAULT_RATING := 1000
const MIN_RATING := 100
const K_FACTOR := 24.0 # Compatibilidad histórica; NEXUS V2 usa K adaptativo.
const CUP_WIN_SIMILAR := 10
const CUP_WIN_STRONGER := 13
const CUP_WIN_WEAKER := 7
const CUP_DRAW_SIMILAR := 4
const CUP_DRAW_STRONGER := 6
const CUP_DRAW_WEAKER := 2
const CUP_LOSS_SIMILAR := -6
const CUP_LOSS_STRONGER := -2
const LARGE_GAP := 150

const LEAGUES := [
    {"id": "bronze", "name": "Bronce", "min_cups": 0},
    {"id": "silver", "name": "Plata", "min_cups": 200},
    {"id": "gold", "name": "Oro", "min_cups": 500},
    {"id": "platinum", "name": "Platino", "min_cups": 900},
    {"id": "diamond", "name": "Diamante", "min_cups": 1400},
    {"id": "legend", "name": "Leyenda", "min_cups": 2000},
]

static func normalize_outcome(outcome: String) -> String:
    var value := outcome.strip_edges().to_lower()
    if value == "win" or value == "loss" or value == "draw":
        return value
    return ""

static func expected_score(my_rating: int, opponent_rating: int) -> float:
    return 1.0 / (1.0 + pow(10.0, float(opponent_rating - my_rating) / 400.0))

static func rating_delta(my_rating: int, opponent_rating: int, outcome: String) -> int:
    var normalized := normalize_outcome(outcome)
    if normalized.is_empty():
        return 0
    var actual := 0.5
    match normalized:
        "win": actual = 1.0
        "loss": actual = 0.0
    return roundi(K_FACTOR * (actual - expected_score(my_rating, opponent_rating)))

static func new_rating(my_rating: int, opponent_rating: int, outcome: String) -> int:
    return maxi(MIN_RATING, my_rating + rating_delta(my_rating, opponent_rating, outcome))

static func cup_delta(my_rating: int, opponent_rating: int, outcome: String) -> int:
    var normalized := normalize_outcome(outcome)
    if normalized.is_empty():
        return 0
    var gap := opponent_rating - my_rating
    if normalized == "win":
        if gap >= LARGE_GAP:
            return CUP_WIN_STRONGER
        if gap <= -LARGE_GAP:
            return CUP_WIN_WEAKER
        return CUP_WIN_SIMILAR
    if normalized == "draw":
        if gap >= LARGE_GAP:
            return CUP_DRAW_STRONGER
        if gap <= -LARGE_GAP:
            return CUP_DRAW_WEAKER
        return CUP_DRAW_SIMILAR
    if gap >= LARGE_GAP:
        return CUP_LOSS_STRONGER
    return CUP_LOSS_SIMILAR

static func cup_total_after(current_cups: int, delta: int) -> int:
    return maxi(0, current_cups + delta)

static func league_for_cups(cups: int) -> Dictionary:
    var selected: Dictionary = LEAGUES[0]
    for league in LEAGUES:
        if cups >= int(league["min_cups"]):
            selected = league
        else:
            break
    return selected.duplicate(true)

static func next_league(cups: int) -> Dictionary:
    var current := league_for_cups(cups)
    for league in LEAGUES:
        if int(league["min_cups"]) > int(current["min_cups"]):
            return league.duplicate(true)
    return {}

static func league_progress(cups: int) -> Dictionary:
    var current := league_for_cups(cups)
    var next := next_league(cups)
    if next.is_empty():
        return {"current": current, "next": {}, "progress": 1.0, "remaining": 0}
    var start := int(current["min_cups"])
    var end := int(next["min_cups"])
    var span := maxi(1, end - start)
    var progress := clampf(float(cups - start) / float(span), 0.0, 1.0)
    return {
        "current": current,
        "next": next,
        "progress": progress,
        "remaining": maxi(0, end - cups),
    }
