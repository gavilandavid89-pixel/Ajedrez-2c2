extends RefCounted
class_name MatchmakingLogic

const BASE_RANGE := 100
const RANGE_STEP := 50
const RANGE_STEP_SECONDS := 2.0
const MAX_RANGE := 400

static func search_range(elapsed: float) -> int:
    var steps := maxi(0, int(floor(elapsed / RANGE_STEP_SECONDS)))
    return mini(MAX_RANGE, BASE_RANGE + steps * RANGE_STEP)

static func compatible(my_rating: int, candidate_rating: int, elapsed: float) -> bool:
    return absi(candidate_rating - my_rating) <= search_range(elapsed)

static func search_label(my_rating: int, elapsed: float, mode_name: String) -> String:
    return "%s · rating %d · rango ±%d" % [mode_name, my_rating, search_range(elapsed)]
