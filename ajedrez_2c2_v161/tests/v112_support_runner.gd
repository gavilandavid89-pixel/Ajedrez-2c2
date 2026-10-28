extends SceneTree
const ReviewTests = preload("res://tests/engine_review_integration_tests.gd")
const UciTests = preload("res://tests/stockfish_uci_protocol_tests.gd")
func _initialize() -> void:
    var review = ReviewTests.new().run()
    var uci = UciTests.new().run()
    print("ENGINE REVIEW: %d/%d OK, %d fallos" % [int(review.get("passed", 0)), int(review.get("total", 0)), Array(review.get("failed", [])).size()])
    print("UCI: %d/9 OK, %d fallos" % [int(uci.get("passed", 0)), Array(uci.get("failed", [])).size()])
    quit(0 if Array(review.get("failed", [])).is_empty() and Array(uci.get("failed", [])).is_empty() else 1)
