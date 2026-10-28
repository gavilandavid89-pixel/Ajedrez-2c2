extends SceneTree

const NexusTeam = preload("res://domain/competitive/nexus_team.gd")
const MatchContext = preload("res://domain/competitive/match_context.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")
const ClubChatServiceScript = preload("res://domain/social/club_chat_service.gd")
const ClubsServiceScript = preload("res://domain/social/clubs_service.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    _check(is_equal_approx(NexusTeam.PLAYER_K_MAX, 34.0), "NEXUS PLAYER_K_MAX matches player_k cap")
    var k := NexusTeam.player_k(NexusTeam.INITIAL_UNCERTAINTY, NexusTeam.MAX_VOLATILITY)
    _check(k <= NexusTeam.PLAYER_K_MAX and k >= NexusTeam.PLAYER_K_MIN, "player_k stays inside declared bounds")

    var ctx := MatchContext.snapshot(1200, 180.0, 0)
    var resolved := MatchContext.with_opponents(ctx, 900, 1600, 1300, [900, 1100], ["R1", "R2"])
    _check(MatchContext.individual_opponent_rating(resolved) == 900, "resolved individual opponent rating wins over array")
    _check(MatchContext.pair_opponent_rating(resolved) == 1600, "resolved pair rating is explicit")

    var array_only := MatchContext.snapshot(1200, 180.0, 0)
    array_only = MatchContext.with_opponents(array_only, 0, 0, 0, [900, 1100], ["R1", "R2"])
    _check(MatchContext.individual_opponent_rating(array_only) == 1000, "array-only context still averages individual opponents")
    _check(MatchContext.pair_opponent_rating(array_only) == 1000, "array-only context never invents a pair rating")
    _check(MatchContext.partner_rating(MatchContext.snapshot(1500, 180.0, 0)) == 1000, "missing partner snapshot uses neutral rating fallback")

    var data := PlayerDataScript.new()
    data.name = "ConsistencyQA"
    root.add_child(data)
    await process_frame
    data.profile["id"] = "USR_CONSISTENCY_QA"
    data.history.clear()
    data.history.append({"mode":0,"timestamp":1_000,"competitive":true,"pair_key":"pair:USR_CONSISTENCY_QA:USR_PARTNER"})
    data.history.append({"mode":1,"timestamp":2_000,"competitive":true})
    data.individual["last_activity_at"] = 0
    data.individual_1c1["last_activity_at"] = 0
    data.individual["nexus_version"] = 2
    data.individual_1c1["nexus_version"] = 2
    data.pair_records = {
        "pair:USR_CONSISTENCY_QA:USR_PARTNER": {
            "partner_id":"USR_PARTNER",
            "partner_name":"Partner",
            "games":3,
            "last_activity_at":0,
        }
    }
    data._normalize_nexus_state()
    data._normalize_1c1_stats()
    data._normalize_pairs()
    _check(int(data.individual.get("last_activity_at", 0)) == 1_000, "2c2 activity recovers from retained history")
    _check(int(data.individual_1c1.get("last_activity_at", 0)) == 2_000, "1c1 activity recovers from retained history")
    _check(int(data.pair_records["pair:USR_CONSISTENCY_QA:USR_PARTNER"].get("last_activity_at", 0)) == 1_000, "pair activity recovers from pair history")

    var identity := get_root().get_node_or_null("PlayerData")
    if identity == null:
        identity = PlayerDataScript.new()
        identity.name = "PlayerData"
        root.add_child(identity)
        await process_frame
    var previous_name := String(identity.profile.get("name", "Tú"))
    identity.profile["name"] = "Nombre Real"
    var club_chat := ClubChatServiceScript.new()
    root.add_child(club_chat)
    var challenge := club_chat.create_challenge("club_audit", "1c1")
    _check(String(challenge.get("sender", "")) == "Nombre Real", "club challenge uses current profile identity")
    _check(String(club_chat.get_messages("club_audit")[0].get("author", "")) == "Nombre Real", "club challenge message uses current profile identity")
    var team_challenge := club_chat.create_challenge("club_audit", "2c2")
    var team_id := String(team_challenge.get("id", ""))
    _check(club_chat.accept_challenge("club_audit", team_id, "USR_A"), "2c2 accepts first additional participant")
    _check(club_chat.accept_challenge("club_audit", team_id, "USR_B"), "2c2 accepts second additional participant")
    _check(club_chat.accept_challenge("club_audit", team_id, "USR_C"), "2c2 accepts third additional participant")
    var accepted_team_challenge := club_chat._find_challenge("club_audit", team_id)
    var team_matches := club_chat.get_watchable_matches("club_audit")
    _check(accepted_team_challenge.get("slots", []).size() == 4 and accepted_team_challenge.get("slots", []).all(func(id): return not String(id).is_empty()), "2c2 stores creator plus three accepted participants")
    _check(team_matches.is_empty() and String(accepted_team_challenge.get("status", "")) == "pending", "2c2 waits for explicit team assignments before starting")
    _check(not club_chat.accept_challenge("club_audit", team_id, "USR_C"), "challenge rejects duplicate acceptance")

    var clubs := ClubsServiceScript.new()
    root.add_child(clubs)
    var created := clubs.create_club("Club Audit", "♟", "", "public", 0)
    _check(String(created.get("founder", "")) == "Nombre Real", "new club stores current profile identity")
    identity.profile["name"] = previous_name

    print("CONSISTENCY AUDIT RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)