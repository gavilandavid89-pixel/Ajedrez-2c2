extends SceneTree

func _init() -> void:
    var test_script = preload("res://tests/modular_architecture_tests.gd")
    var test = test_script.new()
    var result: Dictionary = test.run()
    for failure in result.get("failures", []):
        print("[FAIL] ", failure)
    print("MODULAR ARCHITECTURE: %d checks / %d failures" % [int(result.get("checks", 0)), int(result.get("failures", []).size())])
    quit(1 if not result.get("failures", []).is_empty() else 0)
