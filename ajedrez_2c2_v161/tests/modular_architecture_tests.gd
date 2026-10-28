extends RefCounted

func run() -> Dictionary:
    var checks := 0
    var failures: Array[String] = []
    var must_exist := [
        "res://core/services/app.gd",
        "res://core/navigation/screen_catalog.gd",
        "res://core/navigation/navigation_service.gd",
        "res://core/theme/theme_tokens.gd",
        "res://core/theme/theme_service.gd",
        "res://domain/chess/game_state.gd",
        "res://domain/chess/game_social_service.gd",
        "res://domain/chess/game_match_lifecycle_service.gd",
        "res://domain/chess/game_move_service.gd",
        "res://domain/chess/game_bot_service.gd",
        "res://tests/module_contracts_v67_tests.gd",
        "res://tests/social_contract_v70_tests.gd",
        "res://domain/replay/match_replay_state_service.gd",
        "res://domain/competitive/nexus_team.gd",
        "res://domain/player/player_data.gd",
        "res://ui/components/game/game_chat_controller.gd",
        "res://ui/components/game/game_chat_panel.gd",
        "res://ui/screens/game_hud.gd",
        "res://ui/components/account_page_renderer.gd",
        "res://ui/components/game/game_hud_layout.gd",
        "res://domain/player/player_customization_service.gd",
        "res://domain/player/player_persistence_service.gd",
        "res://domain/player/player_competitive_service.gd",
        "res://domain/player/player_history_service.gd",
        "res://domain/player/player_ranking_service.gd",
        "res://domain/replay/match_replay_view.gd",
        "res://domain/replay/replay_board.gd",
        "res://domain/replay/replay_view_controller.gd",
        "res://domain/replay/replay_view_layout_service.gd",
        "res://ui/components/game/game_input_controller.gd",
        "res://ui/components/game/piece_move_animator.gd",
        "res://ui/components/game/game_bot_coordinator.gd",
        "res://ui/components/game/game_match_result_service.gd",
        "res://ui/components/game/game_flow_controller.gd",
        "res://core/services/storage_file_service.gd",
        "res://core/services/storage_profile_service.gd",
        "res://core/services/storage_cache_service.gd",
        "res://core/services/storage_sync_service.gd",
        "res://MODULE_ARCHITECTURE.md",
        "res://scenes/local_setup.tscn",
        "res://ui/screens/local_setup.gd",
        "res://domain/social/friends_service.gd",
        "res://domain/social/clubs_service.gd",
        "res://domain/social/club_chat_service.gd",
        "res://domain/social/social_contract.gd",
        "res://ui/components/social/social_ui_factory.gd",
        "res://ui/screens/more_screen.gd",
        "res://ui/screens/friends_screen.gd",
        "res://ui/screens/club_browser_screen.gd",
        "res://ui/screens/club_detail_screen.gd",
        "res://ui/screens/club_create_screen.gd",
        "res://ui/screens/club_chat_screen.gd",
    ]
    for path in must_exist:
        checks += 1
        var exists := false
        if path.ends_with(".md"):
            exists = FileAccess.file_exists(path)
        else:
            exists = ResourceLoader.exists(path)
        if not exists:
            failures.append("missing: %s" % path)
    # Productive scripts must live inside an explicit module boundary.
    for root_dir in ["res://scenes", "res://core", "res://domain", "res://ui"]:
        var dir := DirAccess.open(root_dir)
        if dir == null:
            continue
        dir.list_dir_begin()
        var entry := dir.get_next()
        while not entry.is_empty():
            if not dir.current_is_dir() and entry.ends_with(".gd") and root_dir == "res://scenes":
                failures.append("scene owns executable script: %s/%s" % [root_dir, entry])
            entry = dir.get_next()
        dir.list_dir_end()
    checks += 1

    var project_text := FileAccess.get_file_as_string("res://project.godot")
    checks += 1
    if not project_text.contains('ThemeService="*res://core/theme/theme_service.gd"'):
        failures.append("ThemeService autoload missing")
    for autoload_name in ["FriendsService", "ClubsService", "ClubChatService"]:
        checks += 1
        if not project_text.contains('%s="*res://' % autoload_name):
            failures.append("%s autoload missing" % autoload_name)
    var chat_scene := FileAccess.get_file_as_string("res://scenes/game_chat_panel.tscn")
    checks += 1
    if not chat_scene.contains('res://ui/components/game/game_chat_panel.gd'):
        failures.append("chat scene not bound to isolated component")

    var game_state_text := FileAccess.get_file_as_string("res://domain/chess/game_state.gd")
    checks += 1
    if game_state_text.contains("ChessBotController") or game_state_text.contains("rules.valid(board"):
        failures.append("game_state retains direct bot/move implementation")
    checks += 1
    if game_state_text.contains("func _apply_move(") or game_state_text.contains("    slot_active[slot] = false\n    _emit_log(\"%s quedó AUSENTE.\""):
        failures.append("game_state retains extracted implementation bodies")
    return {"checks": checks, "failures": failures}
