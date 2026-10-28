extends Node
class_name StorageManagerClass

signal storage_changed

const ROOT_DIR := "user://ajedrez_2c2"
const CACHE_DIR := ROOT_DIR + "/cache"
const BACKUP_DIR := ROOT_DIR + "/backup"
const SYNC_QUEUE_PATH := ROOT_DIR + "/sync_queue.json"
const STORAGE_META_PATH := ROOT_DIR + "/storage_meta.json"
const STORAGE_VERSION := 1
const MAX_SYNC_QUEUE := 100
const NOMEDIA_MARKER := ".nomedia"

const StorageFileServiceScript = preload("res://core/services/storage_file_service.gd")
const StorageProfileServiceScript = preload("res://core/services/storage_profile_service.gd")
const StorageCacheServiceScript = preload("res://core/services/storage_cache_service.gd")
const StorageSyncServiceScript = preload("res://core/services/storage_sync_service.gd")

var file_service: RefCounted
var profile_service: RefCounted
var cache_service: RefCounted
var sync_service: RefCounted

func _ready() -> void:
    file_service = StorageFileServiceScript.new(self)
    profile_service = StorageProfileServiceScript.new(self)
    cache_service = StorageCacheServiceScript.new(self)
    sync_service = StorageSyncServiceScript.new(self)
    _ensure_dirs()
    _ensure_meta()

func _ensure_dirs() -> void:
    file_service._ensure_dirs()

func _ensure_no_media(dir_path: String) -> void:
    file_service._ensure_no_media(dir_path)

func _ensure_meta() -> void:
    file_service._ensure_meta()

func _absolute(path: String) -> String:
    return file_service._absolute(path)

func _safe_key(value: String) -> String:
    return file_service._safe_key(value)

func _cache_path(ns: String, key: String) -> String:
    return file_service._cache_path(ns, key)

func _backup_path_for(path: String) -> String:
    return file_service._backup_path_for(path)

func read_json(path: String, fallback: Variant = {}) -> Variant:
    return file_service.read_json(path, fallback)

func read_json_with_recovery(path: String, backup_path: String, fallback: Variant = {}) -> Dictionary:
    return file_service.read_json_with_recovery(path, backup_path, fallback)

func write_json_atomic(path: String, data: Variant, backup_path: String = "") -> bool:
    return file_service.write_json_atomic(path, data, backup_path)

func save_profile(payload: Dictionary, legacy_path: String = "") -> bool:
    return profile_service.save_profile(payload, legacy_path)

func load_profile(legacy_path: String, fallback: Dictionary = {}) -> Dictionary:
    return profile_service.load_profile(legacy_path, fallback)

func _write_profile_caches(payload: Dictionary) -> void:
    profile_service._write_profile_caches(payload)

func write_cache_json(ns: String, key: String, data: Dictionary) -> bool:
    return cache_service.write_cache_json(ns, key, data)

func read_cache_json(ns: String, key: String, max_age_seconds: int = 86400) -> Dictionary:
    return cache_service.read_cache_json(ns, key, max_age_seconds)

func clear_cache(ns: String = "", key: String = "") -> void:
    cache_service.clear_cache(ns, key)

func enqueue_sync(operation: Dictionary) -> bool:
    return sync_service.enqueue_sync(operation)

func get_sync_queue() -> Array[Dictionary]:
    return sync_service.get_sync_queue()

func sync_queue_size() -> int:
    return sync_service.sync_queue_size()

func remove_sync_operation(operation_id: String) -> bool:
    return sync_service.remove_sync_operation(operation_id)

func clear_sync_queue() -> void:
    sync_service.clear_sync_queue()

func note_local_change(entity: String, payload: Dictionary) -> bool:
    return sync_service.note_local_change(entity, payload)

func export_debug_state() -> Dictionary:
    return {
        "root": ROOT_DIR,
        "cache_dir": CACHE_DIR,
        "backup_dir": BACKUP_DIR,
        "profile_exists": FileAccess.file_exists(ROOT_DIR + "/profile.json"),
        "backup_exists": FileAccess.file_exists(BACKUP_DIR + "/profile.json.bak"),
        "cache_summary": read_cache_json("profile", "summary", 2147483647),
        "sync_queue_size": sync_queue_size(),
    }

