extends Control
const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

var progress := 0.0
var title_label: Label
var progress_label: Label
var bar: ProgressBar
var done := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_label = get_node("Center/VBox/Title")
	progress_label = get_node("Center/VBox/ProgressText")
	bar = get_node("Center/VBox/Progress")
	bar.value = 0.0
	set_process(true)

func _process(delta: float) -> void:
	progress = min(100.0, progress + delta * 125.0)
	bar.value = progress
	progress_label.text = "Cargando... %d%%" % int(progress)
	if progress >= 100.0 and not done:
		done = true
		await get_tree().create_timer(0.15).timeout
		Navigation.go(ScreenCatalog.MAIN_MENU)
