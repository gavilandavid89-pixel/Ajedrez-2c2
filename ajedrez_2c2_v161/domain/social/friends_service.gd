extends Node

signal changed()

var friends: Array[Dictionary] = [
    {"id": "mica", "name": "Mica", "icon": "♟", "nexus": 520, "online": true},
    {"id": "alex", "name": "Alex", "icon": "♞", "nexus": 640, "online": false},
]
var pending_requests: Array[Dictionary] = []

func get_friends() -> Array[Dictionary]:
    return friends.duplicate(true)

func get_pending_requests() -> Array[Dictionary]:
    return pending_requests.duplicate(true)

func is_friend(player_id: String) -> bool:
    for friend in friends:
        if String(friend.get("id", "")) == player_id:
            return true
    return false

func send_request(player_id: String, player_name: String, icon: String = "♟", nexus: int = 0, source: String = "match_result") -> bool:
    if player_id.is_empty() or is_friend(player_id):
        return false
    for request in pending_requests:
        if String(request.get("id", "")) == player_id:
            return false
    pending_requests.append({
        "id": player_id,
        "name": player_name,
        "icon": icon,
        "nexus": nexus,
        "source": source,
    })
    changed.emit()
    return true

func accept_request(player_id: String) -> bool:
    for i in range(pending_requests.size()):
        if String(pending_requests[i].get("id", "")) == player_id:
            friends.append(pending_requests[i].duplicate(true))
            pending_requests.remove_at(i)
            changed.emit()
            return true
    return false

func reject_request(player_id: String) -> bool:
    for i in range(pending_requests.size()):
        if String(pending_requests[i].get("id", "")) == player_id:
            pending_requests.remove_at(i)
            changed.emit()
            return true
    return false

func request_from_match(player_id: String, player_name: String, icon: String = "♟", nexus: int = 0) -> bool:
    return send_request(player_id, player_name, icon, nexus, "match_result")
