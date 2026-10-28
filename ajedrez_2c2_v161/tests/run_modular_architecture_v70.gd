extends SceneTree

const Suite := preload("res://tests/modular_architecture_tests.gd")
const Contract := preload("res://tests/social_contract_v70_tests.gd")

func _initialize() -> void:
    var suite := Suite.new().run()
    var contract := Contract.new().run()
    print("ARCHITECTURE V70: %d OK / %d FALLARON" % [int(suite.get("checks",0)) - suite.get("failures",[]).size() + int(contract.get("checks",0)) - contract.get("failures",[]).size(), suite.get("failures",[]).size() + contract.get("failures",[]).size()])
    for failure in suite.get("failures",[]):
        push_error(String(failure))
    for failure in contract.get("failures",[]):
        push_error(String(failure))
    quit(1 if not suite.get("failures",[]).is_empty() or not contract.get("failures",[]).is_empty() else 0)
