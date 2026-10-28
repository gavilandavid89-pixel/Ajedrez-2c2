extends RefCounted

const EngineScript = preload("res://domain/bots/stockfish_engine.gd")

func run() -> Dictionary:
    var engine = EngineScript.new()
    var failures: Array[String] = []
    _check(failures, engine._engine_resource_path_for_arch("arm32") == "res://engine/stockfish/stockfish_android_arm32", "ARM32 selecciona su binario")
    _check(failures, engine._engine_resource_path_for_arch("armv7l") == "res://engine/stockfish/stockfish_android_arm32", "ARMv7 selecciona su binario")
    _check(failures, engine._engine_resource_path_for_arch("arm64") == "res://engine/stockfish/stockfish_android_arm64", "ARM64 selecciona su binario")
    _check(failures, engine._engine_resource_path_for_arch("aarch64") == "res://engine/stockfish/stockfish_android_arm64", "AArch64 selecciona su binario")
    _check(failures, engine._engine_resource_path_for_arch("x86_64").is_empty(), "x86_64 no recibe un binario ARM")
    _check(failures, engine._engine_resource_path_for_arch("").is_empty(), "arquitectura desconocida no activa fallback")
    _check(failures, not engine.is_available() or not engine._engine_runtime_path().is_empty(), "motor disponible solo con ABI reconocida")
    return {"passed": 7 - failures.size(), "failed": failures}

func _check(failures: Array[String], condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
