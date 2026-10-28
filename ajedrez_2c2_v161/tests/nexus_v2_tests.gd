extends SceneTree

const Nexus = preload("res://domain/competitive/nexus_team.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    _check(Nexus.NEXUS_VERSION == 2, "NEXUS version is 2")
    var state := {
        "rating": 1000,
        "best_rating": 1000,
        "uncertainty": Nexus.INITIAL_UNCERTAINTY,
        "volatility": Nexus.DEFAULT_VOLATILITY,
        "form": 0.0,
        "last_activity_at": 100,
    }
    var after := Nexus.update_player(state, 1000, "win", 200)
    _check(int(after["rating"]) > 1000, "equal-rated win raises NEXUS")
    _check(float(after["uncertainty"]) < Nexus.INITIAL_UNCERTAINTY, "uncertainty decreases after evidence")
    _check(float(after["confidence"]) > 0.0, "confidence is stored")
    _check(float(after["form"]) > 0.0, "form reacts to result")

    var ten := state.duplicate(true)
    ten["last_activity_at"] = 0
    for i in range(10):
        ten = Nexus.update_player(ten, 1000, "win" if i % 2 == 0 else "loss", i + 1)
    _check(float(ten["uncertainty"]) > 80.0, "uncertainty remains useful after 10 games")

    var inactive := ten.duplicate(true)
    inactive["form"] = 1.0
    inactive["last_activity_at"] = 1
    var decayed := Nexus.apply_inactivity(inactive, 31 * 86400 + 1)
    _check(float(decayed["form"]) < 0.55, "form decays during inactivity")
    _check(float(decayed["uncertainty"]) >= float(ten["uncertainty"]), "inactivity restores uncertainty")

    var pair := Nexus.make_new_pair(1000, 1)
    pair["pair_effect"] = 80.0
    pair["pair_uncertainty"] = 70.0
    var stale_pair := Nexus.apply_pair_inactivity(pair, 1 + 90 * 86400)
    _check(float(stale_pair["pair_uncertainty"]) > 70.0, "pair inactivity restores uncertainty")
    _check(absf(float(stale_pair["pair_effect"])) < 80.0, "pair synergy decays during inactivity")

    print("NEXUS V2 RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
