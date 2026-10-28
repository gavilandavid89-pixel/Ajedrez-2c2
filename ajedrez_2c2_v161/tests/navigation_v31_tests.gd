extends SceneTree

const ModeScene := preload("res://scenes/mode_menu.tscn")
const AccountScene := preload("res://scenes/account_hub.tscn")
const LocalScene := preload("res://scenes/local_setup.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var mode := ModeScene.instantiate()
    root.add_child(mode)
    await process_frame
    await process_frame
    var nav = mode.get_node_or_null("MainNavigation")
    _check(nav != null, "Jugar crea navegación principal")
    if nav != null:
        _check(nav.get_node("Bar/Items").get_child_count() == 4, "Jugar expone exactamente 4 destinos")
        _check(nav._active == "home", "Inicio está activo")
        _check(nav.get_node("Bar/Items/Home").text.find("Inicio") >= 0, "destino Inicio está etiquetado")
        _check(nav.get_node("Bar/Items/Club").text.find("Club") >= 0, "destino Club está reservado")
        _check(nav.get_node("Bar/Items/Friends").text.find("Amigos") >= 0, "destino Amigos está reservado")
        _check(nav.get_node("Bar/Items/More").text.find("Más") >= 0, "destino Más está etiquetado")
    _check(mode.get_node_or_null("Margin/VBox/Account") == null, "Perfil no es un botón central")
    _check(mode.get_node_or_null("Margin/VBox/QuickMenu") == null, "QuickMenu antiguo no existe")
    var local := LocalScene.instantiate()
    root.add_child(local)
    await process_frame
    _check(local.find_child("LocalSetup", true, false) != null or local.name == "LocalSetup", "1c1 Local tiene menú de preparación")
    local.queue_free()
    mode.queue_free()

    var app := root.get_node_or_null("App")
    if app != null:
        for requested in ["ranking", "history", "more", "help"]:
            app.account_start_page = requested
            var account := AccountScene.instantiate()
            root.add_child(account)
            await process_frame
            await process_frame
            _check(account.page == requested, "AccountHub abre %s desde la navegación" % requested)
            _check(account.main_nav == null or not account.main_nav.visible, "AccountHub no muestra barra global en %s" % requested)
            account.queue_free()
            await process_frame
        app.account_start_page = "profile"

    print("V31 NAVEGACIÓN: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
