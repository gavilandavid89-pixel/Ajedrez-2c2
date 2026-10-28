# Ajedrez 2c2 — V85 Clubes, Bots y mantenimiento social

Fecha: 2026-10-06
Motor validado: Godot 4.7.2 real
Viewport visual: 720x720

## 1. Clubes

Los clubes tienen un máximo real de 50 miembros.

Modos de acceso permitidos:

- Público: entrada directa.
- Privado por NEXUS: requisito entre 0 y 3000; el jugador solicita ingreso y una autoridad del club acepta o rechaza.
- Privado por invitación: solo entra mediante invitación emitida por una autoridad habilitada.

Jerarquía inspirada en piezas de ajedrez y diseñada para 50 plazas:

- ♚ Rey — 1 — fundador, autoridad máxima.
- ♛ Dama — hasta 2 — administración.
- ♜ Torre — hasta 3 — moderación y aprobación de solicitudes.
- ♝ Alfil — hasta 5 — oficiales/invitaciones.
- ♞ Caballo — hasta 9 — miembros destacados.
- ♟ Peón — plazas restantes, hasta completar 50.

La suma de las plazas máximas de cargos superiores es 20, dejando hasta 30 Peones.

El Rey es único y no puede duplicarse.

Permisos actuales:

- Rey/Dama/Torre: aceptar o rechazar solicitudes de ingreso.
- Rey/Dama/Torre/Alfil: emitir invitaciones.
- Rey/Dama+: gestionar roles inferiores respetando jerarquía y cupos.
- Nadie puede convertir a otro jugador en Rey.

El NEXUS utilizado para el requisito de club es el NEXUS individual 2c2 del jugador, no el NEXUS-TEAM de una pareja.

## 2. Retos amistosos 2c2

El reto usa cuatro slots visuales, por ejemplo:

`Eragon/🔍/🔍/🔍`

Cada aceptación sustituye un `🔍` por el participante correspondiente.

Flujo:

`UNIRME → ELEGIR COLOR → BLANCAS / NEGRAS`

La partida amistosa solo empieza cuando:

- hay cuatro participantes;
- hay exactamente dos jugadores en Blancas;
- hay exactamente dos jugadores en Negras.

El estado guarda IDs, nombres, bandos y relación de participantes. Las partidas de club continúan siendo amistosas: no afectan copas, rating, puntos de pareja ni NEXUS.

## 3. Bots

Se mantienen 20 bots totales. Para cumplir simultáneamente con 20 bots y cinco categorías, hay 4 bots por categoría.

### Fácil
Mateo — NEXUS 200
Nora — NEXUS 400
Lito — NEXUS 600
Cata — NEXUS 800

### Normal
Tadeo — NEXUS 1000
Vera — NEXUS 1200
Axel — NEXUS 1400
Inés — NEXUS 1600

### Difícil
Dante — NEXUS 1800
Maia — NEXUS 2000
Rocco — NEXUS 2150
Iris — NEXUS 2300

### Muy difícil
Atlas — NEXUS 2450
Nadir — NEXUS 2600
Vega — NEXUS 2750
Kiro — NEXUS 2850

### Extremo
Soren — NEXUS 2925
Helix — NEXUS 2950
Kael — NEXUS 2975
Aegis — NEXUS 3000

El NEXUS es la fuerza objetivo visible del bot. El motor conserva un Elo interno de compatibilidad para controlar profundidad, ruido y aleatoriedad; ese Elo no se presenta como el rating competitivo del jugador.

La selección VS IA muestra ahora NEXUS y la dificultad, no el Elo interno.

Se ejecutó el benchmark de decisiones del motor sobre el catálogo de 20 bots y se almacenaron sus métricas de calidad/aceptación/error en `bot_decision_benchmark.json`. El benchmark sirve como evidencia de comportamiento del motor, no como prueba de que un NEXUS 3000 equivalga a 3000 online humanos.

## 4. Mantenimiento de acciones 2c2

### Sugerir

- Solo 2c2.
- Solo puede proponerla el jugador local durante su turno.
- Una sugerencia activa no puede apilar otra.
- La pieza no se mueve al sugerir.
- El compañero recibe la propuesta.

### Aceptar

- Solo puede aceptarla el destinatario real.
- La aceptación cambia el estado a `accepted`.
- Aceptar no ejecuta automáticamente la jugada.

### Rechazar

- Solo puede rechazarla el destinatario real.
- La sugerencia se elimina inmediatamente.
- La interfaz usa el texto `Rechazar`, no `Cancelar`.

### Cuestionar

- Solo puede usarlo el compañero destinatario.
- Solo una vez por sugerencia.
- No ejecuta ningún movimiento.
- Se mantiene la sugerencia marcada como `questioned` hasta la resolución/movimiento correspondiente.

### Cambio

- Solo 2c2 y modo estratégico.
- Se conserva la regla anterior: el jugador cuyo turno está activo propone el cambio.
- Solo el compañero objetivo puede aceptarlo o rechazarlo.

### Rendirse

- Se conserva la regla de turno.
- En 2c2, el compañero debe confirmar la rendición si está activo.
- El resultado usa el equipo real del solicitante, no `current_team` por accidente.
- No se pueden apilar solicitudes de rendición.

### Tablas

- Se conserva el flujo de dos etapas en 2c2:
  1. acuerdo del compañero;
  2. acuerdo del equipo rival.
- Solo los jugadores habilitados para esa etapa pueden responder.
- No se pueden apilar ofertas de tablas.
- La oferta usa el equipo real del solicitante, no el turno leído de forma indirecta.

## 5. Coherencia de identidad

Las acciones sociales y de juego distinguen explícitamente:

- `local_player_slot`: quién es el usuario local;
- `current_slot`: quién tiene el turno.

No se usan como sinónimos.

Esto evita respuestas de Sugerir/Cambio/Rendición/Tablas atribuidas al slot incorrecto.

## 6. QA ejecutado

- V85 parse contracts: 10/10
- Club access/roles: 169/169
- Bot tests: 255/255
- Game social maintenance: 25/25
- Core run_tests: 39/39
- Competitive: 34/34
- NEXUS V2: 10/10
- NEXUS-TEAM: 27/27
- Competitive Match Context: 11/11
- Social V70: 36/36
- Online Setup: 37/37
- Profile UI: 9/9
- Account Hub: 149/149

Godot 4.7.2 real import: correcto.

Smoke real de la aplicación en 720x720: sin `SCRIPT ERROR` ni `Parse Error`.

El entorno Xvfb mostró la advertencia esperada de V-Sync/audio y un `ERR_CANT_OPEN` de recurso gráfico/audio del entorno aislado; no correspondió a errores de GDScript.

También se generaron clips reales de 20 s de las pantallas modificadas:

- `v85_bot_setup_20s.mp4`
- `v85_club_create_20s.mp4`

## 7. Reglas 2c2 preservadas

No se cambiaron turnos, equipos, movimientos legales, condiciones de victoria/derrota ni la idea base de Sugerir/Cambio. Los cambios se concentran en autoridad, estados, mantenimiento, coherencia de identidad y presentación.
