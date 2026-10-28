extends Control
const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

const AppConfig = preload("res://core/services/app.gd")
const Matchmaking = preload("res://domain/competitive/matchmaking_logic.gd")
const MatchContext = preload("res://domain/competitive/match_context.gd")

var elapsed := 0.0
var done := false
var friend_mode := false
var friend_join := false
var join_code := ""
var mode := AppConfig.MODE_1C1
var minutes := 10
var room_code := "------"
var local_rating := 1000
var local_uncertainty := 320.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var app = RuntimeServicesScript.get_autoload("App")
	if app != null:
		mode = int(app.selected_mode)
		minutes = int(app.selected_time_minutes)
		friend_mode = String(app.online_entry) == "friend"
		friend_join = String(app.online_entry) == "friend_join"
		room_code = String(app.friend_room_code)
		join_code = String(app.join_room_code)
	var player_data = RuntimeServicesScript.get_autoload("PlayerData")
	if player_data != null:
		local_rating = int(player_data.individual.get("rating", 1000)) if mode == AppConfig.MODE_2C2 else int(player_data.individual_1c1.get("rating", 1000))
		local_uncertainty = float(player_data.individual.get("uncertainty", 320.0)) if mode == AppConfig.MODE_2C2 else float(player_data.individual_1c1.get("uncertainty", 320.0))
	_configure_ui()
	if mode == AppConfig.MODE_1C1:
		_configure_1c1_progress_style()
	get_node("Center/Card/Continue").pressed.connect(_on_continue_pressed)
	get_node("Center/Card/Cancel").pressed.connect(_cancel)
	get_viewport().size_changed.connect(_resize)
	_resize()

func _configure_1c1_progress_style() -> void:
	var progress := get_node("Center/Card/Progress") as ProgressBar
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#211B15")
	background.set_corner_radius_all(7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#C79545")
	fill.set_corner_radius_all(7)
	progress.add_theme_stylebox_override("background", background)
	progress.add_theme_stylebox_override("fill", fill)

func _configure_ui() -> void:
	var title := "2c2 · ONLINE" if mode == AppConfig.MODE_2C2 else "1c1 · ONLINE"
	get_node("Center/Card/Title").text = title
	get_node("Center/Card/Subtitle").text = _subtitle()
	get_node("Center/Card/Room").visible = friend_mode
	get_node("Center/Card/Searching").text = "Esperando a tu amigo" if friend_mode else "Buscando rivales"
	get_node("Center/Card/Progress").visible = not friend_mode
	get_node("Center/Card/Continue").visible = false
	get_node("Center/Card/Cancel").text = "Cancelar" if not friend_mode else ("Salir de la sala" if not friend_join else "Salir de la sala")
	get_node("Center/Card/Room/Code").text = join_code if friend_join and not join_code.is_empty() else (room_code if not room_code.is_empty() else "------")
	get_node("Center/Card/Room/Status").text = (
		"Tu amigo será tu compañero. Comparte el enlace o el QR." if mode == AppConfig.MODE_2C2
		else "Comparte el enlace o el QR para que tu rival entre."
	)
	get_node("Center/Card/Hint").text = (
		("Matchmaking local · rating %d · rango de búsqueda ampliable. Conexión real pendiente." % local_rating)
		if mode == AppConfig.MODE_1C1 and not friend_mode
		else ("Matchmaking local: rating %d · el rango se amplía mientras esperas. La conexión real se conectará después." % local_rating)
		if not friend_mode
		else "Sala privada lista. Cuando el online real esté conectado, esperará aquí hasta que entre tu invitado."
	)

func _subtitle() -> String:
	if friend_mode:
		return "Sala privada · %d:00 por equipo" % minutes if mode == AppConfig.MODE_2C2 else "Sala privada · %d:00 por jugador" % minutes
	return "Partida pública · %d:00 por equipo" % minutes if mode == AppConfig.MODE_2C2 else "Partida pública · %d:00 por jugador" % minutes

func _resize() -> void:
	var vp := get_viewport_rect().size
	var portrait := vp.y >= vp.x
	var card := get_node("Center/Card") as Panel
	var w := minf(520.0, vp.x - 32.0)
	var h := minf(520.0 if friend_mode else 330.0, vp.y - 60.0)
	card.custom_minimum_size = Vector2(w, h)
	card.size = Vector2(w, h)
	card.position = (vp - card.size) * 0.5
	var title := get_node("Center/Card/Title") as Label
	var subtitle := get_node("Center/Card/Subtitle") as Label
	var icon := get_node("Center/Card/Icon") as Label
	_set_local_rect(icon, Rect2(Vector2(0.0, 22.0), Vector2(w, 36.0)))
	_set_local_rect(title, Rect2(Vector2(18.0, 62.0), Vector2(maxf(0.0, w - 36.0), 42.0)))
	_set_local_rect(subtitle, Rect2(Vector2(18.0, 106.0), Vector2(maxf(0.0, w - 36.0), 40.0)))
	title.clip_text = true
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 23 if (portrait and vp.x < 420.0) else (26 if portrait else 30))
	subtitle.add_theme_font_size_override("font_size", 18 if (portrait and vp.x < 420.0) else 13)
	if friend_mode:
		get_node("Center/Card/Room").position = Vector2(24.0, 174.0)
		get_node("Center/Card/Room").size = Vector2(w - 48.0, 118.0)
		get_node("Center/Card/Cancel").position = Vector2(24.0, h - 54.0)
		get_node("Center/Card/Cancel").size = Vector2(w - 48.0, 40.0)
		get_node("Center/Card/Hint").position = Vector2(24.0, h - 102.0)
		get_node("Center/Card/Hint").size = Vector2(w - 48.0, 42.0)
	else:
		get_node("Center/Card/Cancel").position = Vector2(24.0, h - 54.0)
		get_node("Center/Card/Cancel").size = Vector2(w - 48.0, 40.0)
		get_node("Center/Card/Hint").position = Vector2(24.0, h - 102.0)
		get_node("Center/Card/Hint").size = Vector2(w - 48.0, 42.0)
		get_node("Center/Card/Searching").position = Vector2(20.0, 154.0)
		get_node("Center/Card/Progress").position = Vector2(56.0, 202.0)
		get_node("Center/Card/Progress").size = Vector2(w - 112.0, 22.0)

func _set_local_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size

func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	if friend_mode:
		get_node("Center/Card/Searching").text = "Esperando a tu amigo" + ".".repeat(int(elapsed * 2.0) % 4)
		return
	var dots := ".".repeat(int(elapsed * 2.0) % 4)
	get_node("Center/Card/Searching").text = "Buscando rivales" + dots
	get_node("Center/Card/Hint").text = Matchmaking.search_label(local_rating, elapsed, "Matchmaking local") + " · conexión real pendiente"
	get_node("Center/Card/Progress").value = minf(100.0, elapsed / 1.35 * 100.0)
	if elapsed >= 1.35:
		done = true
		get_node("Center/Card/Searching").text = "Rival encontrado"
		await get_tree().create_timer(0.35).timeout
		_enter_game()

func _on_continue_pressed() -> void:
	_enter_game()

func _cancel() -> void:
	var app = RuntimeServicesScript.get_autoload("App")
	if app != null:
		app.reset_online_entry()
	Navigation.go(ScreenCatalog.MAIN_MENU)

func _enter_game() -> void:
	done = true
	var app = RuntimeServicesScript.get_autoload("App")
	if app != null:
		app.selected_mode = mode
		app.selected_time_minutes = minutes
		app.competitive_match_context = MatchContext.snapshot(local_rating, local_uncertainty, mode)
		app.online_entry = "random"
		app.temporary_online_bots = not friend_mode and not friend_join
	Navigation.go(ScreenCatalog.GAME)
