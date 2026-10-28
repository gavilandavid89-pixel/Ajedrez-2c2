extends SceneTree

const GameScript := preload("res://domain/chess/game_state.gd")
const ResultScreenScript := preload("res://ui/components/game/game_match_result_screen.gd")
const ResultScene := preload("res://scenes/game_match_result_screen.tscn")
const FriendsScript := preload("res://domain/social/friends_service.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var game = GameScript.new()
    root.add_child(game)
    game.reset_match(0, 10)
    game.running = false
    game.winner_team = game.TEAM_WHITE
    game.winner_reason = "jaque mate"
    var entry := {
        "competitive": true,
        "cup_delta": 10,
        "pair_cup_delta": 10,
        "pair_rating_delta": 12,
        "pair_rating_after": 1012,
        "match_id": "TEST_RESULT",
    }
    var screen := ResultScene.instantiate()
    root.add_child(screen)
    await process_frame
    screen.configure(game, entry)
    _check(screen.find_child("Close", true, false) != null, "pantalla final tiene X para volver al tablero")
    _check(screen.find_child("ResultScroll", true, false) != null, "pantalla final usa scroll")
    _check(screen.find_child("Analyze", true, false) != null, "analizar está dentro del menú final")
    _check(screen.find_child("WinningTeam", true, false) != null, "equipo ganador se muestra como bloque")
    _check(screen.find_child("SharedCrown", true, false) != null, "ganadores comparten una sola corona grande")
    _check(screen.find_child("PlayersHistory", true, false) == null, "perfiles no contaminan la pantalla final")
    _check(screen.find_child("Rematch", true, false) != null, "ganador tiene aceptar/revancha reservado")
    _check(screen.find_child("Rematch", true, false).disabled, "aceptar queda gris hasta recibir revancha")
    _check(screen.find_child("NewGame", true, false) != null, "nueva partida aparece directamente al final")
    _check(screen.find_child("CupReward", true, false) != null and String(screen.find_child("CupReward", true, false).text).find("Copas") < 0, "copas se muestran solo como icono y numero")
    screen.set_rematch_requested(true)
    _check(not screen.find_child("Rematch", true, false).disabled, "aceptar se habilita al recibir revancha")
    _check(_contains_text(screen, "NEXUS de pareja") == false, "resultado no muestra NEXUS de pareja")
    screen.queue_free()
    var loser_screen := ResultScene.instantiate()
    root.add_child(loser_screen)
    await process_frame
    game.winner_team = game.TEAM_BLACK
    loser_screen.configure(game, entry)
    var rematch := loser_screen.find_child("Rematch", true, false) as Button
    _check(rematch != null and rematch.text == "REVANCHA" and not rematch.disabled, "perdedor puede pedir revancha")
    var plus := loser_screen.find_child("Player1", true, false)
    _check(plus != null, "icono de compañero mantiene espacio para + amigo")
    _check(loser_screen.find_child("SharedCrown", true, false) != null, "corona compartida también existe en resultado de derrota")
    loser_screen.queue_free()
    game.queue_free()
    print("MATCH RESULT V71: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
func _contains_text(node: Node, value: String) -> bool:
    if node is Label and String(node.text).find(value) >= 0:
        return true
    if node is Button and String(node.text).find(value) >= 0:
        return true
    for child in node.get_children():
        if _contains_text(child, value):
            return true
    return false

