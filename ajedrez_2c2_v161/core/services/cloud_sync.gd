extends Node
signal state_changed(status: String)
signal request_finished(result: Dictionary)

var enabled: bool = false
var endpoint: String = ""
var auth_token: String = ""
var last_status: String = "disabled"
var last_sync_at: int = 0
var _request: HTTPRequest = null

func configure(base_url: String, token: String = "") -> void:
    endpoint = base_url.strip_edges().trim_suffix("/")
    auth_token = token
    enabled = not endpoint.is_empty()
    last_status = "ready" if enabled else "disabled"
    state_changed.emit(last_status)

func is_configured() -> bool:
    return enabled and not endpoint.is_empty()

func set_auth_token(token: String) -> void:
    auth_token = token

func clear_credentials() -> void:
    endpoint = ""
    auth_token = ""
    enabled = false
    last_status = "disabled"
    state_changed.emit(last_status)

func sync_pending() -> Dictionary:
    if not is_configured():
        last_status = "disabled"
        state_changed.emit(last_status)
        return {"ok": false, "status": "disabled", "reason": "cloud_not_configured"}
    var storage := get_node_or_null("/root/StorageManager")
    if storage == null:
        return {"ok": false, "status": "error", "reason": "storage_unavailable"}
    var queue: Array[Dictionary] = storage.get_sync_queue()
    if queue.is_empty():
        return {"ok": true, "status": "nothing_to_sync", "count": 0}
    var sent := 0
    for item in queue:
        var result: Dictionary = await push_sync_operation(item)
        if not bool(result.get("ok", false)):
            return {"ok": false, "status": "partial", "sent": sent, "error": result}
        storage.remove_sync_operation(String(item.get("id", "")))
        sent += 1
    last_sync_at = Time.get_unix_time_from_system()
    last_status = "synced"
    state_changed.emit(last_status)
    return {"ok": true, "status": last_status, "count": sent}

func pull_remote_state() -> Dictionary:
    var account_id := _account_id_from_auth()
    if account_id.is_empty():
        return {"ok": false, "status": "anonymous"}
    return await _request_json("GET", "/v1/account/snapshot?account_id=" + account_id.uri_encode(), {})

func bootstrap_account(account_id: String, local_revision: int, snapshot: Dictionary) -> Dictionary:
    if not is_configured():
        return {"ok": false, "status": "disabled", "reason": "cloud_not_configured"}
    return await _request_json("POST", "/v1/account/bootstrap", {
        "account_id": account_id,
        "local_revision": local_revision,
        "snapshot": snapshot,
    })

func push_account_snapshot(account_id: String, local_revision: int, snapshot: Dictionary) -> Dictionary:
    if not is_configured():
        return {"ok": false, "status": "disabled", "reason": "cloud_not_configured"}
    return await _request_json("POST", "/v1/account/snapshot", {
        "account_id": account_id,
        "revision": local_revision,
        "snapshot": snapshot,
    })

func push_sync_operation(operation: Dictionary) -> Dictionary:
    if not is_configured():
        return {"ok": false, "status": "disabled"}
    return await _request_json("POST", "/v1/account/events", {"operation": operation})

func _account_id_from_auth() -> String:
    var auth := get_node_or_null("/root/AuthService")
    if auth == null or not auth.has_method("current_account"):
        return ""
    return String(auth.current_account().get("account_id", ""))

func _request_json(method: String, path: String, payload: Dictionary) -> Dictionary:
    if not is_configured():
        return {"ok": false, "status": "disabled"}
    if is_instance_valid(_request):
        _request.queue_free()
    _request = HTTPRequest.new()
    add_child(_request)
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"] )
    if not auth_token.is_empty():
        headers.append("Authorization: Bearer " + auth_token)
    var body := "" if method == "GET" else JSON.stringify(payload)
    var url := endpoint + path
    var err := _request.request(url, headers, HTTPClient.METHOD_GET if method == "GET" else HTTPClient.METHOD_POST, body)
    if err != OK:
        return {"ok": false, "status": "request_error", "code": err}
    var response: Array = await _request.request_completed
    var result := _parse_response(response)
    request_finished.emit(result)
    return result

func _parse_response(response: Array) -> Dictionary:
    var response_code := int(response[1])
    var body_bytes: PackedByteArray = response[3]
    var text := body_bytes.get_string_from_utf8()
    var parsed: Variant = JSON.parse_string(text)
    var data: Dictionary = parsed if parsed is Dictionary else {}
    if response_code >= 200 and response_code < 300:
        var result := data.duplicate(true)
        result["ok"] = true if not result.has("ok") else bool(result.get("ok"))
        result["status_code"] = response_code
        return result
    var error_result := data.duplicate(true)
    error_result["ok"] = false
    error_result["status_code"] = response_code
    error_result["status"] = String(error_result.get("status", "http_error"))
    return error_result
