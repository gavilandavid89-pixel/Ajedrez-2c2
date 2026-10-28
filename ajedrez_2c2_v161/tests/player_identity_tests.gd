extends RefCounted

func run(data: Node) -> Dictionary:
    var report := {"passed": 0, "failed": 0, "checks": []}
    _check(report, not String(data.profile.get("id", "")).is_empty(), "El jugador tiene ID interno")
    _check(report, String(data.profile.get("id", "")).begins_with("USR_"), "El ID usa prefijo de sistema")
    var before := String(data.profile.get("id", ""))
    _check(report, data.set_display_name("ABCDEFGHIJ"), "Acepta exactamente 10 caracteres")
    _check(report, String(data.profile.get("name", "")).length() == 10, "El nombre queda limitado a 10")
    _check(report, not data.set_display_name("ABCDEFGHIJK"), "Rechaza 11 caracteres")
    _check(report, String(data.profile.get("id", "")) == before, "Cambiar nombre no cambia el ID")
    var key: String = data.pair_key("Compañero", "USR_LOCAL_MATE")
    _check(report, key.begins_with("pair:"), "Las parejas pueden usar IDs internos")
    return report

func _check(report: Dictionary, ok: bool, label: String) -> void:
    if ok:
        report["passed"] += 1
    else:
        report["failed"] += 1
    report["checks"].append({"label": label, "ok": ok})
