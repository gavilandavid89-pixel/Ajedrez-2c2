extends SceneTree

const SETUP_SCENE := preload("res://scenes/online_setup.tscn")
const AppConfig := preload("res://core/services/app.gd")

var passed := 0
var failed := 0

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        push_error("[FAIL] " + label)

func _initialize() -> void:
    var setup = SETUP_SCENE.instantiate()
    get_root().add_child(setup)
    await process_frame
    setup.open_for_mode(AppConfig.MODE_1C1)
    await process_frame
    var setup_hint: Label = setup.get_node("Modal/Main/HintTitle")
    _check("1c1" in setup_hint.text, "selector online 1c1 conserva su introducción")
    setup.open_for_mode(AppConfig.MODE_2C2)
    await process_frame
    _check(setup_hint.text == "Elige cómo quieres entrar a la partida.", "selector 2c2 conserva su introducción original")
    setup.queue_free()
    print("V57 1C1 PRESENTATION RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)
