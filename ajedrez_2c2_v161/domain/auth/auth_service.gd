extends Node
class_name ChessAuthService

signal auth_changed(state: Dictionary)
signal message_changed(message: String)

const STATE_PATH := "user://ajedrez_2c2/account_auth.json"
const SCHEMA_VERSION := 1
const PROVIDER_GOOGLE := "google"
const PROVIDER_FACEBOOK := "facebook"
const PROVIDER_PLAY_GAMES := "play_games"
const PROVIDER_EMAIL := "email"
const PROVIDER_GUEST := "guest"
const EXTERNAL_PROVIDERS := [PROVIDER_GOOGLE, PROVIDER_FACEBOOK, PROVIDER_PLAY_GAMES, PROVIDER_EMAIL]

var state: Dictionary = {
    "status": "anonymous",
    "provider": "",
    "account_id": "",
    "display_name": "",
    "email": "",
    "photo_url": "",
    "email_verified": false,
    "linked_providers": [],
    "last_error": "",
    "updated_at": 0,
}
var session_token := ""
var refresh_token := ""
var _bridge: Object = null

func _ready() -> void:
    _load_state()
    _bind_native_bridge()
    call_deferred("_restore_native_session")
    call_deferred("_emit_state")

func _restore_native_session() -> void:
    if String(state.get("status", "")) != "linked":
        return
    if _bridge != null and _bridge.has_method("restore_session"):
        _bridge.restore_session()
    else:
        message_changed.emit("Cuenta vinculada en este dispositivo. Falta validar la sesión con el proveedor Android.")

func _bind_native_bridge() -> void:
    if Engine.has_singleton("AjedrezAuthAndroid"):
        _bridge = Engine.get_singleton("AjedrezAuthAndroid")
        if _bridge != null and _bridge.has_signal("auth_result"):
            _bridge.auth_result.connect(_on_native_auth_result)
        if _bridge != null and _bridge.has_signal("profile_result"):
            _bridge.profile_result.connect(_on_native_profile_result)

func is_authenticated() -> bool:
    return String(state.get("status", "anonymous")) == "authenticated" and not String(state.get("account_id", "")).is_empty()

func current_account() -> Dictionary:
    return state.duplicate(true)

func provider_available(provider: String) -> bool:
    if provider == PROVIDER_GUEST:
        return true
    if _bridge != null and _bridge.has_method("is_provider_available"):
        return bool(_bridge.is_provider_available(provider))
    return false

func sign_in(provider: String) -> Dictionary:
    if provider not in EXTERNAL_PROVIDERS:
        return _fail("Proveedor no soportado")
    if _bridge == null:
        var message := "El conector Android de cuentas no está instalado todavía"
        message_changed.emit(message)
        return {"ok": false, "status": "unavailable", "reason": message}
    state["status"] = "connecting"
    state["last_error"] = ""
    state["updated_at"] = Time.get_unix_time_from_system()
    _emit_state()
    if _bridge.has_method("sign_in"):
        _bridge.sign_in(provider)
        return {"ok": true, "status": "connecting", "provider": provider}
    return _fail("El conector de cuentas no expone sign_in")

func sign_out() -> void:
    if _bridge != null and _bridge.has_method("sign_out"):
        _bridge.sign_out()
    session_token = ""
    refresh_token = ""
    state["status"] = "anonymous"
    state["provider"] = ""
    state["account_id"] = ""
    state["last_error"] = ""
    state["updated_at"] = Time.get_unix_time_from_system()
    _save_state()
    message_changed.emit("Sesión cerrada. Tu progreso local sigue en este dispositivo.")
    _emit_state()

func link_provider(provider: String) -> Dictionary:
    if not is_authenticated():
        return _fail("Primero inicia sesión con una cuenta")
    if provider not in EXTERNAL_PROVIDERS:
        return _fail("Proveedor no soportado")
    if _bridge == null or not _bridge.has_method("link_provider"):
        return _fail("El conector Android no está preparado para vincular ese proveedor")
    _bridge.link_provider(provider)
    return {"ok": true, "status": "connecting", "provider": provider}

func request_profile_data(fields: Array[String] = ["display_name", "email", "photo_url", "email_verified"]) -> Dictionary:
    if not is_authenticated():
        return _fail("No hay una cuenta autenticada")
    if _bridge == null or not _bridge.has_method("request_profile_data"):
        return {
            "ok": true,
            "status": "local_cache",
            "fields": fields.duplicate(),
            "data": _pick_fields(state, fields),
        }
    _bridge.request_profile_data(fields)
    return {"ok": true, "status": "requested", "fields": fields.duplicate()}

func accept_external_identity(provider: String, identity: Dictionary) -> Dictionary:
    if provider not in EXTERNAL_PROVIDERS:
        return _fail("Proveedor no soportado")
    var account_id := String(identity.get("account_id", identity.get("sub", ""))).strip_edges()
    if account_id.is_empty():
        return _fail("La identidad externa no contiene un identificador estable")
    state["status"] = "authenticated"
    state["provider"] = provider
    state["account_id"] = account_id
    state["display_name"] = String(identity.get("display_name", state.get("display_name", "")))
    state["email"] = String(identity.get("email", state.get("email", "")))
    state["photo_url"] = String(identity.get("photo_url", state.get("photo_url", "")))
    state["email_verified"] = bool(identity.get("email_verified", false))
    var linked: Array = state.get("linked_providers", []) if state.get("linked_providers", []) is Array else []
    if not linked.has(provider):
        linked.append(provider)
    state["linked_providers"] = linked
    state["last_error"] = ""
    state["updated_at"] = Time.get_unix_time_from_system()
    session_token = String(identity.get("session_token", ""))
    refresh_token = String(identity.get("refresh_token", ""))
    _save_state()
    _emit_state()
    return {"ok": true, "status": "authenticated", "account": state.duplicate(true)}

func provider_label(provider: String) -> String:
    match provider:
        PROVIDER_GOOGLE: return "Google"
        PROVIDER_FACEBOOK: return "Facebook"
        PROVIDER_PLAY_GAMES: return "Google Play Juegos"
        PROVIDER_EMAIL: return "Correo electrónico"
        _: return provider

func _on_native_auth_result(provider: String, success: bool, payload: Dictionary) -> void:
    if not success:
        _fail(String(payload.get("error", "No se pudo iniciar sesión")))
        return
    accept_external_identity(provider, payload)

func _on_native_profile_result(success: bool, payload: Dictionary) -> void:
    if not success:
        message_changed.emit(String(payload.get("error", "No se pudo obtener la información del perfil")))
        return
    for key in ["display_name", "email", "photo_url", "email_verified"]:
        if payload.has(key):
            state[key] = payload[key]
    state["updated_at"] = Time.get_unix_time_from_system()
    _save_state()
    _emit_state()

func _pick_fields(source: Dictionary, fields: Array[String]) -> Dictionary:
    var result: Dictionary = {}
    for field in fields:
        if source.has(field):
            result[field] = source[field]
    return result

func _fail(message: String) -> Dictionary:
    state["status"] = "error"
    state["last_error"] = message
    state["updated_at"] = Time.get_unix_time_from_system()
    _save_state()
    message_changed.emit(message)
    _emit_state()
    return {"ok": false, "status": "error", "reason": message}

func _emit_state() -> void:
    auth_changed.emit(state.duplicate(true))

func _load_state() -> void:
    if not FileAccess.file_exists(STATE_PATH):
        return
    var file := FileAccess.open(STATE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary and int(parsed.get("schema_version", 0)) == SCHEMA_VERSION:
        var stored: Dictionary = parsed.get("state", {}) if parsed.get("state", {}) is Dictionary else {}
        for key in state.keys():
            if stored.has(key):
                state[key] = stored[key]
        # No tratamos una identidad persistida como una sesión válida: los tokens nunca se guardan.
        if String(state.get("status", "")) == "authenticated" and not String(state.get("account_id", "")).is_empty():
            state["status"] = "linked"

func _save_state() -> void:
    var file := FileAccess.open(STATE_PATH, FileAccess.WRITE)
    if file == null:
        return
    file.store_string(JSON.stringify({"schema_version": SCHEMA_VERSION, "state": state}))
    file.close()
