extends Node

const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

func _ready() -> void:
    await get_tree().process_frame
    var failures := 0
    var storage := RuntimeServicesScript.get_autoload("StorageManager")
    var player := RuntimeServicesScript.get_autoload("PlayerData")
    var cloud := RuntimeServicesScript.get_autoload("CloudSync")
    failures += _check(storage != null, "StorageManager autoload disponible")
    failures += _check(player != null, "PlayerData autoload disponible")
    failures += _check(cloud != null, "CloudSync autoload disponible")
    if storage != null:
        var state: Dictionary = storage.export_debug_state()
        failures += _check(bool(state.get("profile_exists", false)), "perfil local guardado")
        failures += _check(bool(state.get("backup_exists", false)), "backup local preparado")
        var cache: Dictionary = storage.read_cache_json("profile", "summary", 3600)
        failures += _check(bool(cache.get("hit", false)), "caché de resumen generada")
    if player != null:
        failures += _check(not String(player.profile.get("id", "")).is_empty(), "identidad persistente disponible")
        var before_name := String(player.profile.get("name", ""))
        player.save_data()
        failures += _check(String(player.profile.get("name", "")) == before_name, "guardado no altera identidad")
    if cloud != null:
        var sync: Dictionary = cloud.sync_pending()
        failures += _check(String(sync.get("status", "")) == "disabled", "sin servidor la nube queda correctamente desactivada")
    if storage != null:
        failures += _check(storage.sync_queue_size() >= 2, "cola offline conserva núcleo e historial")
        var queue: Array[Dictionary] = storage.get_sync_queue()
        var has_core := false
        var has_history := false
        for item in queue:
            if String(item.get("coalesce_key", "")) == "entity:profile_core":
                has_core = true
            if String(item.get("coalesce_key", "")) == "entity:history":
                has_history = true
        failures += _check(has_core and has_history, "cola contiene operaciones sincronizables reales")
    print("STORAGE RUNTIME: %d/%d OK" % [10 - failures, 10])
    get_tree().quit(1 if failures > 0 else 0)

func _check(value: bool, label: String) -> int:
    if value:
        print("[OK] " + label)
        return 0
    push_error("[FALLA] " + label)
    return 1
