extends Panel
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

signal emote_selected(emote_id: String)
signal closed

const EmoteDataScript = preload("res://domain/player/emote_data.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")
const COOLDOWN_SECONDS := 2.0

@onready var grid: GridContainer = $Body/Grid
@onready var cooldown_label: Label = $Body/Cooldown
@onready var cooldown_bar: ProgressBar = $Body/CooldownBar

var game
var _buttons: Array[Button] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    $Header/Close.pressed.connect(_on_close)
    _build_buttons()
    set_process(false)

func set_game(state) -> void:
    game = state
    refresh()

func _build_buttons() -> void:
    for child in grid.get_children():
        child.queue_free()
    _buttons.clear()

    var player_data = RuntimeServicesScript.get_autoload("PlayerData")
    var allowed: Array = player_data.get_equipped_emotes() if player_data != null else []
    for item in EmoteDataScript.all():
        if not allowed.has(String(item["id"])):
            continue
        var button := Button.new()
        button.custom_minimum_size = Vector2(72, 72)
        button.focus_mode = Control.FOCUS_NONE
        button.tooltip_text = String(item["label"])
        button.mouse_filter = Control.MOUSE_FILTER_STOP
        button.icon = load(String(item["path"]))
        button.expand_icon = true
        var normal := StyleBoxFlat.new()
        normal.bg_color = Color("#191713")
        normal.border_color = Color("#40372C")
        normal.set_border_width_all(1)
        normal.set_corner_radius_all(10)
        var hover := normal.duplicate() as StyleBoxFlat
        hover.bg_color = Color("#2A2116")
        hover.border_color = Color("#C9963B")
        var pressed := hover.duplicate() as StyleBoxFlat
        pressed.bg_color = Color("#3B2B18")
        button.add_theme_stylebox_override("normal", normal)
        button.add_theme_stylebox_override("hover", hover)
        button.add_theme_stylebox_override("pressed", pressed)
        button.add_theme_stylebox_override("disabled", normal)
        var emote_id := String(item["id"])
        button.pressed.connect(func():
            emote_selected.emit(emote_id)
        )
        grid.add_child(button)
        _buttons.append(button)

func refresh() -> void:
    if game == null:
        return
    var player_data = RuntimeServicesScript.get_autoload("PlayerData")
    var allowed: Array = player_data.get_equipped_emotes() if player_data != null else []
    if allowed.is_empty():
        cooldown_label.text = "No tienes reacciones equipadas"
        cooldown_bar.value = 0.0
        _adapt_grid(0)
        return
    var left: float = max(0.0, float(game.emote_cooldown_until) - float(game.now()))
    var locked: bool = left > 0.01
    for button in _buttons:
        button.disabled = locked or not game.running
    cooldown_bar.value = (left / COOLDOWN_SECONDS) * 100.0 if locked else 0.0
    if locked:
        cooldown_label.text = "Enfriamiento: %.1fs" % left
    else:
        cooldown_label.text = "Listo · todos lo verán"

    _adapt_grid(allowed.size())

func _process(_delta: float) -> void:
    # El cooldown se actualiza solo cuando hace falta; el HUD ya refresca el estado dinámico.
    pass

func _adapt_grid(count: int = -1) -> void:
    var w: float = size.x
    grid.columns = 4 if w >= 300.0 else 3
    if count < 0:
        count = _buttons.size()

func resize_for_viewport(viewport_size: Vector2, board_rect: Rect2) -> void:
    var portrait := viewport_size.y >= viewport_size.x
    var panel_w: float
    var columns: int
    if portrait:
        panel_w = min(344.0, max(276.0, viewport_size.x - 24.0))
        columns = 4 if panel_w >= 320.0 else 3
    else:
        panel_w = min(344.0, max(276.0, viewport_size.x * 0.30))
        columns = 4 if panel_w >= 320.0 else 3

    var allowed_count := 0
    var player_data = RuntimeServicesScript.get_autoload("PlayerData")
    if player_data != null:
        allowed_count = player_data.get_equipped_emotes().size()
    var rows: int = maxi(1, int(ceil(float(allowed_count) / float(columns))))
    var panel_h := 84.0 + float(rows) * 74.0 + 54.0
    size = Vector2(panel_w, panel_h)
    grid.columns = columns

    if portrait:
        # En vertical flota cerca de la esquina inferior del tablero, sin salir de pantalla.
        position.x = clamp(viewport_size.x - panel_w - 12.0, 12.0, max(12.0, viewport_size.x - panel_w - 12.0))
        var desired_y := board_rect.end.y - panel_h - 12.0
        position.y = clamp(desired_y, 72.0, max(72.0, viewport_size.y - panel_h - 12.0))
    else:
        # En horizontal ocupa la columna derecha y no recorta el tablero.
        position.x = viewport_size.x - panel_w - 12.0
        position.y = clamp(board_rect.position.y, 72.0, max(72.0, viewport_size.y - panel_h - 12.0))

func _on_close() -> void:
    visible = false
    closed.emit()
