extends SceneTree

const RuntimeServices = preload("res://core/services/runtime_services.gd")
const AccountHubScene = preload("res://scenes/account_hub.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var player := RuntimeServices.get_autoload("PlayerData")
    _check(player != null, "RuntimeServices encuentra PlayerData desde un SceneTree activo")

    var hub := AccountHubScene.instantiate()
    var fallback = hub._data()
    _check(fallback != null, "AccountHub._data() es seguro fuera del árbol")
    hub.free()

    var hub2 := AccountHubScene.instantiate()
    root.add_child(hub2)
    await process_frame
    var data = hub2._data()
    _check(data != null and data.name == "PlayerData", "AccountHub usa el autoload real cuando está en escena")
    hub2.queue_free()
    await process_frame

    _check(RuntimeServices.get_autoload("NoExiste") == null, "RuntimeServices maneja servicios inexistentes")

    print("RUNTIME SERVICE SAFETY: %d/%d OK" % [passed, passed + failed])
    quit(0 if failed == 0 else 1)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
