extends SceneTree

const GameState = preload("res://domain/chess/game_state.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var g := GameState.new()
    g.reset_match(g.MODE_2C2)
    _check(g.slot_profile_ids == ["you", "rival1", "mate", "rival2"], "2c2 asigna cuatro perfiles")
    _check(g.set_slot_profile(2, "you"), "perfil de slot puede reemplazarse")
    _check(g.slot_profile_ids[2] == "you", "perfil reemplazado queda guardado")
    _check(g.slot_owners[2] == "Jugador C", "el nombre interno no cambia si no se entrega nombre")
    _check(is_equal_approx(g.SUGGESTION_COOLDOWN, 2.0), "cooldown de sugerencia es 2s")
    _check(is_equal_approx(g.QUESTION_COOLDOWN, 2.0), "cooldown de cuestionar es 2s")
    g.reset_match(g.MODE_VS_BOT)
    _check(g.slot_profile_ids == ["you", "bot", "", ""], "VS IA oculta perfiles 2c2")
    _check(g.slot_profile_ids[1] == "bot", "VS IA usa perfil de bot")
    g.reset_match(g.MODE_1C1_LOCAL)
    _check(g.slot_profile_ids == ["local1", "local2", "", ""], "1c1 local usa perfiles locales")
    g.free()
    print("PROFILE UI RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
