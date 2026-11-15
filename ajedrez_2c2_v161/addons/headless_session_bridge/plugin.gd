@tool
extends EditorPlugin

const BRIDGE_PORT := 48765
const REGISTRY_PATH := "user://headless_bridge.json"
const PROTOCOL_VERSION := 1
const CONNECTION_IDLE_TIMEOUT_MS := 5000
const SCENE_OPEN_TIMEOUT_MS := 10000

var _server: TCPServer
var _clients: Array[Dictionary] = []
var _pending_scene_opens: Array[Dictionary] = []
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
	for client in _clients:
		var peer: StreamPeerTCP = client["peer"]
		if peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			peer.disconnect_from_host()
	_clients.clear()
	_remove_own_registry()
	if _panel != null and is_instance_valid(_panel):
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()


func _process(_delta: float) -> void:
	if _server == null:
		return

	# Accept every pending local client. The persistent heartbeat operator and
	# short-lived command clients no longer compete for a single socket.
	while _server.is_connection_available():
		var peer := _server.take_connection()
		_clients.append({
			"peer": peer,
			"buffer": "",
			"last_activity_msec": Time.get_ticks_msec()
		})

	for index in range(_clients.size() - 1, -1, -1):
		var client: Dictionary = _clients[index]
		var peer: StreamPeerTCP = client["peer"]
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_remove_client(index)
			continue

		var available := peer.get_available_bytes()
		if available <= 0:
			if Time.get_ticks_msec() - int(client["last_activity_msec"]) > CONNECTION_IDLE_TIMEOUT_MS and not _has_pending_scene_open(peer):
				peer.disconnect_from_host()
				_remove_client(index)
			continue

		client["last_activity_msec"] = Time.get_ticks_msec()
		var packet := peer.get_data(available)
		if packet[0] != OK:
			_remove_client(index)
			continue
		client["buffer"] = str(client["buffer"]) + packet[1].get_string_from_utf8()
		if str(client["buffer"]).length() > 65536:
			peer.disconnect_from_host()
			_remove_client(index)
			continue

		while str(client["buffer"]).contains("\n"):
			var buffer_text := str(client["buffer"])
			var split_at := buffer_text.find("\n")
			var line := buffer_text.substr(0, split_at).strip_edges()
			client["buffer"] = buffer_text.substr(split_at + 1)
			if not line.is_empty():
				_handle_request(peer, line)
		_clients[index] = client

	_poll_pending_scene_opens()


func _has_pending_scene_open(peer: StreamPeerTCP) -> bool:
	for pending in _pending_scene_opens:
		if pending.get("peer") == peer:
			return true
	return false


func _poll_pending_scene_opens() -> void:
	for index in range(_pending_scene_opens.size() - 1, -1, -1):
		var pending: Dictionary = _pending_scene_opens[index]
		var peer: StreamPeerTCP = pending["peer"]
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_pending_scene_opens.remove_at(index)
			continue

		var requested_path := str(pending["scene_path"])
		var root := EditorInterface.get_edited_scene_root()
		if root != null and root.scene_file_path == requested_path:
			_send_response(peer, {
				"ok": true,
				"command": "open_scene",
				"project_id": _project_id,
				"editor_pid": OS.get_process_id(),
				"result": {"ok": true, "scene_path": requested_path, "opened": true}
			})
			_pending_scene_opens.remove_at(index)
			continue

		if Time.get_ticks_msec() >= int(pending["deadline_msec"]):
			_send_response(peer, {
				"ok": false,
				"command": "open_scene",
				"project_id": _project_id,
				"editor_pid": OS.get_process_id(),
				"error": "scene_open_timeout",
				"result": {"ok": false, "scene_path": requested_path, "opened": false}
			})
			_pending_scene_opens.remove_at(index)


func _remove_client(index: int) -> void:
	if index < 0 or index >= _clients.size():
		return
	_clients.remove_at(index)
	if _clients.is_empty():
		_status_label.text = "Estado: esperando operador"


func _handle_request(peer: StreamPeerTCP, line: String) -> void:
	var parsed: Variant = JSON.parse_string(line)
	if not parsed is Dictionary:
		_send_response(peer, {"ok": false, "error": "invalid_json"})
		return
	var request: Dictionary = parsed
	if int(request.get("protocol", -1)) != PROTOCOL_VERSION:
		_send_response(peer, {"ok": false, "error": "protocol_mismatch"})
		return
	if str(request.get("token", "")) != _token:
		_send_response(peer, {"ok": false, "error": "unauthorized"})
		return
	if str(request.get("project_id", "")) != _project_id:
		_send_response(peer, {"ok": false, "error": "wrong_project"})
		return

	var command := str(request.get("command", ""))
	var response := {"ok": true, "command": command, "project_id": _project_id, "editor_pid": OS.get_process_id()}
	match command:
		"ping":
			_status_label.text = "Estado: conectado (%d clientes)" % _clients.size()
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
			if not bool(open_result.get("ok", false)):
				response["ok"] = false
				response["result"] = open_result
			elif bool(open_result.get("pending", false)):
				_pending_scene_opens.append({
					"peer": peer,
					"scene_path": str(open_result.get("scene_path", "")),
					"deadline_msec": Time.get_ticks_msec() + SCENE_OPEN_TIMEOUT_MS
				})
				return
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
		"set_node_properties":
			var property_result := _set_node_properties(request.get("args", {}))
			response["ok"] = bool(property_result.get("ok", false))
			response["result"] = property_result
		_:
			response = {"ok": false, "error": "command_not_allowed"}
	_send_response(peer, response)


func _send_response(peer: StreamPeerTCP, payload: Dictionary) -> void:
	if peer != null and peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		peer.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())


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
	"Marker2D", "Area2D", "StaticBody2D", "CharacterBody2D",
	"RigidBody2D", "AnimatableBody2D", "CollisionShape2D",
	"CollisionPolygon2D", "RayCast2D", "ShapeCast2D"
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
		"root": _serialize_node(root, root, 0, budget),
		"truncated": int(budget["remaining"]) <= 0
	}


func _serialize_node(node: Node, scene_root: Node, depth: int, budget: Dictionary) -> Dictionary:
	if int(budget["remaining"]) <= 0:
		return {"truncated": true}
	budget["remaining"] = int(budget["remaining"]) - 1
	var result := {
		"name": str(node.name),
		"type": node.get_class(),
		# "path" is stable within the edited scene; runtime_path is diagnostic
		# context from the editor's own scene tree and must not be used as an edit target.
		"path": str(scene_root.get_path_to(node)),
		"runtime_path": str(node.get_path()),
		"groups": _get_group_names(node),
		"child_count": node.get_child_count(),
		"properties": _inspect_node_properties(node),
		"children": []
	}
	if depth >= 8:
		result["truncated"] = node.get_child_count() > 0
		return result
	var children: Array = []
	for child in node.get_children():
		if int(budget["remaining"]) <= 0:
			break
		children.append(_serialize_node(child, scene_root, depth + 1, budget))
	result["children"] = children
	if children.size() < node.get_child_count():
		result["truncated"] = true
	return result


func _inspect_node_properties(node: Node) -> Dictionary:
	# Deliberately expose a typed, bounded property schema rather than every
	# Object property. This gives the operator enough information to reason
	# about transforms and 2D collision setup without leaking editor internals.
	var properties: Dictionary = {}
	if node is Node2D:
		var node_2d := node as Node2D
		properties["position"] = _vector2_to_json(node_2d.position)
		properties["rotation_degrees"] = node_2d.rotation_degrees
		properties["scale"] = _vector2_to_json(node_2d.scale)
		properties["z_index"] = node_2d.z_index
		properties["visible"] = node_2d.visible
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		properties["collision_layer"] = collision_object.collision_layer
		properties["collision_mask"] = collision_object.collision_mask
		properties["input_pickable"] = collision_object.input_pickable
	if node is Area2D:
		var area := node as Area2D
		properties["monitoring"] = area.monitoring
		properties["monitorable"] = area.monitorable
	if node is CharacterBody2D:
		var character_body := node as CharacterBody2D
		properties["velocity"] = _vector2_to_json(character_body.velocity)
		properties["up_direction"] = _vector2_to_json(character_body.up_direction)
		properties["motion_mode"] = character_body.motion_mode
		properties["floor_max_angle"] = character_body.floor_max_angle
	if node is RayCast2D:
		var ray_cast := node as RayCast2D
		properties["enabled"] = ray_cast.enabled
		properties["target_position"] = _vector2_to_json(ray_cast.target_position)
		properties["collide_with_areas"] = ray_cast.collide_with_areas
		properties["collide_with_bodies"] = ray_cast.collide_with_bodies
	if node is ShapeCast2D:
		var shape_cast := node as ShapeCast2D
		properties["enabled"] = shape_cast.enabled
		properties["target_position"] = _vector2_to_json(shape_cast.target_position)
		properties["collide_with_areas"] = shape_cast.collide_with_areas
		properties["collide_with_bodies"] = shape_cast.collide_with_bodies
		properties["shape"] = _inspect_shape_resource(shape_cast.shape)
	if node is CollisionPolygon2D:
		var collision_polygon := node as CollisionPolygon2D
		properties["disabled"] = collision_polygon.disabled
		properties["polygon_point_count"] = collision_polygon.polygon.size()
	if node is CollisionShape2D:
		var collision_shape := node as CollisionShape2D
		properties["disabled"] = collision_shape.disabled
		properties["one_way_collision"] = collision_shape.one_way_collision
		properties["shape"] = _inspect_shape_resource(collision_shape.shape)
	return properties


func _inspect_shape_resource(shape: Shape2D) -> Dictionary:
	if shape == null:
		return {"assigned": false}
	var result := {"assigned": true, "type": shape.get_class()}
	var available_properties: Dictionary = {}
	for property_info in shape.get_property_list():
		available_properties[str(property_info.get("name", ""))] = true
	for property_name in ["radius", "height", "size", "a", "b", "extents"]:
		if not available_properties.has(property_name):
			continue
		var value: Variant = shape.get(property_name)
		if value is Vector2:
			result[property_name] = _vector2_to_json(value)
		elif value is float or value is int:
			result[property_name] = value
	return result


func _get_group_names(node: Node) -> Array[String]:
	var names: Array[String] = []
	for group_name in node.get_groups():
		names.append(str(group_name))
	return names


func _vector2_to_json(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


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



const NODE_PROPERTY_ALLOWLIST := {
	"Node2D": ["position", "rotation_degrees", "scale", "z_index", "visible"],
	"CollisionObject2D": ["collision_layer", "collision_mask", "input_pickable"],
	"Area2D": ["monitoring", "monitorable"],
	"CharacterBody2D": ["up_direction", "motion_mode", "floor_max_angle"],
	"RayCast2D": ["enabled", "target_position", "collide_with_areas", "collide_with_bodies"],
	"ShapeCast2D": ["enabled", "target_position", "collide_with_areas", "collide_with_bodies"],
	"CollisionShape2D": ["disabled", "one_way_collision"],
	"CollisionPolygon2D": ["disabled"]
}


func _set_node_properties(raw_args: Variant) -> Dictionary:
	if not raw_args is Dictionary:
		return {"ok": false, "error": "invalid_args"}
	var args: Dictionary = raw_args
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return {"ok": false, "error": "no_edited_scene"}
	var node_path := str(args.get("node_path", ""))
	if node_path.begins_with("/") or node_path == ".." or node_path.contains("../") or node_path.contains("/.."):
		return {"ok": false, "error": "invalid_node_path"}
	var node: Node = root if node_path.is_empty() or node_path == "." else root.get_node_or_null(NodePath(node_path))
	if node == null:
		return {"ok": false, "error": "node_not_found"}
	var raw_properties: Variant = args.get("properties", {})
	if not raw_properties is Dictionary or raw_properties.is_empty():
		return {"ok": false, "error": "properties_required"}
	var allowed: Array = []
	for class_key in NODE_PROPERTY_ALLOWLIST:
		if node.is_class(class_key):
			allowed.append_array(NODE_PROPERTY_ALLOWLIST[class_key])
	var changes: Dictionary = {}
	for property_name in raw_properties:
		var key := str(property_name)
		if key not in allowed:
			return {"ok": false, "error": "property_not_allowed", "property": key}
		var parsed := _validate_node_property(node, key, raw_properties[property_name])
		if not bool(parsed.get("ok", false)):
			return parsed
		changes[key] = parsed["value"]
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Headless Bridge: Configure " + str(node.name))
	for key in changes:
		undo_redo.add_do_property(node, key, changes[key])
		undo_redo.add_undo_property(node, key, node.get(key))
	undo_redo.commit_action()
	return {"ok": true, "node_path": str(root.get_path_to(node)), "changed_properties": changes}


func _validate_node_property(node: Node, key: String, raw_value: Variant) -> Dictionary:
	if key in ["position", "scale", "up_direction", "target_position"]:
		if not raw_value is Dictionary or not raw_value.has("x") or not raw_value.has("y"):
			return {"ok": false, "error": "vector2_expected", "property": key}
		var x := float(raw_value["x"])
		var y := float(raw_value["y"])
		if not is_finite(x) or not is_finite(y) or absf(x) > 1000000.0 or absf(y) > 1000000.0:
			return {"ok": false, "error": "vector2_out_of_range", "property": key}
		return {"ok": true, "value": Vector2(x, y)}
	if key in ["rotation_degrees", "floor_max_angle"]:
		if not (raw_value is int or raw_value is float):
			return {"ok": false, "error": "number_expected", "property": key}
		var number := float(raw_value)
		if not is_finite(number) or absf(number) > 360000.0:
			return {"ok": false, "error": "number_out_of_range", "property": key}
		return {"ok": true, "value": number}
	if key in ["collision_layer", "collision_mask"]:
		if not raw_value is int or int(raw_value) < 0 or int(raw_value) > 4294967295:
			return {"ok": false, "error": "unsigned_32bit_integer_expected", "property": key}
		return {"ok": true, "value": int(raw_value)}
	if key == "z_index":
		if not raw_value is int or int(raw_value) < -4096 or int(raw_value) > 4096:
			return {"ok": false, "error": "integer_out_of_range", "property": key}
		return {"ok": true, "value": int(raw_value)}
	if key == "motion_mode":
		if not raw_value is int or int(raw_value) not in [0, 1]:
			return {"ok": false, "error": "invalid_motion_mode", "property": key}
		return {"ok": true, "value": int(raw_value)}
	if key in ["visible", "input_pickable", "monitoring", "monitorable", "enabled", "collide_with_areas", "collide_with_bodies", "disabled", "one_way_collision"]:
		if not raw_value is bool:
			return {"ok": false, "error": "boolean_expected", "property": key}
		return {"ok": true, "value": raw_value}
	return {"ok": false, "error": "unsupported_property", "property": key}


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
	return {"ok": true, "scene_path": scene_path, "pending": true}
