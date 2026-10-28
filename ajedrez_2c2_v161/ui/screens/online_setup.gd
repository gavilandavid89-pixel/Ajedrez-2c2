extends Control
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

const AppConfig = preload("res://core/services/app.gd")

signal closed
signal start_requested(mode: int, minutes: int)
signal friend_requested(mode: int, minutes: int)
signal join_requested(mode: int, minutes: int, room_code: String)

var selected_mode: int = AppConfig.MODE_1C1
var selected_minutes: int = 10
var friend_page := false
var join_page := false
var qr_preview

const ROOM_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_refs()
	get_node("Modal/Main/Play/Sub").visible = false
	get_node("Modal/Main/Friend/Sub").visible = false
	get_node("Modal/Join/Status").text = ""
	_connect()
	_resize()
	get_viewport().size_changed.connect(_resize)
	visible = false

func _build_refs() -> void:
	qr_preview = get_node("Modal/Friend/QR")

func _connect() -> void:
	get_node("Dim").gui_input.connect(_on_dim_input)
	get_node("Modal/Close").pressed.connect(_close)
	get_node("Modal/Back").pressed.connect(_show_main)
	get_node("Modal/Main/Play").pressed.connect(_start_random)
	get_node("Modal/Main/Friend").pressed.connect(_show_friend)
	get_node("Modal/Friend/Create").pressed.connect(_create_friend)
	get_node("Modal/Friend/JoinRoom").pressed.connect(_show_join)
	get_node("Modal/Friend/InviteCard/CopyLink").pressed.connect(_copy_link)
	get_node("Modal/Friend/InviteCard/RefreshCode").pressed.connect(_new_code)
	get_node("Modal/Friend/Back").pressed.connect(_show_main)
	get_node("Modal/Join/Paste").pressed.connect(_paste_join_code)
	get_node("Modal/Join/Join").pressed.connect(_join_room)
	get_node("Modal/Join/Back").pressed.connect(_show_friend)
	for minutes in [10, 15, 20]:
		get_node("Modal/Main/Time/" + str(minutes)).pressed.connect(func(m: int = minutes): _set_time(m))
		get_node("Modal/Friend/Time/" + str(minutes)).pressed.connect(func(m: int = minutes): _set_time(m))

func open_for_mode(mode: int) -> void:
	selected_mode = mode
	var app = RuntimeServicesScript.get_autoload("App")
	selected_minutes = int(app.selected_time_minutes) if app != null else 10
	selected_minutes = 10 if not [10, 15, 20].has(selected_minutes) else selected_minutes
	friend_page = false
	join_page = false
	_sync_text()
	_sync_time_buttons()
	_show_main()
	visible = true
	_resize()

func _sync_text() -> void:
	var label := "2c2 · COOPERATIVO" if selected_mode == AppConfig.MODE_2C2 else "1c1 · ONLINE"
	get_node("Modal/Title").text = label
	get_node("Modal/Main/Play/Sub").text = "Busca rivales para una partida pública." if selected_mode == AppConfig.MODE_2C2 else "Busca un rival para una partida clásica."
	var hint_title := get_node("Modal/Main/HintTitle") as Label
	if selected_mode == AppConfig.MODE_1C1:
		var data = RuntimeServicesScript.get_autoload("PlayerData")
		if data != null:
			var stats: Dictionary = data.individual_1c1
			hint_title.text = "Tu competitivo · 1c1 · Rating %d · 🏆 %d" % [int(stats.get("rating", 1000)), int(stats.get("cups", 0))]
		else:
			hint_title.text = "Tu competitivo · 1c1"
	else:
		hint_title.text = "Elige cómo quieres entrar a la partida."
	get_node("Modal/Main/Friend/Sub").text = "Crea o únete a una sala privada." if selected_mode == AppConfig.MODE_2C2 else "Crea o únete a una sala privada."
	get_node("Modal/Main/TimeLabel").text = "Tiempo por equipo" if selected_mode == AppConfig.MODE_2C2 else "Tiempo por jugador"
	get_node("Modal/Friend/TimeLabel").text = "Tiempo por equipo" if selected_mode == AppConfig.MODE_2C2 else "Tiempo por jugador"
	get_node("Modal/Friend/InviteCard/Note").text = "Tu amigo será tu compañero de equipo." if selected_mode == AppConfig.MODE_2C2 else "Comparte el enlace o el QR para que tu rival entre."
	get_node("Modal/Join/Intro").text = "Introduce el código o pega el enlace que te compartió tu amigo."
	get_node("Modal/Join/Hint").text = "En 2c2 entrarás como compañero del anfitrión." if selected_mode == AppConfig.MODE_2C2 else "En 1c1 entrarás como rival del anfitrión."
	_sync_room_info()

func _sync_room_info() -> void:
	var app = RuntimeServicesScript.get_autoload("App")
	var code := String(app.friend_room_code) if app != null else "------"
	var link := String(app.friend_invite_link) if app != null else "https://ajedrez2c2.app/r/------"
	get_node("Modal/Friend/Code").text = code
	get_node("Modal/Friend/InviteCard/Link").text = link
	qr_preview.set_code(code)

func _set_time(minutes: int) -> void:
	selected_minutes = minutes
	_sync_time_buttons()

func _sync_time_buttons() -> void:
	for page in ["Main", "Friend"]:
		for minutes in [10, 15, 20]:
			var button: Button = get_node("Modal/" + page + "/Time/" + str(minutes))
			button.button_pressed = selected_minutes == minutes
			button.text = str(minutes) + "'"

func _show_main() -> void:
	friend_page = false
	join_page = false
	get_node("Modal/Main").visible = true
	get_node("Modal/Friend").visible = false
	get_node("Modal/Join").visible = false
	get_node("Modal/Back").visible = false
	get_node("Modal/Close").visible = true
	_sync_text()
	_sync_time_buttons()
	_resize()

func _show_friend() -> void:
	friend_page = true
	join_page = false
	var app = RuntimeServicesScript.get_autoload("App")
	if app != null:
		app.prepare_friend_room()
	get_node("Modal/Main").visible = false
	get_node("Modal/Friend").visible = true
	get_node("Modal/Join").visible = false
	get_node("Modal/Back").visible = true
	get_node("Modal/Close").visible = true
	_sync_text()
	_sync_time_buttons()
	_resize()

func _show_join() -> void:
	friend_page = false
	join_page = true
	get_node("Modal/Main").visible = false
	get_node("Modal/Friend").visible = false
	get_node("Modal/Join").visible = true
	get_node("Modal/Back").visible = true
	get_node("Modal/Close").visible = true
	get_node("Modal/Join/Status").text = ""
	_sync_text()
	_sync_time_buttons()
	_resize()
	get_node("Modal/Join/CodeInput").grab_focus.call_deferred()

func _new_code() -> void:
	var app = RuntimeServicesScript.get_autoload("App")
	if app != null:
		app.prepare_friend_room()
	_sync_room_info()

func _create_friend() -> void:
	friend_requested.emit(selected_mode, selected_minutes)

func _start_random() -> void:
	start_requested.emit(selected_mode, selected_minutes)

func _paste_join_code() -> void:
	if DisplayServer.get_name().to_lower() == "headless":
		return
	var raw: String = DisplayServer.clipboard_get()
	get_node("Modal/Join/CodeInput").text = raw
	_parse_join_preview()

func _parse_room_code(raw: String) -> String:
	var text := raw.strip_edges().to_upper()
	text = text.replace(" ", "").replace("-", "")
	var marker := "/R/"
	var idx := text.find(marker)
	if idx >= 0:
		text = text.substr(idx + marker.length())
		if text.length() > 6:
			text = text.substr(0, 6)
	if text.length() != 6:
		return ""
	for ch in text:
		if ROOM_ALPHABET.find(ch) == -1:
			return ""
	return text

func _parse_join_preview() -> String:
	var raw := String(get_node("Modal/Join/CodeInput").text)
	var code := _parse_room_code(raw)
	if code.is_empty():
		get_node("Modal/Join/Status").text = "Introduce un código de 6 caracteres o un enlace válido."
		get_node("Modal/Join/Status").modulate = Color("#C8785F")
	else:
		get_node("Modal/Join/Status").text = "Sala válida: " + code
		get_node("Modal/Join/Status").modulate = Color("#6F9A70")
	return code

func _join_room() -> void:
	var code := _parse_join_preview()
	if code.is_empty():
		return
	join_requested.emit(selected_mode, selected_minutes, code)

func _copy_link() -> void:
	var app = RuntimeServicesScript.get_autoload("App")
	if app != null and not String(app.friend_invite_link).is_empty():
		DisplayServer.clipboard_set(String(app.friend_invite_link))
		get_node("Modal/Friend/InviteCard/CopyStatus").text = "Enlace copiado"
		await get_tree().create_timer(1.1).timeout
		if is_instance_valid(self):
			get_node("Modal/Friend/InviteCard/CopyStatus").text = ""

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		accept_event()

func _close() -> void:
	visible = false
	closed.emit()

func _resize() -> void:
	var vp := get_viewport_rect().size
	var portrait := vp.y >= vp.x
	var modal := get_node("Modal") as Panel
	var w := minf(560.0, vp.x - 28.0)
	var target_h := 660.0 if friend_page else (430.0 if not join_page else 500.0)
	if not portrait:
		target_h = 520.0 if friend_page else (390.0 if not join_page else 430.0)
	var h := minf(target_h, vp.y - 34.0)
	modal.size = Vector2(w, h)
	modal.position = (vp - modal.size) * 0.5
	var compact := portrait and vp.x < 420.0
	var title := get_node("Modal/Title") as Label
	title.add_theme_font_size_override("font_size", 20 if compact else (23 if portrait else 21))
	title.position = Vector2(58.0 if compact else 24.0, 12.0)
	title.size = Vector2(maxf(140.0, w - (106.0 if compact else 78.0)), 36.0)
	var content_top := 64.0
	var content_h := h - 84.0
	_resize_page("Main", w, content_top, content_h, portrait)
	_resize_page("Friend", w, content_top, content_h, portrait)
	_resize_page("Join", w, content_top, content_h, portrait)

func _resize_page(page_name: String, w: float, top: float, h: float, portrait: bool) -> void:
	var page: Control = get_node("Modal/" + page_name)
	page.position = Vector2(14.0, top)
	page.size = Vector2(w - 28.0, h - 6.0)
	if page_name == "Main":
		var button_w := page.size.x
		var play_h := 72.0 if portrait else 64.0
		var friend_h := 72.0 if portrait else 64.0
		var play_y := 42.0
		var friend_y := play_y + play_h + 12.0
		var time_label_y := friend_y + friend_h + 22.0
		var time_y := time_label_y + 26.0
		_set_local_rect(get_node("Modal/Main/HintTitle"), Rect2(Vector2(0, 2), Vector2(button_w, 26)))
		_set_local_rect(get_node("Modal/Main/Play"), Rect2(Vector2(0, play_y), Vector2(button_w, play_h)))
		_set_local_rect(get_node("Modal/Main/Friend"), Rect2(Vector2(0, friend_y), Vector2(button_w, friend_h)))
		_set_local_rect(get_node("Modal/Main/TimeLabel"), Rect2(Vector2(0, time_label_y), Vector2(button_w, 22)))
		_set_local_rect(get_node("Modal/Main/Time"), Rect2(Vector2(0, time_y), Vector2(button_w, 52)))
		_set_local_rect(get_node("Modal/Main/Hint"), Rect2(Vector2(0, time_y + 70.0), Vector2(button_w, 48)))
		for minutes in [10, 15, 20]:
			get_node("Modal/Main/Time/" + str(minutes)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif page_name == "Friend":
		var full_w := page.size.x
		var split := (not portrait and full_w >= 700.0)
		_set_local_rect(get_node("Modal/Friend/Intro"), Rect2(Vector2(0, 0), Vector2(full_w, 44)))
		if split:
			var left_w := full_w * 0.52
			var right_x := left_w + 12.0
			_set_local_rect(get_node("Modal/Friend/InviteCard"), Rect2(Vector2(0, 56), Vector2(left_w, minf(238.0, page.size.y - 150.0))))
			var qr_split := get_node("Modal/Friend/QR") as Control
			qr_split.custom_minimum_size = Vector2.ZERO
			_set_local_rect(qr_split, Rect2(Vector2(right_x, 70), Vector2(164.0, 164.0)))
			_set_local_rect(get_node("Modal/Friend/Code"), Rect2(Vector2(right_x, 242), Vector2(164.0, 24.0)))
			_set_local_rect(get_node("Modal/Friend/TimeLabel"), Rect2(Vector2(0, 312), Vector2(full_w, 22)))
			_set_local_rect(get_node("Modal/Friend/Time"), Rect2(Vector2(0, 340), Vector2(full_w, 52)))
			_set_local_rect(get_node("Modal/Friend/Create"), Rect2(Vector2(0, 410), Vector2(full_w * 0.5 - 6.0, 50)))
			_set_local_rect(get_node("Modal/Friend/JoinRoom"), Rect2(Vector2(full_w * 0.5 + 6.0, 410), Vector2(full_w * 0.5 - 6.0, 50)))
			_set_local_rect(get_node("Modal/Friend/Back"), Rect2(Vector2(0, 474), Vector2(full_w, 38)))
		else:
			var narrow_portrait := portrait and full_w < 420.0
			if narrow_portrait:
				_set_local_rect(get_node("Modal/Friend/InviteCard"), Rect2(Vector2(0, 42), Vector2(full_w, 160)))
				var qr_size := 88.0
				var qr_portrait := get_node("Modal/Friend/QR") as Control
				qr_portrait.custom_minimum_size = Vector2.ZERO
				_set_local_rect(qr_portrait, Rect2(Vector2((full_w - qr_size) * 0.5, 210), Vector2(qr_size, qr_size)))
				_set_local_rect(get_node("Modal/Friend/Code"), Rect2(Vector2(0, 302), Vector2(full_w, 24)))
				_set_local_rect(get_node("Modal/Friend/TimeLabel"), Rect2(Vector2(0, 332), Vector2(full_w, 22)))
				_set_local_rect(get_node("Modal/Friend/Time"), Rect2(Vector2(0, 358), Vector2(full_w, 46)))
				_set_local_rect(get_node("Modal/Friend/Create"), Rect2(Vector2(0, 414), Vector2(full_w, 46)))
				_set_local_rect(get_node("Modal/Friend/JoinRoom"), Rect2(Vector2(0, 462), Vector2(full_w, 42)))
				_set_local_rect(get_node("Modal/Friend/Back"), Rect2(Vector2(0, 508), Vector2(full_w, 38)))
			else:
				_set_local_rect(get_node("Modal/Friend/InviteCard"), Rect2(Vector2(0, 50), Vector2(full_w, 180)))
				var qr_size := 122.0
				var qr_portrait := get_node("Modal/Friend/QR") as Control
				qr_portrait.custom_minimum_size = Vector2.ZERO
				_set_local_rect(qr_portrait, Rect2(Vector2((full_w - qr_size) * 0.5, 238), Vector2(qr_size, qr_size)))
				_set_local_rect(get_node("Modal/Friend/Code"), Rect2(Vector2(0, 366), Vector2(full_w, 24)))
				_set_local_rect(get_node("Modal/Friend/TimeLabel"), Rect2(Vector2(0, 400), Vector2(full_w, 22)))
				_set_local_rect(get_node("Modal/Friend/Time"), Rect2(Vector2(0, 428), Vector2(full_w, 50)))
				_set_local_rect(get_node("Modal/Friend/Create"), Rect2(Vector2(0, 490), Vector2(full_w, 50)))
				_set_local_rect(get_node("Modal/Friend/JoinRoom"), Rect2(Vector2(0, 548), Vector2(full_w, 50)))
				_set_local_rect(get_node("Modal/Friend/Back"), Rect2(Vector2(0, 606), Vector2(full_w, 38)))
		for minutes in [10, 15, 20]:
			get_node("Modal/Friend/Time/" + str(minutes)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		get_node("Modal/Friend/InviteCard/Link").add_theme_font_size_override("font_size", 18 if not split else 18)
		get_node("Modal/Friend/InviteCard/Note").add_theme_font_size_override("font_size", 18 if portrait else 18)
	else:
		var full_w := page.size.x
		var narrow_portrait := portrait and full_w < 420.0
		if narrow_portrait:
			_set_local_rect(get_node("Modal/Join/Intro"), Rect2(Vector2(0, 0), Vector2(full_w, 50)))
			var code_y := 58.0
			_set_local_rect(get_node("Modal/Join/CodeInput"), Rect2(Vector2(0, code_y), Vector2(full_w, 48)))
			_set_local_rect(get_node("Modal/Join/Paste"), Rect2(Vector2(0, code_y + 56.0), Vector2(full_w, 44)))
			_set_local_rect(get_node("Modal/Join/Status"), Rect2(Vector2(0, code_y + 108.0), Vector2(full_w, 26)))
			_set_local_rect(get_node("Modal/Join/Hint"), Rect2(Vector2(0, code_y + 140.0), Vector2(full_w, 40)))
			var hint := get_node("Modal/Join/Hint") as Label
			hint.text = "Entras como compañero del anfitrión."
			hint.clip_text = true
			hint.autowrap_mode = TextServer.AUTOWRAP_OFF
			var room_settings := get_node("Modal/Join/RoomSettings") as Label
			room_settings.text = "Tiempo y reglas del anfitrión."
			room_settings.clip_text = true
			room_settings.autowrap_mode = TextServer.AUTOWRAP_OFF
			room_settings.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_set_local_rect(room_settings, Rect2(Vector2(0, code_y + 190.0), Vector2(full_w, 44)))
			_set_local_rect(get_node("Modal/Join/Join"), Rect2(Vector2(0, code_y + 246.0), Vector2(full_w, 50)))
			_set_local_rect(get_node("Modal/Join/Back"), Rect2(Vector2(0, code_y + 306.0), Vector2(full_w, 38)))
			get_node("Modal/Join/CodeInput").add_theme_font_size_override("font_size", 22)
		else:
			_set_local_rect(get_node("Modal/Join/Intro"), Rect2(Vector2(0, 0), Vector2(full_w, 48)))
			var code_y := 72.0
			_set_local_rect(get_node("Modal/Join/CodeInput"), Rect2(Vector2(0, code_y), Vector2(full_w, 52)))
			_set_local_rect(get_node("Modal/Join/Paste"), Rect2(Vector2(0, code_y + 62.0), Vector2(full_w, 46)))
			_set_local_rect(get_node("Modal/Join/Status"), Rect2(Vector2(0, code_y + 116.0), Vector2(full_w, 28)))
			_set_local_rect(get_node("Modal/Join/Hint"), Rect2(Vector2(0, code_y + 148.0), Vector2(full_w, 42)))
			_set_local_rect(get_node("Modal/Join/RoomSettings"), Rect2(Vector2(0, code_y + 202.0), Vector2(full_w, 48)))
			_set_local_rect(get_node("Modal/Join/Join"), Rect2(Vector2(0, code_y + 262.0), Vector2(full_w, 52)))
			_set_local_rect(get_node("Modal/Join/Back"), Rect2(Vector2(0, code_y + 324.0), Vector2(full_w, 38)))
			get_node("Modal/Join/CodeInput").add_theme_font_size_override("font_size", 20 if portrait else 18)

func _set_local_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
