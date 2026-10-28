extends RefCounted
class_name NexusTeamRating

# Núcleo competitivo NEXUS-SOLO + NEXUS-TEAM.
# NEXUS-SOLO sirve para 1c1 y 2c2 con estados separados; NEXUS-TEAM
# añade el estado independiente de cada pareja. No toca reglas de partida.
const NEXUS_VERSION := 2
const DEFAULT_RATING := 1000
const MIN_RATING := 100
const MAX_RATING := 3000
const INITIAL_UNCERTAINTY := 320.0
const MIGRATED_UNCERTAINTY := 180.0
const MIN_UNCERTAINTY := 55.0
const MAX_UNCERTAINTY := 420.0
const PAIR_EFFECT_LIMIT := 120.0
const DEFAULT_VOLATILITY := 0.50
const MIN_VOLATILITY := 0.15
const MAX_VOLATILITY := 1.00
const PLAYER_K_MIN := 8.0
const PLAYER_K_MAX := 34.0
const PAIR_K_MIN := 8.0
const PAIR_K_MAX := 28.0
const FORM_DECAY := 0.90
const VOLATILITY_DECAY := 0.94
const UNCERTAINTY_LEARNING_BASE := 0.06
const UNCERTAINTY_LEARNING_CONFIDENT := 0.10
const FORM_INACTIVITY_HALF_LIFE_DAYS := 30.0
const PAIR_EFFECT_INACTIVITY_HALF_LIFE_DAYS := 45.0
const INACTIVITY_DAYS_FOR_FULL_DRIFT := 365.0

static func normalize_outcome(outcome: String) -> String:
    var value := outcome.strip_edges().to_lower()
    if value == "win" or value == "loss" or value == "draw":
        return value
    return ""

static func actual_score(outcome: String) -> float:
    match normalize_outcome(outcome):
        "win": return 1.0
        "loss": return 0.0
        "draw": return 0.5
        _: return -1.0

static func expected_score(my_rating: float, opponent_rating: float) -> float:
    var gap := clampf(opponent_rating - my_rating, -1200.0, 1200.0)
    return 1.0 / (1.0 + pow(10.0, gap / 400.0))

static func _uncertainty_factor(uncertainty: float) -> float:
    return clampf((uncertainty - MIN_UNCERTAINTY) / (INITIAL_UNCERTAINTY - MIN_UNCERTAINTY), 0.0, 1.35)

static func _volatility_factor(volatility: float) -> float:
    return clampf(0.65 + clampf(volatility, MIN_VOLATILITY, MAX_VOLATILITY) * 0.70, 0.75, 1.35)

static func player_k(uncertainty: float, volatility: float) -> float:
    # V2 conserva movimiento fuerte cuando existe poca evidencia, pero evita
    # que la incertidumbre se vuelva inútil demasiado pronto. La curva es
    # deliberadamente suave para no crear saltos artificiales.
    var u := clampf(_uncertainty_factor(uncertainty) / 1.35, 0.0, 1.0)
    var k := PLAYER_K_MIN + (PLAYER_K_MAX - PLAYER_K_MIN) * pow(u, 0.72) * _volatility_factor(volatility)
    return clampf(k, PLAYER_K_MIN, PLAYER_K_MAX)

static func pair_k(uncertainty: float) -> float:
    var u := _uncertainty_factor(uncertainty)
    return lerpf(PAIR_K_MIN, PAIR_K_MAX, clampf(u, 0.0, 1.0))

static func _form_bias(form: float, uncertainty: float) -> float:
    # La forma solo aporta contexto pequeño; nunca domina el rating.
    return clampf(form, -1.0, 1.0) * clampf(uncertainty, 60.0, 360.0) * 0.06

static func effective_rating(rating: float, form: float, uncertainty: float) -> float:
    return clampf(rating + _form_bias(form, uncertainty), MIN_RATING, MAX_RATING)

static func expected_with_state(rating: float, opponent_rating: float, form: float = 0.0, uncertainty: float = INITIAL_UNCERTAINTY) -> float:
    return expected_score(effective_rating(rating, form, uncertainty), opponent_rating)

static func rating_delta(rating: float, opponent_rating: float, outcome: String, uncertainty: float = INITIAL_UNCERTAINTY, volatility: float = DEFAULT_VOLATILITY) -> int:
    var expected := expected_score(rating, opponent_rating)
    var actual := actual_score(outcome)
    var delta := player_k(uncertainty, volatility) * (actual - expected)
    return roundi(delta)

static func apply_inactivity(state: Dictionary, now: int = 0) -> Dictionary:
    var out := state.duplicate(true)
    var last := int(out.get("last_activity_at", 0))
    if now <= 0 or last <= 0 or now <= last:
        return out
    var days := float(now - last) / 86400.0
    if days <= 1.0:
        return out
    var drift := MIN_UNCERTAINTY + (MAX_UNCERTAINTY - MIN_UNCERTAINTY) * clampf(days / INACTIVITY_DAYS_FOR_FULL_DRIFT, 0.0, 1.0)
    out["uncertainty"] = clampf(maxf(float(out.get("uncertainty", INITIAL_UNCERTAINTY)), drift), MIN_UNCERTAINTY, MAX_UNCERTAINTY)
    # La forma representa rendimiento reciente. La incertidumbre y la forma
    # reaccionan a ritmos distintos: el rating no se degrada por inactividad.
    var form := clampf(float(out.get("form", 0.0)), -1.0, 1.0)
    out["form"] = form * exp(-days * log(2.0) / FORM_INACTIVITY_HALF_LIFE_DAYS)
    return out

static func update_player(state: Dictionary, opponent_rating: float, outcome: String, now: int = 0) -> Dictionary:
    if normalize_outcome(outcome).is_empty():
        return state.duplicate(true)
    var current := apply_inactivity(state, now)
    var rating_before := clampf(float(current.get("rating", DEFAULT_RATING)), MIN_RATING, MAX_RATING)
    var uncertainty_before := clampf(float(current.get("uncertainty", INITIAL_UNCERTAINTY)), MIN_UNCERTAINTY, MAX_UNCERTAINTY)
    var volatility_before := clampf(float(current.get("volatility", DEFAULT_VOLATILITY)), MIN_VOLATILITY, MAX_VOLATILITY)
    var form_before := clampf(float(current.get("form", 0.0)), -1.0, 1.0)
    var expected := expected_with_state(rating_before, opponent_rating, form_before, uncertainty_before)
    var actual := actual_score(outcome)
    var surprise := actual - expected
    var delta := roundi(player_k(uncertainty_before, volatility_before) * surprise)
    var rating_after := clampf(rating_before + delta, MIN_RATING, MAX_RATING)
    var uncertainty_norm := clampf((uncertainty_before - MIN_UNCERTAINTY) / (INITIAL_UNCERTAINTY - MIN_UNCERTAINTY), 0.0, 1.0)
    var learning := UNCERTAINTY_LEARNING_BASE + UNCERTAINTY_LEARNING_CONFIDENT * (1.0 - uncertainty_norm)
    var uncertainty_after := MIN_UNCERTAINTY + (uncertainty_before - MIN_UNCERTAINTY) * (1.0 - learning)
    uncertainty_after = clampf(uncertainty_after + absf(surprise) * 5.5, MIN_UNCERTAINTY, MAX_UNCERTAINTY)
    var volatility_after := clampf(volatility_before * VOLATILITY_DECAY + absf(surprise) * 0.34, MIN_VOLATILITY, MAX_VOLATILITY)
    var form_after := clampf(form_before * FORM_DECAY + surprise * 0.78, -1.0, 1.0)

    current["rating"] = roundi(rating_after)
    current["best_rating"] = maxi(int(current.get("best_rating", DEFAULT_RATING)), int(current["rating"]))
    current["uncertainty"] = uncertainty_after
    current["volatility"] = volatility_after
    current["form"] = form_after
    current["confidence"] = clampf(1.0 - (uncertainty_after - MIN_UNCERTAINTY) / (MAX_UNCERTAINTY - MIN_UNCERTAINTY), 0.0, 1.0)
    current["nexus_version"] = NEXUS_VERSION
    if now > 0:
        current["last_activity_at"] = now
    current["last_expected"] = expected
    current["last_surprise"] = surprise
    current["last_delta"] = delta
    return current

static func make_new_pair(seed_strength: float = DEFAULT_RATING, now: int = 0) -> Dictionary:
    return {
        "rating": clampi(roundi(seed_strength), MIN_RATING, MAX_RATING),
        "best_rating": clampi(roundi(seed_strength), MIN_RATING, MAX_RATING),
        "pair_strength": clampi(roundi(seed_strength), MIN_RATING, MAX_RATING),
        "pair_uncertainty": INITIAL_UNCERTAINTY,
        "pair_effect": 0.0,
        "peak_strength": clampi(roundi(seed_strength), MIN_RATING, MAX_RATING),
        "games": 0,
        "wins": 0,
        "losses": 0,
        "draws": 0,
        "last_activity_at": now,
        "last_expected": 0.5,
        "last_surprise": 0.0,
        "last_delta": 0,
        "nexus_version": NEXUS_VERSION,
    }

static func apply_pair_inactivity(pair: Dictionary, now: int = 0) -> Dictionary:
    var out := pair.duplicate(true)
    var last := int(out.get("last_activity_at", 0))
    if now <= 0 or last <= 0 or now <= last:
        return out
    var days := float(now - last) / 86400.0
    if days <= 1.0:
        return out
    var drift := MIN_UNCERTAINTY + (MAX_UNCERTAINTY - MIN_UNCERTAINTY) * clampf(days / INACTIVITY_DAYS_FOR_FULL_DRIFT, 0.0, 1.0)
    out["pair_uncertainty"] = clampf(maxf(float(out.get("pair_uncertainty", INITIAL_UNCERTAINTY)), drift), MIN_UNCERTAINTY, MAX_UNCERTAINTY)
    # La sinergia de una pareja también es información temporal: una pareja
    # que deja de jugar no debe conservar para siempre un efecto aprendido.
    var pair_effect := clampf(float(out.get("pair_effect", 0.0)), -PAIR_EFFECT_LIMIT, PAIR_EFFECT_LIMIT)
    out["pair_effect"] = pair_effect * exp(-days * log(2.0) / PAIR_EFFECT_INACTIVITY_HALF_LIFE_DAYS)
    return out

static func update_pair(pair: Dictionary, opponent_pair_rating: float, outcome: String, team_seed_rating: float, now: int = 0) -> Dictionary:
    if normalize_outcome(outcome).is_empty():
        return pair.duplicate(true)
    var current := apply_pair_inactivity(pair, now)
    var rating_before := clampf(float(current.get("pair_strength", current.get("rating", DEFAULT_RATING))), MIN_RATING, MAX_RATING)
    var uncertainty_before := clampf(float(current.get("pair_uncertainty", INITIAL_UNCERTAINTY)), MIN_UNCERTAINTY, MAX_UNCERTAINTY)
    var pair_effect_before := clampf(float(current.get("pair_effect", 0.0)), -PAIR_EFFECT_LIMIT, PAIR_EFFECT_LIMIT)
    var actual := actual_score(outcome)
    var prediction_rating := clampf(rating_before + pair_effect_before, MIN_RATING, MAX_RATING)
    var expected := expected_score(prediction_rating, opponent_pair_rating)
    var surprise := actual - expected
    var delta := roundi(pair_k(uncertainty_before) * surprise)
    var rating_after := clampf(rating_before + delta, MIN_RATING, MAX_RATING)

    # El efecto de pareja mide el residuo sobre la expectativa individual base.
    # Es descriptivo y limitado; nunca se transfiere al ranking individual.
    var base_expected := expected_score(team_seed_rating, opponent_pair_rating)
    var synergy_signal := actual - base_expected
    var pair_effect_after := clampf(pair_effect_before + synergy_signal * 14.0 * clampf(uncertainty_before / INITIAL_UNCERTAINTY, 0.35, 1.0), -PAIR_EFFECT_LIMIT, PAIR_EFFECT_LIMIT)
    var uncertainty_norm := clampf((uncertainty_before - MIN_UNCERTAINTY) / (INITIAL_UNCERTAINTY - MIN_UNCERTAINTY), 0.0, 1.0)
    var learning := UNCERTAINTY_LEARNING_BASE + UNCERTAINTY_LEARNING_CONFIDENT * (1.0 - uncertainty_norm)
    var uncertainty_after := MIN_UNCERTAINTY + (uncertainty_before - MIN_UNCERTAINTY) * (1.0 - learning)
    uncertainty_after = clampf(uncertainty_after + absf(surprise) * 6.0, MIN_UNCERTAINTY, MAX_UNCERTAINTY)

    current["pair_strength"] = roundi(rating_after)
    current["rating"] = roundi(rating_after) # alias de compatibilidad con la UI existente
    current["best_rating"] = maxi(int(current.get("best_rating", DEFAULT_RATING)), int(current["rating"]))
    current["peak_strength"] = maxi(int(current.get("peak_strength", DEFAULT_RATING)), int(current["pair_strength"]))
    current["pair_uncertainty"] = uncertainty_after
    current["pair_effect"] = pair_effect_after
    current["nexus_version"] = NEXUS_VERSION
    current["last_expected"] = expected
    current["last_surprise"] = surprise
    current["last_delta"] = delta
    if now > 0:
        current["last_activity_at"] = now
    return current

static func validated_best_score(pair: Dictionary) -> float:
    var games := int(pair.get("games", 0))
    var strength := float(pair.get("peak_strength", pair.get("best_rating", pair.get("rating", DEFAULT_RATING))))
    var uncertainty := float(pair.get("pair_uncertainty", INITIAL_UNCERTAINTY))
    if games < 3:
        strength -= 40.0
    if games < 2:
        strength -= 60.0
    strength -= maxf(0.0, uncertainty - 100.0) * 0.05
    return strength

static func seed_pair_strength(player_rating: float, partner_rating: float = DEFAULT_RATING) -> float:
    # Prior estadístico: no copia el rating de uno de los jugadores; usa la media
    # como punto de partida y mantiene incertidumbre propia alta.
    return clampf((player_rating + partner_rating) * 0.5, MIN_RATING, MAX_RATING)
