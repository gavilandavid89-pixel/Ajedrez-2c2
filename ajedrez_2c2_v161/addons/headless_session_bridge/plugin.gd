@tool
extends EditorPlugin

const BRIDGE_PORT := 48765
const REGISTRY_PATH := "user://headless_bridge.json"
const PROTOCOL_VERSION := 1

var _server: TCPServer
var _peer: StreamPeerTCP
var _buffer := ""
var _token := ""
var _project_id := ""
var _registry_absolute_path := ""
var _status_label: Label
var _marker_label: Label
var _panel: VBoxContainer


func _enter_tree() -> void:
	_project_id = ProjectSettings.globalize_path("res://").simplify_path().sha256_text()
	_token = Crypto.new().generate_random_bytes(32).hex_encode()
	_registry_absolute_path = ProjectSettings.globalize_path(REGISTRY_PATH)

	_panel = VBoxContainer.new()
	_panel.name = "HeadlessBridge"
	_panel.custom_minimum_size = Vector2(260, 110)
	var heading := Label.new()
	heading.text = "HEADLESS SESSION BRIDGE"
	_panel.add_child(heading)
	_status_label = Label.new()
	_status_label.text = "Estado: esperando operador"
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_status_label)
	_marker_label = Label.new()
	_marker_label.text = ""
	_marker_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_marker_label)
	var hint := Label.new()
	hint.text = "Solo acepta ping, show_test_marker y clear_test_marker."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(hint)
	add_control_to_bottom_panel(_panel, "Headless Bridge")
	make_bottom_panel_item_visible(_panel)

	_server = TCPServer.new()
	var error := _server.listen(BRIDGE_PORT, "127.0.0.1")
	if error != OK:
		_status_label.text = "Error al abrir puerto: %s" % error
		push_error("Headless bridge could not listen on 127.0.0.1:%d" % BRIDGE_PORT)
		return

	set_process(true)
	call_deferred("_announce_when_ready")


func _exit_tree() -> void:
	set_process(false)
	if _server != null:
		_server.stop()
	if _peer != null:
		_peer.disconnect_from_host()
	_remove_own_registry()
	if _panel != null and is_instance_valid(_panel):
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()


func _process(_delta: float) -> void:
	if _server == null:
		return
	if _peer == null and _server.is_connection_available():
		_peer = _server.take_connection()
		_buffer = ""
	if _peer == null:
		return

	_peer.poll()
	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_peer = null
		_buffer = ""
		_status_label.text = "Estado: operador desconectado (última orden conservada)"
		return

	var available := _peer.get_available_bytes()
	if available <= 0:
		return
	var packet := _peer.get_data(available)
	if packet[0] != OK:
		_peer = null
		_buffer = ""
		return
	_buffer += packet[1].get_string_from_utf8()
	while _buffer.contains("\n"):
		var split_at := _buffer.find("\n")
		var line := _buffer.substr(0, split_at).strip_edges()
		_buffer = _buffer.substr(split_at + 1)
		if not line.is_empty():
			_handle_request(line)


func _handle_request(line: String) -> void:
	var parsed: Variant = JSON.parse_string(line)
	if not parsed is Dictionary:
		_send_response({"ok": false, "error": "invalid_json"})
		return
	var request: Dictionary = parsed
	if int(request.get("protocol", -1)) != PROTOCOL_VERSION:
		_send_response({"ok": false, "error": "protocol_mismatch"})
		return
	if str(request.get("token", "")) != _token:
		_send_response({"ok": false, "error": "unauthorized"})
		return
	if str(request.get("project_id", "")) != _project_id:
		_send_response({"ok": false, "error": "wrong_project"})
		return

	var command := str(request.get("command", ""))
	var response := {"ok": true, "command": command, "project_id": _project_id, "editor_pid": OS.get_process_id()}
	match command:
		"ping":
			_status_label.text = "Estado: conectado (ping)"
			response["status"] = "alive"
		"show_test_marker":
			_marker_label.text = "PRUEBA HEADLESS 001 — CAMBIO RECIBIDO"
			_status_label.text = "Estado: orden recibida"
			response["status"] = "marker_visible"
		"clear_test_marker":
			_marker_label.text = ""
			_status_label.text = "Estado: cambio temporal revertido"
			response["status"] = "marker_cleared"
		_:
			response = {"ok": false, "error": "command_not_allowed"}
	_send_response(response)


func _send_response(payload: Dictionary) -> void:
	if _peer != null and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		_peer.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())


func _write_registry() -> void:
	var file := FileAccess.open(REGISTRY_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Headless bridge could not write discovery registry.")
		return
	file.store_string(JSON.stringify({
		"protocol": PROTOCOL_VERSION,
		"port": BRIDGE_PORT,
		"token": _token,
		"project_id": _project_id,
		"project_path": ProjectSettings.globalize_path("res://").simplify_path(),
		"editor_pid": OS.get_process_id()
	}))
	file.close()


func _remove_own_registry() -> void:
	if not FileAccess.file_exists(REGISTRY_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
	if data is Dictionary and str(data.get("token", "")) == _token:
		DirAccess.remove_absolute(_registry_absolute_path)


func _announce_when_ready() -> void:
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree() and _server != null and _server.is_listening():
		_write_registry()
