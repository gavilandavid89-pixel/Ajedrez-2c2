# Entorno de calibración NEXUS

El juego registra resultados competitivos en `user://nexus_competitive_telemetry.jsonl`.

La telemetría no incluye nombres, emails, IP, chat ni replay. Los jugadores se representan
con una clave SHA-256 estable para poder estudiar trayectorias sin guardar la identidad visible.

## Cuando exista servidor

Configurar una sola vez desde el servicio:

```gdscript
CompetitiveTelemetry.configure_server("https://tu-servidor.example")
```

El cliente enviará lotes a `/v1/telemetry/nexus`. Si falla la red, los eventos permanecen en el
buffer local y se reintentan más tarde.

## Datos útiles para NEXUS

- rating antes/después y delta
- rating del rival y pareja antes de la partida
- expectativa y sorpresa
- incertidumbre antes/después
- expectativa/incertidumbre de pareja
- efecto de pareja
- modo y resultado
- temporada
- cantidad de movimientos y duración
- bot y NEXUS objetivo cuando corresponda

No se usa telemetría para dar puntos durante la partida: primero se recopila y luego se calibra
fuera de línea.

## Laboratorio

Exportar el buffer y analizarlo:

```text
python3 tools/nexus_calibration_lab.py telemetry_export.jsonl --pretty
```

El laboratorio calcula LogLoss, Brier, error de calibración, sorpresa media, evolución de
incertidumbre, distribución por modo y muestras por diferencia de rating.
