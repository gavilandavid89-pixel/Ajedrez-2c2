extends RefCounted
class_name PlayerPersistenceService

const StorageManagerScript = preload("res://core/services/storage_manager.gd")
const NexusTeam = preload("res://domain/competitive/nexus_team.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var _standalone_storage: Variant:
    get: return host._standalone_storage
    set(value): host._standalone_storage = value
var reactions: Variant:
    get: return host.reactions
    set(value): host.reactions = value
var settings: Variant:
    get: return host.settings
    set(value): host.settings = value
var appearance: Variant:
    get: return host.appearance
    set(value): host.appearance = value
var data_changed: Variant:
    get: return host.data_changed

const Competitive = preload("res://domain/competitive/competitive_system.gd")

func get_tree() -> SceneTree:
    return host.get_tree()

var SAVE_PATH: String:
    get: return String(host.SAVE_PATH)
var DEFAULT_NAME: String:
    get: return String(host.DEFAULT_NAME)
var DEFAULT_AVATAR: String:
    get: return String(host.DEFAULT_AVATAR)
var MAX_DISPLAY_NAME_LENGTH: int:
    get: return int(host.MAX_DISPLAY_NAME_LENGTH)
var USER_ID_PREFIX: String:
    get: return String(host.USER_ID_PREFIX)
var profile: Variant:
    get: return host.profile
    set(value): host.profile = value
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
    set(value): host.season = value

func _normalize_pairs() -> void:
    host._normalize_pairs()

func _normalize_nexus_state() -> void:
    host._normalize_nexus_state()

func _normalize_appearance() -> void:
    host._normalize_appearance()

func _default_equipped_emotes() -> Array[String]:
    return host._default_equipped_emotes()

func _normalize_reactions(preserve_empty: bool = true) -> void:
    host._normalize_reactions(preserve_empty)

func _last_2c2_timestamp() -> int:
    return host.competitive_service._last_2c2_timestamp() if host.competitive_service != null else 0

func _last_1c1_timestamp() -> int:
    return host.competitive_service._last_1c1_timestamp() if host.competitive_service != null else 0

func _storage() -> Node:
    var tree := get_tree()
    if tree != null:
        var existing := tree.root.get_node_or_null("StorageManager")
        if existing != null:
            return existing
        if _standalone_storage == null:
            _standalone_storage = StorageManagerScript.new()
            tree.root.add_child(_standalone_storage)
    return _standalone_storage

func load_data() -> void:
    var storage := _storage()
    var loaded: Dictionary = {"ok": false, "data": {}}
    if storage != null:
        loaded = storage.load_profile(SAVE_PATH, {})
    var parsed: Dictionary = loaded.get("data", {}) if loaded.get("ok", false) else {}
    if parsed.is_empty():
        # Primera ejecución: identidad, temporada y loadout inicial preparados.
        _ensure_identity()
        season["started_at"] = Time.get_unix_time_from_system()
        reactions = {"equipped": _default_equipped_emotes()}
        save_data()
        return
    profile = _merge_dict(profile, parsed.get("profile", {}))
    _ensure_identity()
    var raw_individual: Variant = parsed.get("individual", {})
    var raw_individual_1c1: Variant = parsed.get("individual_1c1", {})
    individual = _merge_dict(individual, parsed.get("individual", {}))
    individual_1c1 = _merge_dict(individual_1c1, parsed.get("individual_1c1", {}))
    # Al cargar un bloque antiguo sin versión NEXUS, eliminamos solo los
    # campos V2 derivados que provienen de los defaults modernos. Así la
    # normalización puede aplicar la migración suave correcta sin perder
    # rating/copas históricas.
    if raw_individual is Dictionary and not raw_individual.has("nexus_version"):
        for key in ["nexus_version", "uncertainty", "volatility", "form", "confidence", "last_activity_at"]:
            individual.erase(key)
    if raw_individual_1c1 is Dictionary and not raw_individual_1c1.has("nexus_version"):
        for key in ["nexus_version", "uncertainty", "volatility", "form", "confidence", "last_activity_at"]:
            individual_1c1.erase(key)
    pair_records = parsed.get("pair_records", {}) if parsed.get("pair_records", {}) is Dictionary else {}
    current_partner = _merge_dict(current_partner, parsed.get("current_partner", {}))
    current_pair_id = String(parsed.get("current_pair_id", current_partner.get("pair_key", "")))
    best_pair_id = String(parsed.get("best_pair_id", ""))
    # El historial es evidencia para reconstruir actividad cuando una cuenta
    # antigua no persistió last_activity_at. Debe cargarse antes de normalizar.
    var loaded_history = parsed.get("history", [])
    history.clear()
    if loaded_history is Array:
        for item in loaded_history:
            if item is Dictionary:
                history.append(item)
    if not parsed.has("individual_1c1"):
        _migrate_legacy_competitive_split()
    _normalize_profile()
    _normalize_individual()
    _normalize_1c1_stats()
    _normalize_pairs()
    _normalize_nexus_state()
    season = _merge_dict(season, parsed.get("season", {}))
    if int(season.get("started_at", 0)) <= 0:
        season["started_at"] = Time.get_unix_time_from_system()
    settings = _merge_dict(settings, parsed.get("settings", {}))
    settings["sound"] = bool(settings.get("sound", true))
    appearance = _merge_dict(appearance, parsed.get("appearance", {}))
    _normalize_appearance()
    var loaded_reactions: Variant = parsed.get("reactions", null)
    if loaded_reactions is Dictionary:
        reactions = _merge_dict(reactions, loaded_reactions)
        _normalize_reactions(true)
    else:
        reactions = {"equipped": _default_equipped_emotes()}
    host.data_changed.emit()

func _ensure_identity() -> void:
    var current_id := String(profile.get("id", "")).strip_edges()
    if current_id.is_empty() or current_id == "local_player":
        profile["id"] = _generate_user_id()
    var provider := String(profile.get("auth_provider", "local")).strip_edges().to_lower()
    profile["auth_provider"] = provider if not provider.is_empty() else "local"

func _generate_user_id() -> String:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var high := rng.randi()
    var low := rng.randi()
    return "%s%08X%08X" % [USER_ID_PREFIX, high, low]

func _normalize_profile() -> void:
    _ensure_identity()
    var display_name := String(profile.get("name", DEFAULT_NAME)).strip_edges()
    if display_name.is_empty():
        display_name = DEFAULT_NAME
    if display_name.length() > MAX_DISPLAY_NAME_LENGTH:
        display_name = display_name.substr(0, MAX_DISPLAY_NAME_LENGTH)
    profile["name"] = display_name
    var avatar := String(profile.get("avatar", DEFAULT_AVATAR))
    profile["avatar"] = avatar if not avatar.is_empty() else DEFAULT_AVATAR

func save_data() -> void:
    var payload := {
        "profile": profile,
        "individual": individual,
        "individual_1c1": individual_1c1,
        "pair_records": pair_records,
        "current_partner": current_partner,
        "current_pair_id": current_pair_id,
        "best_pair_id": best_pair_id,
        "history": history.slice(maxi(0, history.size() - 100)),
        "season": season,
        "settings": settings,
        "appearance": appearance,
        "reactions": reactions,
    }
    var storage := _storage()
    if storage != null and storage.save_profile(payload, SAVE_PATH):
        var core_payload := {
            "profile": profile.duplicate(true),
            "individual": individual.duplicate(true),
            "individual_1c1": individual_1c1.duplicate(true),
            "pair_records": pair_records.duplicate(true),
            "current_partner": current_partner.duplicate(true),
            "current_pair_id": current_pair_id,
            "best_pair_id": best_pair_id,
            "season": season.duplicate(true),
            "settings": settings.duplicate(true),
            "appearance": appearance.duplicate(true),
            "reactions": reactions.duplicate(true),
            "saved_at": Time.get_unix_time_from_system(),
        }
        storage.note_local_change("profile_core", core_payload)
        storage.note_local_change("history", {
            "player_id": String(profile.get("id", "")),
            "history": history.slice(maxi(0, history.size() - 100)),
            "saved_at": Time.get_unix_time_from_system(),
        })

func _merge_dict(base: Dictionary, incoming: Variant) -> Dictionary:
    var out := base.duplicate(true)
    if incoming is Dictionary:
        for key in incoming.keys():
            out[key] = incoming[key]
    return out

func _normalize_individual() -> void:
    _normalize_individual_stats(individual)

func _normalize_1c1_stats() -> void:
    _normalize_individual_stats(individual_1c1)
    var migrated: bool = not individual_1c1.has("nexus_version")
    individual_1c1["uncertainty"] = clampf(float(individual_1c1.get("uncertainty", NexusTeam.MIGRATED_UNCERTAINTY if migrated else NexusTeam.INITIAL_UNCERTAINTY)), NexusTeam.MIN_UNCERTAINTY, NexusTeam.MAX_UNCERTAINTY)
    individual_1c1["volatility"] = clampf(float(individual_1c1.get("volatility", NexusTeam.DEFAULT_VOLATILITY)), NexusTeam.MIN_VOLATILITY, NexusTeam.MAX_VOLATILITY)
    individual_1c1["form"] = clampf(float(individual_1c1.get("form", 0.0)), -1.0, 1.0)
    individual_1c1["confidence"] = clampf(float(individual_1c1.get("confidence", 1.0 - (individual_1c1["uncertainty"] - NexusTeam.MIN_UNCERTAINTY) / (NexusTeam.MAX_UNCERTAINTY - NexusTeam.MIN_UNCERTAINTY))), 0.0, 1.0)
    var last_activity := int(individual_1c1.get("last_activity_at", 0))
    if last_activity <= 0:
        last_activity = _last_1c1_timestamp()
    individual_1c1["last_activity_at"] = last_activity
    individual_1c1["nexus_version"] = NexusTeam.NEXUS_VERSION
    individual_1c1["streak"] = maxi(0, int(individual_1c1.get("streak", 0)))

func _normalize_individual_stats(stats: Dictionary) -> void:
    stats["rating"] = maxi(Competitive.MIN_RATING, int(stats.get("rating", Competitive.DEFAULT_RATING)))
    stats["best_rating"] = maxi(int(stats.get("rating", Competitive.DEFAULT_RATING)), int(stats.get("best_rating", Competitive.DEFAULT_RATING)))
    stats["cups"] = maxi(0, int(stats.get("cups", 0)))
    stats["lifetime_cups"] = maxi(int(stats.get("cups", 0)), int(stats.get("lifetime_cups", stats.get("cups", 0))))
    for key in ["games", "wins", "losses", "draws"]:
        stats[key] = maxi(0, int(stats.get(key, 0)))

func _migrate_legacy_competitive_split() -> void:
    # Versiones anteriores mezclaban 1c1 y 2c2 en `individual`. Si hay historial,
    # reconstruimos ambos bloques usando los deltas ya guardados, sin tocar reglas ni partidas.
    var rebuilt_2c2 := _blank_competitive_stats()
    var rebuilt_1c1 := _blank_competitive_stats()
    var has_competitive_history := false
    for entry in history:
        if not entry is Dictionary or not bool(entry.get("competitive", true)):
            continue
        var mode := int(entry.get("mode", -1))
        if mode != 0 and mode != 1:
            continue
        has_competitive_history = true
        var target: Dictionary = rebuilt_2c2 if mode == 0 else rebuilt_1c1
        target["games"] = int(target["games"]) + 1
        match String(entry.get("outcome", "draw")):
            "win":
                target["wins"] = int(target["wins"]) + 1
            "loss":
                target["losses"] = int(target["losses"]) + 1
            _:
                target["draws"] = int(target["draws"]) + 1
        var rating_delta := int(entry.get("rating_delta", 0))
        var cup_delta := int(entry.get("cup_delta", 0))
        target["rating"] = maxi(Competitive.MIN_RATING, int(target["rating"]) + rating_delta)
        target["best_rating"] = maxi(int(target["best_rating"]), int(target["rating"]))
        target["cups"] = Competitive.cup_total_after(int(target["cups"]), cup_delta)
        if cup_delta > 0:
            target["lifetime_cups"] = int(target["lifetime_cups"]) + cup_delta
        if mode == 1:
            match String(entry.get("outcome", "draw")):
                "win": target["streak"] = int(target.get("streak", 0)) + 1
                _:
                    target["streak"] = 0
    if has_competitive_history:
        individual = rebuilt_2c2
        individual_1c1 = rebuilt_1c1

func _blank_competitive_stats() -> Dictionary:
    return {
        "cups": 0,
        "lifetime_cups": 0,
        "games": 0,
        "wins": 0,
        "losses": 0,
        "draws": 0,
        "rating": Competitive.DEFAULT_RATING,
        "best_rating": Competitive.DEFAULT_RATING,
    }
