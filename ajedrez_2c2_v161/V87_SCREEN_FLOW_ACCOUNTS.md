# V87 — flujo completo de pantallas + cuentas

## Auditoría de pantallas

Se recorren las 18 rutas registradas en `ScreenCatalog.all()`. La auditoría no se limita a instanciar y salir: interactúa con los controles encontrados, campos de texto, selectores, sliders, casillas, popups y diálogos.

Resultado Godot 4.7.2: **18 OK / 0 fallos / 255 interacciones**.

`loading` queda como excepción esperada: es una pantalla transitoria de progreso y no necesita controles interactivos.

## Hallazgos corregidos

- Chat de club: faltaba selector de emoticonos; ahora usa las reacciones equipadas y las guarda como eventos `emote`.
- Amigos: existía la lógica de solicitudes pero faltaba la bandeja visual; ahora hay aceptar/rechazar.
- Identidad de club: un perfil local sin ID podía impedir entrar al club; ahora se usa `local_player` como respaldo seguro.
- Creación de club: el fundador podía quedar sin ID si PlayerData todavía no había completado su identidad; se centralizó en `_local_identity()`.
- Diálogos de perfil del club: no se destruían tras confirmar/cancelar; ahora se liberan correctamente.
- Portapapeles: la ruta de pegar código se hace inocua en `headless`, evitando falsos errores de QA.
- Gestión de partida: `ChessGameSocialService` pasó a `RefCounted`, evitando fugas de nodos auxiliares al cerrar la pantalla de partida.

## Cuenta y progreso

Se añadió `AuthService` con proveedores Google, Facebook, Google Play Juegos y correo. La identidad persistida contiene únicamente metadatos necesarios para reconocer la cuenta; los tokens de sesión/refresco se mantienen en memoria. Una identidad guardada se reabre como `linked`, no como sesión autenticada, hasta que el conector Android valide/restaure la sesión.

`AccountSyncService` exporta e importa el snapshot de progreso de `PlayerData`, mantiene una revisión local y no sobrescribe un estado remoto divergente automáticamente. En conflicto se ofrecen `Conservar este dispositivo` o `Restaurar nube`.

`CloudSync` está conectado a un transporte HTTP preparado para:

- `GET /v1/account/snapshot?account_id=...`
- `POST /v1/account/bootstrap`
- `POST /v1/account/snapshot`
- `POST /v1/account/events`

El collector local guarda cuentas por SHA-256 del identificador estable y rechaza una revisión local más antigua que la remota.

## Integración Android pendiente

El contrato `addons/ajedrez_auth_android/contract.json` deja definida la interfaz `AjedrezAuthAndroid` que espera `AuthService`. La implementación Android real debe usar Credential Manager para Google y Play Games Services v2 para Google Play Juegos. No se incluyeron secretos ni IDs reales.

Para producción todavía hay que configurar los IDs de proveedor, la validación del token en backend, HTTPS, rate limiting, retención y el AAR/plugin Android correspondiente.

## QA de regresión

Suite relevante V87:

- runner principal: 39/39
- auth/social V87: 16/16
- autoridad de clubs V86: 21/21
- roles/accesos V85: 171/171
- telemetría NEXUS V86: 13/13
- social V71: 9/9
- social V70: 36/36
- juego/social V85: 25/25
- bots: 267/267
- storage: 18/18
- online setup: 37/37
- orientación/layout: 22/22
- navegación: 18/18

La importación del editor/headless de Godot 4.7.2 termina sin errores de parseo.
