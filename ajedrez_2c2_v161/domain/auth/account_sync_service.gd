extends Node
class_name AccountSyncService

signal state_changed(status: String, detail: Dictionary)

const LOCAL_METADATA_PATH := "user://ajedrez_2c2/account_sync.json"
const REMOTE_BACKUP_PATH := "user://ajedrez_2c2/account_remote_backup.json"
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

var revision := 0
var last_status := "local_only"
var conflict: Dictionary = {}
var _busy := false
var _connected_player_data: Node = null
var _connected_auth: Node = null

func _ready() -> void:
    _load_metadata()
    call_deferred("_bind_runtime")

func _bind_runtime() -> void:
    _connected_player_data = RuntimeServicesScript.get_autoload("PlayerData")
    _connected_auth = RuntimeServicesScript.get_autoload("AuthService")
    if _connected_player_data != null and _connected_player_data.has_signal("data_changed"):
        if not _connected_player_data.data_changed.is_connected(_on_player_data_changed):
            _connected_player_data.data_changed.connect(_on_player_data_changed)
    if _connected_auth != null and _connected_auth.has_signal("auth_changed"):
        if not _connected_auth.auth_changed.is_connected(_on_auth_changed):
            _connected_auth.auth_changed.connect(_on_auth_changed)
    if _connected_auth != null and _connected_auth.is_authenticated():
        call_deferred("bootstrap_after_login")

func _on_player_data_changed() -> void:
    if _busy:
        return
    revision += 1
    _save_metadata()
    var storage := RuntimeServicesScript.get_autoload("StorageManager")
    if storage != null:
        storage.note_local_change("account_snapshot", {
            "revision": revision,
            "account_id": _account_id(),
            "snapshot": export_snapshot(),
        })
    if is_cloud_ready():
        last_status = "pending_upload"
        state_changed.emit(last_status, {"revision": revision})

func _on_auth_changed(new_state: Dictionary) -> void:
    if String(new_state.get("status", "")) == "authenticated":
        call_deferred("bootstrap_after_login")
    elif String(new_state.get("status", "")) == "anonymous":
        last_status = "local_only"
        state_changed.emit(last_status, {})

func is_cloud_ready() -> bool:
    var auth := RuntimeServicesScript.get_autoload("AuthService")
    var cloud := RuntimeServicesScript.get_autoload("CloudSync")
    return auth != null and cloud != null and auth.is_authenticated() and cloud.is_configured()

func _account_id() -> String:
    var auth := RuntimeServicesScript.get_autoload("AuthService")
    return "" if auth == null else String(auth.current_account().get("account_id", ""))

func export_snapshot() -> Dictionary:
    var player_data := _connected_player_data if _connected_player_data != null else RuntimeServicesScript.get_autoload("PlayerData")
    if player_data == null or not player_data.has_method("export_account_snapshot"):
        return {}
    return player_data.export_account_snapshot()

func bootstrap_after_login() -> void:
    var cloud := RuntimeServicesScript.get_autoload("CloudSync")
    if cloud == null or not cloud.is_configured():
        last_status = "authenticated_local_only"
        state_changed.emit(last_status, {"reason":"cloud_not_configured"})
        return
    var result: Dictionary = await cloud.bootstrap_account(_account_id(), revision, export_snapshot())
    if bool(result.get("ok", false)):
        var remote: Dictionary = result.get("snapshot", {}) if result.get("snapshot", {}) is Dictionary else {}
        if remote.is_empty():
            await upload_local_snapshot()
        elif int(result.get("remote_revision", revision)) == revision:
            last_status = "synced"
            state_changed.emit(last_status, result)
        else:
            _store_conflict(remote, result)
        return
    last_status = "sync_error"
    state_changed.emit(last_status, result)

func upload_local_snapshot() -> Dictionary:
    var cloud := RuntimeServicesScript.get_autoload("CloudSync")
    if cloud == null or not cloud.is_configured() or _account_id().is_empty():
        return {"ok": false, "status": "local_only"}
    var result: Dictionary = await cloud.push_account_snapshot(_account_id(), revision, export_snapshot())
    if bool(result.get("ok", false)):
        last_status = "synced"
        _save_metadata()
    elif String(result.get("status", "")) == "conflict":
        var remote: Dictionary = result.get("snapshot", {}) if result.get("snapshot", {}) is Dictionary else {}
        _store_conflict(remote, result)
    else:
        last_status = "sync_error"
    state_changed.emit(last_status, result)
    return result

func has_conflict() -> bool:
    return not conflict.is_empty()

func keep_local_progress() -> Dictionary:
    if conflict.is_empty():
        return {"ok": false, "reason":"no_conflict"}
    var local_backup: Dictionary = conflict.get("local_snapshot", {}) if conflict.get("local_snapshot", {}) is Dictionary else {}
    var remote_revision := int(conflict.get("remote_revision", revision))
    # La decisión explícita "conservar este dispositivo" debe superar la revisión remota
    # antes de subirla; así no se vuelve a rechazar como conflicto.
    revision = maxi(revision, remote_revision) + 1
    conflict.clear()
    _save_conflict_backup(local_backup)
    _save_metadata()
    var result: Dictionary = await upload_local_snapshot()
    return {"ok": bool(result.get("ok", false)), "status":"local_kept" if bool(result.get("ok", false)) else "pending_upload", "upload":result}

func restore_cloud_progress() -> Dictionary:
    if conflict.is_empty():
        return {"ok": false, "reason":"no_conflict"}
    var remote: Dictionary = conflict.get("remote_snapshot", {}) if conflict.get("remote_snapshot", {}) is Dictionary else {}
    if remote.is_empty():
        return {"ok": false, "reason":"remote_empty"}
    _busy = true
    var player_data := RuntimeServicesScript.get_autoload("PlayerData")
    var ok: bool = player_data != null and player_data.has_method("import_account_snapshot") and player_data.import_account_snapshot(remote)
    _busy = false
    if ok:
        revision = int(conflict.get("remote_revision", revision))
        conflict.clear()
        _save_metadata()
        last_status = "restored_from_cloud"
        state_changed.emit(last_status, {"revision": revision})
    return {"ok": ok, "status": last_status}

func _store_conflict(remote: Dictionary, detail: Dictionary) -> void:
    var local: Dictionary = export_snapshot()
    _save_conflict_backup(remote)
    conflict = {
        "remote_snapshot": remote.duplicate(true),
        "local_snapshot": local.duplicate(true),
        "remote_revision": int(detail.get("remote_revision", revision)),
        "local_revision": revision,
    }
    last_status = "conflict"
    state_changed.emit(last_status, conflict.duplicate(true))

func _save_conflict_backup(snapshot: Dictionary) -> void:
    var file := FileAccess.open(REMOTE_BACKUP_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({"saved_at":Time.get_unix_time_from_system(),"snapshot":snapshot}))
    file.close()

func _load_metadata() -> void:
    if not FileAccess.file_exists(LOCAL_METADATA_PATH):
        return
    var file := FileAccess.open(LOCAL_METADATA_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        revision = int(parsed.get("revision", 0))
        last_status = String(parsed.get("last_status", "local_only"))

func _save_metadata() -> void:
    var file := FileAccess.open(LOCAL_METADATA_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({
        "schema_version":1,
        "revision":revision,
        "last_status":last_status,
        "saved_at":Time.get_unix_time_from_system(),
    }))
    file.close()
