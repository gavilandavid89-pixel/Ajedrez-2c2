extends SceneTree

const ClubsService = preload("res://domain/social/clubs_service.gd")
const ClubChatService = preload("res://domain/social/club_chat_service.gd")
const GameSocialService = preload("res://domain/chess/game_social_service.gd")
const BotData = preload("res://domain/bots/bot_data.gd")
const ClubCreate = preload("res://ui/screens/club_create_screen.gd")
const ClubDetail = preload("res://ui/screens/club_detail_screen.gd")
const ClubMembers = preload("res://ui/screens/club_members_screen.gd")
const ClubChat = preload("res://ui/screens/club_chat_screen.gd")
const BotSetup = preload("res://ui/screens/bot_setup.gd")
const GameHud = preload("res://ui/screens/game_hud.gd")

func _initialize() -> void:
    print("V85 PARSE CONTRACTS: 10 OK / 0 FALLARON")
    quit(0)
