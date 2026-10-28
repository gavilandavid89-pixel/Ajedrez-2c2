extends RefCounted
class_name ChessAuthProviderContract

## Provider-neutral contract. Android providers must return a stable account_id,
## short-lived session_token and optional profile fields. Tokens never belong in
## PlayerData or the persistent profile snapshot.

const FIELDS := ["account_id", "display_name", "email", "photo_url", "email_verified"]

static func sanitize_identity(provider: String, raw: Dictionary) -> Dictionary:
    var result := {"provider": provider}
    for field in FIELDS:
        if raw.has(field):
            result[field] = raw[field]
    return result
