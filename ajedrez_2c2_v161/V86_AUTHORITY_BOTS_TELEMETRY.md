# V86 — Autoridad de clubes + calibración de bots + telemetría NEXUS

## Alter ego 1 — autoridad / seguridad
- Rey y Dama pueden asignar roles sin poder gestionar a alguien por encima de su rango.
- Asignar el propio rango a un objetivo inferior hace un intercambio: objetivo toma el rango del actor y actor toma el rango anterior del objetivo.
- El Rey puede reorganizar cualquier rango inferior.
- La Dama puede reorganizar rangos inferiores o reemplazarse con uno de ellos mediante el intercambio.
- El Rey puede expulsar cualquier miembro salvo sí mismo; la Dama puede expulsar rangos inferiores.
- Las solicitudes de ingreso de clubes privados por NEXUS quedan aprobadas/rechazadas solo por Rey o Dama.
- Nunca se crea un segundo Rey.

## Alter ego 2 — estadística / NEXUS
- Los 20 bots siguen divididos 4/4/4/4/4.
- Fácil y Normal conservan 200..1600.
- Difícil: 1700, 1900, 2100, 2300.
- Muy difícil: 2450, 2600, 2750, 2800.
- Extremo: 2850, 2900, 2950, 3000.
- El NEXUS objetivo del bot y el rating interno del motor se registran por separado.
- No se declarará que un bot equivale realmente a un humano de ese NEXUS hasta disponer de resultados reales.

## Telemetría
Se agregó `CompetitiveTelemetry` como autoload. Registra solo señales necesarias para calibrar NEXUS:
expectativa, sorpresa, rating antes/después, incertidumbre, fuerza rival, estado de pareja, resultado,
modo, temporada y datos separados del bot.

No guarda nombres, email, IP, chat ni replay. El jugador se representa con SHA-256 estable.

Buffer local: `user://nexus_competitive_telemetry.jsonl`.
Servidor preparado: `telemetry/server/server.js`, endpoint `/v1/telemetry/nexus`.
Laboratorio offline: `tools/nexus_calibration_lab.py`.

## Importante
La telemetría es observacional. No modifica NEXUS durante la partida ni introduce puntos por
capturas, movimientos, Sugerir, Cambio, tiempo o reacciones.

## Validación disponible en este entorno
- Revisión estática de delimitadores en archivos modificados: consistente.
- Laboratorio Python ejecutado con lote de muestra correctamente.
- Tests V86 preparados: autoridad de clubes, bots y telemetría.

No se afirma una ejecución de Godot 4.7.2 en esta pasada porque el binario de Godot no está presente
en el entorno actual. La validación real de Godot debe ejecutarse antes de considerar V86 como build final.
