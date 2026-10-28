extends RefCounted

const GameReviewServiceScript = preload("res://domain/replay/game_review_service.gd")
const TacticalCommentaryScript = preload("res://domain/replay/review_tactical_commentary.gd")

func run() -> Dictionary:
    var passed := [0]
    var failed: Array[String] = []
    var service := GameReviewServiceScript.new()

    var initial := {
        "board": "rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR",
        "castling": "KQkq",
        "ep": [-1, -1],
        "turn": 0,
    }
    var second := {
        "board": "rnbqkbnrpppppppp....................P...........PPPP.PPPRNBQKBNR",
        "castling": "KQkq",
        "ep": [4, 5],
        "turn": 1,
    }
    var fen := service._state_to_fen(service._decode_state(initial), 0)
    _check(fen == "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", "FEN inicial correcto", passed, failed)
    var fen2 := service._state_to_fen(service._decode_state(second), 1)
    _check(fen2.begins_with("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3"), "FEN de posición posterior correcto", passed, failed)
    _check(service._move_to_uci({"from":"e2","to":"e4"}) == "e2e4", "Conversión UCI normal", passed, failed)
    _check(service._move_to_uci({"from":"e7","to":"e8","promotion":"dama"}) == "e7e8q", "Conversión UCI con promoción", passed, failed)
    var parsed := service.engine._parse_score_line("info depth 14 multipv 2 score cp 37 nodes 123 pv e2e4 e7e5")
    _check(int(parsed.get("multipv", 0)) == 2 and is_equal_approx(float(parsed.get("score", 0.0)), 0.37), "Parser UCI MultiPV", passed, failed)
    var mate_one := service.engine._parse_score_line("info depth 20 score mate 1 pv d1h5")
    var mate_five := service.engine._parse_score_line("info depth 20 score mate 5 pv d1h5 a7a6")
    var delay_mate_one := service.engine._parse_score_line("info depth 20 score mate -1 pv d1h5")
    var delay_mate_five := service.engine._parse_score_line("info depth 20 score mate -5 pv d1h5 a7a6")
    _check(float(mate_one.get("score", 0.0)) > float(mate_five.get("score", 0.0)), "Mate en 1 se valora por encima de mate en 5", passed, failed)
    _check(float(delay_mate_five.get("score", 0.0)) > float(delay_mate_one.get("score", 0.0)), "En posición perdida, retrasar el mate se valora mejor", passed, failed)
    _check(service._centipawn_loss(mate_one, mate_five, 0) >= 300.0, "Diferencia mate en 1 vs mate en 5 no queda clasificada como jugada excelente", passed, failed)
    _check(service._classify_loss(0.0) == "Excelente", "Clasificación de pérdida cero", passed, failed)
    _check(service._classify_loss(300.0) == "Error grave", "Clasificación de pérdida alta", passed, failed)

    var sacrifice_board := {
        "board": [
            ["", "", "", "rey_negro", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "torre_blanca", "", "", "", ""],
            ["", "", "", "rey_blanca", "", "", "", ""],
        ]
    }
    _check(service._is_piece_sacrifice_candidate(sacrifice_board, {"from":"d2", "to":"d7"}), "Detecta candidato a sacrificio de torre", passed, failed)
    var brilliant := service._classify_move(sacrifice_board, {"from":"d2", "to":"d7"}, {"score":1.0, "bestmove":"d2d7"}, {"score":0.9}, [{"score":1.0}, {"score":0.7}], 10.0)
    _check(String(brilliant.get("classification", "")) == "Brillante", "Brillante requiere sacrificio + jugada cercana a la mejor", passed, failed)
    var great := service._classify_move({"board":[]}, {"from":"a1","to":"a2"}, {"score":0.8,"bestmove":"a1a2"}, {"score":0.8}, [{"score":0.8},{"score":-0.5}], 0.0)
    _check(String(great.get("classification", "")) == "Genial", "Genial requiere diferencia clara frente a alternativas", passed, failed)

    var tactical := TacticalCommentaryScript.new()
    var capture_state := {"board": []}
    for y in range(8):
        var row: Array = []
        for x in range(8): row.append("")
        capture_state["board"].append(row)
    capture_state["board"][7][4] = "rey_blanca"
    capture_state["board"][0][4] = "rey_negro"
    capture_state["board"][3][3] = "caballo_negro"
    var tactical_result: Dictionary = tactical.build_commentary(capture_state, {"from":"e4", "to":"d5"}, {"bestmove":"e2e4", "pv":["e2e4", "e7e5"]}, {"pv":["e4d5", "h7h6"]}, [{"score":0.2}, {"score":-0.1}], 65.0)
    _check("caballo negro" in " ".join(tactical_result.get("notes", [])), "Coach táctico identifica la pieza capturada desde el tablero", passed, failed)
    _check(String(tactical_result.get("played_reply", "")) == "h7h6", "Coach táctico toma la respuesta de la variante de la jugada real", passed, failed)
    var tactical_source := FileAccess.get_file_as_string("res://domain/replay/game_review_service.gd")
    _check(tactical_source.contains("review_tactical_commentary.gd") and tactical_source.contains("\"tactical_report\": tactical_report"), "El análisis consume el módulo táctico independiente", passed, failed)

    var engine := service.engine
    _check(engine.is_available(), "El binario real de Stockfish está incluido", passed, failed)
    _check(FileAccess.file_exists("res://engine/stockfish/README.md"), "Documentación del motor presente", passed, failed)
    var review_source := FileAccess.get_file_as_string("res://domain/replay/replay_view_controller.gd")
    _check(review_source.contains("var has_commentary := not review.is_empty()") and review_source.contains("Variante:"), "Coach muestra comentarios y línea sugerida para cada jugada analizada", passed, failed)
    var service_source := FileAccess.get_file_as_string("res://domain/replay/game_review_service.gd")
    _check(service_source.contains("\"best_line\": best_line") and service_source.contains("Mejor alternativa del motor:"), "Informe vincula el comentario con la mejor jugada y la variante del motor", passed, failed)
    _check(review_source.contains("_board.set_state(_states[_index - 1])") and review_source.contains("func toggle_best_move()"), "Ver mejor jugada usa la posición anterior y una acción aislada", passed, failed)
    var layout_source := FileAccess.get_file_as_string("res://domain/replay/replay_view_layout_service.gd")
    _check(layout_source.contains("clampf(480.0 / maxf(1.0, window_width), 1.0, 1.20)"), "Escala móvil limitada para evitar desbordamientos de navegación", passed, failed)
    _check(layout_source.contains("host._coach_line") and layout_source.contains("host._best_move_button"), "La variante y la acción del coach viven en el servicio de layout", passed, failed)

    return {"passed": passed[0], "failed": failed, "total": passed[0] + failed.size()}

func _check(condition: bool, label: String, passed: Array, failed: Array[String]) -> void:
    if condition:
        passed[0] += 1
    else:
        failed.append(label)
