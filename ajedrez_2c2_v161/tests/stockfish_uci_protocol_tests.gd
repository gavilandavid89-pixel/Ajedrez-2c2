extends RefCounted

const EngineScript = preload("res://domain/bots/stockfish_engine.gd")

func run() -> Dictionary:
    var fake_path := ProjectSettings.globalize_path("user://fake_stockfish_uci.sh")
    var script := FileAccess.open("user://fake_stockfish_uci.sh", FileAccess.WRITE)
    if script == null:
        return {"passed": 0, "failed": ["crear motor UCI simulado"]}
    script.store_string("""#!/bin/sh
while IFS= read -r cmd; do
  case "$cmd" in
    uci) echo 'id name FakeStockfish'; echo 'uciok' ;;
    isready) echo 'readyok' ;;
    *searchmoves*)
      move=${cmd##*searchmoves }
      echo "info depth 4 score cp 15 multipv 1 pv $move"
      echo "bestmove $move"
      ;;
    go*)
      echo 'info depth 4 score cp 30 multipv 1 pv e2e4'
      echo 'info depth 4 score cp 20 multipv 2 pv d2d4'
      echo 'bestmove e2e4'
      ;;
    quit) exit 0 ;;
  esac
done
""")
    script.close()
    var chmod_output: Array = []
    var chmod_code := OS.execute("chmod", ["+x", fake_path], chmod_output)
    if chmod_code != 0:
        DirAccess.remove_absolute(fake_path)
        return {"passed": 0, "failed": ["dar permisos al motor UCI simulado"]}

    var engine = EngineScript.new()
    var fens: Array[String] = ["8/8/8/8/8/8/4P3/4K2k w - - 0 1", "8/8/8/8/8/8/4P3/4K2k w - - 0 1"]
    var moves: Array[String] = ["e2e4", "d2d4"]
    var result: Dictionary = engine._analyze_with_binary(fake_path, fens, moves, 4, 2)
    DirAccess.remove_absolute(fake_path)
    var failures: Array[String] = []
    var mate_one: Dictionary = engine._parse_score_line("info depth 12 score mate 1 pv e2e4")
    var mate_five: Dictionary = engine._parse_score_line("info depth 12 score mate 5 pv e2e4")
    var losing_mate_one: Dictionary = engine._parse_score_line("info depth 12 score mate -1 pv e2e4")
    var losing_mate_five: Dictionary = engine._parse_score_line("info depth 12 score mate -5 pv e2e4")
    if not (float(mate_one.get("score", 0.0)) > float(mate_five.get("score", 0.0))):
        failures.append("mate más cercano debe puntuar mejor que mate lejano")
    if not (float(losing_mate_five.get("score", 0.0)) > float(losing_mate_one.get("score", 0.0))):
        failures.append("si se pierde, retrasar el mate debe puntuar mejor")
    var bad_fen: Array[String] = ["8/8/8/8/8/8/8/8 w - - 0 1"]
    var bad_fen_result: Dictionary = engine.analyze_positions(bad_fen, ["e2e4"])
    if bool(bad_fen_result.get("ok", false)):
        failures.append("FEN sin reyes debe rechazarse antes de iniciar el motor")
    var injected_move: Array[String] = ["e2e4\nquit"]
    var bad_move_result: Dictionary = engine.analyze_positions([fens[0]], injected_move)
    if bool(bad_move_result.get("ok", false)):
        failures.append("jugada con texto adicional debe rechazarse")
    if not bool(result.get("ok", false)):
        failures.append("protocolo UCI termina búsquedas: " + String(result.get("error", "sin detalle")))
    else:
        var rows: Array = result.get("moves", [])
        if rows.size() != 2:
            failures.append("una respuesta por posición")
        else:
            if String(rows[0].get("best", {}).get("bestmove", "")) != "e2e4":
                failures.append("mejor jugada principal conservada")
            if String(rows[1].get("played", {}).get("bestmove", "")) != "d2d4":
                failures.append("jugada del usuario asociada a su posición")
            if not is_equal_approx(float(rows[0].get("best", {}).get("score", 0.0)), 0.30):
                failures.append("evaluación principal parseada")
            if not is_equal_approx(float(rows[0].get("played", {}).get("score", 0.0)), 0.15):
                failures.append("evaluación de la jugada jugada parseada")
            if Array(rows[0].get("alternatives", [])).size() != 2:
                failures.append("variantes MultiPV conservadas")
    return {"passed": 9 - failures.size(), "failed": failures}
