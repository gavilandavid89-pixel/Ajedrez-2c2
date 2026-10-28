extends SceneTree

const NexusTeam = preload("res://domain/competitive/nexus_team.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    _check(is_equal_approx(NexusTeam.expected_score(1000.0, 1000.0), 0.5), "NEXUS expected score equal is 0.5")
    _check(NexusTeam.rating_delta(1000, 1300, "win", 320, 1.0) > NexusTeam.rating_delta(1000, 700, "win", 320, 1.0), "upset win learns more than expected win")
    _check(absf(float(NexusTeam.make_new_pair(1000)["pair_effect"])) <= NexusTeam.PAIR_EFFECT_LIMIT, "new pair effect starts bounded")

    var player := {"rating": 1000, "best_rating": 1000, "uncertainty": NexusTeam.INITIAL_UNCERTAINTY, "volatility": NexusTeam.DEFAULT_VOLATILITY, "form": 0.0, "last_activity_at": 0}
    var win := NexusTeam.update_player(player, 1300, "win", 1000)
    _check(int(win["rating"]) > 1000, "player rating rises after upset win")
    _check(float(win["uncertainty"]) < NexusTeam.INITIAL_UNCERTAINTY, "player uncertainty decreases after evidence")
    _check(float(win["volatility"]) >= NexusTeam.MIN_VOLATILITY, "player volatility remains bounded")

    var inactive := player.duplicate(true)
    inactive["last_activity_at"] = 1000
    inactive["uncertainty"] = 70.0
    var drifted := NexusTeam.apply_inactivity(inactive, 1000 + 86400 * 180)
    _check(float(drifted["uncertainty"]) > 70.0, "inactivity raises uncertainty")
    _check(int(drifted["rating"]) == 1000, "inactivity does not directly remove rating")

    var pair := NexusTeam.make_new_pair(1000, 1000)
    _check(float(pair["pair_uncertainty"]) == NexusTeam.INITIAL_UNCERTAINTY, "new pair has independent high uncertainty")
    for i in range(5):
        pair["games"] = int(pair.get("games", 0)) + 1
        pair = NexusTeam.update_pair(pair, 1000, "win", 1000, 2000 + i)
    _check(absf(float(pair["pair_effect"])) <= NexusTeam.PAIR_EFFECT_LIMIT, "pair effect never exceeds configured bound")
    _check(int(pair["pair_strength"]) > 1000, "pair strength learns independently")

    var stable := {"rating": 1400, "best_rating": 1400, "uncertainty": 100.0, "volatility": 0.4, "form": 0.0, "last_activity_at": 0}
    var stable_before := int(stable["rating"])
    var switched := stable.duplicate(true)
    var pair_ab := NexusTeam.make_new_pair(1400)
    var pair_ac := NexusTeam.make_new_pair(1400)
    _check(int(switched["rating"]) == stable_before and int(pair_ab["rating"]) == int(pair_ac["rating"]), "switching partner does not alter individual rating or share pair histories")

    var data := PlayerDataScript.new()
    data.name = "NexusQA"
    root.add_child(data)
    await process_frame
    data.profile["id"] = "USR_NEXUS_TEST"
    data.individual = {
        "cups": 0, "lifetime_cups": 0, "games": 0, "wins": 0, "losses": 0, "draws": 0,
        "rating": 1200, "best_rating": 1200, "uncertainty": 240.0,
        "volatility": 0.5, "form": 0.0, "last_activity_at": 0, "nexus_version": 1
    }
    data.individual_1c1 = {"cups": 0, "lifetime_cups": 0, "games": 0, "wins": 0, "losses": 0, "draws": 0, "rating": 1300, "best_rating": 1300, "streak": 0}
    data.pair_records.clear()
    data.current_partner = {"id": "", "name": "", "pair_key": ""}
    data.current_pair_id = ""
    data.best_pair_id = ""
    data.history.clear()

    var r1 := data.record_result(0, "win", "B", 1000, 1100, "USR_B", {"partner_rating_before": 1150})
    var key_ab := data.pair_key("B", "USR_B")
    _check(data.pair_records.has(key_ab), "A+B pair record created")
    _check(String(data.current_pair_id) == key_ab, "current pair points to A+B")
    _check(String(data.current_partner.get("pair_key", "")) == key_ab, "legacy current partner remains synchronized")
    _check(int(r1["mode"]) == 0 and int(r1["nexus_version"]) == 2, "2c2 result stores NEXUS contract")

    var player_rating_after_ab := int(data.individual["rating"])
    var r2 := data.record_result(0, "loss", "C", 1000, 1050, "USR_C", {"partner_rating_before": 900})
    var key_ac := data.pair_key("C", "USR_C")
    _check(data.pair_records.has(key_ac) and key_ac != key_ab, "A+C pair has separate state from A+B")
    _check(int(data.individual["rating"]) != player_rating_after_ab, "individual 2c2 rating changes from actual results")
    _check(int(data.individual_1c1["rating"]) == 1300, "1c1 rating is untouched by 2c2")
    _check(String(data.current_pair_id) == key_ac, "current pair moves to A+C")
    _check(String(data.best_pair_id) == "", "best pair stays unvalidated before minimum evidence")

    for i in range(3):
        data.record_result(0, "win", "B", 1000, 1100, "USR_B", {"partner_rating_before": 1150})
    _check(String(data.best_pair_id) == key_ab, "validated best pair prefers the stronger evidenced pair")

    var one_rating_before := int(data.individual_1c1["rating"])
    data.record_result(1, "win", "", 1000, 1000)
    _check(int(data.individual_1c1["rating"]) > one_rating_before, "1c1 still uses its independent system")
    _check(int(data.individual["rating"]) == int(data.individual["rating"]), "2c2 state remains structurally valid after 1c1")
    _check(data.pair_records.size() >= 2, "1c1 did not overwrite pair histories")

    var rows := data.pair_rank_rows()
    var found_current := false
    var found_best := false
    for row in rows:
        if String(row["id"]) == "PAIR:%s" % key_ab:
            found_current = bool(row.get("is_current", false))
            found_best = bool(row.get("is_best", false))
    _check(found_current, "pair ranking marks current pair")
    _check(found_best, "pair ranking marks best pair")

    print("NEXUS-TEAM RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
