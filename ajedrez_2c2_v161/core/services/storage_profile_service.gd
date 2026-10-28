extends RefCounted
class_name StorageProfileService

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var ROOT_DIR: String:
    get: return String(host.ROOT_DIR)
var BACKUP_DIR: String:
    get: return String(host.BACKUP_DIR)
var STORAGE_VERSION: int:
    get: return int(host.STORAGE_VERSION)

func read_json(path: String, fallback: Variant = {}) -> Variant:
    return host.read_json(path, fallback)

func read_json_with_recovery(path: String, backup_path: String, fallback: Variant = {}) -> Dictionary:
    return host.read_json_with_recovery(path, backup_path, fallback)

func write_json_atomic(path: String, data: Variant, backup_path: String = "") -> bool:
    return host.write_json_atomic(path, data, backup_path)

func write_cache_json(ns: String, key: String, data: Dictionary) -> bool:
    return host.write_cache_json(ns, key, data)

func _emit_changed() -> void:
    if host != null and host.has_signal("storage_changed"):
        host.storage_changed.emit()

func save_profile(payload: Dictionary, legacy_path: String = "") -> bool:
    var document := {
        "storage_version": STORAGE_VERSION,
        "saved_at": Time.get_unix_time_from_system(),
        "profile": payload,
    }
    var ok := write_json_atomic(ROOT_DIR + "/profile.json", document, BACKUP_DIR + "/profile.json.bak")
    if not ok:
        return false
    if not legacy_path.is_empty():
        # Keep a one-way legacy mirror for safe rollback during migration.
        write_json_atomic(legacy_path, payload)
    _write_profile_caches(payload)
    _emit_changed()
    return true

func load_profile(legacy_path: String, fallback: Dictionary = {}) -> Dictionary:
    var primary_path := ROOT_DIR + "/profile.json"
    var primary := read_json_with_recovery(primary_path, BACKUP_DIR + "/profile.json.bak", {})
    if bool(primary.get("ok", false)):
        var wrapped: Dictionary = primary.get("data", {})
        var payload: Variant = wrapped.get("profile", wrapped)
        if payload is Dictionary:
            if bool(primary.get("recovered", false)):
                # Repair a corrupted primary without rotating it into the backup again.
                write_json_atomic(primary_path, wrapped)
            return {
                "ok": true,
                "data": payload.duplicate(true),
                "source": String(primary.get("source", "primary")),
                "recovered": bool(primary.get("recovered", false)),
            }

    # Migration path from the original v19 save location.
    var legacy: Variant = read_json(legacy_path, null)
    if legacy is Dictionary:
        save_profile(legacy, legacy_path)
        return {"ok": true, "data": legacy.duplicate(true), "source": "legacy", "recovered": true}
    return {"ok": false, "data": fallback.duplicate(true), "source": "default", "recovered": false}

func _write_profile_caches(payload: Dictionary) -> void:
    var individual: Dictionary = payload.get("individual", {}) if payload.get("individual", {}) is Dictionary else {}
    var individual_1c1: Dictionary = payload.get("individual_1c1", {}) if payload.get("individual_1c1", {}) is Dictionary else {}
    var profile: Dictionary = payload.get("profile", {}) if payload.get("profile", {}) is Dictionary else {}
    var reactions: Dictionary = payload.get("reactions", {}) if payload.get("reactions", {}) is Dictionary else {}
    var history: Array = payload.get("history", []) if payload.get("history", []) is Array else []
    write_cache_json("profile", "summary", {
        "cached_at": Time.get_unix_time_from_system(),
        "id": String(profile.get("id", "")),
        "name": String(profile.get("name", "Jugador")),
        "avatar": String(profile.get("avatar", "")),
        "rating": int(individual.get("rating", 0)),
        "cups": int(individual.get("cups", 0)),
        "rating_1c1": int(individual_1c1.get("rating", 0)),
        "cups_1c1": int(individual_1c1.get("cups", 0)),
        "reactions": reactions.get("equipped", []),
    })
    var history_index: Array = []
    var start := maxi(0, history.size() - 100)
    for i in range(start, history.size()):
        var item: Variant = history[i]
        if item is Dictionary:
            history_index.append({
                "match_id": String(item.get("match_id", "")),
                "timestamp": int(item.get("timestamp", 0)),
                "mode": item.get("mode", 0),
                "outcome": String(item.get("outcome", "")),
                "competitive": bool(item.get("competitive", true)),
            })
    write_cache_json("history", "index", {"cached_at": Time.get_unix_time_from_system(), "items": history_index})
