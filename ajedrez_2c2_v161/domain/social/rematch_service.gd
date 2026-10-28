extends Node

signal request_received(request: Dictionary)
signal request_removed(request_id: String)
signal changed()

var pending_requests: Array[Dictionary] = []

func receive_request(requester_id: String, requester_name: String, match_id: String = "", mode: int = 1, icon: String = "♟") -> bool:
    if requester_id.strip_edges().is_empty() or requester_name.strip_edges().is_empty():
        return false
    for item in pending_requests:
        if String(item.get("requester_id", "")) == requester_id and String(item.get("match_id", "")) == match_id:
            return false
    var request := {
        "id": "%s:%s:%d" % [requester_id, match_id, Time.get_ticks_msec()],
        "requester_id": requester_id,
        "requester_name": requester_name,
        "match_id": match_id,
        "mode": mode,
        "icon": icon,
        "created_at": Time.get_unix_time_from_system(),
    }
    pending_requests.append(request)
    request_received.emit(request.duplicate(true))
    changed.emit()
    return true

func get_pending_requests() -> Array[Dictionary]:
    return pending_requests.duplicate(true)

func get_latest_request() -> Dictionary:
    return pending_requests.back().duplicate(true) if not pending_requests.is_empty() else {}

func accept_request(request_id: String) -> bool:
    var request := _find(request_id)
    if request.is_empty():
        return false
    _remove(request_id)
    return true

func reject_request(request_id: String) -> bool:
    var request := _find(request_id)
    if request.is_empty():
        return false
    _remove(request_id)
    return true

func _find(request_id: String) -> Dictionary:
    for item in pending_requests:
        if String(item.get("id", "")) == request_id:
            return item.duplicate(true)
    return {}

func _remove(request_id: String) -> void:
    for i in range(pending_requests.size()):
        if String(pending_requests[i].get("id", "")) == request_id:
            pending_requests.remove_at(i)
            request_removed.emit(request_id)
            changed.emit()
            return
