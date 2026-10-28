extends RefCounted
class_name CompetitiveMatchContext

const VERSION := 1
const MIN_RATING := 100
const MAX_RATING := 3000

static func _rating(value: Variant, fallback: int = 1000) -> int:
    var parsed := int(value)
    if parsed <= 0:
        parsed = fallback
    return clampi(parsed, MIN_RATING, MAX_RATING)

static func snapshot(local_rating: int, local_uncertainty: float, mode: int) -> Dictionary:
    return {
        "version": VERSION,
        "mode": mode,
        "local_rating": _rating(local_rating),
        "local_uncertainty": clampf(local_uncertainty, 55.0, 420.0),
        "source": "local_matchmaking",
    }

static func with_opponents(context: Dictionary, opponent_rating: int = 0, opponent_pair_rating: int = 0, partner_rating: int = 0, opponent_ratings: Array = [], opponent_ids: Array = [], opponent_pair_uncertainty: float = 320.0) -> Dictionary:
    var out := context.duplicate(true)
    if opponent_rating > 0:
        out["opponent_rating"] = _rating(opponent_rating)
    if opponent_pair_rating > 0:
        out["opponent_pair_rating"] = _rating(opponent_pair_rating)
    if partner_rating > 0:
        out["partner_rating"] = _rating(partner_rating)
    out["opponent_ratings"] = opponent_ratings.duplicate()
    out["opponent_ids"] = opponent_ids.duplicate()
    out["opponent_pair_uncertainty"] = clampf(opponent_pair_uncertainty, 55.0, 420.0)
    out["source"] = "resolved_match"
    return out

static func individual_opponent_rating(context: Dictionary, fallback: int = 1000) -> int:
    if context.has("opponent_rating"):
        return _rating(context.get("opponent_rating"), fallback)
    var values: Array = context.get("opponent_ratings", [])
    var sum := 0
    var count := 0
    for value in values:
        var rating := int(value)
        if rating > 0:
            sum += rating
            count += 1
    return _rating(roundi(float(sum) / float(count)) if count > 0 else fallback, fallback)

static func pair_opponent_rating(context: Dictionary, fallback: int = 1000) -> int:
    if context.has("opponent_pair_rating"):
        return _rating(context.get("opponent_pair_rating"), fallback)
    # No inferimos una fuerza de pareja promediando ratings individuales:
    # son estados competitivos distintos. El backend/partida debe entregar
    # un snapshot explícito cuando exista una pareja rival real.
    return _rating(fallback, fallback)

static func partner_rating(context: Dictionary, fallback: int = 1000) -> int:
    return _rating(context.get("partner_rating", fallback), fallback)
