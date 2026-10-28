extends RefCounted
class_name StorageFileService

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var ROOT_DIR: String:
    get: return String(host.ROOT_DIR)
var CACHE_DIR: String:
    get: return String(host.CACHE_DIR)
var BACKUP_DIR: String:
    get: return String(host.BACKUP_DIR)
var STORAGE_META_PATH: String:
    get: return String(host.STORAGE_META_PATH)
var STORAGE_VERSION: int:
    get: return int(host.STORAGE_VERSION)
var NOMEDIA_MARKER: String:
    get: return String(host.NOMEDIA_MARKER)

func _emit_changed() -> void:
    host.storage_changed.emit()

func _ensure_dirs() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT_DIR))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIR))
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
    _ensure_no_media(ROOT_DIR)
    _ensure_no_media(CACHE_DIR)
    _ensure_no_media(BACKUP_DIR)

func _ensure_no_media(dir_path: String) -> void:
    # Defensa adicional para Android: aunque user:// sea privado de la app,
    # el marcador evita que un MediaScanner trate datos futuros como fotos/videos.
    var marker := "%s/%s" % [ProjectSettings.globalize_path(dir_path), NOMEDIA_MARKER]
    if not FileAccess.file_exists(marker):
        var file := FileAccess.open(marker, FileAccess.WRITE)
        if file != null:
            file.store_string("")
            file.close()

func _ensure_meta() -> void:
    if FileAccess.file_exists(STORAGE_META_PATH):
        return
    write_json_atomic(STORAGE_META_PATH, {
        "storage_version": STORAGE_VERSION,
        "created_at": Time.get_unix_time_from_system(),
    })

func _absolute(path: String) -> String:
    return ProjectSettings.globalize_path(path)

func _safe_key(value: String) -> String:
    var out := ""
    for char in value:
        var code := char.unicode_at(0)
        var allowed := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 45 or code == 95
        out += char if allowed else "_"
    return out.substr(0, 80) if out.length() > 80 else out

func _cache_path(ns: String, key: String) -> String:
    return "%s/%s_%s.json" % [CACHE_DIR, _safe_key(ns), _safe_key(key)]

func _backup_path_for(path: String) -> String:
    var file_name := path.get_file()
    return "%s/%s.bak" % [BACKUP_DIR, _safe_key(file_name)]

func read_json(path: String, fallback: Variant = {}) -> Variant:
    if not FileAccess.file_exists(path):
        return fallback
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return fallback
    var text := file.get_as_text()
    if text.is_empty():
        return fallback
    var parser := JSON.new()
    var parse_error := parser.parse(text)
    if parse_error != OK:
        return fallback
    return parser.data

func read_json_with_recovery(path: String, backup_path: String, fallback: Variant = {}) -> Dictionary:
    var primary: Variant = read_json(path, null)
    if primary is Dictionary:
        return {"ok": true, "data": primary, "source": "primary", "recovered": false}
    var backup: Variant = read_json(backup_path, null)
    if backup is Dictionary:
        return {"ok": true, "data": backup, "source": "backup", "recovered": true}
    return {"ok": false, "data": fallback, "source": "default", "recovered": false}

func write_json_atomic(path: String, data: Variant, backup_path: String = "") -> bool:
    var abs_path := _absolute(path)
    var parent := abs_path.get_base_dir()
    DirAccess.make_dir_recursive_absolute(parent)
    var temp_path := "%s.tmp" % abs_path
    var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
    if temp_file == null:
        return false
    temp_file.store_string(JSON.stringify(data))
    temp_file.flush()
    temp_file.close()
    if not FileAccess.file_exists(temp_path):
        return false

    var final_abs := abs_path
    var backup_abs := _absolute(backup_path) if not backup_path.is_empty() else ""
    if not backup_abs.is_empty() and FileAccess.file_exists(final_abs):
        DirAccess.make_dir_recursive_absolute(backup_abs.get_base_dir())
        # Never replace a known-good backup with a corrupted current file.
        var current_valid := read_json(final_abs, null) != null
        if current_valid:
            if FileAccess.file_exists(backup_abs):
                DirAccess.remove_absolute(backup_abs)
            if not DirAccess.copy_absolute(final_abs, backup_abs) == OK:
                return false

    if FileAccess.file_exists(final_abs):
        DirAccess.remove_absolute(final_abs)
    var renamed := DirAccess.rename_absolute(temp_path, final_abs)
    if renamed != OK:
        # Fallback: retain data rather than silently discarding it.
        if FileAccess.file_exists(final_abs):
            DirAccess.remove_absolute(final_abs)
        var fallback_copy := DirAccess.copy_absolute(temp_path, final_abs)
        DirAccess.remove_absolute(temp_path)
        if fallback_copy != OK:
            return false
    if not backup_abs.is_empty() and not FileAccess.file_exists(backup_abs) and FileAccess.file_exists(final_abs):
        DirAccess.copy_absolute(final_abs, backup_abs)
    _emit_changed()
    return true
