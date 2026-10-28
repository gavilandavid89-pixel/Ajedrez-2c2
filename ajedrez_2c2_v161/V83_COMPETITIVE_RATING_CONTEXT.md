# Ajedrez 2c2 — V83
## Contexto competitivo real: rival individual vs rival de pareja

### Objetivo
Separar correctamente las dos evidencias competitivas que existen en 2c2:

- NEXUS-SOLO 2c2: aprende de la fuerza individual de los rivales.
- NEXUS-TEAM: aprende de la fuerza de la pareja rival.

Antes de V83, `record_result()` podía recibir `opponent_pair_rating` y usarlo también para actualizar el NEXUS individual 2c2. Eso mezclaba dos conceptos que el diseño del proyecto mantiene independientes.

### Cambios
- Nuevo `domain/competitive/match_context.gd` como contrato normalizado para el snapshot competitivo de una partida.
- `App.competitive_match_context` conserva el snapshot entre matchmaking y la partida.
- Matchmaking guarda rating e incertidumbre locales antes de entrar al tablero.
- El resultado consume el snapshot y pasa valores distintos para:
  - rival individual;
  - rival de pareja;
  - compañero.
- Si hay bots temporales, sus ELO definidos en `BotData` alimentan el snapshot de prueba en lugar de usar 1000 por defecto.
- El historial guarda `opponent_rating_before`, `opponent_pair_rating_before` y `partner_rating_before`.
- Los snapshots resueltos por la partida tienen prioridad sobre valores genéricos de fallback.
- Se conserva compatibilidad: si no existe snapshot, el sistema sigue usando los argumentos históricos/default.

### Qué NO cambia
- Ninguna regla de 2c2.
- Sugerir y Cambio.
- Turnos.
- Condiciones de victoria/derrota.
- Separación 1c1 / 2c2.
- NEXUS-TEAM como estado independiente.
- Copas y progresión.
- El rating no se expone públicamente con sus variables internas.

### Revisión crítica / alter ego
La revisión crítica buscó especialmente:
1. que el rating de pareja contaminara NEXUS individual;
2. que un snapshot viejo sobrescribiera el resultado real;
3. que faltaran ratings al jugar contra bots temporales;
4. que el fallback rompiera cuentas antiguas.

Resultado: el contrato da prioridad al snapshot resuelto, mantiene fallback compatible y separa las dos evidencias.

### QA real con Godot 4.7.2
- Import/editor: OK.
- Competitive System: 34/34.
- NEXUS-TEAM: 27/27.
- Match Context: 10/10.
- Matchmaking: 8/8.
- 1c1 progression: 5/5.
- Profile UI: 9/9.
- Account Hub: 149/149.
- Online setup: 37/37.
- Smoke real del proyecto a 720x720: proceso estable durante 14 s; sin `SCRIPT ERROR`, `Parse Error`, `Invalid call` ni errores de script.

Las advertencias de audio/V-Sync pertenecen al entorno Linux/Xvfb y no al código competitivo.

### Siguiente punto recomendado
El siguiente salto no debería ser otra modificación matemática de NEXUS. Conviene conectar este mismo contrato a una fuente online autoritativa para que el servidor entregue, por partida:
- rating individual de cada participante;
- rating de la pareja rival;
- incertidumbre/versionado del snapshot;
- identificadores de participantes;
- versión del cálculo.

Así el cliente deja de inferir ratings competitivos y solo consume el snapshot firmado/validado por la capa online cuando exista.
