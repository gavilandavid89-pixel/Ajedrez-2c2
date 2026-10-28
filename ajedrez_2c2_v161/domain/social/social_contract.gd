extends RefCounted
class_name SocialContract

const VERSION := 1
const OWNER_MODULE := "domain/social"

static func module_id() -> String:
    return OWNER_MODULE

static func version() -> int:
    return VERSION
