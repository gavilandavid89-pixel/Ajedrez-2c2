extends SceneTree

const MODE_MENU := preload("res://scenes/mode_menu.tscn")
const PLAYER_DATA := preload("res://domain/player/player_data.gd")

var failed := 0

func _initialize() -> void:
    var data := PLAYER_DATA.new()
    data.name = "PlayerData"
    root.add_child(data)
    var menu := MODE_MENU.instantiate()
    root.add_child(menu)
    await process_frame
    await process_frame
    _check(menu.profile_button != null, "main menu creates profile button")
    _check(menu.profile_button.text.strip_edges().is_empty(), "profile button has no visible name")
    _check(menu.profile_button.icon != null, "profile button exposes player avatar")
    _check(menu.get_node_or_null("Margin/VBox/Account") == null, "perfil ya no usa botón central antiguo")
    _check(menu.main_nav != null and menu.main_nav.get_node("Bar/Items").get_child_count() == 4, "barra principal deja Perfil fuera")
    print("PROFILE ENTRY SMOKE: %d OK / %d FALLARON" % [5 - failed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if not value:
        failed += 1
        push_error("[FALLA] " + label)
    else:
        print("[OK] " + label)
