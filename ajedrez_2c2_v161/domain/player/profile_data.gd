extends RefCounted
class_name ProfileData

const PROFILES := {
    "you": {
        "id": "USR_LOCAL_PLAYER",
        "name": "Tú",
        "avatar": "res://assets/avatars/avatar_you.svg",
        "tag": "Jugador",
        "title": "Jugador",
        "frame": "classic",
    },
    "mate": {
        "id": "USR_LOCAL_MATE",
        "name": "Compañero",
        "avatar": "res://assets/avatars/avatar_mate.svg",
        "tag": "Aliado",
        "title": "Compañero",
        "frame": "classic",
    },
    "rival1": {
        "id": "USR_LOCAL_RIVAL1",
        "name": "Rival 1",
        "avatar": "res://assets/avatars/avatar_rival1.svg",
        "tag": "Rival",
        "title": "Rival",
        "frame": "classic",
    },
    "rival2": {
        "id": "USR_LOCAL_RIVAL2",
        "name": "Rival 2",
        "avatar": "res://assets/avatars/avatar_rival2.svg",
        "tag": "Rival",
        "title": "Rival",
        "frame": "classic",
    },
    "local1": {
        "id": "USR_LOCAL_1",
        "name": "Jugador 1",
        "avatar": "res://assets/avatars/avatar_local1.svg",
        "tag": "Local",
        "title": "Jugador local",
        "frame": "classic",
    },
    "local2": {
        "id": "USR_LOCAL_2",
        "name": "Jugador 2",
        "avatar": "res://assets/avatars/avatar_local2.svg",
        "tag": "Local",
        "title": "Jugador local",
        "frame": "classic",
    },
    "bot": {
        "id": "BOT_LOCAL_3",
        "name": "IA",
        "avatar": "res://assets/avatars/avatar_bot.svg",
        "tag": "Nivel 3",
        "title": "Táctico",
        "frame": "classic",
    },
    "rival": {
        "id": "USR_LOCAL_RIVAL",
        "name": "Rival",
        "avatar": "res://assets/avatars/avatar_rival1.svg",
        "tag": "Oponente",
        "title": "Rival",
        "frame": "classic",
    },
}

static func get_profile(profile_id: String) -> Dictionary:
    if PROFILES.has(profile_id):
        return PROFILES[profile_id].duplicate(true)
    return PROFILES["rival"].duplicate(true)

static func name_for(profile_id: String) -> String:
    return String(get_profile(profile_id).get("name", "Jugador"))
