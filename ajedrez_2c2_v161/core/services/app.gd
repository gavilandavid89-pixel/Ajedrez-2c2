extends Node

const MODE_2C2 := 0
const MODE_1C1 := 1
const MODE_VS_BOT := 2
const MODE_1C1_LOCAL := 3

var selected_mode: int = MODE_2C2
var selected_time_minutes: int = 10
var online_entry: String = "random" # random | friend | friend_join
var friend_room_code: String = ""
var friend_invite_link: String = ""
var join_room_code: String = ""
var selected_bot_id: String = "mateo"
var selected_bot_elo: int = 400
var selected_bot_nexus: int = 200
# Simulación temporal mientras no existe servidor online real.
var temporary_online_bots: bool = false
# Contrato de rating resuelto para la partida actual. El backend real puede reemplazarlo.
var competitive_match_context: Dictionary = {}
# Pantalla inicial del centro de cuenta cuando se abre desde el menú principal.
var account_start_page: String = "profile"
var target_profile_id: String = ""
var target_profile_name: String = ""
# QA: permite recorrer todos los controles sin abandonar la pantalla bajo auditoría.
var navigation_audit_mode := false
var last_navigation_request := ""
var navigation_requests: Array[String] = []
var analysis_return_to_home: bool = false
var club_match_view_id: String = ""
var club_match_view_club_id: String = ""

var _transition_layer: CanvasLayer
var _transition_rect: ColorRect
var _transition_busy := false

func _ready() -> void:
	_ensure_transition_layer()
	if OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR)

func _ensure_transition_layer() -> void:
	if _transition_layer != null and is_instance_valid(_transition_layer):
		return
	_transition_layer = CanvasLayer.new()
	_transition_layer.name = "SceneTransition"
	_transition_layer.layer = 5000
	add_child(_transition_layer)
	_transition_rect = ColorRect.new()
	_transition_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_rect.color = Color("#0E0C0A")
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.visible = false
	_transition_rect.modulate.a = 0.0
	_transition_layer.add_child(_transition_rect)

func change_scene(scene_path: String) -> void:
	if navigation_audit_mode:
		last_navigation_request = scene_path
		navigation_requests.append(scene_path)
		return
	if _transition_busy:
		# A stale transition must never leave a permanent black curtain. Requests
		# are ignored while a valid transition is running, but recover the overlay
		# if its tween was interrupted or its alpha was left fully opaque.
		if _transition_rect != null and is_instance_valid(_transition_rect) and not is_instance_valid(get_tree().current_scene):
			_transition_rect.modulate.a = 0.0
			_transition_rect.visible = false
			_transition_busy = false
		else:
			return
	_transition_busy = true
	_ensure_transition_layer()
	var tree := get_tree()
	if tree == null:
		_transition_busy = false
		return
	_transition_rect.visible = true
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_in := create_tween()
	fade_in.tween_property(_transition_rect, "modulate:a", 1.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fade_in.finished
	var err := tree.change_scene_to_file(scene_path)
	if err != OK:
		var hub := get_tree().root.get_node_or_null("SupervisorHub")
		if hub != null and hub.has_method("record_runtime_error"):
			hub.record_runtime_error("navigation", "Scene change failed", {"scene_path": scene_path, "error_code": err})
		_transition_busy = false
		_transition_rect.modulate.a = 0.0
		_transition_rect.visible = false
		return
	# Do not wait indefinitely for scene_changed: another navigation request or
	# an interrupted scene transition can leave the global fade as a black curtain.
	# The scene swap is synchronous at the API boundary; give the new scene two
	# frames to enter/layout, then always release the overlay.
	await tree.process_frame
	await tree.process_frame
	var fade_out := create_tween()
	fade_out.tween_property(_transition_rect, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await fade_out.finished
	_transition_rect.modulate.a = 0.0
	_transition_rect.visible = false
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await tree.process_frame
	_report_ready_scene(scene_path)
	_transition_busy = false


func _report_ready_scene(scene_path: String) -> void:
	# Report only after the new scene has entered the tree and rendered a frame.
	# This avoids logging a destination before navigation actually succeeds.
	var hub := get_tree().root.get_node_or_null("SupervisorHub")
	if hub == null:
		return
	if hub.has_method("report_scene_ready"):
		hub.report_scene_ready(scene_path, not OS.has_feature("headless"))
	else:
		if hub.interface_agent != null:
			hub.interface_agent.report_screen(scene_path, {"transition": "completed"})
		if hub.has_method("capture_screen") and not OS.has_feature("headless"):
			var capture: Dictionary = hub.capture_screen("screen_" + scene_path.get_file().get_basename(), {"scene_path": scene_path, "capture_reason": "scene_ready"})
			if not bool(capture.get("ok", false)) and hub.has_method("record_runtime_error"):
				hub.record_runtime_error("app_navigation", "Automatic scene screenshot failed", {"scene_path": scene_path, "code": capture.get("code", "unknown")})

func mode_name(mode: int) -> String:
	match mode:
		MODE_2C2:
			return "2c2"
		MODE_1C1:
			return "1c1"
		MODE_VS_BOT:
			return "vs bot"
		MODE_1C1_LOCAL:
			return "1c1 local"
	return "2c2"

func set_time_minutes(minutes: int) -> void:
	selected_time_minutes = clampi(minutes, 1, 60)

func prepare_friend_room() -> void:
	var seed_value := Time.get_ticks_msec()
	var alphabet := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code := ""
	for i in range(6):
		seed_value = int((seed_value * 1103515245 + 12345) & 0x7fffffff)
		code += alphabet[seed_value % alphabet.length()]
	friend_room_code = code
	friend_invite_link = "https://ajedrez2c2.app/r/" + code

func reset_online_entry() -> void:
	competitive_match_context = {}
	online_entry = "random"
	friend_room_code = ""
	friend_invite_link = ""
	join_room_code = ""
	temporary_online_bots = false
