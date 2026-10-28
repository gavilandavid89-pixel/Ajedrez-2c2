extends RefCounted
class_name EmoteData

const EMOTES: Array[Dictionary] = [
    {"id":"bien", "label":"¡Bien!", "path":"res://assets/emotes/bien.png"},
    {"id":"jajaja", "label":"¡Jajaja!", "path":"res://assets/emotes/jajaja.png"},
    {"id":"buena_jugada", "label":"¡Buena jugada!", "path":"res://assets/emotes/buena_jugada.png"},
    {"id":"genial", "label":"¡Genial!", "path":"res://assets/emotes/genial.png"},
    {"id":"gracias", "label":"¡Gracias!", "path":"res://assets/emotes/gracias.png"},
    {"id":"wow", "label":"¡Wow!", "path":"res://assets/emotes/wow.png"},
    {"id":"eh", "label":"¿Eh?", "path":"res://assets/emotes/eh.png"},
    {"id":"que_mala", "label":"¡Qué mala!", "path":"res://assets/emotes/que_mala.png"},
    {"id":"uy", "label":"¡Uy...", "path":"res://assets/emotes/uy.png"},
    {"id":"vamos", "label":"¡Vamos!", "path":"res://assets/emotes/vamos.png"},
    {"id":"tranquilo", "label":"Tranquilo", "path":"res://assets/emotes/tranquilo.png"},
    {"id":"tu_puedes", "label":"¡Tú puedes!", "path":"res://assets/emotes/tu_puedes.png"},
]

static func all() -> Array[Dictionary]:
    return EMOTES.duplicate(true)

static func get_emote(emote_id: String) -> Dictionary:
    for item in EMOTES:
        if String(item["id"]) == emote_id:
            return item
    return {}
