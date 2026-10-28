extends SceneTree

const HOME := preload("res://scenes/mode_menu.tscn")
const RESULT := preload("res://scenes/game_match_result_screen.tscn")
var ok := 0
var failed := 0

func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    await process_frame
    var home := HOME.instantiate() as Control
    root.add_child(home)
    await process_frame
    await process_frame
    var scroll := home.get_node_or_null("HomeScroll") as ScrollContainer
    _check(scroll != null, "Inicio usa un contenedor desplazable")
    _check(scroll != null and scroll.offset_top <= 100.0, "Inicio no reserva una cortina superior grande")
    _check(home.find_child("Title", true, false) != null, "Título de Inicio está en el árbol visible")
    _check(home.get_node_or_null("MainNavigation") != null, "Navegación inferior disponible")
    home.queue_free()
    await process_frame

    var result := RESULT.instantiate() as Control
    root.add_child(result)
    await process_frame
    var home_button := result.get_node_or_null("HomeFixed") as Button
    _check(home_button != null and home_button.visible, "Resultado ofrece volver al inicio sin analizar")
    _check(home_button != null and home_button.custom_minimum_size.y >= 56.0, "Botón Inicio tiene zona táctil amplia")
    _check(result.get_node_or_null("ResultScroll") != null, "Resultado permite deslizar su contenido")
    result.queue_free()
    await process_frame

    var app_source := FileAccess.get_file_as_string("res://core/services/app.gd")
    _check(not app_source.contains("await tree.scene_changed"), "Transición no depende de una señal que pueda dejar cortina permanente")
    var hub_source := FileAccess.get_file_as_string("res://ui/screens/account_hub.gd")
    _check(not hub_source.contains("var task := func():\n        return service.analyze_replay"), "Análisis ya no usa lambda local capturada por el hilo")
    var members_source := FileAccess.get_file_as_string("res://ui/screens/club_members_screen.gd")
    _check(members_source.contains("_on_role_button_pressed.bind"), "Acciones de miembros usan callbacks ligados y validados")
    var renderer_source := FileAccess.get_file_as_string("res://ui/components/account_page_renderer.gd")
    _check(renderer_source.contains("_apply_mobile_readability()"), "Subpáginas de cuenta reciben ajuste de lectura móvil")

    print("V142 MOBILE UI REGRESSION: %d OK / %d FAILED" % [ok, failed])
    quit(1 if failed > 0 else 0)

func _check(condition: bool, message: String) -> void:
    if condition:
        ok += 1
        print("[OK] ", message)
    else:
        failed += 1
        print("[FAIL] ", message)
