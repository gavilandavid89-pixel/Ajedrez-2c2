extends RefCounted
class_name PlayerCustomizationService

const EmoteDataScript = preload("res://domain/player/emote_data.gd")

var host: Node

var appearance: Variant:
    get: return host.appearance
    set(value): host.appearance = value

var reactions: Variant:
    get: return host.reactions
    set(value): host.reactions = value

var settings: Variant:
    get: return host.settings
    set(value): host.settings = value

var profile: Variant:
    get: return host.profile
    set(value): host.profile = value

var MAX_EQUIPPED_EMOTES: int:
    get: return int(host.MAX_EQUIPPED_EMOTES)

var MAX_DISPLAY_NAME_LENGTH: int:
    get: return int(host.MAX_DISPLAY_NAME_LENGTH)

func _init(p_host: Node) -> void:
    host = p_host

func save_data() -> void:
    host.save_data()

func _emit_changed() -> void:
    host.data_changed.emit()

func _normalize_appearance() -> void:
    var board_theme := String(appearance.get("board_theme", "classic"))
    var piece_set := String(appearance.get("piece_set", "classic"))
    var profile_frame := String(appearance.get("profile_frame", "classic"))
    var player_title := String(appearance.get("player_title", "jugador"))
    var name_color := String(appearance.get("name_color", "cream"))
    appearance["board_theme"] = board_theme if board_theme in ["classic", "graphite_gold"] else "classic"
    appearance["piece_set"] = piece_set if piece_set in ["classic", "graphite_gold"] else "classic"
    appearance["profile_frame"] = profile_frame if profile_frame in ["classic", "gold"] else "classic"
    appearance["player_title"] = player_title if player_title in ["jugador", "estratega", "veterano"] else "jugador"
    appearance["name_color"] = name_color if name_color in ["cream", "gold", "blue", "green", "red"] else "cream"


func _default_equipped_emotes() -> Array[String]:
    var out: Array[String] = []
    for item in EmoteDataScript.all():
        if out.size() >= MAX_EQUIPPED_EMOTES:
            break
        out.append(String(item.get("id", "")))
    return out


func _normalize_reactions(preserve_empty: bool = true) -> void:
    var source: Variant = reactions.get("equipped", [])
    var ids: Array[String] = []
    if source is Array:
        for raw in source:
            var emote_id := String(raw).strip_edges()
            if emote_id.is_empty() or ids.has(emote_id):
                continue
            if not EmoteDataScript.get_emote(emote_id).is_empty():
                ids.append(emote_id)
            if ids.size() >= MAX_EQUIPPED_EMOTES:
                break
    if ids.is_empty() and not preserve_empty:
        ids = _default_equipped_emotes()
    reactions["equipped"] = ids


func get_equipped_emotes() -> Array[String]:
    _normalize_reactions(true)
    return reactions["equipped"].duplicate()


func set_equipped_emotes(emote_ids: Array) -> bool:
    var cleaned: Array[String] = []
    for raw in emote_ids:
        var emote_id := String(raw).strip_edges()
        if emote_id.is_empty() or cleaned.has(emote_id):
            continue
        if EmoteDataScript.get_emote(emote_id).is_empty():
            return false
        if cleaned.size() >= MAX_EQUIPPED_EMOTES:
            return false
        cleaned.append(emote_id)
    reactions["equipped"] = cleaned
    save_data()
    _emit_changed()
    return true


func toggle_emote_equipped(emote_id: String) -> bool:
    var current := get_equipped_emotes()
    if current.has(emote_id):
        current.erase(emote_id)
    else:
        if current.size() >= MAX_EQUIPPED_EMOTES or EmoteDataScript.get_emote(emote_id).is_empty():
            return false
        current.append(emote_id)
    return set_equipped_emotes(current)


func move_equipped_emote(emote_id: String, direction: int) -> bool:
    var current := get_equipped_emotes()
    var index := current.find(emote_id)
    if index < 0:
        return false
    var target := clampi(index + direction, 0, current.size() - 1)
    if target == index:
        return false
    var temp := current[index]
    current[index] = current[target]
    current[target] = temp
    return set_equipped_emotes(current)


func set_display_name(new_name: String) -> bool:
    var cleaned := new_name.strip_edges()
    if cleaned.is_empty() or cleaned.length() > MAX_DISPLAY_NAME_LENGTH:
        return false
    profile["name"] = cleaned
    save_data()
    _emit_changed()
    return true


func set_avatar(path: String) -> bool:
    if path.is_empty():
        return false
    var valid_resource := ResourceLoader.exists(path)
    var valid_user_file := path.begins_with("user://") and FileAccess.file_exists(path)
    if not valid_resource and not valid_user_file:
        return false
    profile["avatar"] = path
    save_data()
    _emit_changed()
    return true


func set_setting(key: String, value: bool) -> void:
    settings[key] = value
    save_data()
    _emit_changed()


func get_setting(key: String, fallback: bool = false) -> bool:
    return bool(settings.get(key, fallback))


func set_appearance(key: String, value: String) -> void:
    var allowed_by_key := {
        "board_theme": ["classic", "graphite_gold"],
        "piece_set": ["classic", "graphite_gold"],
        "profile_frame": ["classic", "gold"],
        "player_title": ["jugador", "estratega", "veterano"],
        "name_color": ["cream", "gold", "blue", "green", "red"],
    }
    if not allowed_by_key.has(key):
        return
    var allowed: Array = allowed_by_key[key]
    if not allowed.has(value):
        return
    appearance[key] = value
    save_data()
    _emit_changed()


func set_game_skin(skin_id: String) -> bool:
    if skin_id not in ["classic", "graphite_gold"]:
        return false
    appearance["board_theme"] = skin_id
    appearance["piece_set"] = skin_id
    save_data()
    _emit_changed()
    return true


func get_appearance(key: String, fallback: String = "classic") -> String:
    return String(appearance.get(key, fallback))

