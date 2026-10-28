extends RefCounted
class_name MoveClassificationStyle

# Presentation only: classifications are produced by the existing review service.
# This module never reclassifies a move or invents a missing result.
const COLORS := {
    "Error grave": Color("#D94B4B"),
    "Error": Color("#E06B5E"),
    "Imprecisa": Color("#D9A441"),
    "Bien": Color("#77B96A"),
    "Muy bien": Color("#63C96B"),
    "Excelente": Color("#45D36B"),
    "Genial": Color("#61A8FF"),
    "Brillante": Color("#C07CFF"),
    "Oportunidad perdida": Color("#D9A441"),
}

const IMPORTANT := [
    "Brillante", "Genial", "Excelente", "Muy bien", "Imprecisa",
    "Error", "Error grave", "Oportunidad perdida"
]

static func color_for(classification: String, fallback: Color) -> Color:
    return COLORS.get(classification.strip_edges(), fallback)

static func is_important(classification: String) -> bool:
    return IMPORTANT.has(classification.strip_edges())

static func has_classification(classification: String) -> bool:
    return COLORS.has(classification.strip_edges())
