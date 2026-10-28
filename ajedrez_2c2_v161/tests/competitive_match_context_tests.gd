extends SceneTree

const MatchContext = preload("res://domain/competitive/match_context.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var ctx := MatchContext.snapshot(1420, 110.0, 0)
    ctx = MatchContext.with_opponents(ctx, 980, 1600, 1350, [980, 1040], ["R1", "R2"])
    _check(MatchContext.individual_opponent_rating(ctx) == 980, "individual rating uses explicit opponent snapshot")
    _check(MatchContext.pair_opponent_rating(ctx) == 1600, "pair rating uses explicit team snapshot")
    _check(MatchContext.partner_rating(ctx) == 1350, "partner rating uses explicit snapshot")

    var fallback := MatchContext.snapshot(1000, 320.0, 0)
    fallback.erase("opponent_rating")
    fallback.erase("opponent_pair_rating")
    fallback["opponent_ratings"] = [900, 1100]
    _check(MatchContext.individual_opponent_rating(fallback) == 1000, "individual fallback averages opponent ratings")
    _check(MatchContext.pair_opponent_rating(fallback) == 1000, "pair fallback refuses to invent a team rating from individuals")

    var data := PlayerDataScript.new()
    data.name = "ContextQA"
    root.add_child(data)
    await process_frame
    data.profile["id"] = "USR_CONTEXT_QA"
    data.individual = {"cups":0,"lifetime_cups":0,"games":0,"wins":0,"losses":0,"draws":0,"rating":1200,"best_rating":1200,"uncertainty":240.0,"volatility":0.5,"form":0.0,"last_activity_at":0,"nexus_version":2}
    data.individual_1c1 = {"cups":0,"lifetime_cups":0,"games":0,"wins":0,"losses":0,"draws":0,"rating":1200,"best_rating":1200,"streak":0}
    data.pair_records.clear()
    data.history.clear()

    var result := data.record_result(0, "win", "Partner", 900, 1400, "USR_PARTNER", {
        "competitive_match_context": ctx,
        "opponent_rating_before": 980,
        "opponent_pair_rating": 1600,
        "partner_rating_before": 1350,
    })
    _check(int(result["opponent_rating_before"]) == 980, "history preserves individual opponent rating")
    _check(int(result["opponent_pair_rating_before"]) == 1600, "history preserves pair opponent rating")
    _check(int(result["partner_rating_before"]) == 1350, "history preserves partner rating")
    _check(float(result["expected"]) > 0.5, "individual expectation uses the individual opponent rating")
    _check(float(result["pair_expected"]) < 0.5, "pair expectation uses the separate pair rating")

    var one_v_one := data.record_result(1, "win", "", 900, 1000, "", {
        "competitive_match_context": MatchContext.with_opponents(MatchContext.snapshot(1200, 240.0, 1), 1500, 0, 0)
    })
    _check(int(one_v_one["opponent_rating_before"]) == 1500, "1c1 also consumes resolved individual snapshot")

    print("MATCH CONTEXT RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
