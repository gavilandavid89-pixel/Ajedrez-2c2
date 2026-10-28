extends Node

signal data_changed

const Competitive = preload("res://domain/competitive/competitive_system.gd")
const NexusTeam = preload("res://domain/competitive/nexus_team.gd")
const SAVE_PATH := "user://ajedrez_2c2_profile.json"
const DEFAULT_NAME := "Tú"
const DEFAULT_AVATAR := "res://assets/avatars/avatar_you.svg"
const MAX_DISPLAY_NAME_LENGTH := 10
const USER_ID_PREFIX := "USR_"
const USER_ID_HEX_LENGTH := 16
const MAX_EQUIPPED_EMOTES := 6
const EmoteDataScript = preload("res://domain/player/emote_data.gd")
const PlayerCustomizationServiceScript = preload("res://domain/player/player_customization_service.gd")
const PlayerPersistenceServiceScript = preload("res://domain/player/player_persistence_service.gd")
const PlayerCompetitiveServiceScript = preload("res://domain/player/player_competitive_service.gd")
const PlayerHistoryServiceScript = preload("res://domain/player/player_history_service.gd")
const PlayerRankingServiceScript = preload("res://domain/player/player_ranking_service.gd")
const StorageManagerScript = preload("res://core/services/storage_manager.gd")

var customization_service: RefCounted
var _standalone_storage: Node = null

var profile: Dictionary = {
    "id": "",
    "name": DEFAULT_NAME,
    "avatar": DEFAULT_AVATAR,
    "auth_provider": "local",
}

var individual: Dictionary = {
    # Competitivo 2c2. NEXUS-TEAM vive aquí y nunca se mezcla con 1c1.
    "cups": 0,
    "lifetime_cups": 0,
    "games": 0,
    "wins": 0,
    "losses": 0,
    "draws": 0,
    "rating": NexusTeam.DEFAULT_RATING,
    "best_rating": NexusTeam.DEFAULT_RATING,
    "uncertainty": NexusTeam.INITIAL_UNCERTAINTY,
    "volatility": NexusTeam.DEFAULT_VOLATILITY,
    "form": 0.0,
    "last_activity_at": 0,
    "confidence": 1.0 - (NexusTeam.INITIAL_UNCERTAINTY - NexusTeam.MIN_UNCERTAINTY) / (NexusTeam.MAX_UNCERTAINTY - NexusTeam.MIN_UNCERTAINTY),
    "nexus_version": NexusTeam.NEXUS_VERSION,
}

var individual_1c1: Dictionary = {
    # Competitivo 1c1. Nunca comparte rating/copas con 2c2.
    "cups": 0,
    "lifetime_cups": 0,
    "games": 0,
    "wins": 0,
    "losses": 0,
    "draws": 0,
    "rating": Competitive.DEFAULT_RATING,
    "best_rating": Competitive.DEFAULT_RATING,
    "uncertainty": NexusTeam.INITIAL_UNCERTAINTY,
    "volatility": NexusTeam.DEFAULT_VOLATILITY,
    "form": 0.0,
    "confidence": 1.0 - (NexusTeam.INITIAL_UNCERTAINTY - NexusTeam.MIN_UNCERTAINTY) / (NexusTeam.MAX_UNCERTAINTY - NexusTeam.MIN_UNCERTAINTY),
    "last_activity_at": 0,
    "nexus_version": NexusTeam.NEXUS_VERSION,
    "streak": 0,
}

var pair_records: Dictionary = {}
var current_partner: Dictionary = {"id": "", "name": "", "pair_key": ""}
var current_pair_id := ""
var best_pair_id := ""
var history: Array[Dictionary] = []
var season: Dictionary = {
    "id": 1,
    "name": "Temporada 1",
    "started_at": 0,
}
var settings: Dictionary = {
    "vibration": true,
    "show_coordinates": true,
    "confirm_surrender": true,
    "reduced_motion": false,
    "sound": true,
}
var appearance: Dictionary = {
    # Experiencia de partida
    "board_theme": "classic",
    "piece_set": "classic",
    # Identidad visual del jugador
    "profile_frame": "classic",
    "player_title": "jugador",
    "name_color": "cream",
}
var reactions: Dictionary = {
    "equipped": [],
}

var persistence_service: RefCounted
var competitive_service: RefCounted
var history_service: RefCounted
var ranking_service: RefCounted

func _ready() -> void:
    _ensure_services()
    persistence_service.load_data()

func _ensure_services() -> void:
    if customization_service == null:
        customization_service = PlayerCustomizationServiceScript.new(self)
    if persistence_service == null:
        persistence_service = PlayerPersistenceServiceScript.new(self)
    if competitive_service == null:
        competitive_service = PlayerCompetitiveServiceScript.new(self)
    if history_service == null:
        history_service = PlayerHistoryServiceScript.new(self)
    if ranking_service == null:
        ranking_service = PlayerRankingServiceScript.new(self)

func load_data() -> void:
    _ensure_services()
    persistence_service.load_data()

func save_data() -> void:
    _ensure_services()
    persistence_service.save_data()


func export_account_snapshot() -> Dictionary:
    _ensure_services()
    return {
        "schema_version": 2,
        "exported_at": Time.get_unix_time_from_system(),
        "profile": profile.duplicate(true),
        "individual": individual.duplicate(true),
        "individual_1c1": individual_1c1.duplicate(true),
        "pair_records": pair_records.duplicate(true),
        "current_partner": current_partner.duplicate(true),
        "current_pair_id": current_pair_id,
        "best_pair_id": best_pair_id,
        "history": history.duplicate(true),
        "season": season.duplicate(true),
        "settings": settings.duplicate(true),
        "appearance": appearance.duplicate(true),
        "reactions": reactions.duplicate(true),
    }

func import_account_snapshot(snapshot: Dictionary) -> bool:
    _ensure_services()
    if int(snapshot.get("schema_version", 0)) < 2:
        return false
    if not snapshot.has("profile") or not snapshot.has("history"):
        return false
    profile = snapshot.get("profile", {}).duplicate(true)
    individual = snapshot.get("individual", {}).duplicate(true)
    individual_1c1 = snapshot.get("individual_1c1", {}).duplicate(true)
    pair_records = snapshot.get("pair_records", {}).duplicate(true)
    current_partner = snapshot.get("current_partner", {}).duplicate(true)
    current_pair_id = String(snapshot.get("current_pair_id", ""))
    best_pair_id = String(snapshot.get("best_pair_id", ""))
    history = snapshot.get("history", []).duplicate(true)
    season = snapshot.get("season", {}).duplicate(true)
    settings = snapshot.get("settings", settings).duplicate(true)
    appearance = snapshot.get("appearance", appearance).duplicate(true)
    reactions = snapshot.get("reactions", reactions).duplicate(true)
    _ensure_identity()
    _normalize_profile()
    _normalize_individual()
    _normalize_1c1_stats()
    _normalize_pairs()
    _normalize_nexus_state()
    _normalize_appearance()
    _normalize_reactions(true)
    save_data()
    data_changed.emit()
    return true

func _ensure_identity() -> void:
    _ensure_services()
    persistence_service._ensure_identity()

func _normalize_profile() -> void:
    _ensure_services()
    persistence_service._normalize_profile()

func _normalize_individual() -> void:
    _ensure_services()
    persistence_service._normalize_individual()

func _normalize_1c1_stats() -> void:
    _ensure_services()
    persistence_service._normalize_1c1_stats()

func _normalize_individual_stats(stats: Dictionary) -> void:
    _ensure_services()
    persistence_service._normalize_individual_stats(stats)

func _migrate_legacy_competitive_split() -> void:
    _ensure_services()
    persistence_service._migrate_legacy_competitive_split()

func _blank_competitive_stats() -> Dictionary:
    _ensure_services()
    return persistence_service._blank_competitive_stats()

func _normalize_nexus_state() -> void:
    _ensure_services()
    competitive_service._normalize_nexus_state()

func _normalize_pairs() -> void:
    _ensure_services()
    competitive_service._normalize_pairs()

func _refresh_best_pair_id() -> void:
    _ensure_services()
    competitive_service._refresh_best_pair_id()

func pair_key(partner_name: String, partner_id: String = "") -> String:
    _ensure_services()
    return competitive_service.pair_key(partner_name, partner_id)

func ensure_pair_record(key: String, partner_name: String = "", partner_id: String = "", partner_rating: int = NexusTeam.DEFAULT_RATING) -> Dictionary:
    _ensure_services()
    return competitive_service.ensure_pair_record(key, partner_name, partner_id, partner_rating)

func record_result(mode: int, outcome: String, partner_name: String = "", opponent_rating: int = Competitive.DEFAULT_RATING, opponent_pair_rating: int = Competitive.DEFAULT_RATING, partner_id: String = "", match_detail: Dictionary = {}) -> Dictionary:
    _ensure_services()
    return competitive_service.record_result(mode, outcome, partner_name, opponent_rating, opponent_pair_rating, partner_id, match_detail)

func record_noncompetitive_match(match_detail: Dictionary) -> Dictionary:
    _ensure_services()
    return history_service.record_noncompetitive_match(match_detail)

func mark_history_analysis_viewed(match_id: String, notify: bool = true) -> bool:
    _ensure_services()
    return history_service.mark_history_analysis_viewed(match_id, notify)

func history_analysis_viewed(match_id: String) -> bool:
    _ensure_services()
    return history_service.history_analysis_viewed(match_id)

func _trim_history() -> void:
    _ensure_services()
    history_service._trim_history()

func _generate_match_id() -> String:
    _ensure_services()
    return history_service._generate_match_id()

func current_league() -> Dictionary:
    _ensure_services()
    return ranking_service.current_league()

func current_league_1c1() -> Dictionary:
    _ensure_services()
    return ranking_service.current_league_1c1()

func league_progress() -> Dictionary:
    _ensure_services()
    return ranking_service.league_progress()

func league_progress_1c1() -> Dictionary:
    _ensure_services()
    return ranking_service.league_progress_1c1()

func pair_league(partner_name: String, partner_id: String = "") -> Dictionary:
    _ensure_services()
    return ranking_service.pair_league(partner_name, partner_id)

func reset_current_season(new_name: String = "") -> void:
    _ensure_services()
    ranking_service.reset_current_season(new_name)

func cup_status_text() -> String:
    _ensure_services()
    return ranking_service.cup_status_text()

func individual_rank_rows() -> Array[Dictionary]:
    _ensure_services()
    return ranking_service.individual_rank_rows()

func individual_cup_rank_rows() -> Array[Dictionary]:
    _ensure_services()
    return ranking_service.individual_cup_rank_rows()

func individual_1c1_rank_rows() -> Array[Dictionary]:
    _ensure_services()
    return ranking_service.individual_1c1_rank_rows()

func individual_1c1_cup_rank_rows() -> Array[Dictionary]:
    _ensure_services()
    return ranking_service.individual_1c1_cup_rank_rows()

func pair_rank_rows() -> Array[Dictionary]:
    _ensure_services()
    return ranking_service.pair_rank_rows()

func pair_cup_rank_rows() -> Array[Dictionary]:
    _ensure_services()
    return ranking_service.pair_cup_rank_rows()


func _normalize_appearance() -> void:
    _ensure_services()
    customization_service._normalize_appearance()

func _default_equipped_emotes() -> Array[String]:
    _ensure_services()
    return customization_service._default_equipped_emotes()

func _normalize_reactions(preserve_empty: bool = true) -> void:
    _ensure_services()
    customization_service._normalize_reactions(preserve_empty)

func get_equipped_emotes() -> Array[String]:
    _ensure_services()
    return customization_service.get_equipped_emotes()

func set_equipped_emotes(emote_ids: Array) -> bool:
    _ensure_services()
    return customization_service.set_equipped_emotes(emote_ids)

func toggle_emote_equipped(emote_id: String) -> bool:
    _ensure_services()
    return customization_service.toggle_emote_equipped(emote_id)

func move_equipped_emote(emote_id: String, direction: int) -> bool:
    _ensure_services()
    return customization_service.move_equipped_emote(emote_id, direction)

func set_display_name(new_name: String) -> bool:
    _ensure_services()
    return customization_service.set_display_name(new_name)

func set_avatar(path: String) -> bool:
    _ensure_services()
    return customization_service.set_avatar(path)

func set_setting(key: String, value: bool) -> void:
    _ensure_services()
    customization_service.set_setting(key, value)

func get_setting(key: String, fallback: bool = false) -> bool:
    _ensure_services()
    return customization_service.get_setting(key, fallback)

func set_appearance(key: String, value: String) -> void:
    _ensure_services()
    customization_service.set_appearance(key, value)

func set_game_skin(skin_id: String) -> bool:
    _ensure_services()
    return customization_service.set_game_skin(skin_id)

func get_appearance(key: String, fallback: String = "classic") -> String:
    _ensure_services()
    return customization_service.get_appearance(key, fallback)

