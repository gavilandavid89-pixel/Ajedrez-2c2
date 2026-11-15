@tool
extends EditorPlugin

const BRIDGE_PORT := 48765
const REGISTRY_PATH := "user://headless_bridge.json"
const PROTOCOL_VERSION := 1
const CONNECTION_IDLE_TIMEOUT_MS := 5000

var _server: TCPServer
var _peer: StreamPeerTCP
var _buffer := ""
var _token := ""
var _project_id := ""
var _registry_absolute_path := ""
var _status_label: Label
var _marker_label: Label
var _panel: VBoxContainer
var _last_activity_msec := 0


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
	hint.text = "Órdenes permitidas: ping, marcadores, escenas, inspección, recursos y nodos."
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
		_last_activity_msec = Time.get_ticks_msec()
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
		if _last_activity_msec > 0 and Time.get_ticks_msec() - _last_activity_msec > CONNECTION_IDLE_TIMEOUT_MS:
			_peer.disconnect_from_host()
			_peer = null
			_buffer = ""
			_status_label.text = "Estado: desconectado por falta de señal"
		return
	_last_activity_msec = Time.get_ticks_msec()
	var packet := _peer.get_data(available)
	if packet[0] != OK:
		_peer = null
		_buffer = ""
		return
	_buffer += packet[1].get_string_from_utf8()
	if _buffer.length() > 65536:
		_peer.disconnect_from_host()
		_peer = null
		_buffer = ""
		_status_label.text = "Estado: solicitud rechazada (mensaje demasiado grande)"
		return
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
		"open_scene":
			var open_result := _open_project_scene(request.get("args", {}))
			response["ok"] = bool(open_result.get("ok", false))
			response["result"] = open_result
		"inspect_scene":
			var inspect_result := _inspect_edited_scene()
			response["ok"] = bool(inspect_result.get("ok", false))
			response["result"] = inspect_result
		"list_project_resources":
			var resources_result := _list_project_resources()
			response["ok"] = bool(resources_result.get("ok", false))
			response["result"] = resources_result
		"add_node":
			var result := _add_node_to_edited_scene(request.get("args", {}))
			response["ok"] = bool(result.get("ok", false))
			response["result"] = result
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


const ALLOWED_NODE_TYPES := [
	"Node2D", "Control", "Sprite2D", "AnimatedSprite2D", "Label",
	"RichTextLabel", "ColorRect", "Panel", "Button", "TextureRect",
	"Marker2D", "Area2D", "CollisionShape2D"
]
const MAX_INSPECTED_NODES := 200
const MAX_RESOURCE_ENTRIES := 300


func _inspect_edited_scene() -> Dictionary:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return {"ok": false, "error": "no_edited_scene"}
	var budget := {"remaining": MAX_INSPECTED_NODES}
	return {
		"ok": true,
		"scene_path": root.scene_file_path,
		"root": _serialize_node(root, 0, budget),
		"truncated": int(budget["remaining"]) <= 0
	}


func _serialize_node(node: Node, depth: int, budget: Dictionary) -> Dictionary:
	if int(budget["remaining"]) <= 0:
		return {"truncated": true}
	budget["remaining"] = int(budget["remaining"]) - 1
	var result := {
		"name": str(node.name),
		"type": node.get_class(),
		"path": str(node.get_path()),
		"child_count": node.get_child_count(),
		"children": []
	}
	if depth >= 8:
		result["truncated"] = node.get_child_count() > 0
		return result
	var children: Array = []
	for child in node.get_children():
		if int(budget["remaining"]) <= 0:
			break
		children.append(_serialize_node(child, depth + 1, budget))
	result["children"] = children
	if children.size() < node.get_child_count():
		result["truncated"] = true
	return result


func _list_project_resources() -> Dictionary:
	var entries: Array[String] = []
	_collect_resources("res://", entries)
	return {"ok": true, "entries": entries, "truncated": entries.size() >= MAX_RESOURCE_ENTRIES}


func _collect_resources(path: String, entries: Array[String]) -> void:
	if entries.size() >= MAX_RESOURCE_ENTRIES:
		return
	var directory := DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var item := directory.get_next()
	while not item.is_empty() and entries.size() < MAX_RESOURCE_ENTRIES:
		if item.begins_with("."):
			item = directory.get_next()
			continue
		var child_path := path.path_join(item)
		if directory.current_is_dir():
			_collect_resources(child_path, entries)
		elif item.get_extension().to_lower() in ["tscn", "tres", "gd", "png", "webp", "svg", "ogg", "wav", "json"]:
			entries.append(child_path)
		item = directory.get_next()
	directory.list_dir_end()


func _add_node_to_edited_scene(raw_args: Variant) -> Dictionary:
	if not raw_args is Dictionary:
		return {"ok": false, "error": "invalid_args"}
	var args: Dictionary = raw_args
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return {"ok": false, "error": "no_edited_scene"}
	var type_name := str(args.get("type", ""))
	if type_name not in ALLOWED_NODE_TYPES:
		return {"ok": false, "error": "node_type_not_allowed"}
	var parent_path := str(args.get("parent_path", ""))
	if parent_path.begins_with("/") or parent_path.contains(".."):
		return {"ok": false, "error": "invalid_parent_path"}
	var parent: Node = root if parent_path.is_empty() else root.get_node_or_null(NodePath(parent_path))
	if parent == null:
		return {"ok": false, "error": "parent_not_found"}
	var node_name := str(args.get("name", type_name))
	if node_name.is_empty() or node_name.contains("/") or node_name.contains(":") or node_name == "." or node_name == "..":
		return {"ok": false, "error": "invalid_node_name"}
	var instance := ClassDB.instantiate(type_name)
	if not instance is Node:
		return {"ok": false, "error": "node_creation_failed"}
	var new_node: Node = instance
	new_node.name = node_name
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Headless Bridge: Add " + node_name)
	undo_redo.add_do_method(parent, "add_child", new_node)
	undo_redo.add_do_method(new_node, "set_owner", root)
	undo_redo.add_undo_method(parent, "remove_child", new_node)
	undo_redo.add_undo_method(new_node, "set_owner", null)
	undo_redo.commit_action()
	return {"ok": true, "node_path": str(root.get_path_to(new_node)), "type": type_name, "name": node_name}



func _open_project_scene(raw_args: Variant) -> Dictionary:
	if not raw_args is Dictionary:
		return {"ok": false, "error": "invalid_args"}
	var requested_path := str(raw_args.get("path", ""))
	var scene_path := requested_path.simplify_path()
	if not scene_path.begins_with("res://scenes/") or not scene_path.ends_with(".tscn"):
		return {"ok": false, "error": "scene_path_not_allowed"}
	if not FileAccess.file_exists(scene_path):
		return {"ok": false, "error": "scene_not_found"}
	EditorInterface.open_scene_from_path(scene_path)
	return {"ok": true, "scene_path": scene_path, "accepted": true}
