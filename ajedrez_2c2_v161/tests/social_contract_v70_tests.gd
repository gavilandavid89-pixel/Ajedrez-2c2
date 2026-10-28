extends RefCounted

const Contract := preload("res://domain/social/social_contract.gd")

func run() -> Dictionary:
    var failures: Array[String] = []
    var checks := 0
    checks += 1
    if Contract.module_id() != "domain/social":
        failures.append("social module id incorrect")
    checks += 1
    if Contract.version() != 1:
        failures.append("social contract version incorrect")
    return {"checks": checks, "failures": failures}
