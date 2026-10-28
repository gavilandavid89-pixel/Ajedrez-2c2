# Ajedrez Auth Android — contrato V87

Esta carpeta define el contrato que espera `AuthService` para conectar autenticación nativa en Android. No contiene credenciales ni activa un plugin por sí sola.

## Singleton Godot

Nombre: `AjedrezAuthAndroid`

Métodos esperados:
- `is_provider_available(provider: String) -> bool`
- `sign_in(provider: String)`
- `link_provider(provider: String)`
- `request_profile_data(fields: Array[String])`
- `restore_session()`
- `sign_out()`

Señales:
- `auth_result(provider: String, success: bool, payload: Dictionary)`
- `profile_result(success: bool, payload: Dictionary)`

Payload de identidad aceptado por `AuthService`:
`account_id` o `sub`, `display_name`, `email`, `photo_url`, `email_verified`, `session_token` (solo memoria).

Los tokens de sesión/refresco nunca forman parte de `PlayerData.export_account_snapshot()`.

## Proveedores

- Google: Android Credential Manager + Sign in with Google.
- Facebook: proveedor OAuth/Firebase Authentication.
- Google Play Juegos: Play Games Services v2; no usar la API Google Sign-In antigua.
- Correo: proveedor de email/password o enlace seguro de recuperación.

## Vinculación

El backend debe considerar `account_id` como identidad estable y exigir validación del token antes de leer/escribir progreso. Si una segunda cuenta externa pretende vincularse a una cuenta de juego existente, la operación debe ser explícita y nunca sobrescribir progreso silenciosamente.

## Configuración que queda pendiente

No se deben introducir secretos en el repositorio. Para habilitar producción faltan los IDs/configuración de Google OAuth, Facebook, Play Console/Play Games y el backend de validación.
