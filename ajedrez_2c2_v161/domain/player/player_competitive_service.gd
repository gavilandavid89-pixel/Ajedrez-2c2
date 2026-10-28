extends RefCounted
class_name PlayerCompetitiveService

const Competitive = preload("res://domain/competitive/competitive_system.gd")
const NexusTeam = preload("res://domain/competitive/nexus_team.gd")
const MatchContext = preload("res://domain/competitive/match_context.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var DEFAULT_NAME: String:
    get: return String(host.DEFAULT_NAME)

var profile: Variant:
    get: return host.profile
var individual: Variant:
    get: return host.individual
    set(value): host.individual = value
var individual_1c1: Variant:
    get: return host.individual_1c1
    set(value): host.individual_1c1 = value
var pair_records: Variant:
    get: return host.pair_records
    set(value): host.pair_records = value
var current_partner: Variant:
    get: return host.current_partner
    set(value): host.current_partner = value
var current_pair_id: String:
    get: return String(host.current_pair_id)
    set(value): host.current_pair_id = value
var best_pair_id: String:
    get: return String(host.best_pair_id)
    set(value): host.best_pair_id = value
var history: Variant:
    get: return host.history
    set(value): host.history = value
var season: Variant:
    get: return host.season

func _normalize_individual_stats(stats: Dictionary) -> void:
    host._normalize_individual_stats(stats)

func _normalize_1c1_stats() -> void:
    host._normalize_1c1_stats()

func _trim_history() -> void:
    host._trim_history()

func _generate_match_id() -> String:
    return host._generate_match_id()

func save_data() -> void:
    host.save_data()

func _normalize_nexus_state() -> void:
    # Migración suave de cuentas existentes: conservamos rating/copas y damos
    # una incertidumbre intermedia para que NEXUS aprenda sin sobresaltos.
    var migrated: bool = not individual.has("nexus_version")
    individual["rating"] = maxi(NexusTeam.MIN_RATING, int(individual.get("rating", NexusTeam.DEFAULT_RATING)))
    individual["best_rating"] = maxi(int(individual["rating"]), int(individual.get("best_rating", individual["rating"])))
    individual["uncertainty"] = clampf(float(individual.get("uncertainty", NexusTeam.MIGRATED_UNCERTAINTY if migrated else NexusTeam.INITIAL_UNCERTAINTY)), NexusTeam.MIN_UNCERTAINTY, NexusTeam.MAX_UNCERTAINTY)
    individual["volatility"] = clampf(float(individual.get("volatility", NexusTeam.DEFAULT_VOLATILITY)), NexusTeam.MIN_VOLATILITY, NexusTeam.MAX_VOLATILITY)
    individual["form"] = clampf(float(individual.get("form", 0.0)), -1.0, 1.0)
    var last_activity := int(individual.get("last_activity_at", 0))
    if last_activity <= 0:
        last_activity = _last_2c2_timestamp()
    individual["last_activity_at"] = last_activity
    individual["confidence"] = clampf(1.0 - (float(individual["uncertainty"]) - NexusTeam.MIN_UNCERTAINTY) / (NexusTeam.MAX_UNCERTAINTY - NexusTeam.MIN_UNCERTAINTY), 0.0, 1.0)
    individual["nexus_version"] = NexusTeam.NEXUS_VERSION
    if current_pair_id.is_empty() and not String(current_partner.get("pair_key", "")).is_empty():
        current_pair_id = String(current_partner.get("pair_key", ""))
    _refresh_best_pair_id()

func _last_2c2_timestamp() -> int:
    for i in range(history.size() - 1, -1, -1):
        var item: Variant = history[i]
        if item is Dictionary and int(item.get("mode", -1)) == 0:
            return int(item.get("timestamp", 0))
    return 0

func _last_1c1_timestamp() -> int:
    for i in range(history.size() - 1, -1, -1):
        var item: Variant = history[i]
        if item is Dictionary and int(item.get("mode", -1)) == 1:
            return int(item.get("timestamp", 0))
    return 0

func _last_pair_2c2_timestamp(pair_key_value: String, partner_name: String = "") -> int:
    var target_key := pair_key_value.strip_edges()
    var target_partner := partner_name.strip_edges().to_lower()
    for i in range(history.size() - 1, -1, -1):
        var item: Variant = history[i]
        if not item is Dictionary or int(item.get("mode", -1)) != 0:
            continue
        if not target_key.is_empty() and String(item.get("pair_key", "")) == target_key:
            return int(item.get("timestamp", 0))
        if target_key.is_empty() and not target_partner.is_empty() and String(item.get("partner", "")).strip_edges().to_lower() == target_partner:
            return int(item.get("timestamp", 0))
    return 0

func _refresh_best_pair_id() -> void:
    var best_key := ""
    var best_score := -1.0e30
    for key in pair_records.keys():
        var pair: Variant = pair_records[key]
        if not pair is Dictionary:
            continue
        var score := NexusTeam.validated_best_score(pair)
        if int(pair.get("games", 0)) >= 3 and score > best_score:
            best_score = score
            best_key = String(key)
    # No declaramos una "mejor pareja" oficial hasta tener evidencia mínima.
    # La pareja actual sí existe desde la primera partida; la mejor requiere 3+.
    best_pair_id = best_key

func _normalize_pairs() -> void:
    var now := int(Time.get_unix_time_from_system())
    for key in pair_records.keys():
        if not (pair_records[key] is Dictionary):
            pair_records.erase(key)
            continue
        var pair: Dictionary = pair_records[key]
        pair["partner_id"] = String(pair.get("partner_id", ""))
        pair["partner_name"] = String(pair.get("partner_name", ""))
        var existing_display := String(pair.get("display_name", ""))
        if existing_display.is_empty() or existing_display.begins_with("pair:"):
            existing_display = _pair_display_name(String(pair.get("partner_name", "")))
        pair["display_name"] = existing_display if not existing_display.is_empty() else String(key)
        pair["rating"] = maxi(NexusTeam.MIN_RATING, int(pair.get("pair_strength", pair.get("rating", NexusTeam.DEFAULT_RATING))))
        pair["pair_strength"] = int(pair["rating"])
        pair["best_rating"] = maxi(int(pair.get("rating", NexusTeam.DEFAULT_RATING)), int(pair.get("best_rating", pair.get("rating", NexusTeam.DEFAULT_RATING))))
        pair["peak_strength"] = maxi(int(pair.get("best_rating", NexusTeam.DEFAULT_RATING)), int(pair.get("peak_strength", pair.get("rating", NexusTeam.DEFAULT_RATING))))
        pair["pair_uncertainty"] = clampf(float(pair.get("pair_uncertainty", NexusTeam.MIGRATED_UNCERTAINTY)), NexusTeam.MIN_UNCERTAINTY, NexusTeam.MAX_UNCERTAINTY)
        pair["pair_effect"] = clampf(float(pair.get("pair_effect", 0.0)), -NexusTeam.PAIR_EFFECT_LIMIT, NexusTeam.PAIR_EFFECT_LIMIT)
        pair["cups"] = maxi(0, int(pair.get("cups", 0)))
        pair["lifetime_cups"] = maxi(int(pair.get("cups", 0)), int(pair.get("lifetime_cups", pair.get("cups", 0))))
        pair["games"] = maxi(0, int(pair.get("games", 0)))
        pair["wins"] = maxi(0, int(pair.get("wins", 0)))
        pair["losses"] = maxi(0, int(pair.get("losses", 0)))
        pair["draws"] = maxi(0, int(pair.get("draws", 0)))
        pair["streak"] = int(pair.get("streak", 0))
        var pair_last_activity := int(pair.get("last_activity_at", 0))
        if pair_last_activity <= 0:
            pair_last_activity = _last_pair_2c2_timestamp(String(key), String(pair.get("partner_name", "")))
        if pair_last_activity <= 0 and int(pair.get("games", 0)) == 0:
            pair_last_activity = now
        pair["last_activity_at"] = pair_last_activity
        pair["nexus_version"] = NexusTeam.NEXUS_VERSION
        pair_records[key] = pair

func pair_key(partner_name: String, partner_id: String = "") -> String:
    var my_id := String(profile.get("id", ""))
    var other_id := partner_id.strip_edges()
    if not my_id.is_empty() and not other_id.is_empty():
        var ids := [my_id, other_id]
        ids.sort()
        return "pair:%s:%s" % [ids[0], ids[1]]
    # Legacy/local fallback: readable key for records created before IDs existed.
    var names := [String(profile.get("name", DEFAULT_NAME)), partner_name.strip_edges()]
    names.sort()
    return "%s & %s" % [names[0], names[1]]

func ensure_pair_record(key: String, partner_name: String = "", partner_id: String = "", partner_rating: int = NexusTeam.DEFAULT_RATING) -> Dictionary:
    if not pair_records.has(key) or not (pair_records[key] is Dictionary):
        var seed := NexusTeam.seed_pair_strength(int(individual.get("rating", NexusTeam.DEFAULT_RATING)), partner_rating)
        var created := NexusTeam.make_new_pair(seed, int(Time.get_unix_time_from_system()))
        created["partner_id"] = partner_id.strip_edges()
        created["partner_name"] = partner_name.strip_edges()
        created["display_name"] = _pair_display_name(partner_name)
        created["cups"] = 0
        created["lifetime_cups"] = 0
        created["streak"] = 0
        created["season_id"] = int(season.get("id", 1))
        created["nexus_version"] = NexusTeam.NEXUS_VERSION
        pair_records[key] = created
    return pair_records[key]

func _pair_display_name(partner_name: String) -> String:
    var mine := String(profile.get("name", DEFAULT_NAME)).strip_edges()
    var other := partner_name.strip_edges()
    if other.is_empty():
        return mine
    var names := [mine, other]
    names.sort()
    return "%s & %s" % [names[0], names[1]]

func record_result(mode: int, outcome: String, partner_name: String = "", opponent_rating: int = Competitive.DEFAULT_RATING, opponent_pair_rating: int = Competitive.DEFAULT_RATING, partner_id: String = "", match_detail: Dictionary = {}) -> Dictionary:
    var normalized := Competitive.normalize_outcome(outcome)
    # No transformar silenciosamente un resultado desconocido en tablas: un
    # dato corrupto debe rechazarse antes de tocar ratings, copas o historiales.
    if normalized.is_empty():
        return {"ok": false, "error": "Resultado competitivo inválido; se requiere win, loss o draw.", "outcome": outcome}
    # Stable caller-supplied IDs make result processing idempotent across repeated
    # finish signals/retries. Check before mutating any rating, cup or pair state.
    var requested_match_id := String(match_detail.get("match_id", "")).strip_edges()
    if not requested_match_id.is_empty():
        for previous in history:
            if previous is Dictionary and String(previous.get("match_id", "")) == requested_match_id:
                var duplicate_entry: Dictionary = previous.duplicate(true)
                duplicate_entry["duplicate"] = true
                duplicate_entry["ok"] = true
                return duplicate_entry
    var is_2c2 := mode == 0
    var stats: Dictionary = individual if is_2c2 else individual_1c1
    _normalize_individual_stats(stats)
    var player_rating_before := int(stats.get("rating", Competitive.DEFAULT_RATING))
    var player_cups_before := int(stats.get("cups", 0))
    var player_rating_delta := 0
    var player_cup_delta := 0
    var player_expected := 0.5
    var player_surprise := 0.0
    var player_uncertainty_before := float(stats.get("uncertainty", NexusTeam.MIGRATED_UNCERTAINTY))
    var player_uncertainty_after := player_uncertainty_before

    var pair_key_value := ""
    var pair_rating_delta := 0
    var pair_cup_delta := 0
    var pair_rating_after := 0
    var pair_cups_after := 0
    var pair_expected := 0.5
    var pair_uncertainty_before := 0.0
    var pair_uncertainty_after := 0.0
    var pair_effect := 0.0
    var pair_effect_before := 0.0
    var pair_rating_before := 0
    var entry_opponent_rating := opponent_rating
    var entry_opponent_pair_rating := opponent_pair_rating
    var entry_partner_rating := 0

    if is_2c2:
        _normalize_nexus_state()
        var now := int(Time.get_unix_time_from_system())
        var effective_detail := match_detail.duplicate(true)
        var context_variant: Variant = effective_detail.get("competitive_match_context", {})
        var context: Dictionary = context_variant if context_variant is Dictionary else {}
        var partner_rating := MatchContext.partner_rating(context, int(effective_detail.get("partner_rating_before", NexusTeam.DEFAULT_RATING)))
        var effective_opponent_rating := MatchContext.individual_opponent_rating(context, int(effective_detail.get("opponent_rating_before", opponent_rating)))
        var effective_opponent_pair_rating := MatchContext.pair_opponent_rating(context, int(effective_detail.get("opponent_pair_rating", opponent_pair_rating)))
        entry_opponent_rating = effective_opponent_rating
        entry_opponent_pair_rating = effective_opponent_pair_rating
        entry_partner_rating = partner_rating

        if not partner_name.strip_edges().is_empty():
            pair_key_value = pair_key(partner_name, partner_id)
            var pair := ensure_pair_record(pair_key_value, partner_name, partner_id, partner_rating)
            pair_uncertainty_before = float(pair.get("pair_uncertainty", NexusTeam.INITIAL_UNCERTAINTY))
            var team_seed := NexusTeam.seed_pair_strength(int(stats.get("rating", NexusTeam.DEFAULT_RATING)), partner_rating)
            var pair_before_rating := int(pair.get("pair_strength", pair.get("rating", team_seed)))
            pair_rating_before = pair_before_rating
            pair_effect_before = float(pair.get("pair_effect", 0.0))
            pair_expected = NexusTeam.expected_score(float(pair_before_rating) + pair_effect_before, effective_opponent_pair_rating)
            var updated_pair := NexusTeam.update_pair(pair, effective_opponent_pair_rating, normalized, team_seed, now)
            pair_rating_delta = int(updated_pair.get("last_delta", 0))
            pair_rating_after = int(updated_pair.get("pair_strength", updated_pair.get("rating", NexusTeam.DEFAULT_RATING)))
            pair_cup_delta = Competitive.cup_delta(pair_before_rating, effective_opponent_pair_rating, normalized)
            updated_pair["games"] = int(updated_pair.get("games", 0)) + 1
            match normalized:
                "win":
                    updated_pair["wins"] = int(updated_pair.get("wins", 0)) + 1
                    updated_pair["streak"] = int(updated_pair.get("streak", 0)) + 1
                "loss":
                    updated_pair["losses"] = int(updated_pair.get("losses", 0)) + 1
                    updated_pair["streak"] = 0
                "draw":
                    updated_pair["draws"] = int(updated_pair.get("draws", 0)) + 1
                    updated_pair["streak"] = 0
            updated_pair["cups"] = Competitive.cup_total_after(int(updated_pair.get("cups", 0)), pair_cup_delta)
            if pair_cup_delta > 0:
                updated_pair["lifetime_cups"] = int(updated_pair.get("lifetime_cups", 0)) + pair_cup_delta
            updated_pair["season_id"] = int(season.get("id", 1))
            pair_records[pair_key_value] = updated_pair
            pair_cups_after = int(updated_pair.get("cups", 0))
            pair_uncertainty_after = float(updated_pair.get("pair_uncertainty", pair_uncertainty_before))
            pair_effect = float(updated_pair.get("pair_effect", 0.0))
            current_partner = {"id": String(updated_pair.get("partner_id", partner_id)), "name": String(updated_pair.get("partner_name", partner_name)), "pair_key": pair_key_value}
            current_pair_id = pair_key_value
        else:
            # Sin pareja identificable: el jugador sigue actualizando su estado individual,
            # pero no inventamos un PairState anónimo ni contaminamos el ranking de parejas.
            pair_key_value = ""

        var updated_player := NexusTeam.update_player(individual, float(effective_opponent_rating), normalized, now)
        player_rating_delta = int(updated_player.get("last_delta", 0))
        player_expected = float(updated_player.get("last_expected", 0.5))
        player_surprise = float(updated_player.get("last_surprise", 0.0))
        player_uncertainty_after = float(updated_player.get("uncertainty", player_uncertainty_before))
        individual = updated_player
        player_cup_delta = Competitive.cup_delta(player_rating_before, int(effective_opponent_rating), normalized)
        individual["games"] = int(individual.get("games", 0)) + 1
        match normalized:
            "win": individual["wins"] = int(individual.get("wins", 0)) + 1
            "loss": individual["losses"] = int(individual.get("losses", 0)) + 1
            "draw": individual["draws"] = int(individual.get("draws", 0)) + 1
        individual["cups"] = Competitive.cup_total_after(player_cups_before, player_cup_delta)
        if player_cup_delta > 0:
            individual["lifetime_cups"] = int(individual.get("lifetime_cups", 0)) + player_cup_delta
        individual["best_rating"] = maxi(int(individual.get("best_rating", player_rating_before)), int(individual.get("rating", player_rating_before)))
        if pair_key_value != "":
            _refresh_best_pair_id()
    else:
        # 1c1 usa el mismo núcleo NEXUS-SOLO, pero conserva estado, copas e historial completamente independientes de 2c2.
        var effective_detail_1c1 := match_detail.duplicate(true)
        var context_variant_1c1: Variant = effective_detail_1c1.get("competitive_match_context", {})
        var context_1c1: Dictionary = context_variant_1c1 if context_variant_1c1 is Dictionary else {}
        var player_opp_rating := MatchContext.individual_opponent_rating(context_1c1, maxi(Competitive.MIN_RATING, opponent_rating))
        entry_opponent_rating = player_opp_rating
        _normalize_1c1_stats()
        player_uncertainty_before = float(stats.get("uncertainty", NexusTeam.MIGRATED_UNCERTAINTY))
        var updated_1c1 := NexusTeam.update_player(stats, player_opp_rating, normalized, int(Time.get_unix_time_from_system()))
        player_rating_delta = int(updated_1c1.get("last_delta", 0))
        player_expected = float(updated_1c1.get("last_expected", 0.5))
        player_surprise = float(updated_1c1.get("last_surprise", 0.0))
        stats = updated_1c1
        player_uncertainty_after = float(updated_1c1.get("uncertainty", player_uncertainty_before))
        player_cup_delta = Competitive.cup_delta(player_rating_before, player_opp_rating, normalized)
        match normalized:
            "win": stats["streak"] = int(stats.get("streak", 0)) + 1
            "loss", "draw": stats["streak"] = 0
        stats["games"] = int(stats.get("games", 0)) + 1
        match normalized:
            "win": stats["wins"] = int(stats.get("wins", 0)) + 1
            "loss": stats["losses"] = int(stats.get("losses", 0)) + 1
            "draw": stats["draws"] = int(stats.get("draws", 0)) + 1
        stats["rating"] = maxi(Competitive.MIN_RATING, player_rating_before + player_rating_delta)
        stats["best_rating"] = maxi(int(stats.get("best_rating", Competitive.DEFAULT_RATING)), int(stats["rating"]))
        stats["cups"] = Competitive.cup_total_after(player_cups_before, player_cup_delta)
        if player_cup_delta > 0:
            stats["lifetime_cups"] = int(stats.get("lifetime_cups", 0)) + player_cup_delta
        individual_1c1 = stats

    var entry: Dictionary = {
        "match_id": requested_match_id if not requested_match_id.is_empty() else _generate_match_id(),
        "timestamp": Time.get_unix_time_from_system(),
        "season_id": int(season.get("id", 1)),
        "season_name": String(season.get("name", "Temporada 1")),
        "mode": mode,
        "outcome": normalized,
        "partner": partner_name,
        "cup_delta": player_cup_delta,
        "cups_after": int((individual if is_2c2 else individual_1c1).get("cups", 0)),
        "rating_delta": player_rating_delta,
        "rating_after": int((individual if is_2c2 else individual_1c1).get("rating", 0)),
        "opponent_rating_before": entry_opponent_rating,
        "opponent_pair_rating_before": entry_opponent_pair_rating,
        "partner_rating_before": entry_partner_rating,
        "pair_key": pair_key_value,
        "pair_cup_delta": pair_cup_delta,
        "pair_cups_after": pair_cups_after,
        "pair_rating_delta": pair_rating_delta,
        "pair_rating_after": pair_rating_after,
        "competitive": true,
        "analysis_viewed": false,
    }
    if is_2c2:
        entry["nexus_version"] = NexusTeam.NEXUS_VERSION
        entry["rating_before"] = player_rating_before
        entry["expected"] = player_expected
        entry["surprise"] = player_surprise
        entry["uncertainty_before"] = player_uncertainty_before
        entry["uncertainty_after"] = player_uncertainty_after
        entry["pair_expected"] = pair_expected
        entry["pair_rating_before"] = pair_rating_before
        entry["pair_effect_before"] = pair_effect_before
        entry["pair_uncertainty_before"] = pair_uncertainty_before
        entry["pair_uncertainty_after"] = pair_uncertainty_after
        entry["pair_effect"] = pair_effect
        entry["best_pair_id"] = best_pair_id
    else:
        var league_1c1 := Competitive.league_for_cups(int(stats["cups"]))
        entry["nexus_version"] = NexusTeam.NEXUS_VERSION
        entry["expected"] = player_expected
        entry["surprise"] = player_surprise
        entry["uncertainty_before"] = player_uncertainty_before
        entry["uncertainty_after"] = player_uncertainty_after
        entry["streak_after"] = int(stats.get("streak", 0))
        entry["league_after"] = String(league_1c1.get("name", "Bronce"))
        entry["cups_before"] = player_cups_before
        entry["rating_before"] = player_rating_before
    for key in match_detail.keys():
        entry[String(key)] = match_detail[key]
    history.append(entry)
    _trim_history()
    save_data()
    host.data_changed.emit()
    return history[-1]
