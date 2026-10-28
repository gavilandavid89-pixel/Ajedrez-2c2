extends SceneTree

var passed := 0
var failed := 0
var storage: Node
var cloud: Node

func _initialize() -> void:
    storage = preload("res://core/services/storage_manager.gd").new()
    cloud = preload("res://core/services/cloud_sync.gd").new()
    root.add_child(storage)
    root.add_child(cloud)
    call_deferred("_run")

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("OK: %s" % label)
    else:
        failed += 1
        push_error("FAIL: %s" % label)

func _run() -> void:
    var root := "user://storage_tests"
    var primary := root + "/profile.json"
    var backup := root + "/profile.json.bak"
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(primary))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))

    var payload := {"profile": {"id": "USR_TEST", "name": "Tester"}, "version": 1}
    _check(storage.write_json_atomic(primary, payload), "escritura atómica")
    _check(storage.read_json(primary, {}).get("profile", {}).get("id", "") == "USR_TEST", "lectura JSON principal")

    _check(storage.write_json_atomic(primary, {"profile": {"id": "USR_V2"}}, backup), "rotación a backup")
    _check(storage.read_json(backup, {}).get("profile", {}).get("id", "") == "USR_TEST", "backup conserva versión anterior")

    var corrupt := FileAccess.open(primary, FileAccess.WRITE)
    corrupt.store_string("{not-json")
    corrupt.close()
    var recovered: Dictionary = storage.read_json_with_recovery(primary, backup, {})
    _check(bool(recovered.get("recovered", false)), "recuperación desde backup")
    _check(recovered.get("data", {}).get("profile", {}).get("id", "") == "USR_TEST", "datos recuperados correctos")

    _check(storage.write_cache_json("tests", "summary", {"cached_at": Time.get_unix_time_from_system(), "value": 42}), "crear caché")
    var cache: Dictionary = storage.read_cache_json("tests", "summary", 3600)
    _check(bool(cache.get("hit", false)) and bool(cache.get("fresh", false)), "leer caché fresca")
    _check(int(cache.get("data", {}).get("value", 0)) == 42, "contenido de caché")

    storage.clear_sync_queue()
    _check(storage.note_local_change("test_profile", {"rev": 1}), "encolar cambio offline")
    _check(storage.sync_queue_size() == 1, "cola contiene un cambio")
    _check(storage.note_local_change("test_profile", {"rev": 2}), "actualizar cambio offline")
    _check(storage.sync_queue_size() == 1, "coalescing evita duplicados")
    _check(storage.get_sync_queue()[0].get("payload", {}).get("rev", 0) == 2, "cola conserva la versión más reciente")
    var op_id := String(storage.get_sync_queue()[0].get("id", ""))
    _check(storage.remove_sync_operation(op_id), "eliminar operación sincronizada")
    _check(storage.sync_queue_size() == 0, "cola vacía")

    _check(not cloud.is_configured(), "nube desactivada sin servidor")
    var cloud_result: Dictionary = cloud.sync_pending()
    _check(String(cloud_result.get("status", "")) == "disabled", "nube no simula una sincronización")

    DirAccess.remove_absolute(ProjectSettings.globalize_path(primary))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(root))
    print("STORAGE TESTS: %d/%d OK" % [passed, passed + failed])
    quit(1 if failed > 0 else 0)
