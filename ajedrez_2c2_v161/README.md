# Ajedrez 2c2 — manual de continuidad V146


## Estado actual rápido — V146 (2026-10-17)

**Esta sección es la fuente vigente para la próxima IA.** Leerla junto con `V146_SISTEMA_VISUAL_RESPONSIVE.md` y `TEST_REPORT_V146.md` antes de tocar la interfaz.

- Las capturas de referencia están en `qa_previews/v146/portrait/` y `qa_previews/v146/landscape/`: Inicio, Amigos, Clubes, detalle/creación de club, Miembros, Chat, Más, Perfil y partida.
- `core/layout/layout_metrics.gd` define el rectángulo del tablero y las métricas del HUD. En vertical el tablero conserva casillas cuadradas y usa el ancho disponible con márgenes laterales de 8 unidades lógicas. En horizontal se maximiza contra la altura y las zonas laterales se usan para relojes/jugadores y acciones.
- **Restricción geométrica intencional:** un tablero cuadrado no puede llenar a la vez el ancho de una pantalla 844×390, sin deformar casillas o dejar fuera filas/columnas. V146 conserva casillas cuadradas y prioriza un tablero jugable, con controles en raíles laterales. No cambiar a casillas rectangulares como un arreglo visual improvisado.
- Las pantallas sociales se ajustaron individualmente, no solo con escala global. `SocialUIFactory.is_landscape()` centraliza el criterio de orientación; `ResponsiveMarginController` sigue siendo dueño de los márgenes y de la conexión/desconexión de `Viewport.size_changed`.
- En Miembros, identidad (nombre y rol) son etiquetas separadas; en vertical las acciones van en la segunda fila; en horizontal comparten la fila cuando cabe. En Detalle de club se limitaron mínimos intrínsecos de ancho que antes ensanchaban el ScrollContainer más que la pantalla. Creación de club mantiene la galería visible junto a una tira de iconos desplazable.
- Perfil ya no reserva una banda lateral vacía en horizontal; la cabecera deja espacio al botón flotante de historial. Los mosaicos de estadísticas reservan altura suficiente para la etiqueta. En móviles estrechos, las filas de parejas envuelven detalles y apilan el ranking debajo para que los datos competitivos extensos no ensanchen el `ScrollContainer`.
- No se cambiaron reglas de movimiento, turnos 2c2, delegación, reconexión, rendimiento competitivo ni backend online.
- Validación técnica V146: `tests/run_tests.gd` 42/42; centrado 58/58; HUD profesional 10/10; layout horizontal 33/33; layout móvil 24/24; prueba nueva del tablero 44/44; ajuste por pantalla y capturas 77/77; Account Hub 149/149; agentes QA 12/12; auditoría 14/14; regresión V142 11/11; panel diagnóstico offline 6/6; y las pruebas previas de gesto/escala/fábrica/márgenes, según `TEST_REPORT_V146.md`. Los conteos pertenecen a suites diferentes y pueden solaparse.
- Se ejecutaron capturas reales del proyecto usando Godot 4.7.2, Xvfb, y OpenGL Compatibility. La importación del proyecto se ejecutó en modo headless. **No se probó un teléfono Android físico**, y las comprobaciones no certifican todos los flujos funcionales.


Proyecto Godot 4.7.2 con tablero, reglas de ajedrez, modos y HUD modular.

## Modos

- 2c2 cooperativo: A → B → C → D, perfiles por slot, sugerencias, cuestionar, cambios, chat, tablas, rendición y ausencia.
- 1c1 clásico: solo reglas normales de ajedrez.
- VS IA: solo reglas normales + IA local; no muestra herramientas de equipo.
- 1c1 local: clásico para dos personas en el mismo dispositivo, con rotación del tablero después de cada jugada.

## Interfaz

La UI se construye con escenas y controles de Godot, no como una sola imagen.

- `scenes/player_card.tscn`: tarjeta reutilizable de jugador.
- `profile_data.gd`: catálogo de perfiles de demostración.
- `assets/avatars/*.svg`: avatares intercambiables.
- `scenes/game_hud.tscn`: HUD del juego.
- `scenes/game_hud.gd`: distribuye la UI según el modo y el estado de la partida.

Los paneles de jugador cargan avatar, nombre, rol y estado desde datos; el reloj es único por equipo y vive en la cabecera del equipo. En una integración online, se puede reemplazar el perfil de cualquier slot con:

```gdscript
state.set_slot_profile(slot, profile_id, display_name)
```

Sin tocar la escena de la interfaz.

## Estilo visual

Paleta cálida de carbón, madera, crema y dorado. Los paneles secundarios (sugerencias, cambio, rendición, tablas, historial y chat) aparecen como mini-paneles contextuales para no cubrir el tablero entero.

## Cooldowns

- Sugerir: 2 s.
- Cuestionar: 2 s.

## Tablero

El tablero se calcula al tamaño del viewport y se centra en X. En vertical ocupa todo el ancho disponible de la pantalla, manteniendo la distribución del HUD.


## Actualización de piezas
Las piezas usan sprites PNG recortados, centrados y escalados al 90% de la casilla para conservar buena presencia visual sin desbordarse. El intercambio de posición 2c2 es gratuito.

## V53 — Responsive horizontal/vertical

- Layout horizontal con reserva inferior corregida para evitar desbordes en pantallas anchas y bajas.
- Layout vertical corto ajustado para que tablero, equipos, estado y controles quepan en 360×640.
- Títulos compactos y nombres de jugador protegidos contra desbordes.
- Auditoría responsive: 1464/1464 OK.
- Se mantienen intactas las reglas 2c2 y la mecánica de Sugerir.

## Última actualización
- El cambio de posición 2c2 es una mecánica básica y gratuita: no usa monedas.
- Las piezas usan los sprites PNG existentes, dibujados al 155% del tamaño de la celda para que el contenido visible aproveche aproximadamente 70–90% de la casilla sin perder centrado.
- Los perfiles siguen siendo recursos intercambiables por jugador.


## Emotes rápidos

Se añadió un sistema de 12 emotes para 2c2, 1c1 y 1c1 local. VS IA no muestra el botón porque no hay otro jugador humano que reciba la reacción. El selector es un panel compacto y responsive: en vertical ocupa solo una esquina del tablero y en horizontal se mantiene dentro del área visible. Al enviar un emote, una copia pequeña sobresale desde la tarjeta del jugador que lo envió, sin cubrir el tablero. Enfriamiento: 2 segundos.

Los avatares, nombres y estados siguen siendo elementos dinámicos de Godot; el reloj es un único elemento dinámico por equipo; los emotes son PNG individuales.

La orientación móvil quedó en modo sensor y el stretch usa `expand` para permitir que la composición responda a vertical y horizontal.


## 1c1 Online

La opción `1c1` del menú se trata como la variante online: muestra flujo de búsqueda de rival, estado EN LÍNEA, un reloj por jugador/lado, Historial, Emotes, Rendirse y Tablas. Durante una partida online no se muestran Menú ni Reiniciar y la navegación de cancelar/volver queda bloqueada mientras la partida está activa. Al terminar la partida aparece `Volver al menú`.

La capa de red real todavía no está conectada; el flujo actual es una carcasa visual/local para validar UX y distribución antes de integrar matchmaking, sincronización autoritativa y reconexión.

## Online setup actualizado

Al tocar `2c2` o `1c1 · ONLINE` se abre un modal por encima del menú con:
- Partida pública.
- Jugar con un amigo.
- Tiempo: 10', 15' o 20'.
- Nota visible indicando que el reloj corre únicamente durante el turno activo.

`Jugar con un amigo` abre una sala privada con código, enlace, QR, regeneración de código y selector de tiempo.

Después se muestra una pantalla de matchmaking/espera. La conexión real y la sincronización de red todavía no están implementadas. El matchmaking actual es solo una simulación local con rango de rating para validar la UX y las reglas de búsqueda antes de conectar el servidor.

## Reloj

En 2c2 hay un reloj por equipo. En 1c1 hay un reloj por jugador/lado. Solo el reloj del equipo/jugador cuyo turno está activo disminuye.

### Salas privadas
Desde `2c2` o `1c1 ONLINE -> Jugar con un amigo` ahora existe tanto `Crear sala` como `Unirse a una sala`. Para unirse se puede introducir el código de 6 caracteres o pegar el enlace. La configuración de tiempo/reglas la define el anfitrión.

## Base de cuenta, progreso y ajustes

Se añadió una capa local de progreso para preparar la experiencia antes del servidor real:
- Perfil local con nombre y avatar.
- Estadísticas individuales y de pareja.
- Historial local de resultados.
- Ranking individual y ranking de parejas como estructura de interfaz/local.
- Pantalla de Copas.
- Ajustes persistentes: vibración, coordenadas del tablero, confirmación de rendición y reducción de movimiento.
- El ajuste de coordenadas se aplica directamente al tablero.
- La rendición de 1c1 muestra confirmación cuando el ajuste está activo.

El ranking mostrado sin servidor es una representación local de prueba. No se presenta como ranking global real hasta conectar la persistencia online.

## Sistema competitivo local

La base competitiva quedó separada en sistemas para poder cambiar las reglas sin rehacer la interfaz ni la futura capa online:

- **Rating individual:** representa fuerza relativa y se actualiza según resultado y diferencia de rating.
- **Rating de pareja:** cada combinación de jugador + compañero tiene su propio rating, estadísticas y racha.
- **Copas de temporada:** representan progreso y están separadas del rating.
- **Copas históricas:** conservan la suma de copas positivas acumuladas a través del tiempo.
- **Ligas:** Bronce (0), Plata (200), Oro (500), Platino (900), Diamante (1400) y Leyenda (2000). Los umbrales están centralizados para poder ajustarlos posteriormente.
- **Temporadas:** el estado actual es la Temporada 1 y la infraestructura permite iniciar una nueva temporada sin alterar ratings históricos. El reinicio no está expuesto al jugador mientras no exista una autoridad de servidor.
- **Rankings locales de prueba:** se muestran ranking por rating individual, rating de parejas y tablas de copas de temporada. Se etiquetan como locales hasta que exista persistencia global real.

### Fórmula inicial de copas

La versión actual usa una regla deliberada y aislada en `competitive_system.gd`:

- Victoria: **+7 / +10 / +13** según el rival sea más débil, similar o más fuerte.
- Tablas: **+2 / +4 / +6** con la misma lógica.
- Derrota: **-6**, excepto derrota frente a un rival 150+ puntos superior, que es **-2**.
- Las copas no pueden bajar de cero.

El rating competitivo actual usa **NEXUS V2**: expectativa tipo Elo como base, `K` adaptativo según incertidumbre/volatilidad, forma reciente e incertidumbre que vuelve a crecer con la inactividad. El rating no baja solo por dejar de jugar.

1c1 y 2c2 mantienen estados NEXUS-SOLO independientes. En 2c2, además, cada pareja tiene un NEXUS-TEAM separado: el rating individual aprende de la fuerza individual de los rivales y el NEXUS-TEAM aprende de la fuerza de la pareja rival. La sinergia de pareja está acotada y se degrada gradualmente con la inactividad.

El contrato `competitive_match_context` conserva el snapshot competitivo de una partida y permite que la futura capa online entregue ratings de participantes, pareja e incertidumbre de forma autoritativa. Mientras no exista servidor real, el matchmaking público sigue siendo una simulación local y no representa un ranking global.

### Matchmaking local

El flujo público conserva la UX actual, pero ya tiene una lógica aislada de búsqueda por rating. Comienza con un rango de **±100**, aumenta **+50 cada 2 segundos** y llega como máximo a **±400**. Esto se puede sustituir posteriormente por la búsqueda real del servidor sin cambiar la interfaz.

## Copas

Las copas ya se aplican al terminar partidas clasificadas 1c1 y 2c2. El perfil muestra copas, rating, liga, temporada e historial de cambios. En 2c2, además, la pareja recibe sus propias copas y rating.


### Plantilla visual de clasificaciones

Las interfaces de Ranking, Liga y el diseño preparado para Temporadas comparten una fila visual de Godot con espacios definidos para:
- número de clasificación;
- avatar del jugador (o dos avatares para una pareja);
- nombre;
- copas o rating según la tabla.

La plantilla es reutilizable y responsive; no depende de una imagen estática.


## Identidad de jugador
Cada cuenta local tiene un `user_id` interno único con prefijo `USR_`, separado del nombre visible. El nombre visible se limita a 10 caracteres. El ID se conserva cuando el nombre cambia y está preparado para futuras cuentas/online.

## Bots / dificultad

La modalidad VS IA ahora tiene perfiles de bot y una fuerza objetivo basada en una escala Elo aproximada. La dificultad controla aleatoriedad, ruido de selección y profundidad de evaluación en el bot local. Este Elo es un objetivo de diseño, no un rating oficialmente calibrado; la calibración contra partidas de referencia queda para una etapa posterior.

## Tanda 9 — estabilidad y distribución móvil

- Entrada táctil y mouse emulado unificados para evitar doble procesamiento en Android.
- Espera de IA dependiente del Elo con variación natural por turno; los bots no mueven instantáneamente.
- Sugerencias de bot reutilizan la interfaz cooperativa sin autoaceptarse.
- HUD optimizado: paneles y tarjetas reaccionan a cambios de estado; el ciclo periódico queda para reloj, cooldowns y viewport.
- Reacciones temporales más grandes, sin forzar el layout.
- `.nomedia` en los datos locales y recursos preparados para evitar indexación accidental como medios.
- Auditoría de rutas: no se usan DCIM/Pictures/Movies/Download para guardar assets o partidas.

## V31 — Navegación principal

La pantalla principal ahora se concentra en **Jugar** y sus cuatro modos. La navegación general utiliza un componente reutilizable con cuatro destinos: **Jugar**, **Rankings**, **Historial** y **Más**. Perfil permanece fuera de esa barra y se abre desde el avatar/nombre.

### V34 — Historial, Replay y rendimiento
El Historial muestra una sola acción contextual por partida: **Analizar partida** antes del análisis y **Ver** después. La tarjeta no muestra la lista ni el contador de jugadas; esas jugadas pertenecen al Replay.

Desde Historial, **Analizar partida** abre primero el Replay. Allí aparece un botón compacto inferior **Analizar**. Al pulsarlo se registra `analysis_viewed` y se abre una pantalla de **Tu rendimiento final**, sin incrustar el Replay. Esa pantalla incluye un acceso rápido **Ver partida**.

En el Replay de una partida ya analizada, el acceso compacto pasa a **Ver análisis**. El botón **Ver** del Historial siempre abre el Replay completo.

En vertical la navegación se presenta como barra inferior; en horizontal se transforma en rail lateral. Rankings agrupa clasificaciones, parejas, copas y la interfaz preparada de temporadas. Más queda reservado para ayuda, funciones secundarias y futuras extensiones.

El antiguo `QuickMenu` y el botón central de Cuenta fueron retirados de la escena del menú principal.

---

# V35 — Análisis y Replay interactivos

Replay y Análisis dejaron de tratarse como vídeo. El Replay usa un tablero fijo con lista de jugadas y navegación manual. El Análisis añade resumen de rendimiento, revisión interactiva y detalle de la jugada seleccionada. La clasificación/evaluación de motor queda preparada pero no se inventa hasta integrar un evaluador real.

# V36 — Estudio profesional de partida

La interfaz de Replay/Análisis fue refinada para sentirse como una herramienta de estudio de ajedrez y no como un reproductor de vídeo.

- Se eliminaron slider y controles multimedia de primera/última posición.
- La planilla de jugadas es la navegación principal: número, Blancas y Negras.
- El tablero permanece fijo mientras el jugador selecciona posiciones desde la planilla.
- Replay y Análisis comparten el mismo visor interactivo.
- Análisis presenta cabecera de resultado, rendimiento final, datos de partida, jugada seleccionada y estudio interactivo.
- `Ver partida completa` queda como acceso rápido después del rendimiento.
- En portrait se prioriza un tablero grande y usable.
- No se inventan accuracy, blunders ni evaluaciones de motor sin un evaluador real.

### V37 — Análisis como estudio de partida
- La pantalla **Análisis** deja de ser un informe largo antes del tablero.
- Se eliminan de la parte superior `Rendimiento final`, `Datos de la partida`, `Jugada seleccionada` y el botón `Ver partida completa`.
- El análisis abre directamente el estudio interactivo con tablero + lista de movimientos.
- La futura revisión automática se integrará sobre cada movimiento para clasificar/resaltar jugadas únicamente cuando exista evaluación real; no se inventan métricas.

## V38 — Revisión movimiento por movimiento

La pantalla de Análisis funciona como estudio de la partida. Las jugadas se muestran en una sola tira horizontal compacta y el tablero mantiene el foco. Se retiró la revisión heurística provisional y su `analysis_service.gd`: las clasificaciones de mejor jugada, error, precisión, etc. quedarán a cargo de un motor de ajedrez real mediante UCI, sin duplicar lógica de evaluación dentro del proyecto.

## V39 — Tira compacta y motor real

La revisión ya no usa clasificaciones heurísticas propias. Las jugadas se muestran en una sola línea horizontal desplazable y el análisis queda preparado para delegarse a un motor UCI real.

## V40 — Motor real y estudio compacto

El estudio conserva el tablero en tamaño normal y la tira de movimientos en una sola línea. Se retiró definitivamente la heurística provisional y se añadió una integración UCI con Stockfish 19 mediante `stockfish_engine.gd` + `game_review_service.gd`. El historial guarda el reporte como `engine_analysis`. La carpeta `engine/stockfish/` documenta el binario ARM64 requerido; el proyecto no finge tener un motor funcional si ese binario no está presente.

## V54 — Bucle competitivo y postpartida

- Resultado competitivo inmediato: rating/coplas ganadas o perdidas.
- Acceso directo a Analizar desde el resultado.
- El estudio abre automáticamente la última partida cuando corresponde.
- El menú principal muestra rating, liga y copas actuales bajo 2c2.
- Se mantienen intactas las reglas 2c2 y Sugerir.

## V86 — autoridad, bots y calibración NEXUS
- Rey/Dama gestionan roles respetando jerarquía; asignar su propio rango a un inferior intercambia cargos.
- Expulsión jerárquica y aprobación privada restringida a Rey/Dama.
- 20 bots con NEXUS mejor separado desde Difícil.
- Telemetría NEXUS anonimizada y laboratorio offline preparados para el servidor real.

---

# Manual de continuidad para futuras IAs y desarrolladores

> **Lee esta sección y los documentos de versión antes de modificar código.** Este README es el punto de entrada del proyecto y resume las decisiones que no se deben perder. Los informes históricos aportan contexto, pero no sustituyen la comprobación del código actual.

## 1. Estado de la entrega documentada

- **Proyecto de esta entrega:** `ajedrez_2c2_v146_interfaz_pro.zip`.
- **Base de código:** copia de trabajo derivada del paquete V145; los paquetes V144/V145 originales se mantienen como referencias de continuidad y no se sobrescriben.
- **Versión actual de este README:** V146, con los cambios de disposición por pantalla descritos en `V146_SISTEMA_VISUAL_RESPONSIVE.md`.
- **Documento de dirección visual original:** `V145_SISTEMA_VISUAL_MOVIL.md`; sus objetivos ya se contrastaron con capturas V146. No significa que toda la UI o el backend online estén terminados.
- **Motor usado en esta comprobación:** Godot `4.7.2.stable.official.ed1daf0bf`.
- **Escena inicial configurada:** `res://scenes/loading.tscn`.
- **Servidor gráfico virtual:** Xvfb y `xvfb-run` están disponibles en el entorno Linux de esta sesión.
- **Servidor de juego real:** todavía no conectado. Matchmaking, salas, perfiles competitivos y algunos flujos online son una carcasa/local UX, no un servicio multijugador autoritativo.

### Validación efectuada al preparar esta documentación

Se ejecutó una importación limpia del proyecto con Godot 4.7.2 (`--headless --editor --path ... --quit`): **código de salida 0**. También se lanzó la escena inicial bajo Xvfb durante 300 frames: **código de salida 0**. En ese arranque aparecieron avisos de VSync no soportado y un error de inicialización de audio seguido de fallback al driver dummy; son limitaciones del entorno virtual, no prueba de un fallo de reglas.

Suites ejecutadas sobre esta copia V144:

| Suite | Resultado observado |
|---|---:|
| `tests/run_tests.gd` | 42 OK / 0 fallidas |
| `tests/v141_mobile_layout_tests.gd` | 24 OK / 0 fallidas |
| `tests/mobile_scroll_gesture_v141_tests.gd` | 6 OK / 0 fallidas |
| `tests/v134_agent_modularity_tests.gd` | 12 OK / 0 fallidas |
| `tests/v135_system_audit_tests.gd` | 14 OK / 0 fallidas |
| `tests/v142_mobile_ui_regression_tests.gd` | 11 OK / 0 fallidas |

Son resultados de las suites indicadas, no una certificación completa de la app ni de Android físico. Los conteos no deben sumarse como casos únicos porque las suites pueden solaparse.

## 2. Principios de colaboración y cambios

1. **No borrar ni reescribir módulos grandes sin necesidad.** Inspeccionar primero, identificar el dueño de la responsabilidad y aplicar cambios pequeños, modulares y verificables.
2. **Preservar las reglas de ajedrez y 2c2.** Un problema visual no justifica cambiar movimientos, turnos, delegación, sugerencias, cambios de posición, tablas o rendición.
3. **No afirmar que algo funciona solo porque compila.** Ejecutar pruebas de contrato, regresión, arranque y revisión visual cuando corresponda.
4. **No declarar resuelta una incidencia histórica sin reproducirla o verificar el código afectado.** Documentar claramente qué se probó, con qué comando, en qué versión y qué limitaciones quedan.
5. **Interfaz primero desde el editor de Godot.** Preferir escenas, contenedores, anclajes, temas y componentes reutilizables. El código puede ajustar layout responsive cuando sea necesario, pero evitar coordenadas manuales dispersas.
6. **Mobile-first.** Diseñar para toque, texto legible, áreas táctiles amplias y scroll fiable. El soporte de mouse sirve para pruebas de escritorio, no es el objetivo de interacción principal.
7. **No gastar pruebas innecesarias en el dispositivo.** Las pruebas automatizadas deben ejecutarse primero en PC/Xvfb; validar después los recorridos críticos en Android real.
8. **Documentar cada tanda.** Actualizar este README cuando cambien la arquitectura, el estado real online, las reglas, los comandos o las incidencias. Crear un informe `V###_...md` para una tanda importante y mantener el historial anterior.
9. **No preguntar de nuevo decisiones ya documentadas.** Si falta una decisión verdaderamente bloqueante, explicar la incertidumbre; en lo demás, avanzar con las reglas existentes.
10. **No tocar repositorios/proyectos ajenos.** Limitar cambios al proyecto entregado y a los archivos explícitamente solicitados.

## 3. Modos de juego

- **2c2 cooperativo:** orden de turnos A → B → C → D; perfiles por slot; sugerencias, cuestionar, cambio/intercambio, chat, reacciones, tablas, rendición y tratamiento de ausencia/regreso.
- **1c1 clásico:** reglas normales de ajedrez sin herramientas exclusivas de equipo.
- **VS IA:** reglas normales más IA local; no debe mostrar herramientas sociales que solo tengan sentido entre humanos/equipos.
- **1c1 local:** dos personas en el mismo dispositivo; el tablero rota después de cada jugada.
- **1c1 online / 2c2 online:** los flujos de configuración, salas y matchmaking actuales preparan UX; la conexión, autoridad de partida y sincronización de red real todavía requieren backend.

### Reglas 2c2 que no se deben romper

- Las acciones sociales/de coordinación (chat, sugerencias, reacciones y cambio según su contrato) no se deben bloquear solo porque el usuario no tenga el turno. Esto **no** permite mover una pieza fuera del turno legal.
- La selección de pieza debe funcionar con **un toque**; no introducir doble toque obligatorio que rompa Sugerir.
- El cambio de posición del compañero es gratuito y no consume monedas.
- El reloj es uno por equipo en 2c2 y uno por lado/jugador en 1c1; solo corre el reloj del lado cuyo turno está activo.
- Sugerencias son indicaciones/ghosts y no deben autoaceptarse ni ejecutar un movimiento real sin la acción correspondiente.
- La lógica de ajedrez debe conservar jaque, mate, ahogado, enroque legal, en passant, promoción, capturas y validación de movimientos.
- La evaluación debe distinguir mates por distancia: en igualdad de condiciones, preferir mate más rápido y, al defenderse, prolongar correctamente la resistencia si el mate es inevitable.

### Ausencia y reconexión de compañero

La conexión y el estado de partida deben ser capas separadas. Perder conexión no debe borrar ni reiniciar la partida.

- Durante la desconexión, el compañero activo puede asumir temporalmente las facultades del ausente: ejecutar su turno, pedir tablas sin aprobación del ausente y rendirse por el equipo.
- Al volver, el jugador recupera sus funciones.
- Si el jugador regresa cuando su turno ya fue ejecutado por su compañero mediante delegación, no se repite ese turno; se reincorpora desde el siguiente que le corresponda.
- Si la partida terminó mientras estaba desconectado, la reconexión lo lleva directamente al resultado final, no a una partida activa.
- Se ha discutido una gracia de un minuto para una desconexión/ausencia real antes de declarar derrota. No mostrar ese contador por la mera espera normal después de que un jugador haya realizado su movimiento. Antes de implementar o cambiar esta regla, comprobar `V122_REGLA_MINUTO_GRACIA.md` y las pruebas de carreras/transiciones.
- El sistema de red real debe hacer autoritativos los turnos, el estado y la reconexión en servidor; el estado de escena local no es una frontera de seguridad.

## 4. Arquitectura: dónde debe vivir cada responsabilidad

La regla general es **UI → servicios/dominio → datos**, con dependencias preferentemente unidireccionales. Las pantallas coordinan, no deben absorber toda la lógica.

| Área | Ubicación/entrada principal | Responsabilidad |
|---|---|---|
| Infraestructura compartida | `core/` | Navegación, tema, layout, almacenamiento, servicios transversales |
| Reglas/estado ajedrez | `domain/chess/` | Reglas, movimientos, estado de partida y validación |
| Competitivo | `domain/competitive/` | NEXUS individual, NEXUS-TEAM y contexto competitivo |
| Jugador | `domain/player/` | Identidad, persistencia, historial, ranking, copas y personalización |
| Bots | `domain/bots/` | Decisiones, dificultad, evaluación e integración de Stockfish |
| Replay/análisis | `domain/replay/` | Captura/serialización, navegación del replay y análisis |
| Social | `domain/social/` | Amigos, clubes, chat y revancha |
| Pantallas | `ui/screens/` | Coordinación de una pantalla por archivo/clase principal |
| Componentes visuales | `ui/components/` | Componentes reutilizables; incluye fábrica de UI social |
| Escenas | `scenes/` | Composición visual editable en Godot |
| Pruebas | `tests/` | Contratos, regresiones, capturas y herramientas de QA |
| Herramientas | `tools/` | Auditoría de paquete, calibración y utilidades auxiliares |

### Fachadas y módulos ya definidos

- `PlayerData` coordina servicios de persistencia, competitivo, historial, ranking y personalización.
- `Game` coordina `game_input_controller.gd`, `game_bot_coordinator.gd`, `game_match_result_service.gd` y `game_flow_controller.gd`.
- `game_state.gd` conserva la fachada pública del dominio; el ciclo de vida, movimiento, bot y funciones sociales tienen servicios separados.
- `MatchReplayView` coordina tablero, controlador de vista, layout y estado serializado de replay.
- `StorageManager` coordina servicios de archivos, perfiles, caché y sincronización futura.
- `ui/components/social/social_ui_factory.gd` comparte estilos y componentes de pantallas sociales.
- `core/layout/layout_metrics.gd` centraliza tokens/métricas de la composición visual; no crear otro sistema paralelo de medidas sin justificarlo.

Consultar `MODULE_ARCHITECTURE.md`, `UI_VISUAL_SYSTEM.md` y `UI_SCOPE.md` antes de añadir responsabilidades.

## 5. Sistema de agentes QA y diagnósticos

`SupervisorHub` es la raíz de composición y fachada estable. El registro de agentes está centralizado en `core/services/qa_agent_registry.gd`. Los agentes son observadores: no deben consumir la entrada normal ni alterar reglas, turnos o resultados.

Módulos documentados en `AGENTS_ARCHITECTURE.md`:

- `domain/supervision/touch_observer_agent.gd`: observación pasiva de entrada táctil y correlación toque/acción.
- `domain/supervision/interface_supervisor_agent.gd`: observaciones de pantalla/interfaz.
- `domain/supervision/board_piece_supervisor_agent.gd`: consistencia de tablero/piezas.
- `domain/supervision/replay_supervisor_agent.gd`: consistencia de replay.
- `domain/supervision/screenshot_supervisor_agent.gd`: capturas explícitas/a demanda.
- `domain/supervision/supervisor_journal.gd`: diario persistente y saneado.
- `domain/supervision/qa_bundle_exporter.gd`: selección acotada de evidencia y empaquetado ZIP.
- `domain/online/match_supervisor.gd`: observaciones de política de partida, sin sustituir la lógica autoritativa.

Reglas para mover un agente:
1. Mover el script y recursos asociados juntos.
2. Actualizar su ruta solo en `AGENT_PATHS` de `core/services/qa_agent_registry.gd`.
3. Mantener API pública y contrato del diario; si cambian, actualizar adaptador y pruebas.
4. Ejecutar `tests/v134_agent_modularity_tests.gd` y las pruebas del módulo.
5. No fijar rutas de agentes en pantallas; usar la fachada `SupervisorHub`.

Los diagnósticos se guardan en `user://`; se documentaron `user://supervisor_diagnostics.jsonl` y `user://qa_captures/manifest.jsonl`. El paquete QA limita las capturas (máximo documentado: 40; valor predeterminado 12). Antes de compartirlo, revisar si contiene rutas locales o metadatos de interacción. La exportación manual debe permanecer deshabilitada durante partidas/matchmaking online.

Limitaciones: el observador de toque registra coordenadas y casillas lógicas, no vídeo continuo ni captura automática de cada toque. Una entrada consumida enteramente por un control UI puede no llegar al controlador del tablero. Capturas de renderer pueden no estar disponibles en headless; en ese caso el agente debe informar que no puede capturar, no fallar con una textura nula.

## 6. Sistema visual móvil — especificación V145

La interfaz de referencia es **390 × 844** en vertical, pero debe responder a pantallas estrechas y a horizontal mediante viewport, contenedores y medidas responsivas.

- El tablero conserva prioridad visual durante la partida; jugadores, relojes y acciones son grupos secundarios con separación coherente.
- Las pantallas sociales comparten colores, paneles, botones, títulos y márgenes mediante una fábrica visual.
- Los títulos largos reducen tamaño de fuente de forma controlada y tienen truncado de respaldo.
- Las zonas táctiles deben seguir siendo grandes; el selector de icono de club usa un botón compacto no textual para no forzar saltos de línea.
- Si el dedo supera el umbral de arrastre, el scroll gana el gesto y soltar no debe activar el botón. Los toques breves siguen activando normalmente.
- `ResponsiveMarginController` debe poseer la suscripción a `Viewport.size_changed`, usar referencias débiles y desconectar la señal en `_exit_tree()` para evitar callbacks a pantallas destruidas.
- En vertical, evitar tablero demasiado alto y grandes espacios vacíos inferiores; centrarlo y distribuir el HUD según el viewport.
- En horizontal, mantener tablero centrado y reservar espacio real para navegación lateral, jugadores, relojes y acciones.
- Mantener nítidos los textos y las piezas; no reducir toda la UI a causa de una sola pantalla problemática.
- Mantener tema actual, pero diseñar colores, piezas y tablero para que puedan cambiarse por configuración en el futuro.
- Para nuevas vistas, preferir escenas, contenedores, anclajes y componentes reutilizables desde el editor de Godot cuando resulte práctico. Hay flujos existentes que todavía construyen controles dinámicamente.

### Ciclo visual de regresión requerido

1. Inicio arriba y tras varios desplazamientos.
2. Clubes → detalle → chat → miembros.
3. Más → Cuenta y cada subpágina de configuración.
4. Arrastrar empezando encima de tarjetas y botones; confirmar que el scroll no dispara el botón al soltar.
5. Girar vertical → horizontal → vertical.
6. Partida 1c1 y 2c2, resultado y volver al inicio.
7. Revisar texto, botones, márgenes, barra de navegación, perfil, amigos, miembros, club y entrada de chat.

Ver `V145_SISTEMA_VISUAL_MOVIL.md` y `V141_MOBILE_QA.md`. Las reglas de movimiento y turno nunca se deben modificar como arreglo de layout.

## 7. Competitivo, perfiles y progreso

- `USR_...` es la identidad interna estable; el nombre visible puede cambiar y está limitado a 10 caracteres según el contrato actual.
- NEXUS-SOLO mantiene estados separados para 1c1 y 2c2. NEXUS-TEAM mantiene rating/estado de cada combinación de jugador y pareja.
- La sinergia de pareja está acotada y se degrada gradualmente con inactividad; el rating no debe bajar solo por dejar de jugar.
- Las copas, la liga, la temporada y el rating son sistemas separados. Los umbrales de liga documentados: Bronce 0, Plata 200, Oro 500, Platino 900, Diamante 1400 y Leyenda 2000.
- Fórmula inicial de copas documentada en `competitive_system.gd`: victoria +7/+10/+13 según fuerza relativa; tablas +2/+4/+6; derrota −6 salvo rival 150+ puntos superior, donde es −2; nunca bajar de cero. Verificar el código antes de cambiar la fórmula.
- El contexto `competitive_match_context` permite preparar snapshots para autoridad online futura.
- Rankings, salas, matchmaking y datos competitivos locales no deben etiquetarse como globales/reales hasta tener backend y persistencia autoritativa.
- VS IA usa perfiles de dificultad basados en una escala Elo aproximada. Esa escala es objetivo de diseño, no una calibración competitiva certificada.

## 8. Comandos de desarrollo y validación

Ejecutar desde la raíz del proyecto (la carpeta que contiene `project.godot`):

```bash
# Versión del motor
/path/to/Godot_v4.7.2-stable_linux.x86_64 --version

# Importar recursos y validar carga del editor sin abrir interfaz
/path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --editor --path . --quit

# Suite base de reglas e integración
/path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/run_tests.gd

# Suites relevantes de móvil y agentes
/path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/v141_mobile_layout_tests.gd
/path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/mobile_scroll_gesture_v141_tests.gd
/path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/v134_agent_modularity_tests.gd
/path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/v135_system_audit_tests.gd
/path/to/Godot_v4.7.2-stable_linux.x86_64 --headless --path . --script res://tests/v142_mobile_ui_regression_tests.gd

# Arranque gráfico virtual (requiere Xvfb)
xvfb-run -a /path/to/Godot_v4.7.2-stable_linux.x86_64 --path . --quit-after 300
```

Para una pasada completa, inventariar las suites de `tests/` y ejecutar también las de lógica, competitivo, online setup, replay, orientación horizontal, perfil, clubes, navegación y seguridad de servicios. Guardar salida de cada comando y diferenciar errores de proyecto de advertencias del host (audio dummy/VSync en Xvfb).

No usar `--script` con una suite que no exista en esta versión. Comprobar primero la ruta real. Los scripts `capture_*.gd` suelen ser herramientas de captura, no necesariamente suites de regresión.

## 9. Estado online y límites de seguridad

La UX local ya contiene configuraciones públicas/privadas, código de sala, enlace/QR, selección de reloj, búsqueda simulada y estructuras de ranking. Eso no significa que existan aún:

- matchmaking autoritativo de servidor;
- sincronización de movimientos y estado de partida en red;
- autoridad para aceptar/rechazar movimientos y resolver turnos;
- persistencia global de rating/copas/historial;
- reconexión y delegación coordinadas por servidor;
- protección real frente a clientes manipulados.

No diseñar seguridad de producción basada solo en estado de escena o controles locales. Al implementar backend, el servidor debe validar estado, turno, movimientos, reloj, resultado y cambios de conexión.

## 10. Incidencias históricas y cómo reportarlas

Algunas conversaciones anteriores mencionaron un error de `AcceptDialog` relacionado con `custom_minimum_size` y un acceso al árbol de nodos desde el hilo de `game_review_service.gd`. En el ZIP V144 inspeccionado, el panel de diagnóstico asigna tamaño mínimo a sus contenedores internos, no al `AcceptDialog`, y `GameReviewService` no contiene llamadas `get_node_or_null()`. La importación y las suites ejecutadas no reprodujeron esos mensajes. **No marcar las incidencias como definitivamente resueltas sin probar la acción interactiva que las originaba y revisar el registro completo.**

También hay un error histórico del editor referido como `text_edit.cpp:6981` / `p_gutter = -1`, que no se considera resuelto solo porque no aparezca en una ejecución. Si reaparece, registrar versión de Godot, pasos, log completo y si ocurre en editor, juego o solo Xvfb.

Cuando una prueba falla, documentar:
- versión/commit o ZIP probado;
- comando exacto y código de salida;
- mensaje de error completo y primer frame propio del proyecto;
- pasos para reproducir;
- cambio mínimo realizado;
- suites antes/después y evidencia visual si afecta UI.

## 11. Índice de documentos de referencia

- `README.md`: manual principal y traspaso a futuras IAs.
- `V145_SISTEMA_VISUAL_MOVIL.md`: objetivos de la siguiente tanda visual.
- `MODULE_ARCHITECTURE.md`: límites y responsabilidades de módulos.
- `AGENTS_ARCHITECTURE.md`: contratos y reglas para agentes QA.
- `UI_VISUAL_SYSTEM.md`: jerarquía visual y tokens de diseño.
- `UI_SCOPE.md`: alcance de interfaz.
- `V141_MOBILE_QA.md`: scroll, orientación y capturas probadas bajo Xvfb.
- `QA_V142_NOTAS.md`: regresiones móviles y estabilidad V142.
- `V135_AUDITORIA_SISTEMA_Y_UI.md`: auditoría de sistema/UI y limitaciones de aquella tanda.
- `V121_SEPARACION_CONEXION_PARTIDA.md`: separación conexión/estado de partida.
- `V120_RECONNECT_TURN_RESULT.md`: reconexión y redirección al resultado.
- `V117_DELEGACION_2C2.md`, `V118_INTEGRACION_DELEGACION.md`, `V119_TRANSITION_RACE_AUDIT.md`: delegación y carreras de transición.
- `V122_REGLA_MINUTO_GRACIA.md`: propuesta/contrato de gracia por ausencia.
- `V123_SUPERVISOR_BASE.md` hasta `V135_...`: evolución de agentes, diagnóstico y auditorías.
- `V110_AUDITORIA_LOGICA.md`, `V112_REGLAS_MOTOR_INPUT.md`: reglas y entrada.
- `NEXUS_TEAM_INTEGRADO_V1.md`, `V81_NEXUS_V2.md`, `V82_NEXUS_TEAM_INACTIVITY.md`, `V83_COMPETITIVE_RATING_CONTEXT.md`: sistema competitivo.
- `STORAGE_ARCHITECTURE.md`, `STORAGE_TEST_REPORT.md`: persistencia y sus límites.
- `ONLINE_FLOW.md`, `ONLINE_1C1.md`: flujo online local actual y trabajo pendiente de backend.
- `TEST_REPORT.md`: historial de pruebas previas; no reemplaza la última ejecución realizada.

## 12. Próxima tanda recomendada

1. Usar **V146** como base de trabajo actual y mantener los ZIP V144/V145 originales intactos.
2. Volver a capturar con Xvfb las pantallas vertical/horizontal después de cualquier ajuste de escala, margen, texto o zonas táctiles; comparar con `qa_previews/v146/`.
3. Validar el tablero en 1c1, 2c2, VS IA, local y pantalla de resultado en ambas orientaciones. El diseño V146 preserva casillas cuadradas: horizontal maximiza el tablero contra la altura, no lo deforma para llenar una pantalla panorámica completa.
4. Probar a mano los gestos de scroll que comienzan encima de tarjetas/botones; arrastre supera el umbral = desplaza, soltar no activa, toque corto sí activa.
5. Validar el teclado virtual, rotación real del teléfono, densidades y zonas táctiles en Android físico; Xvfb no sustituye esas pruebas.
6. Retomar los defectos funcionales anotados en la sección V146 y no mezclar arreglos visuales con reglas de ajedrez/2c2 ni con la futura autoridad del servidor.

**Regla de oro:** conserva lo que funciona, no inventes estado de implementación, prueba antes de declarar éxito y deja la siguiente IA con un README y un informe que expliquen exactamente qué cambió.


## 13. Progreso verificado — V145 (2026-10-17)

Esta sección describe cambios realizados sobre la copia V144 en el entorno de trabajo. El ZIP original del usuario se conserva fuera de esta carpeta; el paquete de entrega V145 se generará como una nueva copia.

### Implementado en esta tanda

- `project.godot`: la referencia de diseño móvil cambió de viewport cuadrado `720 × 720` a `390 × 844`, alineada con `V145_SISTEMA_VISUAL_MOVIL.md`. El stretch continúa en `canvas_items` con aspecto `expand`.
- Nuevo `core/layout/responsive_margin_controller.gd` (`ResponsiveMarginController`): administra los márgenes de una pantalla mediante referencias débiles; conecta `Viewport.size_changed`, recalcula orientación vertical/horizontal y desconecta explícitamente en `_exit_tree()`.
- Nuevo autoload `ResponsiveContentScale` en `core/layout/responsive_content_scale.gd`: conserva escala 1.0 en vertical y compensa el encogimiento del canvas de referencia en horizontal mediante `Window.content_scale_factor`, proporcional a la altura real y limitado a 2.5. Se probó a 844 × 390 y 1280 × 720; validar Android físico y HUD horizontal antes de extender el límite.
- `ui/components/social/social_ui_factory.gd`: `configure_main_content_margin()` crea el controlador como hijo de la pantalla. Los títulos largos reducen su tamaño por longitud y tienen truncado con puntos suspensivos como respaldo. Las acciones primarias respetan mínimo de 52 px lógicos y las secundarias mínimo de 48 px.
- Se eliminaron las lambdas locales capturadas por `Viewport.size_changed` en `auth_screen.gd`, `club_detail_screen.gd` y `club_create_screen.gd`; esas pantallas usan ahora el controlador compartido.
- La navegación inferior reduce su tipografía en teléfonos estrechos para que «Amigos» y «Más» no se corten dentro de sus cuatro zonas táctiles.
- La navegación horizontal reserva al menos 174 px a la izquierda en Más y Miembros, evitando que su contenido quede debajo de la barra lateral. Inicio reserva 180 px.
- `mode_menu.gd` desconecta explícitamente las señales de cambio de tamaño de viewport en `_exit_tree()`.
- Las pantallas con navegación inferior reservan 120 px en vertical para que el scroll no pase por detrás de la barra. Se actualizaron Inicio, Amigos, Perfil, Clubes, Chat, Miembros, Más y el visor de partidas de club.
- `club_chat_screen.gd`: el selector de reacciones ajusta ancho, número de columnas y tamaño de botones en pantallas estrechas; el nombre largo del club usa truncado seguro. Se corrigió una doble llamada a `add_child(texture)` en la representación de una reacción de imagen.
- `club_create_screen.gd`: los botones de selección de icono ahora tienen al menos 48 × 48 px lógicos.
- Se añadió `tests/v145_responsive_margin_lifecycle_tests.gd` para probar márgenes verticales/horizontales, propiedad de la conexión de redimensionado y destrucción del controlador con la pantalla.
- `tests/capture_v145_social.gd` permite capturar Inicio, Amigos, Clubes, Más, Miembros y Chat en un viewport de 390 × 844. `tests/capture_v145_landscape.gd` captura las pantallas sociales en 844 × 390 y `tests/capture_v145_game_landscape.gd` el HUD 2c2 horizontal. Las capturas de Chat/Miembros necesitan un club activo; el script de captura prepara el club de demostración.
- Capturas revisadas de V145 guardadas en `qa_previews/v145/portrait/` y `qa_previews/v145/landscape/` para que la siguiente IA compare el aspecto visual sin tener que regenerarlas.

### Validación ejecutada

Con Godot `4.7.2.stable.official` y Xvfb disponible:

| Suite | Resultado |
|---|---:|
| `tests/run_tests.gd` | 42 OK / 0 fallos |
| `tests/v141_mobile_layout_tests.gd` | 24 OK / 0 fallos |
| `tests/v142_mobile_ui_regression_tests.gd` | 11 OK / 0 fallos |
| `tests/v144_professional_hud_tests.gd` | 10 OK / 0 fallos |
| `tests/mobile_scroll_gesture_v141_tests.gd` | 6 OK / 0 fallos |
| `tests/v134_agent_modularity_tests.gd` | 12 OK / 0 fallos |
| `tests/v135_system_audit_tests.gd` | 14 OK / 0 fallos |
| `tests/v131_offline_diagnostics_panel_tests.gd` | 6 OK / 0 fallos |
| `tests/v141_landscape_layout_tests.gd` | 33 OK / 0 fallos |
| `tests/account_hub_tests.gd` | 149 OK / 0 fallos (revalidada V146) |
| `tests/v145_responsive_margin_lifecycle_tests.gd` | 8 OK / 0 fallos |
| `tests/v145_social_ui_factory_tests.gd` | 7 OK / 0 fallos |
| `tests/v145_responsive_content_scale_tests.gd` | 4 OK / 0 fallos |

Total aritmético de estas ejecuciones: **177 comprobaciones aprobadas**, con posible solapamiento entre suites; no representa 101 casos únicos. La importación de proyecto en modo editor terminó con código 0 y sin errores de análisis en el log. Xvfb muestra advertencias de VSync/audio del host que provocan fallback al driver de audio dummy; no confundirlas con errores GDScript.

### Pendiente de verificar

1. Validar el nuevo viewport de referencia en un Android físico y en orientación horizontal, especialmente el HUD de partida y el teclado virtual del chat.
2. Capturar y revisar Chat/Miembros con un club activo y comprobar que el selector de reacciones no sale del viewport.
3. Revisar todas las subpáginas de Más/Cuenta a 360 × 640, 390 × 844, 480 × 960 y horizontal; revisar scroll iniciado encima de tarjetas y botones.
4. `tests/account_hub_tests.gd` se reejecutó en V146 y aprobó 149/149. La excepción que figuraba en el historial de V145 no se reprodujo en esta ejecución; si vuelve a aparecer en otra máquina o cambio futuro, capturar el log completo y volver a investigarla.
5. Repetir pruebas de partida 1c1/2c2 y reconexión; esta tanda no cambia las reglas de ajedrez ni implementa un servidor online.
6. No declarar el cambio de viewport como final para todas las densidades hasta validar dispositivos reales. La referencia solicitada es 390 × 844; las pruebas de Xvfb no sustituyen el tacto en Android.

### Regla para la siguiente IA

Leer primero este `README.md`, luego `V145_SISTEMA_VISUAL_MOVIL.md` y `README_FUNCIONALIDADES_HISTORICAS.md`. Inspeccionar el diff de V145 y ejecutar las suites antes de modificar reglas o módulos ajenos a la interfaz. Continuar desde esta copia de trabajo y no sobrescribir la base V144 original.


## 14. Progreso verificado — V146: organización visual pantalla por pantalla

### Cambios de código

- `core/layout/layout_metrics.gd`: tablero vertical maximiza el ancho disponible (margen de seguridad de 8 unidades lógicas), mantiene geometría cuadrada y calcula la pila de cabeceras/estado/jugadores/acciones con métricas compartidas. En horizontal, tablero cuadrado máximo contra la altura útil y raíles laterales calculados a partir de sus bordes.
- `ui/components/game/game_hud_layout.gd`: controles cooperativos en la columna izquierda en horizontal, emojis/chat/menú debajo; jugadores y relojes se distribuyen en laterales; el historial de movimientos queda en la columna derecha. En vertical, se recortó espaciado estructural sin reducir la zona táctil de acciones.
- `ui/components/player_card.gd`: avatar vertical mínimo de 48 unidades en la tarjeta compacta; los nombres mantienen truncado seguro y la tarjeta horizontal presenta avatar a la izquierda con texto a su lado.
- `ui/components/social/social_ui_factory.gd`: método `is_landscape(host)` compartido para que todas las pantallas tomen la misma decisión de orientación.
- `ui/screens/friends_screen.gd`, `more_screen.gd`, `club_browser_screen.gd`: tarjetas, separaciones, tipografías y alturas elegidas por orientación; los controles siguen teniendo al menos 48 unidades lógicas.
- `ui/screens/club_members_screen.gd`: fila horizontal ocupa el ancho disponible, identidad se presenta con nombre/rol separados, nombre visible en vertical y botones de acción distribuidos según orientación.
- `ui/screens/club_detail_screen.gd`: se elimina la doble autoridad de márgenes, se impide que etiquetas/acciones obliguen al contenido a exceder el ancho disponible, y se adapta jerarquía/miembros destacados a móvil.
- `ui/screens/club_create_screen.gd`: el controlador responsivo controla los márgenes; iconos en una franja horizontal desplazable y botón de galería fijo y legible.
- `ui/screens/club_chat_screen.gd`: cabecera, botón de desafío, estado vacío y compositor adaptados a horizontal/vertical.
- `ui/screens/account_hub.gd` y `ui/components/account_page_renderer.gd`: estadísticas con espacio para título, cuadrícula de personalización a una columna en móvil estrecho, filas de parejas con detalles adaptables y ranking apilado en teléfonos estrechos, y cabecera horizontal sin superponer el acceso a historial ni dejar 160px de espacio vacío.
- `tests/v146_board_layout_tests.gd` valida distintas dimensiones y el máximo razonable del tablero; `tests/v146_social_screen_fit_tests.gd` valida anchura de los ScrollContainers, botones de perfil e iconos/galería. `tests/account_hub_tests.gd` espera ahora a que termine la carga del Autoload PlayerData antes de preparar datos, lo que elimina fallos no deterministas por historial persistido; pasó 149/149 dos ejecuciones consecutivas bajo Xvfb.
- `tests/capture_v146_social.gd`, `tests/capture_v146_social_landscape.gd`, `tests/capture_v146_game_portrait.gd`, `tests/capture_v146_game_landscape.gd` producen capturas repetibles en `qa_previews/v146/`.

### Forma de validación

La prueba se divide en tres capas: contrato matemático de `LayoutMetrics` bajo headless; pruebas de regresión GDScript; y revisión visual de 20 capturas (10 pantallas verticales y 10 horizontales) generadas mediante Xvfb. Las capturas no sustituyen la comprobación en Android.

### Incidencias conocidas / siguientes verificaciones

1. Probar en Android físico la zona táctil, teclado virtual, rotación y escalas en distintas densidades, especialmente chat y ajustes.
2. Confirmar mediante recorridos reales que los controles laterales no tapan el tablero o los overlays de sugerencia/chat/reacción en 2c2 y 1c1, y que la pantalla final usa una distribución legible.
3. La partida horizontal conserva casillas cuadradas; si se exigiera usar literalmente todo el ancho como cuadrado, habría que cambiar la estructura de interacción/orientación, porque no caben 8 columnas y 8 filas cuadradas en 844×390 sin recorte. La decisión V146 es preservar la geometría jugable.
4. Las suites cubren layouts, navegación básica y contratos de QA indicados en el informe. No constituyen auditoría completa del motor de ajedrez, Stockfish, servidores, Android ni todos los flujos sociales.
