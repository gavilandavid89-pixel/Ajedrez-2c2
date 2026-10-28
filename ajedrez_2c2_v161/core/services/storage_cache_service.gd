extends RefCounted
class_name StorageCacheService

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var CACHE_DIR: String:
    get: return String(host.CACHE_DIR)

func _ensure_dirs() -> void:
    host._ensure_dirs()

func _cache_path(ns: String, key: String) -> String:
    return host._cache_path(ns, key)

func _absolute(path: String) -> String:
    return host._absolute(path)

func _safe_key(value: String) -> String:
    return host._safe_key(value)

func read_json(path: String, fallback: Variant = {}) -> Variant:
    return host.read_json(path, fallback)

func write_json_atomic(path: String, data: Variant, backup_path: String = "") -> bool:
    return host.write_json_atomic(path, data, backup_path)

func write_cache_json(ns: String, key: String, data: Dictionary) -> bool:
    _ensure_dirs()
    return write_json_atomic(_cache_path(ns, key), data)

func read_cache_json(ns: String, key: String, max_age_seconds: int = 86400) -> Dictionary:
    var path := _cache_path(ns, key)
    var parsed: Variant = read_json(path, null)
    if not (parsed is Dictionary):
        return {"hit": false, "fresh": false, "data": {}}
    var cached_at := int(parsed.get("cached_at", 0))
    var fresh := cached_at > 0 and (Time.get_unix_time_from_system() - cached_at) <= max_age_seconds
    return {"hit": true, "fresh": fresh, "data": parsed}

func clear_cache(ns: String = "", key: String = "") -> void:
    if ns.is_empty():
        DirAccess.remove_absolute(_absolute(CACHE_DIR))
        _ensure_dirs()
        return
    if key.is_empty():
        var dir := DirAccess.open(_absolute(CACHE_DIR))
        if dir == null:
            return
        dir.list_dir_begin()
        var file_name := dir.get_next()
        var prefix := _safe_key(ns) + "_"
        while not file_name.is_empty():
            if not dir.current_is_dir() and file_name.begins_with(prefix):
                DirAccess.remove_absolute(_absolute(CACHE_DIR + "/" + file_name))
            file_name = dir.get_next()
        dir.list_dir_end()
        return
    var path := _cache_path(ns, key)
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(_absolute(path))
