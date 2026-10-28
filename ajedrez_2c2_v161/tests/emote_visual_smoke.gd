extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")

var failed := 0

func _initialize() -> void:
    var game = GAME_SCENE.instantiate()
    root.add_child(game)
    await process_frame
    await process_frame
    game.hud._toggle_emotes()
    await process_frame
    var panel = game.hud.get_node("EmotePicker")
    _check(panel.visible, "selector de reacciones se abre")
    var visible_buttons := 0
    var grid = panel.get_node_or_null("Body/Grid")
    if grid != null:
        for child in grid.get_children():
            if child is Button and child.visible:
                visible_buttons += 1
    else:
        _check(false, "grid de reacciones existe")
    _check(visible_buttons <= 6, "el selector muestra como máximo las equipadas")
    game.hud._toggle_emotes()
    await process_frame
    _check(not panel.visible, "selector de reacciones se cierra")
    print("EMOTE VISUAL SMOKE: %d OK / %d FALLARON" % [3 - failed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if not value:
        failed += 1
        push_error("[FALLA] " + label)
    else:
        print("[OK] " + label)
