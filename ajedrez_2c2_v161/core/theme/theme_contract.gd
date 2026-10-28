extends RefCounted
class_name ThemeContract

const VERSION := 1
const OWNER_MODULE := "core/theme"

static func module_id() -> String:
    return OWNER_MODULE

static func version() -> int:
    return VERSION
