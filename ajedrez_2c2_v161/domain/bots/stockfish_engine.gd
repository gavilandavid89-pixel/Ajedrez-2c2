extends RefCounted
class_name StockfishEngine

const ENGINE_RESOURCE := "res://engine/stockfish/stockfish_android_arm64"
const ENGINE_RUNTIME := "user://engine/stockfish_android_arm64"
const UCI_LINE_TIMEOUT_MS := 120000

var _ready := false
var _last_error := ""

func _file_size(path: String) -> int:
    if not FileAccess.file_exists(path):
        return 0
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return 0
    var size := file.get_length()
    file.close()
    return size

func is_available() -> bool:
    # get_length evita cargar el ejecutable nativo completo en RAM solo para
    # comprobar su presencia (importante en teléfonos con memoria limitada).
    return _file_size(ENGINE_RUNTIME) > 1000000 or _file_size(ENGINE_RESOURCE) > 1000000

func ensure_runtime_binary() -> bool:
    var runtime_path := ProjectSettings.globalize_path(ENGINE_RUNTIME)
    var runtime_size := _file_size(ENGINE_RUNTIME)
    if runtime_size > 1000000:
        var existing_chmod_output: Array = []
        var existing_chmod_code := OS.execute("chmod", ["+x", runtime_path], existing_chmod_output)
        if existing_chmod_code == 0:
            return true
        _last_error = "Stockfish existe, pero Android no permitió habilitar su ejecución."
        return false
    if FileAccess.file_exists(ENGINE_RUNTIME):
        DirAccess.remove_absolute(runtime_path)
    var source_size := _file_size(ENGINE_RESOURCE)
    if source_size <= 1000000:
        _last_error = "No se encontró el binario de Stockfish 19 para Android ARM64."
        return false
    var runtime_dir := runtime_path.get_base_dir()
    var dir_error := DirAccess.make_dir_recursive_absolute(runtime_dir)
    if dir_error != OK and not DirAccess.dir_exists_absolute(runtime_dir):
        _last_error = "No se pudo crear el directorio de ejecución de Stockfish."
        return false
    var source := FileAccess.open(ENGINE_RESOURCE, FileAccess.READ)
    if source == null:
        _last_error = "No se pudo abrir el binario de Stockfish incluido."
        return false
    var target := FileAccess.open(ENGINE_RUNTIME, FileAccess.WRITE)
    if target == null:
        source.close()
        _last_error = "No se pudo crear el archivo de ejecución de Stockfish."
        return false
    # Copia por bloques para no reservar decenas de megabytes de memoria de una
    # sola vez. Verifica el tamaño final para detectar copias interrumpidas.
    var copied := 0
    while not source.eof_reached():
        var chunk := source.get_buffer(1024 * 1024)
        if chunk.is_empty():
            break
        target.store_buffer(chunk)
        copied += chunk.size()
    source.close()
    target.close()
    if copied != source_size or _file_size(ENGINE_RUNTIME) != source_size:
        DirAccess.remove_absolute(runtime_path)
        _last_error = "La copia de Stockfish quedó incompleta; vuelve a intentarlo."
        return false
    var chmod_output: Array = []
    var chmod_code := OS.execute("chmod", ["+x", runtime_path], chmod_output)
    if chmod_code != 0:
        DirAccess.remove_absolute(runtime_path)
        _last_error = "No se pudo habilitar la ejecución de Stockfish en este dispositivo."
        return false
    return true

func analyze_positions(fens: Array[String], moves_uci: Array[String], depth: int = 12, multi_pv: int = 3) -> Dictionary:
    if fens.is_empty() or moves_uci.size() != fens.size():
        return {"ok": false, "error": "Datos de análisis incompletos.", "moves": []}
    # Valida los datos antes de arrancar el proceso nativo. Un replay corrupto
    # no debe poder inyectar comandos UCI ni dejar al usuario esperando el timeout.
    for i in range(fens.size()):
        if not _is_valid_fen(fens[i]):
            return {"ok": false, "error": "FEN inválido en la posición %d." % (i + 1), "moves": []}
        if not _is_valid_uci_move(moves_uci[i]):
            return {"ok": false, "error": "Jugada UCI inválida en la posición %d." % (i + 1), "moves": []}
    depth = clampi(depth, 1, 30)
    multi_pv = clampi(multi_pv, 1, 5)
    if not ensure_runtime_binary():
        return {"ok": false, "error": _last_error, "moves": []}
    return _analyze_with_binary(ProjectSettings.globalize_path(ENGINE_RUNTIME), fens, moves_uci, depth, multi_pv)

# Ejecuta un protocolo UCI secuencial: cada búsqueda termina en bestmove antes
# de enviar la siguiente posición. Así no se cancelan búsquedas ni se mezclan
# las evaluaciones de jugadas distintas.
func _analyze_with_binary(engine_path: String, fens: Array[String], moves_uci: Array[String], depth: int, multi_pv: int) -> Dictionary:
    var process: Dictionary = OS.execute_with_pipe(engine_path, [], false)
    if process.is_empty() or not process.has("stdio") or not process.has("pid"):
        _last_error = "No se pudo iniciar Stockfish mediante el protocolo UCI."
        return {"ok": false, "error": _last_error, "moves": []}

    var output: FileAccess = process["stdio"]
    var pid: int = int(process["pid"])
    var stderr_pipe: FileAccess = process.get("stderr", null)
    output.store_line("uci")
    output.flush()
    if not _wait_for_token(output, pid, "uciok"):
        _stop_engine(output, stderr_pipe, pid)
        _last_error = "Stockfish no respondió al saludo UCI."
        return {"ok": false, "error": _last_error, "moves": []}

    output.store_line("setoption name Threads value 1")
    output.store_line("setoption name Hash value 32")
    output.store_line("setoption name MultiPV value %d" % clampi(multi_pv, 1, 5))
    output.store_line("isready")
    output.flush()
    if not _wait_for_token(output, pid, "readyok"):
        _stop_engine(output, stderr_pipe, pid)
        _last_error = "Stockfish no quedó listo para analizar."
        return {"ok": false, "error": _last_error, "moves": []}

    var results: Array = []
    for i in range(fens.size()):
        var fen := fens[i].strip_edges()
        var played_move := moves_uci[i].strip_edges()
        if not _is_valid_fen(fen) or not _is_valid_uci_move(played_move):
            _stop_engine(output, stderr_pipe, pid)
            _last_error = "La posición %d no tiene FEN o jugada UCI válida." % (i + 1)
            return {"ok": false, "error": _last_error, "moves": results}

        output.store_line("setoption name MultiPV value %d" % clampi(multi_pv, 1, 5))
        output.store_line("isready")
        output.flush()
        if not _wait_for_token(output, pid, "readyok"):
            _stop_engine(output, stderr_pipe, pid)
            _last_error = "Stockfish no confirmó MultiPV antes de la posición %d." % (i + 1)
            return {"ok": false, "error": _last_error, "moves": results}
        output.store_line("position fen %s" % fen)
        output.store_line("go depth %d" % maxi(1, depth))
        output.flush()
        var best_search := _read_search_result(output, pid)
        if not bool(best_search.get("ok", false)):
            _stop_engine(output, stderr_pipe, pid)
            _last_error = "Stockfish no completó la búsqueda principal en la jugada %d." % (i + 1)
            return {"ok": false, "error": _last_error, "moves": results}

        output.store_line("setoption name MultiPV value 1")
        output.store_line("isready")
        output.flush()
        if not _wait_for_token(output, pid, "readyok"):
            _stop_engine(output, stderr_pipe, pid)
            _last_error = "Stockfish no confirmó el cambio de opciones."
            return {"ok": false, "error": _last_error, "moves": results}

        output.store_line("position fen %s" % fen)
        output.store_line("go depth %d searchmoves %s" % [maxi(1, depth), played_move])
        output.flush()
        var played_search := _read_search_result(output, pid)
        if not bool(played_search.get("ok", false)):
            _stop_engine(output, stderr_pipe, pid)
            _last_error = "Stockfish no evaluó la jugada jugada %d." % (i + 1)
            return {"ok": false, "error": _last_error, "moves": results}

        var alternatives: Array = best_search.get("alternatives", [])
        var best: Dictionary = alternatives[0].duplicate(true) if not alternatives.is_empty() else {}
        best["bestmove"] = String(best_search.get("bestmove", ""))
        var played: Dictionary = played_search.get("score_line", {}).duplicate(true)
        played["bestmove"] = String(played_search.get("bestmove", ""))
        results.append({"best": best, "alternatives": alternatives, "played": played})

    output.store_line("quit")
    output.flush()
    _stop_engine(output, stderr_pipe, pid)
    return {"ok": true, "error": "", "moves": results, "engine": "Stockfish 19", "depth": depth, "multi_pv": clampi(multi_pv, 1, 5)}

func _read_search_result(output: FileAccess, pid: int) -> Dictionary:
    var scores: Dictionary = {}
    var best_move := ""
    var deadline: int = Time.get_ticks_msec() + UCI_LINE_TIMEOUT_MS
    while Time.get_ticks_msec() < deadline:
        var line := _read_uci_line(output, pid, deadline)
        if line.is_empty():
            if not OS.is_process_running(pid):
                break
            continue
        if line.begins_with("info ") and line.contains(" score "):
            var parsed := _parse_score_line(line)
            if not parsed.is_empty():
                scores[int(parsed.get("multipv", 1))] = parsed
        elif line.begins_with("bestmove "):
            var parts := line.split(" ", false)
            best_move = String(parts[1]) if parts.size() > 1 else ""
            break
    if best_move.is_empty() or scores.is_empty():
        return {"ok": false, "bestmove": best_move, "alternatives": [], "score_line": {}}
    var ordered: Array = []
    for key in scores.keys():
        ordered.append(scores[key])
    ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("multipv", 1)) < int(b.get("multipv", 1)))
    return {"ok": true, "bestmove": best_move, "alternatives": ordered, "score_line": ordered[0]}

func _wait_for_token(output: FileAccess, pid: int, token: String) -> bool:
    var deadline: int = Time.get_ticks_msec() + 15000
    while Time.get_ticks_msec() < deadline:
        var line := _read_uci_line(output, pid, deadline)
        if line == token:
            return true
        if line.is_empty() and not OS.is_process_running(pid):
            return false
    return false

func _read_uci_line(output: FileAccess, pid: int, deadline: int) -> String:
    while Time.get_ticks_msec() < deadline:
        var line := output.get_line()
        if not line.is_empty():
            return line.strip_edges()
        if not OS.is_process_running(pid):
            # Permite una última lectura de datos ya almacenados en el pipe.
            var final_line := output.get_line()
            return final_line.strip_edges()
        OS.delay_msec(2)
    return ""

func _stop_engine(output: FileAccess, stderr_pipe: FileAccess, pid: int) -> void:
    if OS.is_process_running(pid) and is_instance_valid(output):
        output.store_line("stop")
        output.store_line("quit")
        output.flush()
    var deadline: int = Time.get_ticks_msec() + 1000
    while OS.is_process_running(pid) and Time.get_ticks_msec() < deadline:
        OS.delay_msec(5)
    if is_instance_valid(output):
        output.close()
    if is_instance_valid(stderr_pipe):
        stderr_pipe.close()
    if OS.is_process_running(pid):
        OS.kill(pid)

func _parse_score_line(line: String) -> Dictionary:
    var parts := line.split(" ", false)
    var idx := parts.find("score")
    if idx < 0 or idx + 2 >= parts.size():
        return {}
    var kind := parts[idx + 1]
    var value := int(parts[idx + 2])
    var score := 0.0
    if kind == "cp":
        score = float(value) / 100.0
    elif kind == "mate":
        # Mantiene la distancia de mate: mate en 1 debe ser mejor que mate en 5,
        # y si estamos perdidos se prefiere retrasar el mate. La escala sigue
        # siendo compatible con el cálculo de pérdida en centipeones del revisor.
        var sign := 1.0 if value > 0 else -1.0
        score = sign * (1000.0 - float(abs(value)))
    else:
        return {}
    var result := {"score": score, "score_type": kind, "raw": value}
    var mpv_idx := parts.find("multipv")
    if mpv_idx >= 0 and mpv_idx + 1 < parts.size():
        result["multipv"] = int(parts[mpv_idx + 1])
    var pv_idx := parts.find("pv")
    if pv_idx >= 0 and pv_idx + 1 < parts.size():
        result["pv"] = parts.slice(pv_idx + 1)
    return result


func _is_valid_uci_move(move: String) -> bool:
    # Solo coordenadas UCI de una jugada normal o promoción; no acepta espacios,
    # saltos de línea ni texto que pudiera convertirse en otra orden del motor.
    if move.length() != 4 and move.length() != 5:
        return false
    var chars := move.to_lower()
    if chars.unicode_at(0) < 97 or chars.unicode_at(0) > 104:
        return false
    if chars.unicode_at(1) < 49 or chars.unicode_at(1) > 56:
        return false
    if chars.unicode_at(2) < 97 or chars.unicode_at(2) > 104:
        return false
    if chars.unicode_at(3) < 49 or chars.unicode_at(3) > 56:
        return false
    if chars.length() == 5 and not "qrbn".contains(chars.substr(4, 1)):
        return false
    return true

func _is_valid_fen(fen: String) -> bool:
    if fen.is_empty() or fen.contains("\n") or fen.contains("\r") or fen.contains("\t"):
        return false
    var fields := fen.split(" ", false)
    if fields.size() != 6:
        return false
    var ranks := fields[0].split("/", false)
    if ranks.size() != 8:
        return false
    const PIECES := "prnbqkPRNBQK"
    var white_kings := 0
    var black_kings := 0
    for rank in ranks:
        var files := 0
        for i in range(rank.length()):
            var ch := rank.substr(i, 1)
            if ch >= "1" and ch <= "8":
                files += int(ch)
            elif PIECES.contains(ch):
                files += 1
                if ch == "K": white_kings += 1
                if ch == "k": black_kings += 1
            else:
                return false
        if files != 8:
            return false
    if white_kings != 1 or black_kings != 1:
        return false
    if fields[1] != "w" and fields[1] != "b":
        return false
    if fields[2] != "-":
        for i in range(fields[2].length()):
            if not "KQkq".contains(fields[2].substr(i, 1)):
                return false
        for right in ["K", "Q", "k", "q"]:
            if fields[2].count(right) > 1:
                return false
    if fields[3] != "-":
        if fields[3].length() != 2 or fields[3].substr(0, 1) < "a" or fields[3].substr(0, 1) > "h" or not ["3", "6"].has(fields[3].substr(1, 1)):
            return false
    if not fields[4].is_valid_int() or not fields[5].is_valid_int():
        return false
    if int(fields[4]) < 0 or int(fields[5]) < 1:
        return false
    return true

func last_error() -> String:
    return _last_error
