extends RefCounted
class_name ScreenCatalog

const LOADING := "res://scenes/loading.tscn"
const MAIN_MENU := "res://scenes/mode_menu.tscn"
const GAME := "res://scenes/game.tscn"
const ACCOUNT := "res://scenes/account_hub.tscn"
const AUTH := "res://scenes/auth_screen.tscn"
const BOT_SETUP := "res://scenes/bot_setup.tscn"
const LOCAL_SETUP := "res://scenes/local_setup.tscn"
const ONLINE_SETUP := "res://scenes/online_setup.tscn"
const ONLINE_MATCHMAKING := "res://scenes/online_matchmaking.tscn"
const MORE := "res://scenes/more_screen.tscn"
const FRIENDS := "res://scenes/friends_screen.tscn"
const CLUBS := "res://scenes/club_browser_screen.tscn"
const CLUB_DETAIL := "res://scenes/club_detail_screen.tscn"
const CLUB_CREATE := "res://scenes/club_create_screen.tscn"
const CLUB_CHAT := "res://scenes/club_chat_screen.tscn"
const PLAYER_PROFILE := "res://scenes/player_profile_screen.tscn"
const CLUB_MEMBERS := "res://scenes/club_members_screen.tscn"
const CLUB_MATCH_VIEWER := "res://scenes/club_match_viewer_screen.tscn"

static func all() -> Dictionary:
    return {
        "loading": LOADING,
        "main_menu": MAIN_MENU,
        "game": GAME,
        "account": ACCOUNT,
        "auth": AUTH,
        "bot_setup": BOT_SETUP,
        "local_setup": LOCAL_SETUP,
        "online_setup": ONLINE_SETUP,
        "online_matchmaking": ONLINE_MATCHMAKING,
        "more": MORE,
        "friends": FRIENDS,
        "clubs": CLUBS,
        "club_detail": CLUB_DETAIL,
        "club_create": CLUB_CREATE,
        "club_chat": CLUB_CHAT,
        "player_profile": PLAYER_PROFILE,
        "club_members": CLUB_MEMBERS,
        "club_match_viewer": CLUB_MATCH_VIEWER,
    }
