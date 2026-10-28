extends RefCounted
class_name PlayerRankingService

const Competitive = preload("res://domain/competitive/competitive_system.gd")
const NexusTeam = preload("res://domain/competitive/nexus_team.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

func pair_key(partner_name: String, partner_id: String = "") -> String:
    return host.pair_key(partner_name, partner_id)

func ensure_pair_record(key: String, partner_name: String = "", partner_id: String = "", partner_rating: int = NexusTeam.DEFAULT_RATING) -> Dictionary:
    return host.ensure_pair_record(key, partner_name, partner_id, partner_rating)

var DEFAULT_NAME: String:
    get: return String(host.DEFAULT_NAME)
var DEFAULT_AVATAR: String:
    get: return String(host.DEFAULT_AVATAR)
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
var current_pair_id: String:
    get: return String(host.current_pair_id)
var best_pair_id: String:
    get: return String(host.best_pair_id)
var season: Variant:
    get: return host.season

func save_data() -> void:
    host.save_data()

func _emit_changed() -> void:
    host._emit_changed()

func current_league() -> Dictionary:
    return Competitive.league_for_cups(int(individual.get("cups", 0)))

func current_league_1c1() -> Dictionary:
    return Competitive.league_for_cups(int(individual_1c1.get("cups", 0)))

func league_progress() -> Dictionary:
    return Competitive.league_progress(int(individual.get("cups", 0)))

func league_progress_1c1() -> Dictionary:
    return Competitive.league_progress(int(individual_1c1.get("cups", 0)))

func pair_league(partner_name: String, partner_id: String = "") -> Dictionary:
    var key := pair_key(partner_name, partner_id)
    var pair := ensure_pair_record(key)
    return Competitive.league_for_cups(int(pair.get("cups", 0)))

func reset_current_season(new_name: String = "") -> void:
    # Preparado para una futura administración de temporadas.
    # No está expuesto en la UI mientras no exista servidor/autorización.
    season["id"] = int(season.get("id", 1)) + 1
    season["name"] = new_name.strip_edges() if not new_name.strip_edges().is_empty() else "Temporada %d" % int(season["id"])
    season["started_at"] = Time.get_unix_time_from_system()
    individual["cups"] = 0
    individual_1c1["cups"] = 0
    for key in pair_records.keys():
        var pair: Dictionary = pair_records[key]
        pair["cups"] = 0
        pair["season_id"] = int(season["id"])
        pair_records[key] = pair
    save_data()
    _emit_changed()

func cup_status_text() -> String:
    var progress := league_progress()
    var next_name := "máxima" if progress["next"].is_empty() else String(progress["next"].get("name", ""))
    if next_name == "máxima":
        return "%s · %d copas · %s" % [String(season.get("name", "Temporada 1")), int(individual.get("cups", 0)), String(progress["current"].get("name", "Bronce"))]
    return "%s · %d copas · %s · faltan %d para %s" % [String(season.get("name", "Temporada 1")), int(individual.get("cups", 0)), String(progress["current"].get("name", "Bronce")), int(progress["remaining"]), next_name]

func _individual_rank_rows_for(stats: Dictionary, cup_sort: bool = false) -> Array[Dictionary]:
    var rows: Array[Dictionary] = [
        {"id": String(profile.get("id", "")), "name": String(profile.get("name", DEFAULT_NAME)), "avatar": String(profile.get("avatar", DEFAULT_AVATAR)), "rating": int(stats.get("rating", Competitive.DEFAULT_RATING)), "cups": int(stats.get("cups", 0)), "me": true},
        {"id": "USR_DEMOA0011223344", "name": "Jugador A", "avatar": "res://assets/avatars/avatar_local1.svg", "rating": 1120, "cups": 640, "me": false},
        {"id": "USR_DEMOB0011223344", "name": "Jugador B", "avatar": "res://assets/avatars/avatar_rival1.svg", "rating": 1085, "cups": 515, "me": false},
        {"id": "USR_DEMOC0011223344", "name": "Jugador C", "avatar": "res://assets/avatars/avatar_mate.svg", "rating": 1040, "cups": 390, "me": false},
        {"id": "USR_DEMOD0011223344", "name": "Jugador D", "avatar": "res://assets/avatars/avatar_rival2.svg", "rating": 995, "cups": 180, "me": false},
    ]
    rows.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["cups"] if cup_sort else a["rating"]) > int(b["cups"] if cup_sort else b["rating"]))
    return rows

func individual_rank_rows() -> Array[Dictionary]:
    return _individual_rank_rows_for(individual, false)

func individual_cup_rank_rows() -> Array[Dictionary]:
    return _individual_rank_rows_for(individual, true)

func individual_1c1_rank_rows() -> Array[Dictionary]:
    return _individual_rank_rows_for(individual_1c1, false)

func individual_1c1_cup_rank_rows() -> Array[Dictionary]:
    return _individual_rank_rows_for(individual_1c1, true)

func pair_rank_rows() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for key in pair_records.keys():
        var item: Dictionary = pair_records[key]
        rows.append({
            "id": "PAIR:%s" % String(key),
            "name": String(item.get("display_name", key)),
            "avatar1": String(profile.get("avatar", DEFAULT_AVATAR)),
            "avatar2": "res://assets/avatars/avatar_mate.svg",
            "rating": int(item.get("pair_strength", item.get("rating", NexusTeam.DEFAULT_RATING))),
            "cups": int(item.get("cups", 0)),
            "uncertainty": float(item.get("pair_uncertainty", NexusTeam.INITIAL_UNCERTAINTY)),
            "games": int(item.get("games", 0)),
            "is_current": String(key) == current_pair_id,
            "is_best": String(key) == best_pair_id,
            "me": true
        })
    # Filas demo solo representan a otros usuarios; nunca se mezclan con nuestros estados.
    rows.append({"id": "PAIR:DEMO_A_B", "name": "Jugador A & Jugador B", "avatar1": "res://assets/avatars/avatar_local1.svg", "avatar2": "res://assets/avatars/avatar_local2.svg", "rating": 1180, "cups": 860, "uncertainty": 90.0, "games": 84, "is_current": false, "is_best": false, "me": false})
    rows.append({"id": "PAIR:DEMO_C_D", "name": "Jugador C & Jugador D", "avatar1": "res://assets/avatars/avatar_rival1.svg", "avatar2": "res://assets/avatars/avatar_rival2.svg", "rating": 1120, "cups": 620, "uncertainty": 115.0, "games": 57, "is_current": false, "is_best": false, "me": false})
    rows.append({"id": "PAIR:DEMO_M_R", "name": "Compañero & Rival", "avatar1": "res://assets/avatars/avatar_mate.svg", "avatar2": "res://assets/avatars/avatar_rival1.svg", "rating": 1060, "cups": 410, "uncertainty": 140.0, "games": 42, "is_current": false, "is_best": false, "me": false})
    rows.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["rating"]) > int(b["rating"]))
    return rows

func pair_cup_rank_rows() -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    for key in pair_records.keys():
        var item: Dictionary = pair_records[key]
        rows.append({
            "id": "PAIR:%s" % String(key),
            "name": String(item.get("display_name", key)),
            "avatar1": String(profile.get("avatar", DEFAULT_AVATAR)),
            "avatar2": "res://assets/avatars/avatar_mate.svg",
            "rating": int(item.get("pair_strength", item.get("rating", NexusTeam.DEFAULT_RATING))),
            "cups": int(item.get("cups", 0)),
            "uncertainty": float(item.get("pair_uncertainty", NexusTeam.INITIAL_UNCERTAINTY)),
            "games": int(item.get("games", 0)),
            "is_current": String(key) == current_pair_id,
            "is_best": String(key) == best_pair_id,
            "me": true
        })
    rows.append({"id": "PAIR:DEMO_A_B", "name": "Jugador A & Jugador B", "avatar1": "res://assets/avatars/avatar_local1.svg", "avatar2": "res://assets/avatars/avatar_local2.svg", "rating": 1180, "cups": 860, "uncertainty": 90.0, "games": 84, "is_current": false, "is_best": false, "me": false})
    rows.append({"id": "PAIR:DEMO_C_D", "name": "Jugador C & Jugador D", "avatar1": "res://assets/avatars/avatar_rival1.svg", "avatar2": "res://assets/avatars/avatar_rival2.svg", "rating": 1120, "cups": 620, "uncertainty": 115.0, "games": 57, "is_current": false, "is_best": false, "me": false})
    rows.append({"id": "PAIR:DEMO_M_R", "name": "Compañero & Rival", "avatar1": "res://assets/avatars/avatar_mate.svg", "avatar2": "res://assets/avatars/avatar_rival1.svg", "rating": 1060, "cups": 410, "uncertainty": 140.0, "games": 42, "is_current": false, "is_best": false, "me": false})
    rows.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["cups"]) > int(b["cups"]))
    return rows
