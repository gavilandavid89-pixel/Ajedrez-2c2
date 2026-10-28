extends Node

## Cross-screen signals for consistent chessboard feedback.
signal board_state_changed(source: String, state: Dictionary)
signal move_animation_started(source: String, move: Dictionary)
signal move_animation_finished(source: String, move: Dictionary)
signal square_highlight_changed(source: String, from_square: String, to_square: String, kind: String)
signal piece_selected(source: String, square: String)
signal analysis_variation_changed(source: String, variation: Array)
signal board_presentation_changed(source: String, flipped: bool, board_theme: String, piece_set: String)
signal board_interaction_changed(source: String, selected_square: String, legal_destinations: Array)
signal move_committed(source: String, move: Dictionary)
signal board_focus_requested(source: String, square: String)

## Semantic event identifiers are stable API: screens should not invent spellings.
const SOURCE_MATCH := "match"
const SOURCE_REPLAY := "replay"
const SOURCE_ANALYSIS := "analysis"
const SOURCE_STUDY := "study"
const SOURCE_PUZZLE := "puzzle"
const HIGHLIGHT_LAST_MOVE := "last_move"
const HIGHLIGHT_SELECTED := "selected"
const HIGHLIGHT_SUGGESTION := "suggestion"
const HIGHLIGHT_ERROR := "error"
const VALID_SOURCES := [SOURCE_MATCH, SOURCE_REPLAY, SOURCE_ANALYSIS, SOURCE_STUDY, SOURCE_PUZZLE]
const VALID_HIGHLIGHTS := [HIGHLIGHT_LAST_MOVE, HIGHLIGHT_SELECTED, HIGHLIGHT_SUGGESTION, HIGHLIGHT_ERROR]

static func is_valid_square(square: String) -> bool:
    if square.length() != 2:
        return false
    var file_code := square.to_lower().unicode_at(0)
    var rank_code := square.unicode_at(1)
    return file_code >= 97 and file_code <= 104 and rank_code >= 49 and rank_code <= 56

static func normalize_square(square: String) -> String:
    var clean := square.strip_edges().to_lower()
    return clean if is_valid_square(clean) else ""

func _valid_source(source: String) -> bool:
    return VALID_SOURCES.has(source)

func publish_state(source: String, state: Dictionary) -> void:
    if not _valid_source(source):
        return
    board_state_changed.emit(source, state.duplicate(true))

func publish_highlight(source: String, from_square: String, to_square: String, kind: String) -> void:
    if not _valid_source(source) or not VALID_HIGHLIGHTS.has(kind):
        return
    var clean_from := normalize_square(from_square)
    var clean_to := normalize_square(to_square)
    if clean_from.is_empty() or clean_to.is_empty():
        return
    square_highlight_changed.emit(source, clean_from, clean_to, kind)

func publish_move_started(source: String, move: Dictionary) -> void:
    if _valid_source(source) and _valid_move(move):
        move_animation_started.emit(source, move.duplicate(true))

func publish_move_finished(source: String, move: Dictionary) -> void:
    if _valid_source(source) and _valid_move(move):
        move_animation_finished.emit(source, move.duplicate(true))

func publish_move_committed(source: String, move: Dictionary) -> void:
    if _valid_source(source) and _valid_move(move):
        move_committed.emit(source, move.duplicate(true))

func publish_presentation(source: String, flipped: bool, board_theme: String, piece_set: String) -> void:
    if not _valid_source(source):
        return
    board_presentation_changed.emit(source, flipped, board_theme, piece_set)

func publish_interaction(source: String, selected_square: String, legal_destinations: Array = []) -> void:
    if not _valid_source(source):
        return
    var selected_clean := normalize_square(selected_square)
    var destinations: Array[String] = []
    for item in legal_destinations:
        var square := normalize_square(String(item))
        if not square.is_empty() and not destinations.has(square):
            destinations.append(square)
    board_interaction_changed.emit(source, selected_clean, destinations)

func request_focus(source: String, square: String) -> void:
    var clean_square := normalize_square(square)
    if _valid_source(source) and not clean_square.is_empty():
        board_focus_requested.emit(source, clean_square)

func _valid_move(move: Dictionary) -> bool:
    return normalize_square(String(move.get("from", ""))) != "" and normalize_square(String(move.get("to", ""))) != ""

func publish_selection(source: String, square: String) -> void:
    if not _valid_source(source):
        return
    var clean_square := normalize_square(square)
    if square.strip_edges().is_empty() or not clean_square.is_empty():
        piece_selected.emit(source, clean_square)

func publish_variation(source: String, variation: Array) -> void:
    if _valid_source(source):
        analysis_variation_changed.emit(source, variation.duplicate(true))
