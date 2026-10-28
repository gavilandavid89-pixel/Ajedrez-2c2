extends RefCounted
class_name BotData

const DEFAULT_BOT := "mateo"
const MIN_ELO := 400
const MAX_ELO := 1800
const MIN_NEXUS := 0
const MAX_NEXUS := 3000

# 20 bots totales: 4 por categoría. El NEXUS es la fuerza objetivo visible;
# el Elo interno mantiene la calibración actual del motor propio.
static func profiles() -> Array[Dictionary]:
	return [
		# FÁCIL · 4
		{"id":"mateo", "name":"Mateo", "difficulty":"Fácil", "elo":400, "nexus":200, "style":"Tranquilo", "desc":"Juega sencillo y deja más oportunidades al rival.", "calibration_quality":0.770240740740741, "acceptable_rate":0.333333333333333, "blunder_rate":0.233333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.18,"development":0.20,"king_safety":0.25,"center":0.22,"simplification":0.15,"risk":0.82}},
		{"id":"nora", "name":"Nora", "difficulty":"Fácil", "elo":450, "nexus":400, "style":"Aprendiz", "desc":"Detecta amenazas simples y algunas capturas.", "calibration_quality":0.749629629629629, "acceptable_rate":0.3, "blunder_rate":0.266666666666667, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.28,"development":0.30,"king_safety":0.32,"center":0.30,"simplification":0.20,"risk":0.68}},
		{"id":"lito", "name":"Lito", "difficulty":"Fácil", "elo":500, "nexus":600, "style":"Activo", "desc":"Busca desarrollo y tácticas básicas sin mucha precisión.", "calibration_quality":0.807185185185185, "acceptable_rate":0.366666666666667, "blunder_rate":0.133333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.36,"development":0.42,"king_safety":0.35,"center":0.40,"simplification":0.28,"risk":0.60}},
		{"id":"cata", "name":"Cata", "difficulty":"Fácil", "elo":550, "nexus":800, "style":"Calculadora", "desc":"Ve combinaciones cortas y castiga errores evidentes.", "calibration_quality":0.795833333333333, "acceptable_rate":0.366666666666667, "blunder_rate":0.2, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.48,"development":0.48,"king_safety":0.42,"center":0.45,"simplification":0.30,"risk":0.54}},
		# NORMAL · 4
		{"id":"tadeo", "name":"Tadeo", "difficulty":"Normal", "elo":650, "nexus":1000, "style":"Práctico", "desc":"Juega planes sencillos y aprovecha piezas mal colocadas.", "calibration_quality":0.842388888888889, "acceptable_rate":0.466666666666667, "blunder_rate":0.133333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.42,"development":0.52,"king_safety":0.48,"center":0.52,"simplification":0.38,"risk":0.50}},
		{"id":"vera", "name":"Vera", "difficulty":"Normal", "elo":700, "nexus":1200, "style":"Posicional", "desc":"Prioriza desarrollo, centro y seguridad del rey.", "calibration_quality":0.80787037037037, "acceptable_rate":0.366666666666667, "blunder_rate":0.166666666666667, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.45,"development":0.62,"king_safety":0.60,"center":0.60,"simplification":0.48,"risk":0.40}},
		{"id":"axel", "name":"Axel", "difficulty":"Normal", "elo":750, "nexus":1400, "style":"Táctico", "desc":"Busca jaques, capturas y respuestas concretas.", "calibration_quality":0.797185185185185, "acceptable_rate":0.4, "blunder_rate":0.233333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.62,"development":0.55,"king_safety":0.48,"center":0.63,"simplification":0.32,"risk":0.55}},
		{"id":"ines", "name":"Inés", "difficulty":"Normal", "elo":800, "nexus":1600, "style":"Equilibrada", "desc":"Combina seguridad y actividad con pocos errores grandes.", "calibration_quality":0.851722222222222, "acceptable_rate":0.5, "blunder_rate":0.133333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.54,"development":0.70,"king_safety":0.67,"center":0.68,"simplification":0.55,"risk":0.32}},
		# DIFÍCIL · 4
		{"id":"dante", "name":"Dante", "difficulty":"Difícil", "elo":900, "nexus":1700, "style":"Combativo", "desc":"Presiona con iniciativa y calcula pequeñas secuencias.", "calibration_quality":0.815611111111111, "acceptable_rate":0.4, "blunder_rate":0.166666666666667, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.68,"development":0.68,"king_safety":0.62,"center":0.70,"simplification":0.35,"risk":0.45}},
		{"id":"maia", "name":"Maia", "difficulty":"Difícil", "elo":1000, "nexus":1900, "style":"Técnica", "desc":"Reduce errores y mantiene posiciones sanas.", "calibration_quality":0.843388888888889, "acceptable_rate":0.466666666666667, "blunder_rate":0.133333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.56,"development":0.76,"king_safety":0.78,"center":0.76,"simplification":0.66,"risk":0.25}},
		{"id":"rocco", "name":"Rocco", "difficulty":"Difícil", "elo":1100, "nexus":2100, "style":"Agresivo", "desc":"Busca complicaciones y castigos tácticos con más precisión.", "calibration_quality":0.881333333333333, "acceptable_rate":0.6, "blunder_rate":0.1, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.82,"development":0.70,"king_safety":0.58,"center":0.72,"simplification":0.22,"risk":0.65}},
		{"id":"iris", "name":"Iris", "difficulty":"Difícil", "elo":1200, "nexus":2300, "style":"Precisa", "desc":"Encuentra recursos tácticos y planes a medio plazo.", "calibration_quality":0.880925925925926, "acceptable_rate":0.633333333333333, "blunder_rate":0.166666666666667, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.64,"development":0.82,"king_safety":0.82,"center":0.82,"simplification":0.72,"risk":0.20}},
		# MUY DIFÍCIL · 4
		{"id":"atlas", "name":"Atlas", "difficulty":"Muy difícil", "elo":1350, "nexus":2450, "style":"Profundo", "desc":"Calcula variantes cortas y castiga imprecisiones con constancia.", "calibration_quality":0.905277777777778, "acceptable_rate":0.766666666666667, "blunder_rate":0.133333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.64,"development":0.88,"king_safety":0.88,"center":0.84,"simplification":0.78,"risk":0.18}},
		{"id":"nadir", "name":"Nadir", "difficulty":"Muy difícil", "elo":1450, "nexus":2600, "style":"Sólido", "desc":"Muy pocos errores graves y excelente defensa.", "calibration_quality":0.915537037037037, "acceptable_rate":0.7, "blunder_rate":0.0666666666666667, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.52,"development":0.90,"king_safety":0.95,"center":0.82,"simplification":0.90,"risk":0.10}},
		{"id":"vega", "name":"Vega", "difficulty":"Muy difícil", "elo":1550, "nexus":2750, "style":"Dinámica", "desc":"Juega posiciones complejas con iniciativa y precisión.", "calibration_quality":0.977907407407407, "acceptable_rate":0.966666666666667, "blunder_rate":0.0333333333333333, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.86,"development":0.84,"king_safety":0.82,"center":0.88,"simplification":0.38,"risk":0.58}},
		{"id":"kiro", "name":"Kiro", "difficulty":"Muy difícil", "elo":1650, "nexus":2800, "style":"Exacto", "desc":"Combina cálculo, seguridad y técnica con muy poco ruido.", "calibration_quality":0.997851851851852, "acceptable_rate":1.0, "blunder_rate":0.0, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.70,"development":0.96,"king_safety":0.96,"center":0.92,"simplification":0.86,"risk":0.08}},
		# EXTREMO · 4
		{"id":"soren", "name":"Soren", "difficulty":"Extremo", "elo":1750, "nexus":2850, "style":"Élite", "desc":"Exige precisión constante y aprovecha casi cualquier concesión.", "calibration_quality":0.997703703703704, "acceptable_rate":1.0, "blunder_rate":0.0, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.74,"development":0.98,"king_safety":0.98,"center":0.94,"simplification":0.90,"risk":0.08}},
		{"id":"helix", "name":"Helix", "difficulty":"Extremo", "elo":1775, "nexus":2900, "style":"Cálculo", "desc":"Busca recursos tácticos muy precisos y minimiza concesiones.", "calibration_quality":0.997555555555556, "acceptable_rate":1.0, "blunder_rate":0.0, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.80,"development":0.97,"king_safety":0.94,"center":0.96,"simplification":0.74,"risk":0.22}},
		{"id":"kael", "name":"Kael", "difficulty":"Extremo", "elo":1790, "nexus":2950, "style":"Universal", "desc":"Juega bien posiciones tácticas, técnicas y defensivas.", "calibration_quality":0.997703703703704, "acceptable_rate":1.0, "blunder_rate":0.0, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.72,"development":0.99,"king_safety":0.99,"center":0.98,"simplification":0.82,"risk":0.10}},
		{"id":"aegis", "name":"Aegis", "difficulty":"Extremo", "elo":1800, "nexus":3000, "style":"Máximo", "desc":"El desafío más fuerte disponible en el motor actual.", "calibration_quality":0.997555555555556, "acceptable_rate":1.0, "blunder_rate":0.0, "avatar":"res://assets/avatars/avatar_bot.svg", "behavior":{"aggression":0.78,"development":1.0,"king_safety":1.0,"center":1.0,"simplification":0.88,"risk":0.05}},
	]

static func get_profile(bot_id: String) -> Dictionary:
	for item in profiles():
		if String(item["id"]) == bot_id:
			return item.duplicate(true)
	return get_profile(DEFAULT_BOT)

static func name_for(bot_id: String) -> String:
	return String(get_profile(bot_id).get("name", "Mateo"))

static func elo_for(bot_id: String) -> int:
	return int(get_profile(bot_id).get("elo", MIN_ELO))

static func nexus_for(bot_id: String) -> int:
	return int(get_profile(bot_id).get("nexus", MIN_NEXUS))

static func difficulty_for(bot_id: String) -> String:
	return String(get_profile(bot_id).get("difficulty", "Normal"))

static func thinking_time_for(bot_id: String) -> float:
	var elo := elo_for(bot_id)
	if elo <= 400: return 1.95
	if elo <= 700: return lerpf(1.95, 1.65, float(elo - 400) / 300.0)
	if elo <= 1000: return lerpf(1.65, 1.35, float(elo - 700) / 300.0)
	if elo <= 1300: return lerpf(1.35, 1.08, float(elo - 1000) / 300.0)
	return lerpf(1.08, 0.90, float(elo - 1300) / 500.0)

static func thinking_delay_for(bot_id: String, rng: RandomNumberGenerator) -> float:
	var base := thinking_time_for(bot_id)
	var jitter := 0.12
	var elo := elo_for(bot_id)
	if elo >= 1300:
		jitter = 0.10
	elif elo >= 700:
		jitter = 0.14
	return clampf(base + rng.randf_range(-jitter, jitter), 0.80, 2.20)

static func behavior_for(bot_id: String) -> Dictionary:
	var behavior: Variant = get_profile(bot_id).get("behavior", {})
	return behavior.duplicate(true) if behavior is Dictionary else {}
