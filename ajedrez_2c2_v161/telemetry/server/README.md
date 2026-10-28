# Collector de telemetría NEXUS

Servidor mínimo para conectar después al backend real.

## Arranque

```bash
NEXUS_TELEMETRY_TOKEN=secreto node telemetry/server/server.js
```

- `GET /health`
- `POST /v1/telemetry/nexus`
- Guarda eventos en `telemetry/server/data/events.jsonl`.

El collector rechaza eventos que no cumplen el schema V1. No calcula ni modifica NEXUS:
su función es conservar datos para el laboratorio offline.

En producción debe ir detrás de HTTPS, autenticación, rate limit y una política de retención.


## Respaldo de cuenta V87

Además del collector NEXUS, el mismo servidor deja preparados estos endpoints para `CloudSync`:

- `GET /v1/account/snapshot?account_id=...`
- `POST /v1/account/bootstrap`
- `POST /v1/account/snapshot`
- `POST /v1/account/events`

El snapshot debe llevar `schema_version >= 2`. El servidor guarda cada cuenta en un archivo cuyo nombre es un SHA-256 del identificador estable, no el identificador en texto plano. Si llega una revisión menor que la remota, responde `409 conflict` y devuelve el snapshot remoto para que el cliente decida entre conservar local o restaurar nube.

Este servidor es un adaptador de almacenamiento mínimo, no un backend de autenticación completo. En producción el bearer token debe validarse contra Google/Firebase/Facebook/Play Games y deben añadirse HTTPS, rate limit, rotación de claves, control de acceso y política de retención.
