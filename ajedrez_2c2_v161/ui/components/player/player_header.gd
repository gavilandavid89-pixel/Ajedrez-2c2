extends PanelContainer
class_name ChessPlayerHeader

const PlayerCardScene = preload("res://scenes/player_card.tscn")
const ProfileDataScript = preload("res://domain/player/profile_data.gd")

var player_color := "white"
var player_card: Control
var nexus_label: Label
var clock_label: Button
var active := false
var _player_data: Dictionary = {}

func _ready() -> void:
	_build_if_needed()
	set_player_data(_player_data)

func set_player_data(data: Dictionary) -> void:
	_player_data = data.duplicate(true)
	_build_if_needed()
	if not is_instance_valid(player_card):
		return
	var profile_id := String(data.get("id", ""))
	var profile := ProfileDataScript.get_profile(profile_id) if not profile_id.is_empty() else {}
	profile.merge(data, true)
	profile["name"] = String(data.get("name", profile.get("name", "Jugador")))
	if player_card.has_method("set_profile"):
		player_card.set_profile(profile, "Jugador", true, false, Color("#D5A84E") if player_color == "white" else Color("#A85A49"))
	var nexus_value: Variant = data.get("nexus", data.get("nexus_level", data.get("nexus_score", null)))
	nexus_label.text = "Nexus %s" % str(nexus_value) if nexus_value != null and str(nexus_value) != "" else "Nexus"

func set_clock(seconds: float, is_active: bool) -> void:
	_build_if_needed()
	var safe_seconds := maxi(0, int(ceil(seconds)))
	clock_label.text = "%d:%02d" % [safe_seconds / 60, safe_seconds % 60]
	active = is_active
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#332815") if active else Color("#17191D")
	style.border_color = Color("#D5A84E") if active else Color("#3D424B")
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(10)
	clock_label.add_theme_stylebox_override("normal", style)
	clock_label.add_theme_color_override("font_color", Color("#FFE3A0") if active else Color("#D8DCE4"))

func _build_if_needed() -> void:
	if is_instance_valid(clock_label):
		return
	custom_minimum_size = Vector2(0, 72)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	player_card = PlayerCardScene.instantiate()
	player_card.custom_minimum_size = Vector2(92, 72)
	player_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(player_card)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 0)
	row.add_child(middle)
	nexus_label = Label.new()
	nexus_label.text = "Nexus"
	nexus_label.add_theme_font_size_override("font_size", 12)
	nexus_label.add_theme_color_override("font_color", Color("#A89B83"))
	middle.add_child(nexus_label)
	clock_label = Button.new()
	clock_label.text = "0:00"
	clock_label.custom_minimum_size = Vector2(76, 40)
	clock_label.focus_mode = Control.FOCUS_NONE
	clock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_label.add_theme_font_size_override("font_size", 19)
	row.add_child(clock_label)
