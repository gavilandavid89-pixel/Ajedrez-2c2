extends RefCounted
class_name NavigationService

const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const ScreenCatalogScript = preload("res://core/navigation/screen_catalog.gd")

static func go(target: String) -> int:
    var routes := ScreenCatalogScript.all()
    var path := target if target.begins_with("res://") else String(routes.get(target, ""))
    if path.is_empty():
        return ERR_DOES_NOT_EXIST
    return RuntimeServicesScript.change_scene(path)
