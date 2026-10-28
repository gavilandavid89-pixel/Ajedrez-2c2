extends SceneTree

const Matchmaking = preload("res://domain/competitive/matchmaking_logic.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    _check(Matchmaking.search_range(0.0) == 100, "initial range is ±100")
    _check(Matchmaking.search_range(1.9) == 100, "range stays initial before 2 seconds")
    _check(Matchmaking.search_range(2.0) == 150, "range widens after 2 seconds")
    _check(Matchmaking.search_range(10.0) == 350, "range widens progressively")
    _check(Matchmaking.search_range(30.0) == 400, "range has a maximum")
    _check(Matchmaking.compatible(1000, 1100, 0.0), "candidate at range edge matches")
    _check(not Matchmaking.compatible(1000, 1101, 0.0), "candidate outside initial range does not match")
    _check(Matchmaking.compatible(1000, 1200, 6.0), "widened range accepts broader candidate")
    print("MATCHMAKING RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
