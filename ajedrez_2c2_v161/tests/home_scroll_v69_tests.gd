extends SceneTree

const ModeScene := preload("res://scenes/mode_menu.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var menu := ModeScene.instantiate()
    root.add_child(menu)
    await process_frame
    await process_frame
    _check(menu.get_node_or_null("HomeScroll") != null, "inicio usa scroll vertical")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/PlayButton") != null, "Jugar es la acción principal")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/BotSectionButton") != null, "Bots es un apartado independiente")
    var title := menu.get_node("HomeScroll/HomeMargin/VBox/Title") as Label
    var play_button := menu.get_node("HomeScroll/HomeMargin/VBox/PlayButton") as Button
    var bot_button := menu.get_node("HomeScroll/HomeMargin/VBox/BotSectionButton") as Button
    _check(play_button.position.y > title.position.y + title.size.y, "Jugar queda debajo del encabezado")
    _check(bot_button.position.y > play_button.position.y + play_button.size.y, "Bots queda inmediatamente después de Jugar")
    _check(menu.get_node_or_null("ProfileButton") != null, "Perfil está arriba como icono")
    _check(menu.get_node_or_null("SettingsButton") == null, "Ajustes ya no ocupa el encabezado y vive en Más")
    var more := menu.get_node_or_null("MoreButton") as Button
    _check(more != null, "Más opciones está como botón de tres puntos")
    if more != null:
        _check(more.text == "⋮", "Más opciones usa solo tres puntos")
        _check(more.position.x > play_button.size.x * 0.5, "Más opciones queda arriba a la derecha")
    var more_menu := menu.get_node_or_null("MoreMenu") as PopupMenu
    _check(more_menu != null, "Menú de tres puntos existe")
    if more_menu != null:
        var labels := []
        for i in range(more_menu.item_count):
            if not more_menu.is_item_separator(i):
                labels.append(more_menu.get_item_text(i))
        _check(labels.has("Club") and labels.has("Amigos") and labels.has("Ajustes") and labels.has("Rankings") and labels.has("Perfil"), "Menú de tres puntos contiene accesos secundarios")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/MÁS OPCIONES") == null, "Se eliminó la sección Más opciones del contenido")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/DailyGoal") != null, "El objetivo diario es una línea discreta")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/PrimaryBreathingRoom") != null, "Existe separación amplia tras las acciones principales")
    _check(menu.get_node_or_null("StreakLabel") != null, "La racha aparece junto al avatar")
    var nav := menu.get_node_or_null("MainNavigation")
    _check(nav != null, "navegación inferior existe")
    if nav != null:
        var labels := []
        for button in nav.get_node("Bar/Items").get_children():
            labels.append(button.text)
        _check(labels.any(func(v): return String(v).find("Inicio") >= 0), "navegación tiene Inicio")
        _check(labels.any(func(v): return String(v).find("Club") >= 0), "navegación reserva Club")
        _check(labels.any(func(v): return String(v).find("Amigos") >= 0), "navegación reserva Amigos")
        _check(labels.any(func(v): return String(v).find("Más") >= 0), "navegación tiene Más")
    var play := menu.get_node("HomeScroll/HomeMargin/VBox/PlayButton") as Button
    play.emit_signal("pressed")
    await process_frame
    _check(menu.get_node("HomeScroll/HomeMargin/VBox/PlayMenu").visible, "Jugar abre menú compacto")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/PlayMenu/PlayOptions/Play1c1") != null, "menú Jugar contiene 1c1")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/PlayMenu/PlayOptions/Play2c2") != null, "menú Jugar contiene 2c2")
    _check(menu.get_node_or_null("HomeScroll/HomeMargin/VBox/PlayMenu/PlayOptions/PlayLocal") != null, "menú Jugar contiene Local")
    var scroll := menu.get_node("HomeScroll") as ScrollContainer
    _check(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "scroll vertical es automático")
    _check(menu.get_node("Margin/VBox/2c2").visible == false, "compatibilidad 2c2 no invade la interfaz")
    _check(menu.get_node("Margin/VBox/1c1").visible == false, "compatibilidad 1c1 no invade la interfaz")
    menu.queue_free()
    await process_frame
    print("HOME SCROLL V69: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
