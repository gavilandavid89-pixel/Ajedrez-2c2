extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    var source := FileAccess.get_file_as_string("res://ui/screens/mode_menu.gd")
    _check(source.find("HistoryProfileIcons") >= 0, "home historial tiene contenedor de perfiles")
    _check(source.find("_open_history_profile") >= 0, "home historial tiene acceso directo a perfil")
    _check(source.find("target_profile_id") >= 0, "home historial prepara el perfil destino")
    _check(source.find("ScreenCatalog.PLAYER_PROFILE") >= 0, "home historial navega al perfil")
    _check(source.find("Ver perfil de %s") >= 0, "iconos tienen identificador accesible")
    print("HISTORY PROFILE V73: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
